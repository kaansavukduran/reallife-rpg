#!/usr/bin/env python3
"""UI-only category/family index. Does not rewrite nutrient values."""
import hashlib
import json
from pathlib import Path
import re
import sys
import zipfile

EXPECTED = '8308fd1d224ef1e5331093748007180da01a7ac713cbac6a1f5bc2a03e1ee70a'
CATEGORIES = {
    'fruit': ['Meyveler', 'Fruit'], 'vegetable': ['Sebzeler', 'Vegetables'],
    'legume': ['Baklagiller', 'Legumes'], 'grain': ['Tahıllar ve ekmek', 'Grains and bread'],
    'nut': ['Kuruyemiş ve tohum', 'Nuts and seeds'], 'dairy': ['Süt ürünleri ve yumurta', 'Dairy and eggs'],
    'meat': ['Et ve kümes hayvanları', 'Meat and poultry'], 'fish': ['Balık ve deniz ürünleri', 'Fish and seafood'],
    'fat': ['Yağlar', 'Fats and oils'], 'drink': ['İçecekler', 'Drinks'],
    'seasoning': ['Baharat ve soslar', 'Spices and sauces'], 'sweet': ['Tatlılar', 'Sweets'],
    'meal': ['Hazır yemek ve atıştırmalık', 'Prepared meals and snacks'],
    'baby': ['Bebek besinleri', 'Baby foods'], 'other': ['Diğer kaynak grupları', 'Other source groups'],
    'custom': ['Kendi besinlerim', 'My foods'],
}
GROUPS = {'0900':'fruit','1100':'vegetable','1600':'legume','0800':'grain','1800':'grain','2000':'grain','1200':'nut','0100':'dairy','0500':'meat','0700':'meat','1000':'meat','1300':'meat','1700':'meat','1500':'fish','0400':'fat','1400':'drink','0200':'seasoning','0600':'seasoning','1900':'sweet','2100':'meal','2200':'meal','2500':'meal','0300':'baby'}
TRANSLATIONS = {
    'Apples':'Elma','Apricots':'Kayısı','Avocados':'Avokado','Bananas':'Muz',
    'Blackberries':'Böğürtlen','Blueberries':'Yaban mersini','Cherries':'Kiraz',
    'Cranberries':'Turna yemişi','Dates':'Hurma','Figs':'İncir','Grapes':'Üzüm',
    'Grapefruit':'Greyfurt','Kiwifruit':'Kivi','Lemons':'Limon','Limes':'Misket limonu',
    'Mangos':'Mango','Melons':'Kavun','Nectarines':'Nektarin','Oranges':'Portakal',
    'Peaches':'Şeftali','Pears':'Armut','Pineapple':'Ananas','Plums':'Erik',
    'Pomegranates':'Nar','Quinces':'Ayva','Raspberries':'Ahududu','Strawberries':'Çilek',
    'Watermelon':'Karpuz','Broccoli':'Brokoli','Carrots':'Havuç','Cauliflower':'Karnabahar',
    'Cabbage':'Lahana','Celery':'Kereviz','Cucumber':'Salatalık','Eggplant':'Patlıcan',
    'Garlic':'Sarımsak','Lettuce':'Marul','Mushrooms':'Mantar','Onions':'Soğan',
    'Peppers':'Biber','Potatoes':'Patates','Spinach':'Ispanak','Tomatoes':'Domates',
    'Beans':'Fasulye','Chickpeas':'Nohut','Lentils':'Mercimek','Peas':'Bezelye',
    'Peanuts':'Yer fıstığı','Nuts':'Kuruyemiş','Seeds':'Tohumlar','Rice':'Pirinç',
    'Oats':'Yulaf','Wheat':'Buğday','Corn':'Mısır','Bread':'Ekmek','Pasta':'Makarna',
    'Egg':'Yumurta','Milk':'Süt','Cheese':'Peynir','Yogurt':'Yoğurt','Butter':'Tereyağı',
    'Beef':'Dana eti','Veal':'Dana eti','Lamb':'Kuzu eti','Pork':'Domuz eti',
    'Chicken':'Tavuk','Turkey':'Hindi','Fish':'Balık','Crustaceans':'Kabuklu deniz ürünleri',
    'Mollusks':'Yumuşakçalar','Oil':'Yağ','Water':'Su','Tea':'Çay','Coffee':'Kahve',
    'Spices':'Baharat','Honey':'Bal','Sugars':'Şeker','Salt':'Tuz',
}

