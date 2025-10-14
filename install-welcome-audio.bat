@echo off
:: RedLine Souls - Welcome Audio Auto-Installer (Batch Version)
:: This downloads the installer script and runs it

color 0B
echo ========================================
echo RedLine Souls - Welcome Audio Installer
echo ========================================
echo.
echo Downloading installer...

:: Run PowerShell script
powershell.exe -ExecutionPolicy Bypass -Command "& { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/install-welcome-audio.ps1' -OutFile '%TEMP%\redline-audio-install.ps1'; & '%TEMP%\redline-audio-install.ps1' }"

pause
