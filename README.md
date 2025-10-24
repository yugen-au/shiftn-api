# ShiftN Perspective Correction Microservice (Wine/Linux)

A REST API microservice that wraps the ShiftN perspective correction tool in a Linux Docker container using Wine for cross-platform compatibility.

## Overview

ShiftN is a powerful Windows tool for automatic correction of converging lines in architectural photography. This project runs ShiftN through Wine in a Linux container, enabling deployment on cost-effective Linux hosting platforms while maintaining full compatibility with the original Windows application.

## Features

- Automatic perspective correction for images using ShiftN
- REST API interface with JSON responses
- Linux Docker container with Wine compatibility layer
- API key authentication for secure access
- ImageMagick integration for BMP to JPEG conversion
- Automatic file cleanup and process management
- Health monitoring endpoints
- Multiple correction modes (A1, A2, A3)

## Quick Start

### Prerequisites

- Docker Desktop (Linux container mode)
- ShiftN application files

### 1. Environment Setup

Copy the environment template and configure your API key:

```bash
cp .env.example .env
# Edit .env and set your API_KEY
```

### 2. Build and Run

```bash
docker-compose build
docker-compose up -d
```

### 3. Test the Service

```bash
# Health check
curl http://localhost:3000/health

# Process an image (with API key)
curl -H "X-API-Key: your-api-key" \
     -F "image=@test.jpg" \
     http://localhost:3000/correct \
     -o corrected.jpg
```

## Project Structure

```
shiftn-microservice-wine/
├── Dockerfile                 # Linux container with Wine
├── docker-compose.yml         # Service configuration
├── .env.example              # Environment template
├── .env                      # Environment variables (gitignored)
├── api/                      # Node.js API server
│   ├── server.js            # Express server with Wine integration
│   ├── package.json         # Dependencies
│   └── temp/                # Temporary upload/output directory
└── shiftn-app/              # ShiftN Windows application files
    ├── ShiftN.exe
    ├── ShiftN.ini
    └── *.dll                # Runtime dependencies
```

## API Documentation

### Authentication

All endpoints except `/health` and `/` require API key authentication.

**Methods:**
- Header: `X-API-Key: your-secret-key`
- Query parameter: `?api_key=your-secret-key`

### Endpoints

#### GET /health

Health check endpoint (no authentication required).

**Response:**
```json
{
  "status": "healthy",
  "shiftNPath": "/app/shiftn",
  "shiftNExists": true
}
```

#### GET /

Service information (no authentication required).

**Response:**
```json
{
  "service": "ShiftN Perspective Correction Microservice",
  "version": "1.0.0",
  "endpoints": {
    "health": "GET /health - Check service health",
    "correct": "POST /correct - Correct perspective in image"
  },
  "options": {
    "A1": "Automatic correction mode 1",
    "A2": "Automatic correction mode 2 (default)",
    "A3": "Automatic correction mode 3"
  }
}
```

#### POST /correct

Correct perspective distortion in an image (requires authentication).

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Headers: `X-API-Key: your-secret-key` (or use query parameter)
- Body:
  - `image` (file, required): Image file to correct
  - `option` (string, optional): Correction mode (A1, A2, A3). Default: A2

