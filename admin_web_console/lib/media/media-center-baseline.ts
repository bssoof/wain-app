import {
  createFinanceCallableInvokerFromEnv,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";

import type {
  MediaCenterBaseline,
  MediaCenterItem,
  MediaCenterSection,
  MediaReadState,
  MediaReferenceIndexHealth,
  MediaReferenceSafety,
  MediaSectionKey,
} from "./media-center-models";

const CALLABLE_CHANNEL = "callable:getAdminMediaInventoryReadBundle";
const UNAVAILABLE_CHANNEL = "media_center_unavailable";
const DEFAULT_STALE_AFTER_MS = 5 * 60 * 1000;
const DEFAULT_SECTION_LIMIT = 60;
const DEFAULT_MEDIA_CENTER_SHARED_CACHE_TTL_MS = 30_000;
const MAX_MEDIA_CENTER_SHARED_CACHE_SIZE = 32;

const SECTION_DEFINITIONS: Record<
  MediaSectionKey,
  { title: string; scopeNote: string }
> = {
  proofs: {
    title: "صور الإثبات",
    scopeNote: "صور إثبات الشحن المعروضة للمراجعة.",
  },
  venue_photos: {
    title: "صور الجهات",
    scopeNote: "صور الجهات المعروضة داخل التطبيق.",
  },
  offer_images: {
    title: "صور العروض",
    scopeNote: "صور العروض المعروضة للمستخدمين.",
  },
  story_images: {
    title: "صور القصص",
    scopeNote: "صور القصص المعروضة للمستخدمين.",
  },
};

type MediaReferenceIndexStatus = MediaReferenceIndexHealth;

type MediaReferenceIndex = {
  status: MediaReferenceIndexStatus;
  asOf: string | null;
  detail: string;
};

type SectionNormalization = {
  items: MediaCenterItem[];
  malformedRows: number;
  invalidPayload: boolean;
};

type MediaCenterBaselineCacheEntry = {
  value: MediaCenterBaseline;
  expiresAt: number;
};

const g = globalThis as any;
g.mediaCenterBaselineCache ??= new Map<string, MediaCenterBaselineCacheEntry>();
const mediaCenterBaselineCache: Map<string, MediaCenterBaselineCacheEntry> = g.mediaCenterBaselineCache;

export type MediaCenterLoaderOptions = {
  env?: Record<string, string | undefined>;
  now?: () => Date;
  invokeCallable?: FinanceCallableInvoker;
};

export function __resetMediaCenterBaselineCacheForTests(): void {
  mediaCenterBaselineCache.clear();
}

export async function loadMediaCenterBaseline(
  options?: MediaCenterLoaderOptions,
): Promise<MediaCenterBaseline> {
  const _t0 = performance.now();
  const env = options?.env ?? process.env;
  const nowFn = options?.now ?? (() => new Date());
  const hasExplicitInvokeCallable = typeof options?.invokeCallable === "function";
  const fetchedAt = nowFn();
  const sharedCacheConfig = resolveMediaCenterSharedCacheConfig(env, options);

  if (sharedCacheConfig.enabled) {
    const cached = readMediaCenterBaselineFromCache(sharedCacheConfig.key);
    if (cached) {
      console.log(
        `[PERF] loadMediaCenterBaseline: ${(performance.now() - _t0).toFixed(0)}ms (channel: cache_hit)`,
      );
      return cached;
    }
  }

  const finalizeResult = (
    baseline: MediaCenterBaseline,
    channel: string,
  ): MediaCenterBaseline => {
    writeMediaCenterBaselineToCache(sharedCacheConfig, baseline);
    console.log(
      `[PERF] loadMediaCenterBaseline: ${(performance.now() - _t0).toFixed(0)}ms (channel: ${channel})`,
    );
    return baseline;
  };

  if (env.WAIN_MEDIA_CENTER_FORCE_UNAVAILABLE === "1") {
    return finalizeResult(
      buildUnavailableBaseline(
        fetchedAt,
        "قراءة الصور والملفات غير متاحة بسبب إعداد تشغيل محلي.",
        UNAVAILABLE_CHANNEL,
      ),
      UNAVAILABLE_CHANNEL,
    );
  }

  const invokeCallable = resolveCallableInvoker(options, env);
  if (!invokeCallable) {
    const firestoreBaseline = await loadMediaCenterFromFirestore(
      fetchedAt,
      env,
      parsePositiveInt(env.WAIN_MEDIA_CENTER_STALE_AFTER_MS) ??
        DEFAULT_STALE_AFTER_MS,
    );
    if (firestoreBaseline) {
      return finalizeResult(firestoreBaseline, "firestore");
    }

    return finalizeResult(
      buildUnavailableBaseline(
        fetchedAt,
        "اتصال خدمة الصور والملفات غير مهيأ.",
        UNAVAILABLE_CHANNEL,
      ),
      UNAVAILABLE_CHANNEL,
    );
  }

  const staleAfterMs =
    parsePositiveInt(env.WAIN_MEDIA_CENTER_STALE_AFTER_MS) ?? DEFAULT_STALE_AFTER_MS;

  try {
    const raw = asRecord(
      await invokeCallable("getAdminMediaInventoryReadBundle", {
        proofLimit:
          parsePositiveInt(env.WAIN_MEDIA_CENTER_PROOF_LIMIT) ?? DEFAULT_SECTION_LIMIT,
        venuePhotoLimit:
          parsePositiveInt(env.WAIN_MEDIA_CENTER_VENUE_PHOTO_LIMIT) ??
          DEFAULT_SECTION_LIMIT,
        offerImageLimit:
          parsePositiveInt(env.WAIN_MEDIA_CENTER_OFFER_IMAGE_LIMIT) ??
          DEFAULT_SECTION_LIMIT,
        storyImageLimit:
          parsePositiveInt(env.WAIN_MEDIA_CENTER_STORY_IMAGE_LIMIT) ??
          DEFAULT_SECTION_LIMIT,
      }),
    );

    if (!raw) {
      return buildUnavailableBaseline(
        fetchedAt,
        "أعادت خدمة الصور والملفات استجابة غير صالحة.",
        CALLABLE_CHANNEL,
      );
    }

    const generatedAt = normalizeIsoDate(raw.checkedAt, nowFn);
    const referenceIndex = normalizeReferenceIndex(
      asRecord(raw.referenceIndex),
      generatedAt,
    );

    const ageMs = Math.max(0, fetchedAt.getTime() - new Date(generatedAt).getTime());
    const staleByAge = ageMs > staleAfterMs;

    const proofs = normalizeProofRows(raw.topupProofs, generatedAt);
    const venuePhotos = normalizeVenuePhotoRows(raw.venuePhotos, generatedAt);
    const offerImages = normalizeOfferImageRows(raw.offerImages, generatedAt);
    const storyImages = normalizeStoryImageRows(raw.storyImages, generatedAt);

    return finalizeResult(
      {
        generatedAt,
        sections: [
          buildSection("proofs", proofs, {
            source: CALLABLE_CHANNEL,
            referenceIndex,
            staleByAge,
            ageMs,
            staleAfterMs,
            emptyMessage: "لا توجد صفوف لصور الإثبات.",
          }),
          buildSection("venue_photos", venuePhotos, {
            source: CALLABLE_CHANNEL,
            referenceIndex,
            staleByAge,
            ageMs,
            staleAfterMs,
            emptyMessage: "لا توجد صفوف لصور الجهات.",
          }),
          buildSection("offer_images", offerImages, {
            source: CALLABLE_CHANNEL,
            referenceIndex,
            staleByAge,
            ageMs,
            staleAfterMs,
            emptyMessage: "لا توجد صفوف لصور العروض.",
          }),
          buildSection("story_images", storyImages, {
            source: CALLABLE_CHANNEL,
            referenceIndex,
            staleByAge,
            ageMs,
            staleAfterMs,
            emptyMessage: "لا توجد صفوف لصور القصص.",
          }),
        ],
      },
      CALLABLE_CHANNEL,
    );
  } catch (error) {
    if (!hasExplicitInvokeCallable) {
      const firestoreBaseline = await loadMediaCenterFromFirestore(
        fetchedAt,
        env,
        staleAfterMs,
      );
      if (firestoreBaseline) {
        return finalizeResult(firestoreBaseline, "firestore_fallback");
      }
    }

    return finalizeResult(
      buildUnavailableBaseline(
        fetchedAt,
        `فشل تحميل الصور والملفات: ${normalizeError(error)}`,
        CALLABLE_CHANNEL,
      ),
      UNAVAILABLE_CHANNEL,
    );
  }
}

function resolveMediaCenterSharedCacheConfig(
  env: Record<string, string | undefined>,
  options: MediaCenterLoaderOptions | undefined,
): {
  enabled: boolean;
  key: string;
  ttlMs: number;
} {
  const isTestRuntime =
    process.env.NODE_ENV === "test" ||
    process.env.VITEST === "true" ||
    process.env.WAIN_TEST_MODE === "1";

  const explicitMode = env.WAIN_MEDIA_CENTER_SHARED_CACHE;
  const enabledByEnv = explicitMode === "1" || explicitMode === undefined;
  const enabledInRuntime = explicitMode === "1" || !isTestRuntime;
  const enabledByOptions =
    explicitMode === "1" || (!options?.now && !options?.invokeCallable);

  const ttlMs =
    parsePositiveInt(env.WAIN_MEDIA_CENTER_SHARED_CACHE_TTL_MS) ??
    DEFAULT_MEDIA_CENTER_SHARED_CACHE_TTL_MS;

  return {
    enabled: enabledByEnv && enabledInRuntime && enabledByOptions && ttlMs > 0,
    key: buildMediaCenterSharedCacheKey(env),
    ttlMs,
  };
}

function buildMediaCenterSharedCacheKey(
  env: Record<string, string | undefined>,
): string {
  const relevantEntries = Object.entries(env)
    .filter(
      ([key]) =>
        key.startsWith("WAIN_") || key.startsWith("NEXT_PUBLIC_WAIN_"),
    )
    .sort(([left], [right]) => left.localeCompare(right));

  return relevantEntries
    .map(([key, value]) => `${key}=${value ?? ""}`)
    .join("|");
}

function readMediaCenterBaselineFromCache(
  key: string,
): MediaCenterBaseline | null {
  const entry = mediaCenterBaselineCache.get(key);
  if (!entry) {
    return null;
  }

  if (entry.expiresAt <= Date.now()) {
    mediaCenterBaselineCache.delete(key);
    return null;
  }

  return entry.value;
}

function writeMediaCenterBaselineToCache(
  config: { enabled: boolean; key: string; ttlMs: number },
  value: MediaCenterBaseline,
): void {
  if (!config.enabled) {
    return;
  }

  mediaCenterBaselineCache.set(config.key, {
    value,
    expiresAt: Date.now() + config.ttlMs,
  });

  if (mediaCenterBaselineCache.size > MAX_MEDIA_CENTER_SHARED_CACHE_SIZE) {
    const oldestKey = mediaCenterBaselineCache.keys().next().value as
      | string
      | undefined;
    if (oldestKey) {
      mediaCenterBaselineCache.delete(oldestKey);
    }
  }
}

async function loadMediaCenterFromFirestore(
  fetchedAt: Date,
  env: Record<string, string | undefined>,
  staleAfterMs: number,
): Promise<MediaCenterBaseline | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const { adminDb } = await import("@/lib/firebase/server");

    const venueFilter = toNonEmptyString(env.WAIN_MEDIA_CENTER_VENUE_ID);
    const proofLimit = parsePositiveInt(env.WAIN_MEDIA_CENTER_PROOF_LIMIT) ??
      DEFAULT_SECTION_LIMIT;
    const venuePhotoLimit =
      parsePositiveInt(env.WAIN_MEDIA_CENTER_VENUE_PHOTO_LIMIT) ??
      DEFAULT_SECTION_LIMIT;
    const offerImageLimit =
      parsePositiveInt(env.WAIN_MEDIA_CENTER_OFFER_IMAGE_LIMIT) ??
      DEFAULT_SECTION_LIMIT;
    const storyImageLimit =
      parsePositiveInt(env.WAIN_MEDIA_CENTER_STORY_IMAGE_LIMIT) ??
      DEFAULT_SECTION_LIMIT;

    let proofQuery: any = adminDb.collection("merchant_topup_requests");
    let offersQuery: any = adminDb.collection("offers");
    let storiesQuery: any = adminDb.collection("stories");
    if (venueFilter) {
      proofQuery = proofQuery.where("venue_id", "==", venueFilter);
      offersQuery = offersQuery.where("venue_id", "==", venueFilter);
      storiesQuery = storiesQuery.where("venue_id", "==", venueFilter);
    }

    const [proofSnap, offersSnap, storiesSnap] = await Promise.all([
      proofQuery.limit(Math.min(500, proofLimit * 8)).get(),
      offersQuery.limit(Math.min(500, offerImageLimit * 6)).get(),
      storiesQuery.limit(Math.min(500, storyImageLimit * 6)).get(),
    ]);

    const venueDocs: Array<{ id: string; data: () => Record<string, unknown> | undefined }> =
      [];
    if (venueFilter) {
      const venueDoc = await adminDb.collection("venues").doc(venueFilter).get();
      if (venueDoc.exists) {
        venueDocs.push({
          id: venueDoc.id,
          data: () => asRecord(venueDoc.data()),
        });
      }
    } else {
      const venueSnap = await adminDb
        .collection("venues")
        .limit(Math.min(250, venuePhotoLimit * 4))
        .get();
      for (const doc of venueSnap.docs) {
        venueDocs.push({
          id: doc.id,
          data: () => asRecord(doc.data()),
        });
      }
    }

    const generatedAt = fetchedAt.toISOString();
    const topupProofs: Array<Record<string, unknown>> = [];
    for (const doc of proofSnap.docs) {
      const row = asRecord(doc.data());
      const proofUrl = toNonEmptyString(row?.proof_image_url ?? row?.proofImageUrl);
      if (!row || !proofUrl) {
        continue;
      }

      const venueId = toNonEmptyString(row.venue_id);
      if (venueFilter && venueId !== venueFilter) {
        continue;
      }

      topupProofs.push({
        id: doc.id,
        venueId,
        mediaUrl: proofUrl,
        status: toNonEmptyString(row.status) ?? "pending",
        createdAt: toIsoDateFromFirestore(row.created_at, generatedAt),
        sourceCollection: "merchant_topup_requests",
        sourceDocumentId: doc.id,
        sourceLabel: `merchant_topup_requests/${doc.id}`,
        safety: {
          referenceType: "topup_request",
          referenceId: doc.id,
          referenceIndexStatus: "unavailable",
          purgeBlocked: true,
        },
      });

      if (topupProofs.length >= proofLimit) {
        break;
      }
    }

    const venuePhotos: Array<Record<string, unknown>> = [];
    for (const doc of venueDocs) {
      const row = doc.data();
      if (!row) {
        continue;
      }

      const photos = toStringArray(row.photos);
      if (photos.length === 0) {
        continue;
      }

      for (let photoIndex = 0; photoIndex < photos.length; photoIndex += 1) {
        const mediaUrl = photos[photoIndex];
        if (!mediaUrl) {
          continue;
        }

        venuePhotos.push({
          id: `${doc.id}:photo:${photoIndex}`,
          venueId: doc.id,
          mediaUrl,
          createdAt: toIsoDateFromFirestore(row.created_at, generatedAt),
          updatedAt: toIsoDateFromFirestore(row.updated_at, generatedAt),
          sourceCollection: "venues",
          sourceDocumentId: doc.id,
          sourceLabel: `venues/${doc.id}`,
          safety: {
            referenceType: "venue",
            referenceId: doc.id,
            referenceIndexStatus: "unavailable",
            purgeBlocked: true,
          },
        });

        if (venuePhotos.length >= venuePhotoLimit) {
          break;
        }
      }

      if (venuePhotos.length >= venuePhotoLimit) {
        break;
      }
    }

    const offerImages: Array<Record<string, unknown>> = [];
    for (const doc of offersSnap.docs) {
      const row = asRecord(doc.data());
      const mediaUrl = readMediaUrlFromRow(row, [
        "image_url",
        "imageUrl",
        "media_url",
        "mediaUrl",
        "photo_url",
        "photoUrl",
        "cover_image_url",
        "coverImageUrl",
        "banner_image_url",
        "bannerImageUrl",
      ]);
      if (!row || !mediaUrl) {
        continue;
      }

      offerImages.push({
        id: doc.id,
        venueId: toNonEmptyString(row.venue_id),
        title: toNonEmptyString(row.title_ar ?? row.title) ?? doc.id,
        status: toNonEmptyString(row.admin_state ?? row.status) ?? "unknown",
        mediaUrl,
        createdAt: toIsoDateFromFirestore(row.created_at, generatedAt),
        updatedAt: toIsoDateFromFirestore(row.updated_at ?? row.created_at, generatedAt),
        sourceCollection: "offers",
        sourceDocumentId: doc.id,
        sourceLabel: `offers/${doc.id}`,
        safety: {
          referenceType: "offer",
          referenceId: doc.id,
          referenceIndexStatus: "unavailable",
          purgeBlocked: true,
        },
      });

      if (offerImages.length >= offerImageLimit) {
        break;
      }
    }

    const storyImages: Array<Record<string, unknown>> = [];
    for (const doc of storiesSnap.docs) {
      const row = asRecord(doc.data());
      const mediaUrl = readMediaUrlFromRow(row, [
        "image_url",
        "imageUrl",
        "media_url",
        "mediaUrl",
        "photo_url",
        "photoUrl",
        "thumbnail_url",
        "thumbnailUrl",
      ]);
      if (!row || !mediaUrl) {
        continue;
      }

      storyImages.push({
        id: doc.id,
        venueId: toNonEmptyString(row.venue_id),
        caption:
          toNonEmptyString(row.caption ?? row.text ?? row.caption_ar) ?? doc.id,
        status: toNonEmptyString(row.admin_state ?? row.status) ?? "unknown",
        mediaUrl,
        createdAt: toIsoDateFromFirestore(row.created_at, generatedAt),
        updatedAt: toIsoDateFromFirestore(row.updated_at ?? row.created_at, generatedAt),
        sourceCollection: "stories",
        sourceDocumentId: doc.id,
        sourceLabel: `stories/${doc.id}`,
        safety: {
          referenceType: "story",
          referenceId: doc.id,
          referenceIndexStatus: "unavailable",
          purgeBlocked: true,
        },
      });

      if (storyImages.length >= storyImageLimit) {
        break;
      }
    }

    const referenceIndex: MediaReferenceIndex = {
      status: "unavailable",
      asOf: generatedAt,
      detail: "reference_index_unavailable_in_firestore_fallback",
    };

    const ageMs = 0;
    const staleByAge = ageMs > staleAfterMs;
    const source = "firestore:media_inventory";

    return {
      generatedAt,
      sections: [
        buildSection("proofs", normalizeProofRows(topupProofs, generatedAt), {
          source,
          referenceIndex,
          staleByAge,
          ageMs,
          staleAfterMs,
          emptyMessage: "لا توجد صفوف لصور الإثبات.",
        }),
        buildSection(
          "venue_photos",
          normalizeVenuePhotoRows(venuePhotos, generatedAt),
          {
            source,
            referenceIndex,
            staleByAge,
            ageMs,
            staleAfterMs,
            emptyMessage: "لا توجد صفوف لصور الجهات.",
          },
        ),
        buildSection(
          "offer_images",
          normalizeOfferImageRows(offerImages, generatedAt),
          {
            source,
            referenceIndex,
            staleByAge,
            ageMs,
            staleAfterMs,
            emptyMessage: "لا توجد صفوف لصور العروض.",
          },
        ),
        buildSection(
          "story_images",
          normalizeStoryImageRows(storyImages, generatedAt),
          {
            source,
            referenceIndex,
            staleByAge,
            ageMs,
            staleAfterMs,
            emptyMessage: "لا توجد صفوف لصور القصص.",
          },
        ),
      ],
    };
  } catch {
    return null;
  }
}

