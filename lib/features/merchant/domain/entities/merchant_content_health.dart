enum MerchantContentHealthStatus { healthy, warning, critical }

enum MerchantContentHealthKind { menu, photos, stories, hours, profile }

class MerchantContentHealthItem {
  final MerchantContentHealthKind kind;
  final MerchantContentHealthStatus status;
  final int? ageDays;
  final int? count;
  final int? missingCount;
  final bool hasActive;

  const MerchantContentHealthItem({
    required this.kind,
    required this.status,
    this.ageDays,
    this.count,
    this.missingCount,
    this.hasActive = false,
  });

  bool get isHealthy => status == MerchantContentHealthStatus.healthy;
}

class MerchantContentHealth {
  final MerchantContentHealthItem menu;
  final MerchantContentHealthItem photos;
  final MerchantContentHealthItem stories;
  final MerchantContentHealthItem hours;
  final MerchantContentHealthItem profile;

  const MerchantContentHealth({
    required this.menu,
    required this.photos,
    required this.stories,
    required this.hours,
    required this.profile,
  });

  List<MerchantContentHealthItem> get items => [
    menu,
    photos,
    stories,
    hours,
    profile,
  ];

  List<MerchantContentHealthItem> get issues =>
      items.where((item) => !item.isHealthy).toList()..sort((left, right) {
        final leftRank = switch (left.status) {
          MerchantContentHealthStatus.critical => 0,
          MerchantContentHealthStatus.warning => 1,
          MerchantContentHealthStatus.healthy => 2,
        };
        final rightRank = switch (right.status) {
          MerchantContentHealthStatus.critical => 0,
          MerchantContentHealthStatus.warning => 1,
          MerchantContentHealthStatus.healthy => 2,
        };
        if (leftRank != rightRank) {
          return leftRank.compareTo(rightRank);
        }
        return left.kind.index.compareTo(right.kind.index);
      });

  bool get allHealthy => issues.isEmpty;

  const MerchantContentHealth.empty()
    : menu = const MerchantContentHealthItem(
        kind: MerchantContentHealthKind.menu,
        status: MerchantContentHealthStatus.healthy,
      ),
      photos = const MerchantContentHealthItem(
        kind: MerchantContentHealthKind.photos,
        status: MerchantContentHealthStatus.healthy,
      ),
      stories = const MerchantContentHealthItem(
        kind: MerchantContentHealthKind.stories,
        status: MerchantContentHealthStatus.healthy,
      ),
      hours = const MerchantContentHealthItem(
        kind: MerchantContentHealthKind.hours,
        status: MerchantContentHealthStatus.healthy,
      ),
      profile = const MerchantContentHealthItem(
        kind: MerchantContentHealthKind.profile,
        status: MerchantContentHealthStatus.healthy,
      );
}

MerchantContentHealth buildMerchantContentHealth({
  required bool hasActiveMenu,
  required DateTime? menuPublishedAt,
  required int photoCount,
  required bool hasActiveStory,
  required DateTime? lastStoryAt,
  required bool is24Hours,
  required int validHoursDays,
  required bool hasName,
  required bool hasCity,
  required bool hasPhone,
  required bool hasCategory,
  required bool hasPhoto,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final missingProfileFields = [
    if (!hasName) 1,
    if (!hasCity) 1,
    if (!hasPhone) 1,
    if (!hasCategory) 1,
    if (!hasPhoto) 1,
  ].length;

  final menuAgeDays = menuPublishedAt == null
      ? null
      : currentTime.difference(menuPublishedAt).inDays;
  final storyAgeDays = lastStoryAt == null
      ? null
      : currentTime.difference(lastStoryAt).inDays;

  final menu = !hasActiveMenu
      ? const MerchantContentHealthItem(
          kind: MerchantContentHealthKind.menu,
          status: MerchantContentHealthStatus.critical,
          hasActive: false,
        )
      : MerchantContentHealthItem(
          kind: MerchantContentHealthKind.menu,
          status: menuAgeDays != null && menuAgeDays <= 14
              ? MerchantContentHealthStatus.healthy
              : MerchantContentHealthStatus.warning,
          ageDays: menuAgeDays,
          hasActive: true,
        );

  final photos = MerchantContentHealthItem(
    kind: MerchantContentHealthKind.photos,
    status: switch (photoCount) {
      >= 5 => MerchantContentHealthStatus.healthy,
      >= 3 => MerchantContentHealthStatus.warning,
      _ => MerchantContentHealthStatus.critical,
    },
    count: photoCount,
  );

  final stories = hasActiveStory
      ? const MerchantContentHealthItem(
          kind: MerchantContentHealthKind.stories,
          status: MerchantContentHealthStatus.healthy,
          hasActive: true,
        )
      : MerchantContentHealthItem(
          kind: MerchantContentHealthKind.stories,
          status: storyAgeDays == null
              ? MerchantContentHealthStatus.critical
              : storyAgeDays <= 7
              ? MerchantContentHealthStatus.healthy
              : storyAgeDays <= 14
              ? MerchantContentHealthStatus.warning
              : MerchantContentHealthStatus.critical,
          ageDays: storyAgeDays,
          hasActive: false,
        );

  final hours = MerchantContentHealthItem(
    kind: MerchantContentHealthKind.hours,
    status: is24Hours
        ? MerchantContentHealthStatus.healthy
        : switch (validHoursDays) {
            >= 5 => MerchantContentHealthStatus.healthy,
            >= 1 => MerchantContentHealthStatus.warning,
            _ => MerchantContentHealthStatus.critical,
          },
    count: validHoursDays,
  );

  final profile = MerchantContentHealthItem(
    kind: MerchantContentHealthKind.profile,
    status: switch (missingProfileFields) {
      0 => MerchantContentHealthStatus.healthy,
      1 => MerchantContentHealthStatus.warning,
      _ => MerchantContentHealthStatus.critical,
    },
    missingCount: missingProfileFields,
  );

  return MerchantContentHealth(
    menu: menu,
    photos: photos,
    stories: stories,
    hours: hours,
    profile: profile,
  );
}
