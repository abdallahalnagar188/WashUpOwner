import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/staff_member.dart';
import 'package:washup_owner/features/manage/common/widgets/amount_input.dart';
import 'package:washup_owner/features/manage/reports/controllers/reports_controller.dart';

String type(String before, String after) => const AmountInputFormatter()
    .formatEditUpdate(TextEditingValue(text: before), TextEditingValue(text: after))
    .text;

void main() {
  test('keeps decimals', () {
    expect(type('29', '29.'), '29.');
    expect(type('29.', '29.5'), '29.5');
    expect(type('29.5', '29.55'), '29.55');
    expect(parseAmount('29.5'), 29.5);
  });

  test('turns Arabic digits and separators into plain ones', () {
    expect(type('', '٢٩'), '29');
    expect(type('29', '29٫'), '29.');
    expect(type('29', '29,'), '29.');
    expect(type('', '۱۲'), '12');
    expect(parseAmount('١٢٫٥'), 12.5);
  });

  test('refuses anything else', () {
    expect(type('29', '29a'), '29');
    expect(type('29.5', '29.5.'), '29.5');
    expect(type('29.555', '29.5555'), '29.555');
    expect(parseAmount(''), isNull);
    expect(parseAmount('.'), isNull);
  });

  test('accepts Egyptian mobiles only', () {
    expect(StaffMember.validPhone('01001234567'), isTrue);
    expect(StaffMember.validPhone('+20 100 123 4567'), isTrue);
    expect(StaffMember.validPhone('1001234567'), isTrue);
    expect(StaffMember.validPhone('01301234567'), isFalse);
    expect(StaffMember.validPhone('0100123'), isFalse);
  });

  test('report ranges count back from today', () {
    final today = DateTime(2026, 11, 15);
    expect(ReportsController.datesFor('7d', today), ('2026-11-09', '2026-11-15'));
    expect(ReportsController.datesFor('14d', today), ('2026-11-02', '2026-11-15'));
    expect(ReportsController.datesFor('30d', today), ('2026-10-17', '2026-11-15'));
    expect(ReportsController.datesFor('month', today), ('2026-11-01', '2026-11-15'));
  });
}