function resolveCallableInvoker(
  options: MediaCenterLoaderOptions | undefined,
  env: Record<string, string | undefined>,
): FinanceCallableInvoker | null {
  if (options?.invokeCallable) {
    return options.invokeCallable;
  }

  const resolution = createFinanceCallableInvokerFromEnv({
    ...env,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      env.NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
  });

  return resolution.ok ? resolution.invokeCallable : null;
}

function buildSection(
  key: MediaSectionKey,
  normalized: SectionNormalization,
  context: {
    source: string;
    referenceIndex: MediaReferenceIndex;
    staleByAge: boolean;
    ageMs: number;
    staleAfterMs: number;
    emptyMessage: string;
  },
): MediaCenterSection {
  const state = deriveSectionState(normalized, context);
  const message = buildSectionMessage(
    state,
    normalized,
    context.emptyMessage,
    context.referenceIndex,
  );

  return {
    key,
    title: SECTION_DEFINITIONS[key].title,
    scopeNote: SECTION_DEFINITIONS[key].scopeNote,
    state,
    source: context.source,
    freshnessNote: buildFreshnessNote({
      state,
      staleByAge: context.staleByAge,
      ageMs: context.ageMs,
      staleAfterMs: context.staleAfterMs,
      referenceIndexStatus: context.referenceIndex.status,
    }),
    referenceSafetyNote: buildReferenceSafetyNote(context.referenceIndex),
    referenceIndexHealth: context.referenceIndex.status,
    purgeBlocked: context.referenceIndex.status !== "healthy",
    items: normalized.items,
    ...(message ? { message } : {}),
  };
}

