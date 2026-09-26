@echo off
:: ============================================================
::  星君常用远程工具 v1.8
::  作者  : 星君 (Xingjun)  |  gp45.ys168.com
::  许可  : MIT License    |  更新日期: 2026-09-26
::  声明  : 本工具仅修改本机配置, 部分功能需管理员权限,
::          使用前请阅读同目录 README 中的注意事项。
:: ============================================================
setlocal EnableExtensions
:: 主菜单是两列, 需要足够宽的窗口; 同时把行数放大, 免得要滚动
mode con: cols=100 lines=43 >nul 2>&1
:: 只在控制台代码页不是 936 时才切换 —— 中文系统本来就是 936, 不必多此一举;
:: 少一次控制台调用也更稳
set "CONSOLE_CP="
for /f "tokens=2 delims=:" %%c in ('chcp') do set "CONSOLE_CP=%%c"
set "CONSOLE_CP=%CONSOLE_CP: =%"
if not "%CONSOLE_CP%"=="936" chcp 936 >nul 2>&1
title 星君常用远程工具 v1.8  -  作者: 星君
color 0A

set "EXPORT_DIR=%~dp0导出"
if not exist "%EXPORT_DIR%" mkdir "%EXPORT_DIR%" >nul 2>&1
set "UAC_REG=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
set "BADCNT=0"

:: ---------------- 启动: 自动请求管理员权限 ----------------
:: 带 /elevated 参数说明是提权后重启的实例, 不再重复请求, 避免反复弹窗
:: 路径通过环境变量 SELF 传给 PowerShell, 免得路径里的引号把命令打断
if /i "%~1"=="/elevated" goto MENU

call :CHECK_ADMIN
if "%IS_ADMIN%"=="1" goto MENU

cls
echo ========================================================
echo    需要管理员权限
echo ========================================================
echo.
echo   本工具有 10 项功能需要管理员权限, 现在尝试提权。
echo.
echo   - 在弹出的 UAC 窗口里点「是」, 会在新窗口以管理员身份重新打开本工具
echo   - 点「否」则以普通权限继续, 需要管理员的功能会提示权限不足
echo.
set "SELF=%~f0"
powershell -NoProfile -Command "try { Start-Process -FilePath $env:SELF -ArgumentList '/elevated' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
if not errorlevel 1 (
    echo   已在管理员窗口重新打开, 这个窗口马上关闭...
    timeout /t 2 >nul
    exit /b 0
)
echo   [!] 没有拿到管理员权限, 以普通权限继续。
echo       想用需要管理员的功能, 请关掉本窗口后重新运行, 并在 UAC 弹窗里点「是」。
echo.
pause
goto MENU

:MENU
cls
echo ==============================================================================================
echo    [星君] gp45.ys168.com  常用远程工具 v1.8
echo    ---  网络 / 防火墙 / 系统 / UAC / 桌面管理  ---
echo    作者: 星君 (Xingjun)  ｜  License: MIT
echo ==============================================================================================
echo.
echo   [网络]                                          [系统更新]
echo    1   查看完整网络配置  [IP/DNS/MAC/适配器]      19   禁用系统更新  [需管理员]
echo    2   快速查看 IP 地址与子网掩码                 20   启用系统更新  [需管理员]
echo    3   查看默认网关与 DNS 服务器
echo    4   保存网络配置到文件  [带时间戳]             [UAC 权限]
echo    5   刷新 DNS 并重新获取 IP  [网络修复]         21   禁用 UAC 提权弹窗  [需管理员, 重启生效]
echo    6   Ping 连通性测试                            22   启用 UAC 提权弹窗  [需管理员, 重启生效]
echo    7   查看路由表                                 23   查看当前 UAC 状态
echo    8   查看已保存的 Wi-Fi 密码
echo                                                   [桌面美化]
echo   [防火墙 / 端口]                                 24   去除快捷方式小箭头  [需管理员]
echo    9   查看防火墙状态  [域 / 专用 / 公用]         25   恢复快捷方式小箭头  [需管理员]
echo   10   开启防火墙  [全部配置文件, 需管理员]
echo   11   关闭防火墙  [全部配置文件, 需管理员]       [维护]
echo   12   放行入站端口  [需管理员]                   26   还原全部改动  [一键恢复, 需管理员]
echo   13   端口占用排查  [查询并可选结束进程]
echo                                                   [修复]
echo   [系统 / 硬件]                                   27   一键修复  [SFC/DISM/网络/图标, 子菜单]
echo   14   打开设备管理器
echo   15   查看详细硬件信息  [systeminfo, 较慢]       [电源 / 锁屏]
echo   16   检查 Windows 激活状态与许可证              28   禁止锁屏与休眠  [需管理员]
echo   17   检查远程桌面是否开启                       29   恢复锁屏与休眠默认  [需管理员]
echo   18   查看磁盘剩余空间
echo                                                   [快捷工具]
echo                                                   30   常用系统工具  [子菜单]
echo.
echo    0   退出
set "choice="
set /p choice=请输入序号后回车: 
call :NORM

