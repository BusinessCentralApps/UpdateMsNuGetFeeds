. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

if ($env:startArtifactVersion) {
    $startArtifactVersion = [System.Version]"$env:startArtifactVersion"
}
else {
    $startArtifactVersion = [System.Version]"0.0.0.0"
}

$versionMatrix = @{"matrix" = @{ "include" = @() }; "fail-fast" = $false; "max-parallel" = 1 }

$sandboxVersions = @(Get-BcArtifactUrl -type 'sandbox' -country 'w1' -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion } | ForEach-Object { $_.Split('/')[4] })
$sandboxVersions | ForEach-Object {
    $versionMatrix.matrix.include += @{"type" = "sandbox"; "version" = "$_" }
}
$onpremVersions = @(Get-BcArtifactUrl -type 'onprem' -country 'w1' -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion } | ForEach-Object { $_.Split('/')[4] })
$onpremVersions | ForEach-Object {
    $versionMatrix.matrix.include += @{"type" = "onprem"; "version" = "$_" }
}
ConvertTo-Json $versionMatrix | Out-Host
Add-Content -Path $ENV:GITHUB_ENV -Value "versionMatrixJson=$(ConvertTo-Json -InputObject $versionMatrix)" -Encoding UTF8
