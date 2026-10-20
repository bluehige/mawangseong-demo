"""Create a local definitions CSV with real Steam set IDs; never upload or edit catalog."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def prepare(set_ids, destination):
    data = ROOT / 'data/v130r/achievements'
    catalog = json.loads((data / 'achievements.json').read_text(encoding='utf8'))
    used_ids = set()
    for group in catalog['sets']:
        if group['id'] == 'base_campaign':
            continue
        value = set_ids.get(group['id'])
        if type(value) is not int or value <= 0:
            raise ValueError('Missing real positive Steam set ID: '+group['id'])
        if value in used_ids:
            raise ValueError('Steam set IDs must be distinct')
        used_ids.add(value)
    with (data / '5267750-achievements-definitions.template.csv').open(encoding='utf-8-sig', newline='') as file:
        reader = csv.DictReader(file)
        fields, rows = reader.fieldnames, list(reader)
    by_id = {row['api_name']: row for row in catalog['achievements']}
    if len(rows) != 100 or len(by_id) != 100 or {r['api_name'] for r in rows} != set(by_id):
        raise ValueError('Definitions must match all 100 runtime achievement API names')
    for row in rows:
        group = by_id[row['api_name']]['set']
        row['setid'] = '' if group == 'base_campaign' else str(set_ids[group])
    if any('REPLACE_WITH' in str(value) for row in rows for value in row.values()):
        raise ValueError('Unresolved REPLACE_WITH placeholder')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.DictWriter(file, fields)
        writer.writeheader(); writer.writerows(rows)
    # Keep the official app-specific filename so Steam can infer the app ID.
    localization = data / '5267750-achievements-localization.csv'
    localized = localization.read_text(encoding='utf-8-sig')
    if 'REPLACE_WITH' in localized:
        raise ValueError('Unresolved localization placeholder')
    (destination.parent / localization.name).write_text(localized, encoding='utf-8-sig')
    with (destination.parent / '5267750-achievement-sets-localization.csv').open(
            'w', encoding='utf-8-sig', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['setid', 'koreana', 'english', 'schinese'])
        for group in catalog['sets']:
            if group['id'] != 'base_campaign':
                writer.writerow([set_ids[group['id']], group['name_ko'],
                    group['name_en'], group['name_zh_cn']])
    return len(rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--set-ids', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'tmp/v130r_step13/5267750-achievements-definitions.csv')
    args = parser.parse_args()
    print(prepare(json.loads(args.set_ids.read_text(encoding='utf-8-sig')), args.output), 'definitions written locally')
