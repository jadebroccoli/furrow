/**
 * Simple in-memory cost tracker with monthly budget circuit breaker.
 *
 * Tracks estimated API costs and prevents further requests
 * if the monthly budget is exceeded.
 */

// Monthly cost accumulator: { "2026-02": { total: 0.45, byCategory: { chat: 0.3, ... } } }
const monthlyCosts = new Map();

function monthKey() {
  return new Date().toISOString().slice(0, 7); // "2026-02"
}

function getMonthData() {
  const key = monthKey();
  if (!monthlyCosts.has(key)) {
    monthlyCosts.set(key, { total: 0, byCategory: {} });
  }
  return monthlyCosts.get(key);
}

/**
 * Track an API cost.
 * @param {number} costUsd - Estimated cost in USD
 * @param {string} category - Category (e.g., 'chat', 'diagnose', 'recommend')
 */
function trackCost(costUsd, category) {
  const data = getMonthData();
  data.total += costUsd;
  data.byCategory[category] = (data.byCategory[category] || 0) + costUsd;
}

/**
 * Check if the monthly budget has been exceeded.
 * @returns {{ exceeded: boolean, total: number, limit: number }}
 */
function checkBudget() {
  const limit = parseFloat(process.env.MONTHLY_BUDGET_LIMIT) || 100;
  const data = getMonthData();
  return {
    exceeded: data.total >= limit,
    total: Math.round(data.total * 10000) / 10000,
    limit,
    byCategory: data.byCategory,
  };
}

/**
 * Middleware that blocks requests when the budget is exceeded.
 */
function budgetGuard(req, res, next) {
  const budget = checkBudget();
  if (budget.exceeded) {
    console.warn(`[budget] Monthly budget exceeded: $${budget.total} / $${budget.limit}`);
    return res.status(503).json({
      error: 'AI features temporarily unavailable due to high demand',
      message: 'Please try again later. Our AI features will be back soon.',
    });
  }
  next();
}

/**
 * Get cost summary (for admin/monitoring).
 */
function getCostSummary() {
  const budget = checkBudget();
  return {
    month: monthKey(),
    totalCostUsd: budget.total,
    budgetLimitUsd: budget.limit,
    percentUsed: Math.round((budget.total / budget.limit) * 10000) / 100,
    byCategory: budget.byCategory,
  };
}

module.exports = { trackCost, checkBudget, budgetGuard, getCostSummary };
