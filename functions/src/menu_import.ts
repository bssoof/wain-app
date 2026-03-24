import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";
import * as functions from "firebase-functions/v1";

type MenuImportStatus =
  | "uploaded"
  | "ocr_done"
  | "extracted"
  | "mapped"
  | "review_required"
  | "published";

type StageName = "ocr" | "extracted" | "mapped";

type StageResult = { jobId: string; status: string; idempotent: boolean };

type OcrLine = { text: string; confidence: number };

type OcrPayload = {
  source: string;
  input_file: string;
  input_files?: string[];
  lines: OcrLine[];
  line_count: number;
  average_confidence: number;
  max_lines: number;
  truncated: boolean;
  generated_at: string;
};

type ExtractedCandidate = {
  raw_line: string;
  name_ar: string;
  price: number | null;
  currency: string;
  market_price_flag: boolean;
  confidence: number;
  category_hint: string | null;
};

type ExtractedPayload = {
  source: string;
  candidates: ExtractedCandidate[];
  skipped_lines: number;
  generated_at: string;
};

type JobCore = {
  status: string;
  versionId: string;
  inputFiles: string[];
};

type CategoryState = {
  id: string;
  key: string;
  nameAr: string;
  nameEn: string;
  sortOrder: number;
  matchTokens: string[];
};

const STATUS_ORDER: MenuImportStatus[] = [
  "uploaded",
  "ocr_done",
  "extracted",
  "mapped",
  "review_required",
  "published",
];

const DEFAULT_CURRENCY = "ILS";
const MAX_OCR_LINES_BASE = 2000;
const MAX_OCR_LINES_PER_FILE = 800;

const CATEGORY_KEYWORDS: Record<string, string[]> = {
  hot_drinks: [
    "hot drinks",
    "coffee",
    "latte",
    "cappuccino",
    "espresso",
    "americano",
    "mocha",
    "\u0645\u0634\u0631\u0648\u0628\u0627\u062a \u0633\u0627\u062e\u0646\u0629",
    "\u0642\u0647\u0648\u0629",
    "\u0634\u0627\u064a",
    "\u0643\u0648\u0641\u064a",
    "\u0644\u0627\u062a\u064a\u0647",
    "\u0643\u0627\u0628\u062a\u0634\u064a\u0646\u0648",
    "\u0627\u0633\u0628\u0631\u064a\u0633\u0648",
    "\u0645\u0648\u0643\u0627",
    "\u0646\u0633\u0643\u0627\u0641\u064a\u0647",
  ],
  cold_drinks: [
    "cold drinks",
    "iced",
    "frappe",
    "smoothie",
    "mojito",
    "milkshake",
    "soft drink",
    "soda",
    "cola",
    "water",
    "\u0645\u0634\u0631\u0648\u0628\u0627\u062a \u0628\u0627\u0631\u062f\u0629",
    "\u0641\u0631\u0627\u0628\u064a\u0647",
    "\u0645\u0648\u0647\u064a\u062a\u0648",
    "\u0645\u064a\u0644\u0643 \u0634\u064a\u0643",
    "\u0645\u0634\u0631\u0648\u0628 \u063a\u0627\u0632\u064a",
    "\u063a\u0627\u0632\u064a",
    "\u0645\u0627\u0621",
    "\u0645\u064a",
    "\u0645\u064a\u0629",
    "\u0628\u064a\u0628\u0633\u064a",
    "\u0643\u0648\u0644\u0627",
    "\u0633\u0628\u0631\u0627\u064a\u062a",
    "\u0644\u064a\u0645\u0648\u0646\u0627\u062f\u0627",
    "\u0644\u0628\u0646",
    "\u0631\u0648\u0628",
  ],
  juices: [
    "juice",
    "fresh juice",
    "smoothie",
    "\u0639\u0635\u0627\u0626\u0631",
    "\u0639\u0635\u064a\u0631",
    "\u0633\u0645\u0648\u0630\u064a",
  ],
  hookah: ["hookah", "shisha", "\u0623\u0631\u0627\u062c\u064a\u0644", "\u0627\u0631\u062c\u064a\u0644\u0629"],
  appetizers: ["appetizer", "starters", "\u0645\u0642\u0628\u0644\u0627\u062a"],
  main_courses: [
    "main",
    "main course",
    "breakfast",
    "brunch",
    "\u0623\u0637\u0628\u0627\u0642 \u0631\u0626\u064a\u0633\u064a\u0629",
    "\u0637\u0628\u0642 \u0631\u0626\u064a\u0633\u064a",
    "\u0627\u0644\u0641\u0637\u0648\u0631",
    "\u0641\u0637\u0648\u0631",
    "\u0627\u0641\u0637\u0627\u0631",
    "\u0627\u0644\u0628\u062e\u0627\u0631\u064a",
    "\u0628\u062e\u0627\u0631\u064a",
  ],
  grills: ["grill", "bbq", "\u0645\u0634\u0627\u0648\u064a", "\u0645\u0634\u0648\u064a\u0627\u062a", "\u0627\u0644\u0645\u0634\u0648\u064a\u0627\u062a"],
  soups: ["soup", "\u0634\u0648\u0631\u0628\u0627\u062a", "\u0634\u0648\u0631\u0628\u0629"],
  breakfast: [
    "breakfast",
    "brunch",
    "\u0627\u0644\u0641\u0637\u0648\u0631",
    "\u0641\u0637\u0648\u0631",
    "\u0627\u0641\u0637\u0627\u0631",
  ],
  desserts: [
    "dessert",
    "sweet",
    "cake",
    "\u062d\u0644\u0648\u064a\u0627\u062a",
    "\u062d\u0644\u0649",
  ],
  drinks: [
    "drink",
    "beverage",
    "soft drink",
    "soda",
    "cola",
    "water",
    "juice",
    "tea",
    "coffee",
    "\u0645\u0634\u0631\u0648\u0628\u0627\u062a",
    "\u0645\u0634\u0627\u0631\u064a\u0628",
    "\u0645\u0627\u0621",
    "\u0645\u064a",
    "\u0645\u0634\u0631\u0648\u0628 \u063a\u0627\u0632\u064a",
    "\u063a\u0627\u0632\u064a",
    "\u0628\u064a\u0628\u0633\u064a",
    "\u0643\u0648\u0644\u0627",
    "\u0633\u0628\u0631\u0627\u064a\u062a",
    "\u0644\u064a\u0645\u0648\u0646\u0627\u062f\u0627",
    "\u0644\u0628\u0646",
    "\u0631\u0648\u0628",
    "\u0634\u0627\u064a",
    "\u0642\u0647\u0648\u0629",
  ],
  burgers: ["burger", "\u0628\u0631\u063a\u0631"],
  shawarma: ["shawarma", "\u0634\u0627\u0648\u0631\u0645\u0627", "\u0627\u0644\u0634\u0627\u0648\u0631\u0645\u0627"],
  pizza: ["pizza", "\u0628\u064a\u062a\u0632\u0627"],
  sandwiches: ["sandwich", "\u0633\u0627\u0646\u062f\u0648\u064a\u0634", "\u0633\u0646\u062f\u0648\u064a\u0634"],
  sides: ["side", "fries", "\u0625\u0636\u0627\u0641\u0627\u062a", "\u0628\u0637\u0627\u0637\u0627"],
  fresh_juices: ["fresh juice", "fresh", "\u0639\u0635\u064a\u0631 \u0637\u0628\u064a\u0639\u064a"],
  smoothies: ["smoothie", "\u0633\u0645\u0648\u0630\u064a"],
  cocktails: ["cocktail", "\u0643\u0648\u0643\u062a\u064a\u0644"],
  milkshakes: ["milkshake", "\u0645\u064a\u0644\u0643 \u0634\u064a\u0643"],
};

const HEADING_PREFIXES = [
  "menu",
  "\u0642\u0627\u0626\u0645\u0629",
  "\u0642\u0633\u0645",
  "\u0631\u0643\u0646",
];

const SECTION_LABEL_KEYWORDS = [
  "menu",
  "food menu",
  "drinks",
  "beverages",
  "desserts",
  "appetizers",
  "main courses",
  "grills",
  "soups",
  "breakfast",
  "\u0642\u0627\u0626\u0645\u0629",
  "\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0637\u0639\u0627\u0645",
  "\u0627\u0644\u0645\u0634\u0631\u0648\u0628\u0627\u062a",
  "\u0645\u0634\u0631\u0648\u0628\u0627\u062a",
  "\u0627\u0644\u062d\u0644\u0648\u064a\u0627\u062a",
  "\u062d\u0644\u0648\u064a\u0627\u062a",
  "\u0627\u0644\u0645\u0634\u0627\u0648\u064a",
  "\u0645\u0634\u0627\u0648\u064a",
  "\u0627\u0644\u0645\u0642\u0628\u0644\u0627\u062a",
  "\u0645\u0642\u0628\u0644\u0627\u062a",
  "\u0627\u0644\u0623\u0637\u0628\u0627\u0642 \u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629",
  "\u0627\u0637\u0628\u0627\u0642 \u0631\u0626\u064a\u0633\u064a\u0629",
  "\u0627\u0644\u0641\u0637\u0648\u0631",
  "\u0641\u0637\u0648\u0631",
  "\u0627\u0641\u0637\u0627\u0631",
  "\u0627\u0644\u0634\u0648\u0631\u0628\u0627\u062a",
  "\u0634\u0648\u0631\u0628\u0627\u062a",
];

const CONTACT_ADDRESS_NOISE_TOKENS = [
  "street",
  "road",
  "avenue",
  "building",
  "floor",
  "address",
  "location",
  "branch",
  "delivery",
  "phone",
  "mobile",
  "whatsapp",
  "contact",
  "\u0634\u0627\u0631\u0639",
  "\u0637\u0631\u064a\u0642",
  "\u0639\u0645\u0627\u0631\u0629",
  "\u0628\u0646\u0627\u064a\u0629",
  "\u0637\u0627\u0628\u0642",
  "\u0639\u0646\u0648\u0627\u0646",
  "\u0645\u0648\u0642\u0639",
  "\u0641\u0631\u0639",
  "\u0647\u0627\u062a\u0641",
  "\u062c\u0648\u0627\u0644",
  "\u0627\u062a\u0635\u0627\u0644",
  "\u0648\u0627\u062a\u0633\u0627\u0628",
  "\u0627\u0644\u062a\u0648\u0635\u064a\u0644",
  "\u062a\u0648\u0635\u064a\u0644",
  "\u0645\u0642\u0627\u0628\u0644",
  "\u0628\u062c\u0627\u0646\u0628",
  "\u0642\u0631\u0628",
];

const IMPORT_ERROR_NOISE_TOKENS = [
  "enable it by visiting",
  "cloud vision api",
  "permission_denied",
  "service_disabled",
  "type.googleapis.com",
  "google.rpc.errorinfo",
  "googleapis.com",
  "\"error\"",
  "\"status\"",
  "\"details\"",
  "\"metadata\"",
  "contact us",
];

