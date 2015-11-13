# Utility Scripts readme



This repo contains some scripts that may come handy during development work. On what the different scripts specifically do take a look at their content, there is inline documentation.

Note that naturally you can create Batch (.bat) or PowerShell (.ps1) scripts yourself that call these scripts when you repeatedly have to execute them with the same parameters.

Scripts in folders:

- SourceControl: scripts related to source control.
- VisualStudio: scripts related to Visual Studio and files it manages.


## Notes on developing scripts

- Always include appropriate documentation in the header of the script on what the script does.
- Include usage example(s) in the script's file.
- Since people can create .bat files pointing to these script (as advised above) only change a script's path if absolutely inevitable, and then communicate the change appropriately.