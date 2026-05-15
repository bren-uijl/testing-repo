@echo off
setlocal enabledelayedexpansion

:: Nexus Browser - Windows Offline Installer
:: Version 1.0.0

echo.
echo ========================================
echo    Nexus Browser Installer v1.0.0
echo ========================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] This installer works best with administrator privileges.
    echo          Some features may require elevated permissions.
    echo.
)

:: Check if Node.js is installed
where node >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Node.js not detected. Installing bundled runtime...
    echo.

    :: Set installation directory
    set "INSTALL_DIR=%ProgramFiles%\NexusBrowser"
    if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

    :: Check for bundled Node.js
    if exist "runtime\node.exe" (
        echo [OK] Using bundled Node.js runtime
        copy /Y "runtime\node.exe" "%INSTALL_DIR%\node.exe" >nul
        copy /Y "runtime\npm.cmd" "%INSTALL_DIR%\npm.cmd" >nul
        copy /Y "runtime\npm" "%INSTALL_DIR%\npm" >nul
        set "NODE_PATH=%INSTALL_DIR%"
    ) else (
        echo [ERROR] Node.js is required to run Nexus Browser.
        echo         Please install Node.js from https://nodejs.org
        echo         and run this installer again.
        echo.
        pause
        exit /b 1
    )
) else (
    echo [OK] Node.js detected
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo      Version: %NODE_VERSION%
    set "NODE_PATH="
)

:: Set installation directory
set "INSTALL_DIR=%ProgramFiles%\NexusBrowser"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo.
echo Installing Nexus Browser to: %INSTALL_DIR%
echo.

:: Copy application files
echo [1/4] Copying application files...
xcopy /E /I /Y "src" "%INSTALL_DIR%\src" >nul
copy /Y "package.json" "%INSTALL_DIR%\package.json" >nul
echo      Done

:: Install dependencies (offline if possible)
echo [2/4] Setting up dependencies...
if exist "node_modules" (
    xcopy /E /I /Y "node_modules" "%INSTALL_DIR%\node_modules" >nul
    echo      Using bundled dependencies
) else (
    echo      Note: Run 'npm install' in %INSTALL_DIR% to fetch dependencies
)
echo      Done

:: Create launch script
echo [3/4] Creating launch script...
(
echo @echo off
echo setlocal
echo.
echo :: Nexus Browser Launcher
echo set "NEXUS_DIR=%INSTALL_DIR%"
echo.
echo :: Use bundled Node.js if available
echo if exist "%%NEXUS_DIR%%\node.exe" (
echo     set "PATH=%%NEXUS_DIR%%;%%PATH%%"
echo ^)
echo.
echo cd /d "%%NEXUS_DIR%%"
echo node src\main.js %%*
) > "%INSTALL_DIR%\nexus.bat"
echo      Done

:: Create shortcuts
echo [4/4] Creating shortcuts...

:: Start Menu shortcut
set "START_MENU=%ProgramData%\Microsoft\Windows\Start Menu\Programs"
if not exist "%START_MENU%\Nexus Browser" mkdir "%START_MENU%\Nexus Browser"

(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set shortcut = WshShell.CreateShortcut("%START_MENU%\Nexus Browser\Nexus Browser.lnk"^)
echo shortcut.TargetPath = "%INSTALL_DIR%\nexus.bat"
echo shortcut.WorkingDirectory = "%INSTALL_DIR%"
echo shortcut.Description = "Nexus Browser"
echo shortcut.Save
) > "%TEMP%\create_shortcut.vbs"
cscript //nologo "%TEMP%\create_shortcut.vbs" >nul
del "%TEMP%\create_shortcut.vbs" >nul

:: Desktop shortcut
set "DESKTOP=%PUBLIC%\Desktop"
if not exist "%DESKTOP%" set "DESKTOP=%USERPROFILE%\Desktop"

(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set shortcut = WshShell.CreateShortcut("%DESKTOP%\Nexus Browser.lnk"^)
echo shortcut.TargetPath = "%INSTALL_DIR%\nexus.bat"
echo shortcut.WorkingDirectory = "%INSTALL_DIR%"
echo shortcut.Description = "Nexus Browser"
echo shortcut.Save
) > "%TEMP%\create_desktop.vbs"
cscript //nologo "%TEMP%\create_desktop.vbs" >nul
del "%TEMP%\create_desktop.vbs" >nul

echo      Done

:: Add to PATH (optional)
echo.
echo [OPTIONAL] Add Nexus Browser to system PATH?
set /p ADD_PATH="Add to PATH? (Y/N): "
if /i "%ADD_PATH%"=="Y" (
    setx PATH "%PATH%;%INSTALL_DIR%" >nul 2>&1
    echo      Added to PATH
)

echo.
echo ========================================
echo    Installation Complete!
echo ========================================
echo.
echo Nexus Browser has been installed to:
echo   %INSTALL_DIR%
echo.
echo You can launch it from:
echo   - Start Menu ^> Nexus Browser
echo   - Desktop shortcut
echo   - Command: nexus (if added to PATH)
echo.
echo To update dependencies, run:
echo   cd %INSTALL_DIR%
echo   npm install
echo.
pause
