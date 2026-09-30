import 'package:flutter/material.dart';

import '../../../pfm.dart';

/// The icon shown next to a category: a fixed one per built-in, a generic
/// tag for anything the user created.
IconData categoryIcon(CategoryModel category) => switch (category.id) {
      BuiltInCategories.cafeResto => Icons.restaurant_outlined,
      BuiltInCategories.groceries => Icons.shopping_basket_outlined,
      BuiltInCategories.health => Icons.medical_services_outlined,
      BuiltInCategories.beauty => Icons.spa_outlined,
      BuiltInCategories.transport => Icons.directions_bus_outlined,
      BuiltInCategories.utilities => Icons.bolt_outlined,
      BuiltInCategories.taxes => Icons.account_balance_outlined,
      BuiltInCategories.gifts => Icons.card_giftcard_outlined,
      BuiltInCategories.cash => Icons.payments_outlined,
      BuiltInCategories.income => Icons.trending_up,
      BuiltInCategories.other => Icons.category_outlined,
      _ => Icons.label_outline,
    };
