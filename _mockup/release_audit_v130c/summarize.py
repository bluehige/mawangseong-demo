"""Summarize evidence without printing raw logs or changing product files."""
import csv
import hashlib
import json
import re
from run_audit import ROOT, OUT, engines, write

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))

campaigns=[]
csv_rows=[]
for seed in [130401,130402,130403]:
    day_path=OUT/f'campaign_{seed}_days.json'
    if not day_path.exists(): continue
    days=read(day_path)
    checks=read(OUT/f'campaign_{seed}_checks.json') if (OUT/f'campaign_{seed}_checks.json').exists() else {}
    restart=read(OUT/f'campaign_{seed}_resume_checks.json') if (OUT/f'campaign_{seed}_resume_checks.json').exists() else {}
    restored=read(OUT/f'campaign_{seed}_postgame_after.json') if (OUT/f'campaign_{seed}_postgame_after.json').exists() else {}
    ending=read(OUT/f'campaign_{seed}_ending_{seed}.json') if (OUT/f'campaign_{seed}_ending_{seed}.json').exists() else {}
    last=next((d for d in days if d['day']==30),{})
    campaigns.append(dict(seed=seed,recorded_days=len(days),battle_wins=sum(bool(d.get('win')) for d in days),retries=sum('retry' in d for d in days),day29=next((d for d in days if d['day']==29),None),ending=ending,hp=last.get('hp'),max_hp=last.get('max_hp'),campaign_checks=checks.get('checks'),campaign_failures=checks.get('failures'),restart_checks=restart.get('checks'),restart_failures=restart.get('failures'),resumed_day=restored.get('day'),resumed_postgame=restored.get('postgame'),rat_union_restored='rat_union' in restored.get('roster',{})))
    for day in days:
        csv_rows.append({k:day.get(k,'') for k in ['seed','day','grade','win','hp','max_hp','preparation_only','advanced','timeout']})
write(OUT/'campaign_summary.json',campaigns)
with (OUT/'campaign_day01_30.csv').open('w',newline='',encoding='utf-8') as file:
    writer=csv.DictWriter(file,fieldnames=['seed','day','grade','win','hp','max_hp','preparation_only','advanced','timeout']); writer.writeheader(); writer.writerows(csv_rows)

logs=[]
for path in sorted((OUT/'logs').glob('*.log')):
    text=path.read_text(encoding='utf-8',errors='replace')
    errors=re.findall(r'(?m)^(?:SCRIPT )?ERROR:.*$',text)
    warnings=re.findall(r'(?m)^WARNING:.*$',text)
    if path.name.startswith('campaign_') or path.name.startswith('restart_'): category='continuous_campaign_and_restart'
    elif path.name.startswith('exe'): category='native_exe_computer_use'
    elif path.name.startswith('windows_export'): category='windows_export'
    elif path.name.startswith('dialogue'): category='dialogue_0121b'
    elif path.name.startswith('legacy'): category='historical_copies'
    elif path.name.startswith('layout'): category='en_zh_layout'
    else: category='data_integrity'
    logs.append(dict(path=path.relative_to(ROOT).as_posix(),category=category,error_count=len(errors),warning_count=len(warnings),error_types=sorted(set(errors)),warning_types=sorted(set(warnings))))
write(OUT/'log_summary.json',dict(files=logs,total_errors=sum(x['error_count'] for x in logs),total_warnings=sum(x['warning_count'] for x in logs),historical_v130b_not_recounted=True))

baseline=read(OUT/'baseline_manifest.json')
changed=[]; missing=[]
for path,digest in baseline.items():
    p=ROOT/path
    if not p.exists(): missing.append(path)
    elif hashlib.sha256(p.read_bytes()).hexdigest()!=digest: changed.append(path)
waves=read(ROOT/'data/waves.json')
authorized_docs=['docs/handoff/CURRENT.md','docs/handoff/V130R_RELEASE_AUDIT_0121C_2026-10-19.md']
write(OUT/'integrity_final.json',dict(baseline_files=len(baseline),changed=changed,authorized_document_changes=[p for p in changed if p in authorized_docs],unexpected_changes=[p for p in changed if p not in authorized_docs],missing=missing,day29_empty=not waves.get('day_29'),waves_sha256=hashlib.sha256((ROOT/'data/waves.json').read_bytes()).hexdigest(),engines=engines()))
print(json.dumps(dict(campaigns=campaigns,log_errors=sum(x['error_count'] for x in logs),log_warnings=sum(x['warning_count'] for x in logs),existing_changed=len(changed),existing_missing=len(missing),engines=engines()),ensure_ascii=True))
