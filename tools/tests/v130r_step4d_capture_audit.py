"""Measure real alpha/label gaps, verify occlusion and publish UTF-8 evidence."""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step4d'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step4d_labels')
FONT = ROOT / 'assets/fonts/NEXON_Maplestory_Light.otf'


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    manifest = json.loads((LOCAL / 'label_manifest.json').read_text(encoding='utf-8'))
    measurements = []
    failures = []
    for capture in manifest:
        for row in capture['units']:
            alpha = Image.open(LOCAL / row['mask']).convert('RGBA').getchannel('A')
            box = alpha.getbbox()
            assert box, row
            label = row['label']
            desired = row['desired_label']
            base_gap = box[1] - desired[1] - desired[3]
            shown_gap = box[1] - label[1] - label[3]
            reveal = Image.open(LOCAL / row['silhouette']).convert('RGBA').getchannel('A')
            clipped = box[0] == 0 or box[1] == 0 or box[2] == 1920 or box[3] == 1080
            ok = 4.5 <= base_gap <= 7.5 and not clipped
            result = {**row, 'capture': capture['capture'], 'alpha_bbox': list(box),
                      'base_gap_px': base_gap, 'shown_gap_px': shown_gap,
                      'silhouette_pixels': sum(reveal.histogram()[1:]), 'clipped': clipped,
                      'result': 'PASS' if ok else 'FAIL'}
            measurements.append(result)
            if not ok:
                failures.append(result)

    behind = next(r for r in measurements if r['capture'] == 'occlusion_check')
    front = next(r for r in measurements if r['capture'] == 'backwall_control')
    assert behind['silhouette_pixels'] > 50, behind
    assert front['silhouette_pixels'] == 0, front
    with_reveal = Image.open(LOCAL / 'occlusion_check.png').convert('RGB')
    without = Image.open(LOCAL / 'occlusion_without_reveal.png').convert('RGB')
    # Existing combat VFX elsewhere may continue between these two frames.
    # Compare the subject's body region; check every changed body pixel.
    region = tuple(behind['alpha_bbox'])
    difference = ImageChops.difference(with_reveal, without).crop(region)
    difference_pixels = sum(difference.convert('L').histogram()[1:])
    assert difference_pixels > 50, 'Silhouette must also be visible in the real scene'
    support = Image.open(LOCAL / behind['silhouette']).convert('RGBA').getchannel('A').point(lambda a: 255 if a else 0).filter(ImageFilter.MaxFilter(3)).crop(region)
    changed_pixels = difference.convert('L').point(lambda a: 255 if a else 0)
    outside = ImageChops.subtract(changed_pixels, support)
    assert outside.getbbox() is None, 'Reveal must change only the occluded part of this body'

    # Diagnostic only: draw true alpha contours and actual label boxes on the
    # untouched E scene, then place the original-pixel distance table alongside.
    scene = Image.open(LOCAL / 'battle_e_day7.png').convert('RGB')
    draw = ImageDraw.Draw(scene)
    e_rows = [r for r in measurements if r['capture'] == 'battle_e_day7']
    number_font = ImageFont.truetype(str(FONT), 22)
    for index, row in enumerate(e_rows, 1):
        alpha = Image.open(LOCAL / row['mask']).convert('RGBA').getchannel('A')
        binary = alpha.point(lambda a: 255 if a else 0)
        edge = ImageChops.subtract(binary, binary.filter(ImageFilter.MinFilter(3)))
        scene.paste((255, 105, 222), (0, 0), edge)
        x, y, w, h = row['label']
        draw.rectangle((x, y, x+w, y+h), outline=(95, 228, 255), width=2)
        draw.text((x, y-23), str(index), font=number_font, fill=(255, 255, 120), stroke_width=1, stroke_fill='black')
        ax, ay, _, _ = row['alpha_bbox']
        draw.text((ax, ay), str(index), font=number_font, fill=(255, 255, 120), stroke_width=1, stroke_fill='black')
    diagnostic = Image.new('RGB', (1920, 1080), '#141a23')
    d = ImageDraw.Draw(diagnostic)
    title = ImageFont.truetype(str(FONT), 30)
    body = ImageFont.truetype(str(FONT), 23)
    d.text((24, 24), '이름표·몸 알파 외곽 검수 / E DAY7 / 사용자 확인 대기', font=title, fill='white')
    diagnostic.paste(scene.resize((1320, 743), Image.Resampling.LANCZOS), (0, 100))
    d.text((22, 875), '분홍: 실제 몸 알파>0 외곽  |  하늘: 실제 이름/HP 박스  |  같은 번호: 같은 유닛', font=body, fill='#aeeeff')
    d.text((22, 920), '간격: 충돌 전 박스 아래~몸 맨 위. 이동: 충돌 회피 Y변위(− 위 / + 아래). 단위는 원본 화면 px.', font=body, fill='white')
    d.text((22, 964), '충돌 전 목표 6px(래스터 반올림 허용 ±1.5px). 비켜난 박스는 몸까지 연결선으로 표시.', font=body, fill='white')
    d.text((1350, 100), '이름       간격     이동Y    표시간격', font=body, fill='#aeeeff')
    for index, row in enumerate(e_rows, 1):
        line = f'{index:02} {row["name"]:<4}  {row["base_gap_px"]:5.1f}  {row["displacement_px"]:+6.1f}  {row["shown_gap_px"]:6.1f}'
        d.text((1350, 145+(index-1)*43), line, font=body, fill='white' if row['result']=='PASS' else '#ff7788')
    diagnostic.save(LOCAL / 'label_check.png')

    lines = ['# 이름표 거리·가림 실측 — 사용자 확인 대기', '',
             '실제 1920×1080 렌더. E/F는 기본 줌0.75·원본 웨이브 첫 접촉, 가림/뒷벽 대조는 실제 길 칸의 일시정지 배치·줌1.0.',
             '몸 전체의 알파>0 외곽은 같은 라이브 프레임·화면 변환의 독립 투명 렌더에서 측정했다. 본 화면에 합성한 몸이 아니다.',
             '기본 간격은 충돌 전 HP 아래~몸 맨 위, 목표6px/래스터 허용±1.5px. 표시 간격은 충돌 회피 후 값으로 음수면 몸 쪽 아래로 비켰다는 뜻이다.',
             '이름표 X는 자기 몸 외곽 중심을 유지한다. 간격/변위/가림은 원본 화면 픽셀 기준이며 축소본에서 재지 않았다.', '',
             '| 화면 | 이름 | 기본 간격px | 충돌 이동Ypx | 표시 간격px | 실루엣 픽셀 | 결과 |',
             '|---|---|---:|---:|---:|---:|---|']
    for row in measurements:
        lines.append(f'| {row["capture"]} | {row["name"]} | {row["base_gap_px"]:.2f} | {row["displacement_px"]:+.2f} | {row["shown_gap_px"]:.2f} | {row["silhouette_pixels"]} | {row["result"]} |')
    lines += ['', f'실루엣 켬/끔 실제 장면 차이 {difference_pixels}픽셀. 앞턱 뒤: {behind["silhouette_pixels"]}픽셀, 뒷벽 앞 길 대조: {front["silhouette_pixels"]}픽셀.',
              '새 그림/배경 제거/사용자 세이브 접근·수정 없음. 전체 회귀·전체 플레이·성능·export는 미요청/미실행.']
    (DEST / 'distance_table.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    (LOCAL / 'label_measurements.json').write_text(json.dumps(measurements, ensure_ascii=False, indent=2), encoding='utf-8')
    for name in ['battle_e_day7', 'battle_f_day3', 'label_check', 'occlusion_check']:
        source = LOCAL / (name+'.png')
        shutil.copy2(source, DEST / source.name)
        preview = Image.open(source); preview.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        preview.save(DEST / 'previews' / source.name)
    for path in ['label_manifest.json', 'label_measurements.json', 'direct_result.json', 'capture_result.json', 'backwall_control.png', 'occlusion_without_reveal.png']:
        shutil.copy2(LOCAL / path, DEST / path)
    for folder in ['alpha', 'silhouette']:
        # Copy only masks referenced by the final run, not abandoned captures.
        for capture in manifest:
            for row in capture['units']:
                relative = Path(row['mask' if folder=='alpha' else 'silhouette'])
                target = DEST / relative; target.parent.mkdir(exist_ok=True)
                shutil.copy2(LOCAL / relative, target)
    previous = json.loads((LOCAL / 'existing_hashes.json').read_text(encoding='utf-8'))
    changed = [p for p, sha in previous.items() if not (ROOT / p).is_file() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest()!=sha]
    assert not changed, changed
    results = {}
    for mode in ['direct', 'capture']:
        result = json.loads((LOCAL / f'{mode}_result.json').read_text(encoding='utf-8'))
        assert result['result']=='TARGETED_PASS', result
        assert (LOCAL / f'{mode}.err.log').stat().st_size==0, mode
        results[mode] = result['checks']
    audit = {'result': 'FAIL' if failures else 'TARGETED_PASS', 'measurements': len(measurements),
             'failures': failures, 'existing_files_preserved': len(previous), 'changed_existing': changed,
             'checks': results, 'scene_reveal_difference_pixels': difference_pixels,
             'behind_reveal_pixels': behind['silhouette_pixels'], 'front_reveal_pixels': front['silhouette_pixels']}
    (DEST / 'capture_audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(audit, ensure_ascii=True))
    assert not failures, 'Raster gap gate failed; see distance_table.md'


if __name__ == '__main__':
    main()
