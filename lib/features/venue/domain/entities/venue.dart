// ignore_for_file: invalid_annotation_target
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    @JsonKey(name: 'all_tags', fromJson: _toStringList) @Default(<String>[]) List<String> allTags,

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
    @JsonKey(name: 'menu_images', fromJson: _toStringList) @Default(<String>[]) List<String> menuImages,

    @JsonKey(fromJson: _toHoursMap) @Default(<String, List<VenueHours>>{}) Map<String, List<VenueHours>> hours,
    @JsonKey(name: 'is_24h') @Default(false) bool is24h,

    @Default(VenuePartner()) VenuePartner partner,
    @JsonKey(name: 'has_active_offers') @Default(false) bool hasActiveOffers,
    @JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? lastStoryAt,

    @JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? createdAt,
    @JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? updatedAt,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);

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
    
    return Venue.fromJson({
      ...data, 
      'id': doc.id,
      'lat': lat,
      'lng': lng,
    });
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
    if (is24h) return true;
    if (hours.isEmpty) return null;

    final dt = now ?? DateTime.now();
    final dayKey = _dayKeys[dt.weekday];
    if (dayKey == null) return null;

    final currentMinutes = dt.hour * 60 + dt.minute;

    // 1) Check today's own slots
    final todaySlots = hours[dayKey];
    if (todaySlots != null) {
      for (final slot in todaySlots) {
        final openMin = _parseTime(slot.open);
        final closeMin = _parseTime(slot.close);
        if (openMin == null || closeMin == null) continue;

        if (slot.spansMidnight) {
          // e.g. 22:00–03:00 → open if current >= 22:00
          if (currentMinutes >= openMin) return true;
        } else {
          if (currentMinutes >= openMin && currentMinutes < closeMin) return true;
        }
      }
    }

    // 2) Check previous day's spans_midnight slots
    //    e.g. Monday 22:00–03:00, now it's Tuesday 01:00 → still open
    final prevDayKey = _dayKeys[dt.weekday == 1 ? 7 : dt.weekday - 1];
    if (prevDayKey != null) {
      final prevSlots = hours[prevDayKey];
      if (prevSlots != null) {
        for (final slot in prevSlots) {
          if (!slot.spansMidnight) continue;
          final closeMin = _parseTime(slot.close);
          if (closeMin == null) continue;
          // We're in the "after midnight" portion of yesterday's shift
          if (currentMinutes < closeMin) return true;
        }
      }
    }

    // If today has no slots at all AND previous day has no overnight carry-over
    if (todaySlots == null || todaySlots.isEmpty) return false;

    return false;
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
    if (num.startsWith('0')) num = '970${num.substring(1)}'; // Palestine default
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

/// Parse "HH:MM" → total minutes, or null on failure.
int? _parseTime(String time) {
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

@freezed
sealed class VenueTags with _$VenueTags {
  const factory VenueTags({
    @JsonKey(fromJson: _toStringList) @Default(<String>[]) List<String> mood,
    @JsonKey(fromJson: _toStringList) @Default(<String>[]) List<String> occasion,
    @JsonKey(name: 'time_of_day', fromJson: _toStringList) @Default(<String>[]) List<String> timeOfDay,

    // واضح عندك في generated code: meal
    @JsonKey(fromJson: _toStringList) @Default(<String>[]) List<String> meal,
  }) = _VenueTags;

  factory VenueTags.fromJson(Map<String, dynamic> json) => _$VenueTagsFromJson(json);
}

@freezed
sealed class VenueHours with _$VenueHours {
  const factory VenueHours({
    required String open,
    required String close,
    @JsonKey(name: 'spans_midnight') @Default(false) bool spansMidnight,
  }) = _VenueHours;

  factory VenueHours.fromJson(Map<String, dynamic> json) => _$VenueHoursFromJson(json);
}

@freezed
sealed class VenuePartner with _$VenuePartner {
  const factory VenuePartner({
    @JsonKey(name: 'is_partner') @Default(false) bool isPartner,
    @Default('C') String tier,
  }) = _VenuePartner;

  factory VenuePartner.fromJson(Map<String, dynamic> json) => _$VenuePartnerFromJson(json);
}
