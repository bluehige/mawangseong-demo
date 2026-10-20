"""Measured reference geometry and whole-frame, equal-scale comparisons."""
from pathlib import Path
import json
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]

def main():
    out = Path(sys.argv[1]).resolve()
    metrics = json.loads((out/'render_metrics.json').read_text(encoding='utf-8'))
    failures = []
    for key, value in metrics['geometry'].items():
        error = [abs(a/b-1) for a,b in zip(value['actual'],value['target'])]
        value['size_error_percent'] = [round(e*100,2) for e in error]
        if max(error)>0.10001: failures.append(key)
    for reference, capture, result in (
        ('docs/design/v1213_uiux/kit/kit_B_cute_dark.png','kit_render.png','compare_kit.png'),
        ('docs/design/v1213_uiux/u3/03_management_build.png','management_render.png','compare_management_strip.png'),
    ):
        left = Image.open(ROOT/reference).convert('RGB').resize((1920,1080),Image.Resampling.LANCZOS)
        right = Image.open(out/capture).convert('RGB')
        assert right.size == (1920,1080), 'Rendered frame must remain 1:1.'
        comparison = Image.new('RGB',(3840,1080))
        comparison.paste(left,(0,0)); comparison.paste(right,(1920,0))
        comparison.save(out/result)
    (out/'geometry_check.json').write_text(json.dumps({'checks':len(metrics['geometry']),'failures':failures,'geometry':metrics['geometry']},ensure_ascii=False,indent=2),encoding='utf-8')
    print(f"FIDELITY geometry {len(metrics['geometry'])} / failures={len(failures)}; whole framebuffer comparisons: 3840x1080")
    return 1 if failures else 0

if __name__ == '__main__': raise SystemExit(main())
