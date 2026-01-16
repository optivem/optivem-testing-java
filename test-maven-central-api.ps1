#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local test script for Maven Central API interactions
.DESCRIPTION
    Tests the deployment validation and publishing workflow locally without running the full GitHub Actions workflow
.EXAMPLE
    .\test-maven-central-api.ps1 -DeploymentId "your-deployment-id-here"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$DeploymentId,
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$SonatypeUsername = $env:SONATYPE_USERNAME,
    
    [Parameter(Mandatory=$false)]
    [string]$SonatypePassword = $env:SONATYPE_PASSWORD
)

# Color output helpers
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

Write-Host ""
Write-Host "🧪 Maven Central API Test Script" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta
Write-Host ""

# Check credentials
if (-not $SonatypeUsername -or -not $SonatypePassword) {
    Write-Error "Sonatype credentials not provided"
    Write-Info "Set environment variables:"
    Write-Host "  `$env:SONATYPE_USERNAME = 'your-username'" -ForegroundColor Gray
    Write-Host "  `$env:SONATYPE_PASSWORD = 'your-password'" -ForegroundColor Gray
    Write-Host ""
    Write-Info "Or pass as parameters:"
    Write-Host "  .\test-maven-central-api.ps1 -SonatypeUsername 'user' -SonatypePassword 'pass'" -ForegroundColor Gray
    exit 1
}

# Set up authentication
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${SonatypeUsername}:${SonatypePassword}"))
$headers = @{
    "Authorization" = "Bearer $auth"
    "Accept" = "application/json"
}

$apiBase = "https://central.sonatype.com"

switch ($Action.ToLower()) {
    "status" {
        if (-not $DeploymentId) {
            Write-Error "DeploymentId required for status check"
            Write-Info "Usage: .\test-maven-central-api.ps1 -DeploymentId 'your-id' -Action status"
            exit 1
        }
        
        Write-Info "Checking deployment status..."
        Write-Host "   Deployment ID: $DeploymentId" -ForegroundColor Gray
        Write-Host ""
        
        try {
            $statusUrl = "$apiBase/api/v1/publisher/status?id=$DeploymentId"
            Write-Host "   URL: $statusUrl" -ForegroundColor Gray
            
            $response = Invoke-RestMethod -Uri $statusUrl -Headers $headers -Method Post -ErrorAction Stop
            
            Write-Success "Response received"
            Write-Host ""
            Write-Host "Deployment State: $($response.deploymentState)" -ForegroundColor Cyan
            
            if ($response.PSObject.Properties['deploymentName']) {
                Write-Host "Deployment Name: $($response.deploymentName)" -ForegroundColor Gray
            }
            
            if ($response.PSObject.Properties['purls']) {
                Write-Host "PURLs:" -ForegroundColor Gray
                $response.purls | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
            }
            
            if ($response.PSObject.Properties['errors'] -and $response.errors) {
                Write-Host ""
                Write-Host "Errors:" -ForegroundColor Red
                $response.errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
            }
            
        } catch {
            Write-Error "API call failed: $($_.Exception.Message)"
            if ($_.ErrorDetails.Message) {
                Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
            }
            exit 1
        }
    }
    
    "publish" {
        if (-not $DeploymentId) {
            Write-Error "DeploymentId required for publishing"
            Write-Info "Usage: .\test-maven-central-api.ps1 -DeploymentId 'your-id' -Action publish"
            exit 1
        }
        
        Write-Info "Publishing deployment..."
        Write-Host "   Deployment ID: $DeploymentId" -ForegroundColor Gray
        Write-Host ""
        
        try {
            $publishUrl = "$apiBase/api/v1/publisher/deployment/$DeploymentId"
            Write-Host "   URL: $publishUrl" -ForegroundColor Gray
            
            $response = Invoke-RestMethod -Uri $publishUrl -Headers $headers -Method Post -ErrorAction Stop
            
            Write-Success "Deployment published successfully!"
            
        } catch {
            Write-Error "Publish failed: $($_.Exception.Message)"
            if ($_.Exception.Response) {
                Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Gray
            }
            if ($_.ErrorDetails.Message) {
                Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
            }
            exit 1
        }
    }
    
    "wait" {
        if (-not $DeploymentId) {
            Write-Error "DeploymentId required for wait"
            Write-Info "Usage: .\test-maven-central-api.ps1 -DeploymentId 'your-id' -Action wait"
            exit 1
        }
        
        Write-Info "Testing wait-for-deployment-validation action..."
        Write-Host ""
        
        & "$PSScriptRoot\.github\actions\wait-for-deployment-validation\wait-for-deployment-validation.ps1" `
            -DeploymentId $DeploymentId `
            -SonatypeUsername $SonatypeUsername `
            -SonatypePassword $SonatypePassword `
            -MaxAttempts 5 `
            -PollInterval 5
    }
    
    "full" {
        if (-not $DeploymentId) {
            Write-Error "DeploymentId required for full test"
            Write-Info "Usage: .\test-maven-central-api.ps1 -DeploymentId 'your-id' -Action full"
            exit 1
        }
        
        Write-Info "Running full workflow test..."
        Write-Host ""
        
        # Step 1: Wait for validation
        Write-Host "Step 1: Wait for deployment validation" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Magenta
        & "$PSScriptRoot\.github\actions\wait-for-deployment-validation\wait-for-deployment-validation.ps1" `
            -DeploymentId $DeploymentId `
            -SonatypeUsername $SonatypeUsername `
            -SonatypePassword $SonatypePassword `
            -MaxAttempts 5 `
            -PollInterval 5
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Validation check failed"
            exit 1
        }
        
        Write-Host ""
        Write-Host "Step 2: Publish deployment" -ForegroundColor Magenta
        Write-Host "===========================" -ForegroundColor Magenta
        & "$PSScriptRoot\.github\actions\publish-central-deployment\publish-central-deployment.ps1" `
            -DeploymentId $DeploymentId `
            -ReleaseVersion "test" `
            -SonatypeUsername $SonatypeUsername `
            -SonatypePassword $SonatypePassword
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Publishing failed"
            exit 1
        }
        
        Write-Success "Full workflow test completed!"
    }
    
    default {
        Write-Error "Unknown action: $Action"
        Write-Host ""
        Write-Info "Available actions:"
        Write-Host "  status  - Check deployment status" -ForegroundColor Gray
        Write-Host "  publish - Publish a deployment" -ForegroundColor Gray
        Write-Host "  wait    - Test validation waiting" -ForegroundColor Gray
        Write-Host "  full    - Test full workflow (wait + publish)" -ForegroundColor Gray
        Write-Host ""
        Write-Info "Examples:"
        Write-Host "  .\test-maven-central-api.ps1 -DeploymentId 'abc-123' -Action status" -ForegroundColor Gray
        Write-Host "  .\test-maven-central-api.ps1 -DeploymentId 'abc-123' -Action wait" -ForegroundColor Gray
        Write-Host "  .\test-maven-central-api.ps1 -DeploymentId 'abc-123' -Action full" -ForegroundColor Gray
        exit 1
    }
}

Write-Host ""
Write-Success "Test completed"
