import 'dart:convert';
import 'dart:ui';

import '../models/category.model.dart';
import '../models/category_rule.model.dart';
import '../models/transaction.model.dart';

/// (De)serialization of everything the repos persist. Stored as JSON
/// strings in Hive (rather than Hive type adapters) so the on-disk format
/// stays readable and needs no generated code.
class FinanceCodec {
  const FinanceCodec();

  String encodeTransaction(TransactionModel tx) => jsonEncode({
        'id': tx.id,
        'date': _date(tx.date),
        'valueDate': tx.valueDate == null ? null : _date(tx.valueDate!),
        'description': tx.description,
        'amount': tx.amountCents,
        'balance': tx.balanceCents,
        'currency': tx.currency,
        'source': tx.source.name,
      });

  TransactionModel decodeTransaction(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return TransactionModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      valueDate: map['valueDate'] == null
          ? null
          : DateTime.parse(map['valueDate'] as String),
      description: map['description'] as String,
      amountCents: map['amount'] as int,
      balanceCents: map['balance'] as int?,
      currency: map['currency'] as String? ?? 'EUR',
      source: TransactionSource.values.byName(map['source'] as String),
    );
  }

  String encodeRules(List<CategoryRule> rules) => jsonEncode([
        for (final r in rules)
          {
            'id': r.id,
            'kind': r.kind.name,
            'value': r.value,
            'categoryId': r.categoryId,
            'createdAt': r.createdAt.toIso8601String(),
          },
      ]);

  List<CategoryRule> decodeRules(String json) => [
        for (final m in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
          CategoryRule(
            id: m['id'] as String,
            kind: RuleKind.values.byName(m['kind'] as String),
            value: m['value'] as String,
            categoryId: m['categoryId'] as String,
            createdAt: DateTime.parse(m['createdAt'] as String),
          ),
      ];

  String encodeCustomCategories(List<CategoryModel> categories) => jsonEncode([
        for (final c in categories)
          {'id': c.id, 'name': c.name, 'color': c.color.toARGB32()},
      ]);

  List<CategoryModel> decodeCustomCategories(String json) => [
        for (final m in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
          CategoryModel(
            id: m['id'] as String,
            kind: CategoryKind.expense,
            color: Color(m['color'] as int),
            name: m['name'] as String,
          ),
      ];

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
