const express = require('express');
const app = express();
const port = process.env.AI_PORT || 3000;

app.use(express.json());

// Middleware for logging (Dev Mode)
app.use((req, res, next) => {
    if (process.env.DEV_MODE === 'true') {
        console.log(`[AI DEV LOG] ${req.method} ${req.url}`);
        console.log('Body:', req.body);
    }
    next();
});

// AI Provider selection middleware
const aiProvider = (req, res, next) => {
    req.provider = process.env.AI_PROVIDER || 'openai';
    next();
};

app.post('/v1/chat/completions', aiProvider, async (req, res) => {
    const { provider } = req;
    console.log(`Using AI Provider: ${provider}`);

    // Logic for calling OpenAI or Claude would go here
    res.json({
        choices: [{
            message: {
                content: `Response from ${provider}: Integrated successfully!`
            }
        }]
    });
});

app.listen(port, () => {
    console.log(`AI Service listening at http://localhost:${port}`);
});
