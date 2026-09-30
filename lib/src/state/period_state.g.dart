// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PeriodState on _PeriodStateBase, Store {
  Computed<YearMonth>? _$monthComputed;

  @override
  YearMonth get month =>
      (_$monthComputed ??= Computed<YearMonth>(() => super.month,
              name: '_PeriodStateBase.month'))
          .value;
  Computed<bool>? _$canGoPreviousComputed;

  @override
  bool get canGoPrevious =>
      (_$canGoPreviousComputed ??= Computed<bool>(() => super.canGoPrevious,
              name: '_PeriodStateBase.canGoPrevious'))
          .value;
  Computed<bool>? _$canGoNextComputed;

  @override
  bool get canGoNext =>
      (_$canGoNextComputed ??= Computed<bool>(() => super.canGoNext,
              name: '_PeriodStateBase.canGoNext'))
          .value;

  late final _$selectedAtom =
      Atom(name: '_PeriodStateBase.selected', context: context);

  @override
  YearMonth? get selected {
    _$selectedAtom.reportRead();
    return super.selected;
  }

  @override
  set selected(YearMonth? value) {
    _$selectedAtom.reportWrite(value, super.selected, () {
      super.selected = value;
    });
  }

  late final _$_PeriodStateBaseActionController =
      ActionController(name: '_PeriodStateBase', context: context);

  @override
  void select(YearMonth value) {
    final _$actionInfo = _$_PeriodStateBaseActionController.startAction(
        name: '_PeriodStateBase.select');
    try {
      return super.select(value);
    } finally {
      _$_PeriodStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void previous() {
    final _$actionInfo = _$_PeriodStateBaseActionController.startAction(
        name: '_PeriodStateBase.previous');
    try {
      return super.previous();
    } finally {
      _$_PeriodStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void next() {
    final _$actionInfo = _$_PeriodStateBaseActionController.startAction(
        name: '_PeriodStateBase.next');
    try {
      return super.next();
    } finally {
      _$_PeriodStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selected: ${selected},
month: ${month},
canGoPrevious: ${canGoPrevious},
canGoNext: ${canGoNext}
    ''';
  }
}
