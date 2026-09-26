#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""批处理脚本静态检查 —— 不依赖 Windows, 在 macOS / Linux 上也能跑。

用法:
    python3 tests/check_bat.py                    # 自动找仓库根目录下的 *.bat
    python3 tests/check_bat.py 星君常用远程工具v1.8.bat

检查项:
    1. 能用 GBK 解码 (中文不乱码的前提)
    2. 换行是纯 CRLF (混入裸 LF 会让 cmd 解析异常)
    3. 没有悬空跳转 (goto / call 的目标标签必须存在)
    4. 括号配对
    5. 每个 set /p 之前都清空了变量 (set /p 在用户直接回车时不清空, 会残留旧值)
    6. 开了 EnableDelayedExpansion 就不能在 echo 里出现 ! (会被吞掉)
    7. 版本号在头部 / 标题 / 菜单 / 退出页里一致

退出码 0 = 通过, 1 = 有问题。
"""
import pathlib
import re
import sys

RED, YEL, GRN, DIM, RST = "\033[31m", "\033[33m", "\033[32m", "\033[2m", "\033[0m"


def find_bat(root: pathlib.Path):
    cands = sorted(root.glob("*.bat")) + sorted(root.glob("*.cmd"))
    return cands


def check(path: pathlib.Path):
    errors, warns = [], []
    raw = path.read_bytes()

    try:
        text = raw.decode("gbk")
    except UnicodeDecodeError as exc:
        return [f"无法按 GBK 解码: {exc}"], []

    lines = text.split("\r\n")

    # --- 1/2 编码与换行 ---
    lone_lf = text.count("\n") - text.count("\r\n")
    if lone_lf:
        errors.append(f"存在 {lone_lf} 个裸 LF, 应为纯 CRLF (否则 cmd 可能解析异常)")
    if raw.startswith(b"\xef\xbb\xbf"):
        errors.append("文件带 UTF-8 BOM, 会让 cmd 第一行报错")

    # --- 3 悬空跳转 ---
    labels = {
        l.strip()[1:].split()[0].lower()
        for l in lines
        if l.strip().startswith(":") and not l.strip().startswith("::")
    }
    jumps = [
        (i, m.group(1).lower())
        for i, l in enumerate(lines, 1)
        for m in re.finditer(r"\b(?:goto|call)\s+:?([A-Za-z_]\w*)", l, re.I)
    ]
    for i, tgt in jumps:
        if tgt not in labels:
            errors.append(f"第 {i} 行: 跳转目标 :{tgt} 不存在")

    # --- 4 括号配对 (剔除 echo/注释行和带引号的参数, 避免误报) ---
    depth, bad = 0, []
    for i, l in enumerate(lines, 1):
        s = re.sub(r"^\s*(echo|::|rem)\b.*$", "", l, flags=re.I)
        s = re.sub(r'"[^"]*"', "", s)
        depth += s.count("(") - s.count(")")
        if depth < 0:
            bad.append(i)
            depth = 0
    if bad:
        errors.append(f"第 {bad[:5]} 行: 右括号多于左括号")
    if depth:
        errors.append(f"文件结束时还有 {depth} 个左括号没闭合")

    # --- 5 set /p 残留值 ---
    for i, l in enumerate(lines):
        m = re.match(r"\s*set /p (\w+)=", l)
        if not m:
            continue
        var = m.group(1)
        window = [x.strip() for x in lines[max(0, i - 3):i]]
        if f'set "{var}="' not in window:
            errors.append(
                f"第 {i + 1} 行: set /p {var} 之前没有 set \"{var}=\" "
                f"(直接回车会残留旧值, 可能被误判为确认)"
            )

    # --- 5.5 echo 行里的未转义特殊字符 ---
    # echo 后面没加引号时, | & < > 会被 cmd 当成管道/重定向/命令分隔符。
    # 踩过: echo 作者: 星君 (Xingjun) | License: MIT 里的 | 被当成管道,
    # 菜单从那一行开始就再也打不出来了。
    for i, l in enumerate(lines, 1):
        if not re.match(r"\s*echo\b", l, re.I):
            continue
        body = l.strip()[4:]
        if body.startswith(".") or body.startswith("("):
            continue
        for ch, name in (("|", "管道"), ("<", "输入重定向"), (">", "输出重定向"), ("&", "命令分隔")):
            if ch in body:
                errors.append(
                    f"第 {i} 行: echo 内容里有未转义的 {ch} ({name}), "
                    f"会被 cmd 当成操作符 —— 改用全角字符或加 ^ 转义"
                )

    # --- 5.7 choice 之后必须紧跟 if errorlevel ---
    # cmd 的内部命令(echo/set/if 等)会把 ERRORLEVEL 重置为 0,
    # 中间插一句 echo. 就会让 if errorlevel 永远不成立 ——
    # 表现是「按 N 取消」失效, 危险操作照样执行。
    for i, l in enumerate(lines):
        if "choice /c" not in l or i + 1 >= len(lines):
            continue
        nxt = lines[i + 1]
        if "if errorlevel" not in nxt and not nxt.strip().lower().startswith("goto"):
            errors.append(
                f"第 {i + 1} 行: choice 之后紧跟的是 {nxt.strip()!r}, 不是 if errorlevel。"
                f"中间的命令会重置 errorlevel, 导致选择结果判错"
            )

    # --- 6 延迟展开与 ! ---
    if re.search(r"EnableDelayedExpansion", text, re.I):
        if re.search(r"^\s*echo[^\r\n]*!", text, re.M):
            errors.append("开了 EnableDelayedExpansion, 但 echo 里出现了 ! —— 会被吞掉")

    # --- 7 版本号一致性 ---
    versions = set(re.findall(r"星君常用远程工具\s*(v[\d.]+)", text))
    if len(versions) > 1:
        errors.append(f"文件内版本号不一致: {sorted(versions)}")
    elif not versions:
        warns.append("文件里没有找到版本号")

    # --- 额外提醒 ---
    if "set /p" in text and "choice /c" not in text:
        warns.append("确认类输入还在用 set /p, 考虑换成 choice /c YN (不产生变量, 无残留值问题)")

    return errors, warns


def main():
    root = pathlib.Path(__file__).resolve().parent.parent
    args = sys.argv[1:]
    targets = [pathlib.Path(a) for a in args] if args else find_bat(root)
    targets = [t if t.is_absolute() else (pathlib.Path.cwd() / t) for t in targets]
    if not targets:
        print(f"{RED}没找到 .bat / .cmd 文件{RST}")
        return 1

    failed = False
    for t in targets:
        if not t.exists():
            print(f"{RED}[缺失] {t}{RST}")
            failed = True
            continue
        errors, warns = check(t)
        size = t.stat().st_size
        if errors:
            failed = True
            print(f"{RED}[不通过] {t.name}{RST}  {DIM}({size} 字节){RST}")
            for e in errors:
                print(f"   {RED}×{RST} {e}")
        else:
            print(f"{GRN}[通过]{RST} {t.name}  {DIM}({size} 字节){RST}")
        for w in warns:
            print(f"   {YEL}!{RST} {w}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
