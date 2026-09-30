import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/transaction.model.dart';
import '../utils/text.util.dart';
import 'xlsx_reader.dart';

class StatementFormatException implements Exception {
  const StatementFormatException(this.message);

  final String message;

  @override
  String toString() => 'StatementFormatException: $message';
}

class StatementParseResult {
  const StatementParseResult({
    required this.transactions,
    required this.skippedRows,
  });

  final List<TransactionModel> transactions;

  /// Non-blank rows under the header that couldn't be read as a transaction
  /// (no parseable date or amount).
  final int skippedRows;
}

/// Turns a Santander (ES) "account activity" export into transactions.
///
/// The sheet starts with an account summary (IBAN, holder, balance — which
/// this deliberately never reads) followed by the transaction table, whose
/// header row is located by its column titles rather than a fixed row
/// number, so a longer/shorter summary block doesn't break it. English and
/// Spanish titles are both accepted, since the app's export language
/// follows the user's Santander settings.
class SantanderStatementParser {
  const SantanderStatementParser({XlsxReader reader = const XlsxReader()})
      : _reader = reader;

  final XlsxReader _reader;

  StatementParseResult parse(Uint8List bytes) {
    try {
      return parseRows(_reader.readFirstSheet(bytes));
    } on XlsxFormatException catch (error) {
      throw StatementFormatException(error.message);
    }
  }

  StatementParseResult parseRows(List<List<String>> rows) {
    final header = _findHeader(rows);
    if (header == null) {
      throw const StatementFormatException(
        'No transaction table found: expected columns like '
        '"Transaction date", "Description" and "Amount".',
      );
    }

    final transactions = <TransactionModel>[];
    final seen = <String, int>{};
    var skipped = 0;

    for (var r = header.row + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((cell) => cell.isEmpty)) continue;

      final date = parseDate(header.cell(row, header.date));
      final amount = parseAmountCents(header.cell(row, header.amount));
      if (date == null || amount == null) {
        skipped++;
        continue;
      }

      final valueDate = parseDate(header.cell(row, header.valueDate));
      final description =
          header.cell(row, header.description).replaceAll(RegExp(r'\s+'), ' ');
      final balance = parseAmountCents(header.cell(row, header.balance));
      final currency = header.cell(row, header.currency);

      // Real duplicates are rare (the running balance differs even for two
      // identical purchases) but the counter keeps ids unique regardless.
      final baseKey = '${_iso(date)}|${valueDate == null ? '' : _iso(valueDate)}'
          '|$description|$amount|${balance ?? ''}';
      final occurrence = seen.update(baseKey, (n) => n + 1, ifAbsent: () => 0);

      transactions.add(
        TransactionModel(
          id: sha1
              .convert('$baseKey#$occurrence'.codeUnits)
              .toString()
              .substring(0, 20),
          date: date,
          valueDate: valueDate,
          description: description,
          amountCents: amount,
          balanceCents: balance,
          currency: currency.isEmpty ? 'EUR' : currency,
        ),
      );
    }

    return StatementParseResult(
      transactions: transactions,
      skippedRows: skipped,
    );
  }

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// `dd/MM/yyyy` (optionally followed by a time), or null.
  static DateTime? parseDate(String raw) {
    final match = RegExp(r'^\s*(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(raw);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // DateTime silently rolls 31/02 over to 03/03 — reject instead.
    return date.month == month && date.day == day ? date : null;
  }

  /// Parses `-1.300,00€`, `3.907,46€`, `2,204.68`, `-27.0` ... into cents,
  /// exactly (no floating point). Null when there's no number in [raw].
  static int? parseAmountCents(String raw) {
    var text = raw.replaceAll('−', '-'); // unicode minus
    final negative = text.contains('-');
    text = text.replaceAll(RegExp('[^0-9,.]'), '');
    if (text.isEmpty) return null;

    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');
    final separator = lastComma > lastDot ? lastComma : lastDot;

    String integerPart = text;
    var fraction = '';
    if (separator >= 0) {
      final digitsAfter = text.length - separator - 1;
      // 1-2 digits after the last separator is a decimal part; exactly 3
      // ("1.300") is a thousands group, as in Spanish formatting.
      if (digitsAfter >= 1 && digitsAfter <= 2) {
        integerPart = text.substring(0, separator);
        fraction = text.substring(separator + 1);
      }
    }
    integerPart = integerPart.replaceAll(RegExp('[.,]'), '');
    if (integerPart.isEmpty) integerPart = '0';

    final cents =
        int.parse(integerPart) * 100 + int.parse(fraction.padRight(2, '0'));
    return negative ? -cents : cents;
  }

  static _Header? _findHeader(List<List<String>> rows) {
    for (var r = 0; r < rows.length; r++) {
      final titles = [for (final cell in rows[r]) normalizeText(cell)];
      final date = _indexOf(titles, _dateTitles);
      final description = _indexOf(titles, _descriptionTitles);
      final amount = _indexOf(titles, _amountTitles);
      if (date < 0 || description < 0 || amount < 0) continue;
      return _Header(
        row: r,
        date: date,
        valueDate: _indexOf(titles, _valueDateTitles),
        description: description,
        amount: amount,
        balance: _indexOf(titles, _balanceTitles),
        currency: _indexOf(titles, _currencyTitles),
      );
    }
    return null;
  }

  static int _indexOf(List<String> titles, Set<String> candidates) =>
      titles.indexWhere(candidates.contains);

  static const _dateTitles = {
    'transaction date',
    'fecha operacion',
    'fecha de operacion',
  };
  static const _valueDateTitles = {'value date', 'fecha valor'};
  static const _descriptionTitles = {'description', 'concepto', 'descripcion'};
  static const _amountTitles = {'amount', 'importe'};
  static const _balanceTitles = {'balance', 'saldo'};
  static const _currencyTitles = {'currency', 'divisa', 'moneda'};
}

class _Header {
  const _Header({
    required this.row,
    required this.date,
    required this.valueDate,
    required this.description,
    required this.amount,
    required this.balance,
    required this.currency,
  });

  final int row;
  final int date;
  final int valueDate;
  final int description;
  final int amount;
  final int balance;
  final int currency;

  String cell(List<String> row, int column) =>
      column >= 0 && column < row.length ? row[column] : '';
}
