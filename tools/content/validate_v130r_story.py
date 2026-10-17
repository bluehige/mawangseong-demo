#!/usr/bin/env python3
"""Validate staged story text only. Never starts Godot or opens a user save.

python -X utf8 tools/content/validate_v130r_story.py --write-report
"""
import argparse
import collections
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FILES = ('join_scenes.json', 'day_overlays.json', 'barks.json',
         'bond_scenes.json', 'duo_scenes.json')
EVENTS = {'deployed', 'engagement_started', 'skill_used', 'hp_below_30',
          'ally_downed', 'victory', 'hungry'}
TEXT_FIELDS = {'title', 'speaker_label', 'emotion_direction', 'text', 'line'}
EXPECTED_NEW_PAIRS = {
    frozenset(p) for p in (
        ('river_frog', 'spider_tailor'), ('glue_snail', 'imp'),
        ('bridge_troll', 'goblin'), ('under_bed_shadow', 'moon_tracker'),
        ('hollow_armor', 'armored_beetle'), ('candle_wisp', 'imp'),
        ('mole_digger', 'stone_sentinel'), ('crumpled_map', 'kobold_scout'),
        ('rat_union', 'mimic_porter'), ('curse_doll', 'spider_tailor'))}


def load(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f'{path}: duplicate JSON key: {key}')
            result[key] = value
        return result
    return json.loads(Path(path).read_text(encoding='utf-8'), object_pairs_hook=unique)


def blocks(scene):
    return scene.get('segments', [scene])


def cues(document):
    for scene in document['scenes']:
        for block in blocks(scene):
            yield from block['cues']