if "%choice%"=="1"  goto NET_ALL
if "%choice%"=="2"  goto NET_IP
if "%choice%"=="3"  goto NET_GATEWAY
if "%choice%"=="4"  goto NET_SAVE
if "%choice%"=="5"  goto NET_FIX
if "%choice%"=="6"  goto NET_PING
if "%choice%"=="7"  goto NET_ROUTE
if "%choice%"=="8"  goto NET_WIFI
if "%choice%"=="9"  goto FW_STATUS
if "%choice%"=="10" goto FW_ON
if "%choice%"=="11" goto FW_OFF
if "%choice%"=="12" goto FW_ALLOW
if "%choice%"=="13" goto PORT_CHECK
if "%choice%"=="14" goto SYS_DEVMGMT
if "%choice%"=="15" goto SYS_INFO
if "%choice%"=="16" goto SYS_ACTIVATE
if "%choice%"=="17" goto SYS_RDP
if "%choice%"=="18" goto SYS_DISK
if "%choice%"=="19" goto UPD_OFF
if "%choice%"=="20" goto UPD_ON
if "%choice%"=="21" goto UAC_OFF
if "%choice%"=="22" goto UAC_ON
if "%choice%"=="23" goto UAC_STATUS
if "%choice%"=="24" goto ARROW_OFF
if "%choice%"=="25" goto ARROW_ON
if "%choice%"=="26" goto RESTORE_ALL
if "%choice%"=="27" goto FIX_MENU
if "%choice%"=="28" goto LOCK_OFF
if "%choice%"=="29" goto LOCK_ON
if "%choice%"=="30" goto TOOL_MENU
if "%choice%"=="0"  goto QUIT
echo.
echo   无效输入, 请输入 0-30 的序号。
set /a BADCNT+=1
if %BADCNT% GEQ 5 (
    echo.
    echo   连续 5 次无效输入, 自动退出。
    timeout /t 2 >nul
    goto QUIT
)
timeout /t 2 >nul
goto MENU

:: ---------------- 网络 ----------------

:NET_ALL
cls
echo -------------------- 完整网络配置 --------------------
ipconfig /all
goto DONE

:NET_IP
cls
echo -------------------- IP 地址与子网掩码 --------------------
ipconfig | findstr /i "IPv4 子网掩码"
goto DONE

:NET_GATEWAY
cls
echo -------------------- 默认网关与 DNS 服务器 --------------------
ipconfig | findstr /i "默认网关 DNS"
goto DONE

:NET_SAVE
cls
call :MAKE_STAMP
set "OUTFILE=%EXPORT_DIR%\网络配置_%STAMP%.txt"
ipconfig /all > "%OUTFILE%" 2>&1
if errorlevel 1 (
    echo   保存失败, 请检查目录权限。
) else (
    echo   已保存到:
    echo   %OUTFILE%
)
goto DONE

:NET_FIX
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 未检测到管理员权限, 部分操作会失败。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 网络修复中 --------------------
echo   [1/3] 刷新 DNS 缓存...
ipconfig /flushdns
echo.
echo   [2/3] 释放当前 IP...
ipconfig /release
echo.
echo   [3/3] 重新获取 IP...
ipconfig /renew
echo.
echo   操作完成。若仍异常, 可重启网卡或路由器。
goto DONE

:NET_PING
cls
echo -------------------- Ping 测试 --------------------
set "target="
set /p target=输入域名或 IP [回车默认 www.baidu.com]: 
if not defined target set "target=www.baidu.com"
echo.
ping %target% -n 4
goto DONE

:NET_ROUTE
cls
echo -------------------- 路由表 --------------------
route print
goto DONE

:NET_WIFI
cls
echo -------------------- 已保存的 Wi-Fi --------------------
netsh wlan show profiles
echo.
set "ssid="
set /p ssid=输入要查看密码的名称 [回车返回菜单]: 
if not defined ssid goto MENU
echo.
netsh wlan show profile name="%ssid%" key=clear | findstr /i "关键内容 安全密钥 Key Content Password"
if errorlevel 1 netsh wlan show profile name="%ssid%" key=clear
goto DONE

:: ---------------- 防火墙 / 端口 ----------------

:FW_STATUS
cls
echo -------------------- 防火墙状态 --------------------
netsh advfirewall show allprofiles state
echo.
echo   说明: Domain=域网络  Private=专用网络  Public=公用网络
echo         ON=开启  OFF=关闭
goto DONE

:FW_ON
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 开关防火墙需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 开启防火墙 --------------------
echo   将开启全部配置文件 [域 / 专用 / 公用] 的防火墙。
echo.
choice /c YN /n /m "确认开启全部配置文件防火墙? [Y=开启 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo.
netsh advfirewall set allprofiles state on
if errorlevel 1 (
    echo   [!] 操作失败, 请确认以管理员身份运行。
    goto DONE
)
echo.
echo   【验证】当前状态:
netsh advfirewall show allprofiles state
goto DONE

