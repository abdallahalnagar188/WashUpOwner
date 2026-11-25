import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/staff_member.dart';
import 'package:washup_owner/core/data/vendor_manage_api.dart';

import '../helpers/fake_server.dart';

Future<NewStaffLogin> create(String message, {Map<String, dynamic> data = const {'id': 'st_1'}}) {
  final server = FakeServer((_) => FakeReply(201, {'status': true, 'message': message, 'data': data}));
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
    expect((await create('تمت إضافة الموظف. كلمة المرور المؤقتة Ab12cd')).password, 'Ab12cd');
    // The live server writes a colon and a note after it.
    expect(
      (await create('تمت إضافة الموظف. كلمة المرور المؤقتة: Xy9-kLm2 (أرسلها لصاحب الحساب، تظهر مرة واحدة فقط)')).password,
      'Xy9-kLm2',
    );
  });

  test('a structured field wins over the message (GAP-077)', () async {
    final login = await create(
      'كلمة المرور المؤقتة: fromText',
      data: {'id': 'st_1', 'tempPassword': 'fromField'},
    );
    expect(login.password, 'fromField');
    expect(
      (await create('تمت الإضافة', data: {'id': 'st_1', 'login': {'status': 'created', 'tempPassword': 'nested1'}})).password,
      'nested1',
    );
  });

  test('without a password the server reason is kept for the dialog', () async {
    final login = await create('تمت إضافة أحمد — هذا الرقم/البريد له حساب دخول آخر على Wash Up — تواصل مع الدعم لربطه');
    expect(login.password, isNull);
    expect(login.message, contains('حساب دخول آخر'));
    expect((await create('تمت الإضافة')).password, isNull);
  });
}
