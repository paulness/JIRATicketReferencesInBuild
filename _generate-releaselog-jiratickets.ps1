<# Make sure to set TeamCity Version Control Settings to Automatically on Agent and install GIT on TeamCity for this to work! #>

<# 
Usage (change both paths as required):
$gitProjectFolder = "C:/GIT/SampleProject"
$releaseLogFilePath = "$gitProjectFolder\build\codedeploy\MyWebSite\releaselog.txt"

ProduceGitReleaseLog -gitProjectFolder $gitProjectFolder -releaseLogFilePath $releaseLogFilePath
#>
 
function ProduceGitReleaseLog ($gitProjectFolder, $releaseLogFilePath) {
    Write-Output "ProduceGitReleaseLog function called for Project folder: $gitProjectFolder"
    Get-ChildItem $gitProjectFolder -force




    <# Get current branch #>
    $gitStatusCommandOutputRaw = & git --git-dir=$gitProjectFolder/.git --work-tree=$gitProjectFolder status
    $a = $gitStatusCommandOutputRaw | Select-String -Pattern '^(?:On branch )(?<branchName>.*)$'
    $currentBranch = $a.Matches.Groups[1].Value
    Write-Output "Producing GitReleaseLog for $currentBranch"




    <# Validate current branch #>
    $isReleaseBranch = $currentBranch -match '(release\-([0-9\.]+))$'

    if (!$isReleaseBranch)
    {
        $errorNotReleaseBranch = "$currentBranch is not a release branch"
	    Write-Output $errorNotReleaseBranch
        Write-Output $errorNotReleaseBranch | Out-File -FilePath $releaseLogFilePath
	    return
    }




    <# Get list of all release branches in order #>
    $gitFetchOuput = & git --git-dir=$gitProjectFolder/.git --work-tree=$gitProjectFolder fetch origin 2>&1 | out-null
    $gitBranchCommandOutputRaw = & git --git-dir=$gitProjectFolder/.git --work-tree=$gitProjectFolder branch -r
    $gitBranchNamesAll = $gitBranchCommandOutputRaw | Select-String -Pattern '\/release\-([0-9\.]+)$'

    $myArray = @()
    foreach ($match in $gitBranchNamesAll.Matches)
    {
        $releaseNumberAsString = $match.Groups[1].Value
        [regex]$pattern = "\."
        $releaseNumberAsDecimal = $pattern.replace($releaseNumberAsString, ",", 1)
        $releaseNumberAsDecimal = $releaseNumberAsDecimal -replace '\.*','';
        $releaseNumberAsDecimal = $releaseNumberAsDecimal -replace '\,','.';

        $props = @{
            releaseNumberAsString = $releaseNumberAsString
            releaseNumberAsDecimal = [decimal]$releaseNumberAsDecimal
            isCurrentBranch = "release-$releaseNumberAsString" -eq $currentBranch
        }

        $object = new-object psobject -Property $props
        $myArray += $object
    }

    $myArray = $myArray | Sort-Object releaseNumberAsDecimal
    $myArray = $myArray | foreach {$i=0} {$_ | Add-Member Index ($i++) -PassThru}
    $index = ($myArray | where {$_.isCurrentBranch -eq $true}).Index


    Write-Output "All remote git release branches in order as follows:"
    Write-Output $myArray





    <# Get previous release branch name #>
    if ($index -eq 0)
    {
        $errorNoPreviousBranch = "$currentBranch is the earliest release branch in the system. No earlier branch found."
	    Write-Output $errorNoPreviousBranch
        Write-Output $errorNoPreviousBranch | Out-File -FilePath $releaseLogFilePath
	    return
    }
    $previousRelease = $myArray[$index-1]
    $previousReleaseName = "release-" + $previousRelease.releaseNumberAsString
    Write-Output "Previous release name: $previousReleaseName"





    <# Get commits between the two branches #>
    $gitCherryCommandOutputRaw = & git --git-dir=$gitProjectFolder/.git --work-tree=$gitProjectFolder cherry "remotes/origin/$previousReleaseName" -v
    $jiraTicketRefs = $gitCherryCommandOutputRaw | Select-String -Pattern '([A-Za-z]+\-\d+)'

    $jiraTicketsArray = @()
    foreach ($match in $jiraTicketRefs.Matches)
    {
        $x = $match.Groups[1].Value
        $jiraTicketsArray += $x.Trim()
    }

    $jiraTicketsArray = $jiraTicketsArray | Get-Unique
    Write-Output $jiraTicketsArray


    <# Create a text file with current branch, previous branch and JIRA ticket refs #>
    Write-Output "Saving release log to: $releaseLogFilePath"
    $jiraTicketsAsString = $jiraTicketsArray -join "`r`n" | Out-String

    Write-Output "CurrentBranch:`r`n$currentBranch`r`n`r`nPreviousBranch:`r`n$previousReleaseName`r`n`r`nJIRA Tickets In This Release:`r`n$jiraTicketsAsString" | Out-File -FilePath $releaseLogFilePath

}