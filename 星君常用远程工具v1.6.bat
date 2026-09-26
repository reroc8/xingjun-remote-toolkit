@echo off
:: ============================================================
::  星君常用远程工具 v1.6
::  作者  : 星君 (Xingjun)  |  gp45.ys168.com
::  许可  : MIT License    |  更新日期: 2026-09-25
::  声明  : 本工具仅修改本机配置, 部分功能需管理员权限,
::          使用前请阅读同目录 README 中的注意事项。
:: ============================================================
setlocal EnableExtensions
chcp 936 >nul 2>&1
title 星君常用远程工具 v1.6  -  作者: 星君
color 0A

set "EXPORT_DIR=%~dp0导出"
if not exist "%EXPORT_DIR%" mkdir "%EXPORT_DIR%" >nul 2>&1
set "UAC_REG=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

:MENU
cls
echo ========================================================
echo    [星君] gp45.ys168.com  常用远程工具 v1.6
echo    ---  网络 / 防火墙 / 系统 / UAC / 桌面管理  ---
echo    作者: 星君 (Xingjun)  |  License: MIT
echo ========================================================
echo.
echo   [网络]
echo    1   查看完整网络配置  [IP / DNS / MAC / 适配器]
echo    2   快速查看 IP 地址与子网掩码
echo    3   查看默认网关与 DNS 服务器
echo    4   保存网络配置到文件  [带时间戳]
echo    5   刷新 DNS 并重新获取 IP  [网络修复]
echo    6   Ping 连通性测试
echo    7   查看路由表
echo    8   查看已保存的 Wi-Fi 密码
echo.
echo   [防火墙 / 端口]
echo    9   查看防火墙状态  [域 / 专用 / 公用]
echo   10   开启防火墙  [全部配置文件, 需管理员]
echo   11   关闭防火墙  [全部配置文件, 需管理员]
echo   12   放行入站端口  [需管理员]
echo   13   端口占用排查  [查询并可选结束进程]
echo.
echo   [系统 / 硬件]
echo   14   打开设备管理器
echo   15   查看详细硬件信息  [systeminfo, 较慢]
echo   16   检查 Windows 激活状态与许可证
echo   17   检查远程桌面是否开启
echo   18   查看磁盘剩余空间
echo.
echo   [系统更新]
echo   19   禁用系统更新  [需管理员]
echo   20   启用系统更新  [需管理员]
echo.
echo   [UAC 权限]
echo   21   禁用 UAC 提权弹窗  [需管理员, 重启生效]
echo   22   启用 UAC 提权弹窗  [需管理员, 重启生效]
echo   23   查看当前 UAC 状态
echo.
echo   [桌面美化]
echo   24   去除快捷方式小箭头  [需管理员]
echo   25   恢复快捷方式小箭头  [需管理员]
echo.
echo    0   退出
echo.
set "choice="
set /p choice=请输入序号后回车: 

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
if "%choice%"=="0"  goto QUIT
echo.
echo   无效输入, 请输入 0-25 的序号。
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
    echo       请右键本文件 - 以管理员身份运行。
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
    echo       请右键本文件 - 以管理员身份运行。
    echo.
    pause
    goto MENU
)
echo -------------------- 开启防火墙 --------------------
echo   将开启全部配置文件 [域 / 专用 / 公用] 的防火墙。
echo.
set /p sure=确认开启请输入 Y, 其他键取消: 
if /i not "%sure%"=="Y" (
    echo   已取消。
    goto DONE
)
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
    echo       请右键本文件 - 以管理员身份运行。
    echo.
    pause
    goto MENU
)
echo -------------------- 关闭防火墙 --------------------
echo   [!] 将关闭全部配置文件的防火墙, 系统将对入站连接不设防。
echo       若只是某个程序被拦, 建议改用功能 12 放行端口。
echo.
set /p sure=确认关闭请输入 OFF, 其他键取消: 
if /i not "%sure%"=="OFF" (
    echo   已取消。
    goto DONE
)
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
    echo       请右键本文件 - 以管理员身份运行。
    echo.
    pause
    goto MENU
)
echo -------------------- 放行入站端口 --------------------
echo   场景: 远程桌面 3389 / 代理 7897 / 自建服务等被防火墙拦截。
echo.
set "port="
set /p port=输入要放行的端口号 [回车返回]: 
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
netstat -ano | findstr /r /c:":%port% "
if errorlevel 1 (
    echo   该端口当前无任何占用。
    goto DONE
)
echo.
echo   上面最后一列数字就是 PID [进程编号]。
echo.
set "pid="
set /p pid=输入要结束的进程 PID [回车返回菜单]: 
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
set "sure="
set /p sure=确认强制结束该进程? 输入 Y 确认, 其他键取消: 
if /i not "%sure%"=="Y" (
    echo   已取消。
    goto DONE
)
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
    echo       请右键本文件 - 以管理员身份运行。
    echo.
    pause
    goto MENU
)
echo -------------------- 禁用系统更新 --------------------
echo   [1/3] 停止并禁用 Windows Update 服务...
net stop wuauserv
sc config wuauserv start= disabled
echo.
echo   [2/3] 停止并禁用后台智能传输服务 BITS...
net stop bits
sc config bits start= disabled
echo.
echo   [3/3] 禁用更新相关计划任务...
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\ScheduledStart" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\Automatic App Update" /Disable >nul 2>&1
echo.
echo   系统更新已禁用。
echo   提示: 部分系统版本会自动恢复更新服务, 若更新再次生效可重跑一次本功能。
goto DONE

