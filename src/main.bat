@echo off
setlocal enabledelayedexpansion

set "FILE_PATH="
set "MESSAGE="
set "SIZE="
set "COMMAND_ARGS="

:show_help
	echo Usage: %~nx0 [OPTIONS] [COMMAND [ARGS...]]
	echo.
	echo Options:
	echo   -m, --message MESSAGE   Message to append to the file (required)
	echo   -p, --path FILE         Path to the file (without extension, required)
	echo   -s, --size SIZE         Max file size before rotating (e.g., 1M, 500K, 2G)
	echo   -h, --help              Show a help message
	echo.
	echo Any arguments after options are treated as a command to execute with its arguments.
	echo.
	echo Examples:
	echo   logwrapper -p logs\output.log -m "Hello World" -s 1M
	echo   logwrapper --path logs\%%DATE%%.log -m "Log entry %%TIME%%" dir
	exit /b 0

:size_to_bytes
	set "size=%~1"
	set "unit=%size:~-1%"
	set "number=%size:~0,-1%"
	if /i "%unit%"=="K" set /a bytes=%number%*1024 & goto :eof
	if /i "%unit%"=="M" set /a bytes=%number%*1024*1024 & goto :eof
	if /i "%unit%"=="G" set /a bytes=%number%*1024*1024*1024 & goto :eof
	if "%unit%"=="" set "bytes=%size%" & goto :eof
	echo Invalid size: %size%
	exit /b 1

:rotate_log
	set "file=%~1"
	set "max_bytes=%~2"
	if exist "%file%" (
		for /f "usebackq" %%A in (`powershell -Command "(Get-Item '%file%').Length"`) do set "filesize=%%A"
		if !filesize! GEQ %max_bytes% (
			set i=1
			:rotate_loop
			if exist "%file%.!i!" (
				set /a i+=1
				goto rotate_loop
			)
			move "%file%" "%file%.!i!" >nul
		)
	)
	exit /b 0

:parse_args
:loop
	if "%~1"=="" goto end_parse
	if "%~1"=="-m" set "MESSAGE=%~2" & shift & shift & goto loop
	if "%~1"=="--message" set "MESSAGE=%~2" & shift & shift & goto loop
	if "%~1"=="-p" set "FILE_PATH=%~2" & shift & shift & goto loop
	if "%~1"=="--path" set "FILE_PATH=%~2" & shift & shift & goto loop
	if "%~1"=="-s" set "SIZE=%~2" & shift & shift & goto loop
	if "%~1"=="--size" set "SIZE=%~2" & shift & shift & goto loop
	if "%~1"=="-h" call :show_help
	if "%~1"=="--help" call :show_help
	set "COMMAND_ARGS=%*"
	goto end_parse
:shift
	shift
	goto loop
:end_parse

	if "%FILE_PATH%"=="" (echo Error: --path is required. & exit /b 1)
	if "%MESSAGE%"=="" (echo Error: --message is required. & exit /b 1)

	for /f "tokens=*" %%D in ('powershell -Command "Get-Date -Format ''yyyy-MM-dd''"') do set "FILE_PATH_EXPANDED=%%D"
	if not "%FILE_PATH_EXPANDED%"=="" set "FILE_PATH_EXPANDED=%FILE_PATH_EXPANDED%"
	if "%FILE_PATH_EXPANDED%"=="" set "FILE_PATH_EXPANDED=%FILE_PATH%"

	for /f "tokens=*" %%D in ('powershell -Command "Get-Date -Format ''HH:mm:ss''"') do set "MESSAGE_EXPANDED=%%D"
	if not "%MESSAGE_EXPANDED%"=="" set "MESSAGE_EXPANDED=%MESSAGE%"
	if "%MESSAGE_EXPANDED%"=="" set "MESSAGE_EXPANDED=%MESSAGE%"

	if not "%COMMAND_ARGS%"=="" (
		for /f "delims=" %%O in ('%COMMAND_ARGS%') do set "CMD_OUTPUT=%%O"
	)

	set "MESSAGE_EXPANDED=%MESSAGE_EXPANDED:{nl=^
%=%"
	set "MESSAGE_EXPANDED=%MESSAGE_EXPANDED:{out=%CMD_OUTPUT%=%"

	for %%D in ("%FILE_PATH_EXPANDED%") do if not exist "%%~dpD" mkdir "%%~dpD"

	if not "%SIZE%"=="" (
		call :size_to_bytes "%SIZE%"
		call :rotate_log "%FILE_PATH_EXPANDED%" "!bytes!"
	)

	echo %MESSAGE_EXPANDED% >> "%FILE_PATH_EXPANDED%"