:FW_OFF
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 开关防火墙需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 关闭防火墙 --------------------
echo   [!] 将关闭全部配置文件的防火墙, 系统将对入站连接不设防。
echo       若只是某个程序被拦, 建议改用功能 12 放行端口。
echo.
choice /c YN /n /m "确认关闭全部配置文件防火墙? [Y=关闭 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo.
netsh advfirewall set allprofiles state off
if errorlevel 1 (
    echo   [!] 操作失败, 请确认以管理员身份运行。
    goto DONE
)
echo.
echo   【验证】当前状态:
netsh advfirewall show allprofiles state
echo.
echo   提示: 排查完成后请用功能 10 及时开启防火墙。
goto DONE

:FW_ALLOW
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 放行端口需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 放行入站端口 --------------------
echo   场景: 远程桌面 3389 / 代理 7897 / 自建服务等被防火墙拦截。
echo.
set "port="
set /p port=输入要放行的端口号 [回车返回]: 
call :NORM
if not defined port goto MENU
set "NONNUM="
for /f "delims=0123456789" %%x in ("%port%") do set "NONNUM=1"
if defined NONNUM (
    echo   [!] 端口必须是纯数字。
    goto DONE
)
echo.
set "proto="
set /p proto=协议 TCP / UDP [回车默认 TCP]: 
if not defined proto set "proto=TCP"
if /i "%proto%"=="T" set "proto=TCP"
if /i "%proto%"=="U" set "proto=UDP"
if /i not "%proto%"=="TCP" if /i not "%proto%"=="UDP" (
    echo   [!] 协议只支持 TCP 或 UDP。
    goto DONE
)
echo.
echo   正在添加规则: 入站 %proto% %port% 放行...
echo   [说明] 若已存在同名规则, 会先删除再重建。
netsh advfirewall firewall delete rule name="星君放行_%proto%_%port%" >nul 2>&1
netsh advfirewall firewall add rule name="星君放行_%proto%_%port%" dir=in action=allow protocol=%proto% localport=%port%
if errorlevel 1 (
    echo   [!] 添加失败, 请确认以管理员身份运行。
    goto DONE
)
echo.
echo   完成! 端口 %port% 的入站 %proto% 流量已放行。
echo   日后删除该规则, 以管理员运行:
echo     netsh advfirewall firewall delete rule name="星君放行_%proto%_%port%"
goto DONE

:PORT_CHECK
cls
echo -------------------- 端口占用排查 --------------------
set "port="
set /p port=输入要排查的端口号 [回车返回]: 
call :NORM
if not defined port goto MENU
set "NONNUM="
for /f "delims=0123456789" %%x in ("%port%") do set "NONNUM=1"
if defined NONNUM (
    echo   [!] 端口必须是纯数字。
    goto DONE
)
echo.
echo   正在查询端口 %port% 的占用情况...
echo.
netstat -ano | findstr /c:":%port% "
if errorlevel 1 (
    echo   该端口当前无任何占用。
    goto DONE
)
echo.
echo   上面最后一列数字就是 PID [进程编号]。
echo.
set "pid="
set /p pid=输入要结束的进程 PID [回车返回菜单]: 
call :NORM
if not defined pid goto MENU
set "NONNUM="
for /f "delims=0123456789" %%x in ("%pid%") do set "NONNUM=1"
if defined NONNUM (
    echo   [!] PID 必须是纯数字。
    goto DONE
)
echo.
echo   该 PID 对应的进程:
tasklist /fi "PID eq %pid%"
echo.
:: 挡住系统关键进程 —— 强制结束它们的后果不可接受(桌面消失 / 蓝屏)
set "PNAME="
for /f "tokens=1 delims=," %%n in ('tasklist /fi "PID eq %pid%" /fo csv /nh 2^>nul') do set "PNAME=%%~n"
for %%n in (explorer.exe winlogon.exe wininit.exe csrss.exe smss.exe services.exe lsass.exe dwm.exe sihost.exe fontdrvhost.exe svchost.exe) do (
    if /i "%PNAME%"=="%%n" goto KILL_BLOCKED
)
choice /c YN /n /m "确认强制结束上面列出的进程? [Y=结束 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
taskkill /f /pid %pid%
if errorlevel 1 (
    echo   [!] 结束失败。若提示拒绝访问, 请以管理员身份运行本工具。
    goto DONE
)
echo.
echo   已结束。再次运行本功能可确认端口已释放。
goto DONE

:: ---------------- 系统 / 硬件 ----------------

:SYS_DEVMGMT
cls
echo   正在打开设备管理器...
start devmgmt.msc
timeout /t 1 >nul
goto MENU

:SYS_INFO
cls
echo -------------------- 系统硬件信息 --------------------
echo   正在收集, 请稍候...
systeminfo
goto DONE

