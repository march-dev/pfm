// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overview_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OverviewState on _OverviewStateBase, Store {
  Computed<MonthlyStats>? _$statsComputed;

  @override
  MonthlyStats get stats =>
      (_$statsComputed ??= Computed<MonthlyStats>(() => super.stats,
              name: '_OverviewStateBase.stats'))
          .value;
  Computed<List<MapEntry<CategoryModel, int>>>? _$expenseBreakdownComputed;

  @override
  List<MapEntry<CategoryModel, int>> get expenseBreakdown =>
      (_$expenseBreakdownComputed ??=
              Computed<List<MapEntry<CategoryModel, int>>>(
                  () => super.expenseBreakdown,
                  name: '_OverviewStateBase.expenseBreakdown'))
          .value;
  Computed<List<MonthlyStats>>? _$historyComputed;

  @override
  List<MonthlyStats> get history =>
      (_$historyComputed ??= Computed<List<MonthlyStats>>(() => super.history,
              name: '_OverviewStateBase.history'))
          .value;
  Computed<bool>? _$hasDataComputed;

  @override
  bool get hasData => (_$hasDataComputed ??= Computed<bool>(() => super.hasData,
          name: '_OverviewStateBase.hasData'))
      .value;

  @override
  String toString() {
    return '''
stats: ${stats},
expenseBreakdown: ${expenseBreakdown},
history: ${history},
hasData: ${hasData}
    ''';
  }
}
