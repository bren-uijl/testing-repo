@echo off
setlocal enabledelayedexpansion

:: Nexus Browser - Windows Offline Installer (Full Bundle)
:: This script creates a self-contained installer package
:: Usage: setup-full.bat

echo.
echo ========================================
echo    Nexus Browser - Full Installer
echo ========================================
echo.

:: Configuration
set "APP_NAME=Nexus Browser"
set "APP_VERSION=1.0.0"
set "INSTALL_DIR=%ProgramFiles%\NexusBrowser"
set "TEMP_DIR=%TEMP%\nexus_install"

:: Clean up temp directory
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

:: Welcome
echo Installing %APP_NAME% v%APP_VERSION%
echo.
echo This installer will:
echo   - Install Nexus Browser to %INSTALL_DIR%
echo   - Create Start Menu and Desktop shortcuts
echo   - Register file associations (optional)
echo.

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Administrator privileges recommended for full installation.
    echo.
)

:: Create installation directory
echo [1/5] Preparing installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo      OK

:: Copy core files
echo [2/5] Installing application files...

:: Create directory structure
mkdir "%INSTALL_DIR%\src\ui" 2>nul
mkdir "%INSTALL_DIR%\src\extensions" 2>nul
mkdir "%INSTALL_DIR%\src\features" 2>nul
mkdir "%INSTALL_DIR%\assets" 2>nul

:: Copy source files (from same directory as installer)
set "SCRIPT_DIR=%~dp0"
set "SOURCE_DIR=%SCRIPT_DIR%..\.."

if exist "%SOURCE_DIR%\src" (
    xcopy /E /I /Y "%SOURCE_DIR%\src" "%INSTALL_DIR%\src" >nul
    copy /Y "%SOURCE_DIR%\package.json" "%INSTALL_DIR%\package.json" >nul
    echo      Application files copied
) else (
    echo      [!] Source files not found in expected location
    echo          Please ensure the installer is in the installers/windows folder
)

:: Install dependencies
echo [3/5] Setting up runtime dependencies...

:: Check for Node.js
where node >nul 2>&1
if %errorLevel% equ 0 (
    echo      Node.js detected, installing dependencies...
    cd /d "%INSTALL_DIR%"
    call npm install --production 2>nul
    if !errorLevel! equ 0 (
        echo      Dependencies installed
    ) else (
        echo      [!] Failed to install dependencies automatically
        echo          Run 'npm install' manually in %INSTALL_DIR%
    )
) else (
    echo      [!] Node.js not found
    echo          The application requires Node.js to run
    echo          Download from: https://nodejs.org
)

:: Create launcher
echo [4/5] Creating launcher...

:: Main launcher batch file
(
echo @echo off
echo :: Nexus Browser Launcher v%APP_VERSION%
echo setlocal
echo.
echo set "NEXUS_HOME=%INSTALL_DIR%"
echo.
echo :: Check for Node.js
echo where node ^>nul 2^>^&1
echo if %%errorLevel%% neq 0 (
echo     echo [ERROR] Node.js is required to run Nexus Browser.
echo     echo         Please install from https://nodejs.org
echo     pause
echo     exit /b 1
echo ^)
echo.
echo :: Launch application
echo cd /d "%%NEXUS_HOME%%"
echo node --no-warnings src\main.js %%*
) > "%INSTALL_DIR%\NexusBrowser.bat"

:: Create VBScript launcher (no console window)
(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo WshShell.Run "%INSTALL_DIR%\NexusBrowser.bat", 0, False
) > "%INSTALL_DIR%\NexusBrowser.vbs"

echo      Launcher created

:: Create shortcuts
echo [5/5] Creating shortcuts...

:: Start Menu
set "START_MENU=%ProgramData%\Microsoft\Windows\Start Menu\Programs\Nexus Browser"
if not exist "%START_MENU%" mkdir "%START_MENU%"

(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set oShellLink = WshShell.CreateShortcut("%START_MENU%\Nexus Browser.lnk"^)
echo oShellLink.TargetPath = "%INSTALL_DIR%\NexusBrowser.vbs"
echo oShellLink.WorkingDirectory = "%INSTALL_DIR%"
echo oShellLink.Description = "Nexus Browser v%APP_VERSION%"
echo oShellLink.Save
) > "%TEMP%\nexus_startmenu.vbs"
cscript //nologo "%TEMP%\nexus_startmenu.vbs" >nul
del "%TEMP%\nexus_startmenu.vbs" >nul

:: Desktop
set "DESKTOP=%PUBLIC%\Desktop"
if not exist "%DESKTOP%" set "DESKTOP=%USERPROFILE%\Desktop"

(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set oShellLink = WshShell.CreateShortcut("%DESKTOP%\Nexus Browser.lnk"^)
echo oShellLink.TargetPath = "%INSTALL_DIR%\NexusBrowser.vbs"
echo oShellLink.WorkingDirectory = "%INSTALL_DIR%"
echo oShellLink.Description = "Nexus Browser v%APP_VERSION%"
echo oShellLink.Save
) > "%TEMP%\nexus_desktop.vbs"
cscript //nologo "%TEMP%\nexus_desktop.vbs" >nul
del "%TEMP%\nexus_desktop.vbs" >nul

echo      Shortcuts created

:: Uninstaller
echo.
echo Creating uninstaller...

(
echo @echo off
echo echo.
echo echo ========================================
echo echo    Nexus Browser Uninstaller
echo echo ========================================
echo echo.
echo.
echo set /p CONFIRM="Are you sure you want to uninstall Nexus Browser? (Y/N): "
echo if /i not "%%CONFIRM%%"=="Y" exit /b
echo.
echo Removing shortcuts...
echo del /f /q "%START_MENU%\Nexus Browser.lnk" ^>nul 2^>^&1
echo del /f /q "%DESKTOP%\Nexus Browser.lnk" ^>nul 2^>^&1
echo rmdir /s /q "%START_MENU%" ^>nul 2^>^&1
echo.
echo Removing application files...
echo rmdir /s /q "%INSTALL_DIR%" ^>nul 2^>^&1
echo.
echo ========================================
echo echo    Uninstallation Complete
echo echo ========================================
echo echo.
echo pause
) > "%INSTALL_DIR%\uninstall.bat"

:: Complete
echo.
echo ========================================
echo    Installation Complete!
echo ========================================
echo.
echo %APP_NAME% v%APP_VERSION% is now installed.
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo Launch from:
echo   - Start Menu ^> Nexus Browser
echo   - Desktop shortcut
echo   - Double-click NexusBrowser.vbs in installation folder
echo.
echo To uninstall, run:
echo   %INSTALL_DIR%\uninstall.bat
echo.
pause
