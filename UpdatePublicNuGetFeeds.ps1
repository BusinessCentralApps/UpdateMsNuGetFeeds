Write-Host "Move All"

. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$repo = $env:GITHUB_REPOSITORY
$feedToken = $env:FEED_TOKEN
$workflow = "Generate NuGet Packages"

gh auth login --with-token
$runs = @(gh run list --repo $repo --workflow $env:GITHUB_WORKFLOW --status in_progress)
if ($runs.count -gt 1) {
  throw "Another instance is already in progress"
}
$runs = gh run list --repo $repo --workflow $workflow --status in_progress
if ($runs) {
  throw "Another run is already in progress"
}

$artifacts = get-bcartifacturl -type sandbox -country w1 -select all
$minimumVersion = [System.Version]"17.0.0.0"
$artifactVersions = @()
$majorminors = $artifacts | ForEach-Object { [System.Version]$_.Split('/')[4] } | Where-Object { $_ -ge $minimumVersion } | Group-Object { "$($_.Major).$($_.Minor)" }
foreach($majorminor in $majorminors) {
    $addVersions = $majorminor.Group | Select-Object -Last 1 | ForEach-Object { "$_" }
    $artifactVersions += @($addVersions)
}

1..2 | ForEach-Object {
    $dependencyVersionTemplate = '[{major}.{minor}.{build}.{revision},{major}.{minor+1}.0.0)'
    $symbolsOnly = "$($_ -eq 1)".ToLowerInvariant()
    if ($symbolsOnly -eq 'true') {
        $name = "MSSymbols"
        $symbolsStr = '.symbols'
    }
    else {
        $name = "MSApps"
        $symbolsStr = ''
    }
    $nuGetServerUrl = "https://dynamicssmb2.pkgs.visualstudio.com/DynamicsBCPublicFeeds/_packaging/$name/nuget/v3/index.json"
#    $nuGetServerUrl = "https://pkgs.dev.azure.com/freddydk/apps/_packaging/$name/nuget/v3/index.json"
    $artifactVersions | ForEach-Object {
        $artifactVersion = "$_"
        $feed, $packageId, $packageVersion = Find-BcNuGetPackage -nuGetServerUrl $nuGetServerUrl -nuGetToken $feedToken -packageName "Microsoft.BaseApplication$symbolsStr.437dbf0e-84ff-417a-965d-ed2bb9650972" -version $artifactVersion -select Exact
        if (!$packageId) {
            $runname = "$name-$artifactVersion"
            Write-Host -ForegroundColor Yellow "$runname"
            gh workflow run --repo $repo $workflow -f nuGetServerUrl=$nuGetServerUrl -f nuGetToken=$feedToken -f artifactVersion=$artifactVersion -f symbolsOnly=$symbolsOnly -f dependencyVersionTemplate=$dependencyVersionTemplate -f run-name=$runname
            Start-Sleep -Seconds 450
        }
    }
}
