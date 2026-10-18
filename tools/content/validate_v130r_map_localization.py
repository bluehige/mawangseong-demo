"""B05 catalog, placeholder, 0089a-name and priority-inventory contracts."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]

def load(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f'duplicate key: {path}: {key}')
            result[key] = value
        return result
    return json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=unique)

def validate():
    errors = []
    locales = load(ROOT/'data/localization/v130r_map_ui.json')['locales']
    tokens = re.compile(r'%[-+0#]*[0-9]*(?:\.[0-9]+)?[sdf]|\{\{[a-zA-Z_]+\}\}')
    for locale in ('en','zh_CN'):
        if set(locales[locale]) != set(locales['ko']): errors.append(f'{locale}: key-set mismatch')
        for key, source in locales['ko'].items():
            target = locales[locale].get(key, '')
            if not target.strip(): errors.append(f'{locale}:{key}: empty')
            if re.search('[가-힣ㄱ-ㅎㅏ-ㅣ]', target): errors.append(f'{locale}:{key}: Korean')
            if tokens.findall(source) != tokens.findall(target): errors.append(f'{locale}:{key}: placeholder drift')
    inventory = load(ROOT/'tools/tests/v130r_b05_inventory.json')
    if len(inventory) != 144 or {r['index'] for r in inventory} != set(range(144)): errors.append('incomplete priority inventory')
    for row in inventory:
        if locales['ko'].get(row['key']) != row['source']: errors.append(f"inventory source drift: {row['index']}")
    # Original proper names are a contract, never replaced with a new romanization.
    registry = load(ROOT/'data/v130r/story/speaker_registry.json')['species_names']
    for locale in ('en','zh_cn'):
        messages = load(ROOT/f'data/v130r/localization_{locale}.json')['messages']
        for species, names in registry.items():
            if messages.get(names['ko']) != names[locale]: errors.append(f'{locale}:{species}: 0089a name drift')
    for path in sorted({p.split(':')[0] for r in inventory for p in r['locations'] if 'Approved' in p}):
        source = (ROOT/path).read_text(encoding='utf-8')
        for key in re.findall(r'"(map\.[a-z0-9_]+)"', source):
            if key not in locales['ko']: errors.append(f'{path}: unknown key {key}')
    return {'result':'FAIL' if errors else 'PASS','map_keys':len(locales['ko']),'priority_candidates':len(inventory),'preserved_names':len(registry),'errors':errors}

if __name__ == '__main__':
    result = validate()
    print(json.dumps(result,ensure_ascii=False,indent=2))
    raise SystemExit(bool(result['errors']))
