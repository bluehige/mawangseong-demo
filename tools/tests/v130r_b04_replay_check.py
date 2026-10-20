"""Compare fresh play with an exact test-copy continuation, not a day fixture."""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TMP = ROOT / 'tmp/v130r_b04'
OUT = ROOT / '_mockup/game_step15_rebalance/replay_state_checks.json'

def load(path):
    return json.loads(path.read_text(encoding='utf-8'))

def normalize(state):
    value=deepcopy(state)
    payload=value['payload']
    payload['onboarding']['start_flow'].pop('play_seconds',None)
    unlocked=payload.get('achievements',{}).get('profile',{}).get('unlocked',{})
    for key in unlocked: unlocked[key]=True
    roles=payload.get('update3',{}).get('active_run',{}).get('run_metrics_update3',{}).get('duo_role_progress',{})
    tokens={}
    counts={}
    for role in sorted(roles):
        normalized=[]
        for token in roles[role].get('tokens',[]):
            if token not in tokens:
                parts=token.split(':')
                kind=':'.join(parts[:2])
                if len(parts)>4: kind+=':'+parts[-1]
                counts[kind]=counts.get(kind,0)+1
                tokens[token]=kind+':event_'+str(counts[kind])
            normalized.append(tokens[token])
        if 'tokens' in roles[role]: roles[role]['tokens']=normalized
    return value

def checked(label):
    folder=TMP/label
    run=load(folder/'run.json')
    checks=load(folder/'checks.json')
    assert run['exit_code']==0 and run['inputs_unchanged'] and run['peak_godot']==1
    assert not run['godot_after'] and not run['stderr'].strip() and not checks['failures']
    return load(folder/'input_hashes.json')

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('fresh')
    parser.add_argument('replay')
    parser.add_argument('--day',type=int,required=True)
    parser.add_argument('--next-day',type=int,required=True)
    parser.add_argument('--seed',type=int,default=130401)
    args=parser.parse_args()
    hashes=checked(args.fresh)
    assert hashes==checked(args.replay), 'Fresh and restored play must use identical source'
    key=(args.seed,args.day)
    first=next(r for r in load(TMP/args.fresh/'days.json') if (r['seed'],r['day'])==key)
    replay=next(r for r in load(TMP/args.replay/'days.json') if (r['seed'],r['day'])==key)
    assert first==replay, 'Every battle, settlement, growth, resource and placement field must match'
    name=f'{args.seed}_{args.next_day}.json'
    a,b=[load(TMP/label/'checkpoints'/name) for label in [args.fresh,args.replay]]
    assert list(a['payload']['world']['monster_roster'])==list(b['payload']['world']['monster_roster']), 'Preserve growth-choice roster order'
    assert list(a['payload']['world']['rooms'])==list(b['payload']['world']['rooms']), 'Preserve facility iteration order'
    assert normalize(a)==normalize(b), 'Entire next-entry state must match apart from declared ephemeral fields'
    result={'fresh':args.fresh,'replay':args.replay,'seed':args.seed,'day':args.day,'next_day':args.next_day,'identical_battle_fields':len(first),'next_entry_equal':True,'roster_and_room_order_equal':True,'input_hashes':hashes,'normalizations':['onboarding.start_flow.play_seconds','achievement unlock timestamps -> presence; unlocked ID set retained','duo_role_progress.tokens process identity/time -> event kind and ordinal; counts/order/identity equivalence retained'],'raw_sha256':{label:{file:hashlib.sha256((TMP/label/file).read_bytes()).hexdigest() for file in ['days.json','run.json',f'checkpoints/{name}']} for label in [args.fresh,args.replay]}}
    history=load(OUT) if OUT.exists() else {'cases':[]}
    history['cases'].append(result)
    OUT.write_text(json.dumps(history,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'battle_fields_equal':len(first),'next_entry_equal':True,'case_count':len(history['cases'])}))

if __name__=='__main__': main()
