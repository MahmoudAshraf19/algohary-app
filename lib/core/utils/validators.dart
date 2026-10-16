/// Small, dependency-free input validators shared across the app.
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );

  /// Returns `true` when [value] (after trimming) looks like a valid e-mail.
  static bool isValidEmail(String? value) {
    if (value == null) return false;
    return _emailRegExp.hasMatch(value.trim());
  }

  /// Converts Arabic-Indic / Persian digits and the Arabic decimal separator to
  /// their ASCII equivalents so `double.tryParse` works for Arabic keyboards.
  static String normalizeDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final a = arabic.indexOf(ch);
      final p = persian.indexOf(ch);
      if (a >= 0) {
        buffer.write(a);
      } else if (p >= 0) {
        buffer.write(p);
      } else if (ch == '٫' || ch == '،' || ch == ',') {
        buffer.write('.');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }
}
