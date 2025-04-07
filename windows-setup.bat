@echo off
echo Setting up Development Environment...
echo Current Time : %time%
echo Current Date : %date%

REM --- Check for Administrator Privileges ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: This script requires Administrator privileges. Please run as administrator.
    pause
    exit /b 1
)

REM --- Define Installation Paths (Adjust if needed) ---
set INSTALL_DIR=%SystemDrive%\DevTools
set REPORT_FILE=%INSTALL_DIR%\installation_report.html
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM --- Initialize HTML Report ---
echo ^<!DOCTYPE html^>^<html lang="en"^>^<head^>^<meta charset="UTF-8"^>^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>^<title>Development Environment Installation Report</title^>^<style^> >> "%REPORT_FILE%"
echo body { font-family: sans-serif; } table { border-collapse: collapse; width: 100%%; } th, td { border: 1px solid #ddd; padding: 8px; text-align: left; } th { background-color: #f2f2f2; } .success { color: green; } .error { color: red; } .upgraded { color: orange; } ^</style^>^</head^>^<body^> >> "%REPORT_FILE%"
echo ^<h1>Development Environment Installation Report</h1>^<table^> >> "%REPORT_FILE%"
echo ^<thead^>^<tr>^<th>Software</th>^<th>Status</th>^<th>Details</th>^</tr>^</thead>^<tbody^> >> "%REPORT_FILE%"

REM --- Function to Check if a Program is Installed (using Chocolatey) ---
:check_choco_installed
choco list --localonly %1 | findstr /B /C:"%1 " >nul 2>&1
if %errorLevel% equ 0 (
    set "%1_INSTALLED=true"
) else (
    set "%1_INSTALLED=false"
)
goto :eof

REM --- Function to Install/Upgrade Software and Report ---
:install_upgrade_report
set "SOFTWARE=%~1"
set "CHOCO_PACKAGE=%~2"
set "ACTION=%~3"
set "STATUS=installed"
set "DETAILS="

call :check_choco_installed "%CHOCO_PACKAGE%"

if "%ACTION%"=="install" (
    if "%%CHOCO_PACKAGE%_INSTALLED%"=="true" (
        set "STATUS=already installed"
    ) else (
        echo --- Installing %SOFTWARE% ---
        choco install %CHOCO_PACKAGE% --confirm
        if %errorLevel% neq 0 (
            set "STATUS=error"
            set "DETAILS=Chocolatey returned error code %errorLevel%"
        )
    )
) else if "%ACTION%"=="upgrade" (
    echo --- Upgrading %SOFTWARE% ---
    choco upgrade %CHOCO_PACKAGE% --confirm
    if %errorLevel% equ 0 (
        call :check_choco_installed "%CHOCO_PACKAGE%"
        if "%%CHOCO_PACKAGE%_INSTALLED%"=="true" (
            set "STATUS=upgraded"
        ) else (
            set "STATUS=error"
            set "DETAILS=Upgrade reported success but package not found"
        )
    ) else if %errorLevel% equ 3010 (
        set "STATUS=reboot required"
        set "DETAILS=Upgrade successful, reboot required"
    ) else (
        set "STATUS=error"
        set "DETAILS=Chocolatey upgrade returned error code %errorLevel%"
    )
)

echo ^<tr^>^<td>%SOFTWARE%^</td^>^<td^><span class="%STATUS: =%"^>%STATUS%^</span^>^<td^>%DETAILS%^</td^>^</tr^> >> "%REPORT_FILE%"
goto :eof

REM --- Install Chocolatey if not present ---
call :check_choco_installed chocolatey
if not "%CHOCOLATEY_INSTALLED%"=="true" (
    echo --- Installing Chocolatey ---
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorLevel% neq 0 (
        echo Error installing Chocolatey. Please check the output.
        echo ^<tr^>^<td>Chocolatey^</td^>^<td^><span class="error"^>error^</span^>^<td^>Error installing Chocolatey. Check script output.^</td^>^</tr^> >> "%REPORT_FILE%"
        goto :end_report
    )
    echo Chocolatey installed. Please restart this script as administrator.
    echo ^<tr^>^<td>Chocolatey^</td^>^<td^><span class="success"^>installed^</span^>^<td^>Installed successfully. Please restart script.^</td^>^</tr^> >> "%REPORT_FILE%"
    goto :end_report
) else (
    echo Chocolatey is already installed.
    echo ^<tr^>^<td>Chocolatey^</td^>^<td^><span class="success"^>already installed^</span^>^<td^>^</td^>^</tr^> >> "%REPORT_FILE%"
)
echo.

REM --- Install/Upgrade Software ---
call :install_upgrade_report "Docker Desktop" "docker-desktop" "install"
call :install_upgrade_report "Java 11 (OpenJDK)" "openjdk11" "install"
call :install_upgrade_report "Java 17 (OpenJDK)" "openjdk17" "install"
call :install_upgrade_report "Maven" "maven" "install"
call :install_upgrade_report "Gradle" "gradle" "install"
call :install_upgrade_report "Git" "git" "install"
call :install_upgrade_report "Node.js (LTS with npm)" "nodejs-lts" "install"
call :install_upgrade_report "kubectl (Kubernetes CLI)" "kubernetes-cli" "install"
call :install_upgrade_report "Python 3" "python3" "install"
call :install_upgrade_report "AWS CLI" "awscli" "install"
call :install_upgrade_report "Azure CLI" "azure-cli" "install"
call :install_upgrade_report "Terraform" "terraform" "install"

:end_report
echo ^</tbody^>^</table^>^</body^>^</html^> >> "%REPORT_FILE%"

echo.
echo --- Installation Process Started ---
echo The script has initiated the installation of the requested tools using Chocolatey.
echo Please monitor the output for each installation and confirm when prompted.
echo You can find the installation report at: %REPORT_FILE%
echo You might need to restart your system after some installations (like Docker Desktop) complete.
echo.
echo To check the installed versions after completion, open a new command prompt or PowerShell window and run:
echo   docker --version
echo   java -version
echo   mvn --version
echo   gradle --version
echo   git --version
echo   node -v
echo   npm -v
echo   kubectl version --client
echo   python --version
echo   aws --version
echo   az --version
echo   terraform --version
echo.
echo Note: Docker Desktop installation might require a system restart.
pause
exit /b 0