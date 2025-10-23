# Quick Start Guide

Get the ShiftN microservice running in 5 minutes!

## Step 1: Prerequisites Check

- [ ] Docker Desktop installed
- [ ] Docker in Windows container mode
- [ ] ShiftN files copied (already done!)

## Step 2: Build the Docker Image

```powershell
cd D:\Documents\claude-projects\shiftn-microservice
docker-compose build
```

This will take 5-10 minutes on first build (downloads Windows base image and installs Node.js).

## Step 3: Start the Service

```powershell
docker-compose up -d
```

Check if it's running:
```powershell
docker ps
```

## Step 4: Test the API

### Option A: Using the test script

```powershell
.\test-api.ps1
```

### Option B: Using cURL

```bash
# Health check
curl http://localhost:3000/health

# Service info
curl http://localhost:3000/

# Process an image (if you have test.jpg)
curl -X POST http://localhost:3000/correct -F "image=@test.jpg" -o output.bmp
```

### Option C: Using PowerShell


```powershell
# Health check
Invoke-RestMethod -Uri http://localhost:3000/health

# Process an image
$form = @{
    image = Get-Item -Path "C:\path\to\image.jpg"
    option = "A2"
}
Invoke-RestMethod -Uri http://localhost:3000/correct -Method Post -Form $form -OutFile "corrected.bmp"
```

## Step 5: Stop the Service

```powershell
docker-compose down
```

## Troubleshooting

### "Cannot connect to Docker daemon"
- Make sure Docker Desktop is running
- Check system tray for Docker icon

### "image operating system "windows" cannot be used on this platform"
- Right-click Docker Desktop icon → "Switch to Windows containers..."

### "Port 3000 already in use"
- Stop other services using port 3000, or
- Edit docker-compose.yml to use a different port: `"8080:3000"`

### Container starts but health check fails
- Check logs: `docker logs shiftn-api`
- Wait 30-60 seconds for Node.js to install
- Verify with: `docker exec shiftn-api powershell node --version`

## Next Steps

- See `README.md` for full API documentation
- Customize `shiftn-app/ShiftN.ini` for different processing parameters
- Integrate the API into your application
- Deploy to production Windows server

## Production Deployment Tips

1. Use proper secrets management for any API keys
2. Set resource limits in docker-compose.yml
3. Set up monitoring and alerting
4. Configure backup for ShiftN.ini
5. Use a reverse proxy (nginx) for HTTPS
6. Consider rate limiting for public APIs

## Useful Commands

```powershell
# View logs
docker logs -f shiftn-api

# Restart service
docker-compose restart

# Rebuild after changes
docker-compose up -d --build

# Check resource usage
docker stats shiftn-api

# Execute commands in container
docker exec -it shiftn-api powershell

# Remove container and images
docker-compose down --rmi all
```

## Testing with Sample Image

The container includes a sample.jpg file. To test with it:

```powershell
# Copy the sample out of the container
docker cp shiftn-api:C:/app/shiftn/sample.jpg ./test-image.jpg

# Process it
$form = @{ image = Get-Item -Path "test-image.jpg"; option = "A2" }
Invoke-RestMethod -Uri http://localhost:3000/correct -Method Post -Form $form -OutFile "result.bmp"
```

You should now have a perspective-corrected image!
