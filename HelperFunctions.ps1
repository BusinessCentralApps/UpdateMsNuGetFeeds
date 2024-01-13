$bcContainerHelperVersion = 'https://bccontainerhelper.blob.core.windows.net/public/preview.zip'
$bcContainerHelperVersion = "https://github.com/freddydk/navcontainerhelper/archive/refs/heads/nuget.zip"

$tempName = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
Write-Host "Downloading BcContainerHelper developer version from $bcContainerHelperVersion"
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile($bcContainerHelperVersion, "$tempName.zip")
Expand-Archive -Path "$tempName.zip" -DestinationPath "$tempName"
Remove-Item "$tempName.zip"
$bcContainerHelperPath = (Get-Item -Path (Join-Path $tempName "*\BcContainerHelper.ps1")).FullName
. $bcContainerHelperPath

$bcContainerHelperConfig.DoNotUseCdnForArtifacts = $true

$ErrorActionPreference = "stop"
