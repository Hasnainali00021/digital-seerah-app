import express from 'express';
import chatRoutes from './chatRoutes.js';
import healthRoutes from './healthRoutes.js';
import quizRoutes from './quizRoutes.js';
import speechRoutes from './speechRoutes.js';

const router = express.Router();

router.use('/health', healthRoutes);
router.use('/api/chat', chatRoutes);
router.use('/api/quiz', quizRoutes);
router.use('/api/speech', speechRoutes);

// Root endpoint
router.get('/', (req, res) => {
    res.json({
        message: 'Seerah Chatbot API',
        version: '1.0.0',
        status: 'running',
        endpoints: {
            health: 'GET /health',
            chat: 'POST /api/chat/query'
        }
    });
});

export default router;