:SYS_ACTIVATE
cls
echo -------------------- Windows 激活状态 --------------------
echo.
echo   - 操作系统:
powershell -NoProfile -Command "$o=Get-CimInstance Win32_OperatingSystem; Write-Output ($o.Caption.Trim() + '  [内部版本 ' + $o.Version + ']')"
echo.
echo   - 许可证详情:
cscript //nologo "%windir%\system32\slmgr.vbs" /dli
echo.
echo   - 激活状态:
cscript //nologo "%windir%\system32\slmgr.vbs" /xpr
goto DONE

:SYS_RDP
cls
echo -------------------- 远程桌面状态 --------------------
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections
echo.
echo   说明:  0x0 = 已开启远程桌面     0x1 = 已关闭
echo.
echo   - 防火墙远程桌面规则:
netsh advfirewall firewall show rule name="Remote Desktop - User Mode (TCP-In)" >nul 2>&1
if errorlevel 1 (
    echo     未找到或已禁用。
) else (
    echo     规则存在。
)
goto DONE

:SYS_DISK
cls
echo -------------------- 磁盘剩余空间 --------------------
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { '{0}   总计 {1,6:N1} GB    剩余 {2,6:N1} GB' -f $_.DeviceID, ($_.Size/1GB), ($_.FreeSpace/1GB) }"
goto DONE

:: ---------------- 系统更新 ----------------

:UPD_OFF
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 禁用系统更新需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 禁用系统更新 --------------------
echo   [1/4] 停止并禁用 Windows Update 服务  wuauserv
call :SVC_OFF wuauserv
echo.
echo   [2/4] 停止并禁用后台智能传输服务  bits
call :SVC_OFF bits
echo.
echo   [3/4] 停止并禁用更新协调服务  UsoSvc
call :SVC_OFF UsoSvc
echo.
echo   [4/4] 禁用更新相关计划任务
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\ScheduledStart" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\Automatic App Update" /Disable >nul 2>&1
echo         计划任务已禁用。
echo.
echo   系统更新已禁用。
echo.
echo   说明: Windows Update Medic Service [WaaSMedicSvc] 受系统保护,
echo         本工具无法禁用它, 它仍可能把更新服务恢复回来。
echo         若发现更新再次生效, 重跑本功能即可。
goto DONE

:UPD_ON
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 启用系统更新需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 启用系统更新 --------------------
echo   [1/4] 启用 Windows Update 服务  wuauserv
call :SVC_ON wuauserv
echo.
echo   [2/4] 启用后台智能传输服务  bits
call :SVC_ON bits
echo.
echo   [3/4] 启用更新协调服务  UsoSvc
call :SVC_ON UsoSvc
echo.
echo   [4/4] 恢复更新相关计划任务
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\ScheduledStart" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\Automatic App Update" /Enable >nul 2>&1
echo         计划任务已恢复。
echo.
echo   系统更新已启用。
goto DONE

:: ---------------- UAC 权限 ----------------

:UAC_OFF
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 修改 UAC 需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 禁用 UAC 提权弹窗 --------------------
echo   原理: 注册表 EnableLUA 设为 0, 重启电脑后生效。
echo.
echo   [!] 禁用期间注意:
echo       1. 所有程序将静默获得管理员权限, 无任何拦截。
echo       2. 商店 / UWP 应用大概率打不开, 属正常现象。
echo       3. 用完请及时用功能 22 恢复启用。
echo.
choice /c YN /n /m "确认禁用 UAC 提权弹窗? [Y=禁用 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo.
reg add "%UAC_REG%" /v EnableLUA /t REG_DWORD /d 0 /f
if errorlevel 1 (
    echo   [!] 写注册表失败, 请确认以管理员身份运行。
    goto DONE
)
echo.
echo   【验证】当前 EnableLUA 值:
reg query "%UAC_REG%" /v EnableLUA 2>nul
echo.
echo   完成! 必须重启电脑后才会真正生效。
goto DONE

:UAC_ON
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 修改 UAC 需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 启用 UAC 提权弹窗 --------------------
echo   原理: 注册表 EnableLUA 设为 1, 重启电脑后生效。
echo   这是推荐的安全状态。
echo.
reg add "%UAC_REG%" /v EnableLUA /t REG_DWORD /d 1 /f
if errorlevel 1 (
    echo   [!] 写注册表失败, 请确认以管理员身份运行。
    goto DONE
)
echo.
echo   【验证】当前 EnableLUA 值:
reg query "%UAC_REG%" /v EnableLUA 2>nul
echo.
echo   完成! 必须重启电脑后 UAC 才会真正生效。
goto DONE