def validate(root=ROOT, story_dir=None):
    root = Path(root)
    folder = Path(story_dir) if story_dir else root / 'data/v130r/story'
    errors, checks = [], 0

    def check(ok, message):
        nonlocal checks
        checks += 1
        if not ok:
            errors.append(message)

    docs = {name: load(folder / name) for name in FILES}
    registry = load(folder / 'speaker_registry.json')
    speakers = registry['speakers']
    species = registry['species_character_ids']
    reverse = {cid: mid for mid, cid in species.items()}
    roster = load(root / 'data/v130r/upkeep.json')['monsters']
    expanded = set(roster) - {'slime', 'goblin', 'imp', 'kobold_scout'}
    check(set(species) == set(roster) and len(species) == 24, 'registry: expected exact 24-species roster')
    source_chars = load(root / 'data/characters.json') | load(root / 'data/regular_version/update4/characters.json') | load(root / 'data/v130r/characters_new.json')
    known_emotions = {'base', 'happy', 'determined', 'none'}
    for row in source_chars.values():
        known_emotions.update(row.get('portrait', {}).get('variants', {}))
        known_emotions.update(row.get('portraits', {}))
    for cid, row in speakers.items():
        check(cid == 'NARRATOR' or cid in source_chars, f'{cid}: unknown source character')
        for emotion, path in row['portrait_slots'].items():
            check(emotion in known_emotions, f'{cid}: unknown portrait emotion {emotion}')
            check((cid == 'NARRATOR' and emotion == 'none' and path == '') or
                  (path.startswith('res://') and (root / path[6:]).is_file()),
                  f'{cid}: missing portrait asset {emotion}: {path}')
        for locale in ('en', 'zh_cn'):
            for mid, mcid in species.items():
                if cid == mcid:
                    expected = load(root / f'data/v130r/localization_{locale}.json')['messages'][roster[mid]['display_name']]
                    check(row['localized_labels'][locale] == expected, f'{cid}: 0089a name drift ({locale})')

    ids = set()
    for filename, d in docs.items():
        check(d.get('schema_version') == 1 and d.get('locale') == 'ko', f'{filename}: invalid metadata')
        for scene in d['scenes']:
            check(scene['id'] not in ids, f'duplicate scene ID: {scene["id"]}')
            ids.add(scene['id'])
            check(scene.get('side_effects') == [], f'{scene["id"]}: story must have no state effects')
            for block in blocks(scene):
                owned = set(block.get('conditions', scene.get('conditions', {})).get('requires_owned_species_ids', []))
                check(owned <= roster.keys(), f'{block["id"]}: invalid roster gate')
                for c in block['cues']:
                    check(c['id'] not in ids, f'duplicate cue ID: {c["id"]}')
                    ids.add(c['id'])
                    cid = c.get('speaker_id')
                    check(cid in speakers, f'{c["id"]}: unknown speaker {cid}')
                    if cid not in speakers:
                        continue
                    row = speakers[cid]
                    check(c['speaker_label'] == row['label'], f'{c["id"]}: speaker label mismatch')
                    check(row['emotion_map'].get(c['emotion_direction']) == c['portrait_emotion'] and
                          c['portrait_emotion'] in row['portrait_slots'], f'{c["id"]}: emotion mapping mismatch')
                    check(isinstance(c['text'], str) and bool(c['text'].strip()), f'{c["id"]}: empty text')
                    check(c['line'] == f"[{c['speaker_label']}|{c['emotion_direction']}]: {c['text']}", f'{c["id"]}: markup mismatch')
                    check(cid not in reverse or reverse[cid] in owned, f'{c["id"]}: monster speaker lacks ownership gate')

    join_scenes = docs['join_scenes.json']['scenes']
    check(len(join_scenes) == 40, 'joins: expected 20 management + 20 first battle scenes')
    seeds = load(root / 'data/v130r/join_scenes.json')
    for mid in expanded:
        rows = [s for s in join_scenes if s['monster_id'] == mid]
        check(len(rows) == 2, f'{mid}: missing join or first battle')
        for s in rows:
            management = s['trigger'] == 'management_entered'
            check(8 <= len(s['cues']) <= 14 if management else 2 <= len(s['cues']) <= 4,
                  f'{s["id"]}: turn count out of range')
            check(s['trigger'] in ('management_entered', 'precombat_confirmed'), f'{s["id"]}: invalid trigger')
            check(s['conditions']['existing_join_condition_first'] and
                  s['conditions']['fallback_day'] == roster[mid].get('join_day'), f'{s["id"]}: changed join policy')
            if not management:
                check(s.get('requires_first_deployment') and 29 in s.get('exclude_days', []), f'{s["id"]}: first battle/day29 gate missing')
            if management and mid in load(root / 'data/v130r/monsters_new.json'):
                check([c['line'] for c in s['cues'][:4]] == seeds['join_'+mid]['lines'], f'{mid}: original four-line seed changed')
    check({s['monster_id'] for s in join_scenes} == expanded, 'joins: roster mismatch')

    overlay_scenes = docs['day_overlays.json']['scenes']
    check(sorted(s['day'] for s in overlay_scenes) == list(range(1, 31)), 'overlays: must contain DAY 1..30 exactly once')
    appearances = collections.defaultdict(set)
    for s in overlay_scenes:
        day = s['day']
        base = load(root / f'data/story/v122_main/day_{day:02}.json')
        anchors = {x['id']: x for x in base['scenes']}
        check(s['insert_after_scene_id'] in anchors, f'DAY {day}: missing insertion anchor')
        check(s['trigger'] == 'management_entered', f'DAY {day}: expected management-only staging')
        check(s['missing_participant_policy'] == 'skip_segment_preserve_original', f'DAY {day}: unsafe skip policy')
        count = sum(len(b['cues']) for b in s['segments'])
        participants = {reverse[c['speaker_id']] for b in s['segments'] for c in b['cues'] if c['speaker_id'] in reverse}
        check(2 <= count <= 6 and 1 <= len(participants) <= 3, f'DAY {day}: overlay size invalid')
        for mid in participants:
            appearances[mid].add(day)
            check(day >= roster[mid].get('join_day', 1), f'DAY {day}: {mid} appears before fallback join day')
        for cid in s['anchor_character_ids']:
            check(cid in source_chars, f'DAY {day}: invalid event character {cid}')
        if day == 29:
            check(s['trigger'] == 'management_entered' and 'precombat' not in s['id'].lower(), 'DAY 29 must have no battle')
    for mid in expanded:
        check(len(appearances[mid]) >= 3, f'{mid}: fewer than three distinct overlay days')

    bark_scenes = docs['barks.json']['scenes']
    check(len(bark_scenes) == 168, 'barks: expected 24 x 7')
    for mid in roster:
        rows = [s for s in bark_scenes if s['monster_id'] == mid]
        check(len(rows) == 7 and {s['trigger'] for s in rows} == EVENTS, f'{mid}: incomplete bark events')
        for s in rows:
            check(len(s['cues']) == 1 and s['cues'][0]['speaker_id'] == species[mid], f'{s["id"]}: invalid bark speaker/length')
            check(s['repeat_policy'] == 'cooldown' and s['cooldown_seconds'] == 25.0, f'{s["id"]}: bark cooldown drift')
            if s['trigger'] == 'hp_below_30':
                check(s['hp_threshold'] == 0.3, f'{mid}: HP threshold changed')

    memories = load(root / 'data/memory_entries.json') | load(root / 'data/v130r/memory_entries_new.json')
    u4 = load(root / 'data/regular_version/update4/bond_events.json')
    bond_scenes = docs['bond_scenes.json']['scenes']
    check(len(bond_scenes) == 72, 'bonds: expected 24 x 3')
    for mid in roster:
        rows = [s for s in bond_scenes if s['monster_id'] == mid]
        check(sorted(s['memory_stage'] for s in rows) == [1, 2, 3], f'{mid}: incomplete memory stages')
        for s in rows:
            check(4 <= len(s['cues']) <= 8, f'{s["id"]}: bond turn count')
            check(s['context'] == 'memory_recollection' and s['memory_id'] in s['conditions']['requires_unlocked_memory_ids'], f'{s["id"]}: unsafe memory gate')
            e = (u4 if s['source_ref'].endswith('bond_events.json') else memories)[s['source_entry_id']]
            check(s['title'] == e['title'] and s['cues'][0]['speaker_id'] == 'NARRATOR' and s['cues'][0]['text'] == e.get('summary', e.get('text')), f'{s["id"]}: memory title/summary drift')
            if 'quote' in e:
                check(s['cues'][1]['text'] == e['quote'], f'{s["id"]}: memory quote drift')
            else:
                check(s['memory_id'] == e['memory_id'] and s['conditions']['original_bond_threshold'] == e['bond_threshold'] and s['conditions']['original_mode_gates_preserved'], f'{s["id"]}: update4 gate drift')

    links = load(root / 'data/regular_version/update3/duo_links.json')
    new_links = load(root / 'data/v130r/duo_links_new.json')
    instances = load(root / 'data/monster_instances.json') | load(root / 'data/regular_version/update4/monster_instances.json') | load(root / 'data/v130r/monster_instances_new.json')
    duo_scenes = docs['duo_scenes.json']['scenes']
    check(len(duo_scenes) == 16 and len({s['duo_id'] for s in duo_scenes}) == 16, 'duos: need 16 unique links')
    check({s['duo_id'] for s in duo_scenes if s['duo_id'] in links} == links.keys(), 'duos: missing existing link')
    check({frozenset(s['member_species_ids']) for s in duo_scenes if s['duo_id'] not in links} == EXPECTED_NEW_PAIRS, 'duos: new pair mismatch')
    for s in duo_scenes:
        check(6 <= len(s['cues']) <= 10, f'{s["id"]}: duo turn count')
        check(set(s['member_species_ids']) == set(s['conditions']['requires_owned_species_ids']) and s['conditions']['requires_external_unlock_event'], f'{s["id"]}: unsafe unlock gate')
        if s['duo_id'] in links:
            original = links[s['duo_id']]
            check(s['conditions']['original_unlock_condition'] == original['unlock_condition'], f'{s["id"]}: original unlock drift')
            check(set(s['member_species_ids']) == {instances[x]['species_id'] for x in original['member_instance_ids']}, f'{s["id"]}: original duo members drift')
        else:
            definition = new_links.get(s['duo_id'], {})
            check(s['conditions'].get('original_unlock_condition') == definition.get('unlock_condition') and bool(definition), f'{s["id"]}: new unlock drift')
            condition = definition.get('unlock_condition', {})
            check([condition.get(k) for k in ('bond_each', 'personal_memory_each', 'deployed_together_days', 'role_combo_count')] == [45, 1, 3, 5], f'{s["id"]}: new unlock values')
            check(set(s['member_species_ids']) == {instances[x]['species_id'] for x in definition.get('member_instance_ids', [])}, f'{s["id"]}: new duo members drift')
            check(definition.get('effect_handler', '').startswith('v130r_') and len(definition.get('gauge_sources', [])) == 2 and definition.get('max_uses_per_battle') == 1, f'{s["id"]}: missing new effect/gauge')

    def parity(ko, tr, locale, path='', key=None):
        check(type(ko) is type(tr), f'{locale}:{path}: type mismatch')
        if type(ko) is not type(tr):
            return
        if isinstance(ko, dict):
            check(ko.keys() == tr.keys(), f'{locale}:{path}: key mismatch')
            for k in ko.keys() & tr.keys():
                parity(ko[k], tr[k], locale, path+'/'+k, k)
        elif isinstance(ko, list):
            check(len(ko) == len(tr), f'{locale}:{path}: list length mismatch')
            for i, (a, b) in enumerate(zip(ko, tr)):
                parity(a, b, locale, path+f'/{i}', key)
        elif key in TEXT_FIELDS:
            check(isinstance(tr, str) and bool(tr.strip()) and not re.search('[가-힣]', tr), f'{locale}:{path}: missing translation')
            check(not re.search(r'\b(TODO|TBD|PLACEHOLDER)\b', tr), f'{locale}:{path}: placeholder translation')
        else:
            check(tr == (locale if key == 'locale' else ko), f'{locale}:{path}: structural value changed')
    locale_counts = {}
    for locale in ('en', 'zh_cn'):
        translated = load(folder / f'localization_story_{locale}.json')
        check(translated.get('locale') == locale and translated.get('status') == 'draft', f'{locale}: invalid metadata')
        check(translated['documents'].keys() == docs.keys(), f'{locale}: document set mismatch')
        for filename, ko in docs.items():
            if filename not in translated['documents']:
                continue
            tr = translated['documents'][filename]
            parity(ko, tr, locale, filename)
            for c in cues(tr):
                if c['speaker_id'] not in speakers:
                    continue
                check(c['speaker_label'] == speakers[c['speaker_id']]['localized_labels'][locale], f'{c["id"]}:{locale}: localized name drift')
                check(c['line'] == f"[{c['speaker_label']}|{c['emotion_direction']}]: {c['text']}", f'{c["id"]}:{locale}: localized markup mismatch')
        locale_counts[locale] = sum(1 for d in translated['documents'].values() for c in cues(d))

    manifest = load(folder / 'manifest.json')
    check(manifest['runtime_connected'] is True and manifest['runtime_side_effects'] == [] and
          (root / manifest['runtime_adapter'][6:]).is_file(), 'manifest: missing runtime adapter or unexpected story side effects')
    for group in ('source_sha256', 'protected_sha256'):
        for path, digest in manifest[group].items():
            check(hashlib.sha256((root / path).read_bytes()).hexdigest() == digest, f'protected/source file drift: {path}')
    counts = {filename: sum(1 for _ in cues(d)) for filename, d in docs.items()}
    check(all(n == sum(counts.values()) for n in locale_counts.values()), 'translation turn totals differ')
    coverage = []
    for mid, cid in species.items():
        per_file = {filename: sum(c['speaker_id'] == cid for c in cues(d)) for filename, d in docs.items()}
        coverage.append({'monster_id': mid, 'name': roster[mid]['display_name'],
                         'overlay_days': sorted(appearances[mid]), 'overlay_day_count': len(appearances[mid]),
                         'spoken_turns': sum(per_file.values()), 'spoken_turns_by_file': per_file})
    return {'result': 'PASS' if not errors else 'FAIL', 'checks': checks, 'errors': errors,
            'scene_counts': {k: len(d['scenes']) for k, d in docs.items()},
            'turns_by_file': counts, 'total_turns': sum(counts.values()),
            'localized_turns': locale_counts, 'monster_coverage': coverage,
            'protected_file_count': len(manifest['protected_sha256']),
            'scope': 'static story/duo data contracts; runtime checked separately by V130RStep11StoryTest',
            'notes': ['Overlay counts are authored opportunities under ownership gates, not guaranteed single-run appearances.',
                      'Memory narration counts as one turn; every bond scene also has three spoken turns.',
                      'New duos use the user-confirmed 45/1/3/5 unlock requirements.']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--story-dir', type=Path)
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--write-report', action='store_true', help='write only _mockup/story_v130r/validation_report.json')
    args = parser.parse_args()
    try:
        result = validate(args.root, args.story_dir)
    except (OSError, ValueError, KeyError, TypeError, IndexError) as exc:
        print(f'FAIL: invalid story input: {exc}', file=sys.stderr)
        return 1
    if args.write_report:
        path = args.root / '_mockup/story_v130r/validation_report.json'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"{result['result']}: {result['checks']} checks; {len(result['errors'])} errors; {result['total_turns']} turns per language")
        print('Monster | Overlay DAYs | Spoken turns')
        for row in result['monster_coverage']:
            print(f"{row['name']} ({row['monster_id']}) | {','.join(map(str, row['overlay_days'])) or '-'} | {row['spoken_turns']}")
        for error in result['errors']:
            print('ERROR:', error)
    return 0 if result['result'] == 'PASS' else 1


if __name__ == '__main__':
    sys.exit(main())
