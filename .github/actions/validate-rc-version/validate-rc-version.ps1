#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates RC version format and extracts release version

.PARAMETER RcVersion
    The RC version to validate (e.g., 1.0.5-rc.47)

.EXAMPLE
    .\validate-rc-version.ps1 -RcVersion "1.0.5-rc.47"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RcVersion
)

if ($RcVersion -notmatch '-rc\.[0-9]+$') {
    Write-Host "❌ Invalid RC version format. Expected: X.Y.Z-rc.N" -ForegroundColor Red
    exit 1
}

# Extract release version (remove -rc.N suffix)
$releaseVersion = $RcVersion -replace '-rc\.[0-9]+$', ''

Write-Host "🔄 Promoting RC $RcVersion → Release $releaseVersion" -ForegroundColor Cyan

# Output for GitHub Actions
if ($env:GITHUB_OUTPUT) {
    "rc_version=${RcVersion}" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    "release_version=${releaseVersion}" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
} else {
    # Local testing output
    Write-Host "RC Version: $RcVersion"
    Write-Host "Release Version: $releaseVersion"
}