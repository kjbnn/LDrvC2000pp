@echo off
cls
mode CON CP SELECT=1251 > nul

set prog_name=DrvC2000pp
set process_name=%prog_name%.exe
set exe_path=.\%prog_name%.exe
set log_file=.\%prog_name%_restart.log
echo %DATE% %TIME:~0,8% Старт %0 >> "%log_file%"

:loop
set dt=%DATE% %TIME:~0,8%

tasklist /fi "imagename eq %process_name%" | find /i "%process_name%" > nul
echo name_err: %errorlevel%
if %errorlevel% equ 1 (
	echo %dt% Процесс не найден, запускаем... >> "%log_file%"
	start "" "%exe_path%"
)

tasklist /fi "imagename eq %process_name%" /fi "status eq not responding" | find /i "%process_name%" > nul
echo status_err: %errorlevel%
if %errorlevel% equ 0 (
	echo %dt% Процесс завис, убиваем... >> "%log_file%"
	taskkill /f /im "%process_name%" >> "%log_file%"
	timeout /t 3 /nobreak >nul
	rundll32 user32.dll,MessageBeep
)

timeout /t 10 /nobreak >nul
goto loop
