import { generateWithFallback } from '../config/gemini.js';

export const generateQuizService = async (content, title) => {
    try {
        // Determine number of questions based on content length
        // Rough estimate: 500 characters ~ 100 words.
        // Short: < 1000 characters -> 3 questions
        // Long: >= 1000 characters -> 10 questions
        const questionCount = content.length > 1000 ? 10 : 3;

        console.log(`🧠 Generating ${questionCount} quiz questions for: ${title}`);

        const prompt = `
        You are an expert Islamic scholar and educator creating a quiz based on the following Seerah event.
        
        Event Title: ${title}
        Event Content: ${content}

        Task: Generate ${questionCount} multiple-choice questions (MCQs) in Urdu language to test the user's understanding of this specific event.

        Requirements:
        1. Language: Urdu (adhere to respectful Islamic terminology).
        2. Format: specific JSON structure.
        3. Options: 4 options per question.
        4. Difficulty: Mixed (Easy to Medium).
        
        Output JSON Format ONLY (No markdown formatting, just raw JSON):
        [
            {
                "question": "سوال یہاں لکھیں؟",
                "options": ["جواب 1", "جواب 2", "جواب 3", "جواب 4"],
                "correct_answer": "جواب 1" // Must match one of the options exactly
            }
        ]
        `;

        const result = await generateWithFallback(prompt);
        let text = result.response.text();

        // Clean up markdown if present
        text = text.replace(/```json/g, '').replace(/```/g, '').trim();

        const quizData = JSON.parse(text);
        return quizData;

    } catch (error) {
        console.error("Gemini Quiz Generation Error:", error);
        throw new Error("Failed to generate quiz.");
    }
};
