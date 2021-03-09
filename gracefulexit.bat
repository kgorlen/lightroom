@echo off
rem
rem Kill tasks that lock shared files, then sleep, switch user, or log off
rem
rem Usage:
rem		gracefulexit {sleep|switch|lock} task1 task2 ...
rem
rem Installation:
rem		Customize location of FreeFileSync .ffs_batch file, if needed -- see below
rem		Copy gracefulexit.bat to C:\Program Files\gracefulexit
rem		Copy sleep.lnk, switch.lnk, lock.lnk, logoff.lnk to:
rem			C:\ProgramData\Microsoft\Windows\Start Menu\Programs\gracefulexit
rem		Pin GracefileExit -> sleep.lnk, switch.lnk, lock.lnk, logoff.lnk to Start Menu
rem		Control Panel->Hardware and Sound->Power Options->System Settings
rem			->Choose what the power button does: Disable Sleep and Lock menu items
rem		
rem Location of FreeFileSync .ffs_batch file:
set syncfile=%APPDATA%\FreeFileSync\Config\full.ffs_batch

rem	Version 2.2:
rem
rem 	Replace nircmd with Powershell
rem
rem	Version 2.1:
rem
rem 	Kill multiple instances of same task
rem		Replace faulting nircmd trayballon with Powershell command

if [%1]==[] (
	echo Usage: gracefulexit {sleep^|switch^|lock^|logoff} task1 task2 ...
	exit /b 1
)

setlocal EnableExtensions
setlocal EnableDelayedExpansion

if /i %1==sleep (
	set action=call :sleep
) else if /i %1==switch (
	set action=rundll32.exe user32.dll,LockWorkStation
) else if /i %1==lock (
rem LockWorkStation same as Switch User on Win10
	set action=rundll32.exe user32.dll,LockWorkStation
) else if /i %1==logoff (
	set action=shutdown -l
) else (
	set action=echo Unrecognized action: %1
)

:KILLTASKS
if [%2]==[] goto SYNCFILES
rem Some tasks (e.g. Quicken) will not close when minimized
	set pname=%2
	call :restore %pname:.exe=%
	for /f "tokens=1,11 delims=: " %%G in ('taskkill /fi "USERNAME eq %USERNAME%" /im %pname%') do (
		if %%G==SUCCESS (
			set pid=%%H
			set pid=!pid:.=!
			call :balloontip "GracefulExit %1" "Closing %pname% PID !pid! ..." 3000
			powershell -Command "Wait-Process -Id !pid!"
		)
	)
	shift /2
	goto KILLTASKS

:SYNCFILES
if exist %syncfile% (
	call :balloontip "GracefulExit %1" "Synchronizing files ..." 3000
	start "Synchronizing Files" /W "%ProgramFiles%\FreeFileSync\FreeFileSync.exe" "%syncfile%"
)

%action%
exit /b

:restore
rem Usage: call :restore Name
rem Reference:
rem		https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/show-or-hide-windows
rem		

powershell -Command "$ErrorActionPreference = 'SilentlyContinue'; $code = '[DllImport(\"user32.dll\")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'; $type = Add-Type -MemberDefinition $code -Name myAPI -PassThru; $process = Get-Process -Name '%~1'; $hwnd = $process.MainWindowHandle; $type::ShowWindowAsync($hwnd, 9)"
exit /b

:sleep
rem Usage: call :sleep
rem Reference:
rem		https://superuser.com/questions/39584/what-is-the-command-to-use-to-put-your-computer-to-sleep-not-hibernate

powershell -Command "Add-Type -Assembly System.Windows.Forms; [System.Windows.Forms.Application]::SetSuspendState('Suspend', $false, $true)"
exit /b

:balloontip
rem	Usage: call :balloontip Title TipText Delay
rem	Reference:
rem 	https://stackoverflow.com/questions/50927132/show-balloon-notifications-from-batch-file

powershell -Command "[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); $objNotifyIcon=New-Object System.Windows.Forms.NotifyIcon; $objNotifyIcon.BalloonTipText='%~2'; $objNotifyIcon.Icon=[system.drawing.systemicons]::Information; $objNotifyIcon.BalloonTipTitle='%~1'; $objNotifyIcon.BalloonTipIcon='None'; $objNotifyIcon.Visible=$True; $objNotifyIcon.ShowBalloonTip(%~3);"
exit /b
