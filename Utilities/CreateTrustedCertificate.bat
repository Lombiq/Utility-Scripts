@echo off

REM This script creates all necessary files and imports them into the local Certificate Store
REM so that it can be used to access localhost sites via HTTPS.
REM The certificate name will be identical to the domain name provided when prompted.

REM Check that openssl.exe is accessible.
openssl version
IF %ERRORLEVEL% NEQ 0 (
    ECHO openssl.exe could not be found. Please make sure it is accessible to this script, e.g. its parent directory is in your PATH.
    ECHO You can find an openssl.exe in your Git installation, e.g. under "C:\Program Files\Git\usr\bin" or similar.
    ECHO If you don't have Git installed, yet, there are several options to install openssl.exe, two of which are:
    ECHO   1. Install Git from https://git-scm.com/download/win
    ECHO   2. Use Chocolatey: choco install openssl
    EXIT /B 1
)
REM Verify that openssl version is >= 1.1.1.
REM The /V switch prints the openssl version info in case it does not match the provided regex.
openssl version | findstr /V /R /C:"[1-9]\.[1-9]\.[1-9]"
REM Ok, this is awkward, but we're checking for a zero errorlevel here, because "findstr" inverts the exit code with /V.
IF %ERRORLEVEL% EQU 0 (
    ECHO Please update openssl.exe to version 1.1.1 or later.
    ECHO There are several options to install the latest openssl.exe, two of which are:
    ECHO   1. Install Git from https://git-scm.com/download/win
    ECHO   2. Use Chocolatey: choco install openssl
    EXIT /B 1
)
ECHO.

:prompt
SET /P DOMAIN=Please enter the domain for the certificate: || Set DOMAIN=NothingChosen
If "%DOMAIN%"=="NothingChosen" GOTO prompt
ECHO.

SET CERTNAME=%DOMAIN%
REM Use a GUID without dashes as the temp folder name to assure it is our own.
SET "FILEPATH=%TEMP%\a533ec0f6526473186d77b8dd0705366"
SET "CERTPATHBASE=%FILEPATH%\%CERTNAME%"

REM 0. Create the target directory; remove left-over folder, in case it exists.
ECHO Creating "%FILEPATH%".
RMDIR /S /Q "%FILEPATH%" 2> nul
MKDIR "%FILEPATH%" 2> nul
IF %ERRORLEVEL% NEQ 0 GOTO :error
ECHO.

REM 1. Create strong certificate and private key, from https://stackoverflow.com/a/41366949/177710
openssl.exe req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout "%CERTPATHBASE%.key" -out "%CERTPATHBASE%.crt" -subj "/CN=%DOMAIN%" -addext "subjectAltName=DNS:%DOMAIN%,DNS:*.%DOMAIN%"
IF %ERRORLEVEL% NEQ 0 GOTO :error
ECHO Created "%CERTPATHBASE%.key".
ECHO Created "%CERTPATHBASE%.crt".
ECHO.

REM 2. Create a PFX file from the above two files, from https://stackoverflow.com/a/17284371/177710
openssl.exe pkcs12 -export -out "%CERTPATHBASE%.pfx" -inkey "%CERTPATHBASE%.key" -in "%CERTPATHBASE%.crt" -name "%DOMAIN%" -passout pass:
IF %ERRORLEVEL% NEQ 0 GOTO :error
ECHO Created "%CERTPATHBASE%.pfx".
ECHO.

REM 3. Import the certificate in the "Local Computer\Personal" store, from https://stackoverflow.com/a/7260297/177710
REM This is actually the same as: IIS Manager -> Server Certificates -> Import... %CERTNAME%.pfx, into Personal store
certutil -f -p "" -importpfx "%CERTPATHBASE%.pfx"
IF %ERRORLEVEL% NEQ 0 GOTO :error
ECHO Imported "%CERTPATHBASE%.pfx" into "Local Computer\Personal" store.
ECHO.

REM Remove the temporary folder including all files (/S) and don't ask (/Q).
RMDIR /S /Q "%FILEPATH%" 2> nul
ECHO Removed "%FILEPATH%".

ECHO.
ECHO Done.
ECHO You can now bind your newly created certificate to your local web site in IIS Manager.
GOTO :eof

:error
ECHO An error occurred - exiting.
EXIT /B 2

@echo on