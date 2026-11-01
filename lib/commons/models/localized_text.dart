import 'package:get/get.dart';

class LocalizedText {
  final String ar;
  final String en;

  const LocalizedText(this.ar, this.en);

  String get value => (Get.locale?.languageCode ?? 'ar') == 'ar' ? ar : en;

  factory LocalizedText.fromJson(dynamic json) {
    if (json is Map) {
      return LocalizedText(
        json['ar']?.toString() ?? '',
        json['en']?.toString() ?? '',
      );
    }
    final text = json?.toString() ?? '';
    return LocalizedText(text, text);
  }

  @override
  String toString() => value;
}
