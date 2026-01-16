param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentId,
    
    [Parameter(Mandatory=$true)]
    [string]$ExpectedState,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypeUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypePassword,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxAttempts = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$PollInterval = 10
)

Write-Host "⏳ Waiting for deployment state: $ExpectedState" -ForegroundColor Blue
Write-Host "   Deployment ID: $DeploymentId" -ForegroundColor Gray
Write-Host "   Expected state: $ExpectedState" -ForegroundColor Cyan
Write-Host "   Max attempts: $MaxAttempts" -ForegroundColor Gray
Write-Host "   Poll interval: ${PollInterval}s" -ForegroundColor Gray
Write-Host ""

# Set up authentication headers
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${SonatypeUsername}:${SonatypePassword}"))
$headers = @{
    "Authorization" = "Bearer $auth"
    "Accept" = "application/json"
}

$apiBase = "https://central.sonatype.com"
$statusUrl = "$apiBase/api/v1/publisher/status?id=$DeploymentId"

$attempt = 0
$validated = $false

while ($attempt -lt $MaxAttempts) {
    $attempt++
    
    Write-Host "[$attempt/$MaxAttempts] Checking deployment status..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri $statusUrl -Headers $headers -Method Post -ErrorAction Stop
        
        $state = $response.deploymentState
        Write-Host "   Status: $state" -ForegroundColor Cyan
        
        # Check if we've reached the expected state
        if ($state -eq $ExpectedState) {
            Write-Host ""
            Write-Host "✅ Deployment reached expected state: $ExpectedState" -ForegroundColor Green
            $validated = $true
        }
        # Check for error states
        elseif ($state -eq "FAILED") {
            Write-Host ""
            Write-Host "❌ Deployment failed" -ForegroundColor Red
            if ($response.PSObject.Properties['errors'] -and $response.errors) {
                Write-Host ""
                Write-Host "Errors:" -ForegroundColor Red
                $response.errors | ForEach-Object { 
                    Write-Host "  • $_" -ForegroundColor Red 
                }
            }
            exit 1
        }
        # Progress messages for different states
        else {
            switch ($state) {
                "PENDING" {
                    Write-Host "   ⏳ Status: PENDING (waiting to start...)" -ForegroundColor Gray
                }
                "VALIDATING" {
                    Write-Host "   🔍 Status: VALIDATING (in progress...)" -ForegroundColor Gray
                }
                "VALIDATED" {
                    Write-Host "   ✓ Status: VALIDATED (waiting for: $ExpectedState)" -ForegroundColor Gray
                }
                "PUBLISHING" {
                    Write-Host "   📤 Status: PUBLISHING (waiting for: $ExpectedState)" -ForegroundColor Gray
                }
                "PUBLISHED" {
                    Write-Host "   ✓ Status: PUBLISHED (waiting for: $ExpectedState)" -ForegroundColor Gray
                }
                default {
                    Write-Host "   ⚠️  Status: $state (waiting for: $ExpectedState)" -ForegroundColor Yellow
                }
            }
        }
        
        if ($validated) {
            break
        }
        
    } catch {
        Write-Host "   ⚠️  Error checking status: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.ErrorDetails.Message) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
    }
    
    if ($attempt -lt $MaxAttempts -and -not $validated) {
        Write-Host "   Waiting ${PollInterval}s before next check..." -ForegroundColor Gray
        Start-Sleep -Seconds $PollInterval
    }
}

if (-not $validated) {
    Write-Host ""
    Write-Host "❌ Timed out waiting for state '$ExpectedState' after $MaxAttempts attempts" -ForegroundColor Red
    Write-Host "   Last state: $state" -ForegroundColor Yellow
    Write-Host "   Check status at: https://central.sonatype.com/publishing/deployments" -ForegroundColor Yellow
    exit 1
}
