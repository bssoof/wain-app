import 'dart:io';
import 'dart:math';

class _MenuItemSeed {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;

  const _MenuItemSeed({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
  });
}

String _buildSearchableText(_MenuItemSeed item) {
  return '${item.nameAr} ${item.nameEn} ${item.descriptionAr}'.toLowerCase();
}

Map<String, String> _buildSearchableTextMap(List<_MenuItemSeed> items) {
  return <String, String>{
    for (final item in items) item.id: _buildSearchableText(item),
  };
}

List<_MenuItemSeed> _generateItems(int count, Random random) {
  const arabicWords = <String>[
    'قهوة',
    'بارد',
    'حار',
    'لاتيه',
    'اسبريسو',
    'شاي',
    'مشروب',
    'فطور',
    'غداء',
    'عصير',
    'ليمون',
    'تفاح',
    'كراميل',
    'فانيلا',
    'حليب',
    'منيو',
  ];

  const englishWords = <String>[
    'coffee',
    'latte',
    'cold',
    'hot',
    'menu',
    'vanilla',
    'caramel',
    'juice',
    'breakfast',
    'tea',
    'milk',
    'espresso',
  ];

  String pick(List<String> words, int minWords, int maxWords) {
    final wordCount = minWords + random.nextInt(maxWords - minWords + 1);
    final buffer = StringBuffer();
    for (var i = 0; i < wordCount; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(words[random.nextInt(words.length)]);
    }
    return buffer.toString();
  }

  return List<_MenuItemSeed>.generate(count, (index) {
    return _MenuItemSeed(
      id: 'item_$index',
      nameAr: pick(arabicWords, 2, 4),
      nameEn: pick(englishWords, 1, 3),
      descriptionAr: pick(arabicWords, 5, 10),
    );
  });
}

void _runBenchmarkForCount({
  required int itemCount,
  required Random random,
  int warmupRuns = 30,
  int measuredRuns = 400,
}) {
  final items = _generateItems(itemCount, random);

  for (var i = 0; i < warmupRuns; i++) {
    _buildSearchableTextMap(items);
  }

  final durationsUs = <int>[];

  for (var i = 0; i < measuredRuns; i++) {
    final stopwatch = Stopwatch()..start();
    _buildSearchableTextMap(items);
    stopwatch.stop();
    durationsUs.add(stopwatch.elapsedMicroseconds);
  }

  durationsUs.sort();

  final sum = durationsUs.fold<int>(0, (a, b) => a + b);
  final avg = sum / durationsUs.length;
  final p50 = durationsUs[(durationsUs.length * 0.50).floor()];
  final p95 = durationsUs[(durationsUs.length * 0.95).floor()];
  final p99 = durationsUs[(durationsUs.length * 0.99).floor()];
  final min = durationsUs.first;
  final max = durationsUs.last;

  stdout.writeln(
    '[menu_perf] searchable_map '
    'items=$itemCount '
    'runs=$measuredRuns '
    'avg=${avg.toStringAsFixed(1)}us '
    'p50=${p50}us '
    'p95=${p95}us '
    'p99=${p99}us '
    'min=${min}us '
    'max=${max}us',
  );
}

void main() {
  final random = Random(42);
  const itemCounts = <int>[100, 200, 500, 1000];

  stdout.writeln('[menu_perf] benchmark_start');
  for (final itemCount in itemCounts) {
    _runBenchmarkForCount(itemCount: itemCount, random: random);
  }
  stdout.writeln('[menu_perf] benchmark_end');
}

