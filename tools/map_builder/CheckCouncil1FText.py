"""Audit player-facing council strings; keep IDs and source paths as compatibility evidence."""
from pathlib import Path
import json,re,sys

ROOT=Path(__file__).resolve().parents[2]
PAT=re.compile(r'상층|2층|두 층|계단|층간|층 전환|층 전이|층 이동|같은 층|다른 층|upper(?:[ _-]?floor)?|stairs?|another floor|same floor|second floor|2nd floor|\b2F\b|上层|二层|两层|楼层|楼梯|跨层|2层',re.I)
INTERNAL=re.compile(r'^(?:res://|[A-Za-z0-9_.:/>-]+$)')
TEXT_KEYS={'display_name','title','description','body','subject','text','sign_text','story_beat','role','role_tag','short_effect','pressure_summary','level_2_text','cost','advantage','weakness','management_dialogue_header','lines','strengths','weaknesses','tone_keywords'}
hits=[]
def record(path,key,value,visible):
 if not PAT.search(value):return
 masked=re.sub(r'%[+\-]?\d*(?:\.\d+)?[fFgG]','',value)
 classification='NUMERIC_FORMAT' if not PAT.search(masked) else 'PLAYER_TEXT' if visible else 'INTERNAL_ID_OR_PATH'
 hits.append({'path':path,'key':key,'value':value,'classification':classification})
def walk(path,value,key='',text=False):
 if isinstance(value,dict):
  for k,v in value.items():walk(path,v,key+'.'+k,text or k in TEXT_KEYS or k in {'messages','supplemental_messages'})
 elif isinstance(value,list):
  for i,v in enumerate(value):walk(path,v,f'{key}[{i}]',text)
 elif isinstance(value,str):record(path,key,value,text)
for p in sorted((ROOT/'data/regular_version/update4').glob('*.json')):walk(p.relative_to(ROOT).as_posix(),json.loads(p.read_text(encoding='utf-8-sig')))
for name in ['ui_en.json','ui_zh_cn.json']:
 p=ROOT/'data/localization'/name;walk(p.relative_to(ROOT).as_posix(),json.loads(p.read_text(encoding='utf-8-sig')))
for directory in ['scripts','scenes']:
 for p in sorted((ROOT/directory).rglob('*')):
  if p.suffix not in ['.gd','.tscn']:continue
  for n,line in enumerate(p.read_text(encoding='utf-8-sig').splitlines(),1):
   for match in re.finditer(r'"(?:[^"\\]|\\.)*"',line):
    value=match.group()[1:-1]
    if PAT.search(value):record(p.relative_to(ROOT).as_posix(),str(n),value,not bool(INTERNAL.match(value)))
out=ROOT/'tmp/v130_council';out.mkdir(parents=True,exist_ok=True)
visible=[x for x in hits if x['classification']=='PLAYER_TEXT']
internal=sum(x['classification']=='INTERNAL_ID_OR_PATH' for x in hits)
numeric=sum(x['classification']=='NUMERIC_FORMAT' for x in hits)
(out/'text_search.json').write_text(json.dumps({'player_text_count':len(visible),'internal_count':internal,'numeric_format_count':numeric,'hits':hits},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Council player text remaining={len(visible)}; internal IDs/paths={internal}; numeric false positives={numeric}')
for x in visible:print(x['path'],x['key'],x['value'])
sys.exit(1 if visible else 0)
