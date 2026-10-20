from pathlib import Path
from PIL import Image
import json, hashlib, csv, re

REPO=Path(__file__).resolve().parents[4]
BATI=Path(__file__).resolve().parent
UI=BATI.parent/'v1213_ui_icons'
MOODS=['dry','dry_happy','stern','tutorial']
LABELS={'dry':'건조한 무표정','dry_happy':'절제된 만족/미소','stern':'엄한 경고','tutorial':'친절한 설명/발화'}

def load(p):return json.loads(p.read_text(encoding='utf-8'))
def rp(p):return p.relative_to(REPO).as_posix()

def alpha_table(ms):
    s=['| 파일 | 크기 | 알파 0 비율 % | 반투명 비율 % | 알파 1~7 비율 % | 외곽 알파 ≥8 픽셀 | 코어에서 4px 초과·알파 32~239 픽셀 |','|---|---|---:|---:|---:|---:|---:|']
    for m in ms:
        s.append(f"| {Path(m['file']).name} | {'×'.join(map(str,m['size']))} | {m['zero_alpha_pct']:.4f} | {m['partial_alpha_pct']:.4f} | {m['low_alpha_1_to_7_pct']:.4f} | {m['edge_alpha_ge8_pixels']} | {m['alpha_ge32_farther_than_4px_from_core']} |")
    return '\n'.join(s)

