# Utility Scripts



## About

Scripts (mostly PowerShell) that come handy during Orchard Core, Orchard 1.x or general .NET development work. We at [Lombiq](https://lombiq.com/) use these every day.


## Prerequisites

In order to use these PowerShell scripts and modules you need to update to at least PowerShell 5. You can check the installed version by running the `$PSVersionTable.PSVersion` command. If you have an earlier version you can download version 5 preview from [here](https://www.microsoft.com/en-us/download/details.aspx?id=48729).

For the Azure-related scripts you'll need the Azure (the new "Az") PowerShell module, so install as documented [here](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps). If you happen to have the older AzureRM module installed you'll need to [uninstall it](https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-2.2.0#uninstall-the-azurerm-module) first. You'll need at least v5.9 of the [Azure storage emulator](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-emulator) for the scripts to work.

To be able to import SQL Server export files (bacpac files) you'll need to import the *SqlServer\Import-BacpacToSqlServer\Import-BacpacToSqlServer.reg* registry script. Then you'll be able to right click on bacpac files and select "Import to SQL Server with PowerShell".


## Installing the PowerShell modules

1. Set the PowerShell script execution policy to Unrestricted in order to use any of the scripts. To achieve this run the `Set-ExecutionPolicy Unrestricted` command.
2. Run the `AddPathToPSModulePath.ps1` script (you need admin privileges) to add the root of the repository to the `PSModulePath` environment variable. This will make PowerShell recognise this folder as one of the folders that contain PS modules. You only need to run this once - after that any changes made to these modules will be picked up automatically when a new PS console is opened.
3. Enjoy!


## Overview of all the included scripts

On what the different scripts do specifically and how to use them take a look at their content, there is inline documentation. This is just a quick overview of the functionality:

- Azure: To help working with the Azure cloud.
    - Copy-ToAzureDevelopmentStorage: Copies all files from the specified folder to Azure Development Storage.
    - Start-AzureStorageEmulator: Starts the Microsoft Azure Storage Emulator.
- Orchard1: For Orchard 1.x tasks.
    - Reset-AppDataFolder: Clears the App_Data folder from temporary files.
    - Restart-Site: Restarts an Orchard 1.x app in IIS.
- OrchardCore: For Orchard 1.x tasks.
    - Init-OrchardCore: Initializes an Orchard Core solution for a git repository.
    - Reset-OrchardCoreApp: Resets and sets up an Orchard Core application. Note that for this to work properly you'll need our [Setup Extensions](https://github.com/Lombiq/Setup-Extensions) project. Check out the script's documentation for details.
- SourceControl: For tasks around managing Mercurial and Git repositories.
    - ArchiveLastCommitToFolder: Copies the files changed in the last commit of a hg repo to another folder.
    - ExportLastCommitToAnotherHgRepo: Exports the files changed in the last commit of a hg repo to another hg repo as a patch.
    - ExportLastCommitToGit: Exports the files changed in the last commit of a hg repo to a git repo as a patch.
- SqlServer: A lot of scripts for common SQL Server tasks.
    - Get-DefaultSqlServerName: Gets the name of the default local SQL Server instance.
    - Import-BacpacToSqlServer: Imports a .bacpac file to a database on a local SQL Server instance. With the attached Registry file you can also add an Explorer context menu shortcut to it.
    - New-SqlServerDatabase: Creates a new database on the given SQL Server instance, after dropping it first if it already exists.
    - Test-SqlServer: Tests the connection to a local SQL Server instance.
    - Test-SqlServerDatabase: Checks whether the given database exists in a local SQL Server instance.
- Utilities: The true utilities!
    - Get-FtpFiles: Downloads all files from a folder on an FTP server.
    - Get-Rekt: Reks the script execution by throwing a fatal exception :).
    - Reload-Module: Reloads PowerShell modules from a folder.
    - Set-FileContent: Replaces a string in a file.
    - Test-VSProjectConsistency: Checks Visual Studio project files' contents against the file system looking for inconsistencies.


## Developing PowerShell modules

Note that naturally you can also create Batch (.bat) or PowerShell (.ps1) scripts yourself that call these scripts when you repeatedly have to execute them with the same parameters.

1. Make a ModuleName folder in one of the thematic subfolders or create a new one.
2. Inside that folder make a ModuleName script with a ModuleName function (optionally you can use the `Cmdlet (advanced function)` snippet). See the existing modules for examples.


## Notes on developing scripts in general

- Always include appropriate documentation and usage examples in the header of the script on what the script does.
- Since people can create .bat files pointing to the batch scripts (as advised above) only change such a script's path if it's absolutely inevitable, then communicate the change appropriately. (For PowerShell modules their location within this folder doesn't matter.)
- If your script needs to be run as an administrator always add the below lines to it. This will allow right click / Run as administrator to work.
    ```
    @setlocal enableextensions
    @cd /d "%~dp0"
    ```


## Contributing and support

Bug reports, feature requests, comments, questions, code contributions, and love letters are warmly welcome, please do so via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.