@echo off
echo "clang-format..."

set PATH=%~dp0;%PATH%

CD /D "%~dp0..\..\src\"
rem --- FROM HERE PASTE YOUR ADMIN-ENABLED BATCH SCRIPT ---

set DestDir=%1

if not "%2" == "" (
	if "%DestDir:~-2,1%"=="h" (
		echo %DestDir%
		clang-format -style=file -i %DestDir%
	)
	
	if "%DestDir:~-4,3%"=="cpp" (
		echo %DestDir%
		clang-format -style=file -i %DestDir%
	)
	
	if "%DestDir:~-3,2%"==".c" (
		echo %DestDir%
		clang-format -style=file -i %DestDir%
	)
	
    goto END
)

if "%1" == "" (
    set DestDir=%~dp0..\..\src\MiddleWare\
)

echo "%DestDir%"

for /F "delims=" %%i IN ( 'dir /A-D /s /b %DestDir%*.h %DestDir%*.cpp %DestDir%*.c %DestDir%*.cc %DestDir%*.cxx' ) do (
    clang-format -style=file -i %%i

    if "%errorlevel%"=="0" (
        echo "%%i"
    ) else (
        ping /n 1 127.0.0.1 >nul
    )
)

for /F "delims=" %%i IN ( 'dir /A-D /s /b %DestDir%\..\include\*.h' ) do (
    clang-format -style=file -i %%i

    if "%errorlevel%"=="0" (
        echo "%%i"
    ) else (
        ping /n 1 127.0.0.1 >nul
    )
)

:END

exit /b