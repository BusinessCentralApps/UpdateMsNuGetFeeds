. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

if ($env:startArtifactVersion) {
    $startArtifactVersion = [System.Version]"$env:startArtifactVersion"
}
else {
    $startArtifactVersion = [System.Version]"0.0.0.0"
}

$versionMatrix = @{"matrix" = @{ "include" = @() }; "fail-fast" = $false; "max-parallel" = 1 }
$sandboxVersions = @(Get-BcArtifactUrl -type 'sandbox' -country 'w1' -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion } | ForEach-Object { $version = [System.Version]$_.Split('/')[4]; return "$($version.Major).$($version.Minor)" } | Select-Object -Unique)

$sandboxVersions | ForEach-Object {
    $versionMatrix.matrix.include += @{"type" = "sandbox"; "version" = "$_" }
}
$onpremVersions = @(Get-BcArtifactUrl -type 'onprem' -country 'w1' -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion } | ForEach-Object { $version = [System.Version]$_.Split('/')[4]; return "$($version.Major).$($version.Minor)" } | Select-Object -Unique)
$onpremVersions | ForEach-Object {
    $versionMatrix.matrix.include += @{"type" = "onprem"; "version" = "$_" }
}
ConvertTo-Json $versionMatrix -Depth 99 | Out-Host
Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "versionMatrixJson=$(ConvertTo-Json -InputObject $versionMatrix -Depth 99 -Compress)"
