const { Router } = require('express');
const axios = require('axios');
const multer = require('multer');
const { authMiddleware, requirePro } = require('../middleware/auth');
const { perUserRateLimit } = require('../middleware/rateLimit');
const { trackCost } = require('../utils/costTracker');

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
});

const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';

/**
 * POST /api/v1/diagnose
 *
 * Multipart form data:
 *   image: file (JPEG/PNG, max 5MB)
 *   plantName: string (optional) — What the user thinks the plant is
 *   description: string (optional) — User's description of the problem
 *   context: JSON string (optional) — { zone, weather, season }
 */
router.post(
  '/',
  authMiddleware,
  requirePro,
  perUserRateLimit('photo', parseInt(process.env.RATE_LIMIT_PHOTO) || 10),
  upload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'Image file is required' });
      }

      const plantName = req.body.plantName || 'unknown plant';
      const description = req.body.description || '';
      let context = {};
      try {
        if (req.body.context) context = JSON.parse(req.body.context);
      } catch (_) { /* ignore parse errors */ }

      // Build diagnosis prompt
      const systemPrompt = buildDiagnosisPrompt(plantName, description, context);

      // Convert image to base64
      const imageBase64 = req.file.buffer.toString('base64');
      const mimeType = req.file.mimetype || 'image/jpeg';

      const response = await axios.post(
        `${GEMINI_URL}?key=${process.env.GEMINI_API_KEY}`,
        {
          system_instruction: {
            parts: [{ text: systemPrompt }],
          },
          contents: [
            {
              role: 'user',
              parts: [
                {
                  inline_data: {
                    mime_type: mimeType,
                    data: imageBase64,
                  },
                },
                {
                  text: description
                    ? `What's wrong with this ${plantName}? ${description}`
                    : `Analyze this photo of my ${plantName}. Identify any diseases, pests, nutrient deficiencies, or other issues. If the plant looks healthy, say so.`,
                },
              ],
            },
          ],
          generationConfig: {
            maxOutputTokens: 1024,
            temperature: 0.4,
          },
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 45000,
        }
      );

      const candidate = response.data.candidates?.[0];
      if (!candidate || !candidate.content?.parts?.[0]?.text) {
        return res.status(502).json({ error: 'No diagnosis from AI' });
      }

      const diagnosis = candidate.content.parts[0].text;

      // Track cost
      const usage = response.data.usageMetadata;
      if (usage) {
        const inputTokens = usage.promptTokenCount || 0;
        const outputTokens = usage.candidatesTokenCount || 0;
        const cost = (inputTokens * 0.15 + outputTokens * 0.60) / 1_000_000;
        trackCost(cost, 'diagnose');
      }

      res.json({
        diagnosis,
        plantName,
        tokensUsed: usage ? {
          input: usage.promptTokenCount,
          output: usage.candidatesTokenCount,
        } : null,
      });
    } catch (err) {
      console.error('[diagnose] Error:', err.response?.data || err.message);

      if (err.response?.status === 429) {
        return res.status(429).json({ error: 'AI service rate limited. Try again in a moment.' });
      }

      res.status(500).json({ error: 'Diagnosis service unavailable' });
    }
  }
);

function buildDiagnosisPrompt(plantName, description, context) {
  let prompt = `You are Furrow's Plant Doctor, an expert at diagnosing vegetable garden plant problems from photos.

When analyzing a photo, provide:
1. **Diagnosis** — What you observe (disease, pest, deficiency, environmental stress, or healthy)
2. **Severity** — Mild, Moderate, or Severe
3. **Cause** — Most likely cause
4. **Treatment** — Specific, actionable steps the home gardener can take
5. **Prevention** — How to prevent this in the future

Keep responses concise and practical. If the plant looks healthy, celebrate that!
If you're unsure, say so and suggest what additional information would help.
Don't make up issues that aren't visible in the photo.`;

  if (context.zone) {
    prompt += `\n\nGardener's USDA Zone: ${context.zone}`;
  }
  if (context.season) {
    prompt += `\nSeason: ${context.season}`;
  }
  if (context.weather) {
    prompt += `\nRecent weather: ${JSON.stringify(context.weather)}`;
  }

  return prompt;
}

module.exports = router;
