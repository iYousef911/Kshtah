export default {
    async fetch(request, env, ctx) {
        // 1. CORS Headers (Allow all for demo, restrict in prod)
        const corsHeaders = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        };

        // Handle Preflight Request
        if (request.method === "OPTIONS") {
            return new Response(null, { headers: corsHeaders });
        }

        // Only allow POST
        if (request.method !== "POST") {
            return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
        }

        try {
            const { prompt, temperature } = await request.json();

            // 2. Validate Input
            if (!prompt) {
                return new Response("Missing prompt", { status: 400, headers: corsHeaders });
            }

            // 3. Call OpenAI API
            const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${env.OPENAI_API_KEY}` // Secret from Environment
                },
                body: JSON.stringify({
                    model: "gpt-3.5-turbo",
                    messages: [
                        { role: "system", content: "You are a helpful assistant for a camping app called Kashat." },
                        { role: "user", content: prompt }
                    ],
                    max_tokens: 60,
                    temperature: 0.7
                })
            });

            // 4. Handle OpenAI Response
            if (!openAIResponse.ok) {
                const errorText = await openAIResponse.text();
                return new Response(`OpenAI Error: ${errorText}`, { status: 502, headers: corsHeaders });
            }

            const data = await openAIResponse.json();
            const content = data.choices[0].message.content;

            // 5. Return Result
            return new Response(JSON.stringify({ content }), {
                headers: { "Content-Type": "application/json", ...corsHeaders }
            });

        } catch (error) {
            return new Response(`Worker Error: ${error.message}`, { status: 500, headers: corsHeaders });
        }
    },
};