function buildUnavailableBaseline(
  at: Date,
  message: string,
  source: string,
): MediaCenterBaseline {
  const generatedAt = at.toISOString();

  return {
    generatedAt,
    sections: [
      buildUnavailableSection("proofs", source, message),
      buildUnavailableSection("venue_photos", source, message),
      buildUnavailableSection("offer_images", source, message),
      buildUnavailableSection("story_images", source, message),
    ],
  };
}

function buildUnavailableSection(
  key: MediaSectionKey,
  source: string,
  message: string,
): MediaCenterSection {
  return {
    key,
    title: SECTION_DEFINITIONS[key].title,
    scopeNote: SECTION_DEFINITIONS[key].scopeNote,
    state: "unavailable",
    source,
    freshnessNote: "مصدر الصور والملفات غير متاح.",
    referenceSafetyNote: "لا يمكن التحقق من ارتباط الملف لأن مصدر الصور والملفات غير متاح.",
    referenceIndexHealth: "unavailable",
    purgeBlocked: true,
    items: [],
    message,
  };
}

function normalizeReferenceIndex(
  value: Record<string, unknown> | undefined,
  fallbackAsOf: string,
): MediaReferenceIndex {
  const status = normalizeReferenceIndexStatus(value?.status);
  return {
    status,
    asOf: normalizeOptionalIsoDate(value?.asOf),
    detail: toNonEmptyString(value?.detail) ?? `reference_index_status_${status}`,
  };
}

