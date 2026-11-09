import 'nutrition.dart';

String normalizedFoodText(String value) {
  var text = value.toLowerCase().replaceAll('\u0307', '');
  const pairs = {
    'ı': 'i',
    'ş': 's',
    'ğ': 'g',
    'ü': 'u',
    'ö': 'o',
    'ç': 'c',
    'İ': 'i',
  };
  pairs.forEach((from, to) => text = text.replaceAll(from, to));
  return text;
}

const foodAliases = {
  'tavuk': 'chicken',
  'hindi': 'turkey',
  'sigir': 'beef',
  'dana': 'beef',
  'kuzu': 'lamb',
  'balik': 'fish',
  'somon': 'salmon',
  'ton': 'tuna',
  'sut': 'milk',
  'yogurt': 'yogurt',
  'peynir': 'cheese',
  'yumurta': 'egg',
  'muz': 'banana',
  'elma': 'apple',
  'yaban mersini': 'blueberries',
  'cilek': 'strawberries',
  'portakal': 'orange',
  'avokado': 'avocado',
  'mercimek': 'lentil',
  'nohut': 'chickpea',
  'fasulye': 'beans',
  'pirinc': 'rice',
  'yulaf': 'oat',
  'bulgur': 'bulgur',
  'bugday': 'wheat',
  'ekmek': 'bread',
  'makarna': 'pasta',
  'patates': 'potato',
  'domates': 'tomato',
  'salatalik': 'cucumber',
  'ispanak': 'spinach',
  'brokoli': 'broccoli',
  'havuc': 'carrot',
  'kabak': 'squash',
  'badem': 'almond',
  'ceviz': 'walnut',
  'findik': 'hazelnut',
  'zeytin': 'olive',
  'yag': 'oil',
  'cig': 'raw',
  'pismis': 'cooked',
};
bool foodMatches(Food food, String query) {
  var q = normalizedFoodText(query.trim());
  final haystack = normalizedFoodText('${food.tr} ${food.en}');
  if (q.isEmpty || haystack.contains(q)) return true;
  // Replace phrases before words. Keep source names and raw/cooked qualifiers.
  q = q.replaceAll('yaban mersini', 'blueberries');
  return q
      .split(RegExp(r'\s+'))
      .every((part) => haystack.contains(foodAliases[part] ?? part));
}
