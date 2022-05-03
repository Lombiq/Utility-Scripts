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
        
        # Import the certificate to the machine-wide certificate store.
        Import-Certificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My

        # Clean up.
        Remove-Item $pfxPath -Force
        
        # Validate new certificate. Unfortunately, "dotnet dev-certs https --check --trust" still reports the
        # certificate as not trusted.
        dotnet dev-certs https --check --verbose
    }
}