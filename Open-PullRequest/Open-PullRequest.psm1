function Open-PullRequest
{
    [CmdletBinding()]
    Param
    (
    )

    Process
    {
        # Your BB username. E.g. x.y@lombiq.com
        $username = ""
        # Your BB password.
        $password = ""
        # E.g. Issue/NAME-01.
        $prTitle= ""
        # E.g. issue/Name-01.
        $sourceBranchName =""
        # E.g. dev.
        $destinationBranchName =""
        # The reviewer's username. Not like x.y@lombiq.com, you can figoure it out during a BB PR making.
        $reviewerName = ""
        # The absolute path of a .hgsub file, the repo paths will be parsed from here.
        $hgsubPath = ""
        # E.g Lombiq.
        $repoOwner = ""

        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

        Get-Content($hgsubPath) | ForEach-Object{
            if(!$_.Equals("")){
                $subrepoUrl = $_.ToString().Split("=")[1]

                if($subrepoUrl.Contains($repoOwner)){
                    $repoName = $subrepoUrl.Split("/")[4]
                    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri https://api.bitbucket.org/2.0/repositories/$repoOwner/$repoName/pullrequests?state=OPEN -Method Get
            
                    if($response.size -eq 0 -or !($response.values.title -eq $prTitle)){
                        Write-Host "Making PR in" $repoName
                        $body = @{
                            title = $prTitle
                            description = "PR for $sourceBranchName branch"
                            source = @{
                                branch = @{
                                    name = "$sourceBranchName"
                                }
                                repository = @{
                                    full_name = "$repoOwner/$repoName"
                                }
                            }
                            destination = @{
                                branch = @{
                                    name = "$destinationBranchName"
                                }
                            }
                            close_source_branch = $false
                            reviewers = @(@{username = "$reviewerName"})
                        }

                        Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri https://api.bitbucket.org/2.0/repositories/$repoOwner/$repoName/pullrequests/ -ContentType "application/json" -Method POST -Body (ConvertTo-Json $body)
                    }
                }
            }
        }
    }
}