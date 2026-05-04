const REQUIRED_PRICING_KEYS = [
  "story_promote_1d",
  "story_promote_3d",
  "story_promote_7d",
  "offer_pin_1d",
  "offer_pin_3d",
  "offer_pin_7d",
];

const WALLET_PRICING_DEFAULTS = {
  story_promote_1d: 3,
  story_promote_3d: 7,
  story_promote_7d: 14,
  offer_pin_1d: 4,
  offer_pin_3d: 9,
  offer_pin_7d: 16,
  currency: "ILS",
};

function parseCliArgs(argv) {
  const args = {};
  for (const token of argv) {
    if (!token.startsWith("--")) continue;
    const [rawKey, ...valueParts] = token.slice(2).split("=");
    if (!rawKey) continue;
    if (valueParts.length === 0) {
      args[rawKey.trim()] = true;
      continue;
    }
    args[rawKey.trim()] = valueParts.join("=").trim();
  }
  return args;
}

function roundMoney(value) {
  return Math.round(value * 100) / 100;
}

function toFiniteNumber(value) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value.trim());
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function validateWalletPricingConfig(pricing, options = {}) {
  const allowNonPositive = options.allowNonPositive === true;
  const allowZeroOnly = options.allowZeroOnly === true;
  const issues = [];
  const normalized = {};
  let numericCount = 0;
  let nonPositiveCount = 0;

  for (const key of REQUIRED_PRICING_KEYS) {
    if (!(key in pricing)) {
      issues.push({ code: "missing_key", field: key, message: `${key} is missing` });
      continue;
    }
    const amount = toFiniteNumber(pricing[key]);
    if (amount == null) {
      issues.push({
        code: "invalid_number",
        field: key,
        message: `${key} must be a finite number`,
      });
      continue;
    }
    numericCount += 1;
    if (amount <= 0) nonPositiveCount += 1;
    if (!allowNonPositive && amount <= 0) {
      issues.push({
        code: "non_positive",
        field: key,
        message: `${key} must be greater than zero`,
      });
    }
    normalized[key] = roundMoney(amount);
  }

  const currency = typeof pricing.currency === "string" ? pricing.currency.trim() : "";
  if (!currency) {
    issues.push({
      code: "missing_currency",
      field: "currency",
      message: "currency must be a non-empty string",
    });
  } else {
    normalized.currency = currency.toUpperCase();
  }

  if (!allowZeroOnly &&
      numericCount === REQUIRED_PRICING_KEYS.length &&
      nonPositiveCount === REQUIRED_PRICING_KEYS.length) {
    issues.push({
      code: "zero_only_pricing",
      field: "pricing",
      message: "all pricing values are non-positive; this is unsafe for enabled features",
    });
  }

  return {
    valid: issues.length === 0,
    issues,
    normalizedPricing: normalized,
  };
}

function formatIssues(issues) {
  return issues.map((issue) => `[${issue.code}] ${issue.message}`).join("; ");
}

module.exports = {
  REQUIRED_PRICING_KEYS,
  WALLET_PRICING_DEFAULTS,
  parseCliArgs,
  roundMoney,
  toFiniteNumber,
  validateWalletPricingConfig,
  formatIssues,
};