**Supported Formats:**
- Input: JPEG, PNG, BMP, TIFF
- Output: JPEG (converted from ShiftN's BMP output using ImageMagick)

**Response:**
- Content-Type: `image/jpeg`
- Body: Corrected image file

## Usage Examples

### cURL
```bash
curl -H "X-API-Key: your-secret-key" \
     -F "image=@building.jpg" \
     -F "option=A2" \
     http://localhost:3000/correct \
     -o corrected.jpg
```

### PowerShell
```powershell
$headers = @{ "X-API-Key" = "your-secret-key" }
$form = @{
    image = Get-Item -Path "building.jpg"
    option = "A2"
}
Invoke-RestMethod -Uri http://localhost:3000/correct -Method Post -Headers $headers -Form $form -OutFile "corrected.jpg"
```

### JavaScript (fetch)
```javascript
const formData = new FormData();
formData.append('image', fileInput.files[0]);
formData.append('option', 'A2');

const response = await fetch('http://localhost:3000/correct', {
    method: 'POST',
    headers: {
        'X-API-Key': 'your-secret-key'
    },
    body: formData
});

const blob = await response.blob();
```

### Python
```python
import requests

headers = {'X-API-Key': 'your-secret-key'}
files = {'image': open('building.jpg', 'rb')}
data = {'option': 'A2'}

response = requests.post('http://localhost:3000/correct', 
                        headers=headers, files=files, data=data)

with open('corrected.jpg', 'wb') as f:
    f.write(response.content)
```

## Configuration

### Environment Variables

Configure in `.env` file:

```bash
# API Configuration
API_KEY=your-secret-api-key-here

# Server Configuration
PORT=3000
NODE_ENV=production

# ShiftN Configuration
SHIFTN_PATH=/app/shiftn
```

### ShiftN Parameters

Customize `shiftn-app/ShiftN.ini` before building:

- JPEG quality settings
- Line detection parameters
- Correction algorithms
- Processing timeouts

## Deployment

### Cost-Effective Linux Hosting

This Wine-based version enables deployment on affordable Linux platforms:

- **Railway**: $0-10/month
- **Render**: $0-7/month  
- **Fly.io**: $0-5/month
- **DigitalOcean**: $5-10/month

**Savings**: $50-100/month compared to Windows hosting

### Railway Deployment

```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway up
```

### Render Deployment

1. Push repository to GitHub
2. Connect to Render
3. Deploy as Docker service
4. Set environment variables in dashboard

## Performance

- **Processing time**: 20-30 seconds per image
- **File size limit**: 50MB
- **Concurrent requests**: Supported with automatic process management
- **Memory usage**: ~200MB base + ~100MB per active job
- **Cleanup**: Automatic removal of temporary files after processing

## Technical Details

### Wine Compatibility

- Runs ShiftN.exe through Wine compatibility layer
- Virtual X server (Xvfb) for GUI-less operation
- Automatic process cleanup prevents hanging Wine processes
- Tested with ShiftN's MFC framework dependencies

### Process Management

- 5-minute timeout for image processing
- Polling every 3 seconds for completion
- Immediate process termination after output detection
- X server lock file cleanup on container restart

### File Conversion

- ShiftN outputs BMP format
- ImageMagick converts BMP to JPEG (90% quality)
- Automatic cleanup of intermediate files
- Error handling for conversion failures

## Troubleshooting

### Container Issues

**Container won't start:**
- Check Docker is in Linux mode
- Verify ShiftN files in `shiftn-app/`
- Check logs: `docker logs container-name`

**X server errors:**
- Container automatically cleans lock files
- Restart container if Xvfb issues persist

### API Issues

**Authentication errors:**
- Verify API key in `.env` file
- Check API key in request headers/query

**Processing failures:**
- Ensure image format is supported
- Check file size under 50MB limit
- Verify ShiftN.ini configuration

### Wine Issues

**ShiftN won't run:**
- Check Wine initialization in logs
- Verify all DLL dependencies present
- Test manually: `docker exec -it container wine /app/shiftn/ShiftN.exe`

## Development

### Local Development

```bash
# Install dependencies
cd api && npm install

# Set environment variables
export SHIFTN_PATH="/path/to/shiftn"
export API_KEY="test-key"

# Run server
npm start
```

### Debugging

```bash
# View logs
docker logs -f container-name

# Execute commands in container
docker exec -it container-name bash

# Check processes
docker exec container-name ps aux

# Test Wine
docker exec container-name wine --version
```

## License and Credits

- **ShiftN** by Marcus Hebel (http://www.shiftn.de) - LGPL v3
- **Wine** compatibility layer - LGPL
- **ImageMagick** image processing - Apache License
- API wrapper - MIT License

## Support

- **ShiftN functionality**: http://www.shiftn.de
- **Wine compatibility**: https://www.winehq.org
- **Docker issues**: Check Docker documentation
- **API wrapper**: Open GitHub issue

## Changelog

### Version 2.0.0
- Linux/Wine compatibility
- API key authentication
- ImageMagick BMP to JPEG conversion
- Improved process management
- X server stability fixes
- Cost-effective deployment options