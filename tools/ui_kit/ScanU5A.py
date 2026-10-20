"""U5-only asset reference, capture and geometry checks; whole regression is excluded."""
import importlib.util
import json
import re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tmp/v1213_u5a'
spec = importlib.util.spec_from_file_location('ux_scan', ROOT / 'tools/ux_audit/scan.py')
scan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scan)


def main():
    failures = []
    old = re.compile(r'assets/sprites/portraits/(?:uiux3d/bati_(?:dry|dry_happy|stern|tutorial)|onboarding/(?:CHR_BATI_portrait_(?:dry|dry_happy|stern|tutorial)|portrait_bati))\.png')
    stale = []
    for directory in ('scripts', 'data', 'scenes'):
        for path in (ROOT / directory).rglob('*'):
            if path.suffix in ('.gd', '.tscn', '.tres', '.json', '.cfg'):
                for line, text in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
                    if old.search(text): stale.append(f'{path.relative_to(ROOT)}:{line}')
    if stale: failures.append({'old_bati_runtime_references': stale})
    data = json.loads((OUT / 'capture_result.json').read_text(encoding='utf-8'))
    expected = {f'{language}_{width}x{height}_{view}' for language in ('ko','en','zh_CN')
                for width, height in ((1920,1080),(2560,1080),(1280,720))
                for view in ('title','dialogue','dialogue_reply','legacy','combat_overlay')}
    actual = {item['id'] for item in data['captures']}
    if expected != actual: failures.append({'missing_captures': sorted(expected-actual)})
    reports = []
    for item in data['captures']:
        image = Image.open(OUT / (item['id'] + '.png'))
        dimensions = re.search(r'_(\d+)x(\d+)_', item['id']).groups()
        if image.size != tuple(map(int,dimensions)): failures.append({'size':item['id'],'actual':image.size})
        report = scan.scan(item)
        reports.append(report)
        if any(report[key] for key in ('zero_lines','overlaps','region_overflow','styled_masks')): failures.append(report)
        for control in item['controls']:
            if control['button'] and not control['tooltip'].strip(): failures.append({'empty_tooltip':control['path']})
            if control['name'] in ('StoryDialogueText','DialogueText') and control['font_px'] < 32: failures.append({'small_dialogue':item['id']})
            if control['name'] in ('StorySpeakerLabel','DialogueSpeakerLabel') and control['font_px'] < 26: failures.append({'small_speaker':item['id']})
            if control['name'] in ('CampaignNewGameButton','CampaignContinueButton','TitleSettingsButton','EndingArchiveButton','TitleQuitButton') and control['font_px'] < 30:
                failures.append({'small_title_menu':item['id'],'control':control['name']})
        by_name = {c['name']: c for c in item['controls']}
        for standing in ('DialogueStandingLeft', 'DialogueStandingRight'):
            if standing not in by_name: continue
            for toolbar in ('DialogueBacklogButton','StoryAutoButton','LegacyStoryAutoButton','StorySkipButton','LegacyStorySkipButton','DialogueMenuButton'):
                if toolbar not in by_name: continue
                width, height = scan.intersection(by_name[standing]['rect'], by_name[toolbar]['rect'])
                if width > 1 and height > 1: failures.append({'standing_toolbar_overlap':item['id'],'standing':standing,'toolbar':toolbar})
    for name, reference in (('title','docs/design/v1213_uiux/u3/01_title.png'), ('dialogue','docs/design/v1213_uiux/u3/02_dialogue.png')):
        left = Image.open(ROOT / reference).convert('RGB')
        assert left.size == (1920,1080), 'Reference must be full frame'
        right = Image.open(OUT / f'ko_1920x1080_{name}.png').convert('RGB')
        assert right.size == (1920,1080), 'Do not shrink/crop actual framebuffer'
        comparison = Image.new('RGB',(3840,1080))
        comparison.paste(left,(0,0)); comparison.paste(right,(1920,0))
        comparison.save(OUT / f'compare_{name}.png',optimize=True)
        view = OUT / 'view'
        view.mkdir(exist_ok=True)
        comparison.thumbnail((1280,1280), Image.Resampling.LANCZOS)
        comparison.save(view / f'compare_{name}.jpg',quality=85)
    for item in data['captures']:
        preview = Image.open(OUT / (item['id'] + '.png')).convert('RGB')
        preview.thumbnail((1280,1280), Image.Resampling.LANCZOS)
        preview.save(view / (item['id'] + '.jpg'),quality=85)
    characters = json.loads((ROOT / 'data/characters.json').read_text(encoding='utf-8'))
    fallback = []
    for character_id, info in characters.items():
        portrait = info.get('portrait', {})
        path = portrait.get('base', next(iter(info.get('portraits', {}).values()), ''))
        if path and character_id != 'CHR_BATI':
            fallback.append({'character_id':character_id,'name':info.get('display_name',character_id), 'asset':path,
                             'note':'No separate standing field in character data; existing portrait is used. Some monster portraits already show their whole body.'})
    (OUT / 'portrait_fallbacks.json').write_text(json.dumps(fallback,ensure_ascii=False,indent=2),encoding='utf-8')
    result = {'captures':len(actual),'old_bati_runtime_references':stale,'failures':failures,'reports':reports,'portrait_fallbacks':fallback,
              'settled_fps':[{'id':x['id'],**x['settled_fps_sample']} for x in data['captures'] if x['settled_fps_sample']]}
    (OUT / 'scan_result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(f'U5-A capture/reference scan: captures={len(actual)}, old Bati refs={len(stale)}, failures={len(failures)}')
    for failure in failures[:5]: print(json.dumps(failure,ensure_ascii=False)[:1800])
    return bool(failures)


if __name__ == '__main__':
    raise SystemExit(main())
