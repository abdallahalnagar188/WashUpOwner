import 'dart:convert';

/// Tolerant readers for API replies: a missing or oddly typed field falls back
/// instead of throwing, so one bad row cannot take a whole screen down.
num readNum(dynamic value, [num fallback = 0]) => readNumOrNull(value) ?? fallback;

num? readNumOrNull(dynamic value) {
  if (value is num) return value;
  return value == null ? null : num.tryParse(value.toString());
}

int readInt(dynamic value, [int fallback = 0]) => readNumOrNull(value)?.toInt() ?? fallback;

bool readBool(dynamic value) => value == true;

String readStr(dynamic value) => value?.toString() ?? '';

/// Null for a missing or blank value, so callers can leave the row out.
String? readStrOrNull(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

/// Audit values may be text, numbers or whole objects.
String? readAnyText(dynamic value) {
  if (value == null) return null;
  if (value is Map || value is List) return jsonEncode(value);
  return readStrOrNull(value);
}

DateTime? readDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

Map<String, dynamic> readMap(dynamic value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), item))
    : <String, dynamic>{};

List<Map<String, dynamic>> readMaps(dynamic value) =>
    value is List ? value.whereType<Map>().map(readMap).toList() : [];

List<String> readStrings(dynamic value) =>
    value is List ? value.where((item) => item != null).map((item) => item.toString()).toList() : [];

List<int> readInts(dynamic value) =>
    value is List ? value.map((item) => readNumOrNull(item)?.toInt()).whereType<int>().toList() : [];

Map<String, int> readCounts(dynamic value) => {
      for (final entry in readMap(value).entries) entry.key: readInt(entry.value),
    };

Map<String, bool> readFlags(dynamic value) => {
      for (final entry in readMap(value).entries) entry.key: entry.value == true,
    };
