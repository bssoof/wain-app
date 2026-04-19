"use client";

import { useMemo, useState } from "react";

import type {
  VenueHoursDayKey,
  VenueHoursMap,
  VenueTagsPayload,
} from "@/lib/venues/venue-command-contracts";

export type VenueCreateFormValue = {
  nameAr: string;
  nameEn: string;
  city: string;
  phone: string;
  categories: string[];
  lat: number;
  lng: number;
  instagram?: string;
  whatsapp?: string;
  facebook?: string;
  website?: string;
  minPrice?: number;
  maxPrice?: number;
  currency?: "ILS" | "USD";
  photos?: string[];
  menuImages?: string[];
  photoFiles?: File[];
  menuImageFiles?: File[];
  hours?: VenueHoursMap;
  is24h?: boolean;
  tags?: VenueTagsPayload;
  transportEnabled?: boolean;
  transportPartnerIds?: string[];
  transportNotesAr?: string;
  transportNotesEn?: string;
  reason: string;
};

const DAY_ORDER: Array<{ key: VenueHoursDayKey; label: string }> = [
  { key: "monday", label: "الاثنين" },
  { key: "tuesday", label: "الثلاثاء" },
  { key: "wednesday", label: "الأربعاء" },
  { key: "thursday", label: "الخميس" },
  { key: "friday", label: "الجمعة" },
  { key: "saturday", label: "السبت" },
  { key: "sunday", label: "الأحد" },
];

const MOOD_TAG_OPTIONS: Array<{ key: string; label: string }> = [
  { key: "romantic", label: "رومانسي" },
  { key: "chill", label: "هادئ" },
  { key: "fun", label: "فرفشة" },
  { key: "cozy", label: "دافئ" },
  { key: "work_friendly", label: "مناسب للشغل" },
  { key: "family", label: "عائلي" },
  { key: "outdoor", label: "في الخارج" },
  { key: "trendy", label: "عصري" },
  { key: "traditional", label: "تقليدي" },
];

const HOUR_PATTERN = /^([01]\d|2[0-3]):[0-5]\d$/;

type VenueDayHoursInput = {
  enabled: boolean;
  open: string;
  close: string;
  spansMidnight: boolean;
};

type VenueHoursInputMap = Record<VenueHoursDayKey, VenueDayHoursInput>;

function parseTokenList(value: string): string[] {
  return Array.from(
    new Set(
      value
        .split(/[\n,،]+/)
        .map((entry) => entry.trim())
        .filter(Boolean),
    ),
  );
}

function uniqueInInputOrder(values: string[]): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const value of values) {
    if (!value || seen.has(value)) {
      continue;
    }

    seen.add(value);
    result.push(value);
  }

  return result;
}

function parseOptionalNonNegativeInteger(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  const parsed = Number(trimmed);
  if (!Number.isFinite(parsed) || parsed < 0) {
    return NaN;
  }

  return Math.floor(parsed);
}

function buildDefaultHoursInputMap(): VenueHoursInputMap {
  return DAY_ORDER.reduce((acc, day) => {
    acc[day.key] = {
      enabled: false,
      open: "09:00",
      close: "22:00",
      spansMidnight: false,
    };
    return acc;
  }, {} as VenueHoursInputMap);
}

function parseHoursFromFormState(value: VenueHoursInputMap): {
  value?: VenueHoursMap;
  error: string | null;
} {
  const normalized: VenueHoursMap = {};

  for (const day of DAY_ORDER) {
    const dayValue = value[day.key];
    if (!dayValue?.enabled) {
      continue;
    }

    const open = dayValue.open.trim();
    const close = dayValue.close.trim();
    if (!HOUR_PATTERN.test(open) || !HOUR_PATTERN.test(close)) {
      return {
        value: undefined,
        error: `أدخل وقتًا صالحًا ليوم ${day.label} بصيغة HH:MM مثل 09:30.`,
      };
    }

    normalized[day.key] = [
      {
        open,
        close,
        spansMidnight: dayValue.spansMidnight,
      },
    ];
  }

  if (Object.keys(normalized).length === 0) {
    return { value: undefined, error: null };
  }

  return {
    value: normalized,
    error: null,
  };
}

