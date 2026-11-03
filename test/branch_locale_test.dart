import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:washup_owner/commons/models/branch_locale.dart';
import 'package:washup_owner/core/helpers/format_helper.dart';

void main() {
  const cairo = BranchLocale(symbol: 'ج.م', decimals: 2, timezone: 'Africa/Cairo');
  const kuwait = BranchLocale(symbol: 'د.ك', decimals: 3, timezone: 'Asia/Kuwait');
  const dubai = BranchLocale(symbol: 'د.إ', decimals: 2, timezone: 'Asia/Dubai');

  setUpAll(() async {
    await initializeDateFormatting('en');
    Get.locale = const Locale('en');
  });

  test('reads branchLocale and the auth/me branch fields', () {
    final row = BranchLocale.fromJson({'symbol': 'د.ك', 'decimals': 3, 'timezone': 'Asia/Kuwait'})!;
    expect([row.symbol, row.decimals, row.timezone], ['د.ك', 3, 'Asia/Kuwait']);
    final branch = BranchLocale.fromBranchJson({'currencySymbol': 'ر.س', 'currencyDecimals': 2, 'timezone': 'Asia/Riyadh'})!;
    expect(branch.symbol, 'ر.س');
    expect(BranchLocale.fromJson(null), isNull);
  });

  test('money follows the currency and its decimals', () {
    expect(FormatHelper.money(1250.5, locale: cairo), '1,250.5 ج.م');
    expect(FormatHelper.money(1.125, locale: kuwait), '1.125 د.ك');
    expect(FormatHelper.money(1.1255, locale: cairo), '1.13 ج.م');
  });

  test('times use the branch clock, not the phone', () {
    final at = DateTime.utc(2026, 11, 3, 8, 0);
    expect(FormatHelper.time(at, locale: dubai), '12:00 PM');
    expect(FormatHelper.time(at, locale: kuwait), '11:00 AM');
    // Egypt is on winter time in November and summer time in July.
    expect(FormatHelper.time(at, locale: cairo), '10:00 AM');
    expect(FormatHelper.time(DateTime.utc(2026, 7, 1, 8), locale: cairo), '11:00 AM');
  });

  test('a time picked on the phone is shown as it is', () {
    expect(FormatHelper.time(DateTime(2026, 11, 3, 9, 30), locale: dubai), '9:30 AM');
  });
}
