import 'package:flutter/painting.dart';

/// How a category takes part in the monthly totals.
enum CategoryKind {
  /// Money spent — summed (negated) into the month's expenses.
  expense,

  /// Money received — summed into the month's income.
  income,

  /// Money merely moved around (cash withdrawn from / put into the account).
  /// Shown on its own and deliberately left out of income and expenses:
  /// counting an ATM withdrawal as spending would count the same money
  /// twice once it's actually spent.
  transfer,
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.kind,
    required this.color,
    this.name,
    this.builtIn = false,
  });

  final String id;
  final CategoryKind kind;
  final Color color;

  /// Only set for user-created categories. Built-ins are named by
  /// AppLocalizations instead (see categoryLabel), keyed off [id].
  final String? name;
  final bool builtIn;

  CategoryModel copyWith({String? name, Color? color}) => CategoryModel(
        id: id,
        kind: kind,
        color: color ?? this.color,
        name: name ?? this.name,
        builtIn: builtIn,
      );
}

/// The fixed categories every install starts with. Their ids are persisted
/// in rules and assignments, so they must never be renamed.
abstract final class BuiltInCategories {
  static const cafeResto = 'cafe_resto';
  static const groceries = 'groceries';
  static const health = 'health';
  static const beauty = 'beauty';
  static const transport = 'transport';
  static const utilities = 'utilities';
  static const taxes = 'taxes';
  static const gifts = 'gifts';
  static const cash = 'cash';
  static const income = 'income';
  static const other = 'other';

  static const all = <CategoryModel>[
    CategoryModel(
      id: cafeResto,
      kind: CategoryKind.expense,
      color: Color(0xFFFF9F0A),
      builtIn: true,
    ),
    CategoryModel(
      id: groceries,
      kind: CategoryKind.expense,
      color: Color(0xFF30D158),
      builtIn: true,
    ),
    CategoryModel(
      id: health,
      kind: CategoryKind.expense,
      color: Color(0xFFFF6B6B),
      builtIn: true,
    ),
    CategoryModel(
      id: beauty,
      kind: CategoryKind.expense,
      color: Color(0xFFBF5AF2),
      builtIn: true,
    ),
    CategoryModel(
      id: transport,
      kind: CategoryKind.expense,
      color: Color(0xFF0A84FF),
      builtIn: true,
    ),
    CategoryModel(
      id: utilities,
      kind: CategoryKind.expense,
      color: Color(0xFFFFD60A),
      builtIn: true,
    ),
    CategoryModel(
      id: taxes,
      kind: CategoryKind.expense,
      color: Color(0xFFAC8E68),
      builtIn: true,
    ),
    CategoryModel(
      id: gifts,
      kind: CategoryKind.expense,
      color: Color(0xFFFF375F),
      builtIn: true,
    ),
    CategoryModel(
      id: cash,
      kind: CategoryKind.transfer,
      color: Color(0xFF5E5CE6),
      builtIn: true,
    ),
    CategoryModel(
      id: income,
      kind: CategoryKind.income,
      color: Color(0xFF63E6BE),
      builtIn: true,
    ),
    CategoryModel(
      id: other,
      kind: CategoryKind.expense,
      color: Color(0xFF8E8E93),
      builtIn: true,
    ),
  ];
}
