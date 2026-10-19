"""Read native CU evidence; never edits a save or controls an application."""
import json
from PIL import Image
from run_audit import ROOT, OUT, STATE, engines, write

def read(name): return json.loads((OUT/name).read_text(encoding='utf-8-sig'))
def text(name):
    data=read('captures/'+name+'_ocr.json')
    if isinstance(data,dict): data=[data]
    return '\n'.join(x['text'] for x in data) if isinstance(data,list) else str(data)

before=read('native_after_exit_v6.json')
after=read('native_after_continue_v6.json')
restore=read('native_restore_comparison.json')
views=read('direct_image_review.json')
dimensions=[dict(path=p,size=list(Image.open(p).size)) for p in views]
new=read('runs/exe_new_game.json'); restarted=read('runs/exe_restart_1.json')
checks={
    'day1_combat_visible':'DAY 1' in text('cu_42_battle_intro_960') and 'Wave' in text('cu_42_battle_intro_960'),
    'day1_victory_visible':'Victory!' in text('cu_44_combat_progress_960'),
    'space_advances_victory_dialogue':'Strictly speaking' in text('cu_45_victory_space_960'),
    'escape_opens_game_menu':'Game menu' in text('cu_46_victory_escape_960'),
    'six_native_save_versions_written':len(read('native_saves_before_exit.json'))==6,
    'restart_continue_same_victory_cue':'Strictly speaking' in text('cu_53_continue_960'),
    'native_restore_preserves_state':all(restore.values()),
    'native_completed_battle_saved':bool(before['active_run']['legacy_payload']['result']['summary'].get('win')),
    'both_native_exits_zero':new['exit_code']==restarted['exit_code']==0,
    'both_native_logs_clean':not any(r['error_lines'] or r['warning_lines'] for r in [new,restarted]),
    'direct_image_limit':len(views)<=12 and all(max(d['size'])<=960 for d in dimensions),
    'task_engines_zero':not engines(),
}
write(OUT/'computer_use.json',dict(passed=all(checks.values()),checks=checks,method='@oai/sky actual Windows click/key; screenshot copies and OCR; normal Main; no injected test code',direct_images_total=len(views),direct_image_dimensions=dimensions,capture_index='cu_capture_index.json',player_name=before['summary']['player_name'],native_checkpoint=before['summary']['checkpoint'],native_day=before['summary']['day'],before_state={k:before['active_run']['legacy_payload']['game_state'][k] for k in ['day','demon_lord_hp','gold','mana','food','player_name']},state_comparison=restore,saved_at_after_explicit_save_and_quit=before['summary']['saved_at_text'],resaved_after_continue_at=after['summary']['saved_at_text'],notes=['Enter while the default-name button had focus requested another name; the visible Use this name button confirmed Cavebaron.','Unread first-play Skip was locked; normal Space advanced the authored dialogue.','After the first normal quit the subsequent CU screenshot had no target; native process exit 0 confirmed completion.','Continued checkpoint was inspected by OCR, not opened as a thirteenth image.']))
print(json.dumps(dict(passed=all(checks.values()),checks=checks,direct_images=len(views)),ensure_ascii=False))
