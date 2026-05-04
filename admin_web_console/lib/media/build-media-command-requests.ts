import type {
  MediaCenterItem,
  MediaCenterSection,
  MediaSectionKey,
} from "./media-center-models";
import type {
  MediaCommandRequestMap,
  MediaCommandTarget,
  MediaCommandTargetType,
  MediaCommandType,
} from "./media-command-contracts";

export function buildMediaCommandRequest<T extends MediaCommandType>(
  command: T,
  item: MediaCenterItem,
  section: MediaCenterSection,
): MediaCommandRequestMap[T] {
  const target = buildMediaCommandTarget(item, section.key);
  const timestamp = new Date().toISOString();
  const reason = `Media Center action ${command} submitted for ${item.title}.`;
  const base = {
    commandId: commandKey(command, item.id),
    correlationId: `media-center:${section.key}:${item.id}`,
    submittedAt: timestamp,
    reason,
    target,
  };

  switch (command) {
    case "media_reference_check":
      return {
        ...base,
        action: "media_reference_check",
        expectedState: {},
      } as MediaCommandRequestMap[T];
    case "media_soft_delete":
      return {
        ...base,
        action: "media_soft_delete",
        expectedState: {
          media_state: "active",
        },
      } as MediaCommandRequestMap[T];
    case "media_quarantine":
      return {
        ...base,
        action: "media_quarantine",
        expectedState: {
          media_state: "active",
        },
      } as MediaCommandRequestMap[T];
    case "media_purge":
      return {
        ...base,
        action: "media_purge",
        expectedState: {
          media_state: "quarantined",
          reference_count: 0,
          reference_index_health: "healthy",
        },
      } as MediaCommandRequestMap[T];
    default:
      throw new Error(`Unsupported media command: ${String(command)}`);
  }
}

export function commandKey(command: MediaCommandType, assetId: string): string {
  return `${command}:${assetId}`;
}

function buildMediaCommandTarget(
  item: MediaCenterItem,
  section: MediaSectionKey,
): MediaCommandTarget {
  const source = parseSourceDocument(item.sourceDocument);

  return {
    targetType: mapSectionToTargetType(section),
    targetId: item.id,
    ...(source
      ? {
          sourceCollection: source.collection,
          sourceDocumentId: source.documentId,
        }
      : {}),
    ...(isReferenceType(item.referenceType)
      ? {
          referenceType: item.referenceType,
        }
      : {}),
    ...(item.referenceId
      ? {
          referenceId: item.referenceId,
        }
      : {}),
  };
}

function mapSectionToTargetType(section: MediaSectionKey): MediaCommandTargetType {
  switch (section) {
    case "proofs":
      return "topup_proof";
    case "venue_photos":
      return "venue_photo";
    case "offer_images":
      return "offer_image";
    case "story_images":
      return "story_image";
    default:
      return "media_asset";
  }
}

function parseSourceDocument(
  sourceDocument: string,
): { collection: "merchant_topup_requests" | "venues" | "offers" | "stories"; documentId: string } | null {
  const parts = sourceDocument.split("/");
  if (parts.length < 2) {
    return null;
  }

  const [collection, ...documentIdParts] = parts;
  const documentId = documentIdParts.join("/").trim();
  if (
    (collection !== "merchant_topup_requests" &&
      collection !== "venues" &&
      collection !== "offers" &&
      collection !== "stories") ||
    documentId.length === 0
  ) {
    return null;
  }

  return {
    collection,
    documentId,
  };
}

function isReferenceType(
  value: string,
): value is "topup_request" | "venue" | "offer" | "story" {
  return (
    value === "topup_request" ||
    value === "venue" ||
    value === "offer" ||
    value === "story"
  );
}