:UAC_STATUS
cls
echo -------------------- 当前 UAC 状态 --------------------
reg query "%UAC_REG%" /v EnableLUA 2>nul
if errorlevel 1 (
    echo   未找到 EnableLUA 键值, 系统默认视为 UAC 开启。
)
echo.
echo   说明:  0x1 = UAC 开启  [推荐]
echo          0x0 = UAC 禁用  [所有程序静默管理员权限]
goto DONE

:: ---------------- 桌面美化 ----------------

:ARROW_OFF
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 去除快捷方式箭头需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 去除快捷方式小箭头 --------------------
echo   原理: 把快捷方式左下角那个箭头图标, 换成一张接近透明的图标。
echo.
echo   [!] 本工具不会去动你的资源管理器。
echo       结束资源管理器会让桌面和任务栏消失几秒 —— 本地没事, 但远程协助时
echo       屏幕一黑连接就断了, 没法恢复。这个风险不值得让工具替你承担。
echo       所以: 改完之后需要注销再登录, 或者重启电脑, 才会生效。
echo.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /t REG_SZ /d "%windir%\System32\imageres.dll,197" /f
if errorlevel 1 (
    echo.
    echo   [!] 写注册表失败, 请确认以管理员身份运行。
    goto DONE
)
echo.
echo   注册表已改好。
echo   注销再登录, 或者重启电脑之后, 小箭头就没了。
goto DONE

:ARROW_ON
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 恢复快捷方式箭头需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 恢复快捷方式小箭头 --------------------
echo   [!] 同上: 本工具不会去动你的资源管理器。改完注销或重启后生效。
echo.
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 >nul 2>&1
if errorlevel 1 (
    echo   当前未去除箭头, 无需恢复。
    goto DONE
)
echo   正在还原注册表...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /f >nul 2>&1
echo.
echo   注册表已还原。注销再登录, 或者重启电脑之后, 小箭头就回来了。
goto DONE

:: ---------------- 维护 ----------------

:RESTORE_ALL
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 还原全部改动需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 还原全部改动 --------------------
echo   本功能会把下列改动一次性恢复为系统默认状态:
echo.
echo     1. 防火墙       开启 [域 / 专用 / 公用]
echo     2. 系统更新     启用 wuauserv / bits / UsoSvc 及计划任务
echo     3. UAC          启用提权弹窗 [EnableLUA = 1]
echo     4. 快捷方式箭头 恢复
echo     5. 放行规则     删除所有名为 星君放行_* 的入站规则
echo.
echo   不会动的: 导出的网络配置文件 [导出 目录]
echo.
choice /c YN /n /m "确认还原上面列出的全部改动? [Y=还原 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo.
echo   [1/5] 开启防火墙...
netsh advfirewall set allprofiles state on
netsh advfirewall show allprofiles state
echo.
echo   [2/5] 启用系统更新...
call :SVC_ON wuauserv
call :SVC_ON bits
call :SVC_ON UsoSvc
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\ScheduledStart" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\Automatic App Update" /Enable >nul 2>&1
echo         计划任务已恢复。
echo.
echo   [3/5] 启用 UAC 提权弹窗...
reg add "%UAC_REG%" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg query "%UAC_REG%" /v EnableLUA 2>nul
echo.
echo   [4/5] 恢复快捷方式箭头...
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 >nul 2>&1
if errorlevel 1 goto RA_NO_ARROW
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /f >nul 2>&1
echo         注册表项已删除, 注销或重启后生效。
goto RA_ARROW_DONE
:RA_NO_ARROW
echo         当前未去除箭头, 跳过。
:RA_ARROW_DONE
echo.
echo   [5/5] 删除 星君放行_* 防火墙规则...
set "FWRULE_N=0"
for /f "delims=" %%n in ('powershell -NoProfile -Command "@(Get-NetFirewallRule -DisplayName '星君放行_*' -ErrorAction SilentlyContinue).Count" 2^>nul') do set "FWRULE_N=%%n"
if "%FWRULE_N%"=="0" (
    echo         没有找到 星君放行_* 规则, 无需清理。
) else (
    powershell -NoProfile -Command "Get-NetFirewallRule -DisplayName '星君放行_*' -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue" >nul 2>&1
    if errorlevel 1 (
        echo         [!] 清理失败, 可手动运行: netsh advfirewall firewall delete rule name="星君放行_TCP_3389"
    ) else (
        echo         已删除 %FWRULE_N% 条 星君放行_* 规则。
    )
)
echo.
echo   全部改动已还原。
echo.
echo   提示: UAC 与系统更新的改动需要重启电脑后彻底生效。
goto DONE

:: ---------------- 修复 ----------------

