import { generateWithFallback } from '../config/gemini.js';

/**
 * Transcribe audio using Gemini's multimodal capabilities.
 * Uses the same fallback model chain as the chatbot for reliability.
 */
export const transcribeAudio = async (base64Audio, mimeType, language) => {
    console.log(`🎤 Transcribing audio (${mimeType}, lang: ${language}, size: ${base64Audio.length} chars)...`);

    const langInstruction = language === 'ur'
        ? 'The audio is in Urdu (اردو). Transcribe it in Urdu script.'
        : 'The audio is in English. Transcribe it in English.';

    const prompt = [
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
    ];

    const result = await generateWithFallback(prompt);
    const transcription = result.response.text().trim();
    console.log(`✅ Transcription: "${transcription}"`);
    return transcription;
};