const SHORT_SINGLE_WORD_ALLOWLIST = new Set([
  normalizeText("tea"),
  normalizeText("chai"),
  normalizeText("coffee"),
  normalizeText("water"),
  normalizeText("cola"),
  normalizeText("\u0634\u0627\u064a"),
  normalizeText("\u0642\u0647\u0648\u0629"),
  normalizeText("\u0645\u0627\u0621"),
  normalizeText("\u0645\u0648\u064a\u0629"),
  normalizeText("\u0641\u0648\u0644"),
  normalizeText("\u062d\u0645\u0635"),
  normalizeText("\u0639\u062f\u0633"),
  normalizeText("\u0627\u0631\u0632"),
  normalizeText("\u0631\u0632"),
  normalizeText("\u0643\u064a\u0643"),
  normalizeText("\u0622\u064a\u0633"),
  normalizeText("\u0643\u0648\u0641\u064a"),
  normalizeText("\u0644\u0627\u062a\u064a\u0647"),
  normalizeText("\u0643\u0627\u0628\u062a\u0634\u064a\u0646\u0648"),
  normalizeText("\u0627\u0633\u0628\u0631\u064a\u0633\u0648"),
  normalizeText("\u0627\u0645\u0631\u064a\u0643\u0627\u0646\u0648"),
  normalizeText("\u0645\u0648\u0643\u0627"),
  normalizeText("\u0641\u0631\u0627\u0628\u064a\u0647"),
  normalizeText("\u0645\u0648\u0647\u064a\u062a\u0648"),
  normalizeText("\u0644\u064a\u0645\u0648\u0646\u0627\u062f\u0627"),
  normalizeText("\u0633\u0645\u0648\u0630\u064a"),
  normalizeText("\u0645\u062a\u0634\u0627"),
  normalizeText("\u0646\u0633\u0643\u0627\u0641\u064a\u0647"),
  normalizeText("\u0628\u064a\u0628\u0633\u064a"),
  normalizeText("\u0643\u0648\u0644\u0627"),
  normalizeText("\u0633\u0628\u0631\u0627\u064a\u062a"),
  normalizeText("\u0644\u064a\u0645\u0648\u0646\u0627\u062f\u0627"),
  normalizeText("\u0644\u0628\u0646"),
  normalizeText("\u0631\u0648\u0628"),
  normalizeText("water"),
  normalizeText("soda"),
  normalizeText("cola"),
  normalizeText("latte"),
  normalizeText("cappuccino"),
  normalizeText("espresso"),
  normalizeText("americano"),
  normalizeText("mocha"),
  normalizeText("frappe"),
  normalizeText("mojito"),
  normalizeText("smoothie"),
  normalizeText("milkshake"),
]);

const HINT_FALLBACK_CATEGORY_KEYS: Record<string, string[]> = {
  hot_drinks: ["drinks", "cold_drinks", "hot_drinks"],
  cold_drinks: ["drinks", "cold_drinks", "hot_drinks"],
  juices: ["drinks", "fresh_juices"],
  smoothies: ["drinks", "smoothies"],
  cocktails: ["drinks", "cocktails"],
  milkshakes: ["drinks", "milkshakes"],
  desserts: ["desserts", "sweets"],
  appetizers: ["appetizers", "sides"],
  main_courses: [
    "main_courses",
    "food",
    "grills",
    "shawarma",
    "burgers",
    "pizza",
    "sandwiches",
    "appetizers",
    "sides",
  ],
  grills: ["grills", "main_courses", "food", "appetizers"],
  shawarma: ["shawarma", "main_courses", "grills", "appetizers"],
  burgers: ["burgers", "main_courses", "grills", "appetizers"],
  pizza: ["pizza", "main_courses", "grills", "appetizers"],
  sandwiches: ["sandwiches", "main_courses", "appetizers", "sides"],
  soups: ["soups", "appetizers", "main_courses", "food"],
  breakfast: ["main_courses", "food", "appetizers", "soups"],
};

const HINT_LABELS_AR: Record<string, string> = {
  drinks: "\u0645\u0634\u0631\u0648\u0628\u0627\u062a",
  hot_drinks: "\u0645\u0634\u0631\u0648\u0628\u0627\u062a \u0633\u0627\u062e\u0646\u0629",
  cold_drinks: "\u0645\u0634\u0631\u0648\u0628\u0627\u062a \u0628\u0627\u0631\u062f\u0629",
  juices: "\u0639\u0635\u0627\u0626\u0631",
  smoothies: "\u0633\u0645\u0648\u0630\u064a",
  cocktails: "\u0643\u0648\u0643\u062a\u064a\u0644",
  milkshakes: "\u0645\u064a\u0644\u0643 \u0634\u064a\u0643",
  appetizers: "\u0645\u0642\u0628\u0644\u0627\u062a",
  main_courses: "\u0623\u0637\u0628\u0627\u0642 \u0631\u0626\u064a\u0633\u064a\u0629",
  grills: "\u0645\u0634\u0627\u0648\u064a",
  soups: "\u0634\u0648\u0631\u0628\u0627\u062a",
  desserts: "\u062d\u0644\u0648\u064a\u0627\u062a",
  breakfast: "\u0641\u0637\u0648\u0631",
};

function firestoreDb(): FirebaseFirestore.Firestore {
  return admin.firestore();
}

