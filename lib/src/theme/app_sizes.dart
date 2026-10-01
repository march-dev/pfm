/// The app's size scale — spacing/gaps, corner radii, and icon sizes shared
/// across screens. Referencing these by name means a size change happens in
/// one place instead of hunting down every "matches X's own Y" comment.
///
/// Not every numeric literal in the app belongs here — a one-off widget's
/// own tuned dimension (a tile's fixed width, a segment's fixed column
/// width) isn't a shared design token just because it happens to be a
/// round number, and forcing it through this scale would risk an
/// unrelated widget resizing the next time this scale changes. This only
/// covers values that are genuinely reused as the same semantic role in
/// more than one place.
abstract final class AppSizes {
  // Spacing/gap scale — padding and gaps between elements, roughly a 4pt
  // grid. Named by pixel value (not t-shirt size) since callers already
  // think in terms of "the usual 16px gap", not an abstract step.
  static const spacing2 = 2.0;
  static const spacing4 = 4.0;
  static const spacing6 = 6.0;
  static const spacing8 = 8.0;
  static const spacing10 = 10.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;

  // Corner radii.
  static const radiusSmall = 4.0;
  static const radiusMedium = 8.0;
  static const radiusLarge = 12.0;
  static const radiusXLarge = 16.0;

  // Icon/glyph sizes.
  static const iconTiny = 12.0;
  static const iconXSmall = 14.0;
  static const iconSmall = 16.0;
  static const iconMedium = 18.0;
  static const iconLarge = 20.0;
  static const iconXLarge = 24.0;
  static const iconHuge = 32.0;

  // A table row's own leading icon badge.
  static const rowIconSize = 40.0;

  // AppTable's default row height.
  static const rowHeight = 56.0;

  // A fixed trailing action column (a delete button) sized to match
  // rowIconSize so the column reads as square.
  static const actionColumnSize = 40.0;

  // The height of every interactive control that sits in a row with others
  // — text field, button, segmented button, split button, dropdown — so
  // they line up edge to edge.
  static const controlHeight = 32.0;

  // Every hairline border/divider in the app is this thick.
  static const borderWidth = 1.0;
}