function normalizeProofRows(value: unknown, fallbackIso: string): SectionNormalization {
  return normalizeRows(value, (row) => {
    const id = toNonEmptyString(row.id);
    const mediaUrl = toNonEmptyString(row.mediaUrl);
    if (!id || !mediaUrl) {
      return null;
    }

    const sourceCollection =
      toNonEmptyString(row.sourceCollection) ?? "merchant_topup_requests";
    const sourceDocumentId = toNonEmptyString(row.sourceDocumentId) ?? id;
    const safety = asRecord(row.safety);
    const status = toNonEmptyString(row.status) ?? "pending";

    return {
      id,
      title: `إثبات شحن ${id}`,
      venueName: toNonEmptyString(row.venueId),
      uploadedAt: normalizeIsoDate(row.createdAt, () => new Date(fallbackIso)),
      sourceDocument: `${sourceCollection}/${sourceDocumentId}`,
      referenceType:
        toNonEmptyString(safety?.referenceType) ?? "topup_request",
      referenceId: toNonEmptyString(safety?.referenceId) ?? id,
      sourceLabel:
        toNonEmptyString(row.sourceLabel) ?? `${sourceCollection}/${sourceDocumentId}`,
      referenceSafety: normalizeReferenceSafety(safety),
      referenceIndexHealth: normalizeReferenceIndexStatus(safety?.referenceIndexStatus),
      purgeBlocked: normalizePurgeBlocked(safety),
      mediaUrl,
      previewNote: `الحالة: ${status}.`,
    };
  });
}

