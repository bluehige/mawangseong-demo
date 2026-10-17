"""Positive examples from the design, intentionally independent of runtime_rules.json."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
catalog = json.loads((root / 'data/v130r/achievements/achievements.json').read_text(encoding='utf8'))
cases = []
stats = dict(STAT_TRAPS_PLACED=50, STAT_TRAP_KILLS=100, STAT_ROSTER=24,
             STAT_MEMORIES=74, STAT_DUOS=16, STAT_SPECS=24, STAT_FROG_SNAG=30,
             STAT_SNAIL_SLOW=200, STAT_TROLL_TOLL=500, STAT_SHADOW_FEAR=50,
             STAT_WISP_REVEAL=20, STAT_MOLE_SABOTAGE=30, STAT_MAP_LOST=100,
             STAT_RAT_GOLD=1000, STAT_GOB_THIEF=30, STAT_PYNN_FIRE=300,
             STAT_ROLO_RAID=10, STAT_BUILDING_MOVES=20, STAT_BARK_SPECIES=24,
             STAT_BATI_LINES=100)
examples = {
 'ACH_THIEF_DENIED': ('battle_finished', dict(win=True, thief_day=True, vault_loss=0)),
 'ACH_SELEN': ('boss_defeated', dict(boss='selen_trainee_paladin')),
 'ACH_ROMAN': ('boss_defeated', dict(boss='roman')),
 'ACH_LEON': ('campaign_complete', dict(completed=True)),
 'ACH_DAY29': ('snapshot', dict(day_reached=30)),
 'ACH_BUILD_FIRST': ('construction', dict(buildings_built=1)),
 'ACH_BUILD_ALL5': ('construction', dict(built_types=5)),
 'ACH_BUILD_MAX': ('construction', dict(building_level_max=True)),
 'ACH_NO_THRONE_DMG': ('battle_finished', dict(win=True, throne_damage=0, day=10)),
 'ACH_SPLIT_DEFENSE': ('battle_finished', dict(win=True, grade='C', both_final_lines_held=True)),
 'ACH_ALL_FACILITIES_ALIVE': ('battle_finished', dict(win=True, facility_disabled=0, castle_stage=3)),
 'ACH_FIRST_MEMORY': ('collection', dict(memories=1)),
 'ACH_FIRST_DUO': ('collection', dict(duos=1)),
 'ACH_FIRST_SPEC': ('collection', dict(specs=1)),
 'ACH_NO_HUNGER': ('campaign_complete', dict(completed=True, hunger_days=0, complete_history=True)),
 'ACH_FULL_HOUSE': ('battle_finished', dict(win=True, slots_full=True, food_shortage=0)),
 'ACH_M_ARMOR': ('battle_finished', dict(leon_battle=True, armor_reassembled_alive=True)),
 'ACH_M_DOLL': ('monster_moment', dict(doll_saved_ally_in_boss=True)),
 'ACH_M_PUDDING': ('monster_moment', dict(pudding_blocked=1000)),
 'ACH_SECRET_BUCKET': ('dialogue_completed', dict(leak_complete=True)),
 'ACH_SECRET_DIRECT_LEON': ('boss_defeated', dict(boss='official_hero_leon', direct_control=True)),
 'ACH_SECRET_ALL_IN_ONE': ('battle_finished', dict(win=False, all_units_one_building=True)),
 'ACH_SECRET_HUNGRY_WIN': ('battle_finished', dict(win=True, hungry_units=5)),
 'ACH_SECRET_37': ('dialogue_completed', dict(join_species='river_frog')),
 'ACH_NIA': ('battle_finished', dict(win=True, day=6, vault_loss=0)),
 'ACH_ENGINEERS': ('battle_finished', dict(win=True, day=20, facility_disabled=0)),
 'ACH_PERFECT_CAMPAIGN': ('campaign_complete', dict(completed=True, defeats=0, complete_history=True)),
 'ACH_GATE_BRIDGE': ('battle_finished', dict(win=True, grade='C')),
 'ACH_VAULT_1000': ('settlement', dict(gold=1000)),
 'ACH_LEVEL_10': ('collection', dict(monster_level=10)),
 'ACH_FIRST_JOIN_SCENE': ('dialogue_completed', dict(join_scene_seen=1)),
 'ACH_SPEED_X3_WIN': ('battle_finished', dict(win=True, speed_always_x3=True)),
 'ACH_SECRET_ZERO_FOOD': ('battle_finished', dict(win=True, previous_settlement_zero_food=True)),
 'ACH_100': ('meta', dict(achievements=99)),
}
for row in catalog['achievements']:
    api, trigger, stat = row['api_name'], row['trigger'], row['progress_stat']
    if api in examples:
        event, fields = examples[api]
    elif stat:
        event, fields = 'progress', {stat: 10 if api == 'ACH_FAMILY_10' else stats[stat]}
    elif trigger.startswith('ending=='):
        event, fields = 'ending', {'ending': trigger.split('==')[1]}
    elif trigger.startswith('crown_evolved('):
        event, fields = 'crown_evolved', {'crown': trigger.removeprefix('crown_evolved(').removesuffix(')')}
    elif trigger.startswith('front_cleared('):
        event, fields = 'front_cleared', {'front': trigger.removeprefix('front_cleared(').removesuffix(')')}
    elif trigger.startswith('castle_stage>='):
        event, fields = 'snapshot', {'castle_stage': int(trigger.split('>=')[1])}
    elif api.startswith('ACH_SEAL_'):
        suffix = api.removeprefix('ACH_SEAL_')
        seal = {'NO_THRONE':'no_throne_damage', 'NO_DOWN':'no_monster_down', 'NO_DISABLE':'no_facility_disable', 'LOW_MANA':'low_mana', 'CONTRACT_VANGUARD':'contract_vanguard', 'ADAPTIVE':'adaptive_rival'}[suffix]
        event, fields = 'seal_cleared', {'seal': seal}
    elif trigger.startswith('day_victory=='):
        event, fields = 'battle_finished', dict(win=True, day=int(trigger.split('==')[1]))
    else:
        raise ValueError(api)
    cases.append(dict(id=api, event=event, facts=fields, source_trigger=trigger))
assert len(cases) == 100
(root / 'tools/tests/v130r_achievement_cases.json').write_text(json.dumps(cases, indent=2)+'\n', encoding='utf8')
print('100 independent design examples written')
