"""Collect exactly seven Steam set IDs and build local CSVs, without network access."""
import json
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
data = root / 'data/v130r/achievements'
catalog = json.loads((data / 'achievements.json').read_text(encoding='utf-8'))
groups = [row for row in catalog['sets'] if row['id'] != 'base_campaign']
ids = {}
print('Enter the seven actual Steam achievement set IDs (not AppID or DepotID).')
for group in groups:
    while True:
        value = input(group['name_en'] + ' [' + group['id'] + ']: ').strip()
        if value.isdecimal() and int(value) > 0 and int(value) not in ids.values():
            ids[group['id']] = int(value)
            break
        print('Enter a distinct positive integer shown in Steamworks.')
output = root / 'Generated'
output.mkdir(exist_ok=True)
actual = output / 'set_ids.json'
actual.write_text(json.dumps(ids, indent=2) + '\n', encoding='utf-8')
subprocess.run([sys.executable, str(root / 'tools/achievements/prepare_steam_import.py'),
    '--set-ids', str(actual), '--output', str(output / '5267750-achievements-definitions.csv')], check=True)
for file in output.glob('*.csv'):
    if 'REPLACE_WITH' in file.read_text(encoding='utf-8-sig'):
        raise ValueError('Unresolved REPLACE_WITH in ' + str(file))
print('PASS: definitions and localization CSVs are in Achievements/Generated.')
