# Introduction 

We see customers time and time again needing to quickly setup ADO teams and git reporsitories with specific artifacts (ARM templates, Web API starters, Path to production Pipelines, etc) to help accelerate the onbaording of services and development projects.

This sample project is an opinionated demo of how to leverage Azure DevOps Cli extension as well as DevOps REST apis to quickly scaffold up:
- New repostiory
- New Project Teams
- Control permissions
- Push GIT files
- Service Connections
- YAML pipelines

# Getting Started

1.	Run process

    - Place your ARM template structure / yaml pipelines into:
    /Manifest/Patterns/< patternName>
        - I have provided a sample pattern in the demo for you.
    - Generate a Personal Access Token with full permissions to Azure DevOps [Create a PAT](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#create-a-pat) and copy it.
    - Update file under **/Manifests/Onboarding/request.json** to describe your artifact
    - Run:
    ```powershell
    /Scripts/OnboardWithManifest.ps1 -PAT <insertYourPatToken>

2.	Software dependencies
    - [Azure Devlops Cli Client Extension](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
    - PowerShell Core 6.0 Minimum


3.	API references

    [Azure DevOps CLI](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
    
    [Azure DevOps REST APIs](https://docs.microsoft.com/en-us/rest/api/azure/devops/?view=azure-devops-rest-6.1)




# Contribute

- Keep main branch deployable; create new branches for new features / bug fixes and merge them into Main via Pull Requests when they’re completed.
- Raise feature requests / bugs as issues
