"use client";

import { useEffect, useMemo, useState } from "react";

import type { VenueDirectoryItem } from "@/lib/venues/venue-directory-models";

export type VenueEditFormValue = {
  nameAr: string;
  nameEn: string;
  city: string;
  phone: string;
  categories: string[];
  lat?: number;
  lng?: number;
  reason: string;
};

export function VenueEditDialog({
  item,
  open,
  pending,
  onCancel,
  onSubmit,
}: {
  item: VenueDirectoryItem | null;
  open: boolean;
  pending: boolean;
  onCancel: () => void;
  onSubmit: (value: VenueEditFormValue) => void | Promise<void>;
}) {
  const [nameAr, setNameAr] = useState("");
  const [nameEn, setNameEn] = useState("");
  const [city, setCity] = useState("");
  const [phone, setPhone] = useState("");
  const [lat, setLat] = useState("");
  const [lng, setLng] = useState("");
  const [categoriesText, setCategoriesText] = useState("");
  const [reason, setReason] = useState("تحديث ملف الجهة من لوحة الإدارة");

  useEffect(() => {
    if (!item || !open) {
      return;
    }

    setNameAr(item.venueName);
    setNameEn(item.venueNameEn ?? "");
    setCity(item.city ?? "");
    setPhone(item.phone ?? "");
    setLat(
      typeof item.lat === "number" && Number.isFinite(item.lat)
        ? String(item.lat)
        : "",
    );
    setLng(
      typeof item.lng === "number" && Number.isFinite(item.lng)
        ? String(item.lng)
        : "",
    );
    setCategoriesText(item.categories.join(", "));
    setReason("تحديث ملف الجهة من لوحة الإدارة");
  }, [item, open]);

  const parsedCategories = useMemo(
    () =>
      categoriesText
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean),
    [categoriesText],
  );

  if (!open || !item) {
    return null;
  }

  const latText = lat.trim();
  const lngText = lng.trim();
  const hasLat = latText.length > 0;
  const hasLng = lngText.length > 0;
  const parsedLat = hasLat ? Number(latText) : null;
  const parsedLng = hasLng ? Number(lngText) : null;
  const hasValidLat =
    parsedLat !== null &&
    Number.isFinite(parsedLat) &&
    parsedLat >= -90 &&
    parsedLat <= 90;
  const hasValidLng =
    parsedLng !== null &&
    Number.isFinite(parsedLng) &&
    parsedLng >= -180 &&
    parsedLng <= 180;
  const coordinatesReady = (!hasLat && !hasLng) || (hasValidLat && hasValidLng);

  const canSubmit =
    nameAr.trim().length > 0 &&
    city.trim().length > 0 &&
    parsedCategories.length > 0 &&
    coordinatesReady &&
    reason.trim().length > 0;

  const submit = () => {
    if (!canSubmit) {
      return;
    }

    const payload: VenueEditFormValue = {
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      city: city.trim(),
      phone: phone.trim(),
      categories: parsedCategories,
      reason: reason.trim(),
    };

    if (hasValidLat && hasValidLng) {
      payload.lat = parsedLat;
      payload.lng = parsedLng;
    }

    void onSubmit(payload);
  };

  return (
    <div className="venue-management-dialog-backdrop" role="presentation">
      <div
        className="card venue-management-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="venue-edit-dialog-title"
      >
        <div className="venue-management-dialog__header">
          <div>
            <h2 id="venue-edit-dialog-title">تعديل ملف الجهة</h2>
            <p className="muted-text">{item.venueId}</p>
          </div>
          <button
            type="button"
            className="action-button action-button-secondary"
            onClick={onCancel}
            disabled={pending}
          >
            إغلاق
          </button>
        </div>

        <div className="venue-management-form-grid">
          <label className="venue-directory-filter-field">
            <span className="muted-text">الاسم بالعربي</span>
            <input
              className="venue-directory-filter-input"
              value={nameAr}
              onChange={(event) => setNameAr(event.target.value)}
              disabled={pending}
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">الاسم بالإنجليزية</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              value={nameEn}
              onChange={(event) => setNameEn(event.target.value)}
              disabled={pending}
              dir="ltr"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">المدينة</span>
            <input
              className="venue-directory-filter-input"
              value={city}
              onChange={(event) => setCity(event.target.value)}
              disabled={pending}
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">الهاتف</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              value={phone}
              onChange={(event) => setPhone(event.target.value)}
              disabled={pending}
              dir="ltr"
              inputMode="tel"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">خط العرض</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              type="number"
              value={lat}
              onChange={(event) => setLat(event.target.value)}
              disabled={pending}
              step="any"
              placeholder="31.9516"
              dir="ltr"
              inputMode="decimal"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">خط الطول</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              type="number"
              value={lng}
              onChange={(event) => setLng(event.target.value)}
              disabled={pending}
              step="any"
              placeholder="35.9239"
              dir="ltr"
              inputMode="decimal"
            />
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">التصنيفات</span>
            <input
              className="venue-directory-filter-input"
              value={categoriesText}
              onChange={(event) => setCategoriesText(event.target.value)}
              disabled={pending}
            />
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">سبب التعديل</span>
            <input
              className="venue-directory-filter-input"
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              disabled={pending}
            />
          </label>
          {!coordinatesReady ? (
            <p className="muted-text venue-management-form-grid__wide">
              أدخل قيمتي خط العرض وخط الطول معًا وبصيغة رقمية صحيحة.
            </p>
          ) : null}
        </div>

        <div className="venue-management-dialog__footer">
          <button
            type="button"
            className="action-button"
            onClick={submit}
            disabled={!canSubmit || pending}
          >
            {pending ? "جارٍ الحفظ..." : "حفظ التعديلات"}
          </button>
          <button
            type="button"
            className="action-button action-button-secondary"
            onClick={onCancel}
            disabled={pending}
          >
            إلغاء
          </button>
        </div>
      </div>
    </div>
  );
}
