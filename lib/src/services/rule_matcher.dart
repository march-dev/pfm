import '../models/category_rule.model.dart';
import '../models/transaction.model.dart';
import '../utils/text.util.dart';
import 'merchant_normalizer.dart';
import 'pattern_matcher.dart';

/// Compiles a rule (kind + value) into a predicate over transactions.
/// Shared by the categorizer and by the assign dialog's "N transactions
/// match" preview, so what the preview promises is exactly what applying
/// the rule then does.
class RuleMatcher {
  const RuleMatcher([this._merchants = const MerchantNormalizer()]);

  final MerchantNormalizer _merchants;

  /// Null when the rule can't match anything (blank value, or a pattern
  /// that isn't valid).
  bool Function(TransactionModel)? compile(RuleKind kind, String value) {
    switch (kind) {
      case RuleKind.exactName:
        final name = normalizeText(value);
        if (name.isEmpty) return null;
        return (tx) => normalizeText(_merchants.merchantOf(tx.description)) == name;
      case RuleKind.pattern:
        final matcher = PatternMatcher.parse(value);
        if (!matcher.isValid) return null;
        return (tx) => matcher.matches(normalizeText(tx.description));
    }
  }

  bool isValid(RuleKind kind, String value) => compile(kind, value) != null;
}
