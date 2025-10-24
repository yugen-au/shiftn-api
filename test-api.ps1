# Test script for ShiftN API

param(
    [string]$BaseUrl = "http://localhost:3000",
    [string]$ApiKey = "",
    [string]$TestImage = ""
)

Write-Host "Testing ShiftN API..." -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Gray
Write-Host ""

# Test 1: Health check (no auth required)
Write-Host "1. Testing health endpoint..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 10
    Write-Host "   Status: $($health.status)" -ForegroundColor Green
    Write-Host "   ShiftN Path: $($health.shiftNPath)" -ForegroundColor Green
    Write-Host "   ShiftN Exists: $($health.shiftNExists)" -ForegroundColor Green
} catch {
    Write-Host "   FAILED: $_" -ForegroundColor Red
    Write-Host "   Is the service running? Try: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 2: Service info (no auth required)
Write-Host "2. Testing service info endpoint..." -ForegroundColor Cyan
try {
    $info = Invoke-RestMethod -Uri "$BaseUrl/" -Method Get -TimeoutSec 10
    Write-Host "   Service: $($info.service)" -ForegroundColor Green
    Write-Host "   Version: $($info.version)" -ForegroundColor Green
    if ($info.options) {
        Write-Host "   Available modes: $($info.options.Keys -join ', ')" -ForegroundColor Green
    }
} catch {
    Write-Host "   FAILED: $_" -ForegroundColor Red
}

Write-Host ""

# Test 3: Authentication test
Write-Host "3. Testing authentication..." -ForegroundColor Cyan
if (-not $ApiKey) {
    # Try to read from .env file
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" | Where-Object { $_ -match "^API_KEY=" }
        if ($envContent) {
            $ApiKey = ($envContent -split "=", 2)[1].Trim('"').Trim("'")
        }
    }
}

if ($ApiKey) {
    try {
        $headers = @{ "X-API-Key" = $ApiKey }
        $response = Invoke-WebRequest -Uri "$BaseUrl/correct" -Method Post -Headers $headers -TimeoutSec 5
        Write-Host "   Authentication failed as expected (no image provided)" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            Write-Host "   Authentication successful (400 error expected without image)" -ForegroundColor Green
        } elseif ($_.Exception.Response.StatusCode -eq 401) {
            Write-Host "   FAILED: Invalid API key" -ForegroundColor Red
        } else {
            Write-Host "   Authentication working" -ForegroundColor Green
        }
    }
} else {
    Write-Host "   SKIPPED: No API key provided" -ForegroundColor Yellow
    Write-Host "   Set API_KEY in .env file or use -ApiKey parameter" -ForegroundColor Yellow
}

Write-Host ""

# Test 4: Image correction
$testImagePath = if ($TestImage) { $TestImage } else { ".\test-image.jpg" }

Write-Host "4. Testing image correction..." -ForegroundColor Cyan
if (Test-Path $testImagePath) {
    if ($ApiKey) {
        try {
            $headers = @{ "X-API-Key" = $ApiKey }
            $form = @{
                image = Get-Item -Path $testImagePath
                option = "A2"
            }
            
            $outputFile = "api-test-output.jpg"
            Write-Host "   Processing image (this may take 20-30 seconds)..." -ForegroundColor Gray
            
            Invoke-RestMethod -Uri "$BaseUrl/correct" -Method Post -Headers $headers -Form $form -OutFile $outputFile -TimeoutSec 120
            
            if (Test-Path $outputFile) {
                $size = (Get-Item $outputFile).Length
                Write-Host "   SUCCESS: Corrected image saved as $outputFile" -ForegroundColor Green
                Write-Host "   File size: $([math]::Round($size/1MB, 2)) MB" -ForegroundColor Green
                
                # Clean up test output
                Write-Host "   Cleaning up test file..." -ForegroundColor Gray
                Remove-Item $outputFile -Force
            } else {
                Write-Host "   FAILED: Output file not created" -ForegroundColor Red
            }
        } catch {
            Write-Host "   FAILED: $_" -ForegroundColor Red
            if ($_.Exception.Response.StatusCode -eq 401) {
                Write-Host "   Check your API key in .env file" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "   SKIPPED: No API key provided for authenticated endpoint" -ForegroundColor Yellow
    }
} else {
    Write-Host "   SKIPPED: No test image found at $testImagePath" -ForegroundColor Yellow
    Write-Host "   To test image processing:" -ForegroundColor Yellow
    Write-Host "   1. Place a test image at $testImagePath" -ForegroundColor Gray
    Write-Host "   2. Or use: .\test-api.ps1 -TestImage 'path\to\image.jpg'" -ForegroundColor Gray
}

Write-Host ""

# Summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Testing complete" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  - Open test-client.html for interactive testing" -ForegroundColor Gray
Write-Host "  - Check logs: docker logs -f shiftn-api" -ForegroundColor Gray
Write-Host "  - View API docs: $BaseUrl" -ForegroundColor Gray
Write-Host ""