function asText(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function asOptionalText(value: unknown): string | null {
  const v = asText(value);
  return v ? v : null;
}

function asNum(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function normalizeInputFiles(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((x) => asText(x)).filter((x) => x.length > 0);
}

function rank(status: string): number {
  return STATUS_ORDER.indexOf(status as MenuImportStatus);
}

function errText(error: unknown): string {
  if (error instanceof functions.https.HttpsError) return error.message;
  if (error instanceof Error) return error.message;
  return String(error);
}

function normalizeText(value: string): string {
  return value
    .toLowerCase()
    .replace(/[\u064B-\u0652]/g, "")
    .replace(/[^a-z0-9\u0600-\u06FF]+/gi, " ")
    .trim();
}

const DIGIT_MAP: Record<string, string> = {
  "\u0660": "0",
  "\u0661": "1",
  "\u0662": "2",
  "\u0663": "3",
  "\u0664": "4",
  "\u0665": "5",
  "\u0666": "6",
  "\u0667": "7",
  "\u0668": "8",
  "\u0669": "9",
  "\u06F0": "0",
  "\u06F1": "1",
  "\u06F2": "2",
  "\u06F3": "3",
  "\u06F4": "4",
  "\u06F5": "5",
  "\u06F6": "6",
  "\u06F7": "7",
  "\u06F8": "8",
  "\u06F9": "9",
};

function normalizeDigits(value: string): string {
  return value
    .replace(/[\u0660-\u0669\u06F0-\u06F9]/g, (match) => DIGIT_MAP[match] ?? match)
    .replace(/\u066B/g, ".")
    .replace(/\u066C/g, ",");
}

function normalizePotentialPriceText(value: string): string {
  return normalizeDigits(value)
    .replace(/[oO]/g, "0")
    .replace(/[lI]/g, "1")
    .replace(/(\d)\s+(?=\d)/g, "$1");
}

function stageDefaultRef(venueId: string, jobId: string, stage: StageName): string {
  return `gs://menu-import/${venueId}/${jobId}/${stage}.json`;
}

function logMenuImportStage(
  level: "info" | "warn" | "error",
  message: string,
  payload: Record<string, unknown>,
): void {
  const data = {
    component: "menu_import",
    ...payload,
  };
  if (level === "error") {
    functions.logger.error(message, data);
    return;
  }
  if (level === "warn") {
    functions.logger.warn(message, data);
    return;
  }
  functions.logger.info(message, data);
}

function parseInlinePrice(line: string): { price: number; matched: string } | null {
  const normalized = normalizePotentialPriceText(line);
  // Price must be at/near the end of the line (last portion), not in the middle of text
  const regex = /(\d{1,5}(?:[.,]\d{1,3})?)\s*(?:\u20aa|ils|nis|shekel|shekels|شيكل|شاقل)?\s*$/gi;
  const match = regex.exec(normalized);
  if (!match) return null;
  const price = asNum(match[1]);
  if (price === null || price <= 0) return null;
  // Make sure there's some text before the price (not just a number line)
  const beforePrice = normalized.slice(0, match.index).trim();
  const hasText = /[a-z\u0600-\u06FF]/i.test(beforePrice);
  if (!hasText) return null;
  return { price, matched: match[0] };
}

function parseLeaderSeparatedPairs(line: string): Array<{ name: string; price: number }> {
  const normalized = normalizeDigits(line);
  const separatorRegex = /(?:[.\u00b7\u2022\u2024\u2027]{3,}|[_\-]{2,}|\|+)/g;
  if (!separatorRegex.test(normalized)) return [];

  const tokens = normalized
    .split(separatorRegex)
    .map((token) => asText(token))
    .filter((token) => token.length > 0);

  if (tokens.length < 2) return [];

  const results: Array<{ name: string; price: number }> = [];
  const seen = new Set<string>();

  const pushPair = (nameRaw: string, priceRaw: number): void => {
    const name = stripPriceArtifacts(nameRaw);
    if (!isPotentialItemText(name)) return;
    if (isCategoryLabelText(name)) return;
    if (isLikelyNonMenuNoise(name)) return;
    const key = `${normalizeText(name)}|${Number(priceRaw.toFixed(3))}`;
    if (seen.has(key)) return;
    seen.add(key);
    results.push({ name, price: Number(priceRaw.toFixed(3)) });
  };

  for (let i = 0; i < tokens.length - 1; i += 1) {
    const left = tokens[i];
    const right = tokens[i + 1];

    const leftPriceOnly = parsePriceOnlyLine(left);
    const rightPriceOnly = parsePriceOnlyLine(right);

    if (leftPriceOnly !== null) {
      pushPair(right, leftPriceOnly);
    }
    if (rightPriceOnly !== null) {
      pushPair(left, rightPriceOnly);
    }
  }

  return results;
}

function splitLineIntoPriceSegments(line: string): string[] {
  const normalized = normalizeDigits(line);
  const regex = /(\d{1,5}(?:[.,]\d{1,3})?)\s*(?:\u20aa|ils|nis)?/gi;
  const matches = [...normalized.matchAll(regex)];
  if (matches.length <= 1) return [line];

  const segments: string[] = [];
  let cursor = 0;
  for (const match of matches) {
    const index = match.index ?? -1;
    if (index < 0) continue;
    const end = index + match[0].length;
    const segment = asText(line.slice(cursor, end));
    if (segment) segments.push(segment);
    cursor = end;
  }

  const tail = asText(line.slice(cursor));
  if (tail) {
    if (segments.length && !/[0-9\u0660-\u0669\u06F0-\u06F9]/.test(tail)) {
      segments[segments.length - 1] = asText(`${segments[segments.length - 1]} ${tail}`);
    } else {
      segments.push(tail);
    }
  }

  return segments.length ? segments : [line];
}

function parsePriceOnlyLine(line: string): number | null {
  const normalized = normalizePotentialPriceText(line);
  const withoutCurrencyWords = normalized
    .replace(/\b(?:ils|nis|shekel|shekels)\b/gi, " ")
    .replace(/شيكل|شيقل|شاقل/g, " ");
  const hasLetters = /[a-z\u0600-\u06FF]/i.test(withoutCurrencyWords);
  if (hasLetters) return null;

  const match = withoutCurrencyWords.match(/^\D*(\d{1,5}(?:[.,]\d{1,3})?)\D*$/i);
  if (!match) return null;
  return asNum(match[1]);
}

function stripPriceArtifacts(line: string): string {
  return normalizeDigits(line)
    .replace(/(\d{1,5}(?:[.,]\d{1,3})?)\s*(?:\u20aa|ils|nis)?/gi, " ")
    .replace(/[|:\u061b\u060c\-\u2013\u2014]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function hintIndicatesDrinks(hint: string | null): boolean {
  const normalized = normalizeText(asText(hint));
  if (!normalized) return false;
  return [
    "drink",
    "beverage",
    "hot_drinks",
    "cold_drinks",
    "juice",
    "smoothie",
    "cocktail",
    "milkshake",
    "\u0645\u0634\u0631\u0648\u0628",
    "\u0645\u0634\u0631\u0648\u0628\u0627\u062a",
    "\u0642\u0647\u0648\u0629",
    "\u0639\u0635\u064a\u0631",
    "\u0639\u0635\u0627\u0626\u0631",
    "\u0643\u0648\u0641\u064a",
    "\u0644\u0627\u062a\u064a\u0647",
    "\u0641\u0631\u0627\u0628\u064a\u0647",
    "\u0645\u0648\u0647\u064a\u062a\u0648",
  ].some((token) => normalized.includes(normalizeText(token)));
}

function isLikelyImportErrorNoise(raw: string): boolean {
  const text = asText(raw);
  if (!text) return false;

  const normalized = normalizeDigits(text).toLowerCase();
  const normalizedWords = normalizeText(text);

  if (IMPORT_ERROR_NOISE_TOKENS.some((token) => normalized.includes(token.toLowerCase()))) {
    return true;
  }

  if (/type\.googleapis\.com|googleapis\.com|permission_denied|service_disabled/i.test(normalized)) {
    return true;
  }

  // JSON-like error payload fragments are never valid section/item names.
  if (/[{}\[\]"]/.test(text) && /[:]/.test(text) && normalizedWords.length > 0) {
    return true;
  }

  return false;
}

function isLikelyCorruptedText(raw: string): boolean {
  const text = asText(raw);
  if (!text) return true;

  // Detect mojibake: sequences of characters from Latin Extended/supplement blocks
  // that look like double-encoded Arabic (Windows-1256 → UTF-8 misinterpretation)
  const mojibakeChars = (text.match(/[\u00C0-\u00FF]/g) ?? []).length;
  if (mojibakeChars >= 3 && mojibakeChars > text.length * 0.3) return true;

  // Detect "Ø" pattern common in Arabic double-encoding (e.g. "Ø³Ù„Ø§Ù…")
  if (/[\u00D8\u00D9\u00DA\u00DB][\u0080-\u00BF]/.test(text)) return true;

  // Detect high ratio of replacement characters or unknown symbols
  const replacementChars = (text.match(/[\uFFFD\uFFFE\uFFFF]/g) ?? []).length;
  if (replacementChars >= 2) return true;

  // Detect text that is mostly non-printable control characters
  const controlChars = (text.match(/[\x00-\x1F\x7F-\x9F]/g) ?? []).length;
  if (controlChars >= 2) return true;

  return false;
}

function isLikelySectionHeading(raw: string, explicitHint: string): boolean {
  const text = asText(raw);
  if (!text) return false;
  const hasDigits = /[0-9\u0660-\u0669\u06F0-\u06F9]/.test(text);

  const cleaned = text.replace(/[:\uFF1A]+$/, "").trim();
  const words = cleaned.split(/\s+/).filter(Boolean);
  if (!words.length || words.length > 3) return false;

  if (hasDigits) return false;
  if (isLikelyImportErrorNoise(cleaned)) return false;
  if (isLikelyNonMenuNoise(cleaned)) return false;
  if (isLikelyCorruptedText(cleaned)) return false;

  const normalized = normalizeText(cleaned);
  if (HEADING_PREFIXES.some((prefix) => normalized.startsWith(prefix))) {
    return true;
  }
  const knownHeading = SECTION_LABEL_KEYWORDS
    .some((keyword) => normalizeText(keyword) === normalized);
  if (knownHeading) return true;

  if (/[:\uFF1A]$/.test(text)) {
    // Generic ":" heading fallback only for short Arabic labels
    // that look like actual menu section names.
    const hasArabic = /[\u0600-\u06FF]/.test(cleaned);
    if (!hasArabic) return false;
    if (words.length > 2) return false;
    // Reject labels that contain Latin chars mixed with Arabic (likely OCR noise)
    const hasLatin = /[a-z]/i.test(cleaned);
    if (hasLatin) return false;
    // Reject very short single-character Arabic "labels"
    if (cleaned.replace(/[^\u0600-\u06FF]/g, "").length < 2) return false;
    return true;
  }

  return false;
}

function isCategoryLabelText(raw: string): boolean {
  const normalized = normalizeText(raw.replace(/[:\uFF1A]+$/, "").trim());
  if (!normalized) return false;

  if (HEADING_PREFIXES.some((prefix) => normalized === prefix || normalized.startsWith(`${prefix} `))) {
    return true;
  }

  return SECTION_LABEL_KEYWORDS
    .some((keyword) => normalizeText(keyword) === normalized);
}

function isLikelyNonMenuNoise(raw: string): boolean {
  const text = asText(raw);
  if (!text) return true;
  if (isLikelyImportErrorNoise(text)) return true;

  const normalized = normalizeDigits(text).toLowerCase();
  const normalizedWords = normalizeText(text);
  const hasDigits = /[0-9]/.test(normalized);
  if (/https?:\/\//i.test(normalized)) return true;
  if (/www\./i.test(normalized)) return true;
  if (/\b[a-z0-9._%+-]+\.(com|net|org|io|co)\b/i.test(normalized)) return true;
  if (/\b[a-z0-9-]+(?:\.[a-z0-9-]+){1,3}\.[a-z]{2,10}\b/i.test(normalized)) return true;
  if (/(instagram|facebook|tiktok|snapchat|whatsapp)/i.test(normalized)) return true;
  if (CONTACT_ADDRESS_NOISE_TOKENS.some((token) => normalizedWords.includes(normalizeText(token)))) {
    if (hasDigits) return true;
    return true;
  }
  if (/\+?\d[\d\s\-()]{7,}\d/.test(normalized)) return true;
  if ((normalized.match(/\d+/g) ?? []).length >= 2 && hasDigits) {
    if (/\b(?:street|road|avenue|building|address|location|branch|شارع|عمارة|بناية|عنوان|موقع|فرع)\b/i
      .test(normalizedWords)) {
      return true;
    }
  }

  const alphaCount = (text.match(/[a-z\u0600-\u06FF]/gi) ?? []).length;
  return alphaCount === 0;
}

function isPotentialItemText(text: string): boolean {
  if (!text || text.length < 3 || text.length > 80) return false;
  if (isLikelyNonMenuNoise(text)) return false;
  const words = text.split(/\s+/).filter(Boolean);
  if (!words.length || words.length > 8) return false;
  const alphaCount = (text.match(/[a-z\u0600-\u06FF]/gi) ?? []).length;
  if (alphaCount < 2) return false;
  if (words.length === 1 && text.length <= 3) {
    const normalized = normalizeText(text);
    if (!SHORT_SINGLE_WORD_ALLOWLIST.has(normalized)) return false;
  }
  if (/^[^a-z0-9\u0600-\u06FF]+$/i.test(text)) return false;
  return true;
}

function detectHint(line: string): string {
  let normalized = normalizeText(line);
  if (!normalized) return "";

  for (const prefix of HEADING_PREFIXES) {
    if (normalized.startsWith(`${prefix} `)) {
      normalized = normalized.slice(prefix.length + 1).trim();
      break;
    }
  }

  for (const [id, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    for (const key of keywords) {
      if (normalized.includes(normalizeText(key))) return id;
    }
  }
  return "";
}

function stableCustomCategoryId(label: string): string {
  const normalized = normalizeText(label).replace(/\s+/g, "_").slice(0, 36);
  if (normalized) return `custom_${normalized}`;
  const digest = crypto.createHash("sha1").update(label).digest("hex").slice(0, 10);
  return `custom_${digest}`;
}

function customLabelForHintKey(hint: string): string {
  const key = asText(hint);
  if (!key) return "\u063a\u064a\u0631 \u0645\u0635\u0646\u0641 (\u0627\u0633\u062a\u064a\u0631\u0627\u062f)";
  return HINT_LABELS_AR[key] ?? key.replace(/_/g, " ");
}

function average(values: number[]): number {
  if (!values.length) return 0;
  return Number((values.reduce((a, b) => a + b, 0) / values.length).toFixed(4));
}

function jobRef(venueId: string, jobId: string): FirebaseFirestore.DocumentReference {
  return firestoreDb().collection("venues").doc(venueId).collection("menu_import_jobs").doc(jobId);
}

function stageRef(venueId: string, jobId: string, stage: StageName): FirebaseFirestore.DocumentReference {
  return jobRef(venueId, jobId).collection("stage_data").doc(stage);
}

function jobTasksRef(venueId: string): FirebaseFirestore.CollectionReference {
  return firestoreDb().collection("venues").doc(venueId).collection("menu_import_tasks");
}

async function ensureMerchantLinkedToVenue(uid: string, venueId: string): Promise<void> {
  const db = firestoreDb();
  const [merchantDoc, userDoc] = await Promise.all([
    db.collection("merchants").doc(uid).get(),
    db.collection("users").doc(uid).get(),
  ]);

  const merchantVenue = asText(merchantDoc.data()?.venue_id);
  const userVenue = asText(userDoc.data()?.merchant_venue_id);
  if (merchantVenue === venueId || userVenue === venueId) return;

  throw new functions.https.HttpsError("permission-denied", "You are not linked to this venue.");
}

async function resolveVersionIdFromVenue(venueId: string): Promise<string> {
  const db = firestoreDb();
  const [venueDoc, configDoc] = await Promise.all([
    db.collection("venues").doc(venueId).get(),
    db.collection("venues").doc(venueId).collection("menu_config").doc("main").get(),
  ]);
  if (!venueDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Venue not found.");
  }
  const draftVersion = asText(configDoc.data()?.draft_version_id);
  if (draftVersion) return draftVersion;
  
  // Phase 0 Hotfix: Prevent falling back to activeVersion. OCR must target an explicit draft.
  throw new functions.https.HttpsError("failed-precondition", "No draft menu version found. OCR import requires an active draft.");
}

async function ensureVersionExists(venueId: string, versionId: string): Promise<void> {
  const snap = await firestoreDb()
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("failed-precondition", "Target menu version does not exist.");
  }
  
  // Phase 0 Hotfix: Ensure the target version is strictly a 'draft'
  const status = asText(snap.data()?.status) || "draft";
  if (status !== "draft") {
    throw new functions.https.HttpsError("failed-precondition", "Target menu version MUST be a draft. Importing directly to active is restricted.");
  }
}

async function readJobCore(venueId: string, jobId: string): Promise<JobCore> {
  const snap = await jobRef(venueId, jobId).get();
  if (!snap.exists) throw new functions.https.HttpsError("not-found", "Import job not found.");
  const data = snap.data() ?? {};
  const status = asText(data.status);
  const versionId = asText(data.version_id);
  if (!status || !versionId) {
    throw new functions.https.HttpsError("failed-precondition", "Import job has invalid shape.");
  }
  return {
    status,
    versionId,
    inputFiles: normalizeInputFiles(data.input_files),
  };
}

async function writeStagePayload(
  venueId: string,
  jobId: string,
  stage: StageName,
  payload: Record<string, unknown>,
): Promise<void> {
  await stageRef(venueId, jobId, stage).set(
    {
      payload,
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function readStagePayload<T>(
  venueId: string,
  jobId: string,
  stage: StageName,
): Promise<T | null> {
  const snap = await stageRef(venueId, jobId, stage).get();
  if (!snap.exists) return null;
  const payload = snap.data()?.payload;
  if (!payload || typeof payload !== "object") return null;
  return payload as T;
}

async function markFailed(
  venueId: string,
  jobId: string,
  actorUid: string,
  errorCode: string,
  message: string,
): Promise<void> {
  await jobRef(venueId, jobId).set(
    {
      status: "failed",
      error_code: errorCode,
      error_message: message.slice(0, 800),
      last_stage_by: actorUid,
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function transition(params: {
  venueId: string;
  jobId: string;
  targetStatus: MenuImportStatus;
  allowedFrom: MenuImportStatus[];
  actorUid: string;
  patch?: Record<string, unknown>;
}): Promise<StageResult> {
  const { venueId, jobId, targetStatus, allowedFrom, actorUid, patch } = params;
  const db = firestoreDb();
  const ref = jobRef(venueId, jobId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new functions.https.HttpsError("not-found", "Import job not found.");

    const current = asText(snap.data()?.status);
    const currentRank = rank(current);
    const targetRank = rank(targetStatus);

    if (current === "failed") {
      throw new functions.https.HttpsError("failed-precondition", "Cannot transition a failed job.");
    }
    if (currentRank < 0 || targetRank < 0) {
      throw new functions.https.HttpsError("failed-precondition", "Unknown import status.");
    }
    if (currentRank >= targetRank) {
      return { jobId, status: current, idempotent: true };
    }
    if (targetRank !== currentRank + 1 || !allowedFrom.includes(current as MenuImportStatus)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Transition from ${current} to ${targetStatus} is not allowed.`,
      );
    }

    tx.set(
      ref,
      {
        status: targetStatus,
        ...(patch ?? {}),
        error_code: null,
        error_message: null,
        updated_at: FieldValue.serverTimestamp(),
        last_stage_by: actorUid,
      },
      { merge: true },
    );
    return { jobId, status: targetStatus, idempotent: false };
  });
}

async function getGoogleAccessToken(): Promise<string> {
  const credential = admin.app().options.credential as {
    getAccessToken?: () => Promise<{ access_token: string }>;
  };
  if (!credential?.getAccessToken) {
    throw new Error("Missing application default credential access token.");
  }
  const token = await credential.getAccessToken();
  const accessToken = asText(token.access_token);
  if (!accessToken) throw new Error("Failed to get access token.");
  return accessToken;
}

function mockOcrLines(uri: string): OcrLine[] {
  const lower = uri.toLowerCase();
  if (lower.includes("template")) {
    return [
      { text: "\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062d\u0644\u0648\u064a\u0627\u062a", confidence: 0.95 },
      { text: "\u062a\u0627\u0631\u062a .......... 100", confidence: 0.92 },
      { text: "\u062a\u0634\u064a\u0632 \u0643\u064a\u0643 .......... 300", confidence: 0.91 },
      { text: "\u062a\u064a\u0631\u0627\u0645\u064a\u0633\u0648 .......... 200", confidence: 0.9 },
      { text: "\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0634\u0631\u0648\u0628\u0627\u062a", confidence: 0.95 },
      { text: "\u0642\u0647\u0648\u0629 \u0633\u0627\u062f\u0629 .......... 10", confidence: 0.92 },
      { text: "\u0642\u0647\u0648\u0629 \u0628\u0627\u0644\u062d\u0644\u064a\u0628 .......... 30", confidence: 0.91 },
      { text: "\u0645\u064a\u0644\u0643 \u0634\u064a\u0643 .......... 50", confidence: 0.9 },
      { text: "\u0641\u0627\u0646\u064a\u0644\u064a\u0627 \u0641\u0631\u0627\u0628\u064a\u0647 .......... 40", confidence: 0.9 },
      { text: "www.reallygreatsite.com", confidence: 0.88 },
      { text: "\u0645\u0648", confidence: 0.86 },
      { text: "\u0639\u0648", confidence: 0.86 },
      { text: "\u062a\u0639\u0648", confidence: 0.86 },
    ];
  }
  if (lower.includes("bukhari") || (lower.includes("food") && !lower.includes("noisyfood"))) {
    return [
      { text: "\u0627\u0644\u0641\u0637\u0648\u0631", confidence: 0.93 },
      { text: "\u0628\u064a\u0636 \u0637\u0645\u0627\u0637\u0645 1.000", confidence: 0.9 },
      { text: "\u0639\u062f\u0633 0.500", confidence: 0.9 },
      { text: "\u0627\u0644\u0645\u0634\u0648\u064a\u0627\u062a", confidence: 0.93 },
      { text: "\u0648\u062c\u0628\u0629 \u0643\u0628\u0627\u0628 1.750", confidence: 0.9 },
      { text: "\u0648\u062c\u0628\u0629 \u0637\u0627\u0648\u0648\u0642 1.750", confidence: 0.9 },
      { text: "\u0627\u0644\u0628\u062e\u0627\u0631\u064a", confidence: 0.94 },
      { text: "\u0628\u062e\u0627\u0631\u064a \u062f\u062c\u0627\u062c 2.000", confidence: 0.9 },
      { text: "\u0645\u062d\u0634\u064a \u0645\u0644\u0641\u0648\u0641 \u0635\u063a\u064a\u0631 0.500", confidence: 0.9 },
      { text: "\u0627\u0644\u0645\u0634\u0631\u0648\u0628\u0627\u062a", confidence: 0.94 },
      { text: "\u0645\u0627\u0621 \u0635\u063a\u064a\u0631 0.100", confidence: 0.89 },
      { text: "\u0634\u0627\u064a 0.100", confidence: 0.89 },
    ];
  }
  if (lower.includes("pricefirst")) {
    return [
      { text: "\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0634\u0631\u0648\u0628\u0627\u062a", confidence: 0.93 },
      { text: "10", confidence: 0.9 },
      { text: "\u0642\u0647\u0648\u0629 \u0633\u0627\u062f\u0629", confidence: 0.9 },
      { text: "30", confidence: 0.9 },
      { text: "\u0642\u0647\u0648\u0629 \u0628\u0627\u0644\u062d\u0644\u064a\u0628", confidence: 0.9 },
    ];
  }
  if (lower.includes("noisyfood")) {
    return [
      { text: "\u0627\u0644\u0645\u0634\u0627\u0648\u064a", confidence: 0.94 },
      { text: "\u0648\u062c\u0628\u0629 \u0643\u0628\u0627\u0628 1.750", confidence: 0.9 },
      { text: "\u0648\u062c\u0628\u0629 \u0634\u064a\u0634 \u0637\u0627\u0648\u0648\u0642 1.750", confidence: 0.9 },
      { text: "\u0634\u0627\u0631\u0639 23 \u0639\u0645\u0627\u0631\u0629 118", confidence: 0.9 },
      { text: "www.reallygreatsite.com", confidence: 0.88 },
      { text: "\u0647\u0627\u062a\u0641 99233085", confidence: 0.86 },
    ];
  }
  if (lower.includes("breakfast")) {
    return [
      { text: "\u0627\u0644\u0641\u0637\u0648\u0631", confidence: 0.93 },
      { text: "\u0641\u0648\u0644 1.000", confidence: 0.9 },
      { text: "\u0639\u062f\u0633 0.500", confidence: 0.9 },
      { text: "\u0628\u064a\u0636 \u0637\u0645\u0627\u0637\u0645 1.000", confidence: 0.9 },
    ];
  }
  if (lower.includes("beveragemapping")) {
    return [
      { text: "\u0645\u0627\u0621 \u0635\u063a\u064a\u0631 0.100", confidence: 0.9 },
      { text: "\u0645\u0634\u0631\u0648\u0628 \u063a\u0627\u0632\u064a 0.150", confidence: 0.9 },
      { text: "\u0644\u0628\u0646/\u0631\u0648\u0628 0.150", confidence: 0.88 },
      { text: "\u0634\u0627\u064a 0.100", confidence: 0.89 },
    ];
  }
  if (lower.includes("cafe")) {
    return [
      { text: "\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0634\u0631\u0648\u0628\u0627\u062a", confidence: 0.95 },
      { text: "\u0642\u0647\u0648\u0629 \u062a\u0631\u0643\u064a 12", confidence: 0.92 },
      { text: "\u0643\u0627\u0628\u062a\u0634\u064a\u0646\u0648 16", confidence: 0.9 },
      { text: "\u062d\u0644\u0648\u064a\u0627\u062a", confidence: 0.94 },
      { text: "\u062a\u0634\u064a\u0632 \u0643\u064a\u0643 24", confidence: 0.91 },
      { text: "\u0628\u0631\u0627\u0648\u0646\u064a", confidence: 0.9 },
      { text: "22", confidence: 0.85 },
    ];
  }
  return [
    { text: "\u0645\u0642\u0628\u0644\u0627\u062a", confidence: 0.94 },
    { text: "\u062d\u0645\u0635 18", confidence: 0.91 },
    { text: "\u0623\u0637\u0628\u0627\u0642 \u0631\u0626\u064a\u0633\u064a\u0629", confidence: 0.94 },
    { text: "\u0634\u0627\u0648\u0631\u0645\u0627 \u062f\u062c\u0627\u062c 35", confidence: 0.9 },
    { text: "\u0644\u062d\u0645 \u0643\u0646\u0641 \u062e\u0627\u0631\u0648\u0641 90", confidence: 0.86 },
  ];
}

async function runVisionOcrBatch(gsUris: string[]): Promise<OcrLine[]> {
  const validUris = gsUris.filter((uri) => uri.startsWith("gs://"));
  if (validUris.length === 0) {
    throw new Error("OCR requires valid gs:// file URIs.");
  }

  const token = await getGoogleAccessToken();

  // Vision API limit is 16 images per request.
  const chunkedUris: string[][] = [];
  for (let i = 0; i < validUris.length; i += 16) {
    chunkedUris.push(validUris.slice(i, i + 16));
  }

  const chunkResults = await Promise.all(chunkedUris.map(async (chunk) => {
    const requests = chunk.map((uri) => ({
      image: { source: { imageUri: uri } },
      features: [{ type: "DOCUMENT_TEXT_DETECTION" }],
      imageContext: { languageHints: ["ar", "en"] },
    }));

    const response = await fetch("https://vision.googleapis.com/v1/images:annotate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ requests }),
    });

    if (!response.ok) {
      throw new Error(`Vision API failed (${response.status}): ${(await response.text()).slice(0, 600)}`);
    }

    const payload = await response.json() as {
      responses?: Array<{
        error?: { message?: string };
        fullTextAnnotation?: { text?: string; pages?: Array<{ confidence?: number }> };
      }>;
    };

    if (!payload.responses) return [] as OcrLine[];
    const linesFromChunk: OcrLine[] = [];

    for (const res of payload.responses) {
      if (res.error?.message) {
        console.warn(`Vision API partial error: ${res.error.message}`);
        continue;
      }
      const text = asText(res.fullTextAnnotation?.text);
      if (!text) continue;

      const confidence = average((res.fullTextAnnotation?.pages ?? [])
        .map((page) => page.confidence)
        .filter((value): value is number => typeof value === "number"));

      const lines = text
        .split(/\r?\n/)
        .map((line) => asText(line))
        .filter((line) => line.length > 0)
        .map((line) => ({ text: line, confidence: confidence || 0.72 }));

      linesFromChunk.push(...lines);
    }

    return linesFromChunk;
  }));

  const allLines: OcrLine[] = [];
  for (const chunkLines of chunkResults) {
    allLines.push(...chunkLines);
  }
  return allLines;
}

async function buildOcrPayload(inputFiles: string[]): Promise<OcrPayload> {
  const normalizedFiles = inputFiles.map((file) => asText(file)).filter((file) => file.length > 0);
  if (!normalizedFiles.length) throw new Error("Import job has no input files.");

  const source = process.env.FIRESTORE_EMULATOR_HOST ? "mock_emulator" : "vision_api";

  let lines: OcrLine[] = [];
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    const lineBuckets = await Promise.all(normalizedFiles.map((file) => mockOcrLines(file)));
    lines = lineBuckets.flat();
  } else {
    lines = await runVisionOcrBatch(normalizedFiles);
  }

  const dynamicMaxLines = Math.max(
    MAX_OCR_LINES_BASE,
    normalizedFiles.length * MAX_OCR_LINES_PER_FILE,
  );
  const truncated = lines.length > dynamicMaxLines;
  const cleaned = lines
    .map((line) => ({
      text: asText(line.text),
      confidence: Number(Math.max(0, Math.min(1, line.confidence)).toFixed(4)),
    }))
    .filter((line) => line.text.length > 0)
    .slice(0, dynamicMaxLines);

  if (!cleaned.length) throw new Error("OCR returned no usable text lines.");

  return {
    source,
    input_file: normalizedFiles[0], // Primary file reference
    input_files: normalizedFiles,
    lines: cleaned,
    line_count: cleaned.length,
    average_confidence: average(cleaned.map((line) => line.confidence)),
    max_lines: dynamicMaxLines,
    truncated,
    generated_at: new Date().toISOString(),
  };
}

function buildExtractedPayload(ocr: OcrPayload): ExtractedPayload {
  const candidates: ExtractedCandidate[] = [];
  const dedupeByName = new Map<string, number>();
  const pendingNames: Array<{ text: string; confidence: number; hint: string | null }> = [];
  const pendingPrices: Array<{ price: number; confidence: number; hint: string | null }> = [];

  let skipped = 0;
  let currentHint: string | null = null;

  const shiftPendingPrice = (hint: string | null): {
    price: number;
    confidence: number;
    hint: string | null;
  } | undefined => {
    if (!pendingPrices.length) return undefined;
    const normalizedHint = normalizeText(asText(hint));
    if (normalizedHint) {
      const idx = pendingPrices.findIndex((pending) => {
        const pendingHint = normalizeText(asText(pending.hint));
        if (!pendingHint) return false;
        return pendingHint === normalizedHint ||
          pendingHint.includes(normalizedHint) ||
          normalizedHint.includes(pendingHint);
      });
      if (idx >= 0) {
        const [matched] = pendingPrices.splice(idx, 1);
        return matched;
      }
    }
    return pendingPrices.shift();
  };

  const pushCandidate = (candidate: ExtractedCandidate): void => {
    const name = asText(candidate.name_ar);
    if (!isPotentialItemText(name)) return;
    if (isCategoryLabelText(name)) return;
    if (isLikelyNonMenuNoise(name)) return;
    const words = name.split(/\s+/).filter(Boolean);
    if (words.length === 1 && name.length <= 3) {
      const normalized = normalizeText(name);
      const trustedShortWord = SHORT_SINGLE_WORD_ALLOWLIST.has(normalized);
      const confidenceFloor = candidate.price === null ? 0.9 : 0.85;
      if (!trustedShortWord && candidate.confidence < confidenceFloor) {
        return;
      }
    }
    if (candidate.price === null) {
      // Allow short single-word items IF they have a category hint (means they appeared
      // under a recognized section heading) or are in the trusted allowlist
      const hasCategoryHint = Boolean(candidate.category_hint);
      const normalized = normalizeText(name);
      const isTrusted = SHORT_SINGLE_WORD_ALLOWLIST.has(normalized);
      if (!hasCategoryHint && !isTrusted) {
        if (name.length < 4 || words.length < 2) return;
      }
    }

    const normalizedName = normalizeText(name);
    if (!normalizedName) return;

    const normalizedCandidate: ExtractedCandidate = {
      ...candidate,
      name_ar: name,
      price: candidate.price === null ? null : Number(candidate.price.toFixed(2)),
    };

    const score = (item: ExtractedCandidate): number => {
      const priceScore = item.price === null ? 0 : 100;
      const marketScore = item.market_price_flag ? 0 : 20;
      const confidenceScore = Math.round(Math.max(0, Math.min(1, item.confidence)) * 100);
      return priceScore + marketScore + confidenceScore;
    };

    const existingIndex = dedupeByName.get(normalizedName);
    if (existingIndex === undefined) {
      dedupeByName.set(normalizedName, candidates.length);
      candidates.push(normalizedCandidate);
      return;
    }

    const existing = candidates[existingIndex];
    if (!existing) return;
    if (score(normalizedCandidate) > score(existing)) {
      candidates[existingIndex] = normalizedCandidate;
      return;
    }

    if (!existing.category_hint && normalizedCandidate.category_hint) {
      existing.category_hint = normalizedCandidate.category_hint;
    }
  };

  for (const line of ocr.lines) {
    const rawLine = asText(line.text);
    if (!rawLine) {
      skipped += 1;
      continue;
    }

    const explicitHintForLine = detectHint(rawLine);
    const headingForLine = isLikelySectionHeading(rawLine, explicitHintForLine);
    if (headingForLine) {
      currentHint =
        explicitHintForLine || `label:${rawLine.replace(/[:\uFF1A]+$/, "").trim()}`;
      pendingNames.length = 0;
      pendingPrices.length = 0;
      continue;
    }

    // If line has no digits at all, could be a standalone name on its own line
    // (common in Arabic menus where name and price are on separate lines)
    const lineHasDigits = /[0-9\u0660-\u0669\u06F0-\u06F9]/.test(rawLine);

    const leaderPairs = lineHasDigits ? parseLeaderSeparatedPairs(rawLine) : [];
    if (leaderPairs.length > 0) {
      const hint = explicitHintForLine || currentHint;
      for (const pair of leaderPairs) {
        pushCandidate({
          raw_line: rawLine,
          name_ar: pair.name,
          price: pair.price,
          currency: DEFAULT_CURRENCY,
          market_price_flag: false,
          confidence: Number(Math.max(0.2, line.confidence * 0.9).toFixed(4)),
          category_hint: hint,
        });
      }
      continue;
    }

    const segments = splitLineIntoPriceSegments(rawLine);
    for (const segment of segments) {
      const raw = asText(segment);
      if (!raw) {
        skipped += 1;
        continue;
      }

      const explicitHint = detectHint(raw);
      if (isLikelySectionHeading(raw, explicitHint)) {
        currentHint =
          explicitHint || `label:${raw.replace(/[:\uFF1A]+$/, "").trim()}`;
        pendingNames.length = 0;
        pendingPrices.length = 0;
        continue;
      }

      const priceOnly = parsePriceOnlyLine(raw);
      if (priceOnly !== null) {
        if (pendingNames.length > 0) {
          const pending = pendingNames.shift();
          if (pending) {
            pushCandidate({
              raw_line: `${pending.text} ${priceOnly}`,
              name_ar: pending.text,
              price: priceOnly,
              currency: DEFAULT_CURRENCY,
              market_price_flag: false,
              confidence: Number(Math.max(0.2, pending.confidence * 0.9).toFixed(4)),
              category_hint: pending.hint,
            });
          }
        } else {
          pendingPrices.push({
            price: priceOnly,
            confidence: line.confidence,
            hint: explicitHint || currentHint,
          });
          if (pendingPrices.length > 5) pendingPrices.shift();
        }
        continue;
      }

      if (isLikelyNonMenuNoise(raw)) {
        skipped += 1;
        continue;
      }

      const marketPrice = /(market\s*price|ask\s*staff|\u0633\u0639\u0631\s*\u0627\u0644\u0633\u0648\u0642|\u062d\u0633\u0628\s*\u0627\u0644\u0633\u0639\u0631)/i
        .test(normalizeDigits(raw));
      const inlinePrice = parseInlinePrice(raw);
      const textForName =
        explicitHint && /[:\uFF1A]/.test(raw)
          ? raw.split(/[:\uFF1A]/).slice(1).join(" ")
          : raw;
      const cleanName = stripPriceArtifacts(textForName || raw);
      const hint = explicitHint || currentHint;

      if (inlinePrice || marketPrice) {
        if (!isPotentialItemText(cleanName)) {
          skipped += 1;
          continue;
        }
        const parseConfidence = inlinePrice ? 0.95 : 0.65;
        pushCandidate({
          raw_line: raw,
          name_ar: cleanName,
          price: inlinePrice ? inlinePrice.price : null,
          currency: DEFAULT_CURRENCY,
          market_price_flag: !inlinePrice || marketPrice,
          confidence: Number(Math.max(0.15, line.confidence * parseConfidence).toFixed(4)),
          category_hint: hint,
        });
        continue;
      }

      if (isPotentialItemText(cleanName)) {
        if (pendingPrices.length > 0) {
          const pendingPrice = shiftPendingPrice(hint);
          if (pendingPrice) {
            pushCandidate({
              raw_line: `${cleanName} ${pendingPrice.price}`,
              name_ar: cleanName,
              price: pendingPrice.price,
              currency: DEFAULT_CURRENCY,
              market_price_flag: false,
              confidence: Number(Math.max(
                0.2,
                ((line.confidence + pendingPrice.confidence) / 2) * 0.88,
              ).toFixed(4)),
              category_hint: hint || pendingPrice.hint,
            });
          }
        } else {
          const pending = { text: cleanName, confidence: line.confidence, hint };
          pendingNames.push(pending);
          if (pendingNames.length > 10) pendingNames.shift();
        }
      } else {
        skipped += 1;
      }
    }
  }

  // Limit pending names to avoid flushing too many priceless items
  const maxPendingFlush = Math.min(pendingNames.length, 15);
  for (let i = 0; i < maxPendingFlush; i += 1) {
    const fallback = pendingNames[i];
    const fallbackWords = fallback.text.split(/\s+/).filter(Boolean);
    const normalizedFallback = normalizeText(fallback.text);
    const singleWordDrinkFallback =
      fallbackWords.length === 1 &&
      fallback.text.length >= 3 &&
      (
        SHORT_SINGLE_WORD_ALLOWLIST.has(normalizedFallback) ||
        hintIndicatesDrinks(fallback.hint)
      );
    if (!singleWordDrinkFallback && (fallback.text.length < 4 || fallbackWords.length < 2)) {
      continue;
    }
    if (isLikelyNonMenuNoise(fallback.text)) {
      continue;
    }
    pushCandidate({
      raw_line: fallback.text,
      name_ar: fallback.text,
      price: null,
      currency: DEFAULT_CURRENCY,
      market_price_flag: true,
      confidence: Number(Math.max(0.12, fallback.confidence * 0.6).toFixed(4)),
      category_hint: fallback.hint,
    });
  }

  return {
    source: ocr.source,
    candidates: candidates.slice(0, 350),
    skipped_lines: skipped,
    generated_at: new Date().toISOString(),
  };
}

function evaluateExtractionQuality(ocr: OcrPayload, extracted: ExtractedPayload): {
  priceSignals: number;
  coverage: number;
  quality: "good" | "low";
  reason: string;
} {
  let priceSignals = 0;
  for (const line of ocr.lines) {
    const raw = asText(line.text);
    if (!raw) continue;
    if (parsePriceOnlyLine(raw) !== null || parseInlinePrice(raw) !== null) {
      priceSignals += 1;
      continue;
    }
    if (parseLeaderSeparatedPairs(raw).length > 0) {
      priceSignals += 1;
    }
  }

  const coverage = priceSignals > 0
    ? Number((extracted.candidates.length / priceSignals).toFixed(4))
    : 1;

  let quality: "good" | "low" = "good";
  let reason = "ok";
  if (priceSignals >= 8 && coverage < 0.45) {
    quality = "low";
    reason = "low_price_signal_coverage";
  } else if (ocr.truncated && coverage < 0.6) {
    quality = "low";
    reason = "truncated_input_low_coverage";
  }

  return { priceSignals, coverage, quality, reason };
}

function toCategoryState(id: string, data: FirebaseFirestore.DocumentData): CategoryState {
  const key = asText(data.key) || id;
  const nameAr = asText(data.name_ar) || key;
  const nameEn = asText(data.name_en) || nameAr;
  const sortOrder = Math.trunc(asNum(data.sort_order) ?? 0);

  const tokenSet = new Set<string>();
  const push = (token: string): void => {
    const normalized = normalizeText(token);
    if (normalized.length >= 2) tokenSet.add(normalized);
  };
  push(id);
  push(key);
  push(nameAr);
  push(nameEn);
  for (const keyword of CATEGORY_KEYWORDS[key] ?? []) {
    push(keyword);
  }

  return {
    id,
    key,
    nameAr,
    nameEn,
    sortOrder,
    matchTokens: [...tokenSet],
  };
}

function findCategoryByText(text: string, categories: CategoryState[]): CategoryState | null {
  const normalized = normalizeText(text);
  if (!normalized) return null;

  let best: CategoryState | null = null;
  let bestScore = 0;
  for (const category of categories) {
    for (const token of category.matchTokens) {
      if (token && normalized.includes(token) && token.length > bestScore) {
        best = category;
        bestScore = token.length;
      }
    }
  }
  return best;
}

function findCategoryByKey(
  categories: CategoryState[],
  keyCandidates: string[],
): CategoryState | null {
  for (const key of keyCandidates) {
    const match = categories.find((category) => category.id === key || category.key === key);
    if (match) return match;
  }
  return null;
}

function pickFirstAvailableByKey(
  categories: CategoryState[],
  keyCandidates: string[],
): CategoryState | null {
  const direct = findCategoryByKey(categories, keyCandidates);
  if (direct) return direct;
  return null;
}

function pickDefaultExistingCategory(categories: CategoryState[]): CategoryState | null {
  if (!categories.length) return null;
  return [...categories].sort((a, b) => a.sortOrder - b.sortOrder)[0];
}

function pickBestExistingFallbackCategory(
  categories: CategoryState[],
  hintOrLabel: string,
): CategoryState | null {
  const normalized = normalizeText(hintOrLabel);
  if (!normalized) return pickDefaultExistingCategory(categories);

  const drinkHint = [
    "drink",
    "hot drink",
    "cold drink",
    "juice",
    "smoothie",
    "cocktail",
    "milkshake",
    "مشروب",
    "مشروبات",
    "عصير",
    "عصائر",
    "سموذي",
    "كوكتيل",
    "ميلك شيك",
    "قهوة",
    "شاي",
  ].some((k) => normalized.includes(normalizeText(k)));
  if (drinkHint) {
    const drinkCategory = pickFirstAvailableByKey(categories, [
      "drinks",
      "hot_drinks",
      "cold_drinks",
      "juices",
      "fresh_juices",
      "smoothies",
      "cocktails",
      "milkshakes",
    ]);
    if (drinkCategory) return drinkCategory;
  }

  const dessertHint = [
    "dessert",
    "sweet",
    "cake",
    "حلويات",
    "حلى",
    "تشيز",
    "كيك",
  ].some((k) => normalized.includes(normalizeText(k)));
  if (dessertHint) {
    const dessertCategory = pickFirstAvailableByKey(categories, [
      "desserts",
      "sweets",
      "eastern_sweets",
      "western_sweets",
      "ice_cream",
    ]);
    if (dessertCategory) return dessertCategory;
  }

  const foodHint = [
    "main",
    "food",
    "breakfast",
    "brunch",
    "grill",
    "shawarma",
    "burger",
    "pizza",
    "sandwich",
    "soup",
    "فطور",
    "افطار",
    "طبق",
    "اطباق",
    "مشاوي",
    "شاورما",
    "برغر",
    "بيتزا",
    "ساندويش",
    "شوربة",
  ].some((k) => normalized.includes(normalizeText(k)));
  if (foodHint) {
    const foodCategory = pickFirstAvailableByKey(categories, [
      "main_courses",
      "grills",
      "shawarma",
      "burgers",
      "pizza",
      "sandwiches",
      "soups",
      "appetizers",
      "sides",
      "food",
    ]);
    if (foodCategory) return foodCategory;
  }

  return pickDefaultExistingCategory(categories);
}

async function ensureCustomCategory(
  venueId: string,
  versionId: string,
  label: string,
  categories: CategoryState[],
  sortState: { value: number },
): Promise<{ id: string; created: boolean }> {
  const name = asText(label).slice(0, 60);
  if (!name) {
    const fallback0 = pickDefaultExistingCategory(categories);
    return { id: fallback0 ? fallback0.id : categories[0]?.id ?? "other", created: false };
  }
  // Guard: never create a custom category from noise text
  if (isLikelyImportErrorNoise(name) || isLikelyNonMenuNoise(name) || isLikelyCorruptedText(name)) {
    const fallback = pickDefaultExistingCategory(categories);
    if (fallback) {
      return { id: fallback.id, created: false };
    }
    // If no fallback exists at all, still don't create from noise
    return { id: categories[0]?.id ?? "other", created: false };
  }
  const id = stableCustomCategoryId(name);
  if (categories.some((category) => category.id === id)) {
    return { id, created: false };
  }

  sortState.value += 1;
  const data = {
    key: id,
    name_ar: name,
    name_en: name,
    sort_order: sortState.value,
    is_custom: true,
    source: "import",
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  };

  await firestoreDb()
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("categories")
    .doc(id)
    .set(data, { merge: true });

  categories.push(toCategoryState(id, data));
  return { id, created: true };
}

async function resolveCategory(params: {
  venueId: string;
  versionId: string;
  candidate: ExtractedCandidate;
  categories: CategoryState[];
  sortState: { value: number };
}): Promise<{ categoryId: string; usedFallback: boolean; created: boolean }> {
  const { venueId, versionId, candidate, categories, sortState } = params;
  const hint = asOptionalText(candidate.category_hint);

  if (hint) {
    if (hint.startsWith("label:")) {
      const labelText = hint.replace("label:", "").trim();
      if (isLikelyImportErrorNoise(labelText) || isLikelyNonMenuNoise(labelText)) {
        const byNameFromNoisyLabel = findCategoryByText(candidate.name_ar, categories);
        if (byNameFromNoisyLabel) {
          return { categoryId: byNameFromNoisyLabel.id, usedFallback: true, created: false };
        }
        const fallbackFromNoisyLabel = pickBestExistingFallbackCategory(categories, candidate.name_ar);
        if (fallbackFromNoisyLabel) {
          return { categoryId: fallbackFromNoisyLabel.id, usedFallback: true, created: false };
        }
        const defaultCategory = pickDefaultExistingCategory(categories);
        if (defaultCategory) {
          return { categoryId: defaultCategory.id, usedFallback: true, created: false };
        }
      }

      const hintedCategory = detectHint(labelText);
      if (hintedCategory) {
        const directFromHint = categories.find(
          (category) => category.id === hintedCategory || category.key === hintedCategory,
        );
        if (directFromHint) {
          return { categoryId: directFromHint.id, usedFallback: true, created: false };
        }

        const fallbackFromHint = findCategoryByKey(
          categories,
          HINT_FALLBACK_CATEGORY_KEYS[hintedCategory] ?? [],
        );
        if (fallbackFromHint) {
          return { categoryId: fallbackFromHint.id, usedFallback: true, created: false };
        }
      }

      const byLabel = findCategoryByText(labelText, categories);
      if (byLabel) {
        return { categoryId: byLabel.id, usedFallback: true, created: false };
      }

      // Before creating custom category from OCR label, check if it looks valid
      const bestExistingForLabel = pickBestExistingFallbackCategory(categories, labelText);
      if (bestExistingForLabel) {
        return { categoryId: bestExistingForLabel.id, usedFallback: true, created: false };
      }

      const ensuredFromLabel = await ensureCustomCategory(
        venueId,
        versionId,
        labelText,
        categories,
        sortState,
      );
      return {
        categoryId: ensuredFromLabel.id,
        usedFallback: true,
        created: ensuredFromLabel.created,
      };
    }

    const direct = categories.find((category) => category.id === hint || category.key === hint);
    if (direct) {
      return { categoryId: direct.id, usedFallback: false, created: false };
    }

    const fallbackKeys = HINT_FALLBACK_CATEGORY_KEYS[hint] ?? [];
    const fallbackByKey = findCategoryByKey(categories, fallbackKeys);
    if (fallbackByKey) {
      return { categoryId: fallbackByKey.id, usedFallback: true, created: false };
    }

    const byHintText = findCategoryByText(hint, categories);
    if (byHintText) {
      return { categoryId: byHintText.id, usedFallback: true, created: false };
    }

    if (Object.prototype.hasOwnProperty.call(CATEGORY_KEYWORDS, hint)) {
      const ensuredFromKnownHint = await ensureCustomCategory(
        venueId,
        versionId,
        customLabelForHintKey(hint),
        categories,
        sortState,
      );
      return {
        categoryId: ensuredFromKnownHint.id,
        usedFallback: true,
        created: ensuredFromKnownHint.created,
      };
    }

    const bestExisting = pickBestExistingFallbackCategory(categories, hint);
    if (bestExisting) {
      return { categoryId: bestExisting.id, usedFallback: true, created: false };
    }

    const ensured = await ensureCustomCategory(
      venueId,
      versionId,
      hint,
      categories,
      sortState,
    );
    return { categoryId: ensured.id, usedFallback: true, created: ensured.created };
  }

  const byName = findCategoryByText(candidate.name_ar, categories);
  if (byName) {
    return { categoryId: byName.id, usedFallback: false, created: false };
  }

  const bySmartFallback = pickBestExistingFallbackCategory(categories, candidate.name_ar);
  if (bySmartFallback) {
    return { categoryId: bySmartFallback.id, usedFallback: true, created: false };
  }

  const uncategorized = await ensureCustomCategory(
    venueId,
    versionId,
    "\u063a\u064a\u0631 \u0645\u0635\u0646\u0641 (\u0627\u0633\u062a\u064a\u0631\u0627\u062f)",
    categories,
    sortState,
  );
  return { categoryId: uncategorized.id, usedFallback: true, created: uncategorized.created };
}

async function countQuery(query: FirebaseFirestore.Query): Promise<number> {
  try {
    const aggregate = await query.count().get();
    return aggregate.data().count;
  } catch {
    return (await query.get()).size;
  }
}

async function deleteImportedItemsSnapshot(
  itemsRef: FirebaseFirestore.CollectionReference,
): Promise<void> {
  const [legacyImported, ocrImported] = await Promise.all([
    itemsRef.where("source", "==", "import").get(),
    itemsRef.where("source", "==", "ocr").get(),
  ]);
  if (legacyImported.empty && ocrImported.empty) return;

  const existingDocs = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();
  for (const doc of legacyImported.docs) {
    existingDocs.set(doc.ref.path, doc);
  }
  for (const doc of ocrImported.docs) {
    existingDocs.set(doc.ref.path, doc);
  }
  if (!existingDocs.size) return;

  const db = firestoreDb();
  let batch = db.batch();
  let count = 0;
  for (const doc of existingDocs.values()) {
    batch.delete(doc.ref);
    count += 1;
    if (count >= 400) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) {
    await batch.commit();
  }
}

async function applyMapping(params: {
  venueId: string;
  versionId: string;
  jobId: string;
  extracted: ExtractedPayload;
}): Promise<{ importedCount: number; categoriesAdded: number; needsReviewCount: number }> {
  const { venueId, versionId, jobId, extracted } = params;
  const db = firestoreDb();
  const versionRef = db.collection("venues").doc(venueId).collection("menu_versions").doc(versionId);
  const categoriesRef = versionRef.collection("categories");
  const itemsRef = versionRef.collection("items");

  const categorySnap = await categoriesRef.get();
  const categories: CategoryState[] = [];
  const noisyCategoryRefs: FirebaseFirestore.DocumentReference[] = [];
  let maxCategorySort = 0;

  for (const doc of categorySnap.docs) {
    const data = doc.data();
    const source = asText(data.source);
    const isCustom = data.is_custom === true || doc.id.startsWith("custom_");
    const label = asText(data.name_ar) || asText(data.key) || doc.id;
    const noisy = isLikelyImportErrorNoise(label) || isLikelyNonMenuNoise(label);

    if (noisy && (source === "import" || isCustom)) {
      noisyCategoryRefs.push(doc.ref);
      continue;
    }

    const category = toCategoryState(doc.id, data);
    categories.push(category);
    maxCategorySort = Math.max(maxCategorySort, category.sortOrder);
  }

  if (noisyCategoryRefs.length > 0) {
    let cleanupBatch = db.batch();
    let cleanupCount = 0;
    for (const ref of noisyCategoryRefs) {
      cleanupBatch.delete(ref);
      cleanupCount += 1;
      if (cleanupCount >= 400) {
        await cleanupBatch.commit();
        cleanupBatch = db.batch();
        cleanupCount = 0;
      }
    }
    if (cleanupCount > 0) {
      await cleanupBatch.commit();
    }
  }

  if (!categories.length) {
    const ensured = await ensureCustomCategory(
      venueId,
      versionId,
      "\u0623\u0635\u0646\u0627\u0641 \u0645\u0633\u062a\u0648\u0631\u062f\u0629",
      categories,
      { value: maxCategorySort },
    );
    if (ensured.created) maxCategorySort += 1;
  }

  await deleteImportedItemsSnapshot(itemsRef);

  const latestSortSnap = await itemsRef.orderBy("sort_order", "desc").limit(1).get();
  let sortCursor = 0;
  if (!latestSortSnap.empty) {
    sortCursor = Math.trunc(asNum(latestSortSnap.docs[0].data().sort_order) ?? 0);
  }

  const sortState = { value: maxCategorySort };
  let importedCount = 0;
  let categoriesAdded = 0;
  let needsReviewCount = 0;

  // Batching setup
  let batch = db.batch();
  let opCount = 0;

  for (let index = 0; index < extracted.candidates.length; index += 1) {
    const candidate = extracted.candidates[index];
    const name = asText(candidate.name_ar);
    if (name.length < 2) continue;

    const hasArabicLetters = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/.test(name);
    const hasEnglishLetters = /[a-zA-Z]/.test(name);
    if (!hasArabicLetters && !hasEnglishLetters) {
      continue; // Drop pure noise / numbers without letters
    }

    const resolved = await resolveCategory({
      venueId,
      versionId,
      candidate,
      categories,
      sortState,
    });
    if (resolved.created) categoriesAdded += 1;

    sortCursor += 1;
    const confidence = Number(Math.max(0.05, Math.min(1, candidate.confidence)).toFixed(4));
    const needsReview = Boolean(
      candidate.market_price_flag ||
      candidate.price === null ||
      confidence < 0.75 ||
      resolved.usedFallback,
    );
    if (needsReview) needsReviewCount += 1;

    const itemId = `imp_${jobId}_${String(index + 1).padStart(4, "0")}`;
    const itemRef = itemsRef.doc(itemId);
    const itemData = {
      category: resolved.categoryId,
      category_id: resolved.categoryId,
      name_ar: name,
      name_en: "",
      description_ar: "",
      description_en: "",
      price: candidate.price === null ? 0 : Number(candidate.price.toFixed(2)),
      currency: asText(candidate.currency) || DEFAULT_CURRENCY,
      market_price_flag: Boolean(candidate.market_price_flag || candidate.price === null),
      source: "ocr",
      is_available: true,
      is_featured: false,
      sort_order: sortCursor,
      tags: [],
      confidence_score: confidence,
      needs_review: needsReview,
      import_job_id: jobId,
      raw_line: asText(candidate.raw_line),
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    };

    batch.set(itemRef, itemData, { merge: true });
    opCount += 1;
    importedCount += 1;

    if (opCount >= 400) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }

  const [itemCount, categoryCount] = await Promise.all([
    countQuery(itemsRef),
    countQuery(categoriesRef),
  ]);
  await versionRef.set(
    {
      item_count: itemCount,
      category_count: categoryCount,
      last_counted_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { importedCount, categoriesAdded, needsReviewCount };
}

async function execRunOcr(params: {
  venueId: string;
  jobId: string;
  actorUid: string;
  ocrOutputRef: string;
}): Promise<StageResult> {
  const { venueId, jobId, actorUid, ocrOutputRef } = params;
  const job = await readJobCore(venueId, jobId);

  if (rank(job.status) >= rank("ocr_done")) {
    return { jobId, status: job.status, idempotent: true };
  }
  if (job.status !== "uploaded") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Transition from ${job.status} to ocr_done is not allowed.`,
    );
  }
  if (!job.inputFiles.length) {
    throw new functions.https.HttpsError("failed-precondition", "Import job has no input files.");
  }

  try {
    logMenuImportStage("info", "Stage start: ocr", { venueId, jobId });
    const payload = await buildOcrPayload(job.inputFiles);
    await writeStagePayload(venueId, jobId, "ocr", payload);
    logMenuImportStage("info", "Stage complete: ocr", {
      venueId,
      jobId,
      lineCount: payload.line_count,
      averageConfidence: payload.average_confidence,
      truncated: payload.truncated,
    });

    return transition({
      venueId,
      jobId,
      targetStatus: "ocr_done",
      allowedFrom: ["uploaded"],
      actorUid,
      patch: {
        ocr_output_ref: ocrOutputRef || stageDefaultRef(venueId, jobId, "ocr"),
        ocr_line_count: payload.line_count,
        ocr_average_confidence: payload.average_confidence,
        ocr_max_lines: payload.max_lines,
        ocr_truncated: payload.truncated,
      },
    });
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    const message = errText(error);
    logMenuImportStage("error", "Stage failed: ocr", { venueId, jobId, error: message });
    await markFailed(venueId, jobId, actorUid, "ocr_failed", message);
    throw new functions.https.HttpsError("internal", `Menu OCR failed: ${message}`);
  }
}

async function execExtract(params: {
  venueId: string;
  jobId: string;
  actorUid: string;
  extractedOutputRef: string;
}): Promise<StageResult> {
  const { venueId, jobId, actorUid, extractedOutputRef } = params;
  const job = await readJobCore(venueId, jobId);

  if (rank(job.status) >= rank("extracted")) {
    return { jobId, status: job.status, idempotent: true };
  }
  if (job.status !== "ocr_done") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Transition from ${job.status} to extracted is not allowed.`,
    );
  }

  try {
    logMenuImportStage("info", "Stage start: extract", { venueId, jobId });
    const ocrPayload = await readStagePayload<OcrPayload>(venueId, jobId, "ocr");
    if (!ocrPayload || !Array.isArray(ocrPayload.lines) || !ocrPayload.lines.length) {
      throw new Error("Missing OCR payload for extraction stage.");
    }
    const extracted = buildExtractedPayload(ocrPayload);
    const extractionQuality = evaluateExtractionQuality(ocrPayload, extracted);
    if (!extracted.candidates.length) {
      throw new Error("OCR extraction produced no candidates.");
    }
    if (extractionQuality.quality === "low") {
      logMenuImportStage("warn", "Low extraction coverage detected", {
        venueId,
        jobId,
        priceSignals: extractionQuality.priceSignals,
        coverage: extractionQuality.coverage,
        reason: extractionQuality.reason,
      });
    }
    await writeStagePayload(venueId, jobId, "extracted", extracted);
    logMenuImportStage("info", "Stage complete: extract", {
      venueId,
      jobId,
      candidates: extracted.candidates.length,
      skippedLines: extracted.skipped_lines,
      priceSignals: extractionQuality.priceSignals,
      coverage: extractionQuality.coverage,
      quality: extractionQuality.quality,
      qualityReason: extractionQuality.reason,
    });

    return transition({
      venueId,
      jobId,
      targetStatus: "extracted",
      allowedFrom: ["ocr_done"],
      actorUid,
      patch: {
        extracted_output_ref: extractedOutputRef || stageDefaultRef(venueId, jobId, "extracted"),
        extracted_candidate_count: extracted.candidates.length,
        extracted_skipped_lines: extracted.skipped_lines,
        extracted_price_signals: extractionQuality.priceSignals,
        extracted_coverage: extractionQuality.coverage,
        extracted_quality: extractionQuality.quality,
        extracted_quality_reason: extractionQuality.reason,
      },
    });
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    const message = errText(error);
    logMenuImportStage("error", "Stage failed: extract", { venueId, jobId, error: message });
    await markFailed(venueId, jobId, actorUid, "extract_failed", message);
    throw new functions.https.HttpsError("internal", `Menu extraction failed: ${message}`);
  }
}

async function execMap(params: {
  venueId: string;
  jobId: string;
  actorUid: string;
  mappedOutputRef: string;
}): Promise<StageResult> {
  const { venueId, jobId, actorUid, mappedOutputRef } = params;
  const job = await readJobCore(venueId, jobId);

  if (rank(job.status) >= rank("mapped")) {
    return { jobId, status: job.status, idempotent: true };
  }
  if (job.status !== "extracted") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Transition from ${job.status} to mapped is not allowed.`,
    );
  }

  try {
    logMenuImportStage("info", "Stage start: map", { venueId, jobId, versionId: job.versionId });
    const extracted = await readStagePayload<ExtractedPayload>(venueId, jobId, "extracted");
    if (!extracted || !Array.isArray(extracted.candidates) || !extracted.candidates.length) {
      throw new Error("Missing extracted payload for mapping stage.");
    }
    const mapResult = await applyMapping({
      venueId,
      versionId: job.versionId,
      jobId,
      extracted,
    });

    await writeStagePayload(venueId, jobId, "mapped", {
      imported_count: mapResult.importedCount,
      categories_added: mapResult.categoriesAdded,
      needs_review_count: mapResult.needsReviewCount,
      generated_at: new Date().toISOString(),
    });
    logMenuImportStage("info", "Stage complete: map", {
      venueId,
      jobId,
      importedCount: mapResult.importedCount,
      categoriesAdded: mapResult.categoriesAdded,
      needsReviewCount: mapResult.needsReviewCount,
    });

    return transition({
      venueId,
      jobId,
      targetStatus: "mapped",
      allowedFrom: ["extracted"],
      actorUid,
      patch: {
        mapped_output_ref: mappedOutputRef || stageDefaultRef(venueId, jobId, "mapped"),
        imported_item_count: mapResult.importedCount,
        mapped_categories_added: mapResult.categoriesAdded,
        mapped_needs_review_count: mapResult.needsReviewCount,
      },
    });
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    const message = errText(error);
    logMenuImportStage("error", "Stage failed: map", { venueId, jobId, error: message });
    await markFailed(venueId, jobId, actorUid, "mapping_failed", message);
    throw new functions.https.HttpsError("internal", `Menu mapping failed: ${message}`);
  }
}

async function execReview(venueId: string, jobId: string, actorUid: string): Promise<StageResult> {
  return transition({
    venueId,
    jobId,
    targetStatus: "review_required",
    allowedFrom: ["mapped"],
    actorUid,
  });
}

export const createMenuImportJob = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = context.auth.uid;
  const venueId = asText(data?.venueId);
  const explicitVersionId = asText(data?.versionId);
  const inputFiles = normalizeInputFiles(data?.inputFiles);
  const idempotencyKey = asText(data?.idempotencyKey);

  if (!venueId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId is required.");
  }
  if (!inputFiles.length) {
    throw new functions.https.HttpsError("invalid-argument", "inputFiles must not be empty.");
  }

  await ensureMerchantLinkedToVenue(uid, venueId);
  const versionId = explicitVersionId || await resolveVersionIdFromVenue(venueId);
  await ensureVersionExists(venueId, versionId);

  const db = firestoreDb();
  const jobsRef = db.collection("venues").doc(venueId).collection("menu_import_jobs");

  const deterministicJobId = idempotencyKey
    ? `job_${crypto
      .createHash("sha1")
      .update(`${venueId}:${uid}:${idempotencyKey}`)
      .digest("hex")
      .slice(0, 24)}`
    : "";

  const ref = deterministicJobId ? jobsRef.doc(deterministicJobId) : jobsRef.doc();
  const existing = await ref.get();
  if (existing.exists) {
    const job = existing.data() ?? {};
    const existingStatus = asText(job.status) || "uploaded";
    const inProgressStatuses = ["uploaded", "ocr_done", "extracted", "mapped"];
    const restartableStatuses = ["failed", "review_required", "published"];

    if (inProgressStatuses.includes(existingStatus)) {
      return {
        success: true,
        jobId: ref.id,
        venueId,
        versionId: asText(job.version_id) || versionId,
        status: existingStatus,
        idempotent: true,
      };
    }

    if (restartableStatuses.includes(existingStatus)) {
      await ref.set({
        venue_id: venueId,
        version_id: versionId,
        status: "uploaded",
        input_files: inputFiles,
        ocr_output_ref: null,
        extracted_output_ref: null,
        mapped_output_ref: null,
        imported_item_count: null,
        categories_added_count: null,
        needs_review_count: null,
        error_code: null,
        error_message: null,
        updated_at: FieldValue.serverTimestamp(),
        last_stage_by: uid,
      }, { merge: true });

      return {
        success: true,
        jobId: ref.id,
        venueId,
        versionId,
        status: "uploaded",
        idempotent: false,
        retried: existingStatus === "failed",
        restarted: existingStatus !== "failed",
      };
    }

    return {
      success: true,
      jobId: ref.id,
      venueId,
      versionId: asText(job.version_id) || versionId,
      status: existingStatus,
      idempotent: true,
    };
  }

  await ref.set({
    venue_id: venueId,
    version_id: versionId,
    status: "uploaded",
    idempotency_key: idempotencyKey || null,
    input_files: inputFiles,
    ocr_output_ref: null,
    extracted_output_ref: null,
    mapped_output_ref: null,
    error_code: null,
    error_message: null,
    created_by: uid,
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });

  return {
    success: true,
    jobId: ref.id,
    venueId,
    versionId,
    status: "uploaded",
    idempotent: false,
  };
});

export const runMenuOcr = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = context.auth.uid;
  const venueId = asText(data?.venueId);
  const jobId = asText(data?.jobId);
  const ocrOutputRef = asText(data?.ocrOutputRef);

  if (!venueId || !jobId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId and jobId are required.");
  }
  await ensureMerchantLinkedToVenue(uid, venueId);

  return execRunOcr({ venueId, jobId, actorUid: uid, ocrOutputRef });
});

export const extractMenuCandidates = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = context.auth.uid;
  const venueId = asText(data?.venueId);
  const jobId = asText(data?.jobId);
  const extractedOutputRef = asText(data?.extractedOutputRef);

  if (!venueId || !jobId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId and jobId are required.");
  }
  await ensureMerchantLinkedToVenue(uid, venueId);

  return execExtract({ venueId, jobId, actorUid: uid, extractedOutputRef });
});

export const mapExtractedMenu = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = context.auth.uid;
  const venueId = asText(data?.venueId);
  const jobId = asText(data?.jobId);
  const mappedOutputRef = asText(data?.mappedOutputRef);

  if (!venueId || !jobId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId and jobId are required.");
  }
  await ensureMerchantLinkedToVenue(uid, venueId);

  return execMap({ venueId, jobId, actorUid: uid, mappedOutputRef });
});

async function runPipelineToReview(params: {
  venueId: string;
  jobId: string;
  actorUid: string;
}): Promise<string> {
  const { venueId, jobId, actorUid } = params;
  logMenuImportStage("info", "Pipeline start", { venueId, jobId, actorUid });
  let current = (await readJobCore(venueId, jobId)).status;
  if (current === "failed") {
    throw new functions.https.HttpsError("failed-precondition", "Cannot process a failed job.");
  }

  const reviewRank = rank("review_required");
  while (rank(current) >= 0 && rank(current) < reviewRank) {
    if (current === "uploaded") {
      current = (await execRunOcr({ venueId, jobId, actorUid, ocrOutputRef: "" })).status;
      continue;
    }
    if (current === "ocr_done") {
      current = (await execExtract({ venueId, jobId, actorUid, extractedOutputRef: "" })).status;
      continue;
    }
    if (current === "extracted") {
      current = (await execMap({ venueId, jobId, actorUid, mappedOutputRef: "" })).status;
      continue;
    }
    if (current === "mapped") {
      current = (await execReview(venueId, jobId, actorUid)).status;
      continue;
    }
    break;
  }
  logMenuImportStage("info", "Pipeline complete", { venueId, jobId, finalStatus: current });
  return current;
}

export const processMenuImport = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = context.auth.uid;
  const venueId = asText(data?.venueId);
  const jobId = asText(data?.jobId);

  if (!venueId || !jobId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId and jobId are required.");
  }
  await ensureMerchantLinkedToVenue(uid, venueId);

  const current = await runPipelineToReview({ venueId, jobId, actorUid: uid });

  return {
    success: true,
    jobId,
    venueId,
    status: current,
    done: current === "review_required" || current === "published",
  };
});

