function Get-GitHubPullRequest
{
    [CmdletBinding()]
    [Alias("gghpr")]
    [OutputType([object])]
    param
    (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a valid repository URL on GitHub.")]
        [string] $RepositoryUrl,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a valid branch name of a pull request on GitHub.")]
        [string] $BranchName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a user name to access the GitHub repository through the API.")]
        [string] $ApiUserName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a password to access the GitHub repository through the API.")]
        [SecureString] $ApiPassword
    )
    
    process
    {
        $repositoryUri = [System.Uri]$RepositoryUrl
        if ($repositoryUri.Host -ne "github.com")
        {
            throw "`"$RepositoryUrl`" must be a valid GitHub URL!"
        }

        if ($repositoryUri.Segments.Count -lt 3)
        {
            throw "`"$RepositoryUrl`" must be a valid GitHub repository URL!"
        }

        $pullRequestId = 0
        if (-not [int]::TryParse($BranchName.Replace("refs/", "").Replace("pull/", "").Replace("/head", ""), [ref] $pullRequestId) `
                -or $pullRequestId -le 0)
        {
            throw "Could not determine the ID of the pull request from the branch name `"$BranchName`"!"
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $repositoryPath = [string]::Join([string]::Empty, $repositoryUri.Segments[1..2])
        $networkCredentials = New-Object System.Net.NetworkCredential($ApiUserName, $ApiPassword)
        $apiCredentials = "$($networkCredentials.UserName):$($networkCredentials.Password)"
        $pullRequestData = $null
        $retryCount = 0

        do
        {
            if ($retryCount -gt 0)
            {
                Start-Sleep -Seconds 5
            }

            $retryCount += 1

            $pullRequestData = Invoke-WebRequest `
                -Uri "https://api.github.com/repos/$repositoryPath/pulls/$pullRequestId" `
                -Headers @{ Authorization = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($apiCredentials)))" } `
                -UseBasicParsing `
            | ConvertFrom-Json
        } while ($null -eq $pullRequestData -and $retryCount -lt 3)

        if ($null -eq $pullRequestData)
        {
            throw "Could not fetch the pull request with ID `"$pullRequestId`" from the `"$repositoryPath`" repository!"
        }

        return $pullRequestData
    }
}
