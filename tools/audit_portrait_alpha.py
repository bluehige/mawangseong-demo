"""Audit every data-declared portrait, including AtlasTexture regions.

Read pixels only; never change image alpha or player saves.
"""
from pathlib import Path
import argparse
import json
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def portrait_paths(value, context=False):
    if isinstance(value, dict):
        for key, item in value.items():
            yield from portrait_paths(item, context or 'portrait' in key.lower())
    elif isinstance(value, list):
        for item in value:
            yield from portrait_paths(item, context)
    elif context and isinstance(value, str) and value.startswith('res://') and value.endswith(('.png', '.tres')):
        yield value


def pixels(path):
    source = ROOT / path.removeprefix('res://')
    if source.suffix == '.png':
        return Image.open(source).convert('RGBA'), str(source.relative_to(ROOT))
    text = source.read_text(encoding='utf-8-sig')
    match = re.search(r'path="(res://[^"]+)"', text)
    image, backing = pixels(match[1])
    region = re.search(r'region = Rect2\(([^)]+)\)', text)
    if region:
        x, y, w, h = map(float, region[1].split(','))
        image = image.crop((round(x), round(y), round(x+w), round(y+h)))
    return image, backing


def inspect(image):
    alpha = image.getchannel('A')
    w, h = image.size
    band = max(1, min(w, h)//100)
    # Count each pixel once, including bottom-edge clothing contact.
    edge = [alpha.getpixel((x, y)) for y in range(h) for x in range(w)
            if x < band or x >= w-band or y < band or y >= h-band]
    corners = [alpha.getpixel((x, y))
               for y0 in (0, h-band) for x0 in (0, w-band)
               for y in range(y0, y0+band) for x in range(x0, x0+band)]
    edge_ratio = sum(a > 248 for a in edge)/len(edge)
    corner_ratio = sum(a > 248 for a in corners)/len(corners)
    # A cut bust can meet the bottom edge. Rectangular backdrops fill the
    # perimeter and/or corners; isolated character contact is reported separately.
    return {'alpha_min': alpha.getextrema()[0], 'alpha_max': alpha.getextrema()[1],
            'edge_opaque_ratio': round(edge_ratio, 6),
            'corner_opaque_ratio': round(corner_ratio, 6),
            'background': alpha.getextrema()[0] != 0 or edge_ratio > .50 or corner_ratio > .50}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', default='tmp/portrait_alpha_20261020/audit.json')
    args = parser.parse_args()
    refs = {}
    for data in (ROOT/'data').rglob('*.json'):
        if 'localization' in data.name:
            continue
        for path in portrait_paths(json.loads(data.read_text(encoding='utf-8-sig'))):
            refs.setdefault(path, []).append(str(data.relative_to(ROOT)))
    rows = []
    for path in sorted(refs):
        image, backing = pixels(path)
        rows.append({'path': path, 'backing': backing, 'width': image.width,
                     'height': image.height, **inspect(image), 'references': refs[path]})
    result = {'scope': 'all data-declared portrait paths; each AtlasTexture region audited',
              'count': len(rows), 'background_count': sum(r['background'] for r in rows), 'rows': rows}
    target = ROOT/args.out
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'portraits': result['count'], 'backgrounds': result['background_count'],
                      'first_backgrounds': [r['path'] for r in rows if r['background']][:5]}, ensure_ascii=False))
    return int(result['background_count'] > 0)


if __name__ == '__main__':
    raise SystemExit(main())
