import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../commons/models/branch_locale.dart';
import '../services/session_service.dart';

class FormatHelper {
  FormatHelper._();

  static final NumberFormat _number = NumberFormat('#,##0.##', 'en');
  static final NumberFormat _plain = NumberFormat('0.###', 'en');

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

  /// The working branch's, for screens that show no single order.
  static BranchLocale? get _working =>
      Get.isRegistered<SessionService>() ? Get.find<SessionService>().localeOf() : null;

  /// [value] in the branch's currency, with as many decimals as it uses.
  static String money(num value, {BranchLocale? locale}) {
    final current = locale ?? _working;
    if (current == null) return '${number(value)} ${'common.egp'.tr}';
    final format = NumberFormat('#,##0', 'en')
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = current.decimals;
    return '${format.format(value)} ${current.symbol}';
  }

  /// [at] on the branch's clock, not the phone's.
  static DateTime _wall(DateTime at, BranchLocale? locale) {
    final current = locale ?? _working;
    return current == null ? at.toLocal() : current.wallClock(at);
  }

  static String time(DateTime at, {BranchLocale? locale}) =>
      DateFormat('h:mm a', _lang).format(_wall(at, locale));

  static String shortDay(DateTime at, {BranchLocale? locale}) =>
      DateFormat('EEE d/M', _lang).format(_wall(at, locale));

  /// Today's orders show the time alone; other days add the date.
  static String dayTime(DateTime at, {BranchLocale? locale}) {
    final wall = _wall(at, locale);
    final today = _wall(DateTime.now().toUtc(), locale);
    return DateUtils.isSameDay(wall, today) ? time(wall) : '${shortDay(wall)} · ${time(wall)}';
  }
}
