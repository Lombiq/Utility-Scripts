@echo off

REM This script creates all necessary files and imports them into the local Certificate Store
REM so that it can be used to access localhost sites via HTTPS.
REM The certificate name will be identical to the domain name provided when prompted.
REM 
REM Needs at least openssl.exe v1.1.1

ECHO.
ECHO Please make sure you're using openssl ^>= 1.1.1 and its in your PATH:
ECHO.
openssl version
IF %ERRORLEVEL% NEQ 0 (
    ECHO openssl.exe could not be found. Please make sure it is accessible to this script, then try again.
    EXIT /B 1
)
ECHO.

:prompt
SET /P DOMAIN=Please enter the domain for the certificate: || Set DOMAIN=NothingChosen
If "%DOMAIN%"=="NothingChosen" goto prompt

SET CERTNAME=%DOMAIN%
SET "FILEPATH=%USERPROFILE%\.ssh"
SET "CERTPATHBASE=%FILEPATH%\%CERTNAME%"

REM 0. Create the target directory if it does not exist, but fail silently in case it does
MKDIR "%FILEPATH% 2> nul

REM 1. Create strong certificate and private key, from https://stackoverflow.com/a/41366949/177710
openssl.exe req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout "%CERTPATHBASE%.key" -out "%CERTPATHBASE%.crt" -subj "/CN=%DOMAIN%" -addext "subjectAltName=DNS:%DOMAIN%"
ECHO Created "%CERTPATHBASE%.key".
ECHO Created "%CERTPATHBASE%.crt".

REM 2. Create a PFX file from the above two files, from https://stackoverflow.com/a/17284371/177710
openssl.exe pkcs12 -export -out "%CERTPATHBASE%.pfx" -inkey "%CERTPATHBASE%.key" -in "%CERTPATHBASE%.crt" -name "%DOMAIN%" -passout pass:
ECHO Created "%CERTPATHBASE%.pfx".

REM 3. Import the certificate in the "Local Computer\Personal" store, from https://stackoverflow.com/a/7260297/177710
REM This is actually the same as: IIS Manager -> Server Certificates -> Import... %CERTNAME%.pfx, into Personal store
certutil -f -p "" -importpfx "%CERTPATHBASE%.pfx"
ECHO Imported "%CERTPATHBASE%.pfx" into "Local Computer\Personal" store.

ECHO.
ECHO Done.
ECHO You can now bind your newly created certificate to your local web site in IIS Manager.

@echo on