const express = require('express');
const multer = require('multer');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs').promises;
const fsSync = require('fs');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;
const SHIFTN_PATH = process.env.SHIFTN_PATH || 'C:\\app\\shiftn';
const SHIFTN_EXE = path.join(SHIFTN_PATH, 'ShiftN.exe');

// Create temp directories if they don't exist
const UPLOAD_DIR = path.join(__dirname, 'temp', 'uploads');
const OUTPUT_DIR = path.join(__dirname, 'temp', 'outputs');

async function ensureDirectories() {
    await fs.mkdir(UPLOAD_DIR, { recursive: true });
    await fs.mkdir(OUTPUT_DIR, { recursive: true });
}

ensureDirectories();

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: UPLOAD_DIR,
    filename: (req, file, cb) => {
        const uniqueName = `${uuidv4()}${path.extname(file.originalname)}`;
        cb(null, uniqueName);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|bmp|tiff|tif/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        
        if (extname && mimetype) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed (JPEG, PNG, BMP, TIFF)'));
        }
    }
});

// Middleware
app.use(express.json());

// Process image with ShiftN
async function processImage(inputPath, outputPath, option = 'A2') {
    return new Promise((resolve, reject) => {
        const outputDir = path.dirname(outputPath);
        const outputFilename = path.basename(outputPath);
        
        const process = spawn(SHIFTN_EXE, [inputPath, outputFilename, option], {
            cwd: outputDir,
            shell: true
        });
        
        let stderr = '';
        
        process.stderr.on('data', (data) => {
            stderr += data.toString();
        });
        
        process.on('close', (code) => {
            if (code === 0) {
                // ShiftN creates .bmp files, check if output exists
                const bmpOutput = outputPath.replace(path.extname(outputPath), '.bmp');
                if (fsSync.existsSync(bmpOutput)) {
                    resolve(bmpOutput);
                } else if (fsSync.existsSync(outputPath)) {
                    resolve(outputPath);
                } else {
                    reject(new Error('ShiftN did not create output file'));
                }
            } else {
                reject(new Error(`ShiftN process failed with code ${code}: ${stderr}`));
            }
        });
        
        process.on('error', (error) => {
            reject(new Error(`Failed to start ShiftN: ${error.message}`));
        });
    });
}

// Cleanup old files
async function cleanupOldFiles(directory, maxAgeMs = 3600000) {
    try {
        const files = await fs.readdir(directory);
        const now = Date.now();
        
        for (const file of files) {
            const filePath = path.join(directory, file);
            const stats = await fs.stat(filePath);
            
            if (now - stats.mtimeMs > maxAgeMs) {
                await fs.unlink(filePath);
            }
        }
    } catch (error) {
        console.error('Cleanup error:', error);
    }
}

// Run cleanup every hour
setInterval(() => {
    cleanupOldFiles(UPLOAD_DIR);
    cleanupOldFiles(OUTPUT_DIR);
}, 3600000);

// Routes
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        shiftNPath: SHIFTN_PATH,
        shiftNExists: fsSync.existsSync(SHIFTN_EXE)
    });
});

app.post('/correct', upload.single('image'), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No image file provided' });
    }
    
    const inputPath = req.file.path;
    const option = req.body.option || 'A2';
    const outputFilename = `${uuidv4()}.jpg`;
    const outputPath = path.join(OUTPUT_DIR, outputFilename);
    
    try {
        const resultPath = await processImage(inputPath, outputPath, option);
        
        // Send the corrected image
        res.sendFile(resultPath, async (err) => {
            if (err) {
                console.error('Error sending file:', err);
            }
            
            // Clean up files after sending
            try {
                await fs.unlink(inputPath);
                await fs.unlink(resultPath);
            } catch (cleanupErr) {
                console.error('Cleanup error:', cleanupErr);
            }
        });
        
    } catch (error) {
        console.error('Processing error:', error);
        
        // Clean up input file on error
        try {
            await fs.unlink(inputPath);
        } catch (cleanupErr) {
            console.error('Cleanup error:', cleanupErr);
        }
        
        res.status(500).json({ 
            error: 'Failed to process image', 
            details: error.message 
        });
    }
});

app.get('/', (req, res) => {
    res.json({
        service: 'ShiftN Perspective Correction Microservice',
        version: '1.0.0',
        endpoints: {
            health: 'GET /health - Check service health',
            correct: 'POST /correct - Correct perspective in image (multipart/form-data with "image" field)'
        },
        options: {
            A1: 'Automatic correction mode 1',
            A2: 'Automatic correction mode 2 (default)',
            A3: 'Automatic correction mode 3'
        }
    });
});

app.listen(PORT, () => {
    console.log(`ShiftN Microservice listening on port ${PORT}`);
    console.log(`ShiftN executable: ${SHIFTN_EXE}`);
    console.log(`Exists: ${fsSync.existsSync(SHIFTN_EXE)}`);
});
