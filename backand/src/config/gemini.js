import { GoogleGenerativeAI } from '@google/generative-ai';
import { config } from './env.js';

if (!config.gemini.apiKey) {
    console.error('Error: GEMINI_API_KEY missing in .env');
}

export const genAI = new GoogleGenerativeAI(config.gemini.apiKey);

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const getRetryDelayMs = (error) => {
    const retryInfo = error?.errorDetails?.find(
        (detail) => detail?.['@type']?.includes('RetryInfo')
    );
    const retryDelay = retryInfo?.retryDelay;
    if (retryDelay) {
        const match = retryDelay.match(/(\d+(?:\.\d+)?)s/i);
        if (match) {
            return Math.ceil(Number(match[1]) * 1000);
        }
    }

    const msg = error?.message || '';
    const match = msg.match(/retry\s+in\s+(\d+(?:\.\d+)?)s/i);
    if (match) {
        return Math.ceil(Number(match[1]) * 1000);
    }

    return 0;
};

let cachedModelList = null;

const loadAvailableModels = async () => {
    if (cachedModelList) {
        return cachedModelList;
    }

    try {
        const list = await genAI.listModels();
        const available = new Set(
            (list?.models || []).map((m) => (m?.name || '').replace('models/', ''))
        );

        cachedModelList = config.gemini.models.filter((name) => available.has(name));

        if (cachedModelList.length === 0) {
            cachedModelList = [...config.gemini.models];
        }
    } catch (error) {
        console.log(`⚠️ Model list unavailable (${error.message?.substring(0, 80)}). Using config list.`);
        cachedModelList = [...config.gemini.models];
    }

    return cachedModelList;
};

// Embedding model (unchanged)
export const embeddingModel = genAI.getGenerativeModel({ model: config.gemini.embeddingModel });

/**
 * Try to generate content using the fallback model chain.
 * If a model returns 429 (rate limited), the next model in the list is tried.
 * This ensures the chatbot stays available even when one model's quota is exhausted.
 */
export const generateWithFallback = async (prompt) => {
    const models = await loadAvailableModels();
    let lastError = null;
    const maxRetries = 2;

    for (const modelName of models) {
        for (let attempt = 0; attempt <= maxRetries; attempt += 1) {
            try {
                console.log(`   ⚡ Trying model: ${modelName}`);
                const m = genAI.getGenerativeModel({ model: modelName });
                const result = await m.generateContent(prompt);
                console.log(`   ✅ Success with: ${modelName}`);
                return result;
            } catch (error) {
                lastError = error;
                const isRateLimit = error.message?.includes('429') || error.message?.includes('quota');
                if (isRateLimit) {
                    const retryDelayMs = getRetryDelayMs(error) || (1000 * (attempt + 1));
                    if (attempt < maxRetries) {
                        console.log(`   ⚠️ ${modelName} rate-limited. Retrying in ${retryDelayMs}ms...`);
                        await sleep(retryDelayMs);
                        continue;
                    }

                    console.log(`   ⚠️ ${modelName} rate-limited, trying next model...`);
                    break;
                }

                // For non-rate-limit errors (e.g., 404), try next model
                console.log(`   ⚠️ ${modelName} failed (${error.message?.substring(0, 80)}), trying next...`);
                break;
            }
        }
    }

    // All models exhausted
    throw lastError;
};
