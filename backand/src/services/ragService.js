import { supabase } from '../config/supabase.js';
import { embeddingModel, generateWithFallback } from '../config/gemini.js';

export const processQuery = async (query) => {
    // 1. Generate Embedding
    console.log('🔍 Generating embedding for query...');
    const embeddingResult = await embeddingModel.embedContent({
        content: { parts: [{ text: query }] },
        outputDimensionality: 768
    });
    const queryEmbedding = embeddingResult.embedding.values;

    // 2. Search Supabase
    console.log('🗄️  Searching database...');
    const { data: documents, error: searchError } = await supabase
        .rpc('match_seerah_chunks', {
            query_embedding: queryEmbedding,
            match_threshold: 0.1,
            match_count: 5,
            query_text: query
        });

    if (searchError) {
        console.error('Supabase Search Error:', searchError);
        throw new Error(`Database search failed: ${searchError.message}`);
    }

    console.log(`✅ Found ${documents ? documents.length : 0} relevant documents.`);

    // 3. Construct Context
    let contextText = "";
    if (documents && documents.length > 0) {
        documents.forEach((doc, index) => {
            contextText += `\n--- Document ${index + 1} ---\nHeading: ${doc.metadata?.heading}\nBook: ${doc.metadata?.book}\nPage: ${doc.page_number}\nContent: ${doc.text}\n----------------\n`;
        });
    } else {
        console.log('⚠️ No relevant documents found. Using general knowledge (fallback).');
        contextText = "No specific context available from the database.";
    }

    // 4. Prompt
    const prompt = `
آپ ایک ماہر اسلامی عالم اور سیرت النبی ﷺ کے ماہر ہیں۔
نیچے دیے گئے "حوالہ جات" (Context) کی بنیاد پر صارف کے سوال کا جواب دیں۔

ہدایات:
1. اپنے جواب کو **صرف** فراہم کردہ حوالہ جات تک محدود رکھیں۔
2. اپنی طرف سے معلومات شامل نہ کریں۔
3. حوالہ جات کا ذکر قدرتی انداز میں کریں (مثلاً: "کتاب سیرت مصطفیٰ کے صفحہ 39 پر ذکر ہے کہ...")۔
4. بریکٹ [] کا استعمال کم سے کم کریں۔
5. اردو زبان میں نہایت ادب اور احترام کے ساتھ جواب دیں۔

حوالہ جات (Context):
${contextText}

سوال: ${query}

جواب:
    `.trim();

    // 5. Generate with automatic model fallback
    console.log('🤖 Calling Gemini API...');
    const result = await generateWithFallback(prompt);
    const answer = result.response.text();
    console.log(`✅ Answer generated (${answer.length} chars)`);

    return {
        answer,
        documents: documents || []
    };
};
