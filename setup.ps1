# Setup script to copy ShiftN files to the project

$source = "C:\Program Files (x86)\ShiftN"
$destination = ".\shiftn-app"

Write-Host "Copying ShiftN files from $source to $destination..." -ForegroundColor Green

# Create destination directory if it doesn't exist
if (-not (Test-Path $destination)) {
    New-Item -Path $destination -ItemType Directory | Out-Null
}

# Define required files
$requiredFiles = @(
    "ShiftN.exe",
    "ShiftN.ini", 
    "mfc120.dll",
    "mfcm120.dll",
    "msvcp120.dll",
    "msvcr120.dll",
    "shiftn_english.dll",
    "COPYING.LESSER.txt",
    "COPYING.txt",
    "license.txt"
)

# Copy only required files
try {
    $copiedFiles = @()
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        $sourcePath = Join-Path $source $file
        if (Test-Path $sourcePath) {
            Copy-Item $sourcePath -Destination $destination -Force
            $copiedFiles += $file
        } else {
            $missingFiles += $file
        }
    }
    
    Write-Host "Successfully copied required ShiftN files" -ForegroundColor Green
    
    # Show copied files
    Write-Host "`nCopied files:" -ForegroundColor Cyan
    Get-ChildItem $destination | Where-Object { $_.Name -in $requiredFiles } | Select-Object Name, Length | Format-Table -AutoSize
    
    # Warn about missing files
    if ($missingFiles.Count -gt 0) {
        Write-Host "Warning: Some files were not found in source:" -ForegroundColor Yellow
        $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    # Verify essential files
    $essentialFiles = @("ShiftN.exe", "ShiftN.ini")
    $missingEssential = $essentialFiles | Where-Object { -not (Test-Path (Join-Path $destination $_)) }
    
    if ($missingEssential.Count -gt 0) {
        Write-Host "`nERROR: Essential files missing" -ForegroundColor Red
        $missingEssential | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    
    Write-Host "`nReady to build Docker image" -ForegroundColor Green
    Write-Host "Run: .\install.ps1" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error copying files: $_" -ForegroundColor Red
    exit 1
}