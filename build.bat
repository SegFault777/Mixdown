@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem Mixdown - Windows build script
rem
rem   Double-click it      : asks which build you want, then builds.
rem   From a command line  : build.bat C:\Qt\5.15.2\msvc2019_64 5      (Windows 7 / 8 / 8.1)
rem                          build.bat C:\Qt\6.5.3\msvc2019_64 6       (Windows 10 or later)
rem
rem Visual Studio is found automatically (2019 or newer, "Desktop development with C++").
rem The installer needs Inno Setup 6 (iscc.exe on PATH); without it only the
rem program folder dist\win-qtN is produced.

set "RC=0"
set "INTERACTIVE="
set "QTDIR=%~1"
set "QTMAJOR=%~2"
if "%~1"=="" set "INTERACTIVE=1"

if "%QTDIR%"=="" if "%QTMAJOR%"=="" goto ask
if "%QTDIR%"=="" goto usage
if "%QTMAJOR%"=="" goto usage
goto check

:ask
echo.
echo ===== Mixdown build =====
echo   [1] Windows 7 / 8 / 8.1  - Qt 5.15, 64-bit
echo   [2] Windows 10 or later  - Qt 6.5, 64-bit
echo.
set "CHOICE="
set /p "CHOICE=Enter 1 or 2: "
if "%CHOICE%"=="1" set "QTMAJOR=5"
if "%CHOICE%"=="2" set "QTMAJOR=6"
if "%QTMAJOR%"=="" goto usage
if "%QTMAJOR%"=="5" set "QTDIR=C:\Qt\5.15.2\msvc2019_64"
if "%QTMAJOR%"=="6" set "QTDIR=C:\Qt\6.5.3\msvc2019_64"
if exist "%QTDIR%\bin\qmake.exe" goto check
echo.
echo Qt was not found in the default folder: %QTDIR%
set "QTDIR="
set /p "QTDIR=Type your Qt folder, for example C:\Qt\5.15.2\msvc2019_64: "
set "QTDIR=%QTDIR:"=%"

:check
if not exist "%QTDIR%\bin\qmake.exe" goto noqt
where nmake >nul 2>nul
if not errorlevel 1 goto havenmake
set "VSDIR="
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR goto nonmake
if not exist "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" goto nonmake
echo Setting up the Visual Studio build environment...
call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul
where nmake >nul 2>nul
if errorlevel 1 goto nonmake

:havenmake
set "PATH=%QTDIR%\bin;%PATH%"
set "BUILDDIR=build\win-qt%QTMAJOR%"
set "OUTDIR=dist\win-qt%QTMAJOR%"
if exist "%BUILDDIR%" rmdir /s /q "%BUILDDIR%"
if exist "%OUTDIR%" rmdir /s /q "%OUTDIR%"
mkdir "%BUILDDIR%"
mkdir "%OUTDIR%"

echo.
echo [1/4] Running qmake...
pushd "%BUILDDIR%"
qmake ..\..\Mixdown.pro -spec win32-msvc "CONFIG+=release"
if errorlevel 1 goto fail_popd
echo.
echo [2/4] Compiling (this can take a few minutes)...
nmake release
if errorlevel 1 goto fail_popd
popd

echo.
echo [3/4] Collecting Qt files with windeployqt...
copy /y "%BUILDDIR%\release\Mixdown.exe" "%OUTDIR%\" >nul
if errorlevel 1 goto fail
windeployqt --release --no-translations --compiler-runtime --dir "%OUTDIR%" "%OUTDIR%\Mixdown.exe"
if errorlevel 1 goto fail

echo.
echo [4/4] Building the installer...
where iscc >nul 2>nul
if errorlevel 1 goto noiscc
iscc /DQtMajor=%QTMAJOR% packaging\windows\mixdown.iss
if errorlevel 1 goto fail
echo.
echo Done: dist\Mixdown-1.0.0-win-qt%QTMAJOR%-setup.exe
goto finish

:noiscc
echo.
echo Inno Setup was not found (iscc.exe is not on PATH), so no installer was built.
echo The program folder is ready: %OUTDIR%
goto finish

:usage
echo.
echo Usage: build.bat ^<Qt directory^> ^<5 or 6^>
echo Example: build.bat C:\Qt\5.15.2\msvc2019_64 5
set "RC=1"
goto finish

:noqt
echo.
echo ERROR: qmake.exe was not found in "%QTDIR%\bin".
echo Check the Qt folder (it must be the MSVC 64-bit kit, e.g. C:\Qt\5.15.2\msvc2019_64).
set "RC=1"
goto finish

:nonmake
echo.
echo ERROR: the Visual C++ build tools (nmake) were not found.
echo Install Visual Studio 2019 or newer (or its Build Tools) with "Desktop development with C++",
echo or run this script from "x64 Native Tools Command Prompt for VS".
echo (No Visual Studio? Use the cloud build described in README.md instead.)
set "RC=1"
goto finish

:fail_popd
popd
:fail
echo.
echo Build failed. Read the messages above.
set "RC=1"

:finish
echo.
if defined INTERACTIVE pause
exit /b %RC%
