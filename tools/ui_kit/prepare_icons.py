"""Optimize existing native-alpha GPT icons, without background removal."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/source/imagegen/v1213_ui_icons'
DEST = ROOT / 'assets/ui/kit/icons'

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    results = []
    for source in sorted(SOURCE.glob('icon_*.png')):
        original = Image.open(source).convert('RGBA')
        for pixels in (64, 128):
            target = DEST / f'{source.stem}_{pixels}.png'
            image = original.resize((pixels, pixels), Image.Resampling.LANCZOS)
            image.save(target, optimize=True)
            alpha = image.getchannel('A')
            assert alpha.getextrema()[0] == 0
            assert all(alpha.getpixel(p) == 0 for p in ((0,0),(pixels-1,0),(0,pixels-1),(pixels-1,pixels-1)))
            results.append({'path':str(target.relative_to(ROOT)), 'size':pixels, 'bytes':target.stat().st_size, 'alpha_range':alpha.getextrema()})
    assert len(results) == 64
    print(json.dumps({'icons':32,'outputs':len(results),'bytes':sum(x['bytes'] for x in results)}))
    out = ROOT / 'tmp/v1213_u4/fidelity'
    out.mkdir(parents=True, exist_ok=True)
    (out / 'icon_checks.json').write_text(json.dumps(results, indent=2), encoding='utf-8')

if __name__ == '__main__': main()
