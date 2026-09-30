enum RuleKind {
  /// Matches every transaction whose merchant name (see MerchantNormalizer)
  /// equals [CategoryRule.value] exactly, ignoring case and accents.
  exactName,

  /// Matches every transaction whose description matches the user-written
  /// pattern in [CategoryRule.value] (see PatternMatcher).
  pattern,
}

/// How widely a manual category assignment applies — the choice offered in
/// the assign dialog.
enum AssignmentScope { single, exactName, pattern }

class CategoryRule {
  const CategoryRule({
    required this.id,
    required this.kind,
    required this.value,
    required this.categoryId,
    required this.createdAt,
  });

  final String id;
  final RuleKind kind;
  final String value;
  final String categoryId;
  final DateTime createdAt;
}
