[CmdletBinding()]
param ()

$Task = ($MyInvocation.MyCommand.Name).split('.')[0]
Write-Output "$Task-Install-Modules"

$InstallPath = $env:PSModulePath -split $([System.IO.Path]::PathSeparator) | Select-Object -First 1
Write-Output "$Task-Install-Modules - $InstallPath - Found installation path"
if (! (Test-Path -Path $InstallPath)){
    try {
        Write-Output "$Task-Install-Modules - $InstallPath - Folder does not exist, creating"
        New-Item -Path $InstallPath -ItemType "directory" -Force | Out-Null
    } catch {
        throw "$Task-Install-Modules - $InstallPath -  Folder creation failed"
    }
}

Write-Output "$Task-Install-Modules - $InstallPath -  Created"

Write-Output "$Task-Install-Modules - $InstallPath - Installing..."
(Get-ChildItem -Path "$env:GITHUB_ACTION_PATH\Modules\" -Recurse).FullName | Foreach-Object { Write-Output "  - $_" }
Get-ChildItem -Path "$env:GITHUB_ACTION_PATH\Modules\" | Copy-Item -Destination $InstallPath -Recurse

Write-Output "$Task-Install-Modules - Installed Modules"
(Get-ChildItem $InstallPath -Recurse).FullName | ForEach-Object { Write-Output "  - $_" }
