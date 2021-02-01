#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ManifestLocation = '..\Manifests\Onboarding\onboardRequest.json',

    [Parameter()]
    [string]
    $PAT
)

$manifest = (Get-Content $ManifestLocation) | ConvertFrom-Json

$teams = $manifest.Teams

.\Onboard-DevOps.ps1 -OrgName $manifest.OrganisationName `
                     -ProjectName $manifest.ProjectName `
                     -PAT $PAT `
                     -RepoName $manifest.Repository `
                     -Teams $teams `
                     -PatternName $manifest.Pattern

