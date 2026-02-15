require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { authMiddleware } = require('./middleware/auth');
const { budgetGuard, getCostSummary } = require('./utils/costTracker');
const { getUsage } = require('./middleware/rateLimit');

const app = express();
const PORT = process.env.PORT || 3100;

// ── Middleware ──
app.use(cors());
app.use(express.json({ limit: '1mb' }));

// Apply budget guard to all /api routes
app.use('/api', budgetGuard);

// ── Routes ──
app.use('/api/v1/chat', require('./routes/chat'));
app.use('/api/v1/identify', require('./routes/identify'));
app.use('/api/v1/diagnose', require('./routes/diagnose'));
app.use('/api/v1/recommend', require('./routes/recommend'));

// Usage endpoint — lets the app show remaining daily quota
app.get('/api/v1/usage', authMiddleware, (req, res) => {
  const usage = getUsage(req.user.userId);
  res.json({ userId: req.user.userId, usage });
});

// ── Health & Monitoring ──
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'furrow-ai-proxy',
    timestamp: new Date().toISOString(),
    uptime: Math.round(process.uptime()),
  });
});

// Admin cost endpoint (protected by a simple header check)
app.get('/admin/costs', (req, res) => {
  const adminKey = req.headers['x-admin-key'];
  if (adminKey !== process.env.JWT_SECRET) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  res.json(getCostSummary());
});

// ── Error handling ──
app.use((err, _req, res, _next) => {
  console.error('[server] Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ── Start ──
app.listen(PORT, () => {
  console.log(`Furrow AI Proxy running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Budget limit: $${process.env.MONTHLY_BUDGET_LIMIT || 100}/month`);

  // Validate required env vars
  const required = ['JWT_SECRET', 'GEMINI_API_KEY', 'PLANTNET_API_KEY'];
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    console.warn(`WARNING: Missing environment variables: ${missing.join(', ')}`);
  }
});
