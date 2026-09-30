import '../utils/text.util.dart';

/// A user-written name pattern, compiled once.
///
/// Three forms, chosen by how the text is written:
///  * `/regex/`      — a regular expression;
///  * contains `*`/`?` — a wildcard match (`*` any run of characters, `?`
///    exactly one), found anywhere in the text;
///  * anything else  — a plain "contains".
///
/// All matching is case- and accent-insensitive, against text that has
/// already been through [normalizeText].
class PatternMatcher {
  PatternMatcher._(this._regex);

  factory PatternMatcher.parse(String pattern) {
    final text = pattern.trim();
    if (text.isEmpty) return PatternMatcher._(null);

    try {
      if (text.length > 2 && text.startsWith('/') && text.endsWith('/')) {
        return PatternMatcher._(
          RegExp(text.substring(1, text.length - 1), caseSensitive: false),
        );
      }

      final normalized = normalizeText(text);
      final source = normalized
          .split('')
          .map(
            (c) => switch (c) {
              '*' => '.*',
              '?' => '.',
              _ => RegExp.escape(c),
            },
          )
          .join();
      return PatternMatcher._(RegExp(source, caseSensitive: false));
    } on FormatException {
      return PatternMatcher._(null);
    }
  }

  final RegExp? _regex;

  /// False for an empty pattern or a `/regex/` that doesn't compile.
  bool get isValid => _regex != null;

  bool matches(String normalizedText) =>
      _regex?.hasMatch(normalizedText) ?? false;
}