export const enqueueMenuImport = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = context.auth.uid;
  const venueId = asText(data?.venueId);
  const jobId = asText(data?.jobId);
  if (!venueId || !jobId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId and jobId are required.");
  }

  await ensureMerchantLinkedToVenue(uid, venueId);
  await readJobCore(venueId, jobId);

  const tasksRef = jobTasksRef(venueId);
  const taskRef = tasksRef.doc();

  await taskRef.set(
    {
      venue_id: venueId,
      job_id: jobId,
      created_by: uid,
      status: "queued",
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await jobRef(venueId, jobId).set(
    {
      processing_state: "queued",
      processing_requested_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return {
    success: true,
    queued: true,
    status: "queued",
    done: false,
    taskId: taskRef.id,
    venueId,
    jobId,
  };
});

export const onMenuImportTaskCreate = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB", failurePolicy: true })
  .firestore
  .document("venues/{venueId}/menu_import_tasks/{taskId}")
  .onCreate(async (snap, context) => {
    const venueId = asText(context.params.venueId);
    const taskId = asText(context.params.taskId);
    const task = snap.data() ?? {};
    const jobId = asText(task.job_id);
    const actorUid = asText(task.created_by) || "menu_import_worker";

    if (!venueId || !taskId || !jobId) {
      await snap.ref.set(
        {
          status: "failed",
          error_message: "Invalid import task payload.",
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    await snap.ref.set(
      {
        status: "processing",
        started_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await jobRef(venueId, jobId).set(
      {
        processing_state: "processing",
        processing_started_at: FieldValue.serverTimestamp(),
        last_task_id: taskId,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    try {
      const finalStatus = await runPipelineToReview({
        venueId,
        jobId,
        actorUid,
      });

      await snap.ref.set(
        {
          status: "completed",
          final_status: finalStatus,
          finished_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      await jobRef(venueId, jobId).set(
        {
          processing_state: "completed",
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } catch (error) {
      const message = errText(error).slice(0, 800);
      await snap.ref.set(
        {
          status: "failed",
          error_message: message,
          finished_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      await jobRef(venueId, jobId).set(
        {
          processing_state: "failed",
          last_worker_error: message,
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      throw error;
    }
  });

