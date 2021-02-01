#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

$ApiVersion_Projects = "1.0"
$ApiVersion_Processes = "1.0"
$ApiVersion_Operations = "2.0"

function Get-VstsProcesses {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,

        [Parameter(Mandatory = $false)]
        [switch] $Raw
    )

    $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/process/processes?api-version=$ApiVersion_Processes"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    if ($Raw) {
        return $response
    }
    else {
        return $response.value    
    }

    return $response
}
function Get-VstsProcess {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $false)]
        [string] $ProcessName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers,

        [Parameter(Mandatory = $false)]
        [switch] $FallbackToDefault
    )

    $allProcesses = Get-VstsProcesses -AccountName $AccountName -Headers $Headers
    $template = $allProcesses | Where-Object { $_.name -eq $ProcessName }

    if ($template) {
        return $template
    }

    if ($FallbackToDefault) {
        return $allProcesses | Where-Object { $_.isDefault }
    }
}

function Get-VstsProject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [string] $ProjectName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )

    $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects/$($ProjectName)?api-version=$ApiVersion_Projects"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    return $response
}

function Get-VstsProjects {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )

    $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects?api-version=$ApiVersion_Projects"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    return $response.value
}

function Remove-VstsTeamProject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,
        
        [Parameter(Mandatory = $true)]
        [guid] $ProjectId,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )

    $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects/$($ProjectId)?api-version=$ApiVersion_Projects"
    $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
    $waitTime = 3
    
    while ((Get-VstsOperation -AccountName $AccountName -OperationId $response.id -Headers $Headers).status -ne "succeeded") {
        Write-Warning "Team Project ($ProjectName) is deleting. Waiting for $($waitTime)s for the operation to finish!"
        Start-Sleep -s $waitTime
    }
}

function New-VstsTeamProject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,
        
        [Parameter(Mandatory = $true)]
        [string] $ProjectName,
        
        [Parameter(Mandatory = $false)]
        [string] $Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Git', 'Tfvc')]
        [string] $VersionControlType = 'Git',
        
        [Parameter(Mandatory = $false)]
        [string] $ProcessTemplateName = 'Scrum',

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )

    $processTemplate = Get-VstsProcess -AccountName $AccountName -ProcessName $ProcessTemplateName -Headers $Headers -FallbackToDefault
    $body = @"
{
  "name": "$ProjectName",
  "description": "$Description",
  "capabilities": {
    "versioncontrol": {
      "sourceControlType": "$VersionControlType"
    },
    "processTemplate": {
      "templateTypeId": "$($processTemplate.id)"
    }
  }
}
"@

    $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects?api-version=$ApiVersion_Projects"
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType "application/json"
    $waitTime = 3
    
    while ((Get-VstsOperation -AccountName $AccountName -OperationId $response.id -Headers $Headers).status -ne "succeeded") {
        Write-Warning "Team Project ($ProjectName) is creating. Waiting for $($waitTime)s for the operation to finish!"
        Start-Sleep -s $waitTime
    }

    return Get-VstsProject -AccountName $AccountName -ProjectName $ProjectName -Headers $Headers
}

function Get-VstsOperation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,
        
        [Parameter(Mandatory = $true)]
        [guid] $OperationId,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )

    $uri = "https://$AccountName.visualstudio.com/DefaultCollection/_apis/operations/$($OperationId)?api-version=$ApiVersion_Operations"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    return $response
}