import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup_owner/commons/models/audit_entry.dart';
import 'package:washup_owner/core/local/app_translation.dart';
import 'package:washup_owner/features/manage/audit/audit_format.dart';

AuditEntry entry(String? oldValue, String? newValue) => AuditEntry.fromJson({
      'id': 'a1',
      'action': 'service.update',
      'oldValue': oldValue,
      'newValue': newValue,
    });

void main() {
  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('ar');
  });

  test('a stored object shows only the fields that changed', () {
    final changes = AuditFormat.changes(entry(
      '{"name":"غسيل","price":120,"durationMin":25,"active":true}',
      '{"name":"غسيل","price":150,"durationMin":25,"active":false}',
    ));

    expect(changes.length, 2);
    expect(changes[0].label, 'السعر');
    expect(changes[0].from, '120 ج.م');
    expect(changes[0].to, '150 ج.م');
    expect(changes[1].from, 'مفعّل');
    expect(changes[1].to, 'موقوف');
  });

  test('status words are translated', () {
    final change = AuditFormat.changes(entry('in_service', 'completed')).single;

    expect(change.from, 'جارٍ التنفيذ');
    expect(change.to, 'مكتمل');
  });

  test('joined values translate word by word', () {
    final change = AuditFormat.changes(entry('pending', 'paid · 96 · cash')).single;

    expect(change.to, 'مدفوع · 96 · نقدي');
  });

  test('a field with no label is left out', () {
    final changes = AuditFormat.changes(entry('{"internalFlag":1}', '{"internalFlag":2}'));

    expect(changes, isEmpty);
  });

  test('broken JSON still shows as text', () {
    final change = AuditFormat.changes(entry(null, '{not json')).single;

    expect(change.to, '{not json');
  });
}
