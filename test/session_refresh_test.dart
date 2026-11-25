import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washup_owner/commons/models/owner_account.dart';
import 'package:washup_owner/core/data/vendor_api.dart';
import 'package:washup_owner/core/local/cache_controller.dart';
import 'package:washup_owner/core/services/session_service.dart';

import 'helpers/fake_server.dart';

Map<String, dynamic> me(String branchName, {String role = 'owner'}) => {
      'id': 'st_1',
      'name': 'Owner',
      'role': role,
      'businessStatus': 'active',
      'branches': [
        {'id': 'br_1', 'name': {'ar': branchName, 'en': branchName}, 'active': true, 'capacity': 3},
      ],
      'permissions': <String, bool>{},
    };

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheController().initSharedPreferences();
  });

  test('re-reads the account after an edit (GAP-083)', () async {
    var name = 'Old';
    final server = FakeServer((_) => FakeReply.ok(me(name)));
    final tokens = MemoryTokens(access: 'a');
    final session = SessionService(VendorApi(fakeClient(server, tokens), tokens));
    session.account.value = OwnerAccount.fromJson(me('Old'));

    name = 'New';
    await session.refreshAccount();

    expect(session.account.value!.branches.single.name.ar, 'New');
    expect(server.requests.single.path, '/vendor/auth/me');
  });

  test('a failed refresh keeps the account on screen', () async {
    final server = FakeServer((_) => FakeReply.error(500, 'down'));
    final tokens = MemoryTokens(access: 'a');
    final session = SessionService(VendorApi(fakeClient(server, tokens), tokens));
    session.account.value = OwnerAccount.fromJson(me('Old'));

    await session.refreshAccount();

    expect(session.account.value!.branches.single.name.ar, 'Old');
  });

  test('nothing is fetched without a signed-in account', () async {
    final server = FakeServer((_) => FakeReply.ok(me('X')));
    final tokens = MemoryTokens();
    final session = SessionService(VendorApi(fakeClient(server, tokens), tokens));

    await session.refreshAccount();

    expect(server.requests, isEmpty);
    expect(session.suspended, isFalse);
  });
}
