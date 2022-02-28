function Update-DotNetDevelopmentCertificateHttps
{
    [CmdletBinding()]
    param()
    
    process
    {
        # Purge current certificates. Note that deleting certificates that were trusted through the "dotnet dev-certs
        # https --trust" command still require a confirmation.
        dotnet dev-certs https --clean

        # Generate new certificate.
        dotnet dev-certs https
        
        # Export the new certificate into a file.
        $pfxPath = "$(Get-Location)\dotnet-dev-cert-https.pfx"
        dotnet dev-certs https --export-path $pfxPath
        
        # Import the certificate into the user's trusted certificate store. Not using "dotnet dev-certs https --trust"
        # here so that there's no confirmation popup, allowing to process to run in non-interactive mode.
        Add-Type -AssemblyName System.Security
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $certificate.Import($pfxPath)
        $certificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList "MY", CurrentUser
        $certificateStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $certificateStore.Add($certificate)
        $certificateStore.Close()

        # Clean up.
        Remove-Item $pfxPath -Force
        
        # Validate new certificate. Unfortunately, "dotnet dev-certs https --check --trust" still reports the
        # certificate as not trusted.
        dotnet dev-certs https --check --verbose
    }
}