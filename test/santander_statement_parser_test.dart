import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pfm/src/models/year_month.model.dart';
import 'package:pfm/src/services/santander_statement_parser.dart';

void main() {
  const parser = SantanderStatementParser();

  group('parseAmountCents', () {
    test('parses Spanish formatting exactly', () {
      expect(SantanderStatementParser.parseAmountCents('-27,00€'), -2700);
      expect(SantanderStatementParser.parseAmountCents('-1.300,00€'), -130000);
      expect(SantanderStatementParser.parseAmountCents('3.907,46€'), 390746);
      expect(SantanderStatementParser.parseAmountCents('-0,95€'), -95);
      expect(
          SantanderStatementParser.parseAmountCents('2.177,28€ EUR'), 217728);
    });

    test('parses plain and English formatting', () {
      expect(SantanderStatementParser.parseAmountCents('-27.0'), -2700);
      expect(SantanderStatementParser.parseAmountCents('2,204.68'), 220468);
      expect(SantanderStatementParser.parseAmountCents('1.300'), 130000);
      expect(SantanderStatementParser.parseAmountCents('−8,7'), -870);
    });

    test('returns null when there is no number', () {
      expect(SantanderStatementParser.parseAmountCents(''), isNull);
      expect(SantanderStatementParser.parseAmountCents('EUR'), isNull);
    });
  });

  group('parseDate', () {
    test('parses dd/MM/yyyy and rejects impossible dates', () {
      expect(
        SantanderStatementParser.parseDate('29/09/2026'),
        DateTime(2026, 9, 29),
      );
      expect(SantanderStatementParser.parseDate('31/02/2026'), isNull);
      expect(SantanderStatementParser.parseDate('Transaction date'), isNull);
    });
  });

  group('parseRows', () {
    test('finds the header after a summary block, English or Spanish', () {
      final result = parser.parseRows([
        ['', '', 'Account', 'Date'],
        [],
        ['Fecha operación', 'Fecha valor', 'Concepto', 'Importe', 'Saldo'],
        ['01/02/2026', '01/02/2026', 'PAGO MOVIL EN X, Y', '-1,50€', '10,00€'],
        ['not a date', '', 'junk', '', ''],
      ]);
      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.amountCents, -150);
      expect(result.skippedRows, 1);
    });

    test('throws a clear error when there is no transaction table', () {
      expect(
        () => parser.parseRows([
          ['just', 'some'],
          ['other', 'sheet'],
        ]),
        throwsA(isA<StatementFormatException>()),
      );
    });

    test('gives identical rows distinct ids, stably', () {
      final rows = [
        ['Transaction date', 'Description', 'Amount'],
        ['01/02/2026', 'COFFEE', '-2,00€'],
        ['01/02/2026', 'COFFEE', '-2,00€'],
      ];
      final first = parser.parseRows(rows).transactions;
      final second = parser.parseRows(rows).transactions;
      expect(first[0].id, isNot(first[1].id));
      expect(first.map((t) => t.id), second.map((t) => t.id));
    });
  });

  group('real Santander export', () {
    final file = File('test/data/TransactionExcelFile.xlsx');

    test('parses every transaction row', () {
      final result = parser.parse(file.readAsBytesSync());
      // Rows 9..48 of the sheet.
      expect(result.transactions, hasLength(40));
      expect(result.skippedRows, 0);
      expect(
        result.transactions.map((t) => t.id).toSet(),
        hasLength(40),
        reason: 'every row must get a unique id',
      );
    });

    test('reads dates, amounts and non-ASCII text correctly', () {
      final txs = parser.parse(file.readAsBytesSync()).transactions;

      final first = txs.first;
      expect(first.date, DateTime(2026, 9, 29));
      expect(first.amountCents, -2700);
      expect(first.balanceCents, 220468);
      expect(first.description, contains('DIGI SPAIN TELECOM'));

      final payroll = txs.singleWhere((t) => t.amountCents == 390746);
      expect(payroll.description, contains('ABONO NOMINA'));
      expect(txs.any((t) => t.amountCents == -130000), isTrue);
      expect(
        txs.singleWhere((t) => t.description.startsWith('RECIBO SUPERFRIENDS')),
        isNotNull,
      );
    });

    test('running balance reconciles with the amounts', () {
      // Each row's balance is the previous (older) row's balance plus its
      // own amount — proves no amount was mis-signed or mis-scaled.
      final txs = parser.parse(file.readAsBytesSync()).transactions;
      for (var i = 0; i < txs.length - 1; i++) {
        expect(
          txs[i + 1].balanceCents! + txs[i].amountCents,
          txs[i].balanceCents,
          reason: 'row $i',
        );
      }
    });

    test('everything falls in September 2026', () {
      final txs = parser.parse(file.readAsBytesSync()).transactions;
      expect(
        txs.map((t) => YearMonth.fromDate(t.date)).toSet(),
        {const YearMonth(2026, 9)},
      );
    });
  });
}
