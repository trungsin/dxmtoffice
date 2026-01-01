const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const app = express();
const port = process.env.AI_PORT || 3000;

app.use(express.json());

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

// Middleware for logging (Dev Mode)
app.use((req, res, next) => {
    if (process.env.DEV_MODE === 'true' && process.env.AI_LOG_ENABLED === 'true') {
        console.log(`[GEMINI AI DEV LOG] ${req.method} ${req.url}`);
        console.log('Payload:', JSON.stringify(req.body).substring(0, 100) + '...');
    }
    next();
});

// AI Assistant Endpoints
app.post('/api/ai/writing/suggest', async (req, res) => {
    try {
        const { prompt } = req.body;
        const result = await model.generateContent(`Suggest and refine the following content: ${prompt}`);
        const response = await result.response;
        res.json({ content: response.text() });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/ai/report/generate', async (req, res) => {
    try {
        const { context } = req.body;
        const result = await model.generateContent(`Generate a professional report based on this context: ${context}`);
        const response = await result.response;
        res.json({ report: response.text() });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health / Status / Version
app.get('/health', (req, res) => res.json({ status: 'OK', message: 'Gemini AI Gateway is healthy.' }));
app.get('/status', (req, res) => res.json({
    status: 'ACTIVE',
    provider: 'google-gemini',
    dev_mode: process.env.DEV_MODE === 'true'
}));
app.get('/version', (req, res) => res.json({ version: '2.0.0-gemini' }));

app.listen(port, () => {
    console.log(`Gemini AI service listening at http://localhost:${port}`);
});
