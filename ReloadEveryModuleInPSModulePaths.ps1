foreach ($path in [Environment]::GetEnvironmentVariable("PSModulePath", "Machine").Split(";", [System.StringSplitOptions]::RemoveEmptyEntries))
{
    Reload-Module $path
}