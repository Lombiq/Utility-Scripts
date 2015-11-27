# Utility Scripts readme



This repo contains some scripts that may come handy during development work. On what the different scripts specifically do take a look at their content, there is inline documentation.

Note that naturally you can create Batch (.bat) or PowerShell (.ps1) scripts yourself that call these scripts when you repeatedly have to execute them with the same parameters.
In order to use the PowerShell scripts you need to update to PowerShell 5.

Scripts in folders:

- SourceControl: scripts related to source control.

Developing and installing PowerShell modules:

1. Make a ModuleName folder.
2. Inside that folder make a ModuleName script with a ModuleName function (optionally you can use the "Cmdlet (advanced function") snippet).
3. Run AddCurrentPathToPSModulePath.ps1 script (you need admin privileges) inside the ModuleName folder's parent folder. It will add the current location to the PSModule path so after that you can use your module anywhere like any cmdlet.
4. Ideally you should put your modules inside the repo's root folder, so anyone who pulls the repo just runs the AddCurrentPathToPSModulePath.ps1 once and then can use all modules.


## Notes on developing scripts

- Always include appropriate documentation in the header of the script on what the script does.
- Include usage example(s) in the script's file.
- Since people can create .bat files pointing to these scripts (as advised above) only change a script's path if absolutely inevitable, and then communicate the change appropriately.