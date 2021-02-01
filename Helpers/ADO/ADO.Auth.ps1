#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

function New-ADOPatAuthHeader {
    [CmdletBinding()]
    param
    (
        [string]$Username,
        [string]$PersonalAccessToken
    )
    $InformationPreference = "continue"
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

    try {
        $basicAuth = ('{0}:{1}' -f $Username, $PersonalAccessToken)
        $basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
        $basicAuth = [System.Convert]::ToBase64String($basicAuth)
        $headers = @{
            Authorization = ('Basic {0}' -f $basicAuth)
        }
    
        return $headers
    } catch {
        throw $_
    }
}


Function Get-AADToken {
       
    [CmdletBinding()]
    [OutputType([string])]
    PARAM (
      [Parameter(Position=0,Mandatory=$true)]
      [ValidateScript({
            try 
            {
              [System.Guid]::Parse($_) | Out-Null
              $true
            } 
            catch 
            {
              $false
            }
      })]
      [Alias('tID')]
      [String]$TenantID,
  
      [Parameter(Position=1,Mandatory=$true)][Alias('cred')]
      [pscredential]
      [System.Management.Automation.CredentialAttribute()]
      $Credential,
      
      [Parameter(Position=0,Mandatory=$false)][Alias('type')]
      [ValidateSet('UserPrincipal', 'ServicePrincipal')]
      [String]$AuthenticationType = 'UserPrincipal'
    )
    Try
    {
      $Username       = $Credential.Username
      $Password       = $Credential.Password
  
      If ($AuthenticationType -ieq 'UserPrincipal')
      {
 
        # Set Authority to Azure AD Tenant
        $authority = 'https://login.microsoftonline.com/common/' + $TenantID
        Write-Verbose "Authority: $authority"
  
        $AADcredential = [Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential]::new($UserName)
        $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority)
        # $authResult = $authContext.AcquireTokenAsync("499b84ac-1321-427f-aa17-267ca6975798", "872cd9fa-d31f-45e0-9eab-6e460a02d1f1",$AADcredential)
        $authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext,"499b84ac-1321-427f-aa17-267ca6975798", "872cd9fa-d31f-45e0-9eab-6e460a02d1f1",$AADcredential)                   

        $Token = $authResult.Result.CreateAuthorizationHeader()

  

      } else {
  
        # Set Authority to Azure AD Tenant
        $authority = 'https://login.windows.net/' + $TenantId
  
        $ClientCred = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential]::new($UserName, $Password)
        $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority)
        $authResult = $authContext.AcquireTokenAsync("499b84ac-1321-427f-aa17-267ca6975798", "872cd9fa-d31f-45e0-9eab-6e460a02d1f1",$ClientCred)
        $Token = $authResult.Result.CreateAuthorizationHeader()
      }
      
    }
    Catch
    {
      Throw $_
      $ErrorMessage = 'Failed to aquire Azure AD token.'
      Write-Error -Message 'Failed to aquire Azure AD token'
    }
    $Token
  }