function normalizeVenuePhotoRows(value: unknown, fallbackIso: string): SectionNormalization {
  return normalizeRows(value, (row) => {
    const id = toNonEmptyString(row.id);
    const mediaUrl = toNonEmptyString(row.mediaUrl);
    if (!id || !mediaUrl) {
      return null;
    }

    const venueId = toNonEmptyString(row.venueId);
    const sourceCollection = toNonEmptyString(row.sourceCollection) ?? "venues";
    const sourceDocumentId = toNonEmptyString(row.sourceDocumentId) ?? venueId ?? id;
    const safety = asRecord(row.safety);

    return {
      id,
      title: toNonEmptyString(row.title) ?? `صورة جهة ${id}`,
      venueName: venueId,
      uploadedAt: normalizeIsoDate(
        row.updatedAt ?? row.createdAt,
        () => new Date(fallbackIso),
      ),
      sourceDocument: `${sourceCollection}/${sourceDocumentId}`,
      referenceType: toNonEmptyString(safety?.referenceType) ?? "venue",
      referenceId: toNonEmptyString(safety?.referenceId) ?? sourceDocumentId,
      sourceLabel:
        toNonEmptyString(row.sourceLabel) ?? `${sourceCollection}/${sourceDocumentId}`,
      referenceSafety: normalizeReferenceSafety(safety),
      referenceIndexHealth: normalizeReferenceIndexStatus(safety?.referenceIndexStatus),
      purgeBlocked: normalizePurgeBlocked(safety),
      mediaUrl,
      previewNote:
        toNonEmptyString(row.previewNote) ?? "عنصر من معرض صور الجهة.",
    };
  });
}

