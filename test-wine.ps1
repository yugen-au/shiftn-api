# ShiftN Wine Version - Quick Test Script
# This script helps you test if Wine version works

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   ShiftN Wine Version - Test Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "1. Checking Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "   Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "   Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check if in Linux mode
Write-Host ""
Write-Host "2. Checking Docker mode..." -ForegroundColor Yellow
$dockerInfo = docker info 2>&1 | Select-String "OSType"
if ($dockerInfo -match "linux") {
    Write-Host "   Docker is in Linux mode (correct for Wine)" -ForegroundColor Green
}
else {
    Write-Host "   Docker is in Windows mode. Please switch to Linux containers." -ForegroundColor Red
    Write-Host "   Right-click Docker icon Switch to Linux containers...'" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "3. Building Docker image (this may take 5-10 minutes)..." -ForegroundColor Yellow
docker-compose build
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Build failed. Check errors above." -ForegroundColor Red
    exit 1
}

# Check if sample image exists
$sampleImage = ".\shiftn-app\sample.jpg"
if (-not (Test-Path $sampleImage)) {
    Write-Host "   Sample image not found at $sampleImage" -ForegroundColor Red
    exit 1
}

try {
    $form = @{
        image = Get-Item -Path $sampleImage
        option = "A2"
    }
    
    $outputFile = "wine-test-output.bmp"
    Write-Host "   Processing sample image..." -ForegroundColor Gray
    
    Invoke-RestMethod -Uri http://localhost:3000/correct -Method Post -Form $form -OutFile $outputFile -ErrorAction Stop
    
    if (Test-Path $outputFile) {
        $fileSize = (Get-Item $outputFile).Length
        Write-Host "   Image processed successfully!" -ForegroundColor Green
        Write-Host "   Output: $outputFile ($([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Gray
    }
    else {
        Write-Host "   Output file not created" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "   Processing failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checking logs..." -ForegroundColor Yellow
    docker logs shiftn-api-wine --tail 50
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   ALL TESTS PASSED!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wine version works! You can now:" -ForegroundColor Green
Write-Host "  Deploy to Railway/Render/Fly.io" -ForegroundColor White
Write-Host "  Save $50-100/month on hosting" -ForegroundColor White
Write-Host "  Open test-client.html to test manually" -ForegroundColor White
Write-Host ""
Write-Host "Compare quality:" -ForegroundColor Yellow
Write-Host "  1. Process same image with native Windows version" -ForegroundColor Gray
Write-Host "  2. Compare wine-test-output.bmp with Windows output" -ForegroundColor Gray
Write-Host "  3. If quality matches, you're good to deploy!" -ForegroundColor Gray
Write-Host ""
Write-Host "View logs: docker logs -f shiftn-api-wine" -ForegroundColor Gray
Write-Host "Stop service: docker-compose down" -ForegroundColor Gray
Write-Host ""
