Write-Host "Move All"

. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$repo = $env:GITHUB_REPOSITORY
$nuGetFeed = $env:NUGET_FEED
$feedToken = $env:FEED_TOKEN
$workflow = "Generate MS NuGet Packages"

gh auth login --with-token
$runs = gh run list --repo $repo --workflow $env:GITHUB_WORKFLOW --status in_progress
if ($runs) {
  throw "Another instance is already in progress"
}
$runs = gh run list --repo $repo --workflow $workflow --status in_progress
if ($runs) {
  throw "Another run is already in progress"
}

