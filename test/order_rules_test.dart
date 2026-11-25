import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/order.dart';
import 'package:washup_owner/core/helpers/form_rules.dart';

void main() {
  group('payment methods (GAP-043)', () {
    test('only what collect_payment accepts', () {
      expect(FormRules.paymentMethods, ['cash', 'card']);
      expect(FormRules.paymentMethods, isNot(contains('online')));
    });
  });

  group('server minimums (GAP-080)', () {
    test('reasons need 3 characters, notes 2, review reports 5', () {
      expect(FormRules.validReason('ab'), isFalse);
      expect(FormRules.validReason(' abc '), isTrue);
      expect(FormRules.validReason('ab', min: FormRules.noteMin), isTrue);
      expect(FormRules.validReason('abcd', min: FormRules.reviewTextMin), isFalse);
      expect(FormRules.validReason('abcde', min: FormRules.reviewTextMin), isTrue);
    });

    test('the plate is counted without spaces and dashes', () {
      expect(FormRules.validPlate('A 1'), isFalse);
      expect(FormRules.validPlate('A-1'), isFalse);
      expect(FormRules.validPlate('ABC'), isTrue);
      expect(FormRules.validPlate('أ ب 1'), isTrue);
    });

    test('a cancel reason may not read like a code', () {
      expect(FormRules.looksLikeCode('customer_request'), isTrue);
      expect(FormRules.looksLikeCode('cancel.r1'), isTrue);
      expect(FormRules.validCancelReason('customer_request'), isFalse);
      expect(FormRules.validCancelReason('Customer asked to cancel'), isTrue);
      expect(FormRules.validCancelReason('العميل اعتذر'), isTrue);
    });
  });

  group('discount preview (GAP-082)', () {
    test('a percent is of the subtotal and rounds to whole units', () {
      final preview = DiscountPreview.of(type: 'percent', value: 15, subtotal: 199)!;
      expect(preview.pct, 15);
      expect(preview.amount, 30); // 29.85 rounds up, like Math.round on the server
    });

    test('a fixed amount is capped at the subtotal', () {
      final preview = DiscountPreview.of(type: 'fixed', value: 500, subtotal: 200)!;
      expect(preview.amount, 200);
      expect(preview.pct, 100);
      expect(DiscountPreview.of(type: 'fixed', value: 50, subtotal: 200)!.pct, 25);
    });

    test('the limit is checked against the subtotal, not the total after an offer', () {
      // Subtotal 200, an offer brought the total to 100: 40 off is 20% of the subtotal.
      final preview = DiscountPreview.of(type: 'fixed', value: 40, subtotal: 200)!;
      expect(preview.pct, 20);
    });

    test('nothing for an empty value', () {
      expect(DiscountPreview.of(type: 'percent', value: 0, subtotal: 100), isNull);
    });
  });
}
