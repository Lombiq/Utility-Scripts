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
        [SecureString] $ApiPassword,

        [Parameter(HelpMessage = "Throws exception if the pull request is not mergeable.")]
        [Switch] $ThrowIfNotMergeable,

        [Parameter(HelpMessage = "When used together with the ThrowIfNotMergeable switch, closed pull requests will not cause an exception.")]
        [Switch] $IgnoreClosed,

        [Parameter(HelpMessage = "When used together with the ThrowIfNotMergeable switch, draft pull requests will not cause an exception.")]
        [Switch] $IgnoreDraft
    )

    process
    {
        $repositoryPath = ""

        if ($RepositoryUrl -like "git@github.com:*")
        {
            $repositoryPathSegments = $RepositoryUrl.TrimStart("git@github.com:").TrimEnd(".git").Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)

            if ($repositoryPathSegments.Count -ne 2)
            {
                throw "`"$RepositoryUrl`" must be a valid SSH URL of a GitHub repository!"
            }

            $repositoryPath = [string]::Join('/', $repositoryPathSegments[0..1])
        }
        else
        {
            $repositoryUri = [System.Uri]$RepositoryUrl

            if ($repositoryUri.Host -ne "github.com")
            {
                throw "`"$RepositoryUrl`" must be a valid HTTPS URL of a GitHub repository!"
            }

            if ($repositoryUri.Segments.Count -lt 3)
            {
                throw "`"$RepositoryUrl`" must be a valid URL of a repository!"
            }

            $repositoryPath = [string]::Join([string]::Empty, $repositoryUri.Segments[1..2])
        }

        $pullRequestId = $BranchName.Replace("refs/", "").Replace("pull/", "").Replace("/head", "")
        $isPullRequestIdValid = [int]::TryParse($pullRequestId, [ref] $pullRequestId)
        if (-not $isPullRequestIdValid -or $pullRequestId -le 0)
        {
            throw "Could not determine the ID of the pull request from the branch name `"$BranchName`"!"
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $networkCredentials = New-Object System.Net.NetworkCredential($ApiUserName, $ApiPassword)
        $apiCredentials = "$($networkCredentials.UserName):$($networkCredentials.Password)"
        $pullRequest = $null
        $retryCount = 0

        do
        {
            if ($retryCount -gt 0)
            {
                Start-Sleep -Seconds 5
            }

            $retryCount += 1

            $credentialsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($apiCredentials))
            $webRequestParameters = @{
                Uri     = "https://api.github.com/repos/$repositoryPath/pulls/$pullRequestId"
                Headers = @{Authorization = "Basic $credentialsBase64" }
            }
            $pullRequest = Invoke-WebRequest @webRequestParameters -UseBasicParsing | ConvertFrom-Json
        } while ($null -eq $pullRequest -and $retryCount -lt 3)

        if ($null -eq $pullRequest)
        {
            throw "Could not fetch the `"https://github.com/$repositoryPath/pull/$pullRequestId`" pull request!"
        }

        $successful = $true

        # Control flow is constructed this way for better readability.
        if ($ThrowIfNotMergeable.IsPresent -and -not $pullRequest.merged -and -not $pullRequest.mergeable)
        {
            $successful = $false

            if ($IgnoreClosed.IsPresent)
            {
                if ($null -eq $pullRequest.state)
                {
                    Write-Warning "Could not determine pull request status!"
                }

                if ($null -eq $pullRequest.state -or $pullRequest.state -eq "closed")
                {
                    $successful = $true
                }
            }

            if ($IgnoreDraft.IsPresent)
            {
                if ($null -eq $pullRequest.draft)
                {
                    Write-Warning "Could not determine if the pull request is draft or not!"
                }

                if ($null -eq $pullRequest.draft -or $pullRequest.draft)
                {
                    $successful = $true
                }
            }
        }

        Write-Output $pullRequest

        if (-not $successful)
        {
            throw "The pull request `"$($pullRequest.html_url)`" is not mergeable!"
        }
    }
}
