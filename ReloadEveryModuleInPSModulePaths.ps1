# For some reason you can't just set $VerbosePreference here and have an effect inside the module.
param(
    [switch] $Verbose
)

# Self-Update first.
if ($Verbose) { Reload-Module -Verbose } else { Reload-Module }

# Reload everything.
[Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') -split ';' |
    Where-Object { Test-Path -PathType Container $PSItem } |
    # Don't try to reload the built-in modules. That's usually meaningless and if they do change you should reboot.
    Where-Object { $PSItem -notlike 'C:\Windows\system32\WindowsPowerShell\v1.0\Modules*' } |
    Where-Object { $PSItem -notlike 'C:\Program Files\WindowsPowerShell\Modules*' } |
    ForEach-Object { if ($Verbose) { Reload-Module $PSItem -Verbose } else { Reload-Module $PSItem } }