import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/core/local/app_translation.dart';
import 'package:washup_owner/core/local/manage_translation.dart';

void main() {
  test('both languages have the same keys', () {
    expect(manageAr.keys.toSet(), manageEn.keys.toSet());
  });

  test('both languages name the same parameters', () {
    final parameter = RegExp(r'@[a-zA-Z]+');
    for (final key in manageAr.keys) {
      Set<String?> names(String text) => parameter.allMatches(text).map((m) => m.group(0)).toSet();
      expect(names(manageAr[key]!), names(manageEn[key]!), reason: key);
    }
  });

  test('every key the screens use exists', () {
    final keys = AppTranslations().keys;
    final known = {...keys['ar']!.keys};
    final used = RegExp(r"'([a-zA-Z]+\.[^' ]+)'\.(?:tr|trParams)\b");
    final missing = <String>[];
    final files = Directory('lib/features/manage')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      for (final match in used.allMatches(file.readAsStringSync())) {
        final key = match.group(1)!;
        final dollar = key.indexOf(r'$');
        final found = dollar < 0
            ? known.contains(key)
            : known.any((k) => k.startsWith(key.substring(0, dollar)));
        if (!found) missing.add('${file.path}: $key');
      }
    }
    expect(missing, isEmpty);
  });
}
