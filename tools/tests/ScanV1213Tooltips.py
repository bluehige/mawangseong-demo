"""Inventory tooltip construction risks and summarize the actual UI tree audit.

Static empty shells/dictionary defaults are candidates, not proof of a runtime
empty tooltip. V1213StageTwoTest records every visible interactive control after
construction and lists real empty tooltip_text values for ko/en/zh_CN.
"""
import argparse
import json
import re
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--audit', nargs='+', default=[])
    parser.add_argument('--out', default='tmp/v1213_s2/tooltip_scan.json')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    sources = []
    for path in sorted((root / 'scripts').rglob('*.gd')):
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
            if re.search(r'(?<!Mouse)(?:Button|TextureButton|CheckButton|CheckBox|OptionButton)\.new\(', line) or re.search(r'preload\("[^"]*ReadableTooltip[^\"]*\.gd"\)\.new\(', line):
                sources.append(dict(path=path.relative_to(root).as_posix(), line=number, kind='direct_constructor', source=line.strip()))
            elif 'tooltip_text' in line and re.search(r'""', line):
                sources.append(dict(path=path.relative_to(root).as_posix(), line=number, kind='empty_or_dynamic_default', source=line.strip()))
            elif re.search(r'\bbutton\([^\n]*,\s*""\s*,', line):
                sources.append(dict(path=path.relative_to(root).as_posix(), line=number, kind='composite_button_shell', source=line.strip()))
    scene_buttons = []
    for path in sorted((root / 'scenes').rglob('*.tscn')):
        blocks = re.split(r'(?=\[node )', path.read_text(encoding='utf-8'))
        for block in blocks:
            header = block.splitlines()[0] if block else ''
            if re.search(r'type="(?:Button|TextureButton|CheckButton|CheckBox|OptionButton)"', header):
                scene_buttons.append(dict(path=path.relative_to(root).as_posix(), node=header, has_tooltip=bool(re.search(r'^tooltip_text = "[^"\n]+"', block, re.M))))
    audits = []
    for supplied in args.audit:
        path = root / supplied
        reports = json.loads(path.read_text(encoding='utf-8'))
        audits.append(dict(path=supplied, screens=len(reports), controls=sum(len(row.get('controls', [])) for row in reports), empty=[dict(screen=row['screen'], locale=row['locale'], control=control) for row in reports for control in row['empty_tooltips']]))
    result = dict(static_candidates=sources, scene_buttons=scene_buttons, runtime_audits=audits, scope='Static inventory of scripts/scenes; runtime matrix of changed screens only. Decorative MOUSE_FILTER_IGNORE images are excluded. Scrollbars are Range controls and must have a tooltip.')
    output = root / args.out
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(dict(static_candidates=len(sources), scene_buttons=len(scene_buttons), runtime_screens=sum(x['screens'] for x in audits), controls=sum(x['controls'] for x in audits), empty=sum(len(x['empty']) for x in audits)), ensure_ascii=False))
    return 1 if any(x['empty'] for x in audits) else 0


if __name__ == '__main__':
    raise SystemExit(main())
