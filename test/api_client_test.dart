import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/order.dart';
import 'package:washup_owner/core/data/vendor_api.dart';
import 'package:washup_owner/core/network/api_client.dart';

import 'helpers/fake_server.dart';

void main() {
  test('sends the token and unwraps data', () async {
    final server = FakeServer((_) => FakeReply.ok({'x': 1}));
    final client = fakeClient(server, MemoryTokens(access: 'a1'));

    final data = await client.get('/vendor/setup');

    expect(data, {'x': 1});
    expect(server.requests.single.auth, 'Bearer a1');
  });

  test('leaves out empty values and "all"', () async {
    final server = FakeServer((_) => FakeReply.ok(null));
    final client = fakeClient(server, MemoryTokens());

    await client.get('/vendor/orders', query: {'branchId': 'all', 'tab': 'paid', 'q': '', 'x': null});

    expect(server.requests.single.query, {'tab': 'paid'});
  });

  test('refreshes once on 401 and retries with the new token', () async {
    final tokens = MemoryTokens(access: 'old', refresh: 'r1');
    final server = FakeServer((request) {
      if (request.path == '/vendor/auth/refresh') {
        return FakeReply.ok({'access_token': 'new', 'refresh_token': 'r2'});
      }
      return request.auth == 'Bearer new' ? FakeReply.ok('fine') : FakeReply.error(401, 'expired');
    });
    final client = fakeClient(server, tokens);

    final results = await Future.wait([client.get('/vendor/live'), client.get('/vendor/setup')]);

    expect(results, ['fine', 'fine']);
    expect(tokens.access, 'new');
    expect(tokens.refresh, 'r2');
    expect(server.requests.where((r) => r.path == '/vendor/auth/refresh').length, 1,
        reason: 'two 401s must share one refresh');
  });

  test('a refused refresh ends the session', () async {
    var expired = 0;
    final server = FakeServer((_) => FakeReply.error(401, 'no'));
    final client = fakeClient(server, MemoryTokens(access: 'a', refresh: 'r'))
      ..onSessionExpired = () => expired++;

    await expectLater(client.get('/vendor/live'), throwsA(isA<ApiException>()));

    expect(expired, 1);
  });

  test('a server refusal shows the server message', () async {
    final server = FakeServer((_) => FakeReply.error(422, 'خدمة غير موجودة في هذا الفرع'));
    final client = fakeClient(server, MemoryTokens());

    await expectLater(
      client.get('/vendor/availability'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'خدمة غير موجودة في هذا الفرع')),
    );
  });

  test('login keeps both tokens and reads the account', () async {
    final tokens = MemoryTokens();
    final server = FakeServer(
      (_) => FakeReply.ok({
        'access_token': 'a',
        'refresh_token': 'r',
        'account': {
          'id': 'st_1',
          'name': 'Owner',
          'role': 'owner',
          'permissions': {'refund': true},
          'branches': [],
        },
      }),
    );
    final api = VendorApi(fakeClient(server, tokens), tokens);

    final account = await api.login(phone: '01000000000', password: 'x');

    expect(account.role, 'owner');
    expect(tokens.access, 'a');
    expect(server.requests.single.body, {'phone': '01000000000', 'password': 'x'});
  });

  test('order actions post the action key with its fields', () async {
    final server = FakeServer((_) => FakeReply.ok(null));
    final api = VendorApi(fakeClient(server, MemoryTokens()), MemoryTokens());

    await api.runAction('ord_1', OrderAction.collectPayment, {'method': 'cash', 'amountReceived': 29.5});

    final request = server.requests.single;
    expect(request.path, '/vendor/orders/ord_1/actions');
    expect(request.body, {'action': 'collect_payment', 'method': 'cash', 'amountReceived': 29.5});
  });
}
