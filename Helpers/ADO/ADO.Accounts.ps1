#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

$ApiVersion_Accounts = "6.1-preview.1"

. "$PSScriptRoot\ADO.Common.ps1"

function Get-ADOAccountList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [guid] $MemberId,

        [Parameter(Mandatory = $false)]
        [guid] $OwnerId,

        [Parameter(Mandatory = $false)]
        [switch] $RawOutput
    )

    Process {
        $params = @{}

        if ($MemberId) {
            $params.Add("memberId", $MemberId)
        }

        if ($OwnerId) {
            $params.Add("ownerId", $OwnerId)
        }
    
        $uri = "https://app.vssps.visualstudio.com/_apis/Accounts?$(ConvertTo-QueryString $params)&api-version=$ApiVersion_Accounts"
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers
    
        if ($RawOutput) {
            return $response
        }
        else {
            return $response.value    
        }    
    }
}