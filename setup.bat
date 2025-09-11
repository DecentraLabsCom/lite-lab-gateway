@echo off
setlocal enabledelayedexpansion
REM =================================================================
REM DecentraLabs Gateway - Quick Setup Script (Windows)
REM =================================================================

echo 🚀 DecentraLabs Gateway - Quick Setup
echo ======================================
echo.

REM Check prerequisites
echo 🔍 Checking prerequisites...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    echo    Visit: https://docs.docker.com/desktop/install/windows-install/
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    docker compose version >nul 2>&1
    if errorlevel 1 (
        echo ❌ Docker Compose is not installed.
        echo    Visit: https://docs.docker.com/compose/install/
        pause
        exit /b 1
    )
)

echo ✅ Docker and Docker Compose are available
echo.

REM Check if .env already exists
if exist ".env" (
    echo ⚠️  .env file already exists!
    set /p overwrite="Do you want to overwrite it? (y/N): "
    if /i not "%overwrite%"=="y" (
        echo Setup cancelled.
        pause
        exit /b
    )
)

REM Copy template
copy .env.example .env >nul
echo ✅ Created .env file from template
echo.

REM Ask for domain
echo.
echo 🔑 Database Passwords
echo --------------------
echo Enter database passwords (leave empty for auto-generated):
set /p "mysql_root_password=MySQL root password: "
set /p "mysql_password=Guacamole database password: "

if "%mysql_root_password%"=="" (
    set mysql_root_password=R00t_P@ss_%RANDOM%_%TIME:~9%
    set mysql_root_password=!mysql_root_password: =!
    echo Generated root password: !mysql_root_password!
)

if "%mysql_password%"=="" (
    set mysql_password=Gu@c_%RANDOM%_%TIME:~9%
    set mysql_password=!mysql_password: =!
    echo Generated database password: !mysql_password!
)

REM Update passwords in .env file
powershell -Command "(Get-Content .env) -replace 'MYSQL_ROOT_PASSWORD=.*', 'MYSQL_ROOT_PASSWORD=!mysql_root_password!' | Set-Content .env"
powershell -Command "(Get-Content .env) -replace 'MYSQL_PASSWORD=.*', 'MYSQL_PASSWORD=!mysql_password!' | Set-Content .env"

echo.
echo ⚠️  IMPORTANT: Save these passwords securely!
echo    Root password: !mysql_root_password!
echo    Database password: !mysql_password!
echo.

echo 🌐 Domain Configuration
echo ----------------------
echo Enter your domain name (or press Enter for localhost):
set /p domain="Domain [localhost]: "
if "%domain%"=="" set domain=localhost

REM Update .env file with intelligent defaults
if "%domain%"=="localhost" (
    echo 🔧 Configuring for local development...
    powershell -Command "(Get-Content .env) -replace 'SERVER_NAME=.*', 'SERVER_NAME=localhost' | Set-Content .env"
    powershell -Command "(Get-Content .env) -replace 'ISSUER=.*', 'ISSUER=https://localhost/auth' | Set-Content .env"
    powershell -Command "(Get-Content .env) -replace 'HTTPS_PORT=.*', 'HTTPS_PORT=8443' | Set-Content .env"
    powershell -Command "(Get-Content .env) -replace 'HTTP_PORT=.*', 'HTTP_PORT=8080' | Set-Content .env"
    echo    - Server: https://localhost:8443
    echo    - Using development ports (8443/8080) - no admin needed
) else (
    echo 🔧 Configuring for production...
    powershell -Command "(Get-Content .env) -replace 'SERVER_NAME=.*', 'SERVER_NAME=%domain%' | Set-Content .env"
    powershell -Command "(Get-Content .env) -replace 'ISSUER=.*', 'ISSUER=https://%domain%/auth' | Set-Content .env"
    powershell -Command "(Get-Content .env) -replace 'HTTPS_PORT=.*', 'HTTPS_PORT=443' | Set-Content .env"
    powershell -Command "(Get-Content .env) -replace 'HTTP_PORT=.*', 'HTTP_PORT=80' | Set-Content .env"
    echo    - Server: https://%domain%
    echo    - Using standard ports (443/80)
)

echo 💡 To use different ports, edit HTTPS_PORT/HTTP_PORT in .env after setup

echo.
echo 🔐 SSL Certificates
echo -------------------

REM Check certificates
if not exist "certs" mkdir certs

if not exist "certs\fullchain.pem" (
    echo ❌ SSL certificates not found!
    echo.
    echo You need to add SSL certificates to the 'certs' folder:
    echo   - certs\fullchain.pem (certificate)
    echo   - certs\privkey.pem (private key)
    echo   - certs\public_key.pem (JWT public key)
    echo.
    if "%domain%"=="localhost" (
        echo For localhost, you can generate self-signed certificates with OpenSSL
        echo or use the provided certificates if available.
    ) else (
        echo For production, get valid certificates from:
        echo   - Let's Encrypt (certbot)
        echo   - Your certificate authority
        echo   - Cloud provider (AWS ACM, etc.)
    )
) else (
    echo ✅ SSL certificates found
)

echo.
echo 🎯 Next Steps
echo -------------
echo 1. Review and customize .env file if needed
echo 2. Ensure SSL certificates are in place
echo 3. Run: docker-compose up -d
if "%domain%"=="localhost" (
    echo 4. Access: https://localhost:8443
) else (
    echo 4. Access: https://%domain%
)
echo.

REM Ask if user wants to start services
set /p "start_services=Do you want to start the services now? (Y/n): "
if /i "%start_services%"=="n" goto :skip_start
if /i "%start_services%"=="no" goto :skip_start

echo.
echo � Starting services...
docker-compose up -d

if errorlevel 0 (
    echo.
    echo ✅ Services started successfully!
    if "%domain%"=="localhost" (
        echo 🌐 Access your lab at: https://localhost:8443
    ) else (
        echo 🌐 Access your lab at: https://%domain%
    )
    echo 👤 Default login: guacadmin / guacadmin
    echo.
    echo 📊 To check status: docker-compose ps
    echo 📋 To view logs: docker-compose logs -f
) else (
    echo ❌ Failed to start services. Check the error messages above.
)
goto :end

:skip_start
echo �📚 For more information, see README.md
echo 🚀 Setup complete!

:end
echo.
pause