function normalizeOfferImageRows(value: unknown, fallbackIso: string): SectionNormalization {
  return normalizeRows(value, (row) => {
    const id = toNonEmptyString(row.id);
    const mediaUrl = toNonEmptyString(row.mediaUrl);
    if (!id || !mediaUrl) {
      return null;
    }

    const sourceCollection = toNonEmptyString(row.sourceCollection) ?? "offers";
    const sourceDocumentId = toNonEmptyString(row.sourceDocumentId) ?? id;
    const safety = asRecord(row.safety);
    const status = toNonEmptyString(row.status) ?? "unknown";

    return {
      id,
      title: toNonEmptyString(row.title) ?? `صورة عرض ${id}`,
      venueName: toNonEmptyString(row.venueId),
      uploadedAt: normalizeIsoDate(
        row.updatedAt ?? row.createdAt,
        () => new Date(fallbackIso),
      ),
      sourceDocument: `${sourceCollection}/${sourceDocumentId}`,
      referenceType: toNonEmptyString(safety?.referenceType) ?? "offer",
      referenceId: toNonEmptyString(safety?.referenceId) ?? id,
      sourceLabel:
        toNonEmptyString(row.sourceLabel) ?? `${sourceCollection}/${sourceDocumentId}`,
      referenceSafety: normalizeReferenceSafety(safety),
      referenceIndexHealth: normalizeReferenceIndexStatus(safety?.referenceIndexStatus),
      purgeBlocked: normalizePurgeBlocked(safety),
      mediaUrl,
      previewNote: `Offer status: ${status}.`,
    };
  });
}