# Generic USDA prefixes are groups, not individual foods. Split them one level
# deeper so almonds and walnuts (or salmon and tuna) never become "forms" of
# the same food in the picker.
GENERIC = {'Nuts','Seeds','Fish','Crustaceans','Mollusks','Beans','Cheese','Oil','Spices','Babyfood','Soup','Sauce','Salad dressing','Beverages','Snacks','Bread','Cereals ready-to-eat','Fast foods'}
DETAILS = {
 'almonds':'Badem','walnuts':'Ceviz','cashew nuts':'Kaju','hazelnuts or filberts':'Fındık','pistachio nuts':'Antep fıstığı','pecans':'Pikan cevizi','pine nuts':'Çam fıstığı','brazilnuts':'Brezilya cevizi','chestnuts':'Kestane','macadamia nuts':'Makadamya','coconut meat':'Hindistan cevizi','almond butter':'Badem ezmesi','chia seeds':'Chia tohumu','flaxseed':'Keten tohumu','sesame seeds':'Susam','sunflower seed kernels':'Ay çekirdeği','pumpkin and squash seed kernels':'Kabak çekirdeği','poppy seed':'Haşhaş tohumu',
 'salmon':'Somon','tuna':'Ton balığı','anchovy':'Hamsi','sardine':'Sardalya','mackerel':'Uskumru','cod':'Morina','trout':'Alabalık','sea bass':'Levrek','carp':'Sazan','herring':'Ringa','swordfish':'Kılıç balığı','tilapia':'Tilapya','shrimp':'Karides','crab':'Yengeç','lobster':'Istakoz','crayfish':'Kerevit','octopus':'Ahtapot','squid':'Kalamar','mussel':'Midye','oyster':'İstiridye','scallop':'Deniz tarağı',
 'feta':'Beyaz peynir','cheddar':'Çedar','mozzarella':'Mozzarella','parmesan':'Parmesan','cream':'Krem peynir','cottage':'Cottage peyniri','ricotta':'Ricotta','brie':'Brie','camembert':'Camembert',
 'olive':'Zeytinyağı','canola':'Kanola yağı','sunflower':'Ayçiçek yağı','soybean':'Soya yağı','sesame':'Susam yağı','coconut':'Hindistan cevizi yağı','corn':'Mısır yağı','peanut':'Yer fıstığı yağı','palm':'Palm yağı',
 'snap':'Taze fasulye','black':'Siyah fasulye','white':'Beyaz fasulye','kidney':'Kidney fasulye','lima':'Lima fasulyesi','mung':'Maş fasulyesi','pinto':'Pinto fasulye','adzuki':'Adzuki fasulyesi',
 'pepper, black':'Karabiber','pepper, white':'Beyaz biber','pepper, red or cayenne':'Kırmızı biber','cinnamon':'Tarçın','turmeric':'Zerdeçal','cumin seed':'Kimyon tohumu','oregano':'Oregano (kekik)','thyme':'Thyme (kekik)','ginger':'Zencefil','paprika':'Toz kırmızı biber','mustard seed':'Hardal tohumu','coriander seed':'Kişniş tohumu','basil':'Fesleğen','dill seed':'Dereotu tohumu','rosemary':'Biberiye','cloves':'Karanfil','nutmeg':'Muskat','allspice':'Yenibahar','cardamom':'Kakule','saffron':'Safran','bay leaf':'Defne yaprağı',
}
TRANSLATIONS.update({'Raisins':'Kuru üzüm','Soybeans':'Soya fasulyesi','Buckwheat':'Karabuğday','Quinoa':'Kinoa','Barley':'Arpa','Rye':'Çavdar','Chickpea flour':'Nohut unu'})

