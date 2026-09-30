import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../services.dart';

/// User-created categories (the built-ins live in code — see
/// BuiltInCategories).
class CustomCategoriesRepo {
  const CustomCategoriesRepo({required Box box, required FinanceCodec codec})
      : _box = box,
        _codec = codec;

  final Box _box;
  final FinanceCodec _codec;

  static const _key = 'customCategoriesKey';

  List<CategoryModel> getAll() {
    final json = _box.get(_key) as String?;
    return json == null ? [] : _codec.decodeCustomCategories(json);
  }

  Future<void> saveAll(List<CategoryModel> categories) =>
      _box.put(_key, _codec.encodeCustomCategories(categories));
}
