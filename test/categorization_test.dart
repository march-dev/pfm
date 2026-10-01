import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pfm/src/models.dart';
import 'package:pfm/src/services.dart';
import 'package:pfm/src/utils/text.util.dart';

TransactionModel tx(
  String description, {
  int cents = -1000,
  String id = 't',
  DateTime? date,
  TransactionSource source = TransactionSource.bank,
}) =>
    TransactionModel(
      id: id,
      date: date ?? DateTime(2026, 9, 10),
      description: description,
      amountCents: cents,
      source: source,
    );

CategoryRule rule(
  RuleKind kind,
  String value,
  String categoryId, {
  int minute = 0,
}) =>
    CategoryRule(
      id: '$kind$value$minute',
      kind: kind,
      value: value,
      categoryId: categoryId,
      createdAt: DateTime(2026, 1, 1, 0, minute),
    );

TransactionCategorizer categorizer({
  List<CategoryRule> rules = const [],
  Map<String, String> assignments = const {},
  Set<String> extraCategories = const {},
}) =>
    TransactionCategorizer(
      rules: rules,
      assignments: assignments,
      categoryIds: {
        for (final c in BuiltInCategories.all) c.id,
        ...extraCategories,
      },
    );

void main() {
  group('MerchantNormalizer', () {
    const m = MerchantNormalizer();

    test('strips card, city and reference noise', () {
      expect(
        m.merchantOf(
            'PAGO MOVIL EN CONSUM V. F.CAT, VALENCIA ES, TARJ. :*247394'),
        'CONSUM V. F.CAT',
      );
      expect(
        m.merchantOf(
            'COMPRA Order from restaurant, Valencia, TARJETA 5489 , COMISION 0,00'),
        'Order from restaurant',
      );
      expect(
        m.merchantOf(
            'COMPRA INTERNET EN CONFECCIONES PA, ALMASSERA ES, TARJ. :*247394'),
        'CONFECCIONES PA',
      );
      expect(
        m.merchantOf('RECIBO DIGI SPAIN TELECOM SA, concepto: FACTURA DIGI'),
        'DIGI SPAIN TELECOM SA',
      );
      expect(
        m.merchantOf(
            'RECIBO SUPERFRIENDS INTERNATIONAL SCHOOL Nº RECIBO 0049 5446'),
        'SUPERFRIENDS INTERNATIONAL SCHOOL',
      );
      expect(
        m.merchantOf(
            'TRANSFERENCIA INMEDIATA A FAVOR DE Elena S CONCEPTO Marchenko'),
        'Elena S',
      );
      expect(
        m.merchantOf(
            'TRANSFERENCIA DE BRAVE BRAINS S.L., CONCEPTO ABONO NOMINA 08/2026.'),
        'BRAVE BRAINS S.L.',
      );
      expect(
        m.merchantOf(
            'COMPRA BIZUM Agencia Estatal de Administracion Tributaria 18/09/2026'),
        'Agencia Estatal de Administracion Tributaria',
      );
      expect(
          m.merchantOf('BIZUM A FAVOR DE ANNA BEST CONCEPTO: x'), 'ANNA BEST');
    });

    test('falls back to the text before the first comma', () {
      expect(m.merchantOf('SOMETHING ODD, with, commas'), 'SOMETHING ODD');
    });
  });

  group('PatternMatcher', () {
    bool hit(String pattern, String text) =>
        PatternMatcher.parse(pattern).matches(normalizeText(text));

    test('plain text is a case- and accent-insensitive contains', () {
      expect(hit('consum', 'PAGO MOVIL EN CONSUM V.'), isTrue);
      expect(hit('FARMACIA andrés', 'farmacia andres, valencia'), isTrue);
      expect(hit('mercadona', 'PAGO MOVIL EN CONSUM'), isFalse);
    });

    test('* and ? are wildcards', () {
      expect(hit('order*restaurant', 'COMPRA Order from restaurant'), isTrue);
      expect(hit('cons?m', 'CONSUM'), isTrue);
      expect(hit('cons?m', 'CONSM'), isFalse);
    });

    test('/regex/ is a regular expression', () {
      expect(hit('/starbucks|costa/', 'PAGO MOVIL EN STARBUCKS'), isTrue);
      expect(hit('/^recibo/', 'RECIBO DIGI'), isTrue);
      expect(hit('/^recibo/', 'PAGO RECIBO'), isFalse);
    });

    test('regex specials in plain text are literal', () {
      expect(hit('v. f.cat', 'CONSUM V. F.CAT'), isTrue);
      expect(hit('a.b', 'axb'), isFalse);
    });

    test('blank and broken patterns are invalid, never throw', () {
      expect(PatternMatcher.parse('  ').isValid, isFalse);
      expect(PatternMatcher.parse('/(unclosed/').isValid, isFalse);
      expect(PatternMatcher.parse('/(unclosed/').matches('anything'), isFalse);
    });
  });

  group('built-in categorization', () {
    final c = categorizer();
    String of(String d, {int cents = -1000}) =>
        c.categorize(tx(d, cents: cents));

    test('recognises the categories from the brief', () {
      expect(of('PAGO MOVIL EN STARBUCKS RUZAF, VALENCIA ES'),
          BuiltInCategories.cafeResto);
      expect(of('PAGO MOVIL EN CONSUM V. F.CAT, VALENCIA ES'),
          BuiltInCategories.groceries);
      expect(of('PAGO MOVIL EN FARMACIA ANDRES, VALENCIA ES'),
          BuiltInCategories.health);
      expect(of('PAGO MOVIL EN PELUQUERIA LOLA, VALENCIA ES'),
          BuiltInCategories.beauty);
      expect(
          of('COMPRA RENFE, MADRID, TARJETA 1'), BuiltInCategories.transport);
      expect(of('RECIBO DIGI SPAIN TELECOM SA, concepto: FACTURA DIGI'),
          BuiltInCategories.utilities);
      expect(
          of('COMPRA BIZUM Agencia Estatal de Administracion Tributaria 18/09/2026'),
          BuiltInCategories.taxes);
      expect(of('PAGO MOVIL EN FLORISTERIA ROSA, VALENCIA ES'),
          BuiltInCategories.gifts);
    });

    test('health and beauty are told apart', () {
      expect(of('FARMACIA CENTRAL'), BuiltInCategories.health);
      expect(of('SEPHORA PARIS'), BuiltInCategories.beauty);
    });

    test('ATM withdrawals go to cash', () {
      expect(
        of('RETIRADA DE EFECTIVO EN CAJERO AUTOMATICO 004901720010 EL 10/09/2026'),
        BuiltInCategories.cash,
      );
    });

    test('whole-word keywords do not match inside other words', () {
      expect(of('PAGO MOVIL EN BARCELONA TRAVEL'), BuiltInCategories.other);
    });

    test('"COMPRA INTERNET EN" alone does not make a utility', () {
      expect(
        of('COMPRA INTERNET EN CONFECCIONES PA, ALMASSERA ES, TARJ. :*247394'),
        BuiltInCategories.other,
      );
    });

    test('uber eats is food, plain uber is transport', () {
      expect(of('COMPRA UBER EATS, AMSTERDAM'), BuiltInCategories.cafeResto);
      expect(of('COMPRA UBER TRIP, AMSTERDAM'), BuiltInCategories.transport);
    });

    test('unmatched money in is income, unmatched money out is other', () {
      expect(of('TRANSFERENCIA DE ACME SL, CONCEPTO NOMINA', cents: 300000),
          BuiltInCategories.income);
      expect(of('SOMETHING UNKNOWN'), BuiltInCategories.other);
    });
  });

  group('user rules and priority', () {
    test('an exact-name rule matches that merchant across raw variants', () {
      final c = categorizer(rules: [
        rule(
            RuleKind.exactName, 'Rain Forest Val', BuiltInCategories.groceries),
      ]);
      expect(
        c.categorize(
            tx('PAGO MOVIL EN RAIN FOREST VAL, VALENCIA ES, TARJ. :*1')),
        BuiltInCategories.groceries,
      );
      expect(
        c.categorize(tx('PAGO MOVIL EN RAIN FOREST VALENCIA, VALENCIA ES')),
        BuiltInCategories.other,
        reason: 'exact means exact — a longer name is a different merchant',
      );
    });

    test('a pattern rule matches anywhere in the description', () {
      final c = categorizer(rules: [
        rule(RuleKind.pattern, 'rain forest', BuiltInCategories.groceries),
      ]);
      expect(
        c.categorize(tx('PAGO MOVIL EN RAIN FOREST VALENCIA, VALENCIA ES')),
        BuiltInCategories.groceries,
      );
    });

    test('user rules beat the built-in dictionary', () {
      final c = categorizer(rules: [
        rule(RuleKind.pattern, 'starbucks', BuiltInCategories.gifts),
      ]);
      expect(
          c.categorize(tx('PAGO MOVIL EN STARBUCKS')), BuiltInCategories.gifts);
    });

    test('priority: single assignment > exact name > pattern (newest first)',
        () {
      final t = tx('PAGO MOVIL EN SHOP X, VALENCIA ES', id: 'a');
      final rules = [
        rule(RuleKind.pattern, 'shop', BuiltInCategories.taxes, minute: 1),
        rule(RuleKind.pattern, 'shop x', BuiltInCategories.gifts, minute: 2),
      ];
      expect(categorizer(rules: rules).categorize(t), BuiltInCategories.gifts,
          reason: 'newer pattern wins over older pattern');

      final withExact = [
        ...rules,
        rule(RuleKind.exactName, 'shop x', BuiltInCategories.health, minute: 0),
      ];
      expect(
          categorizer(rules: withExact).categorize(t), BuiltInCategories.health,
          reason: 'exact name is more specific than any pattern');

      expect(
        categorizer(
            rules: withExact,
            assignments: {'a': BuiltInCategories.beauty}).categorize(t),
        BuiltInCategories.beauty,
        reason: 'a one-off assignment beats every rule',
      );
    });

    test('custom categories work, and vanish gracefully when deleted', () {
      final rules = [rule(RuleKind.pattern, 'rent', 'custom_1')];
      final t = tx('TRANSFERENCIA A FAVOR DE X CONCEPTO rent');
      expect(
          categorizer(rules: rules, extraCategories: {'custom_1'})
              .categorize(t),
          'custom_1');
      expect(categorizer(rules: rules).categorize(t), BuiltInCategories.other);
      expect(
        categorizer(assignments: {'t': 'custom_1'}).categorize(t),
        BuiltInCategories.other,
      );
    });

    test('manual cash operations default to cash', () {
      final t = tx('Cash withdrawn', source: TransactionSource.manualCash);
      expect(categorizer().categorize(t), BuiltInCategories.cash);
      expect(
        categorizer(assignments: {'t': BuiltInCategories.cafeResto})
            .categorize(t),
        BuiltInCategories.cafeResto,
        reason: 'a cash purchase can be re-filed under what it was spent on',
      );
    });

    test('an invalid pattern rule is ignored, not fatal', () {
      final c = categorizer(rules: [
        rule(RuleKind.pattern, '/(bad/', BuiltInCategories.gifts),
      ]);
      expect(c.categorize(tx('anything')), BuiltInCategories.other);
    });
  });

  group('StatisticsCalculator', () {
    final categories = {for (final c in BuiltInCategories.all) c.id: c};
    const calc = StatisticsCalculator();

    test('splits income, expenses and cash; nets refunds', () {
      final txs = [
        tx('salary', cents: 300000, id: '1'),
        tx('shop', cents: -5000, id: '2'),
        tx('shop', cents: -2500, id: '3'),
        tx('refund', cents: 1000, id: '4'),
        tx('atm', cents: -20000, id: '5'),
        tx('cash in', cents: 5000, id: '6'),
        tx('october', cents: -100, id: '7', date: DateTime(2026, 10, 1)),
      ];
      final stats = calc.byMonth(
        transactions: txs,
        categoryOf: {
          '1': BuiltInCategories.income,
          '2': BuiltInCategories.groceries,
          '3': BuiltInCategories.groceries,
          '4': BuiltInCategories.groceries,
          '5': BuiltInCategories.cash,
          '6': BuiltInCategories.cash,
          '7': BuiltInCategories.other,
        },
        categories: categories,
      );

      final sep = stats[const YearMonth(2026, 9)]!;
      expect(sep.incomeCents, 300000);
      expect(sep.expenseCents, 6500, reason: '5000 + 2500 - 1000 refund');
      expect(sep.expenseByCategory[BuiltInCategories.groceries], 6500);
      expect(sep.cashOutCents, 20000);
      expect(sep.cashInCents, 5000);
      expect(sep.netCents, 300000 - 6500, reason: 'cash is not spending');
      expect(sep.transactionCount, 6);

      expect(stats[const YearMonth(2026, 10)]!.expenseCents, 100);
      expect(stats, hasLength(2));
    });
  });

  group('real export end to end', () {
    test('September totals match the statement', () {
      final txs = const SantanderStatementParser()
          .parse(File('test/data/TransactionExcelFile.xlsx').readAsBytesSync())
          .transactions;
      final c = categorizer();
      final categoryOf = c.categorizeAll(txs);
      final stats = const StatisticsCalculator().byMonth(
        transactions: txs,
        categoryOf: categoryOf,
        categories: {for (final k in BuiltInCategories.all) k.id: k},
      )[const YearMonth(2026, 9)]!;

      expect(stats.incomeCents, 390746);
      expect(stats.cashOutCents, 20000);
      // Independent check: income - expenses - cash out == sum of amounts.
      final total = txs.fold<int>(0, (s, t) => s + t.amountCents);
      expect(
          stats.incomeCents - stats.expenseCents - stats.cashOutCents, total);

      expect(categoryOf[txs.first.id], BuiltInCategories.utilities);
      final atm = txs.singleWhere((t) => t.description.startsWith('RETIRADA'));
      expect(categoryOf[atm.id], BuiltInCategories.cash);
      final consum = txs.where((t) => t.description.contains('CONSUM'));
      expect(consum.map((t) => categoryOf[t.id]).toSet(),
          {BuiltInCategories.groceries});
    });
  });
}
