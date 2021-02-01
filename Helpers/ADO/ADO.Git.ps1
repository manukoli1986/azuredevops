$ApiVersion_Git = "6.1-preview.1"

#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

function Get-ADOGitRepositories {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [string] $ProjectName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,

        [Parameter(Mandatory = $false)]
        [switch] $RawOutput
    )


    #POST https://dev.azure.com/{organization}/{project}/_apis/git/repositories?api-version=6.1-preview.1
    $uri = "https://dev.azure.com/$AccountName/$ProjectName/_apis/git/repositories?api-version=$ApiVersion_Git"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers

    if ($RawOutput) {
        return $response
    }
    else {
        return $response.value    
    }    
}

function Get-ADOGitRepository {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [string] $ProjectName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,

        [Parameter(Mandatory = $true)]
        [string] $RepositoryName
    )

    $uri = "https://dev.azure.com/$AccountName/$ProjectName/_apis/git/repositories/$($RepositoryName)?api-version=$ApiVersion_Git"
    # $uri = "https://$AccountName.visualstudio.com/DefaultCollection/$ProjectName/_apis/git/repositories/$($RepositoryName)?api-version=$ApiVersion_Git"
    return Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers
}

function Get-ADOGitRepositoryCommits {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [guid] $RepositoryId,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,
        
        [Parameter(Mandatory = $false)]
        [switch] $Raw
    )
    $uri = "https://dev.azure.com/$AccountName/$ProjectName/_apis/git/repositories/$($RepositoryId)/commits?api-version=$ApiVersion_Git"
    # $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/git/repositories/$RepositoryId/commits?api-version=1.0"
            
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers
    
    if ($Raw) {
        return $response
    }
    else {
        return $response.value    
    }    
}

function Get-ADOGitCommit {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,
        
        [Parameter(Mandatory = $true)]
        [string] $ProjectName,

        [Parameter(Mandatory = $true)]
        [guid] $RepositoryId,
        
        [Parameter(Mandatory = $true)]
        [string] $CommitId,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,
        
        [Parameter(Mandatory = $false)]
        [switch] $IncludeChanges
    )
    $uri = "https://dev.azure.com/$AccountName/$ProjectName/_apis/git/repositories/$($RepositoryId)/commits/$($CommitId)?api-version=$ApiVersion_Git"
    # $uri = "https://$AccountName.visualstudio.com/DefaultCollection/$ProjectName/_apis/git/repositories/$RepositoryId/commits/$($CommitId)?api-version=$ApiVersion_Git"

    if ($IncludeChanges) {
        $uri += '&changeCount=100'
    }
            
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers
    
    
    return $response
    
}
function Get-ADOGitRepositoryPushes {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [guid] $RepositoryId,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,
        
        [Parameter(Mandatory = $false)]
        [switch] $Raw
    )
    $uri = "https://dev.azure.com/$AccountName/$ProjectName/_apis/git/repositories/$($RepositoryId)/pushes?api-version=$ApiVersion_Git"
    # $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/git/repositories/$RepositoryId/pushes?api-version=$ApiVersion_Git"
            
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers

    
    if ($Raw) {
        return $response
    }
    else {
        return $response.value    
    }    
}


function New-ADOGitPush {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,
        
        [Parameter(Mandatory = $true)]
        [string] $ProjectName,

        [Parameter(Mandatory = $true)]
        [string] $RepositoryName,
        
        [Parameter(Mandatory = $true)]
        [array] $Changes,
        
        [Parameter(Mandatory = $true)]
        [string] $Comment,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers        
    )

    $repo = Get-ADOGitRepository -AccountName $AccountName -ProjectName $projectName -RepositoryName $RepositoryName -Headers $Headers
    $lastCommit = Get-ADOGitRepositoryCommits -AccountName $AccountName -RepositoryId $repo.id -Headers $Headers | Select-Object -First 1
    if ($null -eq $lastCommit)
    {
        $lastCommitId = '0000000000000000000000000000000000000000'
    } else {
        $lastCommitId = $($lastCommit.commitId)
    }
  
    $template = @"
{
  "refUpdates": [
    {
      "name": "refs/heads/master",
      "oldObjectId": "$lastCommitId"
    }
  ],
  "commits": [
    {
      "comment": "$Comment",
      "changes": []
    }
  ]
}
"@ | ConvertFrom-Json

    $template.commits[0].changes = $Changes
    $json = $template | ConvertTo-Json -Depth 5
    # $json = [Newtonsoft.Json.JsonConvert]::SerializeObject($template)


    # $uri = "https://dev.azure.com/$AccountName/$ProjectName/_apis/git/repositories/$($repo.id)/pushes?api-version=$ApiVersion_Git"
    $uri = "https://dev.azure.com/$AccountName/_apis/git/repositories/$($repo.id)/pushes?api-version=6.1-preview.2"


    Invoke-RestMethod -Uri $uri -Method POST -Body $json -ContentType "application/json" -Headers $Headers | Out-Null
}

function New-ADOGitRepository {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [string] $ProjectName,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,

        [Parameter(Mandatory = $true)]
        [string] $RepositoryName
    )

    $body = @"
{
  "name": "$RepositoryName",
  "project": {
    "id": "$ProjectId"
  }
}
"@
    $uri = "https://dev.azure.com/$AccountName/$ProjectName/_apis/git/repositories/?api-version=$ApiVersion_Git"
    # $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/git/repositories/?api-version=$ApiVersion_Git"
    return Invoke-RestMethod -Uri $uri -Method Post -Headers $Headers -Body $body -ContentType "application/json"
}