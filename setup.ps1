# Setup script to copy ShiftN files to the project

$source = "C:\Program Files (x86)\ShiftN"
$destination = ".\shiftn-app"

Write-Host "Copying ShiftN files from $source to $destination..." -ForegroundColor Green

# Create destination directory if it doesn't exist
if (-not (Test-Path $destination)) {
    New-Item -Path $destination -ItemType Directory | Out-Null
}

# Copy all files
try {
    Copy-Item "$source\*" -Destination $destination -Recurse -Force
    Write-Host "Successfully copied ShiftN files!" -ForegroundColor Green
    
    # List copied files
    Write-Host "`nCopied files:" -ForegroundColor Cyan
    Get-ChildItem $destination | Select-Object Name, Length | Format-Table -AutoSize
    
    Write-Host "`nReady to build Docker image!" -ForegroundColor Green
    Write-Host "Run: docker-compose build" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error copying files: $_" -ForegroundColor Red
    exit 1
}
