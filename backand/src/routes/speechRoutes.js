import express from 'express';
import { transcribeAudio } from '../services/speechService.js';

const router = express.Router();

/**
 * POST /api/speech/transcribe
 * Body: { audio: "base64string", mimeType: "audio/aac", language: "en" | "ur" }
 * Returns: { text: "transcribed text" }
 */
router.post('/transcribe', async (req, res) => {
    try {
        const { audio, mimeType, language } = req.body;

        if (!audio) {
            return res.status(400).json({ error: 'Missing audio data' });
        }

        console.log(`📥 Received audio: ${audio.length} chars base64, mimeType: ${mimeType}, lang: ${language}`);

        const text = await transcribeAudio(
            audio,
            mimeType || 'audio/aac',
            language || 'en'
        );

        res.json({ text });
    } catch (error) {
        console.error('❌ Speech transcription error:', error);
        console.error('❌ Full stack:', error.stack);
        res.status(500).json({
            error: 'Transcription failed',
            message: error.message,
            details: error.toString()
        });
    }
});

export default router;
