#!/usr/bin/env python3
"""Validate the staged v130r monster catalog without loading Godot or writing files.

Run from any directory: python tools/content/validate_v130r_monsters.py
Add --design-dir PATH to compare every supplied Korean design field verbatim.
This checks catalog availability, not runtime integration or actual duo unlocks.
"""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NEW_IDS = {
    'river_frog', 'glue_snail', 'bridge_troll', 'under_bed_shadow', 'hollow_armor',
    'candle_wisp', 'mole_digger', 'crumpled_map', 'rat_union', 'curse_doll',
}
FILL_IDS = {'spore_healer', 'stone_sentinel', 'war_drummer', 'moon_tracker', 'mimic_porter'}
COUNTS = {'monsters_new': 10, 'monster_instances_new': 10, 'characters_new': 10,
          'skills_new': 30, 'specializations_new': 32, 'memory_entries_new': 45, 'join_scenes': 10}
TEXT_KEYS = {'display_name', 'species_name', 'role', 'recommended_spot', 'planned_duo',
             'personality', 'story', 'description', 'role_tag', 'short_effect', 'title',
             'summary', 'quote', 'lines', 'shortage_status', 'rule_text', 'join_policy_note',
             'income_note', 'join_condition', 'roster_upkeep_text'}


def load(path):
    def unique_pairs(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f'{path}: duplicate key {key}')
            result[key] = value
        return result
    return json.loads(path.read_text(encoding='utf-8-sig'), object_pairs_hook=unique_pairs)


def baseline(root, filename, updates=()):
    result = load(root / 'data' / (filename + '.json'))
    for update in updates:
        result.update(load(root / 'data/regular_version' / update / (filename + '.json')))
    return result


def player_texts(value):
    result = set()
    if isinstance(value, dict):
        for key, item in value.items():
            if key in TEXT_KEYS:
                for text in item if isinstance(item, list) else [item]:
                    if isinstance(text, str) and re.search('[가-힣]', text):
                        result.add(text)
            result.update(player_texts(item))
    elif isinstance(value, list):
        for item in value:
            result.update(player_texts(item))
    return result


