import 'dart:convert';

import 'package:get/get.dart';

import '../../../commons/models/audit_entry.dart';
import '../../../core/helpers/format_helper.dart';

/// One readable change, like the price going from 120 to 150. [from] is null
/// when the entry only records a new value.
class AuditChange {
  final String? label;
  final String? from;
  final String? to;

  const AuditChange({this.label, this.from, this.to});
}

/// Turns the raw values the server stores into text an owner can read. Keys
/// with no translation are left out rather than shown as code.
class AuditFormat {
  AuditFormat._();

  static const Set<String> _moneyFields = {'price', 'amount', 'total', 'discountValue'};
  static const Set<String> _hiddenFields = {'id', 'branchId', 'businessId', 'updatedAt', 'createdAt'};

  static List<AuditChange> changes(AuditEntry entry) {
    final oldValue = _decode(entry.oldValue);
    final newValue = _decode(entry.newValue);
    if (oldValue is Map || newValue is Map) {
      return _mapChanges(
        oldValue is Map ? oldValue : const {},
        newValue is Map ? newValue : const {},
      );
    }
    final from = _plain(oldValue);
    final to = _plain(newValue);
    if (from == null && to == null) return const [];
    if (from == to) return [AuditChange(to: to)];
    return [AuditChange(from: from, to: to)];
  }

  static dynamic _decode(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return jsonDecode(trimmed);
      } on FormatException {
        return trimmed;
      }
    }
    return trimmed;
  }

  static List<AuditChange> _mapChanges(Map<dynamic, dynamic> oldMap, Map<dynamic, dynamic> newMap) {
    final result = <AuditChange>[];
    for (final key in {...oldMap.keys, ...newMap.keys}) {
      final field = key.toString();
      final oldItem = oldMap[key];
      final newItem = newMap[key];
      if (_hiddenFields.contains(field) || _same(oldItem, newItem)) continue;
      final labelKey = 'audit.field.$field';
      if (labelKey.tr == labelKey) continue;
      result.add(
        AuditChange(
          label: labelKey.tr,
          from: _fieldValue(field, oldItem),
          to: _fieldValue(field, newItem),
        ),
      );
    }
    return result;
  }

  static bool _same(dynamic a, dynamic b) => jsonEncode(a) == jsonEncode(b);

  static String? _fieldValue(String field, dynamic value) {
    if (value == null) return null;
    if (value is bool) return (value ? 'audit.on' : 'audit.off').tr;
    if (value is num) return _moneyFields.contains(field) ? FormatHelper.money(value) : FormatHelper.number(value);
    if (value is Map) {
      final shown = (Get.locale?.languageCode == 'en' ? value['en'] : value['ar']) ?? value['ar'];
      return shown?.toString() ?? 'audit.changed'.tr;
    }
    if (value is List) return 'audit.changed'.tr;
    return _word(value.toString());
  }

  /// Text values such as `paid · 96 · cash`, one known word at a time.
  static String? _plain(dynamic value) {
    if (value == null) return null;
    return value.toString().split(' · ').map(_word).join(' · ');
  }

  static String _word(String word) {
    for (final prefix in const ['status.', 'pay.', 'method.', 'source.']) {
      final key = '$prefix$word';
      if (key.tr != key) return key.tr;
    }
    return word;
  }
}
