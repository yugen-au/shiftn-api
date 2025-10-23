# ShiftN Perspective Correction Microservice

A REST API microservice that wraps the ShiftN perspective correction tool in a Docker container for easy deployment and integration.

## Overview

ShiftN is a powerful tool for automatic correction of converging lines in architectural photography. This project containerizes ShiftN and exposes it as a simple REST API for use in microservice architectures.

## Features

- Automatic perspective correction for images
- REST API interface
- Docker containerized for easy deployment
- File upload support
- Automatic cleanup of temporary files
- Health check endpoint
- Multiple correction modes

## Prerequisites

- Docker Desktop for Windows (with Windows containers enabled)
- Windows host machine (required for Windows containers)

## Project Structure

```
shiftn-microservice/
├── Dockerfile                 # Windows container definition
├── docker-compose.yml         # Docker Compose configuration
├── .dockerignore             # Files to exclude from Docker build
├── README.md                 # This file
├── api/                      # Node.js API wrapper
│   ├── server.js            # Express server
│   ├── package.json         # Node.js dependencies
│   └── temp/                # Temporary upload/output directory
└── shiftn-app/              # ShiftN application files (to be copied)
    ├── ShiftN.exe
    ├── ShiftN.ini
    ├── *.dll                # Language and runtime DLLs
    └── ...
```

## Setup Instructions

### 1. Copy ShiftN Application Files

Copy all files from your ShiftN installation to the `shiftn-app` directory:


```powershell
Copy-Item "C:\Program Files (x86)\ShiftN\*" -Destination ".\shiftn-app\" -Recurse
```

Required files:
- ShiftN.exe
- ShiftN.ini
- shiftn_english.dll
- shiftn_deutsch.dll
- shiftn_francais.dll
- shiftn_espanol.dll
- mfc120.dll
- mfcm120.dll
- msvcp120.dll
- msvcr120.dll

### 2. Switch Docker to Windows Containers

Right-click Docker Desktop system tray icon and select "Switch to Windows containers..."

### 3. Build the Docker Image

```powershell
docker-compose build
```

Or build manually:

```powershell
docker build -t shiftn-microservice .
```

### 4. Run the Container

Using Docker Compose:

```powershell
docker-compose up -d
```

Or run manually:

```powershell
docker run -d -p 3000:3000 --name shiftn-api shiftn-microservice
```

## API Documentation

### Base URL

```
http://localhost:3000
```

### Endpoints

#### GET /

Get service information and available endpoints.

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

#### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "shiftNPath": "C:\\app\\shiftn",
  "shiftNExists": true
}
```

#### POST /correct

Correct perspective distortion in an image.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body:
  - `image` (file, required): Image file to correct
  - `option` (string, optional): Correction mode (A1, A2, or A3). Default: A2

**Supported Image Formats:**
- JPEG (.jpg, .jpeg)
- PNG (.png)
- BMP (.bmp)
- TIFF (.tif, .tiff)

**Response:**
- Content-Type: `image/bmp`
- Body: Corrected image file (BMP format)

**Example using cURL:**


```bash
curl -X POST http://localhost:3000/correct \
  -F "image=@building.jpg" \
  -F "option=A2" \
  -o corrected.bmp
```

**Example using PowerShell:**

```powershell
$uri = "http://localhost:3000/correct"
$filePath = "C:\path\to\image.jpg"
$form = @{
    image = Get-Item -Path $filePath
    option = "A2"
}
Invoke-RestMethod -Uri $uri -Method Post -Form $form -OutFile "corrected.bmp"
```

**Example using JavaScript (fetch):**

```javascript
const formData = new FormData();
formData.append('image', fileInput.files[0]);
formData.append('option', 'A2');

const response = await fetch('http://localhost:3000/correct', {
    method: 'POST',
    body: formData
});

const blob = await response.blob();
const url = URL.createObjectURL(blob);
```

**Example using Python:**

```python
import requests

url = 'http://localhost:3000/correct'
files = {'image': open('building.jpg', 'rb')}
data = {'option': 'A2'}

response = requests.post(url, files=files, data=data)

with open('corrected.bmp', 'wb') as f:
    f.write(response.content)
```

## Correction Modes

- **A1**: Automatic correction mode 1
- **A2**: Automatic correction mode 2 (default, recommended)
- **A3**: Automatic correction mode 3

The modes correspond to different algorithms in ShiftN. A2 is generally the most reliable.

## Configuration


ShiftN's processing parameters are controlled by the `ShiftN.ini` file. You can customize this file in the `shiftn-app` directory before building the Docker image.

Key parameters in `ShiftN.ini`:
- JPEG quality (default: 100)
- Minimum line length
- Line contrast settings
- Sharpening parameters
- Focal length
- And many more...

## Environment Variables

- `PORT`: API server port (default: 3000)
- `NODE_ENV`: Node environment (default: production)
- `SHIFTN_PATH`: Path to ShiftN executable directory (default: C:\app\shiftn)

## Troubleshooting

### Container fails to start

1. Ensure Docker is in Windows container mode
2. Check Docker logs: `docker logs shiftn-api`
3. Verify ShiftN files were copied correctly to `shiftn-app/`

### Health check fails

1. Check if Node.js installed correctly in container
2. Verify port 3000 is not already in use
3. Check container logs for errors

### Image processing fails

1. Verify input image is a supported format
2. Check ShiftN.ini configuration
3. Ensure image is not corrupted
4. Check container has sufficient memory

### Output is always BMP

This is expected behavior. ShiftN outputs BMP files regardless of the input format. You can convert to other formats after processing if needed.

## Performance Notes

- Processing time: ~0.2-0.5 seconds per image
- File size limit: 50MB
- Temporary files are cleaned up automatically after 1 hour
- Files are deleted immediately after successful processing

## Development

To run the API locally without Docker (Windows only):


1. Install Node.js
2. Navigate to `api` directory
3. Install dependencies:
   ```powershell
   npm install
   ```
4. Set environment variable to point to ShiftN:
   ```powershell
   $env:SHIFTN_PATH = "C:\Program Files (x86)\ShiftN"
   ```
5. Run the server:
   ```powershell
   npm start
   ```

For development with auto-reload:
```powershell
npm run dev
```

## License

ShiftN is licensed under LGPL v3. See the COPYING.LESSER.txt file in the ShiftN application directory.

This API wrapper is provided as-is for integration purposes.

## Credits

- **ShiftN** by Marcus Hebel (http://www.shiftn.de)
- Line detection algorithm based on work by J. Brian Burns, Allen R. Hanson, Edward M. Riseman
- Uses libjpeg, libtiff, and zlib libraries

## Support

For issues with:
- ShiftN functionality: Visit http://www.shiftn.de
- This API wrapper: Open an issue in the project repository
- Docker/deployment: Check Docker documentation

## Changelog

### Version 1.0.0
- Initial release
- Basic REST API with single endpoint
- Docker containerization
- Automatic file cleanup
- Health check endpoint