def validate(root=ROOT, design_dir=None):
    errors, notes = [], []
    checks = 0

    def check(ok, message):
        nonlocal checks
        checks += 1
        if not ok:
            errors.append(message)

    def required(row, fields, label):
        check(isinstance(row, dict) and set(fields) <= row.keys(), f'{label}: missing required fields')

    staged = {name: load(root / 'data/v130r' / (name + '.json')) for name in COUNTS}
    for name, expected in COUNTS.items():
        check(isinstance(staged[name], dict) and len(staged[name]) == expected, f'{name}: expected {expected} entries')
    mnew, inew, cnew, snew, pnew, enew, scenes = (staged[n] for n in COUNTS)
    check(set(mnew) == NEW_IDS, 'new monster IDs differ from agreed roster')
    base_m = baseline(root, 'monsters', ('update3', 'update4'))
    base_i = baseline(root, 'monster_instances', ('update4',))
    base_c = baseline(root, 'characters', ('update4',))
    base_s = baseline(root, 'skills', ('update4',))
    base_p = baseline(root, 'specializations', ('update4',))
    base_e = baseline(root, 'memory_entries')
    for label, new, old in [('monsters', mnew, base_m), ('instances', inew, base_i),
                            ('characters', cnew, base_c), ('skills', snew, base_s),
                            ('specializations', pnew, base_p), ('memories', enew, base_e)]:
        check(not (new.keys() & old.keys()), f'{label}: staged IDs collide with baseline')
    monsters, instances, characters = base_m | mnew, base_i | inew, base_c | cnew
    skills, specializations, memories = base_s | snew, base_p | pnew, base_e | enew

    stat_fields = ['max_hp', 'atk', 'def', 'move_speed', 'attack_range', 'attack_interval', 'int', 'loyalty']
    for mid, m in mnew.items():
        required(m, ['display_name', 'role', *stat_fields, 'sprite', 'skill_slots', 'recommended_spot',
                     'upkeep_food', 'join_day', 'contract_monster', 'instance_id', 'character_id',
                     'specialization_ids', 'bond_memory_ids', 'join_scene_id'], mid)
        for field in stat_fields:
            check(type(m.get(field)) in (int, float) and m[field] > 0, f'{mid}: invalid {field}')
        check('recommended_room' not in m, f'{mid}: old room recommendation used')
        check(type(m.get('upkeep_food')) is int and 1 <= m['upkeep_food'] <= 3, f'{mid}: invalid upkeep')
        check(type(m.get('join_day')) is int and 1 <= m['join_day'] <= 30, f'{mid}: invalid join day')
        check(m.get('contract_monster') is True, f'{mid}: contract marker missing')
        check(m.get('sprite') == '' and m.get('asset_status') == 'not_generated', f'{mid}: unexpected generated asset')
        check(m.get('instance_id') in inew and m.get('character_id') in cnew, f'{mid}: instance/character reference missing')
        check(m.get('join_scene_id') in scenes, f'{mid}: missing join scene')
        ids = m.get('skill_slots', [])
        check(len(ids) >= 2 and len(ids) == len(set(ids)), f'{mid}: need at least 2 unique skills')
        for sid in ids:
            check(sid in skills, f'{mid}: unknown skill {sid}')
        check(m.get('skills') == ids, f'{mid}: inconsistent skill list')
        check(m.get('passive_skill_ids') == [sid for sid in ids if snew.get(sid, {}).get('passive')], f'{mid}: passive refs mismatch')
        spec_ids = m.get('specialization_ids', [])
        check(len(spec_ids) == 2 and len(set(spec_ids)) == 2, f'{mid}: need exactly 2 specializations')
        for pid in spec_ids:
            check(pid in pnew and pnew[pid].get('monster_id') == mid, f'{mid}: invalid specialization {pid}')
        check(set(m.get('bond_memory_ids', {})) == {'1', '2', '3'}, f'{mid}: missing bond rank mapping')
        for rank, eid in m.get('bond_memory_ids', {}).items():
            check(eid in enew and enew[eid].get('monster_id') == mid and enew[eid].get('bond_rank') == int(rank),
                  f'{mid}: invalid memory {eid}')

    for iid, instance in inew.items():
        required(instance, ['instance_id', 'species_id', 'character_id', 'display_name', 'level', 'exp',
                            'bond', 'bond_rank', 'specialization_id', 'evolution_id',
                            'equipped_skill_ids', 'unlocked_memory_ids'], iid)
        mid, cid = instance.get('species_id'), instance.get('character_id')
        check(instance.get('instance_id') == iid and mid in mnew and cid in cnew, f'{iid}: invalid identity refs')
        check(mnew.get(mid, {}).get('instance_id') == iid and mnew.get(mid, {}).get('character_id') == cid, f'{iid}: reciprocal identity mismatch')
        check(instance.get('level') == 1 and all(instance.get(k) == 0 for k in ['exp', 'bond', 'bond_rank']), f'{iid}: unexpected initial progress')
        for sid in instance.get('equipped_skill_ids', []):
            check(sid in mnew.get(mid, {}).get('skills', []) and not skills.get(sid, {}).get('passive'), f'{iid}: bad equipped skill {sid}')
        check(instance.get('equipped_skill_ids') == [sid for sid in mnew.get(mid, {}).get('skills', []) if not skills.get(sid, {}).get('passive')], f'{iid}: incomplete active skill loadout')
        check(instance.get('specialization_id') == '' and instance.get('evolution_id') == '' and instance.get('unlocked_memory_ids') == [], f'{iid}: must not pre-unlock progression')

    for cid, c in cnew.items():
        required(c, ['display_name', 'category', 'species_group', 'faction', 'combat_side',
                     'implementation_scope', 'role_tags', 'unit_ref', 'portrait', 'generation_profile', 'personality', 'story'], cid)
        ref = c.get('unit_ref', {})
        check(ref.get('dataset') == 'monsters' and ref.get('id') in mnew, f'{cid}: invalid unit_ref')
        check(mnew.get(ref.get('id'), {}).get('character_id') == cid, f'{cid}: reciprocal character ref mismatch')
        check(bool(c.get('generation_profile', {}).get('identity_anchor')), f'{cid}: art identity missing')
        check('base' in c.get('portrait', {}) and {'happy', 'determined'} <= c.get('portrait', {}).get('variants', {}).keys(), f'{cid}: missing portrait plan')

    for sid, s in snew.items():
        required(s, ['display_name', 'icon', 'cost_mana', 'cooldown', 'description', 'type', 'passive', 'impl_note'], sid)
        check(s.get('type') in ('active', 'passive') and s.get('passive') == (s.get('type') == 'passive'), f'{sid}: skill type mismatch')
        check(type(s.get('cooldown')) in (int, float) and s['cooldown'] >= 0 and s.get('cost_mana') == 0, f'{sid}: invalid schema defaults')
        check(bool(s.get('description')) and bool(s.get('impl_note')), f'{sid}: missing design text')
    for pid, p in pnew.items():
        required(p, ['display_name', 'monster_id', 'role_tag', 'short_effect', 'description', 'stat_multipliers', 'stat_bonuses', 'skill_upgrade'], pid)
        check(p.get('monster_id') in monsters, f'{pid}: unknown monster owner')
        upgrade_sid = p.get('skill_upgrade', {}).get('skill_id')
        check(not upgrade_sid or upgrade_sid in skills, f'{pid}: unknown upgrade skill')
    for eid, e in enew.items():
        required(e, ['monster_id', 'bond_rank', 'title', 'summary', 'quote'], eid)
        check(e.get('monster_id') in monsters, f'{eid}: unknown monster owner')
        check(type(e.get('bond_rank')) is int and e['bond_rank'] in (1, 2, 3), f'{eid}: invalid bond rank')
        check(eid == f"bond_{e.get('monster_id')}_rank_{e.get('bond_rank')}", f'{eid}: incompatible rank-derived ID')
    for mid in NEW_IDS | FILL_IDS:
        check(sorted(e['bond_rank'] for e in enew.values() if e['monster_id'] == mid) == [1, 2, 3], f'{mid}: need 3 memories at ranks 1–3')
        check(sum(p['monster_id'] == mid for p in pnew.values()) == 2, f'{mid}: need 2 new specializations')
    check(sum(p['monster_id'] == 'kobold_scout' for p in pnew.values()) == 2, 'Rolo needs 2 specializations')

    for scene_id, scene in scenes.items():
        required(scene, ['monster_id', 'instance_id', 'character_id', 'join_day', 'lines', 'speaker_character_ids'], scene_id)
        mid = scene.get('monster_id')
        check(mid in mnew and scene_id == mnew.get(mid, {}).get('join_scene_id'), f'{scene_id}: invalid scene owner')
        check(scene.get('instance_id') == mnew.get(mid, {}).get('instance_id') and scene.get('character_id') == mnew.get(mid, {}).get('character_id'), f'{scene_id}: invalid scene identity')
        check(scene.get('join_day') == mnew.get(mid, {}).get('join_day'), f'{scene_id}: join day mismatch')
        check(len(scene.get('lines', [])) == len(scene.get('speaker_character_ids', [])) == 4, f'{scene_id}: dialogue alignment mismatch')
        for line, cid in zip(scene.get('lines', []), scene.get('speaker_character_ids', [])):
            match = re.fullmatch(r'\[([^|\]]+)\|([^\]]+)\]: .+', line)
            check(match is not None, f'{scene_id}: invalid [speaker|emotion] line')
            check(cid in characters, f'{scene_id}: unknown speaker {cid}')
            if match and cid in characters:
                display = characters[cid]['display_name']
                check(match[1] == display or display.endswith(' ' + match[1]) or (cid == 'CHR_DARKLORD_PLAYER' and match[1] == '마왕'), f'{scene_id}: speaker name/id mismatch')

    upkeep = load(root / 'data/v130r/upkeep.json')
    roster = upkeep.get('monsters', {})
    check(len(monsters) == len(roster) == 24 and roster.keys() == monsters.keys(), 'upkeep must cover all 24 monsters')
    for mid, row in roster.items():
        required(row, ['display_name', 'upkeep_food', 'join_condition', 'role', 'recommended_spot'], f'upkeep.{mid}')
        check(type(row.get('upkeep_food')) is int and 1 <= row['upkeep_food'] <= 3, f'upkeep.{mid}: invalid cost')
        if mid in mnew:
            check(row.get('upkeep_food') == mnew[mid]['upkeep_food'] and row.get('join_day') == mnew[mid]['join_day'], f'upkeep.{mid}: new monster mismatch')
    stages = upkeep.get('stages', [])
    expected_stages = [(1, 14, 15, 15, 30, '21'), (15, 19, 18, 23, 45, '31'),
                       (20, 26, 22, 30, 60, '40 (+전선 3마리 48)'), (27, 30, 26, 34, 75, '40~48')]
    check(len(stages) == 4, 'upkeep: expected 4 stages')
    for row, expected in zip(stages, expected_stages):
        check(tuple(row.get(k) for k in ['day_start', 'day_end', 'defense_spots', 'food_income_per_day', 'storage_capacity', 'roster_upkeep_text']) == expected, f'upkeep stage {row.get("stage")}: design numbers changed')
    rules = upkeep.get('settlement', {})
    check(rules.get('deployed_only') is True and rules.get('reserve_upkeep_food') == 0 and rules.get('next_battle_atk_multiplier') == 0.8 and rules.get('recovery_nest_allowed_when_hungry') is False and rules.get('monster_disappears') is False, 'upkeep shortage rules mismatch')
    check(upkeep.get('building_costs', {}).get('food_removed') is True and upkeep.get('building_costs', {}).get('removed_barracks_food') == 2, 'building food policy mismatch')

    # Cover returning Silky/Popo via their actual update4 bond-event definitions.
    bond_events = load(root / 'data/regular_version/update4/bond_events.json')
    coverage = []
    for mid in sorted(monsters):
        memory_ids = [eid for eid, e in memories.items() if e.get('monster_id') == mid]
        event_ids = [e['memory_id'] for e in bond_events.values() if e.get('species_id') == mid]
        pids = [pid for pid, p in specializations.items() if p.get('monster_id', p.get('species_id')) == mid]
        sids = [sid for sid in monsters[mid].get('skills', monsters[mid].get('skill_slots', [])) if sid]
        check(len(set(memory_ids + event_ids)) >= 3, f'{mid}: fewer than 3 memories')
        check(len(pids) == 2, f'{mid}: expected exactly 2 specializations, got {len(pids)}')
        check(len(sids) >= 2 and all(sid in skills for sid in sids), f'{mid}: missing valid skills')
        coverage.append({'monster_id': mid, 'memories': len(set(memory_ids + event_ids)), 'specializations': len(pids), 'skills': len(sids)})

    # Source-keyed translation coverage, dialogue markup, and numeric effect parity.
    texts = player_texts(staged) | player_texts(upkeep)
    names = {'골딘', '바티', '마왕', '밀로', '니아', '셀렌'} | {r['display_name'] for r in roster.values()}
    texts |= names
    localizations = {}
    for locale in ('en', 'zh_cn'):
        loc = load(root / 'data/v130r' / ('localization_' + locale + '.json'))
        messages = loc.get('messages', {})
        localizations[locale] = messages
        check(loc.get('schema_version') == 1 and loc.get('locale') == locale and loc.get('status') == 'draft', f'{locale}: localization metadata invalid')
        check(texts <= messages.keys(), f'{locale}: untranslated source keys: {sorted(texts - messages.keys())}')
        for source, translated in messages.items():
            check(isinstance(translated, str) and bool(translated.strip()) and not re.search('[가-힣]', translated), f'{locale}: blank or Korean fallback: {source}')
        for scene in scenes.values():
            for source in scene['lines']:
                match = re.fullmatch(r'\[([^|\]]+)\|([^\]]+)\]: .+', messages.get(source, ''))
                check(match is not None, f'{locale}: broken dialogue markup')
                if match:
                    speaker = source[1:source.index('|')]
                    check(match[1] == messages.get(speaker), f'{locale}: inconsistent speaker name {speaker}')
        for row in list(snew.values()) + list(pnew.values()):
            source = row['description']
            numbers = lambda text: sorted(re.findall(r'\d+(?:\.\d+)?', text))
            check(numbers(source) == numbers(messages.get(source, '')), f'{locale}: numeric effect changed: {source}')
        for name in names - {m['display_name'] for m in mnew.values()}:
            existing = load(root / 'data/localization' / ('ui_' + locale + '.json'))['messages'].get(name)
            check(not existing or messages.get(name) == existing, f'{locale}: returning name changed: {name}')
    check(localizations['en'].keys() == localizations['zh_cn'].keys(), 'localization key sets differ')

    duos = []
    links = load(root / 'data/regular_version/update3/duo_links.json')
    for lid, link in links.items():
        need = link.get('unlock_condition', {}).get('personal_memory_each', 1)
        members = []
        for iid in link['member_instance_ids']:
            check(iid in instances, f'{lid}: unknown member instance {iid}')
            mid = instances.get(iid, {}).get('species_id')
            before = sum(e.get('monster_id') == mid for e in base_e.values())
            after = sum(e.get('monster_id') == mid for e in memories.values())
            members.append({'instance_id': iid, 'monster_id': mid, 'baseline_memories': before,
                            'staged_memories': after, 'memory_requirement_possible': after >= need})
        check(all(m['memory_requirement_possible'] for m in members), f'{lid}: memory requirement remains impossible')
        duos.append({'id': lid, 'display_name': link['display_name'], 'required_each': need, 'members': members,
                     'scope': 'catalog_availability_only; bond/days/role/event/runtime not evaluated'})
    notes.append('Baseline empty-memory blockers: ' + ', '.join(d['id'] for d in duos if any(m['baseline_memories'] == 0 for m in d['members'])))
    notes.append('Historical baseline stored rank-derived IDs without catalog checks; Step7 now checks existence. Runtime behavior is verified separately in Godot.')
    notes.append('This Python report covers source data only. Run tools/run_v130r_step7.ps1 -Mode direct/capture for runtime skills, assets, recruitment and duo unlocks.')

    source_hashes = {}
    if design_dir is not None:
        source_path = design_dir / 'monsters_v130r_v1.json'
        source = load(source_path)
        for path in (source_path, design_dir / 'MONSTER_DESIGN_v130r_v1.md'):
            source_hashes[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
        for m in source['new_monsters']:
            mid = m['id']
            actual = mnew.get(mid, {})
            check(all(actual.get(k) == v for k, v in m['stats'].items()), f'{mid}: source stats mismatch')
            for target, original in [('display_name', 'name'), ('species_name', 'species'), ('role', 'role'), ('recommended_spot', 'line'), ('upkeep_food', 'upkeep'), ('join_day', 'join_day'), ('planned_duo', 'duo')]:
                check(actual.get(target) == m[original], f'{mid}: source {original} mismatch')
            c = cnew.get(actual.get('character_id'), {})
            check(c.get('personality') == m['personality'] and c.get('story') == m['story'] and c.get('generation_profile', {}).get('identity_anchor') == m['art'], f'{mid}: source character/art mismatch')
            check(scenes.get('join_' + mid, {}).get('lines') == m['join_scene'], f'{mid}: source dialogue changed')
            check(actual.get('skills') == [s['id'] for s in m['skills']], f'{mid}: source skill order mismatch')
            for s in m['skills']:
                a = snew.get(s['id'], {})
                check(all(a.get(t) == s[o] for t, o in [('display_name', 'name'), ('description', 'desc'), ('impl_note', 'impl'), ('type', 'type')]), f'{s["id"]}: source skill text changed')
                check(a.get('cooldown') == s.get('cooldown', 0), f'{s["id"]}: source cooldown changed')
                for key in ('trigger_hp_ratio', 'once_per_battle'):
                    check(a.get(key) == s.get(key), f'{s["id"]}: source {key} changed')
        all_items = [(m['id'], m) for m in source['new_monsters']] + list(source['existing_fill'].items())
        for mid, m in all_items:
            for e in m['memories']:
                a = enew.get(f'bond_{mid}_rank_{e["rank"]}', {})
                check(all(a.get(k) == e[k] for k in ('title', 'summary', 'quote')), f'{mid} rank {e["rank"]}: source memory changed')
            for p in m['specs']:
                a = pnew.get(p['id'], {})
                check(a.get('display_name') == p['name'] and a.get('description') == a.get('short_effect') == p['desc'], f'{p["id"]}: source specialization changed')
        for p in source['rolo_specializations']:
            a = pnew.get(p['id'], {})
            check(a.get('display_name') == p['name'] and a.get('description') == p['desc'], f'{p["id"]}: source Rolo specialization changed')
        # Parse chapter 2 costs and chapter 3 economy directly, without recomputing design totals.
        md = (design_dir / 'MONSTER_DESIGN_v130r_v1.md').read_text(encoding='utf-8-sig')
        chapter2 = md.split('## 2.')[1].split('## 3.')[0]
        cost_rows = [line for line in chapter2.splitlines() if line.startswith('| ')][1:]
        for line in cost_rows:
            columns = [c.strip() for c in line.strip('|').split('|')]
            labels = [n.strip().replace(' (신)', '') for n in columns[0].split('/')]
            costs = [int(n.strip()) for n in columns[3].split('/')]
            for name, cost in zip(labels, costs):
                row = next((r for r in roster.values() if r['display_name'] == name), {})
                check(row.get('upkeep_food') == cost, f'{name}: chapter 2 upkeep changed')
        chapter3 = md.split('## 3.')[1].split('## 4.')[0]
        stage_rows = [line for line in chapter3.splitlines() if line.startswith('| ')][1:]
        for line, stage in zip(stage_rows, stages):
            cols = [c.strip() for c in line.strip('|').split('|')]
            check(stage['roster_upkeep_text'] == cols[3] and stage['food_income_per_day'] == int(cols[4]) and stage['storage_capacity'] == int(cols[5]), f'stage {stage["stage"]}: chapter 3 changed')
    else:
        notes.append('Verbatim external design comparison not requested; use --design-dir to verify source text and stats.')
    return {'result': 'PASS' if not errors else 'FAIL', 'checks': checks, 'errors': errors,
            'counts': {k: len(v) for k, v in staged.items()}, 'roster_coverage': coverage,
            'localization_counts': {k: len(v) for k, v in localizations.items()},
            'duo_memory_availability': duos, 'source_sha256': source_hashes, 'notes': notes}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT, help='repository root (defaults to this script location)')
    parser.add_argument('--design-dir', type=Path, help='original JSON and Markdown directory, for verbatim comparison')
    parser.add_argument('--json', action='store_true', help='print complete JSON report to stdout')
    args = parser.parse_args()
    try:
        result = validate(args.root, args.design_dir)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f'FAIL: invalid input: {exc}', file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"{result['result']}: {result['checks']} checks, {len(result['errors'])} errors")
        print('Staged counts:', json.dumps(result['counts'], ensure_ascii=False))
        print('Roster: 24; memories >=3, specializations =2, skills >=2 (base + staged + update4 bond events)')
        print('Localization:', result['localization_counts'])
        for duo in result['duo_memory_availability']:
            counts = ', '.join(f"{m['monster_id']} {m['baseline_memories']}->{m['staged_memories']}" for m in duo['members'])
            print(f"DUO {duo['id']} (need {duo['required_each']} each): {counts}")
        for note in result['notes']:
            print('NOTE:', note)
        for error in result['errors']:
            print('ERROR:', error)
    return 0 if result['result'] == 'PASS' else 1


if __name__ == '__main__':
    sys.exit(main())
