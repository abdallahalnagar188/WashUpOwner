/// The minimums the vendor server enforces, so a form refuses what the server
/// would refuse instead of sending it and showing a 422 (GAP-080).
class FormRules {
  FormRules._();

  /// Cancel, refund, discount and block reasons (`requireReason` / `requireText`).
  static const int reasonMin = 3;

  /// An order note (`note` action).
  static const int noteMin = 2;

  /// A plate after the server's normalising (spaces, dashes, dots and underscores removed).
  static const int plateMin = 3;

  /// Review replies and review reports (`requireText(…, 5)`).
  static const int reviewTextMin = 5;

  /// Payment methods `collect_payment` accepts (GAP-043): the server refuses `online`.
  static const List<String> paymentMethods = ['cash', 'card'];

  static final RegExp _plateNoise = RegExp(r'[\s\-_.]');
  static final RegExp _machineKey = RegExp(r'^[a-z0-9]+(?:[._][a-z0-9]+)+$', caseSensitive: false);
  static final RegExp _arabic = RegExp('[؀-ۿ]');

  /// The plate the way the server counts its length.
  static String plateKey(String plate) => plate.replaceAll(_plateNoise, '');

  static bool validPlate(String plate) => plateKey(plate.trim()).length >= plateMin;

  static bool validReason(String text, {int min = reasonMin}) => text.trim().length >= min;

  /// The server refuses a cancel reason that reads like a code (`customer_request`),
  /// so the customer never sees one.
  static bool looksLikeCode(String text) {
    final value = text.trim();
    return _machineKey.hasMatch(value) && !_arabic.hasMatch(value);
  }

  static bool validCancelReason(String text) => validReason(text) && !looksLikeCode(text);
}
