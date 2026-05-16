import dotenv from 'dotenv';
dotenv.config();

export const config = {
    port: process.env.PORT || 3000,
    gemini: {
        apiKey: process.env.GEMINI_API_KEY,
        // Priority list of models with fallback
        models: [
            'gemini-flash-latest', 
            'gemini-3-flash',        
            'gemini-2.0-flash',
            'gemini-2.5-flash',
            'gemini-1.5-flash',
        ],
        embeddingModel: 'gemini-embedding-001',
    },
    supabase: {
        url: process.env.SUPABASE_URL,
        anonKey: process.env.SUPABASE_ANON_KEY,
    }
};