:FIX_MENU
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 修复功能需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 一键修复 --------------------
echo   适用: 电脑卡顿 / 蓝屏 / 更新报错 / 上不了网 / 图标变白。
echo   全部调用 Windows 自带命令, 不联网、不装东西。
echo.
echo     1   全部修复  [系统文件 + 系统映像 + 网络 + 图标缓存]
echo     2   系统文件检查修复   sfc /scannow
echo     3   系统映像修复       DISM /RestoreHealth
echo     4   网络重置修复       winsock + ip reset + flushdns
echo     5   重建图标缓存  [给手动步骤]
echo.
echo     0   返回主菜单
echo.
echo   提示:
echo     - 2 和 3 很慢, 可能要 10-30 分钟, 中途别关窗口
echo     - 4 会重置网络设置, 完成后一般要重启电脑
echo.
:: 子菜单只有 6 个选项, 用 choice 单键选择 —— 不用敲回车, 也不会读不到输入
:: (实测重定向输入时, 同一个进程里只有第一次 set /p 能读到内容)
choice /c 123450 /n /m "请按键选择 [1-5=执行 / 0=返回主菜单]: "
if errorlevel 6 goto MENU
if errorlevel 5 goto FIX_ICON
if errorlevel 4 goto FIX_NET
if errorlevel 3 goto FIX_DISM
if errorlevel 2 goto FIX_SFC
goto FIX_ALL

:FIX_ALL
cls
echo -------------------- 一键修复全部 --------------------
echo   将依次执行:
echo     1. 系统文件检查修复   sfc /scannow
echo     2. 系统映像修复       DISM /RestoreHealth
echo     3. 网络重置修复       winsock + ip reset + flushdns
echo.
echo   [!] 整个过程可能要 20-40 分钟, 中途别关窗口。
echo.
set "sure="
choice /c YN /n /m "确认开始? [Y=开始 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo ========================================================
echo   [1/3] 系统文件检查修复  sfc /scannow
echo ========================================================
sfc /scannow
echo.
echo ========================================================
echo   [2/3] 系统映像修复  DISM /RestoreHealth
echo ========================================================
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo ========================================================
echo   [3/3] 网络重置修复
echo ========================================================
netsh winsock reset
netsh int ip reset
ipconfig /flushdns
echo.
echo   全部完成。
echo   网络设置已重置, 请重启电脑后生效。
goto DONE

:FIX_SFC
cls
echo -------------------- 系统文件检查修复 --------------------
echo   正在执行 sfc /scannow。
echo   可能要 5-20 分钟, 进度会显示在下面, 中途别关窗口。
echo.
sfc /scannow
echo.
echo   完成。若提示「无法修复某些文件」, 可以再跑一次功能 3 的 DISM。
goto DONE

:FIX_DISM
cls
echo -------------------- 系统映像修复 --------------------
echo   正在执行 DISM /Online /Cleanup-Image /RestoreHealth。
echo   可能要 10-30 分钟, 进度会显示在下面, 中途别关窗口。
echo.
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo   完成。这一步修的是系统映像, 建议之后再做一次功能 2 的 sfc。
goto DONE

:FIX_NET
cls
echo -------------------- 网络重置修复 --------------------
echo   适用: 能上 QQ 但打不开网页 / 网页加载异常 / DNS 解析不正常。
echo.
echo   [!] 会重置 Winsock 和 TCP/IP 设置, 完成后需要重启电脑。
echo.
set "sure="
choice /c YN /n /m "确认重置网络设置? [Y=重置 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo   [1/3] 重置 Winsock 目录...
netsh winsock reset
echo.
echo   [2/3] 重置 TCP/IP 协议栈...
netsh int ip reset
echo.
echo   [3/3] 刷新 DNS 缓存...
ipconfig /flushdns
echo.
echo   完成。请重启电脑后生效。
goto DONE

:FIX_ICON
cls
echo -------------------- 重建图标缓存 --------------------
echo   适用: 图标变白 / 图标错乱 / 显示成默认图标。
echo.
echo   [!] 这一步本工具不自动做, 原因:
echo       重建缓存必须先结束资源管理器, 才能删掉被它占用的缓存文件。
echo       而结束资源管理器会让桌面和任务栏消失几秒 —— 本地操作没事,
echo       但远程协助时屏幕一黑连接就断了, 没法恢复。所以不替你动它。
echo.
echo   手动操作 [安全做法, 不会黑屏]:
echo     1. 按 Ctrl + Shift + Esc 打开任务管理器
echo     2. 在「进程」里找到「Windows 资源管理器」
echo     3. 右键它, 选「重新启动」
echo     4. 桌面闪一下就会回来, 图标缓存同时重建
echo.
echo   如果做完图标还是不对, 重启一次电脑基本都能好。
echo.
pause
goto FIX_MENU

:: ---------------- 电源 / 锁屏 ----------------

