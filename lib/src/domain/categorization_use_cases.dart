import 'package:flutter/painting.dart';

import '../../pfm.dart';

/// Everything the categorization UI needs to rebuild itself from, as last
/// persisted.
class CategorizationSnapshot {
  const CategorizationSnapshot({
    required this.rules,
    required this.assignments,
    required this.customCategories,
  });

  final List<CategoryRule> rules;
  final Map<String, String> assignments;
  final List<CategoryModel> customCategories;
}

/// Business logic for teaching the app which category things belong to:
/// one-off assignments, name/pattern rules, and custom categories. Each
/// mutation returns the resulting [CategorizationSnapshot] (or null after
/// telling the user it failed) for the state to adopt.
class CategorizationUseCases {
  const CategorizationUseCases(
    this._rules,
    this._assignments,
    this._categories,
    this._l10n, [
    this._matcher = const RuleMatcher(),
  ]);

  final RulesRepo _rules;
  final AssignmentsRepo _assignments;
  final CustomCategoriesRepo _categories;
  final AppLocalizations _l10n;
  final RuleMatcher _matcher;

  CategorizationSnapshot load() {
    try {
      return _snapshot();
    } catch (error, stackTrace) {
      logError('Load categorization', error, stackTrace);
      SnackbarManager.show(_l10n.errorLoadData);
      return const CategorizationSnapshot(
        rules: [],
        assignments: {},
        customCategories: [],
      );
    }
  }

  /// Files [transactionId] (and, per [scope], more) under [categoryId].
  ///
  ///  * [AssignmentScope.single] — just that transaction.
  ///  * [AssignmentScope.exactName] / [AssignmentScope.pattern] — a rule on
  ///    [value] (the merchant name / the pattern text). [coveredIds] are the
  ///    transactions that rule now matches: any earlier one-off assignment
  ///    among them is dropped, since a one-off would otherwise silently
  ///    outrank the rule the user just asked for.
  Future<CategorizationSnapshot?> assign({
    required String transactionId,
    required String categoryId,
    required AssignmentScope scope,
    String value = '',
    Set<String> coveredIds = const {},
  }) async {
    // Validated before touching storage: it needs no I/O, and the user
    // should hear "that pattern isn't valid" even if storage is the thing
    // that's broken.
    final ruleKind = switch (scope) {
      AssignmentScope.single => null,
      AssignmentScope.exactName => RuleKind.exactName,
      AssignmentScope.pattern => RuleKind.pattern,
    };
    if (ruleKind != null && !_matcher.isValid(ruleKind, value)) {
      SnackbarManager.show(_l10n.errorInvalidPattern);
      return null;
    }

    try {
      final assignments = _assignments.getAll();
      if (ruleKind == null) {
        assignments[transactionId] = categoryId;
      } else {
        final rules = _rules.getAll()
          ..removeWhere(
            (r) => r.kind == ruleKind && _sameValue(r.value, value),
          );
        rules.add(
          CategoryRule(
            id: 'rule_${DateTime.now().microsecondsSinceEpoch}',
            kind: ruleKind,
            value: value.trim(),
            categoryId: categoryId,
            createdAt: DateTime.now(),
          ),
        );
        assignments.removeWhere((txId, _) => coveredIds.contains(txId));
        await _rules.saveAll(rules);
      }
      await _assignments.saveAll(assignments);
      return _snapshot();
    } catch (error, stackTrace) {
      logError('Assign category', error, stackTrace);
      SnackbarManager.show(_l10n.errorAssignCategory);
      return null;
    }
  }

  /// Removes a transaction's one-off assignment, so it goes back to being
  /// categorized by rules and the built-in dictionary.
  Future<CategorizationSnapshot?> clearAssignment(String transactionId) async {
    try {
      await _assignments.saveAll(_assignments.getAll()..remove(transactionId));
      return _snapshot();
    } catch (error, stackTrace) {
      logError('Clear assignment', error, stackTrace);
      SnackbarManager.show(_l10n.errorAssignCategory);
      return null;
    }
  }

  Future<CategorizationSnapshot?> deleteRule(String ruleId) async {
    try {
      await _rules.saveAll(_rules.getAll()..removeWhere((r) => r.id == ruleId));
      return _snapshot();
    } catch (error, stackTrace) {
      logError('Delete rule', error, stackTrace);
      SnackbarManager.show(_l10n.errorSaveRule);
      return null;
    }
  }

  Future<CategorizationSnapshot?> createCategory(
    String name,
    Color color,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final custom = _categories.getAll();
      final taken = {
        for (final c in [...BuiltInCategories.all, ...custom])
          normalizeText(categoryLabel(_l10n, c)),
      };
      if (taken.contains(normalizeText(trimmed))) {
        SnackbarManager.show(_l10n.errorCategoryExists(trimmed));
        return null;
      }
      custom.add(
        CategoryModel(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          kind: CategoryKind.expense,
          color: color,
          name: trimmed,
        ),
      );
      await _categories.saveAll(custom);
      return _snapshot();
    } catch (error, stackTrace) {
      logError('Create category "$trimmed"', error, stackTrace);
      SnackbarManager.show(_l10n.errorSaveCategory);
      return null;
    }
  }

  /// Deletes a custom category along with every rule and assignment that
  /// pointed at it.
  Future<CategorizationSnapshot?> deleteCategory(String categoryId) async {
    try {
      await _categories.saveAll(
        _categories.getAll()..removeWhere((c) => c.id == categoryId),
      );
      await _rules.saveAll(
        _rules.getAll()..removeWhere((r) => r.categoryId == categoryId),
      );
      await _assignments.saveAll(
        _assignments.getAll()..removeWhere((_, id) => id == categoryId),
      );
      return _snapshot();
    } catch (error, stackTrace) {
      logError('Delete category', error, stackTrace);
      SnackbarManager.show(_l10n.errorSaveCategory);
      return null;
    }
  }

  CategorizationSnapshot _snapshot() => CategorizationSnapshot(
        rules: _rules.getAll(),
        assignments: _assignments.getAll(),
        customCategories: _categories.getAll(),
      );

  static bool _sameValue(String a, String b) =>
      normalizeText(a) == normalizeText(b);
}