export function VenueCreateDialog({
  open,
  pending,
  onCancel,
  onSubmit,
}: {
  open: boolean;
  pending: boolean;
  onCancel: () => void;
  onSubmit: (value: VenueCreateFormValue) => void | Promise<void>;
}) {
  const [nameAr, setNameAr] = useState("");
  const [nameEn, setNameEn] = useState("");
  const [city, setCity] = useState("");
  const [phone, setPhone] = useState("");
  const [instagram, setInstagram] = useState("");
  const [whatsapp, setWhatsapp] = useState("");
  const [facebook, setFacebook] = useState("");
  const [website, setWebsite] = useState("");
  const [lat, setLat] = useState("");
  const [lng, setLng] = useState("");
  const [categoriesText, setCategoriesText] = useState("");
  const [minPriceText, setMinPriceText] = useState("");
  const [maxPriceText, setMaxPriceText] = useState("");
  const [currency, setCurrency] = useState<"ILS" | "USD">("ILS");
  const [photosText, setPhotosText] = useState("");
  const [menuImagesText, setMenuImagesText] = useState("");
  const [photoFiles, setPhotoFiles] = useState<File[]>([]);
  const [menuImageFiles, setMenuImageFiles] = useState<File[]>([]);
  const [is24h, setIs24h] = useState(false);
  const [hoursByDay, setHoursByDay] =
    useState<VenueHoursInputMap>(buildDefaultHoursInputMap);
  const [selectedMoodTags, setSelectedMoodTags] = useState<string[]>([]);
  const [moodTagsText, setMoodTagsText] = useState("");
  const [occasionTagsText, setOccasionTagsText] = useState("");
  const [timeOfDayTagsText, setTimeOfDayTagsText] = useState("");
  const [mealTagsText, setMealTagsText] = useState("");
  const [transportEnabled, setTransportEnabled] = useState(false);
  const [transportPartnerIdsText, setTransportPartnerIdsText] = useState("");
  const [transportNotesAr, setTransportNotesAr] = useState("");
  const [transportNotesEn, setTransportNotesEn] = useState("");
  const [reason, setReason] = useState("إنشاء جهة جديدة من لوحة الإدارة");

  const parsedCategories = useMemo(() => parseTokenList(categoriesText), [categoriesText]);

  const parsedPhotos = useMemo(() => parseTokenList(photosText), [photosText]);
  const parsedMenuImages = useMemo(() => parseTokenList(menuImagesText), [menuImagesText]);
  const parsedMoodTags = useMemo(
    () => uniqueInInputOrder([...selectedMoodTags, ...parseTokenList(moodTagsText)]),
    [selectedMoodTags, moodTagsText],
  );
  const parsedOccasionTags = useMemo(() => parseTokenList(occasionTagsText), [occasionTagsText]);
  const parsedTimeOfDayTags = useMemo(() => parseTokenList(timeOfDayTagsText), [timeOfDayTagsText]);
  const parsedMealTags = useMemo(() => parseTokenList(mealTagsText), [mealTagsText]);
  const parsedTransportPartnerIds = useMemo(
    () => parseTokenList(transportPartnerIdsText),
    [transportPartnerIdsText],
  );

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
  const coordinatesReady = hasValidLat && hasValidLng;

  const parsedMinPrice = parseOptionalNonNegativeInteger(minPriceText);
  const parsedMaxPrice = parseOptionalNonNegativeInteger(maxPriceText);
  const hasAnyPricingInput =
    minPriceText.trim().length > 0 || maxPriceText.trim().length > 0;

  let pricingError: string | null = null;
  let minPriceValue: number | undefined;
  let maxPriceValue: number | undefined;

  if (hasAnyPricingInput) {
    if (Number.isNaN(parsedMinPrice) || Number.isNaN(parsedMaxPrice)) {
      pricingError = "الأسعار يجب أن تكون أرقامًا صحيحة غير سالبة.";
    } else if (parsedMinPrice === null || parsedMaxPrice === null) {
      pricingError = "عند إدخال سعر، أدخل الحد الأدنى والحد الأعلى معًا.";
    } else if (parsedMaxPrice < parsedMinPrice) {
      pricingError = "الحد الأعلى للسعر يجب أن يكون أكبر من أو يساوي الحد الأدنى.";
    } else {
      minPriceValue = parsedMinPrice;
      maxPriceValue = parsedMaxPrice;
    }
  }

  const { value: parsedHours, error: hoursError } = useMemo(() => {
    if (is24h) {
      return { value: undefined, error: null };
    }
    return parseHoursFromFormState(hoursByDay);
  }, [is24h, hoursByDay]);

  const canSubmit =
    nameAr.trim().length > 0 &&
    city.trim().length > 0 &&
    parsedCategories.length > 0 &&
    coordinatesReady &&
    !pricingError &&
    !hoursError &&
    reason.trim().length > 0;

  if (!open) {
    return null;
  }

  const toggleMoodTag = (tagKey: string) => {
    setSelectedMoodTags((current) => {
      if (current.includes(tagKey)) {
        return current.filter((entry) => entry !== tagKey);
      }

      return [...current, tagKey];
    });
  };

  const updateHoursInput = (
    dayKey: VenueHoursDayKey,
    field: keyof VenueDayHoursInput,
    fieldValue: string | boolean,
  ) => {
    setHoursByDay((current) => ({
      ...current,
      [dayKey]: {
        ...current[dayKey],
        [field]: fieldValue,
      },
    }));
  };

  const submit = () => {
    if (!canSubmit) {
      return;
    }

    const payload: VenueCreateFormValue = {
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      city: city.trim(),
      phone: phone.trim(),
      categories: parsedCategories,
      lat: parsedLat as number,
      lng: parsedLng as number,
      reason: reason.trim(),
    };

    const instagramValue = instagram.trim();
    if (instagramValue) {
      payload.instagram = instagramValue;
    }

    const whatsappValue = whatsapp.trim();
    if (whatsappValue) {
      payload.whatsapp = whatsappValue;
    }

    const facebookValue = facebook.trim();
    if (facebookValue) {
      payload.facebook = facebookValue;
    }

    const websiteValue = website.trim();
    if (websiteValue) {
      payload.website = websiteValue;
    }

    if (minPriceValue !== undefined && maxPriceValue !== undefined) {
      payload.minPrice = minPriceValue;
      payload.maxPrice = maxPriceValue;
      payload.currency = currency;
    }

    if (parsedPhotos.length > 0) {
      payload.photos = parsedPhotos;
    }

    if (parsedMenuImages.length > 0) {
      payload.menuImages = parsedMenuImages;
    }

    if (photoFiles.length > 0) {
      payload.photoFiles = photoFiles;
    }

    if (menuImageFiles.length > 0) {
      payload.menuImageFiles = menuImageFiles;
    }

    payload.is24h = is24h;
    if (!is24h && parsedHours && Object.keys(parsedHours).length > 0) {
      payload.hours = parsedHours;
    }

    const tags: VenueTagsPayload = {};
    if (parsedMoodTags.length > 0) {
      tags.mood = parsedMoodTags;
    }
    if (parsedOccasionTags.length > 0) {
      tags.occasion = parsedOccasionTags;
    }
    if (parsedTimeOfDayTags.length > 0) {
      tags.timeOfDay = parsedTimeOfDayTags;
    }
    if (parsedMealTags.length > 0) {
      tags.meal = parsedMealTags;
    }
    if (Object.keys(tags).length > 0) {
      payload.tags = tags;
    }

    if (transportEnabled) {
      payload.transportEnabled = true;
      if (parsedTransportPartnerIds.length > 0) {
        payload.transportPartnerIds = parsedTransportPartnerIds;
      }

      const notesArValue = transportNotesAr.trim();
      const notesEnValue = transportNotesEn.trim();
      if (notesArValue) {
        payload.transportNotesAr = notesArValue;
      }
      if (notesEnValue) {
        payload.transportNotesEn = notesEnValue;
      }
    }

    void onSubmit(payload);
  };

  return (
    <div className="venue-management-dialog-backdrop" role="presentation">
      <div
        className="card venue-management-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="venue-create-dialog-title"
      >
        <div className="venue-management-dialog__header">
          <div>
            <h2 id="venue-create-dialog-title">إضافة جهة جديدة</h2>
            <p className="muted-text">
              الحقول المطلوبة: الاسم العربي، المدينة، تصنيف واحد على الأقل، وخطي العرض والطول لضمان ظهور الجهة في التطبيق فورًا.
            </p>
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
          <p className="muted-text venue-management-form-grid__wide">
            <strong>بيانات أساسية</strong>
          </p>
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
              placeholder="اختياري عند الإنشاء"
              dir="ltr"
              inputMode="tel"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">حساب إنستغرام</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              value={instagram}
              onChange={(event) => setInstagram(event.target.value)}
              disabled={pending}
              placeholder="instagram.com/..."
              dir="ltr"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">رقم واتساب</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              value={whatsapp}
              onChange={(event) => setWhatsapp(event.target.value)}
              disabled={pending}
              placeholder="+97059..."
              dir="ltr"
              inputMode="tel"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">صفحة فيسبوك</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              value={facebook}
              onChange={(event) => setFacebook(event.target.value)}
              disabled={pending}
              placeholder="facebook.com/..."
              dir="ltr"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">الموقع الإلكتروني</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              value={website}
              onChange={(event) => setWebsite(event.target.value)}
              disabled={pending}
              placeholder="https://..."
              dir="ltr"
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

          <p className="muted-text venue-management-form-grid__wide">
            <strong>تسعير وتصنيف</strong>
          </p>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">التصنيفات</span>
            <input
              className="venue-directory-filter-input"
              value={categoriesText}
              onChange={(event) => setCategoriesText(event.target.value)}
              disabled={pending}
              placeholder="مثال: مقهى، فطور، قهوة مختصة"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">الحد الأدنى للسعر</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              type="number"
              min="0"
              step="1"
              value={minPriceText}
              onChange={(event) => setMinPriceText(event.target.value)}
              disabled={pending}
              placeholder="مثال: 20"
              dir="ltr"
              inputMode="numeric"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">الحد الأعلى للسعر</span>
            <input
              className="venue-directory-filter-input venue-directory-filter-input--ltr"
              type="number"
              min="0"
              step="1"
              value={maxPriceText}
              onChange={(event) => setMaxPriceText(event.target.value)}
              disabled={pending}
              placeholder="مثال: 80"
              dir="ltr"
              inputMode="numeric"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">العملة</span>
            <select
              className="venue-directory-filter-select venue-directory-filter-select--ltr"
              value={currency}
              onChange={(event) => setCurrency(event.target.value as "ILS" | "USD")}
              disabled={pending}
              dir="ltr"
            >
              <option value="ILS">ILS</option>
              <option value="USD">USD</option>
            </select>
          </label>
          {pricingError ? (
            <p className="muted-text venue-management-form-grid__wide">
              {pricingError}
            </p>
          ) : null}

          <p className="muted-text venue-management-form-grid__wide">
            <strong>صور ومنيو</strong>
          </p>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">رفع صور الجهة مباشرة (متعدد)</span>
            <input
              className="venue-directory-filter-input"
              type="file"
              accept="image/*"
              multiple
              onChange={(event) =>
                setPhotoFiles(Array.from(event.target.files ?? []))
              }
              disabled={pending}
              data-testid="venue-create-photo-files-input"
            />
            <span className="muted-text">
              {photoFiles.length > 0
                ? `تم اختيار ${photoFiles.length} صورة للجهة.`
                : "لم يتم اختيار صور جهة بعد."}
            </span>
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">رفع صور المنيو مباشرة (متعدد)</span>
            <input
              className="venue-directory-filter-input"
              type="file"
              accept="image/*"
              multiple
              onChange={(event) =>
                setMenuImageFiles(Array.from(event.target.files ?? []))
              }
              disabled={pending}
              data-testid="venue-create-menu-files-input"
            />
            <span className="muted-text">
              {menuImageFiles.length > 0
                ? `تم اختيار ${menuImageFiles.length} صورة منيو.`
                : "لم يتم اختيار صور منيو بعد."}
            </span>
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">صور الجهة (رابط واحد بكل سطر أو فاصلة)</span>
            <textarea
              className="venue-directory-filter-input"
              value={photosText}
              onChange={(event) => setPhotosText(event.target.value)}
              disabled={pending}
              rows={3}
              placeholder="https://.../photo1.jpg"
            />
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">صور المنيو (رابط واحد بكل سطر أو فاصلة)</span>
            <textarea
              className="venue-directory-filter-input"
              value={menuImagesText}
              onChange={(event) => setMenuImagesText(event.target.value)}
              disabled={pending}
              rows={3}
              placeholder="https://.../menu1.jpg"
            />
          </label>
          <p className="muted-text venue-management-form-grid__wide">
            يمكنك المزج بين الرفع المباشر وإدخال الروابط. الروابط الناتجة من الرفع المباشر تُحفظ تلقائيًا بعد إنشاء الجهة.
          </p>

          <p className="muted-text venue-management-form-grid__wide">
            <strong>المواعيد</strong>
          </p>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">عمل 24 ساعة</span>
            <input
              type="checkbox"
              checked={is24h}
              onChange={(event) => setIs24h(event.target.checked)}
              disabled={pending}
            />
          </label>
          <div className="venue-management-form-grid__wide venue-hours-grid" data-testid="venue-create-hours-grid">
            <p className="muted-text">حدّد أيام العمل وساعات كل يوم. اترك اليوم غير مفعّل إذا كان مغلقًا.</p>
            {DAY_ORDER.map((day) => {
              const dayValue = hoursByDay[day.key];
              const rowDisabled = pending || is24h;
              const inputsDisabled = rowDisabled || !dayValue.enabled;

              return (
                <div className="venue-hours-row" key={day.key} data-testid={`venue-create-hours-row-${day.key}`}>
                  <span className="venue-hours-day">{day.label}</span>
                  <label className="venue-hours-control">
                    <input
                      type="checkbox"
                      checked={dayValue.enabled}
                      onChange={(event) =>
                        updateHoursInput(day.key, "enabled", event.target.checked)
                      }
                      disabled={rowDisabled}
                      data-testid={`venue-create-hours-open-${day.key}`}
                    />
                    <span className="muted-text">مفتوح</span>
                  </label>
                  <label className="venue-hours-control">
                    <span className="muted-text">من</span>
                    <input
                      className="venue-directory-filter-input venue-directory-filter-input--ltr"
                      type="time"
                      value={dayValue.open}
                      onChange={(event) =>
                        updateHoursInput(day.key, "open", event.target.value)
                      }
                      disabled={inputsDisabled}
                      dir="ltr"
                      data-testid={`venue-create-hours-from-${day.key}`}
                    />
                  </label>
                  <label className="venue-hours-control">
                    <span className="muted-text">إلى</span>
                    <input
                      className="venue-directory-filter-input venue-directory-filter-input--ltr"
                      type="time"
                      value={dayValue.close}
                      onChange={(event) =>
                        updateHoursInput(day.key, "close", event.target.value)
                      }
                      disabled={inputsDisabled}
                      dir="ltr"
                      data-testid={`venue-create-hours-to-${day.key}`}
                    />
                  </label>
                  <label className="venue-hours-control">
                    <input
                      type="checkbox"
                      checked={dayValue.spansMidnight}
                      onChange={(event) =>
                        updateHoursInput(day.key, "spansMidnight", event.target.checked)
                      }
                      disabled={inputsDisabled}
                      data-testid={`venue-create-hours-spans-midnight-${day.key}`}
                    />
                    <span className="muted-text">يمتد لليوم التالي</span>
                  </label>
                </div>
              );
            })}
          </div>
          {hoursError ? (
            <p className="muted-text venue-management-form-grid__wide">{hoursError}</p>
          ) : null}

          <p className="muted-text venue-management-form-grid__wide">
            <strong>وسوم الجهة</strong>
          </p>
          <div className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">أجواء المكان (اختر ما ينطبق)</span>
            <div className="venue-mood-tags-grid">
              {MOOD_TAG_OPTIONS.map((option) => (
                <label className="venue-mood-tag-chip" key={option.key}>
                  <input
                    type="checkbox"
                    checked={selectedMoodTags.includes(option.key)}
                    onChange={() => toggleMoodTag(option.key)}
                    disabled={pending}
                    data-testid={`venue-create-mood-tag-${option.key}`}
                  />
                  <span>{option.label}</span>
                </label>
              ))}
            </div>
          </div>
          <label className="venue-directory-filter-field">
            <span className="muted-text">وسوم أجواء إضافية (اختياري)</span>
            <input
              className="venue-directory-filter-input"
              value={moodTagsText}
              onChange={(event) => setMoodTagsText(event.target.value)}
              disabled={pending}
              placeholder="مثال: reading_friendly, rooftop"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">وسوم المناسبة</span>
            <input
              className="venue-directory-filter-input"
              value={occasionTagsText}
              onChange={(event) => setOccasionTagsText(event.target.value)}
              disabled={pending}
              placeholder="مثال: date, family, business_meeting"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">وسوم وقت الزيارة</span>
            <input
              className="venue-directory-filter-input"
              value={timeOfDayTagsText}
              onChange={(event) => setTimeOfDayTagsText(event.target.value)}
              disabled={pending}
              placeholder="مثال: morning, sunset, late_night"
            />
          </label>
          <label className="venue-directory-filter-field">
            <span className="muted-text">وسوم الوجبات</span>
            <input
              className="venue-directory-filter-input"
              value={mealTagsText}
              onChange={(event) => setMealTagsText(event.target.value)}
              disabled={pending}
              placeholder="مثال: breakfast, dinner, dessert"
            />
          </label>

          <p className="muted-text venue-management-form-grid__wide">
            <strong>بيانات النقل (اختياري)</strong>
          </p>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">تفعيل النقل</span>
            <input
              type="checkbox"
              checked={transportEnabled}
              onChange={(event) => setTransportEnabled(event.target.checked)}
              disabled={pending}
            />
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">معرّفات شركاء النقل (فواصل أو أسطر)</span>
            <input
              className="venue-directory-filter-input"
              value={transportPartnerIdsText}
              onChange={(event) => setTransportPartnerIdsText(event.target.value)}
              disabled={pending || !transportEnabled}
              placeholder="partner_1, partner_2"
            />
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">ملاحظات النقل (عربي)</span>
            <textarea
              className="venue-directory-filter-input"
              value={transportNotesAr}
              onChange={(event) => setTransportNotesAr(event.target.value)}
              disabled={pending || !transportEnabled}
              rows={2}
            />
          </label>
          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">ملاحظات النقل (إنجليزي)</span>
            <textarea
              className="venue-directory-filter-input"
              value={transportNotesEn}
              onChange={(event) => setTransportNotesEn(event.target.value)}
              disabled={pending || !transportEnabled}
              rows={2}
            />
          </label>

          <label className="venue-directory-filter-field venue-management-form-grid__wide">
            <span className="muted-text">سبب الإنشاء</span>
            <input
              className="venue-directory-filter-input"
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              disabled={pending}
            />
          </label>
          {!coordinatesReady ? (
            <p className="muted-text venue-management-form-grid__wide">
              أدخل خط العرض وخط الطول بصيغة رقمية صحيحة. هذا الشرط مطلوب لظهور الجهة في نتائج التطبيق.
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
            {pending ? "جارٍ الإنشاء..." : "إنشاء الجهة"}
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