def main():
    initial=load(BATI/'alpha_checks.json')['characters']
    preferred=load(BATI/'alpha_checks_fullheight.json')['characters']
    portraits=[m for m in initial if 'portrait' in m['file']]
    ui=load(UI/'alpha_checks.json')['icons']
    use=load(BATI/'expression_usage.json')
    lines=['# 바티 귀여운 체형 — v1213 UI/UX 후보 제작',
        '', '- Generation model: GPT internal image generation',
        '- Generated date: 2026-10-14',
        '- Target version: 1.2.13 (v1213 UI/UX candidate; 사용자 폴더 이름에 따른 가정)',
        '', '## 범위와 인계', '',
        '사용자가 승인한 대화 v4의 큰 둥근 머리·짧고 통통한 몸·짧은 다리를 기준으로 제작했다. 신규 런타임 연결 또는 기존 파일 교체는 하지 않았다. git 명령은 실행하지 않았으므로 브랜치·HEAD·main·원격 권위는 확인하지 않았다. 코드 커밋과 정책/CURRENT 권위 확인은 헤드 작업자가 담당한다. 이 문서가 허용된 쓰기 범위 안의 통합 출처·핸드오프다. docs/handoff는 수정하지 않았다.',
        '', '권장 연결 후보는 `bati_standing_<표정>_fullheight.png` 4개와 `bati_portrait_<표정>.png` 4개다. 최초 1024×1536 전신 후보는 대안으로 보존했다. 전신 전체가 화면 높이를 충분히 채우도록 추가 생성한 정사각 후보는 도형 높이 98.37~98.83%다. 넓은 양 날개를 보존한 1536×1536 납품 크기는 요구 최소 1024×1536의 각 변 이상이다. 정사각 생성 원본은 1254×1254이며 납품본은 균일 확대다. 원본 픽셀의 상세도가 1536 네이티브 생성과 같다고 주장하지 않는다.',
        '', '## 입력 기준', '',
        '- `docs/design/v1213_screens/v1213_dialogue_v4.png`: 체형·캐릭터 승인 기준. 오른쪽 바티만 사용.',
        '- `docs/design/v1213_screens/bati_cute_standing_candidate.png`: 귀·날개·의상·깃펜·장부의 정체성 기준.',
        '- 기존 `CHR_BATI_portrait_dry.png`: 정사각 상반신 초상의 구도 기준만 사용.',
        '', '## 현재 그림 경로 전수 조사', '',
        'rg로 선택 작업트리의 bati / CHR_BATI 참조를 조사했다. tmp, output, builds, web_Demo, docs/handoff/archive는 제외했다. usage_rg_results.txt에 원문, usage_inventory.json에 검색 명령과 파일별 일치 수, expression_usage.json에 JSON 화자/표정 집계를 보존했다. 현재 스냅샷에는 런타임 바티 PNG 9개가 있다. 이름에 `batim`/`CombatIdle`이 들어가는 검색 오탐은 사용처 판정에서 제외했다.',
        '', '| 기존 런타임 경로 | 크기 / 모드 | 현재 용도·연결 | 표정 | 대응 새 후보 |',
        '|---|---|---|---|---|']
    for mood in MOODS:
        lines.append(f'| assets/sprites/portraits/uiux3d/bati_{mood}.png | 1199×1312 / RGBA | characters.json base/variants를 통해 대화·이름 입력·전투 대사·이벤트 출연진에서 공유 | {LABELS[mood]} | bati_standing_{mood}_fullheight.png / 전용 작은 초상에는 bati_portrait_{mood}.png |')
    for mood in MOODS:
        lines.append(f'| assets/sprites/portraits/onboarding/CHR_BATI_portrait_{mood}.png | 512×512 / RGBA | 기존 온보딩 정사각 초상; 현재 코드/데이터의 직접 파일 참조는 발견하지 못함 | {LABELS[mood]} | bati_portrait_{mood}.png |')
    lines.append('| assets/sprites/portraits/onboarding/portrait_bati.png | 512×512 / RGB | 구형 기본 초상; 현재 코드/데이터의 직접 파일 참조는 발견하지 못함 | 기본/건조한 표정 | bati_portrait_dry.png 재사용 계획 |')
    lines += ['', '## 공유 화면·표정 해석', '',
        '| 화면/기능 | 해석 경로 / 현재 표시 크기 | 대응 |','|---|---|---|',
        '| 일반 대화/온보딩 | GameRoot.gd:_onboarding_add_portrait / 전달 rect에 비율 맞춤·하단 정렬, 바티 스케일 0.8 | 전신 4종 |',
        '| 이름 입력 | NameEntryUI.gd:13 / 600×490 | dry 전신 |',
        '| 전투 스토리 대사 | CombatStoryFeed.gd:104-105 / 100×112 | 표정별 초상 후보 |',
        '| 캠페인 공지 출연진 | ManagementSceneController.gd:1046-1053 / 50×50, 비율 채움 | 표정별 정사각 초상 후보 |',
        '| 데이터 기본/미정의 표정 | characters.json:86-112 / base=dry, neutral→dry, briefing→tutorial | 기존 매핑을 유지할 예정 |',
        '', '현재 JSON 화자 집계: '+', '.join(f'{k} {v}건' for k,v in use['emotions'].items())+'. `serious` 2건은 별도 alias가 없어 현재 resolver에서 base=dry로 돌아간다. 이번 작업에서 이를 stern으로 바꾸지 않았다. 캠페인 DAY 1~30, 온보딩 대사, 스토리 파일 및 update3 이벤트에서 CHR_BATI가 관찰됐다. 데이터별 목록은 expression_usage.json 참조.',
        '', '현재는 큰 그림과 작은 초상이 같은 characters.json resolver를 공유한다. 새 작은 초상 4종을 화면별로 선택하는 실제 연결은 헤드가 구현해야 한다. 별도 예외 경로를 수정하거나 코드를 추가하지 않았다.',
        '', '## 생성·저장·후처리', '',
        '모든 생성 호출은 내부 imagegen 도구의 `transparent_background: true`를 사용했다. 외부 API/서비스·배경 제거·알파 임계값으로 도려내기·매팅은 사용하지 않았다. 최초 전신4종은 원본 1024×1536을 복사했고, 상반신4종은 네이티브 1254×1254 RGBA를 512×512로 LANCZOS 축소했다. 추가 전신4종은 네이티브 정사각 RGBA를 1536×1536로 균일 확대했다. originals의 모든 파일은 생성 결과를 그대로 복사했다. 알파는 리사이즈 과정의 보간 외에 수정하지 않았다.',
        '', 'generation_prompts.json와 generation_fullheight_prompts.json에 실제 호출 프롬프트를 보존했다. 총 바티 생성 호출 13회: 최초 dry 시도1회, 초기 전신4회, 초상4회, 높이 채움 전신4회. 최초 dry 시도는 더 넓은 저알파 여백 때문에 최종 후보로 채택하지 않았으며 Codex 기본 생성 저장소에만 남아 있다.',
        '', '## 고정 경로 필드 — 보존 원본과 후보', '']
    for p in sorted(BATI.rglob('*.png')):
        lines.append('- Source image path: '+rp(p))
        name=p.name
        if p.parent==BATI and name.startswith('bati_standing_') and name.endswith('_fullheight.png'):
            mood=name.removeprefix('bati_standing_').removesuffix('_fullheight.png')
            lines.append(f'- Runtime image path: assets/sprites/portraits/uiux3d/bati_{mood}.png (planned; not yet wired)')
        elif p.parent==BATI and name.startswith('bati_portrait_'):
            mood=name.removeprefix('bati_portrait_').removesuffix('.png')
            lines.append(f'- Runtime image path: assets/sprites/portraits/onboarding/CHR_BATI_portrait_{mood}.png (planned; not yet wired)')
    lines += ['- Runtime image path: assets/sprites/portraits/onboarding/portrait_bati.png (planned reuse of dry portrait; not yet wired)',
        '', '원본·미리보기·초기 대안의 Source image path는 출처 추적용이며 별도 런타임 파일을 생성하지 않았다. 파일명에 preview 또는 check가 들어가는 RGB 이미지는 검토용 합성본이며 투명 자산으로 채택하지 않는다.',
        '', '## 알파 및 외곽 검증', '',
        '정의: 투명 비율은 알파=0 픽셀 수 / 전체 픽셀 수다. 반투명은 알파 1~254다. 내부 생성 원본의 넓은 면이 대개 알파253이므로 반투명 비율을 곧바로 헤일로 비율로 해석하면 안 된다. 검사 코어는 알파≥240, 보이는 외곽 기준은 알파≥8이다. 모든 표정에서 실제 알파0을 확인했고 체크무늬를 그린 불투명 배경은 없었다.',
        '', alpha_table(preferred+portraits),
        '', '정사각 전신4종: 귀·날개·깃펜·발끝 모두 유지, 외곽 알파≥8은 0픽셀이다. 일부 외곽에 알파1 잔여 18~36픽셀이 있다. 알파32~239·코어에서 4px 초과 픽셀은 전신당51~133개로 털/깃펜/날개/코트의 가느다란 끝과 일치하는 작은 군집이다. 숫자만으로 엄밀한 무헤일로를 증명하지는 않는다. 직접 본 밝은/어두운 합성본에서는 넓고 연속적인 몸 주변 빛번짐은 보이지 않았다. 알파1~7의 미세 잔여를 숨기거나 제거하지 않고 그대로 기록했다.',
        '', '상반신4종의 코어4px 초과·알파32~239 픽셀은 0개다. 기존 구도대로 몸통을 하단에서 자른 bust이므로 하단 외곽 알파가 0일 필요는 없다. 귀와 좌우 얼굴은 잘리지 않았다.',
        '', 'alpha_checks_fullheight.json은 권장 전신4종, alpha_checks.json은 최초 전신과 초상8종의 전체 수치다. 밝은·어두운 배경 합성은 검토용이며 실제 게임 부팅/화면 연결 검수는 미실행이다. 빌드·전체 회귀·검수 에이전트·커밋·푸시는 요청 범위가 아니므로 실행하지 않았다.',
        '', '## 다음 작업', '',
        '헤드는 권장 전신4종과 작은 초상4종을 대응표대로 연결하고, 정사각 전신의 하단 정렬/비율 및 작은 초상 resolver 분리를 실제 화면에서 확인한다. 기존 generic portrait_bati.png는 dry 초상 재사용 계획이다. 이 폴더 자체를 런타임 자산 경로로 쓰지 않는다. 승인된 v4 체형을 다시 결정할 필요는 없으며, 최종 파일 채택과 연결·커밋은 헤드 작업 범위다.',
        '', '- Review task ID: NOT_REQUESTED', '- Remaining P1/P2: N/A', '- Final review result: TARGETED_PASS (후보의 크기·실제 알파·직접 미리보기 확인에 한정; 게임 검수 아님)',
        '- Branch / base SHA / last commit SHA: NOT_QUERIED (사용자 git 금지)', '- Remote push: NOT_RUN', '- Runtime wiring: not yet wired', '']
    assert not (BATI/'SOURCE.md').exists()
    (BATI/'SOURCE.md').write_text('\n'.join(lines),encoding='utf-8')
    lines=['# 스타일 B — UI 아이콘32종 후보', '', '- Generation model: GPT internal image generation', '- Generated date: 2026-10-14', '- Target version: 1.2.13 (v1213 UI/UX candidate; 사용자 폴더 이름에 따른 가정)', '',
        '## 기준과 제작', '',
        '`docs/design/v1213_uiux/kit/kit_B_cute_dark.png`의 귀여운 다크 판타지 아이콘 톤을 사용했다. 금색 베벨·짙은 자주 외곽·보라색 포인트를 유지했다. 내부 imagegen을 transparent_background:true로 호출해 네이티브 RGBA 원본 시트2장에 각각16종을 생성했다. 두 번째 시트는 첫 번째 시트도 참조해 톤을 맞췄다. generation_prompts.json에 실제 프롬프트를 보존했다. 외부 이미지 서비스 또는 유료 API를 사용하지 않았다.',
        '', '도구에는 전용 크기 인자가 없으므로 프롬프트에2048×2048을 요청했으나 실제 생성 원본은1254×1254다. 4×4 시트를 분리해 각 기호의 실제 알파 영역을 감싼 뒤 비율을 유지하여 최대 길이208픽셀로 축소하고256×256 투명 캔버스 중앙에 넣었다. 배경 제거·알파 임계값 보정은 하지 않았다. 모든 개별 PNG의 최소 여백은24픽셀이고 도형 중심은 반 픽셀 이내로 맞췄다. 가로로 긴 체크 등의 모양에는 반대 축 여백이 더 크며 형태 비율은 보존한다.',
        '', 'prepare_and_check.py에 실제 분할 위치·리사이즈·미리보기·수치 검증을 보존했다. 이 스크립트는 새 파일을 만들 때 기존 파일이 있으면 중단한다. 전체 제작을 다시 실행할 필요 없이 결과 PNG/JSON을 검토할 수 있다.',
        '', '## 아이콘 목록 및 알파 검사', '',
        '| 용도 | 파일 | 크기 | 알파0 비율 % | 반투명 비율 % | 여백 좌/상/우/하 px | 외곽 비투명 픽셀 |', '|---|---|---|---:|---:|---|---:|']
    for m in ui:
        lines.append(f"| {m['label']} | {Path(m['file']).name} | 256×256 | {m['zero_alpha_pct']:.4f} | {m['partial_alpha_pct']:.4f} | {'/'.join(map(str,m['margins_px']))} | {m['edge_nonzero_pixels']} |")
    lines += ['', '## 고정 경로 필드', '']
    for p in sorted(UI.rglob('*.png')):
        lines.append('- Source image path: '+rp(p))
        if p.parent==UI and p.name.startswith('icon_'):
            lines.append('- Runtime image path: assets/sprites/ui/v1213_ui_icons/'+p.name+' (planned; not yet wired)')
    lines += ['', '원본 시트와 icons_preview.png는 출처/검토용이다. 미리보기는 의도적으로 어두운 RGB 배경 위에32종을 나열했다. 개별 icon_*.png만 실제 투명 자산 후보다. 모든 planned 경로는 후속 연결 계획이며 해당 위치에는 아무 파일도 쓰지 않았다.',
        '', '## 검증과 한계', '',
        'Pillow로PNG/RGBA를 디코딩하고 numpy/scipy로 알파0·반투명 비율·외곽·도형범위를 계산했다. 32개 모두256×256이며 알파0 비율52.9373~80.0079%, 외곽 비투명 픽셀0, 최소 여백24px다. 두 시트의 기호가 분할 경계에서 잘리지 않았는지 확인했고 최종 icons_preview.png를 직접 열어 모든 용도를 확인했다. 저장/불러오기, 재생/넘기기/자동재생의 기호는 서로 다르다. 감시초소의 보라색 범위 링은 요청한 의미 표현이며 기호 안의 의도적 반투명 요소다.',
        '', '게임 연결·실행 검수·빌드·전체 회귀는 하지 않았다. git 명령/커밋/푸시도 실행하지 않았다. 기준 브랜치와원격 권위 확인 및 실제 연결은 헤드 작업자가 수행한다. docs/handoff 수정 권한이 없어 이SOURCE.md가 통합 출처·핸드오프를 대신한다.',
        '', '- Review task ID: NOT_REQUESTED', '- Remaining P1/P2: N/A', '- Final review result: TARGETED_PASS (생성 후보의 크기·알파·분할·미리보기 검사에 한정)', '- Runtime wiring: not yet wired', '']
    assert not (UI/'SOURCE.md').exists()
    (UI/'SOURCE.md').write_text('\n'.join(lines),encoding='utf-8')
    # Every new PNG appears exactly once as a Source image path in its own SOURCE.
    checks=[]
    for folder in [BATI,UI]:
        doc=(folder/'SOURCE.md').read_text(encoding='utf-8')
        paths=re.findall(r'^- Source image path: (.+)$',doc,re.M)
        expected={rp(p) for p in folder.rglob('*.png')}
        assert len(paths)==len(set(paths)) and set(paths)==expected
        assert all((REPO/p).is_file() for p in paths)
        assert all(k+':' in doc for k in ['Generation model','Generated date','Target version','Source image path','Runtime image path'])
        plans=re.findall(r'^- Runtime image path: (.+)$',doc,re.M)
        assert plans and all('not yet wired' in p for p in plans)
        checks.append({'source_document':rp(folder/'SOURCE.md'),'source_image_count':len(paths),'planned_runtime_count':len(plans),'source_paths_exist':True,'each_png_referenced_exactly_once':True})
    (BATI/'source_policy_checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),encoding='utf-8')
    # Final file manifest covers only the two allowed directories; sha256 for image transfer.
    for folder in [BATI,UI]:
        manifest=folder/'FILES_MANIFEST.csv'
        with manifest.open('w',encoding='utf-8-sig',newline='') as f:
            w=csv.writer(f);w.writerow(['path','bytes','sha256'])
            for p in sorted(folder.rglob('*')):
                if p.is_file() and p!=manifest:
                    w.writerow([rp(p),p.stat().st_size,hashlib.sha256(p.read_bytes()).hexdigest()])
    print(json.dumps(checks,ensure_ascii=False))
    print('preferred fullbody4 + bust4 + icon32: verified; manifests written')

if __name__=='__main__':main()
