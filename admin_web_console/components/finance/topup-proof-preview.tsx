"use client";

import type { TopUpRequest } from "@/lib/finance/read-models";

type TopUpProofPreviewVariant = "table" | "dialog";

export function TopUpProofPreview({
  request,
  variant = "table",
}: {
  request: TopUpRequest;
  variant?: TopUpProofPreviewVariant;
}) {
  const proofImageUrl = request.proofImageUrl?.trim() ?? "";
  const previewUrl = resolveProofPreviewUrl(proofImageUrl);

  if (!proofImageUrl) {
    return <span className="muted-text">لا يوجد وصل</span>;
  }

  if (!previewUrl) {
    return (
      <div className="topup-proof topup-proof--error">
        <span>مسار الوصل غير صالح</span>
        <code title={proofImageUrl}>{proofImageUrl}</code>
      </div>
    );
  }

  const isDialog = variant === "dialog";
  const imageClassName = isDialog ? "topup-proof__image" : "topup-proof__thumb";
  const alt = `وصل طلب الشحن ${request.id}`;

  return (
    <div className={`topup-proof topup-proof--${variant}`}>
      <a href={previewUrl} rel="noreferrer" target="_blank">
        <img alt={alt} className={imageClassName} src={previewUrl} />
        <span>عرض الوصل</span>
      </a>
      {request.proofStorageDeleted ? (
        <span className="topup-proof__warning">تم حذف الملف من التخزين</span>
      ) : null}
      {request.proofRetentionUntil ? (
        <span className="muted-text">
          محفوظ حتى {new Date(request.proofRetentionUntil).toLocaleDateString("ar")}
        </span>
      ) : null}
    </div>
  );
}

function resolveProofPreviewUrl(value: string): string | null {
  if (/^(https?:\/\/|blob:|data:)/i.test(value)) {
    return value;
  }

  const storagePath = normalizeStoragePath(value);
  return storagePath
    ? `/api/admin/topup-proof?path=${encodeURIComponent(storagePath)}`
    : null;
}

function normalizeStoragePath(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  if (/^gs:\/\//i.test(trimmed)) {
    const withoutScheme = trimmed.replace(/^gs:\/\//i, "");
    const firstSlash = withoutScheme.indexOf("/");
    return firstSlash >= 0 ? withoutScheme.slice(firstSlash + 1) : null;
  }

  const normalized = trimmed.replace(/^\/+/, "");
  return normalized.includes("/") ? normalized : null;
}
