"""Source-derived UI summaries. Never writes or infers nutrient values."""
import re

STATES = [
    (r'\braw\b', 'Çiğ', 'Raw'),
    (r'\bcooked\b', 'Pişmiş', 'Cooked'),
    (r'\bprecooked\b', 'Ön pişmiş', 'Precooked'),
    (r'\buncooked\b', 'Pişirilmemiş', 'Uncooked'),
    (r'\bfrozen\b', 'Dondurulmuş', 'Frozen'),
    (r'\bcanned\b', 'Konserve', 'Canned'),
    (r'\bdried\b', 'Kurutulmuş', 'Dried'),
    (r'\bsmoked\b', 'Tütsülenmiş', 'Smoked'),
    (r'\bcured\b', 'Kürlenmiş', 'Cured'),
    (r'\bunheated\b', 'Isıtılmamış', 'Unheated'),
    (r'\bheated\b', 'Isıtılmış', 'Heated'),
    (r'\bunprepared\b', 'Hazırlanmamış', 'Unprepared'),
]
METHODS = [
    (r'\bpan-fried\b', 'Tavada kızartılmış', 'Pan-fried'),
    (r'\bstir-fried\b', 'Sote', 'Stir-fried'),
    (r'(?<!-)\bfried\b', 'Kızartılmış', 'Fried'),
    (r'\bpan-broiled\b', 'Yağ eklemeden tavada pişmiş', 'Pan-broiled'),
    (r'(?<!-)\bbroiled\b', 'Fırında ızgara', 'Broiled'),
    (r'\bpan-browned\b', 'Tavada esmerleştirilmiş', 'Pan-browned'),
    (r'\bgrilled\b', 'Izgara', 'Grilled'),
    (r'\broasted\b', 'Fırında kızartılmış', 'Roasted'),
    (r'\bbaked\b', 'Fırınlanmış', 'Baked'),
    (r'\bbraised\b', 'Ağır ateşte pişmiş', 'Braised'),
    (r'\bboiled\b', 'Haşlanmış', 'Boiled'),
    (r'\bstewed\b', 'Sulu pişmiş', 'Stewed'),
    (r'\bsimmered\b', 'Kısık ateşte suda pişmiş', 'Simmered'),
    (r'\bsteamed\b', 'Buharda pişmiş', 'Steamed'),
    (r'\bmicrowaved\b', 'Mikrodalgada pişmiş', 'Microwaved'),
]
TRAITS = [
    (r'\bboneless\b', 'Kemiksiz', 'Boneless'),
    (r'\bbone[- ]in\b', 'Kemikli', 'Bone-in'),
    (r'\bbone removed\b', 'Kemik ayrılmış', 'Bone removed'),
    (r'\b(?:skinless|without skin|skin removed|skin and bone removed)\b', 'Derisiz', 'Skinless'),
    (r'\bwith skin\b', 'Derili', 'With skin'),
    (r'\bmeat and skin\b', 'Derili et', 'Meat and skin'),
    (r'\bmeat only\b', 'Yalnız et', 'Meat only'),
    (r'\bskin only\b', 'Yalnız deri', 'Skin only'),
    # Lean-only is a sampled tissue fraction, NOT a claim of 0 g fat.
    (r'\bseparable lean only\b', 'Yalnız et kısmı', 'Separable lean only'),
    (r'\bseparable lean and fat\b', 'Et ve yağ birlikte', 'Separable lean and fat'),
    (r'\bseparable fat\b', 'Ayrılabilir yağ kısmı', 'Separable fat'),
    (r'\bexternal fat only\b', 'Yalnız dış yağ', 'External fat only'),
    (r'\bwith added solution\b', 'İlave çözeltili', 'With added solution'),
    (r'\bgrass-fed\b', 'Otla beslenmiş', 'Grass-fed'),
    (r'\baustralian\b', 'Avustralya kaynağı', 'Australian source'),
    (r'\bnew zealand\b', 'Yeni Zelanda kaynağı', 'New Zealand source'),
    (r'\b(?:battered|batter)\b', 'Hamur kaplamalı', 'Battered'),
    (r'\bbreaded\b', 'Galeta kaplamalı', 'Breaded'),
    (r'\bflour\b', 'Un kaplamalı', 'Flour coating'),
    (r'\bwith broth\b', 'Et suyuyla', 'With broth'),
    (r'\bwith water\b', 'Su eklenmiş', 'With water'),
    (r'\bdrained solids\b', 'Süzülmüş katı kısım', 'Drained solids'),
    (r'\blight meat\b', 'Beyaz et', 'Light meat'),
    (r'\bdark meat\b', 'Koyu et', 'Dark meat'),
    (r'\bmechanically (?:separated|deboned)\b', 'Mekanik ayrılmış', 'Mechanically separated'),
]


def meat_label(description, family, part):
    """Short bilingual title plus explicit qualifiers; exact source stays separate."""
    text = description.lower()
    # Parenthetical notes can describe future use ("cuts to be cured"). They
    # must not turn a fresh/raw entry into an already cured product.
    preparation = re.sub(r'\([^)]*\)', '', text)
    preparation = re.sub(r'[^,]*flavou?r[^,]*', '', preparation)
    preparation = re.sub(r'\bnot (?:fully )?cooked\b', 'uncooked', preparation)
    preparation = re.sub(r'\bnot heated\b', 'unheated', preparation)
    states = [[tr, en] for pattern, tr, en in STATES if re.search(pattern, preparation)]
    methods = [[tr, en] for pattern, tr, en in METHODS if re.search(pattern, preparation)]
    if methods and not any(s[1] in {'Raw', 'Cooked', 'Uncooked', 'Precooked'} for s in states):
        states.insert(0, ['Pişmiş', 'Cooked'])
    if not states:
        states = [['Hazırlama belirtilmemiş', 'Preparation not stated']]
    title = [' · '.join([family[i], part[i], *(s[i] for s in states)])
             for i in range(2)]
    traits = [[tr, en] for pattern, tr, en in TRAITS if re.search(pattern, text)]
    traits += methods
    # Only explicit composition percentages; "97% fat free" is NOT 97% fat.
    lean = re.search(r'(\d+(?:\.\d+)?)\s*%\s*lean(?: meat)?\b', text)
    fat = re.search(r'(\d+(?:\.\d+)?)\s*%\s*fat\b(?![- ]free)', text)
    if lean:
        n = lean[1]; traits.append([f'Kaynak bileşimi: %{n.replace(".", ",")} et', f'Source composition: {n}% lean'])
    if fat:
        n = fat[1]; traits.append([f'Kaynak bileşimi: %{n.replace(".", ",")} yağ', f'Source composition: {n}% fat'])
    fat_free = re.search(r'(?:(\d+(?:\.\d+)?)\s*%\s*)?fat[- ]free\b', text)
    if fat_free:
        n = fat_free[1]
        traits.append([f'Kaynak tanımı: {"%" + n + " " if n else ""}yağsız',
                       f'Source description: {n + "% " if n else ""}fat free'])
    trim = re.search(r'trimmed to\s+(\d+(?:/\d+)?)\s*"?\s*fat', text)
    if trim:
        traits.append([f'Dış yağ payı: {trim[1]} inç', f'External fat trim: {trim[1]} inch'])
    grade = re.search(r'\b(choice|select|prime|all grades)\b', text)
    if grade:
        name = grade[1].title()
        traits.append([f'Kaynak sınıfı: {name}', f'Source grade: {name}'])
    return {'title': title, 'traits': traits}
