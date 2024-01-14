Write-Host "Calculate Packages"

. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$artifactType = $env:artifactType
$artifactVersion = $env:artifactVersion
$package = $env:package

# feedUrl is like https://dev.azure.com/freddydk/apps/_artifacts/feed/universal
$feedUrl = $env:feedUrl
if ($feedUrl -match '^(https:\/\/dev\.azure\.com\/[^\/]+\/)([^\/]+)\/_artifacts\/feed\/([^\/]+)$') {
    $organization = $matches[1]
    $project = $matches[2]
    $feed = $matches[3]
}
else {
    throw "Invalid feedUrl '$feedUrl'"
}

$artifactUrl = Get-BcArtifactUrl -type $artifactType -version $artifactVersion -country $package
$folders = Download-Artifacts -artifactUrl $artifactUrl -includePlatform:($package -eq 'base')

foreach($folder in $folders) {
    Set-Location $folder
    $name = [System.IO.Path]::GetFileName($folder).ToLowerInvariant()
    Write-Host "artifactType: $artifactType"
    Write-host "artifactVersion: $artifactVersion"
    Write-Host "package: $package"
    Write-Host "folder: $folder"
    Write-Host "name: $name"
    $version = [System.Version]$artifactVersion
    $packageName = "$($artifactType).$($name).$($version.Major)"
    $packageVersion = "$($version.Minor).$($version.Build).$($version.Revision)"
    $packageDescription = "Package for $artifactType $artifactVersion $name"
    Write-Host "Uploading $packageName.$packageVersion to $feed"
    az artifacts universal publish --organization $organization --project=$project --scope project --feed $feed --name $packageName --version $packageVersion --description $packageDescription --path .
    Write-Host "done uploading"
}
