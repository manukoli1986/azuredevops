#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $OrgName,

    [Parameter()]
    [string]
    $ProjectName,

    [Parameter()]
    [string]
    $PAT,
    
    [Parameter()]
    [string]
    $RepoName,

    [Parameter()]
    [array]
    $Teams,

    [Parameter()]
    [string]
    $PatternName
)

$ErrorActionPreference = 'Stop'

. "..\Helpers\ADO\ADO.Auth.ps1"
. "..\Helpers\ADO\ADO.Git.ps1"
. "..\Helpers\ADO\ADO.Graph.ps1"



function GetUserByMailAddress([string] $mailAddress) {
    $users = Get-ADOUsers -AccountName $OrgName -Headers $auth
    $user = $users | where-Object { $_.mailAddress -eq $mailAddress }
    return $user
}

function GetGroupByName([string] $ProviderDisplayName) {
    $groups = Get-ADOGroups -AccountName $OrgName -Headers $auth
    $group = $groups | where-Object { $_.principalName -eq $ProviderDisplayName }
    return $group
}

function CheckAzDevOpsExtension () {
    $azExtensions = az extension list | ConvertFrom-json
    $azDevOpsExt = $azExtensions | Where-Object { 
        $_.name -eq 'azure-devops'
    }
    if ($null -eq $azDevOpsExt) {
        throw "No valid Azure Devops Extenions installed. Please install it with  az extension add --name azure-devops"
    }
}

function GetSecurityGroupDescriptor ([string] $ProjectName,
    [string] $groupName) {
    $secGroups = (az devops security group list --project $ProjectName) | ConvertFrom-Json
    $secGroup = ($secGroups.graphGroups) | Where-Object { ($_.principalName -eq $groupName) }
    return $secGroup.descriptor
}

function UploadArtifactsToGit ([string] $SourcePath,
    [string] $DestinationProject,
    [string] $DestinationGit,
    [string] $patternName) {

    $sourceFiles = Get-ChildItem $SourcePath -Recurse | Where-Object { $_.PSIsContainer -eq $false }

    foreach ($file in $sourceFiles) {
        $contents = Get-Content $($file.FullName) | Out-String

$changeString = @"
{
"changeType": "add",
"item": {
"path": "/tasks.md"
},
"newContent": {
"content": "# Tasks\n\n* Item 1\n* Item 2",
"contentType": "rawtext"
}
}
"@
        $patternIndex = $file.FullName.IndexOf($patternName)
        $filesLength = $file.FullName.Length
        $start = $patternIndex+$($patternName.Length)
        $end = ($filesLength-$patternIndex -($patternName.Length))
        $gitPath = $file.FullName.Substring($start, $end)
        $gitPath = $gitPath.replace("\","/")

        $change = $changeString | ConvertFrom-Json
        $change.item.path = $gitPath
        $change.newContent.content = $contents
        # $change.newContent.content = [Newtonsoft.Json.JsonConvert]::SerializeObject($contents,[Newtonsoft.Json.Formatting]::Indented)
        Write-Host "Copying [$($file.FullName)] to [$gitPath]"

        New-ADOGitPush -AccountName $OrgName `
                       -ProjectName $ProjectName `
                       -RepositoryName $RepoName `
                       -Changes $change `
                       -Comment "Arian bot was here!" `
                       -Headers $auth
    }

}




$OrgNameFull = "https://dev.azure.com/$OrgName"
$env:AZURE_DEVOPS_EXT_PAT = $PAT
$auth = $null
$repo = $null
$patternsRootPath = "..\Manifests\Patterns"


$auth = New-ADOPatAuthHeader -Username '' `
    -PersonalAccessToken $PAT


#region Projects
$project = az devops project show -p $ProjectName

if ($null -eq $project) {
    Write-Host "Creating Project $($ProjectName)"
    az devops project create --name $ProjectName
}
#endRegion

#region Repos
$repo = az repos show --org $OrgNameFull `
    --project $ProjectName `
    --repository $RepoName `
                    
if ($null -ne $repo) {
    $repo = $repo | convertfrom-json
    Write-Host "Found Repository [$($repo.Name)]"
}
else {
    Write-Host "Creating repo [$RepoName]"
    $repo = az repos create --org $OrgNameFull `
        --project $ProjectName `
        --name $RepoName `

}

$a = UploadArtifactsToGit -SourcePath "$patternsRootPath\$PatternName" `
    -DestinationProject $ProjectName `
    -DestinationGit $RepoName `
    -patternName $PatternName




#endRegion


#region Teams
#Check teams and build them if they don't exist
#Grant teams permissions
foreach ($team in $teams) {
    $teamName = "$RepoName-$($team.Name)"
    Write-Host "Checking if team [$teamName] exists"
    $teamResult = az devops team show --team $teamName `
        --org $OrgNameFull `
        --project $ProjectName

    if ($null -ne $teamResult) {
        $teamResult = GetGroupByName($("[$ProjectName]\$teamName"))
        Write-Host "Found Team [$($teamResult.principalName)]"
    }
    else {
        Write-Host "Creating team [$teamName]"
        $teamResult = az devops team create --name $teamName `
            --organization $OrgNameFull `
            --project $ProjectName
        $teamResult = $teamResult | ConvertFrom-json

        #Add Security ACL to the Team
        $groupName = "[$ProjectName]\$($team.Details.RBAC)"
        $secGroupId = GetSecurityGroupDescriptor -ProjectName $ProjectName -groupName $groupName

        $gSec = Add-ADOGroupMember -AccountName $OrgName `
            -SubjectDescriptor $($teamResult.identity.subjectDescriptor) `
            -ContainerDescriptor $secGroupId `
            -Headers $auth

        #Add team members
        $teamMembers = $team.Details.Members
        
        foreach ($member in $teamMembers) {
            $mailAddress = $($member.mailAddress)
            Write-Host "Checking Team member mail address [$mailAddress]"
            $user = GetUserByMailAddress($mailAddress)
            $uDescriptor = $user.descriptor

            $group = GetGroupByName("[$ProjectName]\$teamName")
            $gDescriptor = $group.descriptor

            $tSec = Add-ADOGroupMember -AccountName $OrgName `
                -SubjectDescriptor $uDescriptor `
                -ContainerDescriptor $gDescriptor `
                -Headers $auth

        }
    }

}
#endRegion

#region ServiceConnections
#TODO create service connections based on a naming convention
#az devops service-endpoint list
#az devops service-endpoint create
#endRegion



#region Policies
#TODO ADD Policies using az cli
#endRegion


#region Pipelines
#az pipelines create 
#endRegion
