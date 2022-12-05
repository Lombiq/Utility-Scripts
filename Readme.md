# Lombiq Utility Scripts



## About

Scripts (mostly PowerShell) that come handy during Orchard Core, Orchard 1.x or general .NET development work. We at [Lombiq](https://lombiq.com/) use these every day.


## Prerequisites

In order to use these PowerShell scripts and modules you need to update to at least PowerShell 5. You can check the installed version by running the `$PSVersionTable.PSVersion` command. If you have an earlier version you can download the current version from [here](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell).

For the Azure-related scripts you'll need the Azure (the new "Az") PowerShell module, so install as documented [here](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps). If you happen to have the older AzureRM module installed you'll need to [uninstall it](https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-2.2.0#uninstall-the-azurerm-module) first. You'll need at least v5.9 of the [Azure storage emulator](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-emulator) for the scripts to work.

To be able to import SQL Server export files (bacpac files) you'll need to import the *SqlServer\Import-BacpacToSqlServer\Import-BacpacToSqlServer.reg* registry script. Then you'll be able to right click on bacpac files and select "Import to SQL Server with PowerShell", or simply double-click on them. This needs the DAC Framework so if you get a "No SQL Package executable found for importing the database!" error then install it from [here](https://docs.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage-download?view=sql-server-ver15).

If you are working on a remote database without SQL Server locally installed (eg. Azure or the [Docker container](https://hub.docker.com/_/microsoft-mssql-server)) you have to install "PowerShell Extensions for Microsoft SQL Server 2012". Despite the name it works with newer versions as well. See [this tutorial](https://sqlpadawan.com/2018/08/01/how-to-install-sql-server-sqlps-powershell-module/).

As of writing this document [SQL Server in Docker doesn't support Windows authentication](https://github.com/microsoft/mssql-docker/issues/165). You can use the commands that support SQL authentication (eg. `Reset-OrchardCoreApp`) by providing a user name and password with the appropriate arguments.


## Installing the PowerShell modules

1. Set the PowerShell script execution policy to Unrestricted in order to use any of the scripts. To achieve this run the `Set-ExecutionPolicy Unrestricted` command.
2. Run the `AddPathToPSModulePath.ps1` script (you need admin privileges) to add the root of the repository to the `PSModulePath` environment variable. This will make PowerShell recognise this folder as one of the folders that contain PS modules. You only need to run this once - after that any changes made to these modules will be picked up automatically when a new PS console is opened. **NOTE**: It may be required to restart the PowerShell console, so do that as well.
3. Enjoy!


## Overview of all the included scripts

On what the different scripts do specifically and how to use them take a look at their content, there is inline documentation. This is just a quick overview of the functionality:

- Azure: To help working with the Azure cloud.
    - Copy-ToAzureDevelopmentStorage: Copies all files from the specified folder to Azure Development Storage.
    - Start-AzureStorageEmulator: Starts the Microsoft Azure Storage Emulator.
- Ftp: For working with FTP directories and files.
    - Get-FtpDirectory: Recursively downloads a folder from an FTP server.
    - Get-FtpFiles: Downloads all files from a folder on an FTP server.
    - New-FtpDirectory: Recursively uploads a folder to an FTP server.
    - Remove-FtpDirectory: Recursively removes a folder on an FTP server.
    - Rename-FtpDirectory: Renames a folder on an FTP server.
- Orchard1: For Orchard 1.x tasks.
    - Reset-AppDataFolder: Clears the App_Data folder from temporary files.
    - Restart-Site: Restarts an Orchard 1.x app in IIS.
- OrchardCore: For Orchard Core tasks.
    - Initialize-OrchardCoreSolution: Initializes an Orchard Core solution for a git repository.
    - Reset-OrchardCoreApp: Resets and sets up an Orchard Core application. Note that for this to work properly you'll need our [Setup Extensions](https://github.com/Lombiq/Setup-Extensions) project. Check out the script's documentation for details.
- SourceControl: For tasks around managing Mercurial and Git repositories.
    - ArchiveLastCommitToFolder: Copies the files changed in the last commit of a hg repo to another folder.
    - ExportLastCommitToAnotherHgRepo: Exports the files changed in the last commit of a hg repo to another hg repo as a patch.
    - ExportLastCommitToGit: Exports the files changed in the last commit of a hg repo to a git repo as a patch.
- SqlServer: A lot of scripts for common SQL Server tasks.
    - Get-DefaultSqlServerName: Gets the name of the default local SQL Server instance.
    - Import-BacpacToSqlServer: Imports a .bacpac file to a database on a local SQL Server instance. With the attached Registry file you can also add an Explorer context menu shortcut to it. Use the Docker version if you need that, but make sure to edit the `-ConnectionString` value first!
    - New-SqlServerDatabase: Creates a new database on the given SQL Server instance, after dropping it first if it already exists.
    - Test-SqlServer: Tests the connection to a local SQL Server instance.
    - Test-SqlServerDatabase: Checks whether the given database exists in a local SQL Server instance.
- Utilities: The true utilities!
    - CreateTrustedCertificate: Creates all necessary files and imports them into the local Certificate Store so that it can be used to access localhost sites via HTTPS, without the browser showing certificate errors.
    - Get-Rekt: Wrecks the script execution by throwing a fatal exception :).
    - Reload-Module: Reloads PowerShell modules from a folder.
    - Set-FileContent: Replaces a string in a file.
    - Test-Url: Sends a ping request to a URL, returning a boolean value based on the response.
    - Test-VSProjectConsistency: Checks Visual Studio project files' contents against the file system looking for inconsistencies.

## Notes

- The cmdlets follow the convention of using [`Write-Verbose`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-verbose?view=powershell-7.2) for outputting status messages, so they can be used in automation without generating a lot of output. If you are invoking them from a terminal, use the `-Verbose` switch to see how the cmdlet is progressing. This can be especially useful if the execution wasn't successful.

## Contributing and support

Bug reports, feature requests, comments, questions, code contributions, and love letters are warmly welcome, please do so via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.

### Developing PowerShell modules
Note that naturally you can also create Batch (.bat) or PowerShell (.ps1) scripts yourself that call these scripts when you repeatedly have to execute them with the same parameters.

1. Make a ModuleName folder in one of the thematic subfolders or create a new one.
2. Inside that folder make a ModuleName script with a ModuleName function (optionally you can use the `Cmdlet (advanced function)` snippet). See the existing modules for examples.

### Notes on developing scripts in general
- Instead of a simple text editor it's better to use an IDE to develop scripts, like [Visual Studio Code](https://code.visualstudio.com/) with the [PowerShell extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell) or [PowerShell ISE](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/ise/introducing-the-windows-powershell-ise) (though this is not actively maintained any more).
- Note that PowerShell modules stay in memory once loaded in a session (window) so if you change them you'll only see the changes applied if you e.g. open a new PowerShell console.
- Always include appropriate documentation and usage examples in the header of the script on what the script does.
- Since people can create .bat files pointing to the batch scripts (as advised above) only change such a script's path if it's absolutely inevitable, then communicate the change appropriately. (For PowerShell modules their location within this folder doesn't matter.)
- If your script needs to be run as an administrator always add the below lines to it. This will allow right click / Run as administrator to work.
    ```
    @setlocal enableextensions
    @cd /d "%~dp0"
    ```
