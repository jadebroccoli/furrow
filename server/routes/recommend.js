const { Router } = require('express');
const axios = require('axios');
const { authMiddleware, requirePro } = require('../middleware/auth');
const { perUserRateLimit } = require('../middleware/rateLimit');
const { trackCost } = require('../utils/costTracker');

const router = Router();

const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';

// Zone-level cache: { "7b:2026-03": { data, timestamp } }
const cache = new Map();
const CACHE_TTL = 7 * 24 * 60 * 60 * 1000; // 7 days

/**
 * POST /api/v1/recommend
 *
 * Body: {
 *   zone: string,           — USDA zone (e.g., "7b")
 *   month: number,          — Current month (1-12)
 *   existingPlants?: string[], — Species already planted
 *   gardenSize?: string,    — e.g., "small", "medium", "large"
 * }
 */
router.post(
  '/',
  authMiddleware,
  requirePro,
  perUserRateLimit('recommend', parseInt(process.env.RATE_LIMIT_RECOMMEND) || 3),
  async (req, res) => {
    try {
      const { zone, month, existingPlants, gardenSize } = req.body;

      if (!zone || !month) {
        return res.status(400).json({ error: 'Zone and month are required' });
      }

      // Check cache first (zone-level, not user-specific)
      const cacheKey = `${zone}:${new Date().getFullYear()}-${String(month).padStart(2, '0')}`;
      const cached = cache.get(cacheKey);

      if (cached && (Date.now() - cached.timestamp) < CACHE_TTL) {
        // Personalize the cached base recommendation
        const personalized = personalizeRecommendation(cached.data, existingPlants);
        return res.json({
          recommendation: personalized,
          cached: true,
          zone,
          month,
        });
      }

      // Generate fresh recommendation
      const prompt = buildRecommendPrompt(zone, month, gardenSize);

      const response = await axios.post(
        `${GEMINI_URL}?key=${process.env.GEMINI_API_KEY}`,
        {
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: {
            maxOutputTokens: 1024,
            temperature: 0.6,
          },
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000,
        }
      );

      const candidate = response.data.candidates?.[0];
      if (!candidate || !candidate.content?.parts?.[0]?.text) {
        return res.status(502).json({ error: 'No recommendation from AI' });
      }

      const recommendation = candidate.content.parts[0].text;

      // Cache the base recommendation
      cache.set(cacheKey, {
        data: recommendation,
        timestamp: Date.now(),
      });

      // Track cost
      const usage = response.data.usageMetadata;
      if (usage) {
        const inputTokens = usage.promptTokenCount || 0;
        const outputTokens = usage.candidatesTokenCount || 0;
        const cost = (inputTokens * 0.15 + outputTokens * 0.60) / 1_000_000;
        trackCost(cost, 'recommend');
      }

      // Personalize for this user
      const personalized = personalizeRecommendation(recommendation, existingPlants);

      res.json({
        recommendation: personalized,
        cached: false,
        zone,
        month,
      });
    } catch (err) {
      console.error('[recommend] Error:', err.response?.data || err.message);

      if (err.response?.status === 429) {
        return res.status(429).json({ error: 'AI service rate limited. Try again later.' });
      }

      res.status(500).json({ error: 'Recommendation service unavailable' });
    }
  }
);

function buildRecommendPrompt(zone, month, gardenSize) {
  const monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  const monthName = monthNames[month] || 'Unknown';
  const sizeContext = gardenSize ? `Garden size: ${gardenSize}.` : '';

  return `You are a vegetable garden planting advisor. Give practical planting recommendations for USDA Hardiness Zone ${zone} in ${monthName}.

${sizeContext}

Provide:
1. **Plant Now (Direct Sow)** — What can be planted directly in the ground right now
2. **Start Indoors** — What seeds to start indoors for transplanting later
3. **Harvest Time** — What may be ready to harvest if previously planted
4. **Garden Tasks** — 2-3 important tasks for this month (mulching, pruning, pest prevention, etc.)
5. **Pro Tip** — One expert tip specific to this zone and month

Focus on common vegetable garden crops: tomatoes, peppers, squash, beans, peas, lettuce, herbs, root vegetables, etc.
Keep it concise and actionable. Use bullet points.`;
}

function personalizeRecommendation(baseRecommendation, existingPlants) {
  if (!existingPlants || existingPlants.length === 0) {
    return baseRecommendation;
  }

  // Simple personalization: append a note about what they already have
  const plantList = existingPlants.slice(0, 10).join(', ');
  return baseRecommendation + `\n\n---\n*You already have ${plantList} in your garden. Consider companion planting opportunities!*`;
}

module.exports = router;
