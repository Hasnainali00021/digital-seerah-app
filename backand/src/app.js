import express from 'express';
import cors from 'cors';
import routes from './routes/index.js';

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Routes
app.use('/', routes);

// 404 Handler (MUST be LAST)
app.use((req, res) => {
    res.status(404).json({
        error: 'Endpoint not found',
        requested: req.method + ' ' + req.path,
        availableEndpoints: {
            root: 'GET /',
            health: 'GET /health',
            chat: 'POST /api/chat/query'
        }
    });
});

export default app;
