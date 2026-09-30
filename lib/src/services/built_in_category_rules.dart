import '../models/category.model.dart';
import '../utils/text.util.dart';

/// The keyword dictionary used when the user hasn't taught the app
/// anything about a transaction yet — mostly Spanish chains and generic
/// words that show up in Santander descriptions.
///
/// Keywords are matched against the normalized description (lowercase, no
/// accents) as whole words, so `bar` doesn't match `barcelona`; a trailing
/// `*` makes it a prefix match (`peluquer*` covers peluquería/peluquero).
/// Categories are tried in the order listed, first hit wins — which is why
/// cash and taxes come first (an ATM withdrawal or a tax bill must never be
/// mistaken for a shop), and why `uber eats` (cafe) is seen before `uber`
/// (transport).
class BuiltInCategoryRules {
  BuiltInCategoryRules() : _compiled = _compile();

  /// The category id whose keywords match [description], or null.
  String? categoryFor(String normalizedDescription) {
    for (final entry in _compiled) {
      if (entry.pattern.hasMatch(normalizedDescription)) return entry.id;
    }
    return null;
  }

  final List<({String id, RegExp pattern})> _compiled;

  static List<({String id, RegExp pattern})> _compile() => [
        for (final entry in _keywords.entries)
          (
            id: entry.key,
            pattern: RegExp(
              '(?<![a-z0-9])(?:${entry.value.map(_keywordSource).join('|')})',
            ),
          ),
      ];

  static String _keywordSource(String keyword) {
    final prefix = keyword.endsWith('*');
    final word = normalizeText(prefix ? keyword.substring(0, keyword.length - 1) : keyword);
    return '${RegExp.escape(word)}${prefix ? '' : '(?![a-z0-9])'}';
  }

  static const _keywords = <String, List<String>>{
    BuiltInCategories.cash: [
      'retirada de efectivo',
      'ingreso de efectivo',
      'ingreso en efectivo',
      'cajero',
    ],
    BuiltInCategories.taxes: [
      'agencia estatal de administracion tributaria',
      'aeat',
      'hacienda',
      'tributaria',
      'ayuntamiento',
      'ajuntament',
      'impuesto*',
      'tasa',
      'tasas',
      'dgt',
      'seguridad social',
      'tgss',
      'ibi',
      'irpf',
      'tesoreria general',
    ],
    BuiltInCategories.utilities: [
      'digi',
      'telecom*',
      'movistar',
      'vodafone',
      'orange',
      'telefonica',
      'masmovil',
      'yoigo',
      'pepephone',
      'iberdrola',
      'endesa',
      'naturgy',
      'holaluz',
      'luz',
      'agua',
      'aquaservice',
      'aqua service',
      'emivasa',
      'gas natural',
      'butano',
      'electricidad',
      'fibra',
      'suministro*',
    ],
    BuiltInCategories.cafeResto: [
      'restaurant*',
      'cafe',
      'cafes',
      'cafeteria*',
      'bar',
      'cerveceria*',
      'taberna',
      'tapas',
      'pizza*',
      'pizzeria*',
      'burger*',
      'mcdonald*',
      'starbucks',
      'telepizza',
      'glovo',
      'uber eats',
      'ubereats',
      'just eat',
      'deliveroo',
      'panaderia*',
      'pasteleria*',
      'heladeria*',
      'churreria*',
      'bocadiller*',
      'kebab',
      'sushi',
      'botanas',
      'dulce de leche',
      'cuartoscuro',
    ],
    BuiltInCategories.groceries: [
      'consum',
      'mercadona',
      'carrefour',
      'lidl',
      'aldi',
      'alcampo',
      'eroski',
      'hipercor',
      'supercor',
      'supermercado*',
      'condis',
      'bonpreu',
      'caprabo',
      'ahorramas',
      'froiz',
      'gadis',
      'fruteria*',
      'carniceria*',
      'pescaderia*',
      'verduleria*',
      'charcuteria*',
      'ultramarinos',
      'mas y mas',
      'plusfresc',
    ],
    BuiltInCategories.health: [
      'farmacia*',
      'parafarmacia*',
      'clinica*',
      'hospital*',
      'dentist*',
      'medic*',
      'optica*',
      'sanitas',
      'adeslas',
      'fisioterap*',
      'psicolog*',
      'podolog*',
      'laboratorio*',
      'oftalmolog*',
    ],
    BuiltInCategories.beauty: [
      'peluquer*',
      'barber*',
      'estetica*',
      'perfumeria*',
      'sephora',
      'douglas',
      'primor',
      'manicura*',
      'cosmetic*',
      'maquillaje',
      'depil*',
      'kiko',
      'rituals',
    ],
    BuiltInCategories.transport: [
      'renfe',
      'metrovalencia',
      'metro',
      'emt',
      'taxi*',
      'uber',
      'cabify',
      'bolt',
      'freenow',
      'gasolinera*',
      'repsol',
      'cepsa',
      'galp',
      'shell',
      'parking*',
      'aparcamiento*',
      'estacionamiento',
      'alsa',
      'ryanair',
      'vueling',
      'iberia',
      'easyjet',
      'blablacar',
      'bicing',
      'valenbisi',
      'peaje*',
      'autopista*',
      'flixbus',
      'ouigo',
      'iryo',
      'cercanias',
    ],
    BuiltInCategories.gifts: [
      'regalo*',
      'gift',
      'floristeria*',
      'flores',
      'juguet*',
      'joyeria*',
      'cumpleanos',
    ],
  };
}
