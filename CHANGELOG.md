# 更新日志

本文件记录 **星君常用远程工具** 的版本变更。

> v1.6 之前通过 [gp45.ys168.com](https://gp45.ys168.com) 分发，未在本仓库归档，因此没有更早的记录。

---

## [v1.7] — 2026-09-26

**下载**：[XingjunRemoteTool-v1.7.bat](https://github.com/reroc8/xingjun-remote-toolkit/releases/download/v1.7/XingjunRemoteTool-v1.7.bat)
**SHA256**：`fa2fc0bb94f524e9133ba83ea7b32092dc037a9b5942f4ea05863bbca6359d8e`

修掉 v1.6 里几个会真正影响使用的问题。

### 修复

- **确认提示可能被残留值误判**（严重）—— 确认变量 `sure` 在 3 处没有提前清空，而 `set /p` 在用户直接回车时**不会**清空变量。
  后果：用户在上一个提示输过 `Y`，到了下一个提示（比如"确认禁用 UAC"）直接回车想取消，
  变量仍是 `Y`，会被当成确认执行。**可能导致 UAC 被意外禁用。**
  已在功能 10 / 11 / 21 / 26 的提示前补上 `set "sure="`。
- **权限检测误判** —— 原用 `net session` 判断管理员权限。Server 服务（`LanmanServer`）被停用时，
  即使已经是管理员也会被判成普通用户，需要管理员的功能直接拒绝执行。
  改用 `fsutil dirty query %SystemDrive%`（不依赖任何服务），`net session` 退为兜底。
- **禁用系统更新不彻底** —— 补上 `UsoSvc`（Update Orchestrator Service），
  它会主动把 `wuauserv` 拉回来。现在一并停用并禁用。
- **重复放行同一端口会失败** —— 规则名固定，第二次添加同名规则会报"已存在"。
  改为先 `delete rule` 再 `add rule`。
- `findstr /r /c:` 去掉无效的 `/r` 参数（`/c:` 已把整串当字面量）。

### 新增

- **还原全部改动（功能 26）** —— 一键把防火墙 / 系统更新 / UAC / 快捷方式箭头恢复为默认状态，
  并通过 PowerShell 清理所有 `星君放行_*` 防火墙规则。执行前会列出将要还原的项并要求确认，
  不会动 `导出` 目录里的文件。

### 改进

- **输入容错** —— 菜单序号、端口号、PID 自动去掉前后空格，全角数字转半角（`１` → `1`）
- **服务操作会报告实际结果** —— 新增 `:SVC_OFF` / `:SVC_ON` 子程序，
  不再只打一行命令就完事，而是回读服务状态并说明是否需要重启才彻底生效
- **去箭头 / 恢复箭头前明确提示**资源管理器提权的副作用，并给出恢复办法

### 已知限制

- `WaaSMedicSvc`（Windows Update Medic Service）受系统保护，本工具无法禁用，
  它仍可能把更新服务恢复回来。重跑功能 19 即可。
- 确认字母（`Y` / `OFF`）只认半角，全角字母不会自动转换。

---

## [v1.6] — 2026-09-25

首个 GitHub 发布版。

**下载**：[XingjunRemoteTool-v1.6.bat](https://github.com/reroc8/xingjun-remote-toolkit/releases/download/v1.6/XingjunRemoteTool-v1.6.bat)
**SHA256**：`ce0a7bb62659dbf3efce19d7d2e7da256d4d69e68eb12578701b531bba484c06`

### 新增

- 端口占用排查（功能 13）—— 查出占用进程的 PID，确认后可强制结束
- UAC 状态查看（功能 23）
- 恢复快捷方式箭头（功能 25）—— 会先检测是否已去除，避免无谓操作

### 变更

- 菜单按功能域分组：网络 / 防火墙端口 / 系统硬件 / 系统更新 / UAC / 桌面美化，编号重排为 0-25
- 网络配置导出改为带时间戳的独立文件，统一输出到 `导出` 目录
- 改配置类功能（防火墙、系统更新、UAC、箭头）统一加入**二次确认**与**执行后验证**，操作完回读当前状态确认生效

### 改进

- 端口号 / PID 输入增加纯数字校验，避免非法输入直接传给系统命令
- 增加管理员权限预检，权限不足时给出明确指引而不是让命令直接失败

### 已知限制（v1.7 已修）

- ~~权限检测用 `net session`，Server 服务（`LanmanServer`）被停用时会把管理员误判为普通用户~~
  → 已在 [v1.7] 改用 `fsutil dirty query`
- ~~禁用系统更新只处理 `wuauserv` 和 `bits`，未处理会把服务拉起的 `UsoSvc`~~
  → 已在 [v1.7] 补上 `UsoSvc`

---

## 未发布

### v1.8（计划）

- [ ] 确认字母也做全角转半角，与数字的处理保持一致
- [ ] 功能 15（`systeminfo`）耗时较长，考虑加"按 Ctrl+C 中断"的提示或换更快的取数方式
- [ ] 功能 24 / 25 改用非提权方式重启资源管理器，从根上避免权限继承问题
- [ ] 功能 8 查看 Wi-Fi 密码：支持从列表里选序号，不用手输 SSID

---

[v1.7]: https://github.com/reroc8/xingjun-remote-toolkit/releases/tag/v1.7
[v1.6]: https://github.com/reroc8/xingjun-remote-toolkit/releases/tag/v1.6
