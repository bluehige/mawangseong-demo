"""Publish real viewport evidence using UTF-8 paths; never alter game artwork."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step4b'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step4b_scale')


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    for name in ['scale_place', 'scale_battle', 'battle_contact', 'battle_crowd']:
        source = LOCAL / f'{name}.png'
        if not source.exists():
            continue
        picture = Image.open(source)
        assert picture.size == (1920, 1080)
        shutil.copy2(source, DEST / source.name)
        picture.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        picture.save(DEST / 'previews' / source.name)
    if (LOCAL / 'scale_battle.png').exists():
        # Identical screen crop, from unchanged .75 camera, keeps the same units
        # legible even in the requested reduced review image.
        crop = (580, 280, 1380, 880)
        pair = Image.new('RGB', (1600, 600))
        for index, name in enumerate(['scale_place', 'scale_battle']):
            pair.paste(Image.open(LOCAL / f'{name}.png').convert('RGB').crop(crop), (index * 800, 0))
        pair.save(DEST / 'scale_place_vs_battle.png')
        pair.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        pair.save(DEST / 'previews/scale_place_vs_battle.png')
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
    diagnostic = results['performance']['evidence']['diagnostic_replay']
    lines = ['# 전투 크기·성능 — 사용자 확인 대기', '',
             '실제 1920×1080 / Godot 4.6.3 / OpenGL Compatibility / 최대60fps / 준비2초·측정18초.',
             '생산14명+시험 전용 복제4명 대 고체력 탐험가10명. 변경 전후 동일한 기존 Step4 성능 함수를 실행했다.', '',
             '| 항목 | 변경 전 | 변경 후 |', '|---|---:|---:|']
    for key in perf:
        lines.append(f'| {key} | {baseline.get(key, "—")} | {perf[key]} |')
    lines += ['', '## 원인 분석', '',
              '별도120틱 수동 재생 진단(위 실시간 측정 표본에 포함하지 않음): ' + json.dumps(diagnostic, ensure_ascii=False), '',
              '원인 1줄: 기존 mean_physics_ms는 실제 틱 평균이 아니라 Godot가 1초마다 갱신하는 최대 물리시간을 프레임마다 반복 수집한 평균이어서 약12ms로 보고됐다(순간 지연 원인은 이 값만으로 확정 불가).',
              '근거: [Godot 4.6 main.cpp](https://github.com/godotengine/godot/blob/4.6/main/main.cpp#L4587-L4669). 실제 전투 스크립트 수동 재생 시간은 위 별도 진단을 참조한다.',
              '비교 가능한 기존 필드와 방법은 보존했다. 성능 개선을 확정할 차이는 없으며 전체 회귀·장시간 검수·export 미실행.', '',
              '공통 몸체 기준76×88월드px, 시작 배율0.75 → 최대57×66화면px, 레온·셀렌1.25배. 몸체 비율과 기존 애니메이션 유지.',
              '비교는 동일 카메라 원본1920×1080의 동일(580,280)–(1380,880) 영역을 좌 배치/우 전투로 나란히 합성했다. 원본도 함께 보존.',
              'battle_contact는 실제 원본 DAY7의 첫 교전, battle_crowd는 의도적으로 겹친 일시정지 합성 검수 배치다.', '',
              '그림 새 생성·원본 수정0, 기존 GPT 조각만 사용. 개인 세이브 미접근; 앞 단계 시험 JSON 바이트 불변.']
    (DEST / 'performance.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    audit = {'result': 'TARGETED_PASS', 'existing_files_preserved': len(previous), 'changed_existing': changed,
             'previews_max': [1000, 600], 'checks': {mode: result['checks'] for mode, result in results.items()}}
    (DEST / 'capture_audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(audit))


if __name__ == '__main__':
    main()