function normalizeStoryImageRows(value: unknown, fallbackIso: string): SectionNormalization {
  return normalizeRows(value, (row) => {
    const id = toNonEmptyString(row.id);
    const mediaUrl = toNonEmptyString(row.mediaUrl);
    if (!id || !mediaUrl) {
      return null;
    }

    const sourceCollection = toNonEmptyString(row.sourceCollection) ?? "stories";
    const sourceDocumentId = toNonEmptyString(row.sourceDocumentId) ?? id;
    const safety = asRecord(row.safety);
    const status = toNonEmptyString(row.status) ?? "unknown";

    return {
      id,
      title: toNonEmptyString(row.caption) ?? `صورة قصة ${id}`,
      venueName: toNonEmptyString(row.venueId),
      uploadedAt: normalizeIsoDate(
        row.updatedAt ?? row.createdAt,
        () => new Date(fallbackIso),
      ),
      sourceDocument: `${sourceCollection}/${sourceDocumentId}`,
      referenceType: toNonEmptyString(safety?.referenceType) ?? "story",
      referenceId: toNonEmptyString(safety?.referenceId) ?? id,
      sourceLabel:
        toNonEmptyString(row.sourceLabel) ?? `${sourceCollection}/${sourceDocumentId}`,
      referenceSafety: normalizeReferenceSafety(safety),
      referenceIndexHealth: normalizeReferenceIndexStatus(safety?.referenceIndexStatus),
      purgeBlocked: normalizePurgeBlocked(safety),
      mediaUrl,
      previewNote: `Story status: ${status}.`,
    };
  });
}

function normalizeRows(
  value: unknown,
  mapRow: (row: Record<string, unknown>) => MediaCenterItem | null,
): SectionNormalization {
  if (!Array.isArray(value)) {
    return {
      items: [],
      malformedRows: 0,
      invalidPayload: true,
    };
  }

  const items: MediaCenterItem[] = [];
  let malformedRows = 0;

  for (const entry of value) {
    const row = asRecord(entry);
    if (!row) {
      malformedRows += 1;
      continue;
    }

    const normalized = mapRow(row);
    if (!normalized) {
      malformedRows += 1;
      continue;
    }

    items.push(normalized);
  }

  return {
    items,
    malformedRows,
    invalidPayload: false,
  };
}

function deriveSectionState(
  normalized: SectionNormalization,
  context: {
    referenceIndex: MediaReferenceIndex;
    staleByAge: boolean;
  },
): MediaReadState {
  if (normalized.invalidPayload) {
    return "unavailable";
  }

  if (context.staleByAge || context.referenceIndex.status !== "healthy") {
    return "stale";
  }

  if (normalized.items.length === 0) {
    return "empty";
  }

  return "success";
}

function buildSectionMessage(
  state: MediaReadState,
  normalized: SectionNormalization,
  emptyMessage: string,
  referenceIndex: MediaReferenceIndex,
): string | undefined {
  if (state === "unavailable") {
    return "بيانات هذا القسم غير صالحة أو ناقصة.";
  }

  if (state === "empty") {
    return emptyMessage;
  }

  if (state === "stale") {
    const malformedNote =
      normalized.malformedRows > 0
        ? ` تم تجاهل ${normalized.malformedRows} عنصر/عناصر غير صالحة.`
        : "";
    return `حالة ارتباط الملفات تحتاج مراجعة.${malformedNote}`;
  }

  if (normalized.malformedRows > 0) {
    return `تم تجاهل ${normalized.malformedRows} عنصر/عناصر غير صالحة.`;
  }

  return undefined;
}

function buildFreshnessNote(args: {
  state: MediaReadState;
  staleByAge: boolean;
  ageMs: number;
  staleAfterMs: number;
  referenceIndexStatus: MediaReferenceIndexStatus;
}): string {
  if (args.state === "unavailable") {
    return "تعذر تجهيز بيانات هذا القسم من استجابة الخدمة.";
  }

  if (args.state === "empty") {
    return "لا توجد عناصر في هذا القسم حاليًا.";
  }

  if (args.staleByAge) {
    return "البيانات قديمة وتحتاج تحديثًا قبل اتخاذ قرار مهم.";
  }

  if (args.referenceIndexStatus !== "healthy") {
    return "ارتباط بعض الملفات يحتاج مراجعة؛ لذلك يبقى الحذف النهائي ممنوعًا.";
  }

  return "البيانات محدثة.";
}

