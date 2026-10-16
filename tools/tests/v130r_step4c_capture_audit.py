"""Step4C real raster alpha measurement and UTF-8 evidence publishing."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step4c'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step4c_scale')


def snapshot():
    LOCAL.mkdir(parents=True, exist_ok=True)
    paths = subprocess.check_output(['git', 'ls-files', '-m', '-o', '--exclude-standard', '-z'], cwd=ROOT).decode('utf-8').split('\0')
    data = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths if p and (ROOT / p).is_file() and p != 'tools/tests/v130r_step4c_capture_audit.py'}
    (LOCAL / 'existing_hashes.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Snapshotted {len(data)} existing files')


def publish():
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    if '--images-only' in sys.argv:
        for source in LOCAL.glob('*.png'):
            image = Image.open(source)
            image.thumbnail((1000, 600), Image.Resampling.LANCZOS)
            image.save(DEST / 'previews' / source.name)
        return
    manifest = json.loads((LOCAL / 'alpha_manifest.json').read_text(encoding='utf-8'))
    lines = ['# 실제 화면 몸 높이 — 사용자 확인 대기', '',
             '1920×1080, 시작 줌 0.75, 칸 96×48px. 일반 목표64–80px, 대형73.6–92px(×1.15), 보스86.4–108px(×1.35).',
             '값은 계산식 예측이 아니라 실제 Godot 투명 보조 렌더의 알파>0 외곽 높이(정수 px)다.',
             '각 원본 장면을 일시정지하고 같은 sprite/frame/화면 변환으로 한 개체씩 별도1920×1080 투명 viewport에 렌더했다.',
             '이 보조 패스는 배경·이펙트·UI·다른 유닛을 제외한다. 가려진 몸 전체의 높이이며 가림 후 남은 조각 높이가 아니다.',
             '보조 패스는 장면 캡처에 합성하지 않았다. crowd는 의도적으로 몰아 놓은 합성 시험이며 두 전투는 원래 DAY 웨이브의 첫 접촉이다.',
             '', '| 캡처 | 유닛 | ID | 분류 | 실제 높이 px | 허용 px | 알파 외곽 (x,y,w,h) | 결과 |',
             '|---|---|---|---|---:|---|---|---|']
    measurements = []
    failures = []
    for capture in manifest:
        name = capture['capture']
        image = Image.open(LOCAL / f'{name}.png')
        assert image.size == (1920, 1080)
        shutil.copy2(LOCAL / f'{name}.png', DEST / f'{name}.png')
        image.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        image.save(DEST / 'previews' / f'{name}.png')
        assert len(capture['units']) == 6
        assert len({r['id'] for r in capture['units']}) == 6
        for row in capture['units']:
            mask = Image.open(LOCAL / row['mask']).convert('RGBA')
            bbox = mask.getchannel('A').getbbox()
            assert bbox, row
            x, y, r, b = bbox
            height = b - y
            lo, hi = 64 * row['multiplier'], 80 * row['multiplier']
            inside = x > 0 and y > 0 and r < 1920 and b < 1080
            ok = lo <= height <= hi and inside
            result = {**row, 'capture': name, 'height_px': height, 'alpha_bbox': [x, y, r-x, height], 'range_px': [lo, hi], 'result': 'PASS' if ok else 'FAIL'}
            measurements.append(result)
            if not ok:
                failures.append(result)
            lines.append(f'| {name}.png | {row["name"]} | {row["id"]} | {row["class"]} | {height} | {lo:g}–{hi:g} | ({x},{y},{r-x},{height}) | {result["result"]} |')
    lines += ['', f'총 {len(measurements)}개 측정, 실패 {len(failures)}. 범위 밖 또는 화면 경계에서 잘린 몸은 FAIL.',
              '같은 알파 원본 기준높이96월드px(폭 제한 없음), 대형·보스 배율을 공통 정의에서 적용. 줌 변경 시 지도와 비례.',
              '애니메이션의 프레임·찌그러짐·회전은 유지하므로 정수 측정은 보통±수px 변화한다. 모든 순간·모든 보스 조합을 검사한 결과는 아니다.',
              '배치 화면에는 적/보스가 없으므로 배치6종은 몬스터다. 실제 웨이브에 없는 보스·대형 적은 crowd에서 검사했다.']
    (DEST / 'size_table.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    (LOCAL / 'size_measurements.json').write_text(json.dumps(measurements, ensure_ascii=False, indent=2), encoding='utf-8')
    shutil.copy2(LOCAL / 'size_measurements.json', DEST / 'size_measurements.json')
    shutil.copy2(LOCAL / 'alpha_manifest.json', DEST / 'alpha_manifest.json')
    shutil.copytree(LOCAL / 'alpha', DEST / 'alpha', dirs_exist_ok=True)
    print(json.dumps({'measurements': len(measurements), 'failures': failures}, ensure_ascii=True))
    assert not failures, 'Actual alpha height gate failed; see size_table.md'
    if '--preview' in sys.argv:
        return
    previous = json.loads((LOCAL / 'existing_hashes.json').read_text(encoding='utf-8'))
    changed = [p for p, h in previous.items() if not (ROOT / p).is_file() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != h]
    assert not changed, changed
    results = {}
    for mode in ['direct', 'capture', 'performance']:
        results[mode] = json.loads((LOCAL / f'{mode}_result.json').read_text(encoding='utf-8'))
        assert results[mode]['result'] == 'TARGETED_PASS', results[mode]
        assert (LOCAL / f'{mode}.err.log').stat().st_size == 0, mode
        shutil.copy2(LOCAL / f'{mode}_result.json', DEST / f'{mode}_result.json')
    baseline = json.loads((LOCAL / 'baseline_performance.json').read_text(encoding='utf-8'))['evidence']['performance']
    perf = results['performance']['evidence']['performance']
    lines = ['# 크기 재작업 성능 재측정 — 사용자 확인 대기', '',
             '같은 PC / Godot4.6.3 / OpenGL Compatibility / 1920×1080 / 최대60fps / 준비2초·측정18초.',
             '14명+시험 복제4명 대 고체력 탐험가10명, E 지도. 변경 전후 동일한 Step4 performance()를 실행했다.',
             '변경 전은 이번 세션0095(0ef246e0) 코드의 새 측정이며 이전 인계값을 복사한 것이 아니다.', '',
             '| 항목 | 변경 전 | 변경 후 |', '|---|---:|---:|']
    for key in perf:
        lines.append(f'| {key} | {baseline.get(key, "—")} | {perf[key]} |')
    lines += ['', 'mean_process_ms/mean_physics_ms는 Godot Performance 모니터를 프레임마다 읽은 값의 평균이다. 실제 틱 실행시간의 산술평균으로 해석하지 않는다.',
              '프레임 간 실측 간격으로 평균fps·P95·P99를 계산했다. 단일18초 표본이므로 장시간60fps·성능 개선을 보장하지 않는다.',
              '알파 외곽 읽기는 텍스처별로 캐시한다. 크기를 키우기 위한 새 이미지·고해상도 자산은 추가하지 않았다.',
              '개인 저장 접근/수정0, Godot 동시최대1/종료0. 전체 회귀·전체 플레이·export 미실행.']
    (DEST / 'performance.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    audit = {'result': 'TARGETED_PASS', 'existing_files_preserved': len(previous), 'changed_existing': changed,
             'alpha_measurements': len(measurements), 'alpha_failures': len(failures),
             'checks': {mode: result['checks'] for mode, result in results.items()}}
    (DEST / 'capture_audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(audit))


if __name__ == '__main__':
    if '--snapshot' in sys.argv:
        snapshot()
    else:
        publish()
