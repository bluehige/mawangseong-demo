"""Create a local definitions CSV with real Steam set IDs; never upload or edit catalog."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def prepare(set_ids, destination):
    data = ROOT / 'data/v130r/achievements'
    catalog = json.loads((data / 'achievements.json').read_text(encoding='utf8'))
    for group in catalog['sets']:
        if group['id'] == 'base_campaign':
            continue
        value = set_ids.get(group['id'])
        if type(value) is not int or value <= 0:
            raise ValueError('Missing real positive Steam set ID: '+group['id'])
    with (data / '5267750-achievements-definitions.template.csv').open(encoding='utf-8-sig', newline='') as file:
        reader = csv.DictReader(file)
        fields, rows = reader.fieldnames, list(reader)
    by_id = {row['api_name']: row for row in catalog['achievements']}
    for row in rows:
        group = by_id[row['api_name']]['set']
        row['setid'] = '' if group == 'base_campaign' else str(set_ids[group])
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.DictWriter(file, fields)
        writer.writeheader(); writer.writerows(rows)
    return len(rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--set-ids', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'tmp/v130r_step13/5267750-achievements-definitions.csv')
    args = parser.parse_args()
    print(prepare(json.loads(args.set_ids.read_text(encoding='utf-8-sig')), args.output), 'definitions written locally')