function buildReferenceSafetyNote(referenceIndex: MediaReferenceIndex): string {
  const asOfNote = referenceIndex.asOf ? ` اعتبارًا من ${referenceIndex.asOf}` : "";

  if (referenceIndex.status === "healthy") {
    return `ارتباط الملفات سليم${asOfNote}. يمكن تنفيذ الخيارات المتاحة حسب الصلاحية.`;
  }

  if (referenceIndex.status === "stale") {
    return `ارتباط الملفات قديم${asOfNote}. الحذف النهائي محظور إلى أن يتم التحديث.`;
  }

  if (referenceIndex.status === "failed") {
    return `تعذر فحص ارتباط الملفات${asOfNote}. تعامل مع الصفحة كعرض فقط.`;
  }

  return `ارتباط الملفات غير متاح${asOfNote}. لا يمكن التحقق الكامل من الحالة.`;
}

function normalizeReferenceSafety(
  value: Record<string, unknown> | undefined,
): MediaReferenceSafety {
  if (!value) {
    return "unknown";
  }

  const status = normalizeReferenceIndexStatus(value.referenceIndexStatus);
  const purgeBlocked = toBoolean(value.purgeBlocked);

  if (status === "healthy" && purgeBlocked === false) {
    return "safe";
  }

  if (status === "failed" || status === "unavailable") {
    return "unsafe";
  }

  return "unknown";
}

function normalizePurgeBlocked(value: Record<string, unknown> | undefined): boolean {
  const status = normalizeReferenceIndexStatus(value?.referenceIndexStatus);
  const purgeBlocked = toBoolean(value?.purgeBlocked);

  if (status !== "healthy") {
    return true;
  }

  return purgeBlocked !== false;
}

function normalizeReferenceIndexStatus(value: unknown): MediaReferenceIndexStatus {
  if (typeof value !== "string") {
    return "unavailable";
  }

  const normalized = value.trim().toLowerCase();
  if (
    normalized === "healthy" ||
    normalized === "stale" ||
    normalized === "failed"
  ) {
    return normalized;
  }

  return "unavailable";
}

function normalizeIsoDate(value: unknown, fallback: () => Date): string {
  const parsed = normalizeOptionalIsoDate(value);
  return parsed ?? fallback().toISOString();
}

function normalizeOptionalIsoDate(value: unknown): string | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value).toISOString();
  }

  if (typeof value === "string") {
    const date = new Date(value);
    if (!Number.isNaN(date.getTime())) {
      return date.toISOString();
    }
  }

  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString();
  }

  return null;
}

function toIsoDateFromFirestore(value: unknown, fallbackIso: string): string {
  const parsed = parseFirestoreDate(value);
  return parsed ? parsed.toISOString() : fallbackIso;
}

function parseFirestoreDate(value: unknown): Date | null {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  if (typeof value === "string") {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) {
      return new Date(parsed);
    }
    return null;
  }

  if (!value || typeof value !== "object") {
    return null;
  }

  const row = value as {
    toDate?: () => Date;
    seconds?: unknown;
    _seconds?: unknown;
  };

  if (typeof row.toDate === "function") {
    const date = row.toDate();
    if (date instanceof Date && !Number.isNaN(date.getTime())) {
      return date;
    }
  }

  const seconds =
    typeof row.seconds === "number"
      ? row.seconds
      : typeof row._seconds === "number"
        ? row._seconds
        : null;

  if (seconds !== null && Number.isFinite(seconds)) {
    const date = new Date(seconds * 1000);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  return null;
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => toNonEmptyString(entry))
    .filter((entry): entry is string => Boolean(entry));
}

function readMediaUrlFromRow(
  row: Record<string, unknown> | undefined,
  keys: string[],
): string | undefined {
  if (!row) {
    return undefined;
  }

  for (const key of keys) {
    const value = toNonEmptyString(row[key]);
    if (value) {
      return value;
    }
  }

  return undefined;
}

function parsePositiveInt(raw: string | undefined): number | undefined {
  if (!raw) {
    return undefined;
  }

  const value = Number.parseInt(raw, 10);
  return Number.isFinite(value) && value > 0 ? value : undefined;
}

function normalizeError(error: unknown): string {
  if (error instanceof Error && error.message.trim().length > 0) {
    return error.message;
  }

  if (typeof error === "string" && error.trim().length > 0) {
    return error.trim();
  }

  return "unknown_error";
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, unknown>;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function toBoolean(value: unknown): boolean | undefined {
  if (typeof value === "boolean") {
    return value;
  }

  return undefined;
}
