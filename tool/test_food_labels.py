import hashlib
import json
from pathlib import Path
import unittest

from food_labels import meat_label


class FoodLabelTests(unittest.TestCase):
    def label(self, text):
        return meat_label(text, ['Et', 'Meat'], ['Parça', 'Cut'])

    def test_fat_free_claim_is_not_fat_percentage(self):
        label = self.label('Turkey, breast, smoked, lemon pepper flavor, 97% fat-free')
        self.assertIn(['Kaynak tanımı: %97 yağsız', 'Source description: 97% fat free'], label['traits'])
        self.assertFalse(any('Source composition' in t[1] for t in label['traits']))

    def test_formulation_and_trim_do_not_claim_zero_fat(self):
        label = self.label('Beef, ground, 95% lean meat / 5% fat, trimmed to 0" fat, raw')
        self.assertIn(['Kaynak bileşimi: %95 et', 'Source composition: 95% lean'], label['traits'])
        self.assertIn(['Kaynak bileşimi: %5 yağ', 'Source composition: 5% fat'], label['traits'])
        self.assertIn(['Dış yağ payı: 0 inç', 'External fat trim: 0 inch'], label['traits'])
        lean = self.label('Beef, separable lean only, raw')
        self.assertIn(['Yalnız et kısmı', 'Separable lean only'], lean['traits'])
        self.assertFalse(any('%' in t[1] or 'free' in t[1] for t in lean['traits']))

    def test_parenthetical_future_use_does_not_mean_already_cured(self):
        label = self.label('Pork, fresh, composite cuts, (includes cuts to be cured), raw')
        self.assertIn('Raw', label['title'][1])
        self.assertNotIn('Cured', label['title'][1])

    def test_unheated_cured_meat_is_not_raw_or_cooked(self):
        label = self.label('Pork, cured, ham, unheated')
        self.assertIn('Cured', label['title'][1])
        self.assertIn('Unheated', label['title'][1])
        self.assertNotIn('Raw', label['title'][1])
        self.assertNotIn('Cooked', label['title'][1])

    def test_frozen_and_cooked_are_both_visible(self):
        label = self.label('Beef, ground, patties, frozen, cooked, broiled')
        self.assertIn('Frozen', label['title'][1])
        self.assertIn('Cooked', label['title'][1])
        self.assertIn(['Fırında ızgara', 'Broiled'], label['traits'])

    def test_skin_bone_and_negation_are_explicit(self):
        label = self.label('Turkey, breast, skin and bone removed, not cooked')
        self.assertIn('Uncooked', label['title'][1])
        self.assertIn(['Derisiz', 'Skinless'], label['traits'])
        self.assertIn(['Kemik ayrılmış', 'Bone removed'], label['traits'])
        self.assertNotIn(['Derili', 'With skin'], label['traits'])
        label = self.label('Chicken, breast, boneless, oven roasted flavor, raw')
        self.assertEqual(label['title'][1], 'Meat · Cut · Raw')
        self.assertNotIn(['Fırında kızartılmış', 'Roasted'], label['traits'])

    def test_index_coverage_provenance_and_original_numeric_data(self):
        root = Path(__file__).resolve().parent.parent
        data = json.loads((root/'assets/data/food_index.json').read_text())
        source = json.loads((root/'docs/sources/NUTRITION_SOURCE.json').read_text())
        self.assertEqual(set(data['labels']), {key for key,item in data['items'].items() if len(item)>2})
        self.assertEqual(len(data['labels']), 1976)
        for label in data['labels'].values():
            self.assertEqual(len(label['title']), 2)
            self.assertTrue(all(0<len(t)<180 for t in label['title']))
            self.assertTrue(all(len(t)==2 for t in label['traits']))
        self.assertEqual(hashlib.sha256((root/'assets/data/foods.json').read_bytes()).hexdigest(), source['derived_sha256'])
        self.assertEqual(hashlib.sha256((root/'assets/data/food_index.json').read_bytes()).hexdigest(), source['browsing_index']['sha256'])


if __name__ == '__main__':
    unittest.main()
