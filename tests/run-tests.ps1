# 星君常用远程工具 —— Windows 冒烟测试
#
# 在真实 Windows 上运行脚本, 喂入按键序列, 断言输出内容。
# 只测「不会改动系统」的路径, 或者「确认时选取消」的路径。
#
# 用法:
#   powershell -ExecutionPolicy Bypass -File tests\run-tests.ps1
#
# 参数:
#   -ScriptPath  被测脚本。不传则在仓库根目录里自动找第一个 .bat。
#   -TimeoutSec  单个用例的超时秒数, 默认 60。超时说明脚本卡住了。
#
# 三个 Windows 上的坑, 别改坏:
#   0. 代码页要设, 但必须在别的进程里设。同一个 cmd 进程里执行过 chcp 之后,
#      它的 set /p 就读不到重定向输入了(变量直接不被赋值)。
#      所以 wrapper 用 `cmd /c chcp 936` 起子进程去设, 控制台代码页变了,
#      而本进程没执行过 chcp, set /p 依然正常。脚本副本里也把 chcp 相关行
#      移除了, 双保险。
#   1. 本文件必须是 UTF-8 with BOM。Windows PowerShell 5.1 会把没有 BOM 的
#      UTF-8 脚本按系统 ANSI 代码页读, 里面的中文断言会全部乱码。
#   2. 本文件必须是 CRLF 换行。PowerShell 5.1 对纯 LF 的脚本会解析异常
#      (跨行块注释会认不出来), 报 "Unexpected attribute 'CmdletBinding'"。
#
# 为什么把脚本复制到纯 ASCII 的临时路径再跑:
#   脚本文件名是中文, 而生成的辅助 .cmd 会被 cmd 按当前代码页解析,
#   代码页不是 936 时中文路径会乱码。复制成 ASCII 名最省事。
#
# 输出文件按 GBK 读 —— 脚本里执行了 chcp 936, 重定向到文件的是 GBK 字节。

[CmdletBinding()]
param(
    [string]$ScriptPath = '',
    [int]$TimeoutSec = 60
)

$ErrorActionPreference = 'Stop'

# GBK(936) 在 PowerShell 7 / .NET Core 上要先注册代码页提供程序才能拿到
try {
    $gbk = [System.Text.Encoding]::GetEncoding(936)
} catch {
    [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
    $gbk = [System.Text.Encoding]::GetEncoding(936)
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $ScriptPath) {
    $found = Get-ChildItem -LiteralPath $repoRoot -Filter '*.bat' -File |
             Sort-Object Name | Select-Object -First 1
    if (-not $found) { Write-Host '找不到 .bat 文件' -ForegroundColor Red; exit 1 }
    $ScriptPath = $found.FullName
}
if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Write-Host "脚本不存在: $ScriptPath" -ForegroundColor Red
    exit 1
}

