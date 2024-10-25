. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$type = $env:type
$country = $env:country
if ($env:startArtifactVersion) {
    $startArtifactVersion = [System.Version]"$env:startArtifactVersion"
}
else {
    $startArtifactVersion = [System.Version]"0.0.0.0"
}
$registryPassword = $env:registryPassword
$registry = 'fkregistry'
$registryFQ = "$registry.azurecr.io"

# Download ORAS
$version = "1.2.0"
$filename = Join-Path $env:TEMP "oras_$($version)_windows_amd64.zip"
Invoke-RestMethod -Method GET -UseBasicParsing -Uri "https://github.com/oras-project/oras/releases/download/v$($version)/oras_$($version)_windows_amd64.zip" -OutFile $filename
Expand-Archive -Path $filename -DestinationPath temp

$registryPassword | ./temp/oras.exe login --username $registry --password-stdin $registryFQ

Write-Host "Type: $type"
Write-Host "Country: $country"
Write-Host "StartArtifactVersion: $startArtifactVersion"

$existingTags = ./temp/oras.exe repo tags "$registryFQ/$type"
$existingTags | Out-Host

$artifacts = get-bcartifacturl -type $type -country $country -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion }
$artifacts | ForEach-Object {
    $tag = "$("$_".Split('/')[4])-$("$_".Split('/')[5])"
    if ($existingTags -notcontains $tag) {
        Write-Host $_

    }
}
