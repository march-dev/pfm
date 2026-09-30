import '../../l10n/generated/app_localizations.dart';
import '../models/category.model.dart';

/// The name to show for [category]: the user's own text for a custom one,
/// or the localized name for a built-in.
String categoryLabel(AppLocalizations l10n, CategoryModel category) {
  if (!category.builtIn) return category.name ?? category.id;
  return switch (category.id) {
    BuiltInCategories.cafeResto => l10n.categoryCafeResto,
    BuiltInCategories.groceries => l10n.categoryGroceries,
    BuiltInCategories.health => l10n.categoryHealth,
    BuiltInCategories.beauty => l10n.categoryBeauty,
    BuiltInCategories.transport => l10n.categoryTransport,
    BuiltInCategories.utilities => l10n.categoryUtilities,
    BuiltInCategories.taxes => l10n.categoryTaxes,
    BuiltInCategories.gifts => l10n.categoryGifts,
    BuiltInCategories.cash => l10n.categoryCash,
    BuiltInCategories.income => l10n.categoryIncome,
    _ => l10n.categoryOther,
  };
}
