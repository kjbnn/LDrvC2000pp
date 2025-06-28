@echo off
if "%1" =="" (
	echo Use parameter ip address!
	exit /b
)
set host=%1
echo Host Address: %1 
set logfile=%host%.log

echo Target Host = %host% >> %logfile%
for /f "tokens=*" %%A in ('ping %host% -n 1 ') do (echo %%A>>%logfile% && GOTO Ping)
:Ping
for /f "tokens=* skip=2" %%A in ('ping %host% -n 1 ') do (
    echo %date% %time:~0,2%:%time:~3,2%:%time:~6,2% %%A>>%logfile%
    echo %date% %time:~0,2%:%time:~3,2%:%time:~6,2% %%A
    timeout 1 >NUL 
rem	TIMEOUT 4
    GOTO Ping)