$work = Join-Path $env:TEMP ('xjbat-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work -Force | Out-Null

# 复制成 ASCII 文件名, 避免代码页把中文路径搞乱
$tool = Join-Path $work 'tool.bat'
# 测试环境要在没有真实控制台的情况下喂入按键, 而 chcp 在「无控制台 + 重定向输入」
# 的组合下会让后续 set /p 读不到输入(实测: 去掉 chcp 就正常, 保留就读到空)。
# 所以副本里把脚本自己的 chcp 中和掉, 改由 wrapper 在调用前设好代码页 ——
# 这样输出仍是 GBK, set /p 也能正常读到按键。
$toolText = [System.IO.File]::ReadAllText($ScriptPath, $gbk)
$toolLines = $toolText -split "`r`n"
$removed = @($toolLines | Where-Object { $_ -match 'chcp' })
$toolLines = $toolLines | Where-Object { $_ -notmatch 'chcp' }
$toolText = ($toolLines -join "`r`n")
[System.IO.File]::WriteAllText($tool, $toolText, $gbk)
Write-Host "已从测试副本里移除 $($removed.Count) 行含 chcp 的代码:"
$removed | ForEach-Object { Write-Host "    - $($_.Trim())" }

function Read-Output {
    # 测试环境不能用 chcp(它会让 set /p 读不到重定向输入), 所以脚本输出的
    # 编码取决于控制台默认代码页, 不一定是 GBK。
    #
    # 不要用「解出来 CJK 字符最多」这种启发式 —— 猜错的时候两种解码都能解出
    # 一堆生僻字, 反而选错。改用确定性判断: 脚本输出里一定有"星君"两个字,
    # 哪个编码能解出这两个字, 就用哪个。
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $gbkEnc = [System.Text.Encoding]::GetEncoding(936)
    $utf8Enc = New-Object System.Text.UTF8Encoding $false
    foreach ($enc in @($gbkEnc, $utf8Enc)) {
        $t = $enc.GetString($bytes)
        if ($t.Contains('星君')) { return $t }
    }
    return $gbkEnc.GetString($bytes)
}

function Invoke-Bat {
    param([string]$Bat, [string]$InputText, [string]$BatArgs = '')
    $id = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $inF = Join-Path $work "in-$id.txt"
    $outF = Join-Path $work "out-$id.txt"
    $runF = Join-Path $work "run-$id.cmd"
    [System.IO.File]::WriteAllText($inF, $InputText, $gbk)
    # 代码页必须在「另一个进程」里设置:
    #   - 在同一个 cmd 进程里执行 chcp, 之后它的 set /p 就读不到重定向输入
    #   - 但 chcp 改的是整个控制台的代码页, 所以用 cmd /c 起个子进程设好,
    #     控制台代码页就变了, 而本进程没执行过 chcp, set /p 依然正常。
    # 这样脚本输出就是 GBK, 中文断言才能对上。
    $w = "@echo off`r`ncmd /c chcp 936 >nul`r`n`"$Bat`" $BatArgs < `"$inF`" > `"$outF`" 2>&1`r`n"
    [System.IO.File]::WriteAllText($runF, $w, [System.Text.Encoding]::ASCII)
    $p = Start-Process -FilePath $env:ComSpec -ArgumentList '/c', $runF `
                       -PassThru -NoNewWindow -WorkingDirectory $work
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill() } catch { }
        return [pscustomobject]@{ TimedOut = $true; Output = ''; ExitCode = -1; OutFile = $outF }
    }
    $text = ''
    if (Test-Path -LiteralPath $outF) {
        $text = Read-Output $outF
    }
    return [pscustomobject]@{ TimedOut = $false; Output = $text; ExitCode = $p.ExitCode; OutFile = $outF }
}

$results = New-Object System.Collections.ArrayList
function Add-Result {
    param([string]$Name, [string]$Status, [string]$Detail)
    [void]$results.Add([pscustomobject]@{ Name = $Name; Status = $Status; Detail = $Detail })
}

function Test-Case {
    param(
        [string]$Name,
        [string]$InputText,
        [string[]]$Contain = @(),
        [string[]]$NotContain = @(),
        [switch]$NeedsAdmin,
        [string]$Bat = $tool,
        [string]$BatArgs = ''
    )
    if ($NeedsAdmin -and -not $isAdmin) {
        Add-Result $Name 'SKIP' '当前不是管理员, 跳过'
        return
    }
    $r = Invoke-Bat -Bat $Bat -InputText $InputText -BatArgs $BatArgs
    if ($r.TimedOut) {
        Add-Result $Name 'FAIL' "超时 $TimeoutSec 秒 (脚本卡住)"
        Write-Host "  ----- 超时详情: $Name -----" -ForegroundColor DarkYellow
        if (Test-Path -LiteralPath $r.OutFile) {
            $partial = Read-Output $r.OutFile
            Write-Host "  (已产生的输出 $($partial.Length) 字符, 末尾 800 字符)"
            if ($partial.Length -gt 800) { $partial = $partial.Substring($partial.Length - 800) }
            Write-Host $partial
        } else {
            Write-Host "  <没有任何输出>"
        }
        Write-Host "  ----- 详情结束 -----" -ForegroundColor DarkYellow
        return
    }
    $out = $r.Output
    $problems = @()
    # 用 Contains 做字面量匹配 —— -like 会把断言里的 * ? [ ] 当通配符
    foreach ($s in $Contain) {
        if (-not $out.Contains($s)) { $problems += "缺少: $s" }
    }
    foreach ($s in $NotContain) {
        if ($out.Contains($s)) { $problems += "不该出现: $s" }
    }
    if ($problems.Count) {
        Add-Result $Name 'FAIL' ($problems -join ' / ')
        Write-Host "  ----- 失败详情: $Name (输出 $($out.Length) 字节) -----" -ForegroundColor DarkYellow
        if ($out) { Write-Host $out } else { Write-Host "<脚本没有任何输出>" }
        Write-Host "  ----- 详情结束 -----" -ForegroundColor DarkYellow
    } else {
        Add-Result $Name 'PASS' ''
    }
}

# 注意: PowerShell 的 IsInRole(Administrator) 只看组成员身份,
# 令牌被 UAC 过滤时也会返回 True, 不能用来判断有没有真的提权。
# 这里用一个探针实测, 顺便把结果打出来。
$adminProbe = Join-Path $work 'admincheck.bat'
$apLines = @(
    '@echo off',
    'fsutil dirty query %SystemDrive% >nul 2>&1',
    'echo FSUTIL=%errorlevel%',
    'net session >nul 2>&1',
    'echo NETSESSION=%errorlevel%',
    'whoami /groups | findstr /c:"S-1-16-12288" >nul 2>&1',
    'echo HIGHINTEGRITY=%errorlevel%'
)
[System.IO.File]::WriteAllText($adminProbe, ($apLines -join "`r`n") + "`r`n", [System.Text.Encoding]::ASCII)
$adminOut = (Invoke-Bat -Bat $adminProbe -InputText '').Output
$isAdmin = $adminOut.Contains('FSUTIL=0')

# 断言里不要写死版本号 —— 仓库里可能同时有多个版本的文件要测
$toolSrc = [System.IO.File]::ReadAllText($ScriptPath, $gbk)
$ver = [regex]::Match($toolSrc, '星君常用远程工具 (v[\d.]+)').Groups[1].Value
$hasRestore = $toolSrc.Contains('还原全部改动')
Write-Host "版本     : $ver" 

Write-Host "被测脚本 : $ScriptPath"
Write-Host "工作目录 : $work"
Write-Host "提权检测 : $(($adminOut -split "`r?`n" | Where-Object { $_ }) -join '  ')"
Write-Host "判定     : $(if ($isAdmin) { '已提权' } else { '未提权 (令牌被过滤)' })"
Write-Host ''

# ---------------------------------------------------------------- choice 行为自检
# 先单独验证 choice 能不能读管道输入 —— 后面脚本里的确认提示都依赖这一点
$choiceBat = Join-Path $work 'choicetest.bat'
$cbLines = @(
    '@echo off',
    'choice /c YN /n /m "pick "',
    'if errorlevel 2 (echo RESULT=N) else (echo RESULT=Y)'
)
[System.IO.File]::WriteAllText($choiceBat, ($cbLines -join "`r`n") + "`r`n",
                               [System.Text.Encoding]::ASCII)

Test-Case -Name 'choice 能读管道输入 (按 Y)' -Bat $choiceBat `
          -InputText "Y`n" -Contain @('RESULT=Y') -BatArgs '/elevated'
Test-Case -Name 'choice 能读管道输入 (按 N)' -Bat $choiceBat `
          -InputText "N`n" -Contain @('RESULT=N') -BatArgs '/elevated'

# ---------------------------------------------------------------- 主脚本用例
# 每个用例的输入都以 0 收尾, 保证脚本一定会退出, 不会空转
# ---------------------------------------------------------------- 探针
# 逐项加变量, 定位到底哪一步让 set /p 读到空
$mkProbe = {
    param([string]$File, [string[]]$Body)
    [System.IO.File]::WriteAllText($File, (('@echo off') + "`r`n" + ($Body -join "`r`n") + "`r`n"),
                                   $gbk)
    return $File
}

$p1 = & $mkProbe (Join-Path $work 'p1.bat') @(
    'set "x="', 'set /p x=pick: ', 'if "%x%"=="11" (echo YES-MATCH) else (echo NO-MATCH)')
Test-Case -Name '探针1 基线 ASCII 提示' -Bat $p1 -InputText "11`n" -Contain @('YES-MATCH')

# 注意: 这里刻意不测「chcp 936 + set /p」的组合。
# 实测在「无真实控制台 + 重定向输入」下, 只要执行过 chcp, 之后的 set /p
# 就读不到任何输入(变量直接不被赋值)。所以测试环境全程不碰 chcp,
# 脚本输出改由 Read-Output 自动识别编码。详见 run-tests.ps1 顶部说明。

$p3 = & $mkProbe (Join-Path $work 'p3.bat') @(
    'set "x="', 'set /p x=请输入序号后回车: ',
    'if "%x%"=="11" (echo YES-MATCH) else (echo NO-MATCH)')
Test-Case -Name '探针3 中文提示' -Bat $p3 -InputText "11`n" -Contain @('YES-MATCH')

$p6 = & $mkProbe (Join-Path $work 'p6.bat') @(
    'cls', 'set "x="', 'set /p x=pick: ',
    'if "%x%"=="11" (echo YES-MATCH) else (echo NO-MATCH)')
Test-Case -Name '探针6 加了 cls' -Bat $p6 -InputText "11`n" -Contain @('YES-MATCH')

# 用真实脚本里的 :NORM 段落, 看它会不会把输入改坏
$toolText = [System.IO.File]::ReadAllText($tool, $gbk)
    $nm = [regex]::Match($toolText, "(?sm)^:NORM\r\n.*?\r\nexit /b\r\n")
Write-Host "  [信息] 提取到 NORM 段 $($nm.Value.Length) 字符"
$p5body = @('@echo off', 'set "x="', 'set /p x=pick: ', 'call :NORM',
            'echo VALUE=[%x%]',
            'if "%x%"=="11" (echo YES-MATCH) else (echo NO-MATCH)') + ($nm.Value -split "`r`n")
$p5 = & $mkProbe (Join-Path $work 'p5.bat') $p5body
Test-Case -Name '探针5 真实 :NORM 段' -Bat $p5 -InputText "11`n" -Contain @('YES-MATCH')

# 决定性诊断: 副本里已经没有 chcp 了, 直接看 set /p 能不能读到
$dbgText = [System.IO.File]::ReadAllText($tool, $gbk)
$d1 = Join-Path $work 'dbgX.bat'
[System.IO.File]::WriteAllText($d1, $dbgText.Replace(
    'set /p choice=请输入序号后回车: ',
    "set /p choice=请输入序号后回车: `r`necho RAW=[%choice%]`r`nexit /b"), $gbk)
Test-Case -Name '诊断 set /p 在无 chcp 副本里能否读到' -Bat $d1 `
          -InputText "11`n" -Contain @('RAW=[11]') -BatArgs '/elevated'

# 功能执行时都会先打一条横线包起来的标题, 用它当断言标记,
# 免得匹配到菜单里的同名文字造成「假通过」
$TL = '-------------------- '   # 左: 横线 + 空格
$TR = ' --------------------'   # 右: 空格 + 横线

Test-Case -Name '菜单能显示并正常退出' `
          -InputText "0`n0`n0`n" -BatArgs '/elevated' `
          -Contain @("星君常用远程工具 $ver", '感谢使用, 再见。')

$menuItems = @('1   查看完整网络配置', '13   端口占用排查', '0   退出')
if ($hasRestore) { $menuItems += '26   还原全部改动' }
Test-Case -Name '菜单列出全部条目' `
          -InputText "0`n0`n" -BatArgs '/elevated' `
          -Contain $menuItems

Test-Case -Name '无效输入有提示' `
          -InputText "99`n0`n0`n" -BatArgs '/elevated' `
          -Contain @('无效输入, 请输入 0-26 的序号。')

Test-Case -Name '半角序号可用 (功能 3)' `
          -InputText "3`n0`n0`n" -BatArgs '/elevated' `
          -Contain @("${TL}默认网关与 DNS 服务器${TR}")

Test-Case -Name '全角序号 ２ 自动转半角 (功能 2)' `
          -InputText "２`n0`n0`n" -BatArgs '/elevated' `
          -Contain @("${TL}IP 地址与子网掩码${TR}")

Test-Case -Name '全角两位数 ２３ 自动转半角 (功能 23)' `
          -InputText "２３`n0`n0`n" -BatArgs '/elevated' `
          -Contain @("${TL}当前 UAC 状态${TR}")

Test-Case -Name '序号前后空格被忽略 (功能 2)' `
          -InputText "  2  `n0`n0`n" -BatArgs '/elevated' `
          -Contain @("${TL}IP 地址与子网掩码${TR}")

Test-Case -Name '只读功能 9 防火墙状态' `
          -InputText "9`n0`n0`n" -BatArgs '/elevated' `
          -Contain @("${TL}防火墙状态${TR}")

Test-Case -Name '只读功能 23 UAC 状态' `
          -InputText "23`n0`n0`n" -BatArgs '/elevated' `
          -Contain @("${TL}当前 UAC 状态${TR}", 'EnableLUA')

Test-Case -Name '确认提示按 N 走取消分支 (不改系统)' -NeedsAdmin `
          -InputText "11`nN`n0`n0`n" -BatArgs '/elevated' `
          -Contain @('已取消。') `
          -NotContain @('排查完成后请用功能 10')

# 这里不测「确认时按 Y」: choice 在 set /p 已经读过一次重定向输入之后,
# 拿不到后续的按键(实测会走成取消分支)。无真实控制台时驱动不了 choice,
# 所以只测「按 N 取消」这条不会改动系统的路径。
# Y 分支的正确性由 check_bat.py 保证: 确认块必须是 choice 紧跟 if errorlevel。


# ---------------------------------------------------------------- 汇总
Write-Host ''
$width = ($results | Measure-Object -Property Name -Maximum).Maximum.Length
foreach ($r in $results) {
    $color = switch ($r.Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        default { 'Yellow' }
    }
    $line = "{0,-6} {1}" -f $r.Status, $r.Name.PadRight($width)
    if ($r.Detail) { $line += "  -- $($r.Detail)" }
    Write-Host $line -ForegroundColor $color
}

$pass = @($results | Where-Object Status -eq 'PASS').Count
$fail = @($results | Where-Object Status -eq 'FAIL').Count
$skip = @($results | Where-Object Status -eq 'SKIP').Count
Write-Host ''
Write-Host "通过 $pass / 失败 $fail / 跳过 $skip" -ForegroundColor $(if ($fail) { 'Red' } else { 'Green' })

Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
exit $(if ($fail) { 1 } else { 0 })
