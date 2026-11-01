import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FormatHelper {
  FormatHelper._();

  static final NumberFormat _number = NumberFormat('#,##0.##', 'en');

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    final value = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return value.isEmpty ? '؟' : value;
  }

  static String number(num value) => _number.format(value);

  static String money(num value) => '${number(value)} ${'common.egp'.tr}';

  static String time(DateTime at) =>
      DateFormat('h:mm a', Get.locale?.languageCode ?? 'ar').format(at.toLocal());
}
