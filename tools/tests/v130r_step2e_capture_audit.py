"""Export genuine viewport captures and independently audit the grouped geometry."""
from pathlib import Path
import hashlib
import json
import math
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step2e'
OUT = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step2e')
NAMES = ['radial_barracks', 'radial_watchtower_edge', 'radial_vault', 'info_upgrade']


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'previews').mkdir(exist_ok=True)
    checks = []

    def check(ok, label):
        checks.append({'ok': bool(ok), 'label': label})

    def overlaps(a, b):
        x, y, w, h = a
        u, v, s, t = b
        return x < u+s and u < x+w and y < v+t and v < y+h

    metrics = json.loads((LOCAL / 'capture_metrics.json').read_text(encoding='utf-8'))
    for name in NAMES:
        source = LOCAL / (name + '.png')
        with Image.open(source) as image:
            check(image.size == (1920, 1080), 'genuine viewport size ' + name)
            preview = image.copy()
            preview.thumbnail((1000, 650))
            preview.save(OUT / 'previews' / source.name)
        shutil.copy2(source, OUT / source.name)
        data = metrics[name]
        cx, cy = data['center']
        check(data['exterior'] <= data['radius'] <= data['exterior']+48.01, 'compact exterior radius '+name)
        angles = []
        for index, rect in enumerate(data['rects']):
            x, y, w, h = rect
            dx, dy = x+40-cx, y+40-cy
            check(abs(math.hypot(dx, dy)-data['radius']) < .05, 'fixed radius ' + name)
            check(x >= 0 and y >= 0 and x+w <= 1920 and y+h <= 1080, 'inside ' + name)
            angles.append(math.atan2(dy, dx))
            for ui in data['ui'].values():
                check(not overlaps(rect, ui), 'no UI overlap ' + name)
            for other in data['rects'][:index]:
                check(not overlaps(rect, other), 'no label overlap ' + name)
        for previous, angle in zip(angles, angles[1:]):
            check(abs((angle-previous) % math.tau-data['step']) < .001, 'equal angles ' + name)
        if 'panel' in data:
            x, y, w, h = data['panel']
            nearest = (min(max(cx, x), x+w), min(max(cy, y), y+h))
            check(math.dist((cx, cy), nearest) <= data['radius']+80, 'adjacent info ' + name)
            for rect in [*data['rects'], *data['ui'].values()]:
                check(not overlaps(data['panel'], rect), 'info avoids menu/UI ' + name)
    baseline = json.loads((LOCAL / 'existing_files.json').read_text(encoding='utf-8'))
    changed = [name for name, digest in baseline.items()
               if not (ROOT/name).is_file()
               or hashlib.sha256((ROOT/name).read_bytes()).hexdigest() != digest]
    check(not changed, 'existing mixed work preserved')
    for mode in ['direct', 'capture']:
        result = json.loads((LOCAL / (mode+'_result.json')).read_text(encoding='utf-8'))
        check(result['result'] == 'TARGETED_PASS' and not result['failures'], mode+' pass')
        check(not (LOCAL / (mode+'.err.log')).read_text(encoding='utf-8').strip(), mode+' stderr empty')
        for suffix in ['.log', '.err.log', '_result.json', '_metrics.json']:
            shutil.copy2(LOCAL / (mode+suffix), OUT / (mode+suffix))
    report = {'result': 'TARGETED_PASS' if all(c['ok'] for c in checks) else 'FAIL',
              'checks': len(checks), 'failures': [c for c in checks if not c['ok']],
              'preserved_files': len(baseline), 'changed_existing': changed}
    (OUT / 'capture_audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    (OUT / 'README.txt').write_text(
        '실제 1920×1080 화면 캡처\n'
        'previews/는 1000px 이하 축소본입니다. 한 번에 한 장씩 확인합니다.\n'
        '원형 메뉴는 건물 중심 고정 반지름·동일 각도 간격입니다.\n'
        '맵 그림 겹침 허용, UI·화면 밖 침범 금지. 사용자 확인 대기.\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))
    if report['failures']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
