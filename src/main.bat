@echo off
setlocal enabledelayedexpansion

set "FILE_PATH="
set "MESSAGE="
set "SIZE="
set "COMMAND_ARGS="

:parse_args
if "%~1"=="" goto after_args

if "%~1"=="-m"  set "MESSAGE=%~2" & shift & shift & goto parse_args
if "%~1"=="--message" set "MESSAGE=%~2" & shift & shift & goto parse_args

if "%~1"=="-p"  set "FILE_PATH=%~2" & shift & shift & goto parse_args
if "%~1"=="--path" set "FILE_PATH=%~2" & shift & shift & goto parse_args

if "%~1"=="-s"  set "SIZE=%~2" & shift & shift & goto parse_args
if "%~1"=="--size" set "SIZE=%~2" & shift & shift & goto parse_args

if "%~1"=="-h"  goto show_help
if "%~1"=="--help" goto show_help

set "COMMAND_ARGS=%*"
goto after_args

:after_args

if "%FILE_PATH%"=="" (
	echo Error: --path is required.
	exit /b 1
)
if "%MESSAGE%"=="" (
	echo Error: --message is required.
	exit /b 1
)

for /f "tokens=1-4 delims=/-. " %%a in ("%date%") do (
	set "D1=%%a"
	set "D2=%%b"
	set "D3=%%c"
)

if "!D1!" gtr "31" (
	set "YYYY=!D1!"
	set "MM=!D2!"
	set "DD=!D3!"
) else (
	set "DD=!D1!"
	set "MM=!D2!"
	set "YYYY=!D3!"
)

for /f "tokens=1-2 delims=: " %%a in ("%time%") do (
	set "HH=%%a"
	set "MN=%%b"
)

set "FILE_PATH_EXPANDED=%FILE_PATH%"
set "MESSAGE_EXPANDED=%MESSAGE%"

set "FILE_PATH_EXPANDED=!FILE_PATH_EXPANDED:%%Y=!%YYYY%!"
set "FILE_PATH_EXPANDED=!FILE_PATH_EXPANDED:%%m=!%MM%!"
set "FILE_PATH_EXPANDED=!FILE_PATH_EXPANDED:%%d=!%DD%!"
set "FILE_PATH_EXPANDED=!FILE_PATH_EXPANDED:%%H=!%HH%!"
set "FILE_PATH_EXPANDED=!FILE_PATH_EXPANDED:%%M=!%MN%!"

set "MESSAGE_EXPANDED=!MESSAGE_EXPANDED:%%Y=!%YYYY%!"
set "MESSAGE_EXPANDED=!MESSAGE_EXPANDED:%%m=!%MM%!"
set "MESSAGE_EXPANDED=!MESSAGE_EXPANDED:%%d=!%DD%!"
set "MESSAGE_EXPANDED=!MESSAGE_EXPANDED:%%H=!%HH%!"
set "MESSAGE_EXPANDED=!MESSAGE_EXPANDED:%%M=!%MN%!"

set "FILE_PATH_EXPANDED=%FILE_PATH_EXPANDED%.log"

set "CMD_OUTPUT="

if not "%COMMAND_ARGS%"=="" (
	for /f "delims=" %%A in ('%COMMAND_ARGS%') do (
		set "CMD_OUTPUT=!CMD_OUTPUT!%%A\r\n"
	)
	echo(!CMD_OUTPUT!
)

set "MESSAGE_EXPANDED=!MESSAGE_EXPANDED:{out}=!CMD_OUTPUT!!"

set "TMPMSG=!MESSAGE_EXPANDED!"
set "TMPMSG=!TMPMSG:{nl}=#NL#!"

set "OUTPUT_FILE=%temp%\_msg.tmp"
> "%OUTPUT_FILE%" (
	for %%L in ("!TMPMSG:#NL#=" "!") do (
		echo %%~L
	)
)

for %%D in ("%FILE_PATH_EXPANDED%") do (
	if not exist "%%~dpD" mkdir "%%~dpD"
)

set "MAX_BYTES="
if not "%SIZE%"=="" (
	set "S=%SIZE%"
	set "NUM=%S:~0,-1%"
	set "UNIT=%S:~-1%"

	if /i "%UNIT%"=="K" set /a MAX_BYTES=%NUM%*1024
	if /i "%UNIT%"=="M" set /a MAX_BYTES=%NUM%*1024*1024
	if /i "%UNIT%"=="G" set /a MAX_BYTES=%NUM%*1024*1024*1024
)

if defined MAX_BYTES (
	if exist "%FILE_PATH_EXPANDED%" (
		for %%A in ("%FILE_PATH_EXPANDED%") do set "SIZE_NOW=%%~zA"
		if !SIZE_NOW! GEQ !MAX_BYTES! (
			set i=1
			:rot_loop
			if exist "%FILE_PATH_EXPANDED%.!i!" (
				set /a i+=1
				goto rot_loop
			)
			move "%FILE_PATH_EXPANDED%" "%FILE_PATH_EXPANDED%.!i!" >nul
		)
	)
)

type "%OUTPUT_FILE%" >> "%FILE_PATH_EXPANDED%"

exit /b 0

:show_help
echo Usage: logwrapper.bat [OPTIONS] [COMMAND [ARGS...]]
echo.
echo Options:
echo   -m, --message MESSAGE   Message to append to the file (required)
echo   -p, --path FILE         Path to the file (without extension, required)
echo   -s, --size SIZE         Rotate at size (1M, 500K, 2G)
echo   -h, --help              Show help
echo.
exit /b 0
