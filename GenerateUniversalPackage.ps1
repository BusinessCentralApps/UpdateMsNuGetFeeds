Write-Host "Calculate Packages"

. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$artifactType = $env:artifactType
if ($artifactType -eq '') { $artifactType = 'sandbox' }
$artifactVersion = $env:artifactVersion
$package = $env:package

# https://dev.azure.com/freddydk/apps/_artifacts/feed/universal
$feedUrl = $env:feedUrl
if ($feedUrl -match '^(https:\/\/dev\.azure\.com\/[^\/]+\/)([^\/]+)\/_artifacts\/feed\/([^\/]+)$') {
    $organization = $matches[1]
    $project = $matches[2]
    $feed = $matches[3]
}
else {
    throw "Invalid feedUrl '$feedUrl'"
}
$feedToken = $env:feedToken
$env:AZURE_DEVOPS_EXT_PAT = $feedToken

$artifactUrl = Get-BcArtifactUrl -type $artifactType -version $artifactVersion -country $package
$folders = Download-Artifacts -artifactUrl $artifactUrl -includePlatform:($package -eq 'base')

foreach($folder in $folders) {
    $name = [System.IO.Path]::GetFileName($folder)
    Write-Host "artifactType: $artifactType"
    Write-host "artifactVersion: $artifactVersion"
    Write-Host "package: $package"
    Write-Host "folder: $folder"
    Write-Host "name: $name"
    $version = [System.Version]$artifactVersion
    $packageName = "$($artifactType).$($version.Major).$($package)"
    $packageVersion = "$($version.Major).$($version.Build).$($version.Revision)"
    $packageDescription = "Package for $artifactType $artifactVersion $package"
    az artifacts universal publish --organization $organization --project=$project --scope project --feed $feed --name $packageName --version $packageVersion --description $packageDescription --path .
}
