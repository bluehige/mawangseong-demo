"""Compare actual game captures without repainting or substituting mockups."""
import csv
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MOCK = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup')
OUT = MOCK/'game_step2'
REQUIRED = ['build_01_bar','build_02_drag_valid','build_03_drag_invalid',
    'build_04_placed','build_05_radial','build_06_info','build_07_trap_on_road',
    'build_08_moved','zoom2x_start','dynamic_full','dynamic_full_art_only']


def main():
    checks = []
    def check(ok, label): checks.append({'ok':bool(ok),'label':label})
    for name in REQUIRED:
        with Image.open(OUT/f'{name}.png') as image:
            check(image.size==(1920,1080),f'actual game 1920x1080 {name}')
    for left, right, name in [
        (MOCK/'game_step1/game_full.png',OUT/'dynamic_full.png','regress_vs_step1'),
        (MOCK/'ui_icons_v1/ui_preview_build.png',OUT/'build_05_radial.png','compare_ui_vs_mockup')]:
        compare = Image.new('RGB',(3840,1080))
        compare.paste(Image.open(left).convert('RGB'),(0,0))
        compare.paste(Image.open(right).convert('RGB'),(1920,0))
        compare.save(OUT/f'{name}.png')
        check(Image.open(OUT/f'{name}.png').size==(3840,1080),'paired '+name)
    a = np.asarray(Image.open(MOCK/'game_step1/game_full_art_only.png').convert('RGB'),dtype=float)
    b = np.asarray(Image.open(OUT/'dynamic_full_art_only.png').convert('RGB'),dtype=float)
    delta = np.abs(a-b)
    # Same camera, compare independent landmarks rather than just a whole-frame mean.
    regions = {'throne':(1070,65,1280,265),'vault':(1420,300,1580,445),
        'ward_core':(1055,380,1220,550),'barracks':(565,440,770,565),
        'recovery':(940,625,1115,745),'watchtower':(410,525,520,680),
        'bait_treasure':(685,735,800,835),'entrance':(405,710,550,845),
        'entrance_bridge':(70,890,340,1040),'water':(1190,320,1340,370)}
    registration = {}
    for name,(x1,y1,x2,y2) in regions.items():
        options = [(float(np.abs(a[y1:y2,x1:x2]-b[y1+dy:y2+dy,x1+dx:x2+dx]).mean()),dx,dy)
            for dy in range(-3,4) for dx in range(-3,4)]
        error,dx,dy = min(options)
        registration[name] = {'offset':[dx,dy],'mean_rgb_error':error}
        check((dx,dy)==(0,0),'landmark no displacement '+name)
    check(float(delta.mean())<1.0,'near-identical step1 regression mean <1/255')
    source = Image.open(ROOT/'assets/source/imagegen/v130r_step2/cell_highlight_source.png')
    runtime = Image.open(ROOT/'assets/maps/v130r_step2/ui/cell_highlight.png')
    for name,image in [('native source',source),('runtime',runtime)]:
        check(image.mode=='RGBA' and image.getchannel('A').getextrema()==(0,255),'real transparent alpha '+name)
    icon_ids = ['build_barracks','build_recovery_nest','build_ward_core','build_watchtower',
        'build_decoy_treasure','build_spike_trap','build_sticky_trap','menu_info','menu_upgrade',
        'menu_move','menu_dismantle_refund','menu_assign_defenders','frame_normal',
        'frame_selected','frame_disabled','place_auto','place_clear_all']
    for id in icon_ids:
        approved = MOCK/'ui_icons_v1/icons_128'/f'{id}.png'
        used = ROOT/'assets/maps/v130r_step2/ui'/f'{id}.png'
        check(approved.read_bytes()==used.read_bytes(),'GPT icon bytes preserved '+id)
    report = {'result':'PASS' if all(c['ok'] for c in checks) else 'FAIL','checks':checks,
        'mean_rgb_error':float(delta.mean()),'p99_channel_error':float(np.percentile(delta,99)),
        'exact_rgb_fraction':float(np.all(delta==0,axis=2).mean()),
        'fraction_pixel_channel_error_over_16':float(np.any(delta>16,axis=2).mean()),
        'registration':registration,'highlight_native_size':source.size}
    (OUT/'capture_audit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    rows = [
        ['맵 칸·문·수비','승인 plan_E와 자동 계산의 길·문·수비18칸 동일. 자동 테스트로 전체 칸 대조','해소'],
        ['그림 조립',f"art-only 평균 RGB차이 {delta.mean():.6f}/255; p99 {np.percentile(delta,99):.0f}; 대표10영역 이동량0. 칸 알파 경계·연석 조각 분할의 미세 차이",'미세 차이 남음'],
        ['건설 바','목업은 왼쪽 세로, 게임은 사용자 지시대로 하단 가로 7아이콘. 승인 GPT PNG 바이트 동일','의도된 차이'],
        ['원형 메뉴·정보','목업 와이어프레임 도형 대신 실제 맵. 건물 둘레 GPT 5아이콘, 건물 옆 GPT 흑요석 패널. 비용은 기존 게임값이어서 목업 숫자와 다름','의도된 차이'],
        ['유효·불가·범위','새 GPT 네이티브 투명 칸 조각을 녹/적/청/금/보라 색조로 조립. 원점 후보 전체 A* 판정은 프레임 분할 후 표시','대표 화면 사용자 확인 대기'],
        ['시작 카메라','엄밀한 원본0.75배(96×48칸)는 양 끝을 동시에 담을 수 없음. 기본 시작은0.43 안전 맞춤(약55×28칸), 옥좌·입구 다리 전체 포함. 휠로0.75 이상 확대 가능','엄밀한 기본2배 요구와 차이 남음'],
        ['임시 규칙','개별 가시40금/끈끈이60금, 환불=실제 지불액50% 내림, 오라=0069 시각화 반경. 초기18수비는plan 유지, 신규 시설은기존 성단계 정원 보너스 적용','밸런스 승인 아님'],
        ['다음 단계','수비 지점만 자동 계산·표시. 몬스터 편성 UI·전투 연결 미구현(요청 제외)','범위 유지'],
        ['설계서4-3','원문 경로 미제공. 네 칸 점유를 보는 이중 격자 꼭짓점 선택+연속 경계 조립으로 구현. 해당 절 원문 자체와 대조하지 못함','원문 대조 미실행']]
    for filename, selected in [('differences.csv',rows),('ui_differences.csv',rows[2:7])]:
        with (OUT/filename).open('w',encoding='utf-8-sig',newline='') as file:
            writer=csv.writer(file); writer.writerow(['항목','실제 차이·근거','상태']); writer.writerows(selected)
    for mode in ['direct','gui']:
        result = json.loads((ROOT/f'tmp/v130r_step2/{mode}_result.json').read_text(encoding='utf-8-sig'))
        check(result['result']=='TARGETED_PASS',mode+' actual test pass')
    for name in ['direct.log','direct.err.log','capture.log','capture.err.log','direct_result.json','gui_result.json']:
        import shutil
        shutil.copy2(ROOT/'tmp/v130r_step2'/name,OUT/name)
    # Preserve pre-existing dirty files; no assumptions about their authorship.
    old = json.loads((ROOT/'tmp/v130r_step2/existing_hashes.json').read_text())
    changed = [p for p,sha in old.items() if not (ROOT/p).is_file() or hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=sha]
    preservation = {'existing_dirty_files':len(old),'changed':changed,
        'save_protection':'All Godot launches set isolated APPDATA/LOCALAPPDATA; only explicitly copied v5/v6 files and branch sidecar written.',
        'original_user_save_hash_baseline':'Not collected in this session; no claim of a full original-user-folder hash audit.'}
    (OUT/'preservation_audit.json').write_text(json.dumps(preservation,indent=2)+'\n',encoding='utf-8')
    check(not changed,'pre-existing dirty files preserved')
    report['checks'] = checks
    report['result'] = 'PASS' if all(c['ok'] for c in checks) else 'FAIL'
    (OUT/'capture_audit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k not in ['checks','registration']},indent=2))
    print('Checks',len(checks),'failures',[c['label'] for c in checks if not c['ok']])
    if not all(c['ok'] for c in checks): raise SystemExit(1)


if __name__=='__main__': main()
