@echo off
rem Startup script to map drive letter to network folder
rem Usage:
rem		catmap drive-letter network-folder
rem
rem Installation:
rem		Copy catmap.bat to %ProgramFiles%\catmap
rem		Create shortcut in %APPDATA%\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
rem		with target "%Program Files%\catmap\catmap.bat drive-letter network-folder"

if [%2]==[] (
	echo Usage: catmap drive-letter network-folder
	exit /b 1
)

rem subst command will fail until network folder available

:MAP
subst %1 %2
if not exist %1\ (
	ping -n 6 127.0.0.1 >nul
	goto MAP
)