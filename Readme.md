# Utility Scripts readme



This repo contains some scripts that may come handy during development work. On what the different scripts specifically do take a look at their content, there is inline documentation.

First of all, you need to set the PowerShell script execution policy to Unrestricted in order to use any of the scripts. To achieve this run the `Set-ExecutionPolicy Unrestricted` command.


## Installing PowerShell modules

Run the `AddPathToPSModulePath.ps1` script (you need admin privileges) to add the root of the repository to the `PSModulePath` environment variable. This will make PowerShell recognise this folder as one of the folders that contain PS modules. You only need to run this once - after that any changes made to these modules will be picked up automatically when a new PS console is opened.

In order to use these PowerShell scripts and modules you need to update to at least PowerShell 5. You can check the installed version by running the `$PSVersionTable.PSVersion` command. If you have an earlier version you can download version 5 preview from [here](https://www.microsoft.com/en-us/download/details.aspx?id=48729).

For the Azure-related scripts you'll need the Azure (the new "Az") PowerShell module, so install as documented [here](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps). If you happen to have the older AzureRM module installed you'll need to [uninstall it](https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-2.2.0#uninstall-the-azurerm-module) first.


## Developing PowerShell modules

Note that naturally you can also create Batch (.bat) or PowerShell (.ps1) scripts yourself that call these scripts when you repeatedly have to execute them with the same parameters.

1. Make a ModuleName folder.
2. Inside that folder make a ModuleName script with a ModuleName function (optionally you can use the `Cmdlet (advanced function)` snippet).
4. Ideally you should put your modules inside the repository's root folder, so after running `AddPathToPSModulePath.ps1` once the modules will be available on the system.


## Notes on developing scripts

- Always include appropriate documentation and usage examples in the header of the script on what the script does.
- Since people can create .bat files pointing to these scripts (as advised above) only change a script's path if it's absolutely inevitable, then communicate the change appropriately.