#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
function Get-ADOUsers {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )
    $uri = "https://vssps.dev.azure.com/$AccountName/_apis/graph/users?api-version=6.1-preview.1"
            
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers

    return $response.value    
}    

function Get-ADOGroups {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )
    $uri = "https://vssps.dev.azure.com/$AccountName/_apis/graph/groups?api-version=6.1-preview.1"
            
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers

    return $response.value    
}    


function Add-ADOGroupMember {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $AccountName,

        [Parameter(Mandatory = $true)]
        [string] $SubjectDescriptor,

        [Parameter(Mandatory = $true)]
        [string] $ContainerDescriptor,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Headers
    )
    $uri = "https://vssps.dev.azure.com/$AccountName/_apis/graph/memberships/$SubjectDescriptor/$ContainerDescriptor`?api-version=6.1-preview.1"
            
    $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $Headers

    return $response    
}    