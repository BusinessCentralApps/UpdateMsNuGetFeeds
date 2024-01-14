Write-Host "Calculate Packages"

. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$artifactType = $env:artifactType
if ($artifactType -eq '') { $artifactType = 'sandbox' }
$artifactVersion = $env:artifactVersion
$package = $env:package

$artifactUrl = Get-BcArtifactUrl -type $artifactType -version $artifactVersion -country $package
$folders = Download-Artifacts -artifactUrl $artifactUrl -includePlatform:($package -eq 'base')

foreach($folder in $folders) {
    $name = [System.IO.Path]::GetFileName($folder)
    Write-Host "artifactType: $artifactType"
    Write-host "artifactVersion: $artifactVersion"
    Write-Host "package: $package"
    Write-Host "folder: $folder"
    Write-Host "name: $name"
}
