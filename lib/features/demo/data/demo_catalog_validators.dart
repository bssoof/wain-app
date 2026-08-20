import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';

/// Every local asset reference the demo owns, as repository-relative paths.
///
/// Kept as one list so a test can assert that each file actually exists on disk
/// rather than trusting the string.
List<String> demoAssetPaths() {
  const prefix = 'asset://';
  final paths = <String>{
    for (final photo in demoVenuePhotos)
      if (photo.startsWith(prefix)) photo.substring(prefix.length),
    for (final item in demoMenuItems)
      if (item.photoUrl.startsWith(prefix)) item.photoUrl.substring(prefix.length),
  };
  return paths.toList()..sort();
}

/// Why the demo is not yet fit to show a customer, empty when it is.
///
/// Kept separate from [validateDemoCatalogs] on purpose: structural validity
/// says the wiring is correct, this says the content is real. Passing the first
/// and failing this is the expected state until the photo pack lands.
List<String> demoAssetPackReadiness() {
  final blockers = <String>[];

  if (!demoVenueAssetPackInstalled) {
    blockers.add(
      'venue photo pack not installed: the gallery is showing food and drink '
      'stand-ins, not storefront/seating/workspace/terrace photography',
    );
  }

  final uniqueItemPhotos =
      demoMenuItems.map((item) => item.photoUrl).toSet().length;
  if (uniqueItemPhotos < demoMenuItems.length) {
    blockers.add(
      'menu photos are reused: $uniqueItemPhotos unique images across '
      '${demoMenuItems.length} items',
    );
  }

  return blockers;
}

/// Contract problems in the demo catalogs, empty when everything holds.
///
/// This is the single place the demo's invariants are written down; the tests
/// assert on it instead of restating the rules.
List<String> validateDemoCatalogs() {
  final problems = <String>[];

  // --- identity -------------------------------------------------------
  final sectionIds = demoMenuSections.map((s) => s.id).toList();
  if (sectionIds.toSet().length != sectionIds.length) {
    problems.add('duplicate section ids: $sectionIds');
  }

  final itemIds = demoMenuItems.map((i) => i.id).toList();
  if (itemIds.toSet().length != itemIds.length) {
    problems.add('duplicate menu item ids');
  }

  // --- shape ----------------------------------------------------------
  if (demoMenuSections.length < 6) {
    problems.add('expected at least 6 sections, found ${demoMenuSections.length}');
  }

  final available = demoMenuItems.where((i) => i.isAvailable).toList();
  if (available.length < 24) {
    problems.add('expected at least 24 available items, found ${available.length}');
  }

  if (!demoMenuItems.any((i) => !i.isAvailable)) {
    problems.add('expected at least one unavailable item for the merchant view');
  }

  if (!demoMenuItems.any((i) => i.isFeatured)) {
    problems.add('expected at least one featured item');
  }

  // --- per-section ----------------------------------------------------
  for (final section in demoMenuSections) {
    final sectionItems =
        available.where((i) => i.category == section.id).toList();
    if (sectionItems.length < 3 || sectionItems.length > 5) {
      problems.add(
        'section "${section.id}" must hold 3-5 available items, '
        'found ${sectionItems.length}',
      );
    }
    final orders = sectionItems.map((i) => i.sortOrder).toList();
    if (orders.toSet().length != orders.length) {
      problems.add('section "${section.id}" has duplicate sortOrder values');
    }
  }

  // --- orphans --------------------------------------------------------
  for (final item in demoMenuItems) {
    if (!sectionIds.contains(item.category)) {
      problems.add('item "${item.id}" points at unknown section "${item.category}"');
    }
  }

  // --- per-item contract ----------------------------------------------
  for (final item in demoMenuItems) {
    problems.addAll(_validateItem(item));
  }

  // --- venue ----------------------------------------------------------
  // Structural only: the gallery must have six slots wired up. Whether those
  // slots hold real *venue* photography is a separate question, answered by
  // [demoAssetPackReadiness] — a demo can be structurally valid and still not
  // fit to put in front of a customer.
  if (demoVenuePhotos.length < 6) {
    problems.add('expected 6 gallery slots, found ${demoVenuePhotos.length}');
  }

  final venue = buildDemoVenue();
  final tagCount =
      venue.tags.mood.length +
      venue.tags.occasion.length +
      venue.tags.timeOfDay.length +
      venue.tags.meal.length;
  if (tagCount < 8) {
    problems.add('expected at least 8 venue attributes, found $tagCount');
  }
  for (final family in <String, List<String>>{
    'mood': venue.tags.mood,
    'occasion': venue.tags.occasion,
    'time_of_day': venue.tags.timeOfDay,
    'meal': venue.tags.meal,
  }.entries) {
    if (family.value.isEmpty) {
      problems.add('tag family "${family.key}" is empty');
    }
  }

  // --- hours ----------------------------------------------------------
  const weekdays = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  for (final day in weekdays) {
    if (!venue.hours.containsKey(day)) {
      problems.add('hours are missing "$day"');
    }
  }
  if (!venue.hours.values.any((slots) => slots.length > 1)) {
    problems.add('expected one day with two separate slots');
  }
  if (!venue.hours.values.any((slots) => slots.isEmpty)) {
    problems.add('expected one closed day');
  }
  if (!venue.hours.values
      .any((slots) => slots.any((slot) => slot.spansMidnight))) {
    problems.add('expected one slot spanning midnight');
  }

  return problems;
}

List<String> _validateItem(MenuItem item) {
  final problems = <String>[];
  if (item.nameAr.trim().isEmpty) problems.add('item "${item.id}" has no Arabic name');
  if (item.nameEn.trim().isEmpty) problems.add('item "${item.id}" has no English name');
  if (item.descriptionAr.trim().isEmpty) {
    problems.add('item "${item.id}" has no Arabic description');
  }
  if (item.price <= 0) problems.add('item "${item.id}" has a non-positive price');
  if (item.currency.trim().isEmpty) problems.add('item "${item.id}" has no currency');
  if (!item.photoUrl.startsWith('asset://')) {
    problems.add('item "${item.id}" must use a local asset:// photo');
  }
  return problems;
}
