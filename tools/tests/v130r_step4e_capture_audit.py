"""Audit actual GPU contours, depth clipping and fixed defense homes; publish evidence."""
from pathlib import Path
import hashlib
import json
import shutil

import numpy as np
from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step4e'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step4e_silhouette')


def main():
    manifest = json.loads((LOCAL / 'label_manifest.json').read_text(encoding='utf-8'))
    depth = np.asarray(Image.open(LOCAL / 'wall_depth.png').convert('RGBA'))
    measurements = []
    for capture in manifest:
        for row in capture['units']:
            body = Image.open(LOCAL / row['mask']).convert('RGBA').getchannel('A')
            rgba = np.asarray(Image.open(LOCAL / row['silhouette']).convert('RGBA'))
            alpha = rgba[:, :, 3]
            ys, xs = np.nonzero(alpha)
            # A contour is supported by the actual body, never a displaced copy.
            assert not np.any((alpha > 0) & (np.asarray(body) == 0)), row['id']
            # GPU's 2px inward samples may cover fractional raster edge pixels.
            interior = body.point(lambda a: 255 if a >= 26 else 0).filter(ImageFilter.MinFilter(7))
            assert not np.any((alpha > 0) & (np.asarray(interior) > 0)), ('filled interior', row)
            assert int(alpha.max()) <= 103, ('opacity exceeds 40%', row)
            if len(xs):
                a, b, c, d, tx, ty = capture['screen_to_map']
                wx = a * (xs + .5) + c * (ys + .5) + tx
                wy = b * (xs + .5) + d * (ys + .5) + ty
                ox, oy, width, height = capture['wall_bounds']
                u = (wx - ox) / width
                v = (wy - oy) / height
                assert np.all((u >= 0) & (u < 1) & (v >= 0) & (v < 1))
                ix = (u * depth.shape[1]).astype(int)
                iy = (v * depth.shape[0]).astype(int)
                pixel = depth[iy, ix].astype(float)
                wall = (pixel[:, 0] * 256 + pixel[:, 1]) / 65535 * 3500
                valid = (pixel[:, 3] >= 128) & (wall > row['depth'] + .5)
                # GPU/CPU inverse matrix rounding can choose adjacent wall texels
                # at an exact edge. Allow one depth texel, never a body offset.
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        near = depth[np.clip(iy+dy, 0, depth.shape[0]-1), np.clip(ix+dx, 0, depth.shape[1]-1)].astype(float)
                        foot = (near[:, 0]*256+near[:, 1])/65535*3500
                        valid |= (near[:, 3] >= 128) & (foot > row['depth']+.5)
                assert np.all(valid), ('outside occlusion', row)
                color = rgba[ys, xs, :3].mean(axis=0)
                if capture['capture'] == 'outline_enemy':
                    assert color[0] > color[2] * 1.6, color
                else:
                    assert color[2] > color[0] * 1.6 and color[2] > color[1], color
            measurements.append({'capture': capture['capture'], 'id': row['id'], 'pixels': len(xs),
                                 'max_alpha': int(alpha.max()), 'alignment': 'PASS', 'empty_interior': 'PASS',
                                 'depth_clip': 'PASS', 'screen_width': '2px (raster tolerance 1px)'})

    for name in ['occlusion_check', 'outline_zoom_0.5', 'outline_zoom_0.75', 'outline_zoom_1.0', 'outline_enemy']:
        assert sum(r['pixels'] for r in measurements if r['capture'] == name) > 30, name
    assert sum(r['pixels'] for r in measurements if r['capture'] == 'backwall_control') == 0
    subject = next(c for c in manifest if c['capture'] == 'occlusion_check')['units'][0]
    region = Image.open(LOCAL / subject['mask']).getchannel('A').getbbox()
    diff = ImageChops.difference(Image.open(LOCAL / 'occlusion_check.png').convert('RGB'),
                                Image.open(LOCAL / 'occlusion_without_reveal.png').convert('RGB')).convert('L')
    support = Image.open(LOCAL / subject['silhouette']).getchannel('A').point(lambda a: 255 if a else 0)
    changed = diff.point(lambda a: 255 if a else 0)
    assert changed.crop(region).getbbox(), 'Contour absent in actual scene'
    assert ImageChops.subtract(changed, support.filter(ImageFilter.MaxFilter(3))).crop(region).getbbox() is None

    original = json.loads((LOCAL / 'existing_hashes.json').read_text(encoding='utf-8'))
    assert all((ROOT / p).is_file() and hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == h for p, h in original.items())
    results = {}
    for mode in ['direct', 'capture']:
        result = json.loads((LOCAL / f'{mode}_result.json').read_text(encoding='utf-8'))
        assert result['result'] == 'TARGETED_PASS', result
        assert (LOCAL / f'{mode}.err.log').stat().st_size == 0, mode
        results[mode] = result['checks']
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    for name in ['battle_e_day7', 'occlusion_check', 'barracks_front']:
        im = Image.open(LOCAL / f'{name}.png')
        if name == 'barracks_front':
            rows = next(c for c in manifest if c['capture'] == name)['units']
            boxes = [Image.open(LOCAL / r['mask']).getchannel('A').getbbox() for r in rows]
            # An unscaled crop of the real viewport, including all four labels.
            im = im.crop((min(b[0] for b in boxes)-150, min(b[1] for b in boxes)-200,
                          max(b[2] for b in boxes)+150, max(b[3] for b in boxes)+90))
        im.save(DEST / f'{name}.png')
        preview = im.copy(); preview.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        preview.save(DEST / 'previews' / f'{name}.png')
    for name in ['label_manifest.json', 'direct_result.json', 'capture_result.json', 'wall_depth.png', 'backwall_control.png']:
        shutil.copy2(LOCAL / name, DEST / name)
    audit = {'result': 'TARGETED_PASS', 'checks': results, 'raster_subjects': len(measurements),
             'existing_files_preserved': len(original), 'measurements': measurements,
             'limits': 'Targeted E DAY7 first contact and paused road fixtures; no full playthrough or performance test.'}
    (DEST / 'capture_audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k, v in audit.items() if k != 'measurements'}, ensure_ascii=True))


if __name__ == '__main__':
    main()
