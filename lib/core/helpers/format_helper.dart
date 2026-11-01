import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FormatHelper {
  FormatHelper._();

  static final NumberFormat _number = NumberFormat('#,##0.##', 'en');
  static final NumberFormat _plain = NumberFormat('0.##', 'en');

  static String get _lang => Get.locale?.languageCode ?? 'ar';

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

  /// For prefilling inputs: no thousands separator.
  static String plain(num value) => _plain.format(value);

  static String money(num value) => '${number(value)} ${'common.egp'.tr}';

  static String time(DateTime at) => DateFormat('h:mm a', _lang).format(at.toLocal());

  static String shortDay(DateTime at) => DateFormat('EEE d/M', _lang).format(at.toLocal());

  /// Today's orders show the time alone; other days add the date.
  static String dayTime(DateTime at) {
    final local = at.toLocal();
    return DateUtils.isSameDay(local, DateTime.now()) ? time(local) : '${shortDay(local)} · ${time(local)}';
  }
}
