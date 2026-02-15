/**
 * Per-user rate limiting with in-memory store.
 *
 * Tracks request counts per userId per endpoint category per day.
 * Resets at midnight UTC.
 */

// In-memory store: { "userId:category:dateKey": count }
const store = new Map();

// Clean up expired entries every hour
setInterval(() => {
  const today = dateKey();
  for (const key of store.keys()) {
    if (!key.endsWith(today)) {
      store.delete(key);
    }
  }
}, 60 * 60 * 1000);

function dateKey() {
  return new Date().toISOString().slice(0, 10); // "2026-02-14"
}

/**
 * Creates a per-user rate limiter for a given category.
 *
 * @param {string} category - Rate limit category (e.g., 'chat', 'photo', 'recommend')
 * @param {number} maxPerDay - Maximum requests per user per day
 */
function perUserRateLimit(category, maxPerDay) {
  return (req, res, next) => {
    if (!req.user || !req.user.userId) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const key = `${req.user.userId}:${category}:${dateKey()}`;
    const current = store.get(key) || 0;

    if (current >= maxPerDay) {
      return res.status(429).json({
        error: 'Daily limit reached',
        category,
        limit: maxPerDay,
        resetsAt: new Date(new Date().setUTCHours(24, 0, 0, 0)).toISOString(),
      });
    }

    store.set(key, current + 1);

    // Add usage info to response headers
    res.set('X-RateLimit-Limit', String(maxPerDay));
    res.set('X-RateLimit-Remaining', String(maxPerDay - current - 1));

    next();
  };
}

/**
 * Get current usage for a user across all categories.
 */
function getUsage(userId) {
  const today = dateKey();
  const usage = {};
  const categories = ['chat', 'photo', 'recommend'];

  for (const cat of categories) {
    const key = `${userId}:${cat}:${today}`;
    usage[cat] = {
      used: store.get(key) || 0,
      limit: getLimitForCategory(cat),
    };
  }

  return usage;
}

function getLimitForCategory(category) {
  switch (category) {
    case 'chat': return parseInt(process.env.RATE_LIMIT_CHAT) || 20;
    case 'photo': return parseInt(process.env.RATE_LIMIT_PHOTO) || 10;
    case 'recommend': return parseInt(process.env.RATE_LIMIT_RECOMMEND) || 3;
    default: return 10;
  }
}

module.exports = { perUserRateLimit, getUsage };
