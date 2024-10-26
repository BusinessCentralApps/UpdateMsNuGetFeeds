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

$versions = Get-BcArtifactUrl -type $type -version $version -country w1 -select all | Sort-Object { [System.Version]$_.Split('/')[4] } -Descending | ForEach-Object { $_.Split('/')[4] } | Select-Object -First 2
$versions | ForEach-Object {
    $thisVersion = $_
    Write-Host "Version: $thisVersion"
    $artifacts = Get-BcArtifactUrl -type $type -version $thisVersion -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion }
    $artifacts | ForEach-Object {
        $artifactUrl = $_
        Write-Host "ArtifactUrl: $artifactUrl"
        $country = $artifactUrl.Split('/')[5]
        $tag = "$thisVersion-$country"
        Write-Host -NoNewline "Tag: $tag "
        if ($existingTags -contains $tag) {
            Write-Host "exists"
        }
        else {
            Write-Host "doesn't exist"
            if ($country -eq 'core') {
                $path = Download-Artifacts -artifactUrl $artifactUrl
                Set-Location -Path (Join-Path $path '..' -Resolve)
                & $orasExePath push "$registryFQ/$($type):$tag" .\$country\:application/x-tar
            }
            else {
                $paths = Download-Artifacts -artifactUrl $artifactUrl -includePlatform
                Set-Location -Path (Join-Path $paths[0] '..' -Resolve)
                & $orasExePath push "$registryFQ/$($type):$tag" .\$country\:application/x-tar .\platform\:application/x-tar
                if ($country -eq 'w1' -and $existingTags -notcontains "$thisVersion-platform") {
                    & $orasExePath push "$registryFQ/$($type):$thisVersion-platform" .\platform\:application/x-tar
                }
            }
        }
    }
    Flush-ContainerHelperCache
}
