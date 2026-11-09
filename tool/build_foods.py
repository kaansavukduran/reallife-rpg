#!/usr/bin/env python3
"""Compile the complete public-domain USDA SR28 archive + curated TR names.

python3 tool/build_foods.py /tmp/reallife-usda-sr28.zip /path/to/besinmatriksi
The reference checkout is read only. Values always come from the verified
official archive; translations never substitute values or a different food.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile

EXPECTED = '8308fd1d224ef1e5331093748007180da01a7ac713cbac6a1f5bc2a03e1ee70a'
MAPPING = {
    'energy': ('208', 'kcal'), 'protein': ('203', 'g'),
    'carb': ('205', 'g'), 'fat': ('204', 'g'), 'fiber': ('291', 'g'),
    'sugars': ('269', 'g'), 'ca': ('301', 'mg'), 'fe': ('303', 'mg'),
    'mg': ('304', 'mg'), 'k': ('306', 'mg'), 'na': ('307', 'mg'),
    'zn': ('309', 'mg'), 'se': ('317', 'µg'), 'vitc': ('401', 'mg'),
    'b12': ('418', 'µg'), 'vitd': ('328', 'µg'), 'folate': ('417', 'µg'),
    'vita_rae': ('320', 'µg'), 'vite': ('323', 'mg'), 'vitk': ('430', 'µg'),
}

def main():
    archive, reference = Path(sys.argv[1]), Path(sys.argv[2])
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == EXPECTED
    root = Path(__file__).resolve().parent.parent
    with zipfile.ZipFile(archive) as z:
        def raw(name):
            return z.read(next(n for n in z.namelist() if Path(n).name == name))
        def rows(name):
            return ([v.strip('~') for v in line.split('^')]
                    for line in raw(name).decode('iso-8859-1').splitlines() if line)
        definitions = {r[0]: r for r in rows('NUTR_DEF.txt')}
        for key, (nutrient_id, unit) in MAPPING.items():
            assert definitions[nutrient_id][1] == unit, (key, definitions[nutrient_id])
        by_nutrient = {v[0]: k for k, v in MAPPING.items()}
        values = {}
        for row in rows('NUT_DATA.txt'):
            if row[1] in by_nutrient and row[2] != '':
                n = float(row[2])
                assert 0 <= n <= 1000000
                values.setdefault(row[0], {})[by_nutrient[row[1]]] = n
        descriptions = {r[0]: r[2] for r in rows('FOOD_DES.txt')}
        curated = json.loads((reference / 'src/data/foods.json').read_text())
        foods, covered = [], set()
        for food in curated['foods']:
            for form in food['forms']:
                if not form.get('usda') or form.get('ifct') or form.get('estFrom'):
                    continue
                ndb = form['usda']['ndb']
                if ndb not in descriptions:
                    continue
                covered.add(ndb)
                foods.append({'id': food['id'] + ':' + form['key'],
                              'tr': food['tr'] + ' · ' + form['label'],
                              'en': descriptions[ndb], 'source': 'USDA SR28 / NDB ' + ndb,
                              'values': values.get(ndb, {})})
        for ndb, name in descriptions.items():
            if ndb not in covered:
                foods.append({'id': 'usda:' + ndb, 'tr': name, 'en': name,
                              'source': 'USDA SR28 / NDB ' + ndb,
                              'values': values.get(ndb, {})})
        assert len({f['id'] for f in foods}) == len(foods)
        output = root / 'assets/data/foods.json'
        output.write_text(json.dumps(foods, ensure_ascii=False, separators=(',', ':')))
        meta = {'archive_url': 'https://www.ars.usda.gov/ARSUserFiles/80400535/DATA/SR/sr28/dnload/sr28asc.zip',
                'archive_sha256': EXPECTED, 'encoding': 'Official ISO-8859-1 decoded to UTF-8 JSON',
                'reference': 'https://github.com/kaansavukduran/besinmatriksi',
                'reference_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=reference, text=True).strip(),
                'records': len(foods), 'distinct_usda_foods': len(descriptions),
                'components': {k: {'usda': v[0], 'unit': v[1]} for k, v in MAPPING.items()},
                'raw_sha256': {name: hashlib.sha256(raw(name)).hexdigest() for name in ['FOOD_DES.txt', 'NUT_DATA.txt', 'NUTR_DEF.txt']},
                'derived_sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                'policy': 'Only direct official USDA values per 100 g edible portion; missing values absent; no IFCT; curated TR names where available, other source names English.'}
        (root / 'docs/sources/NUTRITION_SOURCE.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2))
        print(f'{len(foods)} records, {len(descriptions)} distinct USDA foods, all 20 units checked')

if __name__ == '__main__':
    main()
