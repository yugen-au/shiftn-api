# Test script for ShiftN Microservice API

$baseUrl = "http://localhost:3000"

Write-Host "Testing ShiftN Microservice API..." -ForegroundColor Green
Write-Host ""

# Test 1: Health check
Write-Host "1. Testing health endpoint..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "   Status: $($health.status)" -ForegroundColor Green
    Write-Host "   ShiftN Path: $($health.shiftNPath)" -ForegroundColor Green
    Write-Host "   ShiftN Exists: $($health.shiftNExists)" -ForegroundColor Green
} catch {
    Write-Host "   FAILED: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Service info
Write-Host "2. Testing service info endpoint..." -ForegroundColor Cyan
try {
    $info = Invoke-RestMethod -Uri "$baseUrl/" -Method Get
    Write-Host "   Service: $($info.service)" -ForegroundColor Green
    Write-Host "   Version: $($info.version)" -ForegroundColor Green
} catch {
    Write-Host "   FAILED: $_" -ForegroundColor Red
}

Write-Host ""

# Test 3: Image correction (if test image exists)
$testImage = ".\test-image.jpg"
if (Test-Path $testImage) {
    Write-Host "3. Testing image correction..." -ForegroundColor Cyan
    try {
        $form = @{
            image = Get-Item -Path $testImage
            option = "A2"
        }
        
        Invoke-RestMethod -Uri "$baseUrl/correct" -Method Post -Form $form -OutFile "corrected-output.bmp"
        
        if (Test-Path "corrected-output.bmp") {
            $size = (Get-Item "corrected-output.bmp").Length
            Write-Host "   SUCCESS: Corrected image saved (Size: $([math]::Round($size/1MB, 2)) MB)" -ForegroundColor Green
        } else {
            Write-Host "   FAILED: Output file not created" -ForegroundColor Red
        }
    } catch {
        Write-Host "   FAILED: $_" -ForegroundColor Red
    }
} else {
    Write-Host "3. Skipping image correction test (no test-image.jpg found)" -ForegroundColor Yellow
    Write-Host "   To test image correction, place a test-image.jpg in this directory" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Testing complete!" -ForegroundColor Green
