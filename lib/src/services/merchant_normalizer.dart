/// Extracts the merchant / counterparty name out of a Santander description.
///
/// Raw descriptions are mostly noise around one useful name — the card
/// number, the city, the invoice reference, the transfer concept:
///
///   `PAGO MOVIL EN CONSUM V. F.CAT, VALENCIA ES, TARJ. :*247394`  -> `CONSUM V. F.CAT`
///   `RECIBO DIGI SPAIN TELECOM SA, concepto: FACTURA DIGI`        -> `DIGI SPAIN TELECOM SA`
///   `TRANSFERENCIA INMEDIATA A FAVOR DE Ana CONCEPTO Rent`        -> `Ana`
///
/// This is what the "exact name" rule scope compares, so two purchases at
/// the same shop group together even though their raw text differs.
class MerchantNormalizer {
  const MerchantNormalizer();

  String merchantOf(String description) {
    final text = description.trim();
    for (final pattern in _patterns) {
      final name = pattern.firstMatch(text)?.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    // Unknown shape: everything up to the first comma, capped so a long
    // free-text description doesn't become an unreadable "name".
    final head = text.split(',').first.trim();
    return head.length > 60 ? head.substring(0, 60).trim() : head;
  }

  static const _tail = r'(?:\s*,|\s+CONCEPTO\b|\s+concepto\b|$)';

  // Order matters: the more specific "COMPRA BIZUM" / "COMPRA INTERNET EN"
  // shapes must be tried before the generic "COMPRA".
  static final _patterns = <RegExp>[
    RegExp(r'^PAGO MOVIL EN\s+(.+?)\s*,', caseSensitive: false),
    RegExp(r'^COMPRA INTERNET EN\s+(.+?)\s*,', caseSensitive: false),
    RegExp(
      r'^COMPRA BIZUM\s+(.+?)(?:\s+\d{2}/\d{2}/\d{4})?\s*$',
      caseSensitive: false,
    ),
    RegExp(r'^COMPRA\s+(.+?)\s*,', caseSensitive: false),
    RegExp(
      r'^RECIBO\s+(.+?)(?:\s*,|\s+N\S{0,2}\s+RECIBO|\s+REF\b|$)',
      caseSensitive: false,
    ),
    RegExp(
      '^TRANSFERENCIA(?: INMEDIATA)? A FAVOR DE\\s+(.+?)$_tail',
      caseSensitive: false,
    ),
    RegExp('^TRANSFERENCIA DE\\s+(.+?)$_tail', caseSensitive: false),
    RegExp('^BIZUM (?:A FAVOR DE|DE)\\s+(.+?)$_tail', caseSensitive: false),
    RegExp(
      '^(RETIRADA DE EFECTIVO EN CAJERO AUTOMATICO)',
      caseSensitive: false,
    ),
  ];
}
