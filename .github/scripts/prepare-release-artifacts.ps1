#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Prepares release artifacts by copying and renaming RC artifacts

.PARAMETER RcVersion
    The RC version to rename from

.PARAMETER ReleaseVersion
    The release version to rename to

.EXAMPLE
    .\prepare-release-artifacts.ps1 -RcVersion "1.0.5-rc.47" -ReleaseVersion "1.0.5"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RcVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion
)

Write-Host "📦 Preparing release artifacts..." -ForegroundColor Blue

# Verify downloaded artifacts exist
Write-Host "🔍 Verifying downloaded artifacts..." -ForegroundColor Yellow
if (-not (Test-Path "temp-artifacts")) {
    Write-Host "❌ temp-artifacts directory not found!" -ForegroundColor Red
    exit 1
}

Get-ChildItem temp-artifacts/ | Format-Table -AutoSize

$expectedFiles = @(
    "optivem-test-${RcVersion}.jar",
    "optivem-test-${RcVersion}-sources.jar", 
    "optivem-test-${RcVersion}-javadoc.jar"
)

foreach ($file in $expectedFiles) {
    if (-not (Test-Path "temp-artifacts\$file")) {
        Write-Host "❌ Missing expected file: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ All expected artifacts found" -ForegroundColor Green

# Create output directory
New-Item -ItemType Directory -Path "core\build\libs" -Force | Out-Null

# Copy and rename artifacts for release
Copy-Item "temp-artifacts\optivem-test-${RcVersion}.jar" "core\build\libs\optivem-test-${ReleaseVersion}.jar"
Copy-Item "temp-artifacts\optivem-test-${RcVersion}-sources.jar" "core\build\libs\optivem-test-${ReleaseVersion}-sources.jar" 
Copy-Item "temp-artifacts\optivem-test-${RcVersion}-javadoc.jar" "core\build\libs\optivem-test-${ReleaseVersion}-javadoc.jar"

Write-Host "✅ Release artifacts prepared" -ForegroundColor Green
Get-ChildItem "core\build\libs\" | Format-Table -AutoSize