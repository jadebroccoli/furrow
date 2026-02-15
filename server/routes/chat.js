const { Router } = require('express');
const axios = require('axios');
const { authMiddleware, requirePro } = require('../middleware/auth');
const { perUserRateLimit } = require('../middleware/rateLimit');
const { trackCost } = require('../utils/costTracker');

const router = Router();

const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';

/**
 * POST /api/v1/chat
 *
 * Body: {
 *   message: string,               — User's question
 *   context: {                      — Garden context from the app
 *     zone?: string,                — e.g. "7b"
 *     plants?: [{ name, species, plantedDate, status, daysSincePlanted }],
 *     weather?: { temp, condition, forecast },
 *     season?: string,
 *   },
 *   history?: [{ role, content }],  — Previous messages (last 5)
 * }
 */
router.post(
  '/',
  authMiddleware,
  requirePro,
  perUserRateLimit('chat', parseInt(process.env.RATE_LIMIT_CHAT) || 20),
  async (req, res) => {
    try {
      const { message, context, history } = req.body;

      if (!message || typeof message !== 'string' || message.trim().length === 0) {
        return res.status(400).json({ error: 'Message is required' });
      }

      if (message.length > 2000) {
        return res.status(400).json({ error: 'Message too long (max 2000 characters)' });
      }

      // Build system prompt with garden context
      const systemPrompt = buildSystemPrompt(context);

      // Build conversation contents
      const contents = [];

      // Add conversation history (last 5 turns)
      if (history && Array.isArray(history)) {
        const recentHistory = history.slice(-10); // Last 5 exchanges = 10 messages
        for (const msg of recentHistory) {
          contents.push({
            role: msg.role === 'user' ? 'user' : 'model',
            parts: [{ text: msg.content }],
          });
        }
      }

      // Add current user message
      contents.push({
        role: 'user',
        parts: [{ text: message }],
      });

      const response = await axios.post(
        `${GEMINI_URL}?key=${process.env.GEMINI_API_KEY}`,
        {
          system_instruction: {
            parts: [{ text: systemPrompt }],
          },
          contents,
          generationConfig: {
            maxOutputTokens: 1024,
            temperature: 0.7,
          },
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000,
        }
      );

      const candidate = response.data.candidates?.[0];
      if (!candidate || !candidate.content?.parts?.[0]?.text) {
        return res.status(502).json({ error: 'No response from AI' });
      }

      const aiResponse = candidate.content.parts[0].text;

      // Track estimated cost
      const usage = response.data.usageMetadata;
      if (usage) {
        const inputTokens = usage.promptTokenCount || 0;
        const outputTokens = usage.candidatesTokenCount || 0;
        const cost = (inputTokens * 0.15 + outputTokens * 0.60) / 1_000_000;
        trackCost(cost, 'chat');
      }

      res.json({
        response: aiResponse,
        tokensUsed: usage ? {
          input: usage.promptTokenCount,
          output: usage.candidatesTokenCount,
        } : null,
      });
    } catch (err) {
      console.error('[chat] Error:', err.response?.data || err.message);

      if (err.response?.status === 429) {
        return res.status(429).json({ error: 'AI service rate limited. Try again in a moment.' });
      }

      res.status(500).json({ error: 'AI service unavailable' });
    }
  }
);

function buildSystemPrompt(context) {
  let prompt = `You are Furrow's Garden Advisor, an expert on outdoor vegetable gardening. You provide practical, actionable advice for home gardeners growing food.

Rules:
- Keep responses concise (2-4 paragraphs max)
- Focus on vegetable, herb, and fruit gardening
- Be encouraging but honest about challenges
- When relevant, suggest specific actionable steps
- If you're not sure about something, say so
- Use simple language, avoid jargon unless explaining it`;

  if (context) {
    if (context.zone) {
      prompt += `\n\nThe gardener is in USDA Hardiness Zone ${context.zone}.`;
    }

    if (context.season) {
      prompt += `\nCurrent season: ${context.season}.`;
    }

    if (context.weather) {
      const w = context.weather;
      prompt += `\nCurrent weather: ${w.condition || 'unknown'}, ${w.temp || 'unknown'} temperature.`;
      if (w.forecast) {
        prompt += ` 7-day forecast: ${w.forecast}`;
      }
    }

    if (context.plants && context.plants.length > 0) {
      prompt += '\n\nTheir current garden contains:';
      for (const p of context.plants.slice(0, 20)) { // Cap at 20 plants to limit tokens
        prompt += `\n- ${p.name}`;
        if (p.species) prompt += ` (${p.species})`;
        if (p.plantedDate) prompt += `, planted ${p.plantedDate}`;
        if (p.daysSincePlanted) prompt += ` (${p.daysSincePlanted} days ago)`;
        if (p.status) prompt += `, status: ${p.status}`;
      }
    }
  }

  return prompt;
}

module.exports = router;
