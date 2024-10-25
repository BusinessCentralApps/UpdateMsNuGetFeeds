. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$type = $env:type
$version = $env:version
$registryPassword = $env:registryPassword
$registry = 'fkregistry'
$registryFQ = "$registry.azurecr.io"

# Download ORAS
$version = "1.2.0"
$filename = Join-Path $env:TEMP "oras_$($version)_windows_amd64.zip"
Invoke-RestMethod -Method GET -UseBasicParsing -Uri "https://github.com/oras-project/oras/releases/download/v$($version)/oras_$($version)_windows_amd64.zip" -OutFile $filename
Expand-Archive -Path $filename -DestinationPath temp
$orasExePath = Join-Path './temp' 'oras.exe' -Resolve

$registryPassword | & $orasExePath login --username $registry --password-stdin $registryFQ

Write-Host "Type: $type"
Write-Host "Version: $version"
Write-Host "StartArtifactVersion: $startArtifactVersion"

$existingTags = @()
$existingTags = & $orasExePath repo tags "$registryFQ/$type"
if ("$?" -eq "0") {
    Write-Host "Existiung Tags:"
    $existingTags | Out-Host
}

$artifacts = Get-BcArtifactUrl -type $type -version $version -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion }
$artifacts | ForEach-Object {
    $artifactUrl = $_
    $country = $artifactUrl.Split('/')[5]
    $tag = "$version-$country"
    if ($existingTags -notcontains $tag) {
        Write-Host $artifactUrl
        if ($country -eq 'core') {
            $path = Download-Artifacts -artifactUrl $artifactUrl
            Set-Location -Path (Join-Path $path '..' -Resolve)
            & $orasExePath push "$registryFQ/$($type):$tag" .\$country\:application/x-tar
        }
        else {
            $paths = Download-Artifacts -artifactUrl $artifactUrl -includePlatform
            Set-Location -Path (Join-Path $paths[0] '..' -Resolve)
            & $orasExePath push "$registryFQ/$($type):$tag" .\$country\:application/x-tar .\platform\:application/x-tar
            if ($country -eq 'w1' -and $existingTags -notcontains "$version-platform") {
                & $orasExePath push "$registryFQ/$($type):$version-platform" .\platform\:application/x-tar
            }
        }
    }
}