:UPD_ON
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 启用系统更新需要管理员权限。
    echo       请右键本文件 - 以管理员身份运行。
    echo.
    pause
    goto MENU
)
echo -------------------- 启用系统更新 --------------------
echo   [1/3] 启用 Windows Update 服务...
sc config wuauserv start= auto
net start wuauserv
echo.
echo   [2/3] 启用后台智能传输服务 BITS...
sc config bits start= auto
net start bits
echo.
echo   [3/3] 恢复更新相关计划任务...
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\ScheduledStart" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\Automatic App Update" /Enable >nul 2>&1
echo.
echo   系统更新已启用。
goto DONE

:: ---------------- UAC 权限 ----------------

:UAC_OFF
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 修改 UAC 需要管理员权限。
    echo       请右键本文件 - 以管理员身份运行。
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
set /p sure=确认禁用请输入 Y, 其他键取消: 
if /i not "%sure%"=="Y" (
    echo   已取消。
    goto DONE
)
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
    echo       请右键本文件 - 以管理员身份运行。
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
    echo       请右键本文件 - 以管理员身份运行。
    echo.
    pause
    goto MENU
)
echo -------------------- 去除快捷方式箭头 --------------------
echo   原理: 将快捷方式图标替换为透明图标, 并重启资源管理器。
echo   桌面和任务栏会闪一下, 属正常现象。
echo.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /t REG_SZ /d "%windir%\System32\imageres.dll,-1970" /f
if errorlevel 1 (
    echo.
    echo   [!] 写注册表失败, 请确认以管理员身份运行。
    goto DONE
)
echo.
echo   正在重启资源管理器...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo.
echo   完成, 快捷方式小箭头已去除。
goto DONE

:ARROW_ON
cls
call :CHECK_ADMIN
if "%IS_ADMIN%"=="0" (
    echo   [!] 恢复快捷方式箭头需要管理员权限。
    echo       请右键本文件 - 以管理员身份运行。
    echo.
    pause
    goto MENU
)
echo -------------------- 恢复快捷方式箭头 --------------------
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 >nul 2>&1
if errorlevel 1 (
    echo   当前未去除箭头, 无需恢复。
    goto DONE
)
echo   正在还原注册表...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /f >nul 2>&1
echo   正在重启资源管理器...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo.
echo   完成, 快捷方式小箭头已恢复。
goto DONE

:: ---------------- 公共子程序 ----------------

:MAKE_STAMP
set "STAMP="
for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -format yyyyMMdd_HHmmss"') do set "STAMP=%%i"
if not defined STAMP set "STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
if not defined STAMP set "STAMP=export"
set "STAMP=%STAMP: =0%"
exit /b

:CHECK_ADMIN
net session >nul 2>&1
if errorlevel 1 (set "IS_ADMIN=0") else (set "IS_ADMIN=1")
exit /b

:DONE
echo.
echo --------------------------------------------------------
pause
goto MENU

:QUIT
cls
echo ========================================================
echo    星君常用远程工具 v1.6
echo    作者: 星君 (Xingjun)  |  License: MIT
echo    感谢使用, 再见。
echo ========================================================
timeout /t 2 >nul
endlocal
exit /b 0
