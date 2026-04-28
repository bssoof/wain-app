import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no .dart file in lib/ contains mojibake artifacts', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory must exist');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    // Known mojibake patterns (UTF-8 double/triple-encoding artifacts)
    final mojibakePatterns = <String, RegExp>{
      'garbled em-dash (â€")': RegExp(
        r'\u00e2\u20ac[\u201c\u201d\u0093\u0094]',
      ),
      'garbled box-drawing (â"€)': RegExp(r'\u00e2\u201e\u20ac'),
      'triple-encoded Arabic (Ø·)': RegExp(r'[\u00d8][\u00a7-\u00b7]'),
      'replacement character (U+FFFD)': RegExp(r'\uFFFD'),
      'suspicious Arabic mojibake': RegExp(r'[\u0600-\u06FF][\u00A0-\u00FF]'),
    };

    final failures = <String>[];

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final entry in mojibakePatterns.entries) {
        if (entry.value.hasMatch(content)) {
          failures.add('${entry.key} found in ${file.path}');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'Mojibake detected in lib/:\n${failures.join('\n')}',
    );
  });

  test('no .arb file contains mojibake artifacts', () {
    final l10nDir = Directory('lib/l10n');
    if (!l10nDir.existsSync()) return;

    final arbFiles = l10nDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.arb'),
    );

    final suspiciousMojibake = RegExp(r'[\u0600-\u06FF][\u00A0-\u00FF]|\uFFFD');

    for (final file in arbFiles) {
      final content = file.readAsStringSync();
      expect(
        suspiciousMojibake.hasMatch(content),
        isFalse,
        reason: 'Mojibake found in ${file.path}',
      );
    }
  });
}
