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
# 两个 Windows 上的坑, 别改坏:
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
[System.IO.File]::WriteAllBytes($tool, [System.IO.File]::ReadAllBytes($ScriptPath))

$isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host ''
Write-Host "被测脚本 : $ScriptPath"
Write-Host "工作目录 : $work"
Write-Host "管理员   : $isAdmin"
Write-Host ''

function Invoke-Bat {
    param([string]$Bat, [string]$InputText)
    $id = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $inF = Join-Path $work "in-$id.txt"
    $outF = Join-Path $work "out-$id.txt"
    $runF = Join-Path $work "run-$id.cmd"
    [System.IO.File]::WriteAllText($inF, $InputText, $gbk)
    $w = "@echo off`r`n`"$Bat`" < `"$inF`" > `"$outF`" 2>&1`r`n"
    [System.IO.File]::WriteAllText($runF, $w, [System.Text.Encoding]::ASCII)
    $p = Start-Process -FilePath $env:ComSpec -ArgumentList '/c', $runF `
                       -PassThru -NoNewWindow -WorkingDirectory $work
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill() } catch { }
        return [pscustomobject]@{ TimedOut = $true; Output = ''; ExitCode = -1 }
    }
    $text = ''
    if (Test-Path -LiteralPath $outF) {
        $text = [System.IO.File]::ReadAllText($outF, $gbk)
    }
    return [pscustomobject]@{ TimedOut = $false; Output = $text; ExitCode = $p.ExitCode }
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
        [string]$Bat = $tool
    )
    if ($NeedsAdmin -and -not $isAdmin) {
        Add-Result $Name 'SKIP' '当前不是管理员, 跳过'
        return
    }
    $r = Invoke-Bat -Bat $Bat -InputText $InputText
    if ($r.TimedOut) {
        Add-Result $Name 'FAIL' "超时 $TimeoutSec 秒 (脚本卡住或被 choice/pause 阻塞)"
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
          -InputText "Y`n" -Contain @('RESULT=Y')
Test-Case -Name 'choice 能读管道输入 (按 N)' -Bat $choiceBat `
          -InputText "N`n" -Contain @('RESULT=N')

# ---------------------------------------------------------------- 主脚本用例
# 每个用例的输入都以 0 收尾, 保证脚本一定会退出, 不会空转
# ---------------------------------------------------------------- 探针
# set /p 从重定向文件读入时, 可能把行尾的 CR 一起放进变量,
# 导致 if "%x%"=="3" 匹配不上。先用最小例子确认这个判断。
$probe = Join-Path $work 'probe.bat'
$pb = @(
    '@echo off',
    'set "x="',
    'set /p x=pick: ',
    'if "%x%"=="3" (echo MATCH) else (echo NOMATCH)'
)
[System.IO.File]::WriteAllText($probe, ($pb -join "`r`n") + "`r`n",
                               [System.Text.Encoding]::ASCII)
Test-Case -Name '探针 set /p 读 CRLF 输入' -Bat $probe -InputText "3`r`n" -Contain @('MATCH')
Test-Case -Name '探针 set /p 读 LF 输入' -Bat $probe -InputText "3`n" -Contain @('MATCH')


# 功能执行时都会先打一条横线包起来的标题, 用它当断言标记,
# 免得匹配到菜单里的同名文字造成「假通过」
$T = '-------------------- '

Test-Case -Name '菜单能显示并正常退出' `
          -InputText "0`n0`n0`n" `
          -Contain @('星君常用远程工具 v1.8', '感谢使用, 再见。')

Test-Case -Name '菜单列出全部条目' `
          -InputText "0`n0`n" `
          -Contain @('1   查看完整网络配置', '13   端口占用排查',
                     '26   还原全部改动', '0   退出')

Test-Case -Name '无效输入有提示' `
          -InputText "99`n0`n0`n" `
          -Contain @('无效输入, 请输入 0-26 的序号。')

Test-Case -Name '半角序号可用 (功能 3)' `
          -InputText "3`n0`n0`n" `
          -Contain @("${T}默认网关与 DNS 服务器${T}")

Test-Case -Name '全角序号 ２ 自动转半角 (功能 2)' `
          -InputText "２`n0`n0`n" `
          -Contain @("${T}IP 地址与子网掩码${T}")

Test-Case -Name '全角两位数 ２３ 自动转半角 (功能 23)' `
          -InputText "２３`n0`n0`n" `
          -Contain @("${T}当前 UAC 状态${T}")

Test-Case -Name '序号前后空格被忽略 (功能 2)' `
          -InputText "  2  `n0`n0`n" `
          -Contain @("${T}IP 地址与子网掩码${T}")

Test-Case -Name '只读功能 9 防火墙状态' `
          -InputText "9`n0`n0`n" `
          -Contain @("${T}防火墙状态${T}")

Test-Case -Name '只读功能 23 UAC 状态' `
          -InputText "23`n0`n0`n" `
          -Contain @("${T}当前 UAC 状态${T}", 'EnableLUA')

Test-Case -Name '确认提示按 N 走取消分支 (不改系统)' -NeedsAdmin `
          -InputText "11`nN`n0`n0`n" `
          -Contain @('已取消。') `
          -NotContain @('排查完成后请用功能 10')

Test-Case -Name '确认提示按 Y 走执行分支 (功能 10)' -NeedsAdmin `
          -InputText "10`nY`n0`n0`n" `
          -Contain @('【验证】当前状态') `
          -NotContain @('已取消。')


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
