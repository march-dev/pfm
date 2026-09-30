import '../models/category.model.dart';
import '../models/category_rule.model.dart';
import '../models/transaction.model.dart';
import '../utils/text.util.dart';
import 'built_in_category_rules.dart';
import 'rule_matcher.dart';

/// Decides which category a transaction belongs to. Most specific wins:
///
///  1. the user's one-off assignment of this exact transaction;
///  2. a user "exact name" rule for its merchant;
///  3. a user pattern rule (newest first, when several match);
///  4. a manual cash operation -> Cash;
///  5. the built-in keyword dictionary;
///  6. fallback: money in -> Income, money out -> Other.
///
/// Anything pointing at a category that no longer exists is ignored, so
/// deleting a category degrades gracefully to the next step instead of
/// orphaning transactions.
class TransactionCategorizer {
  TransactionCategorizer({
    required Iterable<CategoryRule> rules,
    required Map<String, String> assignments,
    required Set<String> categoryIds,
    RuleMatcher matcher = const RuleMatcher(),
    BuiltInCategoryRules? builtIn,
  })  : _assignments = assignments,
        _categoryIds = categoryIds,
        _builtIn = builtIn ?? BuiltInCategoryRules() {
    // Newest first, so for both kinds a later rule shadows an earlier one.
    final ordered = rules.where((r) => categoryIds.contains(r.categoryId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final rule in ordered) {
      final predicate = matcher.compile(rule.kind, rule.value);
      if (predicate == null) continue;
      (rule.kind == RuleKind.exactName ? _exactRules : _patternRules)
          .add((predicate: predicate, categoryId: rule.categoryId));
    }
  }

  final Map<String, String> _assignments;
  final Set<String> _categoryIds;
  final BuiltInCategoryRules _builtIn;
  final _exactRules = <({bool Function(TransactionModel) predicate, String categoryId})>[];
  final _patternRules = <({bool Function(TransactionModel) predicate, String categoryId})>[];

  String categorize(TransactionModel tx) {
    final assigned = _assignments[tx.id];
    if (assigned != null && _categoryIds.contains(assigned)) return assigned;

    for (final rule in _exactRules) {
      if (rule.predicate(tx)) return rule.categoryId;
    }
    for (final rule in _patternRules) {
      if (rule.predicate(tx)) return rule.categoryId;
    }

    if (tx.isManual) return BuiltInCategories.cash;

    final builtIn = _builtIn.categoryFor(normalizeText(tx.description));
    if (builtIn != null) return builtIn;

    return tx.isIncoming ? BuiltInCategories.income : BuiltInCategories.other;
  }

  Map<String, String> categorizeAll(Iterable<TransactionModel> transactions) => {
        for (final tx in transactions) tx.id: categorize(tx),
      };
}
