# ShiftN API Installation Script
# This script builds and starts the ShiftN API

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   ShiftN API - Installation" -ForegroundColor Cyan
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
    Write-Host "   Docker is in Linux mode" -ForegroundColor Green
}
else {
    Write-Host "   Docker is in Windows mode. Please switch to Linux containers." -ForegroundColor Red
    Write-Host "   Right-click Docker icon -> 'Switch to Linux containers...'" -ForegroundColor Yellow
    exit 1
}

# Check if ShiftN files exist
Write-Host ""
Write-Host "3. Checking ShiftN files..." -ForegroundColor Yellow
$shiftnExe = ".\shiftn-app\ShiftN.exe"
if (Test-Path $shiftnExe) {
    Write-Host "   ShiftN files found" -ForegroundColor Green
}
else {
    Write-Host "   ShiftN files not found in shiftn-app directory" -ForegroundColor Red
    Write-Host "   Run setup.ps1 first to copy ShiftN files" -ForegroundColor Yellow
    exit 1
}

# Check environment file
Write-Host ""
Write-Host "4. Checking environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "   Environment file exists" -ForegroundColor Green
}
else {
    Write-Host "   No .env file found. Copying from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "   Please edit .env file to set your API_KEY" -ForegroundColor Yellow
}

# Check if container is already running and handle it
Write-Host ""
Write-Host "5. Checking for existing containers..." -ForegroundColor Yellow
$runningContainers = docker-compose ps -q 2>$null
if ($runningContainers) {
    Write-Host "   Existing containers found. Stopping them first..." -ForegroundColor Yellow
    docker-compose down
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Warning: Failed to stop some containers" -ForegroundColor Yellow
    } else {
        Write-Host "   Containers stopped successfully" -ForegroundColor Green
    }
}
else {
    Write-Host "   No existing containers running" -ForegroundColor Green
}

# Build Docker image
Write-Host ""
Write-Host "6. Building Docker image (this may take a while)..." -ForegroundColor Yellow
docker-compose build
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Build failed. Check errors above." -ForegroundColor Red
    exit 1
}
Write-Host "   Docker image built successfully" -ForegroundColor Green

# Start the service
Write-Host ""
Write-Host "7. Starting the service..." -ForegroundColor Yellow
docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Failed to start service" -ForegroundColor Red
    exit 1
}

Write-Host "   Waiting for service to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Basic health check
Write-Host ""
Write-Host "8. Verifying service is running..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri http://localhost:3000/health -ErrorAction Stop
    Write-Host "   Service is responding: $($health.status)" -ForegroundColor Green
}
catch {
    Write-Host "   Service not responding yet. Check logs if needed:" -ForegroundColor Yellow
    Write-Host "   docker logs shiftn-api" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service is running at: http://localhost:3000" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test API endpoints: .\test-api.ps1" -ForegroundColor White
Write-Host "  2. Try the web interface: test-client.html" -ForegroundColor White
Write-Host "  3. Check service info: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  View logs: docker logs -f shiftn-api" -ForegroundColor Gray
Write-Host "  Stop service: docker-compose down" -ForegroundColor Gray
Write-Host "  Restart: docker-compose restart" -ForegroundColor Gray
Write-Host ""