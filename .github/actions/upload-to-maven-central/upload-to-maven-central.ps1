#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates Maven Central bundle from existing artifacts and uploads without rebuilding

.PARAMETER ReleaseVersion
    The release version to upload

.PARAMETER SonatypeUsername
    Sonatype username

.PARAMETER SonatypePassword
    Sonatype password

.PARAMETER GpgPrivateKey
    GPG private key for signing

.PARAMETER GpgPassphrase
    GPG passphrase

.EXAMPLE
    .\upload-to-maven-central.ps1 -ReleaseVersion "1.0.5" -SonatypeUsername "user" -SonatypePassword "pass" -GpgPrivateKey $key -GpgPassphrase $phrase
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypeUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypePassword,
    
    [Parameter(Mandatory=$true)]
    [string]$GpgPrivateKey,
    
    [Parameter(Mandatory=$true)]
    [string]$GpgPassphrase
)

Write-Host "📦 Creating Maven Central bundle from existing artifacts..." -ForegroundColor Blue

$artifactsDir = "core/build/libs"
$bundleDir = "core/build/central-portal-bundle"
$mavenDir = "$bundleDir/com/optivem/optivem-test/$ReleaseVersion"
$bundleZip = "core/build/optivem-test-$ReleaseVersion.zip"

# Verify artifacts exist
$requiredFiles = @(
    "$artifactsDir/optivem-test-$ReleaseVersion.jar",
    "$artifactsDir/optivem-test-$ReleaseVersion-sources.jar",
    "$artifactsDir/optivem-test-$ReleaseVersion-javadoc.jar"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ Missing required artifact: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ All required artifacts found" -ForegroundColor Green

# Create bundle directory structure
if (Test-Path $bundleDir) {
    Remove-Item $bundleDir -Recurse -Force
}
New-Item -ItemType Directory -Path $mavenDir -Force | Out-Null

# Generate POM file
$pomContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.optivem</groupId>
    <artifactId>optivem-test</artifactId>
    <version>$ReleaseVersion</version>
    <packaging>jar</packaging>
    
    <name>Optivem Test Library</name>
    <description>A simple calculator library for testing purposes</description>
    <url>https://github.com/optivem/optivem-test-java</url>
    
    <licenses>
        <license>
            <name>MIT License</name>
            <url>https://opensource.org/licenses/MIT</url>
        </license>
    </licenses>
    
    <developers>
        <developer>
            <id>optivem</id>
            <name>Optivem</name>
            <email>info@optivem.com</email>
        </developer>
    </developers>
    
    <scm>
        <connection>scm:git:git://github.com/optivem/optivem-test-java.git</connection>
        <developerConnection>scm:git:ssh://github.com:optivem/optivem-test-java.git</developerConnection>
        <url>https://github.com/optivem/optivem-test-java</url>
    </scm>
</project>
"@

$pomFile = "$mavenDir/optivem-test-$ReleaseVersion.pom"
$pomContent | Out-File -FilePath $pomFile -Encoding utf8 -NoNewline

# Copy artifacts to bundle
foreach ($file in $requiredFiles) {
    $fileName = Split-Path $file -Leaf
    Copy-Item $file "$mavenDir/$fileName"
}

Write-Host "📝 Importing GPG key..." -ForegroundColor Yellow

# Import GPG key
$gpgKeyFile = [System.IO.Path]::GetTempFileName()
$GpgPrivateKey | Out-File -FilePath $gpgKeyFile -Encoding utf8 -NoNewline

gpg --batch --import $gpgKeyFile 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to import GPG key" -ForegroundColor Red
    Remove-Item $gpgKeyFile -Force
    exit 1
}

Remove-Item $gpgKeyFile -Force

Write-Host "🔐 Signing artifacts..." -ForegroundColor Yellow

# Sign all files
$filesToSign = @(
    "optivem-test-$ReleaseVersion.pom",
    "optivem-test-$ReleaseVersion.jar",
    "optivem-test-$ReleaseVersion-sources.jar",
    "optivem-test-$ReleaseVersion-javadoc.jar"
)

foreach ($fileName in $filesToSign) {
    $filePath = "$mavenDir/$fileName"
    
    # Sign with GPG
    $env:GPG_TTY = $(tty)
    echo $GpgPassphrase | gpg --batch --yes --passphrase-fd 0 --armor --detach-sign $filePath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to sign $fileName" -ForegroundColor Red
        exit 1
    }
    
    # Generate checksums
    $fileContent = [System.IO.File]::ReadAllBytes($filePath)
    
    # MD5
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $md5Hash = [BitConverter]::ToString($md5.ComputeHash($fileContent)).Replace("-", "").ToLower()
    $md5Hash | Out-File -FilePath "$filePath.md5" -Encoding ascii -NoNewline
    
    # SHA1
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $sha1Hash = [BitConverter]::ToString($sha1.ComputeHash($fileContent)).Replace("-", "").ToLower()
    $sha1Hash | Out-File -FilePath "$filePath.sha1" -Encoding ascii -NoNewline
}

Write-Host "✅ All artifacts signed and checksums generated" -ForegroundColor Green

# Create zip bundle
Write-Host "📦 Creating bundle zip..." -ForegroundColor Yellow
if (Test-Path $bundleZip) {
    Remove-Item $bundleZip -Force
}

Compress-Archive -Path "$bundleDir/*" -DestinationPath $bundleZip

Write-Host "✅ Bundle created: $bundleZip" -ForegroundColor Green

# Upload to Central Portal
Write-Host "📤 Uploading to Maven Central..." -ForegroundColor Blue

$curlArgs = @(
    '-X', 'POST',
    'https://central.sonatype.com/api/v1/publisher/upload',
    '-u', "${SonatypeUsername}:${SonatypePassword}",
    '-F', "bundle=@$bundleZip",
    '-F', 'publishingType=USER_MANAGED'
)

& curl @curlArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Upload completed successfully!" -ForegroundColor Green
Write-Host "🔗 Check status: https://central.sonatype.com/publishing/deployments" -ForegroundColor Cyan