:LOCK_OFF
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 改电源设置需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 禁止锁屏与休眠 --------------------
echo   适用: 远程协助时不想让对方电脑锁屏 / 挂机跑任务 / 长时间看东西。
echo.
echo   将做这些改动:
echo     1. 显示器永不自动关闭
echo     2. 电脑永不自动睡眠
echo     3. 关闭屏幕保护
echo     4. 唤醒时不再要求输入密码
echo     5. 取消系统层面的「无操作自动锁屏」限制
echo.
echo   注意: 这样电脑会一直耗电、屏幕常亮, 用完记得用功能 29 恢复。
echo.
set "sure="
choice /c YN /n /m "确认执行? [Y=执行 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo   [1/5] 显示器永不关闭...
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
echo   [2/5] 电脑永不睡眠...
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
echo   [3/5] 关闭屏幕保护...
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 0 /f >nul 2>&1
echo   [4/5] 唤醒时不要求密码...
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
echo   [5/5] 取消无操作自动锁屏限制...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f >nul 2>&1
echo.
echo   完成。
echo   提示: 如果屏幕保护是被组策略强制的, 这里可能改不动。
echo   部分笔记本在电池模式下还有厂商自己的省电策略, 会盖过这里的设置。
goto DONE

:LOCK_ON
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 改电源设置需要管理员权限。
    echo       请关闭本窗口后重新运行, 在 UAC 弹窗里点「是」。
    echo.
    pause
    goto MENU
)
echo -------------------- 恢复锁屏与休眠默认 --------------------
echo   将恢复为 Windows 常见的默认值:
echo     - 显示器 10 分钟自动关闭 [电池 5 分钟]
echo     - 电脑 30 分钟自动睡眠   [电池 15 分钟]
echo     - 唤醒时要求输入密码
echo     - 无操作自动锁屏限制 恢复为 15 分钟
echo.
echo   如果想让系统自己管, 也可以在「电源选项」里选回「平衡」计划。
echo.
set "sure="
choice /c YN /n /m "确认恢复? [Y=恢复 / N=取消] "
if errorlevel 2 (
    echo.
    echo   已取消。
    goto DONE
)
echo.
echo   [1/4] 显示器 10 分钟自动关闭...
powercfg /change monitor-timeout-ac 10
powercfg /change monitor-timeout-dc 5
echo   [2/4] 电脑 30 分钟自动睡眠...
powercfg /change standby-timeout-ac 30
powercfg /change standby-timeout-dc 15
echo   [3/4] 唤醒时要求输入密码...
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
echo   [4/4] 无操作自动锁屏限制 恢复为 15 分钟...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 900 /f >nul 2>&1
echo.
echo   完成。已恢复为常见的默认值。
goto DONE

:: ---------------- 快捷工具 ----------------

:TOOL_MENU
cls
echo -------------------- 常用系统工具 --------------------
echo   远程指导时, 省得让对方一层层点菜单找。
echo.
echo     1   事件查看器          eventvwr.msc      [看报错 / 蓝屏原因]
echo     2   系统配置 / 启动项    msconfig          [看开机启动项]
echo     3   服务                services.msc
echo     4   计算机管理          compmgmt.msc      [设备 / 磁盘 / 服务 / 事件]
echo     5   程序和功能          appwiz.cpl        [卸载软件]
echo     6   网络连接            ncpa.cpl          [网卡状态 / 改 IP]
echo     7   任务管理器          taskmgr
echo     8   电源选项            powercfg.cpl      [配合功能 28/29]
echo     9   上帝模式                              [集中了几乎所有系统设置]
echo.
echo     0   返回主菜单
echo.
:: 只有 10 个选项, 用 choice 单键选择
choice /c 1234567890 /n /m "请按键选择 [1-9=打开 / 0=返回主菜单]: "
if errorlevel 10 goto MENU
if errorlevel 9 goto TOOL_GODMODE
if errorlevel 8 goto TOOL_POWER
if errorlevel 7 goto TOOL_TASKMGR
if errorlevel 6 goto TOOL_NCPA
if errorlevel 5 goto TOOL_APPWIZ
if errorlevel 4 goto TOOL_COMPMGMT
if errorlevel 3 goto TOOL_SERVICES
if errorlevel 2 goto TOOL_MSCONFIG
goto TOOL_EVENTVWR

:TOOL_EVENTVWR
echo.
echo   正在打开 事件查看器...
start "" eventvwr.msc
goto TOOL_OPENED

:TOOL_MSCONFIG
echo.
echo   正在打开 系统配置...
start "" msconfig
goto TOOL_OPENED

:TOOL_SERVICES
echo.
echo   正在打开 服务...
start "" services.msc
goto TOOL_OPENED

:TOOL_COMPMGMT
echo.
echo   正在打开 计算机管理...
start "" compmgmt.msc
goto TOOL_OPENED

:TOOL_APPWIZ
echo.
echo   正在打开 程序和功能...
start "" appwiz.cpl
goto TOOL_OPENED

:TOOL_NCPA
echo.
echo   正在打开 网络连接...
start "" ncpa.cpl
goto TOOL_OPENED

:TOOL_TASKMGR
echo.
echo   正在打开 任务管理器...
start "" taskmgr
goto TOOL_OPENED

:TOOL_POWER
echo.
echo   正在打开 电源选项...
start "" powercfg.cpl
goto TOOL_OPENED

