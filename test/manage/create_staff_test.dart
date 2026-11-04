import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/core/data/vendor_manage_api.dart';

import '../helpers/fake_server.dart';

Future<String?> create(String message) {
  final server = FakeServer((_) => FakeReply(201, {'status': true, 'message': message, 'data': {'id': 'st_1'}}));
  return VendorManageApi(fakeClient(server, MemoryTokens())).createStaff(
    name: 'Worker',
    phone: '01000000001',
    role: 'employee',
    branchId: 'br_1',
    maxDiscountPct: 5,
    permissions: const {},
  );
}

void main() {
  test('reads the temporary password out of the reply message', () async {
    expect(await create('تمت إضافة الموظف. كلمة المرور المؤقتة Ab12cd'), 'Ab12cd');
    // The live server writes a colon and a note after it.
    expect(
      await create('تمت إضافة الموظف. كلمة المرور المؤقتة: Xy9-kLm2 (أرسلها لصاحب الحساب، تظهر مرة واحدة فقط)'),
      'Xy9-kLm2',
    );
  });

  test('a message without a password returns null', () async {
    expect(await create('تمت الإضافة'), isNull);
  });
}
