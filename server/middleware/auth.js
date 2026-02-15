const jwt = require('jsonwebtoken');

/**
 * JWT authentication middleware.
 *
 * Expects: Authorization: Bearer <token>
 * Token payload must include: { userId, isPro, iat, exp }
 *
 * Sets req.user = { userId, isPro } on success.
 */
function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = header.slice(7);

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded.userId) {
      return res.status(401).json({ error: 'Invalid token payload' });
    }

    req.user = {
      userId: decoded.userId,
      isPro: decoded.isPro === true,
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

/**
 * Require Pro subscription.
 * Must be used AFTER authMiddleware.
 */
function requirePro(req, res, next) {
  if (!req.user || !req.user.isPro) {
    return res.status(403).json({
      error: 'Pro subscription required',
      upgrade: true,
    });
  }
  next();
}

module.exports = { authMiddleware, requirePro };