:TOOL_GODMODE
echo.
echo   正在打开 上帝模式 [第一次打开可能要几秒]...
start "" explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}
goto TOOL_OPENED

:TOOL_OPENED
echo.
echo   已打开。可以继续选别的, 或按 0 返回主菜单。
timeout /t 2 >nul
goto TOOL_MENU

:: ---------------- 公共子程序 ----------------

:NORM
:: 归一化输入: 去掉半角/全角空格, 全角数字转半角
:: 就地处理 choice / port / pid 三个变量, 未定义的跳过
if defined choice set "choice=%choice: =%"
if defined choice set "choice=%choice:　=%"
if defined choice set "choice=%choice:０=0%"
if defined choice set "choice=%choice:１=1%"
if defined choice set "choice=%choice:２=2%"
if defined choice set "choice=%choice:３=3%"
if defined choice set "choice=%choice:４=4%"
if defined choice set "choice=%choice:５=5%"
if defined choice set "choice=%choice:６=6%"
if defined choice set "choice=%choice:７=7%"
if defined choice set "choice=%choice:８=8%"
if defined choice set "choice=%choice:９=9%"
if defined port set "port=%port: =%"
if defined port set "port=%port:　=%"
if defined port set "port=%port:０=0%"
if defined port set "port=%port:１=1%"
if defined port set "port=%port:２=2%"
if defined port set "port=%port:３=3%"
if defined port set "port=%port:４=4%"
if defined port set "port=%port:５=5%"
if defined port set "port=%port:６=6%"
if defined port set "port=%port:７=7%"
if defined port set "port=%port:８=8%"
if defined port set "port=%port:９=9%"
if defined pid set "pid=%pid: =%"
if defined pid set "pid=%pid:　=%"
if defined pid set "pid=%pid:０=0%"
if defined pid set "pid=%pid:１=1%"
if defined pid set "pid=%pid:２=2%"
if defined pid set "pid=%pid:３=3%"
if defined pid set "pid=%pid:４=4%"
if defined pid set "pid=%pid:５=5%"
if defined pid set "pid=%pid:６=6%"
if defined pid set "pid=%pid:７=7%"
if defined pid set "pid=%pid:８=8%"
if defined pid set "pid=%pid:９=9%"
exit /b

:SVC_OFF
:: 停止并禁用服务. 用法: call :SVC_OFF 服务名
net stop %1 >nul 2>&1
sc config %1 start= disabled >nul 2>&1
if errorlevel 1 (
    echo         [!] 服务 %1 不存在或受系统保护, 已跳过。
    exit /b
)
set "SVCST="
for /f "tokens=3" %%s in ('sc query %1 ^| findstr /i "STATE"') do set "SVCST=%%s"
if "%SVCST%"=="1" (
    echo         %1  已停止, 启动类型 = 禁用
) else (
    echo         %1  启动类型 = 禁用 [当前仍在运行, 重启后彻底生效]
)
exit /b

:SVC_ON
:: 把服务恢复为自动启动. 用法: call :SVC_ON 服务名
sc config %1 start= auto >nul 2>&1
if errorlevel 1 (
    echo         [!] 服务 %1 不存在, 已跳过。
    exit /b
)
net start %1 >nul 2>&1
echo         %1  启动类型 = 自动
exit /b


:MAKE_STAMP
set "STAMP="
for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -format yyyyMMdd_HHmmss"') do set "STAMP=%%i"
if not defined STAMP set "STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
if not defined STAMP set "STAMP=export"
set "STAMP=%STAMP: =0%"
exit /b

:CHECK_ADMIN
:: 优先用 fsutil 判断 - 不依赖任何系统服务, 避免 Server 服务被停用时误判
:: net session 作为兜底, 两者任一通过即认为有管理员权限
set "IS_ADMIN=0"
fsutil dirty query %SystemDrive% >nul 2>&1
if not errorlevel 1 set "IS_ADMIN=1"
if "%IS_ADMIN%"=="1" exit /b
net session >nul 2>&1
if not errorlevel 1 set "IS_ADMIN=1"
exit /b

:KILL_BLOCKED
echo.
echo   [!] %PNAME% 是系统关键进程, 强制结束它会导致桌面消失或系统崩溃。
echo       已阻止, 没有结束任何进程。
echo.
echo   要重启资源管理器的话: 按 Ctrl + Shift + Esc 打开任务管理器,
echo   在「进程」里找到「Windows 资源管理器」, 右键选「重新启动」。
echo.
echo   要结束别的程序, 请重新输入它的 PID。
goto DONE

:DONE
set "BADCNT=0"
echo.
echo --------------------------------------------------------
pause
goto MENU

:QUIT
cls
echo ========================================================
echo    星君常用远程工具 v1.8
echo    作者: 星君 (Xingjun)  ｜  License: MIT
echo    感谢使用, 再见。
echo ========================================================
timeout /t 2 >nul
endlocal
exit /b 0
