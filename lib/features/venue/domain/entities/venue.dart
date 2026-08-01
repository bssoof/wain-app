// ignore_for_file: invalid_annotation_target
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wain_app/core/utils/hours_calculator.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

// Force Rebuild
// ---------- helpers (robust parsing) ----------
double _toDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _toInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

List<String> _toStringList(Object? v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String) {
    if (v.isEmpty) return const [];
    return v.split(',').map((e) => e.trim()).toList();
  }
  return const [];
}

Timestamp? _toTimestamp(Object? v) {
  if (v is Timestamp) return v;
  // Handle ISO string from cache
  if (v is String) {
    final dt = DateTime.tryParse(v);
    if (dt != null) return Timestamp.fromDate(dt);
  }
  // Handle int (millis) from Cloud Functions
  if (v is int) {
    return Timestamp.fromMillisecondsSinceEpoch(v);
  }
  return null;
}

/// Convert Timestamp to ISO string for JSON serialization (cache-friendly)
String? _timestampToJson(Timestamp? t) => t?.toDate().toIso8601String();

String _stringValue(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? '' : text;
}

String _firstNonEmptyString(List<Object?> values, {required String fallback}) {
  for (final value in values) {
    final text = _stringValue(value);
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

Map<String, dynamic> _normalizeVenueJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  final location = normalized['location'];
  if (location is GeoPoint) {
    normalized['lat'] ??= location.latitude;
    normalized['lng'] ??= location.longitude;
  } else if (location is Map) {
    normalized['lat'] ??= location['lat'] ?? location['latitude'];
    normalized['lng'] ??= location['lng'] ?? location['longitude'];
  }

  normalized['id'] = _firstNonEmptyString([
    normalized['id'],
    normalized['venue_id'],
    normalized['venueId'],
  ], fallback: '');

  final nameAr = _firstNonEmptyString([
    normalized['name_ar'],
    normalized['name'],
    normalized['title_ar'],
    normalized['name_en'],
    normalized['title_en'],
  ], fallback: 'Venue');

  final nameEn = _firstNonEmptyString([
    normalized['name_en'],
    normalized['name'],
    normalized['title_en'],
    normalized['name_ar'],
    normalized['title_ar'],
  ], fallback: nameAr);

  normalized['name_ar'] = nameAr;
  normalized['name_en'] = nameEn;
  normalized['city'] = _firstNonEmptyString([normalized['city']], fallback: '');
  normalized['phone'] = _stringValue(normalized['phone']);
  normalized['rating'] ??=
      normalized['average_rating'] ?? normalized['review_rating'];
  normalized['min_price'] ??=
      normalized['price_min'] ?? normalized['minPrice'] ?? normalized['price'];
  normalized['max_price'] ??=
      normalized['price_max'] ??
      normalized['maxPrice'] ??
      normalized['min_price'] ??
      normalized['price'];
  normalized['has_active_offers'] ??=
      normalized['has_offers'] ?? normalized['hasActiveOffers'];

  final tags = normalized['tags'];
  normalized['tags'] = tags is Map
      ? Map<String, dynamic>.from(tags)
      : <String, dynamic>{};

  final partner = normalized['partner'];
  if (partner != null && partner is! Map) {
    normalized.remove('partner');
  }

  normalized['photos'] ??=
      normalized['photo_urls'] ??
      normalized['image_urls'] ??
      normalized['image_url'];

  return normalized;
}

Map<String, List<VenueHours>> _toHoursMap(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, List<VenueHours>>{};
  raw.forEach((k, v) {
    final key = k.toString();
    if (v is List) {
      out[key] = v
          .whereType<Map>()
          .map((m) => VenueHours.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      out[key] = const [];
    }
  });
  return out;
}

// ---------- models ----------
@freezed
sealed class Venue with _$Venue {
  const factory Venue({
    @JsonKey(includeToJson: false) required String id,

    @JsonKey(name: 'name_ar') required String nameAr,
    @JsonKey(name: 'name_en') required String nameEn,
    @JsonKey(name: 'name_ar_norm') @Default('') String nameArNorm,
    @JsonKey(name: 'name_en_norm') @Default('') String nameEnNorm,

    @JsonKey(fromJson: _toDouble) required double lat,
    @JsonKey(fromJson: _toDouble) required double lng,
    required String city,

    @JsonKey(fromJson: _toStringList) required List<String> categories,
    required VenueTags tags,
    @JsonKey(name: 'all_tags', fromJson: _toStringList)
    @Default(<String>[])
    List<String> allTags,

    @JsonKey(name: 'min_price', fromJson: _toInt) required int minPrice,
    @JsonKey(name: 'max_price', fromJson: _toInt) required int maxPrice,
    @Default('ILS') String currency,

    @JsonKey(fromJson: _toDouble) required double rating,

    required String phone,
    @Default('') String instagram,
    @Default('') String whatsapp,
    @Default('') String facebook,
    @Default('') String website,
    @JsonKey(fromJson: _toStringList) @Default(<String>[]) List<String> photos,
    @JsonKey(name: 'menu_images', fromJson: _toStringList)
    @Default(<String>[])
    List<String> menuImages,

    @JsonKey(fromJson: _toHoursMap)
    @Default(<String, List<VenueHours>>{})
    Map<String, List<VenueHours>> hours,
    @JsonKey(name: 'is_24h') @Default(false) bool is24h,

    @Default(VenuePartner()) VenuePartner partner,
    @JsonKey(name: 'has_active_offers') @Default(false) bool hasActiveOffers,
    @JsonKey(name: 'transport_enabled') @Default(false) bool transportEnabled,
    @JsonKey(name: 'transport_partner_ids', fromJson: _toStringList)
    @Default(<String>[])
    List<String> transportPartnerIds,
    @JsonKey(name: 'transport_notes_ar') @Default('') String transportNotesAr,
    @JsonKey(name: 'transport_notes_en') @Default('') String transportNotesEn,
    @JsonKey(
      name: 'last_story_at',
      fromJson: _toTimestamp,
      toJson: _timestampToJson,
    )
    Timestamp? lastStoryAt,

    // Admin-managed status fields (Phase B — Venue Management)
    @JsonKey(name: 'subscription_status')
    @Default('active')
    String subscriptionStatus,
    @JsonKey(name: 'visibility_status')
    @Default('visible')
    String visibilityStatus,
    @JsonKey(name: 'operational_status')
    @Default('active')
    String operationalStatus,
    @JsonKey(
      name: 'admin_status_updated_at',
      fromJson: _toTimestamp,
      toJson: _timestampToJson,
    )
    Timestamp? adminStatusUpdatedAt,
    @JsonKey(name: 'admin_status_updated_by') String? adminStatusUpdatedBy,

    @JsonKey(
      name: 'created_at',
      fromJson: _toTimestamp,
      toJson: _timestampToJson,
    )
    Timestamp? createdAt,
    @JsonKey(
      name: 'updated_at',
      fromJson: _toTimestamp,
      toJson: _timestampToJson,
    )
    Timestamp? updatedAt,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) =>
      _$VenueFromJson(_normalizeVenueJson(json));

  factory Venue.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    // Extract lat/lng from GeoPoint if stored as 'location'
    final location = data['location'];
    double lat = 0.0;
    double lng = 0.0;
    if (location is GeoPoint) {
      lat = location.latitude;
      lng = location.longitude;
    } else {
      // Fallback to separate fields if they exist
      lat = _toDouble(data['lat']);
      lng = _toDouble(data['lng']);
    }

    return Venue.fromJson({...data, 'id': doc.id, 'lat': lat, 'lng': lng});
  }
}

// ---------- venue helpers ----------

/// Day-of-week mapping (Dart: 1=Monday → 7=Sunday)
const _dayKeys = {
  1: 'monday',
  2: 'tuesday',
  3: 'wednesday',
  4: 'thursday',
  5: 'friday',
  6: 'saturday',
  7: 'sunday',
};

/// Extension providing computed helpers on [Venue].
extension VenueHelpers on Venue {
  /// Returns `true` if the venue is currently open, `false` if closed,
  /// or `null` if hours are unknown / not configured.
  ///
  /// Edge cases handled:
  /// - `is_24h` → always open
  /// - Empty `hours` map → null (unknown)
  /// - `spans_midnight` (e.g. 22:00–03:00) → correct overnight check
  bool? isOpenNow({DateTime? now}) {
    return isOpenNowFromSlots<VenueHours>(
      hours: hours,
      is24Hours: is24h,
      now: now,
      openOf: (slot) => slot.open,
      closeOf: (slot) => slot.close,
      spansMidnightOf: (slot) => slot.spansMidnight,
    );
  }

  /// Today's formatted hours string, e.g. "09:00 - 22:00", or null.
  String? get todayHoursText {
    if (is24h) return 'open_24h';
    if (hours.isEmpty) return null;

    final dayKey = _dayKeys[DateTime.now().weekday];
    if (dayKey == null) return null;

    final slots = hours[dayKey];
    if (slots == null || slots.isEmpty) return 'closed_today';
    return slots.map((s) => '${s.open} - ${s.close}').join(' ، ');
  }

  /// Normalized phone for `tel:` URI (strips spaces).
  String get normalizedPhone => phone.replaceAll(RegExp(r'\s+'), '');

  /// WhatsApp deep link number (strip leading 0, ensure country code).
  String get whatsappNumber {
    var num = whatsapp.replaceAll(RegExp(r'\s+'), '');
    if (num.startsWith('0')) {
      num = '970${num.substring(1)}'; // Palestine default
    }
    if (!num.startsWith('+') && !num.startsWith('00')) num = '+$num';
    return num.replaceAll('+', '');
  }

  /// Whether the venue has any social link configured.
  bool get hasSocialLinks =>
      instagram.isNotEmpty ||
      facebook.isNotEmpty ||
      website.isNotEmpty ||
      whatsapp.isNotEmpty;
}

@freezed
sealed class VenueTags with _$VenueTags {
  const factory VenueTags({
    @JsonKey(fromJson: _toStringList) @Default(<String>[]) List<String> mood,
    @JsonKey(fromJson: _toStringList)
    @Default(<String>[])
    List<String> occasion,
    @JsonKey(name: 'time_of_day', fromJson: _toStringList)
    @Default(<String>[])
    List<String> timeOfDay,

    // واضح عندك في generated code: meal
    @JsonKey(fromJson: _toStringList) @Default(<String>[]) List<String> meal,
  }) = _VenueTags;

  factory VenueTags.fromJson(Map<String, dynamic> json) =>
      _$VenueTagsFromJson(json);
}

@freezed
sealed class VenueHours with _$VenueHours {
  const factory VenueHours({
    required String open,
    required String close,
    @JsonKey(name: 'spans_midnight') @Default(false) bool spansMidnight,
  }) = _VenueHours;

  factory VenueHours.fromJson(Map<String, dynamic> json) =>
      _$VenueHoursFromJson(json);
}

@freezed
sealed class VenuePartner with _$VenuePartner {
  const factory VenuePartner({
    @JsonKey(name: 'is_partner') @Default(false) bool isPartner,
    @Default('C') String tier,
  }) = _VenuePartner;

  factory VenuePartner.fromJson(Map<String, dynamic> json) =>
      _$VenuePartnerFromJson(json);
}
