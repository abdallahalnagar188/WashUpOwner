import 'package:flutter/services.dart';

/// Digits with one optional decimal point, so 29.5 stays 29.5. Arabic digits
/// and separators from the phone's keyboard become plain ones first.
class AmountInputFormatter extends TextInputFormatter {
  static final RegExp _shape = RegExp(r'^\d*\.?\d{0,3}$');

  const AmountInputFormatter();

  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30);
      } else if (rune == 0x066B || rune == 0x2C) {
        buffer.write('.');
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = normalize(newValue.text);
    if (!_shape.hasMatch(text)) return oldValue;
    return newValue.copyWith(text: text);
  }
}

const List<TextInputFormatter> amountInput = [AmountInputFormatter()];

const TextInputType amountKeyboard = TextInputType.numberWithOptions(decimal: true);

/// The number in an amount field, null while it is empty or half typed.
num? parseAmount(String text) => num.tryParse(AmountInputFormatter.normalize(text).trim());
