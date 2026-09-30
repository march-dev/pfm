// Pure domain logic with no persistence of its own — statement parsing,
// name/pattern matching, categorization, statistics, (de)serialization.
// Kept separate from repos/ (which read from or write to Hive or the file
// system) since these aren't repositories.
export 'services/built_in_category_rules.dart';
export 'services/finance_codec.dart';
export 'services/merchant_normalizer.dart';
export 'services/pattern_matcher.dart';
export 'services/rule_matcher.dart';
export 'services/santander_statement_parser.dart';
export 'services/statistics_calculator.dart';
export 'services/transaction_categorizer.dart';
export 'services/xlsx_reader.dart';
