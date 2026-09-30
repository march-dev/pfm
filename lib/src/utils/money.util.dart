/// Formats integer cents the way Santander prints them: `.` thousands,
/// `,` decimals, currency symbol last — `-1.300,00€`. [showSign] adds an
/// explicit `+` to positive amounts (for a statement-style amount column).
String formatCents(int cents, {bool showSign = false, String currency = 'EUR'}) {
  final absolute = cents.abs();
  final units = (absolute ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  final symbol = currency == 'EUR' ? '€' : ' $currency';
  final sign = cents < 0
      ? '-'
      : showSign && cents > 0
          ? '+'
          : '';
  return '$sign$units,$fraction$symbol';
}
