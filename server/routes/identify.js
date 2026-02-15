const { Router } = require('express');
const axios = require('axios');
const multer = require('multer');
const FormData = require('form-data');
const { authMiddleware, requirePro } = require('../middleware/auth');
const { perUserRateLimit } = require('../middleware/rateLimit');

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
});

const PLANTNET_URL = 'https://my-api.plantnet.org/v2/identify/all';

/**
 * POST /api/v1/identify
 *
 * Multipart form data:
 *   image: file (JPEG/PNG, max 5MB)
 *   organs: string (optional) — "leaf", "flower", "fruit", "bark", "auto" (default)
 *
 * Returns PlantNet identification results.
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

      const organs = req.body.organs || 'auto';

      // Forward to PlantNet API
      const form = new FormData();
      form.append('images', req.file.buffer, {
        filename: req.file.originalname || 'plant.jpg',
        contentType: req.file.mimetype || 'image/jpeg',
      });
      form.append('organs', organs);

      const response = await axios.post(
        `${PLANTNET_URL}?include-related-images=false&no-reject=false&nb-results=5&lang=en&api-key=${process.env.PLANTNET_API_KEY}`,
        form,
        {
          headers: form.getHeaders(),
          timeout: 30000,
        }
      );

      const data = response.data;

      // Simplify results for the app
      const results = (data.results || []).map((r) => ({
        species: {
          scientificName: r.species?.scientificNameWithoutAuthor || '',
          commonNames: r.species?.commonNames || [],
          family: r.species?.family?.scientificNameWithoutAuthor || '',
        },
        score: Math.round((r.score || 0) * 100),
      }));

      res.json({
        results,
        bestMatch: results.length > 0 ? results[0] : null,
        query: { organs },
      });
    } catch (err) {
      console.error('[identify] Error:', err.response?.data || err.message);

      if (err.response?.status === 404) {
        return res.json({
          results: [],
          bestMatch: null,
          message: 'No plant species matched. Try a clearer photo of the leaves or flowers.',
        });
      }

      if (err.response?.status === 429) {
        return res.status(429).json({ error: 'Plant identification service rate limited. Try again later.' });
      }

      res.status(500).json({ error: 'Plant identification service unavailable' });
    }
  }
);

module.exports = router;
