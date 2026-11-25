import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/core/data/vendor_api.dart';
import 'package:washup_owner/core/network/api_client.dart';
import 'package:washup_owner/features/more/presentation/widgets/change_password_sheet.dart';

import 'helpers/fake_server.dart';

void main() {
  group('change password (GAP-044)', () {
    test('renews the session, then sends both passwords', () async {
      final server = FakeServer((request) => request.path == '/vendor/auth/change-password'
          ? const FakeReply(200, {'status': true, 'message': 'تم تغيير كلمة المرور', 'data': null})
          : FakeReply.ok({'id': 'st_1'}));
      final tokens = MemoryTokens(access: 'a', refresh: 'r');
      final api = VendorApi(fakeClient(server, tokens), tokens);

      final outcome = await api.changePassword(currentPassword: 'old-pass', newPassword: 'new-pass-1');

      expect(outcome, 'تم تغيير كلمة المرور');
      expect(server.requests.map((r) => r.path), ['/vendor/auth/me', '/vendor/auth/change-password']);
      expect(server.requests.last.body, {'currentPassword': 'old-pass', 'newPassword': 'new-pass-1'});
    });

    test('a wrong current password is shown, not treated as an expired session', () async {
      final server = FakeServer((request) => request.path == '/vendor/auth/change-password'
          ? FakeReply.error(401, 'كلمة المرور الحالية غير صحيحة')
          : FakeReply.ok({'id': 'st_1'}));
      final tokens = MemoryTokens(access: 'a', refresh: 'r');
      final client = fakeClient(server, tokens);
      var expired = false;
      client.onSessionExpired = () => expired = true;

      await expectLater(
        VendorApi(client, tokens).changePassword(currentPassword: 'wrong', newPassword: 'new-pass-1'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'كلمة المرور الحالية غير صحيحة')),
      );
      expect(server.requests.where((r) => r.path == '/vendor/auth/refresh'), isEmpty);
      expect(expired, isFalse);
      expect(tokens.access, 'a');
    });

    test('the form asks for 8 characters, a new value and a matching confirmation', () {
      expect(ChangePasswordSheet.problem(current: 'old-pass', next: 'short', repeat: ''), isNotNull);
      expect(ChangePasswordSheet.problem(current: 'same-pass', next: 'same-pass', repeat: 'same-pass'), isNotNull);
      expect(ChangePasswordSheet.problem(current: 'old-pass', next: 'new-pass-1', repeat: 'other'), isNotNull);
      expect(ChangePasswordSheet.problem(current: 'old-pass', next: 'new-pass-1', repeat: 'new-pass-1'), isNull);
    });
  });

  test('forgot password sends the phone and returns the neutral answer (GAP-044)', () async {
    final server = FakeServer((_) => const FakeReply(200, {'status': true, 'message': 'لو الرقم مسجل عندنا…', 'data': null}));
    final api = VendorApi(fakeClient(server, MemoryTokens()), MemoryTokens());

    expect(await api.forgotPassword(phone: '+201001234567'), 'لو الرقم مسجل عندنا…');
    expect(server.requests.single.path, '/vendor/auth/forgot-password');
    expect(server.requests.single.body, {'phone': '+201001234567'});
  });
}
