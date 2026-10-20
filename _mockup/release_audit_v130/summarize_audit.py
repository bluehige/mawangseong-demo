"""Produce evidence indexes; never infer success from an exit code alone."""
from pathlib import Path
import collections, csv, hashlib, json, math, re, statistics, subprocess
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[1]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,v): p.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')

runs=[read(p) for p in sorted((OUT/'runs').glob('*.json'))]
write(OUT/'run_index.json',runs)
with (OUT/'run_index.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['id','exit_code','seconds','timeout','script_error','peak_rss_bytes','error_lines','warning_lines','stdout','stderr'])
    w.writeheader(); w.writerows({k:r.get(k) for k in w.fieldnames} for r in runs)

errors=collections.Counter(); warnings=collections.Counter(); examples={}
for r in runs:
    for kind in ['stdout','stderr']:
        p=ROOT/r[kind]
        for line in p.read_text(encoding='utf-8',errors='replace').splitlines():
            clean=re.sub(r'\x1b\[[0-9;]*m','',line).strip()
            if clean.startswith(('SCRIPT ERROR:','ERROR:')):
                errors[clean]+=1; examples.setdefault(clean,str(p.relative_to(OUT)))
            elif clean.startswith('WARNING:'):
                warnings[clean]+=1; examples.setdefault(clean,str(p.relative_to(OUT)))
write(OUT/'log_summary.json',{'runs':len(runs),'errors':sum(errors.values()),'warnings':sum(warnings.values()),'error_types':len(errors),'warning_types':len(warnings),'top20':[{'type':k,'count':v,'example':examples[k]} for k,v in (errors+warnings).most_common(20)],'all_errors':dict(errors),'all_warnings':dict(warnings)})

performance=[]
for p in sorted(OUT.glob('perf_*_1920x1080.json')):
    d=read(p); samples=sorted(d['samples_ms'])
    if not samples: continue
    row={k:d[k] for k in ['day','grade','actual_size','viewport','max_monsters','max_enemies','layout_msec','static_memory_bytes','video_memory_bytes','duration_msec']}
    row.update(samples=len(samples),mean_ms=statistics.mean(samples),p95_ms=samples[math.ceil(.95*len(samples))-1],p99_ms=samples[math.ceil(.99*len(samples))-1],mean_fps=1000/statistics.mean(samples),evidence=p.name)
    performance.append(row)
write(OUT/'performance_summary.json',performance)

campaigns=[]
for seed in [13011,13012,13013]:
    p=OUT/f'campaign_{seed}_days.json'
    if not p.exists(): continue
    rows=read(p); events=read(OUT/f'campaign_{seed}_events.json'); attempts=[]
    for r in rows:
        retry='retry' in r; r=r['retry'] if retry else r
        attempts.append({'seed':seed,'retry':retry,**{k:r.get(k) for k in ['day','grade','win','hp','max_hp','food','gold','duration']},'owned':len(r.get('owned',[])),'settlement':r.get('settlement',{}).get('food_ledger',{})})
    campaigns.append({'seed':seed,'max_entered_day':max(x['day'] for x in events),'ending_reached':any(x['screen']=='ending' for x in events),'attempts':attempts,'save_reload':[x for x in events if x['tag'] in ['save','reload']]})
write(OUT/'campaign_summary.json',campaigns)
with (OUT/'campaign_day01_30.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.writer(f); w.writerow(['seed','day','attempt','result','throne_hp','food','gold','owned','evidence'])
    for c in campaigns:
        for day in range(1,31):
            matches=[r for r in c['attempts'] if r['day']==day]
            if not matches: w.writerow([c['seed'],day,'','BLOCKED_BY_SCRIPT_ERROR' if day==c['max_entered_day'] and day>1 else 'NOT_REACHED','','','','',f'campaign_{c["seed"]}_events.json'])
            for i,r in enumerate(matches): w.writerow([c['seed'],day,i+1,'WIN' if r['win'] else 'DEFEAT',r['hp'],r['food'],r['gold'],r['owned'],f'campaign_{c["seed"]}_days.json'])
            final=next((r for r in runs if r['id']==f'campaign_final_{c["seed"]}'),{})
            if day==c['max_entered_day'] and final.get('script_error',False):
                w.writerow([c['seed'],day,len(matches)+1,'SCRIPT_ERROR_NO_RESULT','','','','',f'logs/campaign_final_{c["seed"]}.stderr.log'])

excerpts=[]; sources=[]
for p in sorted((ROOT/'docs/handoff').glob('V130R_STEP*.md')):
    m=re.search(r'STEP(\d+)',p.name)
    if not m or int(m[1])>12: continue
    sources.append(str(p.relative_to(ROOT)))
    lines=p.read_text(encoding='utf-8').splitlines(); selected=set()
    for i,line in enumerate(lines):
        if re.search('남은 차이|미해결|가정|보류|미검수|미실행|사용자 확인 대기|원문.*대조',line):
            selected.update(range(max(0,i-1),min(len(lines),i+5)))
        if re.match(r'^## 7[. ]',line):
            end=next((j for j in range(i+1,len(lines)) if lines[j].startswith('## ')),len(lines)); selected.update(range(i,end))
    excerpts.append('### '+str(p.relative_to(ROOT))+'\n\n'+ '\n'.join(f'{i+1}: {lines[i]}'.rstrip() for i in sorted(selected)))
(OUT/'handoff_remainders.md').write_text('# STEP1~12 잔여·가정 원문 색인\n\n분류와 후속 해소 대조는 handoff_review.md. 아래는 누락 확인용 원문 발췌이며 과거 지시를 재활성화하지 않는다.\n\n'+'\n\n'.join(excerpts),encoding='utf-8')
write(OUT/'handoff_source_index.json',sources)

integrity=[]
for label,filename in [('product','product_manifest.json'),('test_source','save_sources_before.json'),('player_original','player_save_hashes_before.json')]:
    for row in read(OUT/filename):
        p=Path(row['path']); p=p if p.is_absolute() else ROOT/p
        actual=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else 'MISSING'
        integrity.append({'group':label,'path':row['path'],'unchanged':actual==row['sha256'],'sha256':actual})
write(OUT/'integrity_final.json',integrity)
print(json.dumps({'runs':len(runs),'exit_zero':sum(r['exit_code']==0 for r in runs),'errors':sum(errors.values()),'warnings':sum(warnings.values()),'performance_scenarios':len(performance),'campaigns':len(campaigns),'handoffs':len(sources),'integrity_mismatches':sum(not r['unchanged'] for r in integrity)},ensure_ascii=True))
