"""Auditable translation of the approved v130 triggers, not a runtime expression parser."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'data/v130r/achievements'
catalog = json.loads((DATA / 'achievements.json').read_text(encoding='utf-8'))
rules = {}


def rule(api, event, **fields):
    terms = []
    for key, value in fields.items():
        op, target = value if isinstance(value, tuple) else ('eq', value)
        terms.append([key, op, target])
    rules[api] = {'event': event, 'terms': terms}


for api, day in [('FIRST_NIGHT', 1), ('HERO_TRAINEE', 3), ('MILO', 5)]:
    rule('ACH_' + api, 'battle_finished', win=True, day=day)
rule('ACH_THIEF_DENIED', 'battle_finished', win=True, thief_day=True, vault_loss=0)
for api, stage in [('GRADE_E', 2), ('GRADE_D', 3), ('GRADE_C', 4), ('STONE_BRIDGE', 3)]:
    rule('ACH_' + api, 'snapshot', castle_stage=('gte', stage))
rule('ACH_SELEN', 'boss_defeated', boss=('prefix', 'selen_'))
rule('ACH_ROMAN', 'boss_defeated', boss='roman')
rule('ACH_LEON', 'campaign_complete', completed=True)
rule('ACH_DAY29', 'snapshot', day_reached=30)
rule('ACH_BUILD_FIRST', 'construction', buildings_built=('gte', 1))
rule('ACH_BUILD_ALL5', 'construction', built_types=('gte', 5))
rule('ACH_BUILD_MAX', 'construction', building_level_max=True)
rule('ACH_NO_THRONE_DMG', 'battle_finished', win=True, throne_damage=0, day=('gte', 10))
rule('ACH_SPLIT_DEFENSE', 'battle_finished', win=True, grade='C', both_final_lines_held=True)
rule('ACH_ALL_FACILITIES_ALIVE', 'battle_finished', win=True, facility_disabled=0, castle_stage=('gte', 3))
rule('ACH_FIRST_MEMORY', 'collection', memories=('gte', 1))
rule('ACH_FIRST_DUO', 'collection', duos=('gte', 1))
rule('ACH_FIRST_SPEC', 'collection', specs=('gte', 1))
rule('ACH_NO_HUNGER', 'campaign_complete', completed=True, complete_history=True, hunger_days=0)
rule('ACH_FULL_HOUSE', 'battle_finished', win=True, slots_full=True, food_shortage=0)
rule('ACH_M_ARMOR', 'battle_finished', leon_battle=True, armor_reassembled_alive=True)
rule('ACH_M_DOLL', 'monster_moment', doll_saved_ally_in_boss=True)
rule('ACH_M_PUDDING', 'monster_moment', pudding_blocked=('gte', 1000))
for suffix, seal in [('NO_THRONE','no_throne_damage'),('NO_DOWN','no_monster_down'),('LOW_MANA','low_mana'),('NO_DISABLE','no_facility_disable'),('CONTRACT_VANGUARD','contract_vanguard'),('ADAPTIVE','adaptive_rival')]:
    rule('ACH_SEAL_' + suffix, 'seal_cleared', seal=seal)
rule('ACH_SECRET_BUCKET', 'dialogue_completed', leak_complete=True)
rule('ACH_SECRET_DIRECT_LEON', 'boss_defeated', boss='official_hero_leon', direct_control=True)
rule('ACH_SECRET_ALL_IN_ONE', 'battle_finished', win=False, all_units_one_building=True)
rule('ACH_SECRET_HUNGRY_WIN', 'battle_finished', win=True, hungry_units=('gte', 5))
rule('ACH_SECRET_37', 'dialogue_completed', join_species='river_frog')
rule('ACH_NIA', 'battle_finished', win=True, day=6, vault_loss=0)
rule('ACH_ENGINEERS', 'battle_finished', win=True, day=20, facility_disabled=0)
rule('ACH_PERFECT_CAMPAIGN', 'campaign_complete', completed=True, complete_history=True, defeats=0)
rule('ACH_GATE_BRIDGE', 'battle_finished', win=True, grade='C')
rule('ACH_VAULT_1000', 'settlement', gold=('gte', 1000))
rule('ACH_LEVEL_10', 'collection', monster_level=('gte', 10))
rule('ACH_FIRST_JOIN_SCENE', 'dialogue_completed', join_scene_seen=('gte', 1))
rule('ACH_SPEED_X3_WIN', 'battle_finished', win=True, speed_always_x3=True)
rule('ACH_SECRET_ZERO_FOOD', 'battle_finished', win=True, previous_settlement_zero_food=True)
rule('ACH_100', 'meta', achievements=('gte', 99))
for row in catalog['achievements']:
    api = row['api_name']
    if row['progress_stat']:
        rule(api, 'progress', **{row['progress_stat']: ('gte', row['progress_max'])})
    elif api.startswith(('ACH_END_', 'ACH_END3_', 'ACH_END4_')):
        rule(api, 'ending', ending=row['trigger'].split('==', 1)[1])
    elif api.startswith('ACH_FRONT_'):
        rule(api, 'front_cleared', front=row['trigger'][14:-1])
    elif api.startswith('ACH_CROWN_'):
        rule(api, 'crown_evolved', crown=row['trigger'][14:-1])

assert len(rules) == 100 and set(rules) == {x['api_name'] for x in catalog['achievements']}
assert all(x['terms'] for x in rules.values())
(DATA / 'runtime_rules.json').write_text(json.dumps(rules, indent=2) + '\n', encoding='utf-8')
print('100 explicit rule definitions written')
