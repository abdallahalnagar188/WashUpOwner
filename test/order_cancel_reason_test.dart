import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup_owner/commons/models/order.dart';
import 'package:washup_owner/core/local/app_translation.dart';
import 'package:washup_owner/features/orders/presentation/pages/order_details_page.dart';

OrderDetails order(Map<String, dynamic>? cancel) => OrderDetails.fromJson({
      'order': {
        'id': 'ord_1',
        'status': 'cancelled',
        'paymentStatus': 'pending',
        'scheduledAt': '2026-10-23T11:30:00.000Z',
        if (cancel != null) 'cancel': cancel,
      },
    });

void main() {
  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('ar');
  });

  test('reads the reason from the order', () {
    final details = order({
      'reason': 'expired_unconfirmed',
      'byType': 'system',
      'byId': 'auto_close',
      'at': '2026-10-28T10:50:00.082Z',
    });

    expect(details.cancelReason, 'expired_unconfirmed');
  });

  test('an order without a cancellation has no reason', () {
    expect(order(null).cancelReason, isNull);
  });

  test('codes read as sentences', () {
    expect(cancelReasonText('expired_unconfirmed'), 'أُلغي تلقائيًا لأن المغسلة لم تؤكد في الوقت المحدد');
    expect(cancelReasonText('expired_not_started'), 'أُلغي تلقائيًا لأن الخدمة لم تبدأ في الوقت المحدد');
    expect(cancelReasonText('cancel.r1'), 'تغيّرت الخطة');
  });

  test('a reason staff typed stays as it is', () {
    expect(cancelReasonText('العميل اعتذر'), 'العميل اعتذر');
  });
}
