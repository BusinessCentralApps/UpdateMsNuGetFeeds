Write-Host "Move All"

. (Join-Path $PSScriptRoot "HelperFunctions.ps1")

$repo = $env:GITHUB_REPOSITORY
$workflow = "Generate Business Central Artifacts"

gh auth login --with-token
gh auth status
$runs = gh run list --repo $repo --workflow $workflow --status in_progress
if ($runs) {
  throw "There are runs in progress"
}

'bcartifacts','bcinsider' | ForEach-Object {
    $storageAccount = $_
    'onprem','sandbox' | Where-Object { $_ -eq 'sandbox' -or $storageAccount -eq 'bcartifacts' } | ForEach-Object {
        $type = $_
        $feedUrl = "https://dev.azure.com/freddydk/apps/_artifacts/feed/$storageAccount"
        $feedApiUrl = "https://feeds.dev.azure.com/freddydk/apps/_apis/packaging/Feeds/$storageAccount"
        $artifacts = Get-BCArtifactUrl -storageAccount $storageAccount -type $type -select all -accept_insiderEula
        $artifactVersions = @($artifacts | ForEach-Object {
            $version = $_.Split('/')[4]
            $country = $_.Split('/')[5]
            "$version/$country"
            if ($country -eq 'base') {
                "$version/platform"
            }
        })
        $artifactVersions.Count | Out-Host

        $result = invoke-restmethod -UseBasicParsing -Uri "$feedApiUrl/packages?api-version=7.0&packageNameQuery=$type&includeAllVersions=true"
        $universalVersions = @($result.value | ForEach-Object {
            $major = $_.name.Split('.')[2]
            $country = $_.name.Split('.')[1]
            $_.versions | ForEach-Object {
                return "$major.$($_.version)/$country"
            }
        })
        $universalVersions.Count | Out-Host

        $missingVersions = Compare-Object -ReferenceObject $artifactVersions -DifferenceObject $universalVersions | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }
        $missingVersions | Out-Host
        $missingVersions.count | Out-Host

        $missingVersions | Group-Object { $_.Split('/')[0] } | ForEach-Object {
            $version = $_.Name
            if ($artifactVersions -notcontains "$version/at") {
                Write-Host "AT not yet available for $version, skipping for now"
            }
            elseif ($_.Group.Count -gt 10) {
                $runname = "$storageAccount $type $version all"
                Write-Host $runname
                gh workflow run --repo $repo $workflow -f feedUrl=$feedUrl -f feedToken=$adoKey -f storageAccount=$storageAccount -f artifactType=$type -f artifactVersion=$version -f run-name=$runname
                Start-Sleep -Seconds $_.Group.Count
            }
            else {
                $_.Group | ForEach-Object {
                    $country = $_.Split('/')[1]
                    $runname = "$storageAccount $type $version $country"
                    Write-Host $runname
                    gh workflow run --repo $repo $workflow -f feedUrl=$feedUrl -f feedToken=$adoKey -f storageAccount=$storageAccount -f artifactType=$type -f artifactVersion=$version -f country=$country -f run-name=$runname
                    Start-Sleep -Seconds 5
                }
            }
        }
    }
}
