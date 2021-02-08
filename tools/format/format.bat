@echo off
echo "clang-format..."

set PATH=%~dp0;%PATH%

CD /D "%~dp0..\..\projects\"
rem --- FROM HERE PASTE YOUR ADMIN-ENABLED BATCH SCRIPT ---

set ProjectDirName=%1

set DestDir=%~dp0..\..\projects\projects\%ProjectDirName%\

echo "%DestDir%"

for /F "delims=" %%i IN ( 'dir /A-D /s /b %DestDir%*.h %DestDir%*.cpp %DestDir%*.c %DestDir%*.cc %DestDir%*.cxx' ) do (
    clang-format -style=file -i %%i

    if "%errorlevel%"=="0" (
        echo "%%i"
    ) else (
        ping /n 1 127.0.0.1 >nul
    )
)

:END

exit /b