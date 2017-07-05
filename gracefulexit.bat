@echo off
rem Kill tasks that lock shared files, then sleep, switch user, or lock session
rem Usage:
rem		gracefulexit {sleep|switch|lock} task1 task2 ...
rem
rem Installation:
rem		Copy gracefulexit.bat to C:\Program Files\gracefulexit
rem		Copy sleep.lnk, switch.lnk, lock.lnk, logoff.lnk to:
rem			C:\ProgramData\Microsoft\Windows\Start Menu\Programs\gracefulexit
rem		Install nircmd/nircmdc (http://www.nirsoft.net/utils/nircmd.html):
rem			Copy nircmd.exe, nircmdc.exe to C:\Windows\System32
rem		Control Panel->Hardware and Sound->Power Options->System Settings
rem			->Choose what the power button does: Disable Sleep and Lock menu items

if [%1]==[] (
	echo Usage: gracefulexit {sleep^|switch^|lock^|logoff} task1 task2 ...
	exit /b 1
)

setlocal EnableExtensions

if /i %1==sleep (
	set icon=shell32.dll,027
	set action=nircmd standby
) else if /i %1==switch (
	set icon=shell32.dll,238
	set action=nircmd lockws
) else if /i %1==lock (
	set icon=shell32.dll,047
rem Download and install tsdiscon.exe in %SystemRoot%\System32, if necessary.
rem	set action=%SystemRoot%\System32\tsdiscon.exe
rem Using LockWorkStation, since same as (missing) tsdiscon on Win10
rem Does NOT lock! -- same as tsdiscon.exe
	set action=nircmd lockws
) else if /i %1==logoff (
	set icon=shell32.dll,112
	set action=shutdown -l
) else (
	set icon=shell32.dll,221
	set action=echo Unrecognized action: %1
)

:KILLTASKS
if [%2]==[] goto SYNCFILES
rem Some tasks (e.g. Quicken) will not close when minimized
	nircmd win normal process %2
	for /f "tokens=1,11 delims=: " %%G in ('taskkill /fi "USERNAME eq %USERNAME%" /im %2') do (
		set result=%%G
		set pid=%%H
		)
	set pid=%pid:.=%
	if %result%==SUCCESS (
		nircmd trayballoon "GracefulExit %2" "Closing PID %pid%..." "%icon%" 3000
		nircmd waitprocess /%pid%
		)
	shift /2
	goto KILLTASKS

:SYNCFILES
set syncfile=%APPDATA%\FreeFileSync\Config\full.ffs_batch
if exist %syncfile% (
	nircmd trayballoon "GracefulExit" "Synchronizing files..." "%icon%" 3000
	start "Synchronizing Files" /W "%ProgramFiles%\FreeFileSync\FreeFileSync.exe" "%syncfile%"
)

%action%