def family_name(description):
    parts = [part.strip() for part in description.split(',')]
    root = parts[0]
    if root in GENERIC and len(parts)>1:
        detail = parts[1]
        if root == 'Spices' and detail == 'pepper' and len(parts)>2:
            detail += ', ' + parts[2]
        name = root + ', ' + detail
        key = detail.lower()
        if root == 'Bread':
            tr = {'white':'Beyaz ekmek','whole-wheat':'Tam buğday ekmeği','rye':'Çavdar ekmeği','corn':'Mısır ekmeği','multi-grain':'Çok tahıllı ekmek','wheat':'Buğday ekmeği','wheat bran':'Kepekli ekmek','italian':'İtalyan ekmeği','pita':'Pita ekmeği','egg':'Yumurtalı ekmek'}.get(key)
        elif root == 'Cheese':
            allowed = {'feta','cheddar','mozzarella','parmesan','cream','cottage','ricotta','brie','camembert'}
            tr = DETAILS.get(key) if key in allowed else {'white':'Beyaz peynir','blue':'Küflü peynir','swiss':'İsviçre peyniri','edam':'Edam','gouda':'Gouda'}.get(key)
        elif root == 'Oil':
            allowed = {'olive','canola','sunflower','soybean','sesame','coconut','corn','peanut','palm'}
            tr = DETAILS.get(key) if key in allowed else {'walnut':'Ceviz yağı','almond':'Badem yağı','safflower':'Aspir yağı','rapeseed':'Kolza yağı','flaxseed':'Keten yağı','grapeseed':'Üzüm çekirdeği yağı','avocado':'Avokado yağı'}.get(key)
        elif root in {'Nuts','Seeds','Fish','Crustaceans','Mollusks','Beans','Spices'}:
            tr = DETAILS.get(key)
        else:
            tr = None
        if tr is None:
            tr = TRANSLATIONS.get(root,root) + ' · ' + detail
        return name,tr
    return root,TRANSLATIONS.get(root,root)

def main():
    archive = Path(sys.argv[1]); assert hashlib.sha256(archive.read_bytes()).hexdigest() == EXPECTED
    root = Path(__file__).resolve().parent.parent
    with zipfile.ZipFile(archive) as z:
        path = next(n for n in z.namelist() if Path(n).name == 'FOOD_DES.txt')
        rows = [[v.strip('~') for v in line.split('^')] for line in z.read(path).decode('iso-8859-1').splitlines() if line]
    descriptions = {r[0]:r for r in rows}
    families = {}; items = {}
    foods = json.loads((root/'assets/data/foods.json').read_text())
    for food in foods:
        ndb = re.search(r'NDB (\d+)', food['source']).group(1)
        row = descriptions[ndb]; category = GROUPS.get(row[1], 'other')
        prefix,label_tr = family_name(row[2]); family = category + '/' + prefix.casefold()
        families[family] = {'category':category,'tr':label_tr,'en':prefix}
        desc = row[2].lower()
        form = next((key for key in ['canned','frozen','dried','raw','cooked'] if key in desc), 'other')
        if form == 'other' and any(v in desc for v in ['roasted','boiled','fried','braised','grilled','baked','steamed']): form = 'cooked'
        items[food['id']] = [family,form]
    assert len(items) == len(foods) == 8789
    data = {'source_archive_sha256':EXPECTED,'categories':CATEGORIES,'families':families,'items':items}
    path = root/'assets/data/food_index.json'; path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
    print('Indexed',len(items),'foods;',len(families),'families;',hashlib.sha256(path.read_bytes()).hexdigest())

if __name__ == '__main__': main()
