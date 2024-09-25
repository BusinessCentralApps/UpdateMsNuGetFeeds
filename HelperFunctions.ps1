$bcContainerHelperVersion = 'https://bccontainerhelper.blob.core.windows.net/public/preview.zip'

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

function GetNuGetServerUrlAndRepository {
    Param(
        [string] $nuGetServerUrl
    )
    if ($nugetServerUrl -match '^https:\/\/github\.com\/([^\/]+)\/([^\/]+)$') {
        $githubRepository = $nuGetServerUrl
        $nuGetServerUrl = "https://nuget.pkg.github.com/$($Matches[1])/index.json"
    }
    else {
        $githubRepository = ''
    }
    return $nuGetServerUrl, $githubRepository
}

function GetAppFile {
    Param(
        [string] $appFile,
        [switch] $symbolsOnly
    )
    Write-Host "'$appFile'"
    Write-Host $appFile.GetType()
    if ($symbolsOnly) {
        $symbolsFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item -Path $symbolsFolder -ItemType Directory | Out-Null
        $symbolsFile = Join-Path $symbolsFolder "$([System.IO.Path]::GetFileNameWithoutExtension(($appFile))).app"
        Write-Host "Creating symbols file $symbolsFile"
        Create-SymbolsFileFromAppFile -appFile $appFile -symbolsFile $symbolsFile | Out-Null
        if (-not (Test-Path $symbolsFile)) {
            throw "Could not create symbols file from $appFile"
        }
        return $symbolsFile
    }
    else {
        return $appFile
    }
}
