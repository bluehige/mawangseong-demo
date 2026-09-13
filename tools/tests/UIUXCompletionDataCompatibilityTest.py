"""Check that the completion work changes art paths, not content or game rules."""
import json, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
BASE="f38029c7d406577ca55e97c2a9bedf0e4f7cb607"
TABLES=["data/characters.json","data/monsters.json","data/enemies.json","data/evolution_rules.json",
"data/regular_version/update3/monsters.json","data/regular_version/update3/enemies.json",
"data/regular_version/update4/monsters.json","data/regular_version/update4/enemies.json",
"data/regular_version/update4/rival_bosses.json","data/regular_version/update4/crown_evolutions.json"]
def baseline(file):
    return json.loads(subprocess.check_output(["git","show",BASE+":"+file],cwd=ROOT))
count=0
def compare(old,new,path):
    global count
    count+=1
    if isinstance(old,dict):
        assert old.keys()==new.keys(),path+" keys changed"
        for key in old:compare(old[key],new[key],path+"/"+key)
    elif isinstance(old,list):
        assert len(old)==len(new),path+" list size changed"
        for index,(a,b) in enumerate(zip(old,new)):compare(a,b,path+"/"+str(index))
    elif old!=new:
        assert isinstance(old,str) and isinstance(new,str) and old.startswith("res://assets/") and new.startswith("res://assets/sprites/"),path+" gameplay value changed"
        assert ("/portrait/" in path) or path.rsplit("/",1)[-1] in {"sprite","sprite_sheet","combat_sprite"},path+" non-art field"
        assert (ROOT/new.removeprefix("res://")).is_file(),path+" missing runtime asset"
for file in TABLES:compare(baseline(file),json.loads((ROOT/file).read_text(encoding="utf-8")),file)
file="data/v122/combat_visual_profiles.json"
old=baseline(file);new=json.loads((ROOT/file).read_text(encoding="utf-8"))
for key in old:
    if key!="unit_overrides":
        assert old[key]==new[key],key+" shared visual profile changed"
        count+=1
for id,value in old["unit_overrides"].items():
    assert value.get("profile_id")==new["unit_overrides"][id].get("profile_id"),id+" body class changed"
    count+=1
print(f"UIUX_COMPLETION_DATA_COMPATIBILITY_TEST: PASS ({count} comparisons)")
