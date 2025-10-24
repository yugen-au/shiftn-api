# Use Node.js LTS on Debian (better Wine support than Alpine)
FROM node:18-bookworm

# Install Wine and dependencies for running Windows applications
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
        wine \
        wine32 \
        wine64 \
        xvfb \
        imagemagick \
        cabextract \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Wine environment variables
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win32
ENV DISPLAY=:99

# Create app directory
WORKDIR /app

# Copy ShiftN application files
COPY shiftn-app /app/shiftn

# Copy API files
COPY api/package*.json /app/api/
WORKDIR /app/api
RUN npm install --production

COPY api/server.js /app/api/

# Create temp directories
RUN mkdir -p /app/api/temp/uploads /app/api/temp/outputs

# Initialize Wine (creates Windows environment)
# Run in background X server for Wine GUI operations
RUN Xvfb :99 -screen 0 1024x768x16 &
RUN wine wineboot --init && sleep 5

# Set environment for ShiftN
ENV SHIFTN_PATH=/app/shiftn
ENV PORT=3000
ENV NODE_ENV=production

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start X server and Node.js API
CMD rm -f /tmp/.X*-lock /tmp/.X11-unix/X* && \
    Xvfb :99 -screen 0 1024x768x16 & \
    sleep 2 && \
    node server.js
