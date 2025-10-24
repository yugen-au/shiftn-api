# ShiftN Wine Version - Manual Test
# Simplified test that works with Windows PowerShell 5.1

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   ShiftN Wine - Manual Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Starting the container..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start container" -ForegroundColor Red
    exit 1
}

Write-Host "Waiting 60 seconds for Wine to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "Step 2: Checking if service is running..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri http://localhost:3000/health -ErrorAction Stop
    Write-Host "Service Status: $($health.status)" -ForegroundColor Green
    Write-Host "ShiftN Path: $($health.shiftNPath)" -ForegroundColor Gray
    Write-Host "ShiftN Exists: $($health.shiftNExists)" -ForegroundColor Gray
}
catch {
    Write-Host "Service not responding!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Container logs:" -ForegroundColor Yellow
    docker logs shiftn-api-wine
    exit 1
}

Write-Host ""
Write-Host "Step 3: Testing image processing..." -ForegroundColor Yellow
Write-Host "Use cURL or open test-client.html to test image processing" -ForegroundColor Gray
Write-Host ""
Write-Host "Example cURL command:" -ForegroundColor Cyan
Write-Host 'curl -X POST http://localhost:3000/correct -F "image=@shiftn-app/sample.jpg" -F "option=A2" -o wine-output.bmp' -ForegroundColor White
Write-Host ""
Write-Host "Or open: test-client.html in your browser" -ForegroundColor Cyan
Write-Host ""
Write-Host "View logs: docker logs -f shiftn-api-wine" -ForegroundColor Gray
Write-Host "Stop service: docker-compose down" -ForegroundColor Gray
Write-Host ""
