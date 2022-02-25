function Update-DotNetDevelopmentCertificateHttps
{
    [CmdletBinding()]
    param()
    
    process
    {
        # Purge current certificates.
        dotnet dev-certs https --clean

        # Generate new certificate.
        dotnet dev-certs https
        
        # Export the new certificate into a file.
        $pfxPath = "$(Get-Location)\dotnet-dev-cert-https.pfx"
        dotnet dev-certs https --export-path $pfxPath
        
        # Import the certificate into the user's trusted certificate store.
        Add-Type -AssemblyName System.Security
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $certificate.Import($pfxPath)
        $certificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList "MY", CurrentUser
        $certificateStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $certificateStore.Add($certificate)
        $certificateStore.Close()

        # Clean up.
        Remove-Item $pfxPath -Force
        
        # Validate new certificate.
        dotnet dev-certs https --check --verbose
    }
}