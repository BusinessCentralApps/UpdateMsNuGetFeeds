. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$type = $env:type
$country = $env:country
if ($env:startArtifactVersion) {
    $startArtifactVersion = [System.Version]"$env:startArtifactVersion"
}
else {
    $startArtifactVersion = [System.Version]"0.0.0.0"
}

$artifacts = get-bcartifacturl -type $type -country $country -select all | Where-Object { [System.Version]$_.Split('/')[4] -ge $startArtifactVersion }
$artifacts | ForEach-Object {
    Write-Host $_
}
