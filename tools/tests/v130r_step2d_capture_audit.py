"""Copy actual captures to the Korean output path and compare reference framing."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step2d'
MOCKUP = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup')
OUT = MOCKUP / 'game_step2d'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'previews').mkdir(exist_ok=True)
    checks = []

    def check(ok, label):
        checks.append({'ok': bool(ok), 'label': label})

    for name, size in [('start_1920', (1920, 1080)), ('start_1280', (1280, 720)),
                       ('font_info', (1920, 1080)), ('font_bar', (1920, 1080))]:
        source = LOCAL / (name + '.png')
        with Image.open(source) as image:
            check(image.size == size, 'actual viewport size ' + name)
            preview = image.copy()
            preview.thumbnail((1000, 650))
            preview.save(OUT / 'previews' / source.name)
        shutil.copy2(source, OUT / source.name)

    reference = Image.open(MOCKUP / 'game_step2b/radial_edge.png').convert('RGB')
    start = Image.open(OUT / 'start_1920.png').convert('RGB')
    check(reference.size == start.size == (1920, 1080), 'reference and start same actual resolution')
    comparison = Image.new('RGB', (3840, 1120), '#16171c')
    comparison.paste(reference, (0, 40))
    comparison.paste(start, (1920, 40))
    draw = ImageDraw.Draw(comparison)
    draw.text((20, 12), 'STEP 2B radial_edge | center (1930,1390), zoom 0.75', fill='white')
    draw.text((1940, 12), 'STEP 2D start | center (1930,1390), zoom 0.75', fill='white')
    comparison.save(OUT / 'compare_start.png')
    comparison.thumbnail((1600, 650))
    comparison.save(OUT / 'previews/compare_start.png')

    # A fixed unobscured map patch must be pixel-identical: this checks the
    # actual reference image rather than just repeating camera constants.
    patch = (720, 300, 1300, 650)
    a, b = reference.crop(patch), start.crop(patch)
    equal = sum(x == y for x, y in zip(a.getdata(), b.getdata())) / (a.width*a.height)
    check(equal > .99, 'reference map patch same pixels >99%')
    baseline = json.loads((LOCAL / 'existing_files.json').read_text(encoding='utf-8'))
    changed = [n for n, digest in baseline.items() if not (ROOT/n).is_file()
               or hashlib.sha256((ROOT/n).read_bytes()).hexdigest() != digest]
    check(not changed, 'existing mixed files preserved')
    for mode in ['direct', 'capture']:
        result = json.loads((LOCAL / (mode+'_result.json')).read_text(encoding='utf-8'))
        check(result['result'] == 'TARGETED_PASS' and not result['failures'], mode+' pass')
        check(not (LOCAL / (mode+'.err.log')).read_text(encoding='utf-8').strip(), mode+' stderr empty')
        for suffix in ['.log', '.err.log', '_result.json', '_metrics.json']:
            shutil.copy2(LOCAL / (mode+suffix), OUT / (mode+suffix))
    report = {'result': 'TARGETED_PASS' if all(c['ok'] for c in checks) else 'FAIL',
              'checks': len(checks), 'failures': [c for c in checks if not c['ok']],
              'reference_patch_identical_fraction': equal,
              'preserved_files': len(baseline), 'changed_existing': changed}
    (OUT / 'capture_audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))
    if report['failures']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
