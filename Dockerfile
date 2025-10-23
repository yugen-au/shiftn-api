# Use Windows Server Core as base image
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Set working directory
WORKDIR /app

# Copy ShiftN application files
COPY shiftn-app/ /app/shiftn/

# Copy API wrapper
COPY api/ /app/api/

# Install Node.js for the API wrapper
# Using Chocolatey to install Node.js
RUN powershell -Command \
    Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); \
    choco install -y nodejs-lts

# Set environment variables
ENV SHIFTN_PATH=C:\\app\\shiftn
ENV NODE_ENV=production

# Install Node.js dependencies
WORKDIR /app/api
RUN npm install

# Expose API port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD powershell -Command "try { Invoke-WebRequest -Uri http://localhost:3000/health -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }"

# Start the API server
CMD ["node", "server.js"]
