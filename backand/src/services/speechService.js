import { genAI } from '../config/gemini.js';

/**
 * Transcribe audio using Gemini's multimodal capabilities.
 * Uses gemini-1.5-flash specifically (separate quota from gemini-2.0-flash
 * used by the chatbot, and has generous free-tier audio support).
 */
export const transcribeAudio = async (base64Audio, mimeType, language) => {
    console.log(`🎤 Transcribing audio (${mimeType}, lang: ${language}, size: ${base64Audio.length} chars)...`);

    const langInstruction = language === 'ur'
        ? 'The audio is in Urdu (اردو). Transcribe it in Urdu script.'
        : 'The audio is in English. Transcribe it in English.';

    // Use gemini-1.5-flash for speech — it has separate free-tier quota
    // and excellent audio transcription support
    const speechModel = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-lite' });

    const result = await speechModel.generateContent([
        {
            inlineData: {
                mimeType: mimeType,
                data: base64Audio,
            },
        },
        {
            text: `You are a speech-to-text transcriber. ${langInstruction}

Rules:
1. Return ONLY the transcribed text — no explanations, no quotes, no formatting.
2. If you cannot understand the audio, return an empty string.
3. Do not add any extra words or translations.
4. Preserve the original language of the speech.`,
        },
    ]);

    const transcription = result.response.text().trim();
    console.log(`✅ Transcription: "${transcription}"`);
    return transcription;
};
