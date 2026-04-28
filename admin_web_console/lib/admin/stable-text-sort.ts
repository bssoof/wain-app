const ARABIC_TEXT_PATTERN =
  /[\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff\ufb50-\ufdff\ufe70-\ufeff]/u;

type StableTextSortKey = {
  bucket: number;
  normalized: string;
  raw: string;
};

export function compareAdminText(left: string, right: string): number {
  const leftKey = buildStableTextSortKey(left);
  const rightKey = buildStableTextSortKey(right);

  if (leftKey.bucket !== rightKey.bucket) {
    return leftKey.bucket - rightKey.bucket;
  }

  if (leftKey.normalized < rightKey.normalized) {
    return -1;
  }

  if (leftKey.normalized > rightKey.normalized) {
    return 1;
  }

  if (leftKey.raw < rightKey.raw) {
    return -1;
  }

  if (leftKey.raw > rightKey.raw) {
    return 1;
  }

  return 0;
}

function buildStableTextSortKey(value: string): StableTextSortKey {
  const raw = value.trim();
  const normalized = raw.normalize("NFKC").toLowerCase();

  return {
    bucket: ARABIC_TEXT_PATTERN.test(normalized) ? 0 : 1,
    normalized,
    raw,
  };
}
