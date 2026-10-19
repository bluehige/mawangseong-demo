"""Create the final review only after required evidence is available."""
import json
from run_audit import ROOT, OUT, engines

def load(name): return json.loads((OUT/name).read_text(encoding='utf-8-sig'))
assert not engines(), engines()
campaigns=load('campaign_summary.json')
runs=[json.loads(p.read_text(encoding='utf-8')) for p in sorted((OUT/'runs').glob('*.json'))]
legacy=load('legacy_checks.json')
layout=load('layout_checks.json')
dialogue=load('dialogue/after.json')
behavior=load('dialogue/behavior.json')
native=load('computer_use.json')
logs=load('log_summary.json')
identity=load('integrity_final.json')
head=load('baseline_git.json')['head']
required=['campaign_'+str(s) for s in [130401,130402,130403]]+['restart_'+str(s) for s in [130401,130402,130403]]+['legacy','layout','dialogue_after','dialogue_behavior','windows_export','data_story','data_monsters','data_map_localization','validator_tests']
assert all(any(r['id']==name for r in runs) for name in required), 'Missing run records'
pass_runs=all(not r['exit_code'] and not r.get('timeout',False) and not r.get('error_lines',0) for r in runs)
campaign_ok=len(campaigns)==3 and all(c['recorded_days']==30 and c['battle_wins']==29 and not c['campaign_failures'] and not c['restart_failures'] and c['resumed_day']==30 and c['resumed_postgame'] and c['day29']['preparation_only'] for c in campaigns)
local_ok=pass_runs and campaign_ok and not legacy['failures'] and not layout['failures'] and not dialogue['violations'] and not dialogue['failures'] and not behavior['failures'] and native['passed'] and not identity.get('unexpected_changes',identity['changed']) and not identity['missing']
verdict='조건부' if local_ok else '불가'
status='해소' if local_ok else '근거별 결과 확인 필요'
tested=sum(x['tested'] for x in dialogue['counts'].values())
rows='\n'.join(f"| {c['seed']} | {c['battle_wins']}승 / DAY29 준비 / {c['retries']}회 | {c['hp']}/{c['max_hp']} | {c['ending'].get('ending')} | {c['campaign_checks']} / {c['restart_checks']}, 실패 {len(c['campaign_failures'] or [])}/{len(c['restart_failures'] or [])} |" for c in campaigns)
run_rows='\n'.join(f"| `{r['id']}` | {r['exit_code']} | {r.get('error_lines',0)} / {r.get('warning_lines',0)} | {r['seconds']:.2f} |" for r in runs)
report=f'''| ID | 0121 후 해소 여부 / 분류 | 판정 근거 |
|---|---|---|
| B01 · P0 | 기존 해소 유지 | 기존 현재 입력 2회×47검사 재사용. 새 3회 캠페인의 대사 진행과 0121b 입력 {behavior['checks']}검사로 보완. |
| B02 · P1 | 기존 해소 유지 | 기존 B02/B03 377검사 재사용. 성장·공통 전투 연결 수치 변경 없음. |
| B03 · P1 | 기존 해소 유지 | 새 연속 캠페인 3회에서 자연 날짜·원정·전직·DAY29 준비·DAY30 엔딩 점검. 모든 전선/의회 엔딩 조합 보장은 아님. |
| B04 · P1 | 완주 차단 해소 유지 / 잔여 권장 | 아래 새 3회 결과와 기존 10회 곡선·배치 비교를 구분. DAY15~28 승률100%, 집중 배치 우위는 비차단. |
| B05 · P1 | 기존 해소 유지 | 기존 10,946검사·언어별 스킬 설명214필드 재사용. 새 en/zh 설정·대사 측정·지도 번역 검사로 표시 변경 보완. |
| G01 | {'기능 해소 / 출시 세이브 출처 제한' if campaign_ok else '미해소 · 차단'} | 엔딩→후기 실제 디스크 저장→별도 프로세스 재시작 복원 {sum(not c['campaign_failures'] and not c['restart_failures'] and c['resumed_postgame'] for c in campaigns)}/3. 구 v1~v6 사본 {legacy['checks']}검사. 실제 1.2.12/Steam1.3.0 출시판에서 만든 저장의 출처 증빙은 미확보. |
| G02 | 미해소 · 사용자 출시 단계 | Steam 접속·게시·실계정 해제 미실행. 로컬 업적 근거는 기존 감사 재사용. 보고서 말미 사용자 단계 필요. |
| N01 · P1 | {status} | 3회 모두 신규 동료 포함 후기 저장·v6 DAY30 플래그·11개 상태 영역 재시작 비교. 이전 0/3 저장 실패 기록은 이전 감사에 보존. |
| N02 · P2 | {'표적 해소' if local_ok else '근거별 결과 확인 필요'} | 새 Windows export 및 실제 EXE의 오류/경고는 아래 범주 집계. 이전 빈 번역/리소스 오류와 구분. |
| N03 · P2 | {'표적 해소' if native['passed'] else '미해소'} | 새 EXE 실제 조작의 DAY1 전투·승리 대사 Space·Escape 메뉴·저장·종료·재시작 Continue 결과는 Computer Use 기록 참조. |
| V01 · P2 | {'표적 해소' if not layout['failures'] else '미해소'} | en/zh_CN 설정 5분류의 카드·라벨 여백과 실제 대표 화면. |
| V02 · P3 | {'표적 해소' if not layout['failures'] else '미해소'} | 업적 알림 y≥160 및 클릭 통과 검사. 960px 이하 알림 대표 캡처. |

**최종 판정: {verdict}. 사용자 확인 대기.**

{'요청한 로컬 표적 검증은 통과했다. 공개 출시 가능으로 무조건 승인하지 않는다. G02 사용자 작업, 출시 세이브 출처 제한 확인 및 아래 비차단 편차의 수용을 남긴다.' if local_ok else '필수 실행/단언/무결성 중 실패 또는 미완료가 있어 출시 가능으로 판정하지 않는다. 아래 실제 결과를 따른다.'}

기준: 1.3.0, 2026-10-19 KST, `codex/v130r-defense-layout`, 검수 제품 SHA `{head}`. 제품 코드·데이터·자산·밸런스 변경0. 기존 추적 import 1,307개를 보존했다. 사용자 저장 원본에 접근하지 않고 기존 테스트 사본과 새 격리 프로필만 사용했다. push/fetch/태그/Steam/main 조작0. 로컬 main은 없고 캐시 origin/main `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 원격 최신성은 미확인이다.

새 캠페인(3개 모두 새 게임부터 연속 진행, 자원·성장·승패 임의 주입 없음):

| 시드 | 전투 / 준비일 / 재도전 | DAY30 HP | 엔딩 | 본 실행 / 재시작 검사 |
|---|---|---:|---|---|
{rows}

후기 버튼으로 관리에 진입한 뒤 저장을 강제 반영하고 실제 v6 파일의 DAY30·완주·후기 플래그를 읽었다. 그 후 엔진을 종료하고 같은 격리 저장을 별도 프로세스에서 불러와 날짜·HP·금·마나·식량·식량/허기·완주·후기·엔딩·로스터·배치를 비교했다. [요약](campaign_summary.json), [90일 CSV](campaign_day01_30.csv), 원본 `campaign_1304xx_*`, `runs/`와 `logs/` 참조. 공통 전투 코드를 60Hz로 진행하고 장식 렌더만 줄인 기존 FastController 시험이며 30일 연속 EXE 수동 플레이를 뜻하지 않는다.

구 저장은 `tmp/v130_m6/original_copies/`의 v1~v5 및 이전 감사 격리 EXE의 v6를 다시 격리 복사했다. 6개 입력 사본의 해시 불변, 날짜·체크포인트 보존, 정상 v6 변환을 검사했다([출처와 결과](legacy_checks.json)). 제품에 의한 테스트 복사본의 마이그레이션만 허용했으며, 파일을 수동으로 고쳐 통과시키지 않았다. 이 사본들의 정확한 제작 출시판은 확인되지 않았다.

Windows export는 현재 프로젝트의 `Windows Desktop`을 새로 빌드했다. 실제 Main 진입이며 테스트 스크립트·창 크기 autoload를 EXE에 주입하지 않았다. APPDATA/LOCALAPPDATA는 `tmp/release_audit_v130c_v130r_release_blockers/profiles/computer_use/`, Steam 초기화는 `MAWANG_DISABLE_STEAM=1`로 차단했다. [빌드 파일 해시](build_files.json), [실제 조작·저장·재실행](computer_use.json), [캡처 폴더](captures/) 참조. 원시 스크린샷은 모델에 전달하지 않고 960px 이하 사본만 직접 열람했다. 직접 이미지 열람은 {native['direct_images_total']}장으로 12장 이하다.

en/zh_CN 대표 설정 화면과 알림은 실제 렌더했으며 [레이아웃 {layout['checks']}검사](layout_checks.json), [영어 설정](settings_en.png), [중국어 설정](settings_zh_CN.png), [알림](toast_zh_CN.png)에서 확인한다. 대사 넘침 검사기 0121b 재실행은 19 UI×3언어×2해상도×2배율 {tested:,}배치, 넘침 {len(dialogue['violations'])}건, 원문 보존 {dialogue['checks']:,}검사·입력 {behavior['checks']}검사다([측정](dialogue/after.json), [입력](dialogue/behavior.json)). 원어민 교정·모든 화면 실플레이·글 전체의 의미 검수는 아니다.

데이터 무결성: 스토리 73,027검사, 몬스터 2,408검사, 지도 번역164키/우선144항목/고유명24종, 검증기 자체13테스트의 실제 종료 결과는 `runs/`와 `data_*.json` 참조. 보호 waves 해시는 `2d5b3519c6bf6a630a099844d07a2db92a5646fe5425db7d3ff392168205b539`이며 0119c 최종판과 LF 정규화 후 동일하다. DAY29 빈 웨이브를 유지했다. [이전 근거 색인](reused_evidence.json), [변경 보존 결과](integrity_final.json), [export import 보존](export_import_preservation.json).

잔여 편차는 요청대로 **비차단 / 권장**으로 유지한다. 아래 값은 과거 고정 비교이며 이번 HEAD의 새 10회 재측정이 아니다.

| 항목 | 수치 근거 | 분류 |
|---|---|---|
| B04 난도 곡선 | 0119c `0dec2aac` 새 게임10회: 정상 재도전 포함10/10 완주, 무재도전9/10. DAY15~28 첫 승률100%. HP15/16=78.27/76.62%, 25/26=47.64/44.90%. | 비차단 / 권장, 목표 미달 기록 유지 |
| DAY5 몰아배치 | 추천 HP81.07%, 최종선 집중84.80%: 집중 +3.73%p, 승률은 모두100%. | 비차단 / 권장 |
| DAY15 몰아배치 | 추천79.35%, 병영·핵·옥좌 집중79.71%: 집중 +0.36%p, 승률 모두100%. | 비차단 / 권장 |
| DAY27 몰아배치 | 추천45.34%, 집중46.50%: 집중 +1.16%p, 승률 모두90%. | 비차단 / 권장 |
| 명령 손해 2/24전투 | 12쌍24전투 모두 승리. 실제 발동11쌍 중 DAY15/130401 HP1216→1190(−26)·생존9→8, DAY30/130403 HP769→535(−234). DAY15/130402는 위기 미발생으로 미발동. | 비차단 / 권장, 항상 이득 보장 아님 |

“HP1~6%p”는 개괄 표현으로만 보존하며 확정 근거는 위의 **3.73/0.36/1.16%p**다. 배치 비교는 v9_candidate의 실제 진입 사본80개에 최종 웨이브를 적용한 것으로 최종10회 성장 경로와 동일하지 않다. [원본 곡선](../../tmp/v130r_b04/v13_report/day_curve.md), [원본 배치 표](../../tmp/v130r_b04/v13_report/stacking_compare.md), [명령 비교](../../docs/handoff/V130R_FIX_COMMANDS_2026-10-18.md). waves·스탯·명령 효과 수치는 변경하지 않았다.

기존 성능은 재측정하지 않았다. 이전 E19/D25/C30 평균46.08/35.80/38.57FPS 및 조건·한계는 [기존 감사](../release_audit_v130b/RELEASE_AUDIT.md)를 따른다. 로로 원정 위험 표기, E 건설 상한/기본도면, 의회 임시 안전 시설 자격, 자연 기억/합동기·전문화·모든 엔딩·장기 경제 전수, Steam 재전송 시나리오·내장 그래픽·음원/문장 취향은 기존 [잔여 대조](../release_audit_v130b/residual_review.md)를 유지한다. 요청 없는 전체 회귀·전체 수동 플레이·별도 전체 검수 에이전트는 미실행이며, 읽기 전용 보조 조사1명은 기존 근거/변경 범위만 대조했다.

이번 실행 오류 로그는 이전 0120의 오류123/경고8,941과 합산하지 않는다. 이번 합계 ERROR/SCRIPT ERROR **{logs['total_errors']}**, WARNING **{logs['total_warnings']}**. [범주별 집계](log_summary.json)에 캠페인·재시작/구사본/export/EXE/언어/0121b/데이터 검증을 분리했다. 종료0만으로 PASS 처리하지 않고 결과 JSON의 실패 배열·저장 파일·복원 상태를 함께 읽었다. 데이터 검사3종은 초기 중복 호출로 2회 실행됐고 모두 종료0이었다. 아래 실행 표와 원시 로그는 최종 호출 기준이며 [초기 호출 기록](static_duplicate_history.json)을 별도로 남겼다.

| 새 실행 | 종료 | 오류 / 경고 | 초 |
|---|---:|---:|---:|
{run_rows}

보존·실행 제한: Godot은 직렬1개 이하, 이 작업 종료 시0개. 생성 이미지0, 직접 이미지 {native['direct_images_total']}/12장·모두960px 이하 사본. 초기 Git 상태/인계 읽기 일부가 필요 이상 길게 잘려 출력됐으며 이후 결과·로그는 요약만 전달했다. 기존 산출물을 덮어쓰지 않고 새 폴더에 기록했다. 빌드·캡처·원시 로그는 로컬 산출물이며 소스 커밋에 넣지 않는다.

G02 — 사용자가 할 단계(이 작업에서는 실행하지 않음):

1. Steamworks **App 5267750**에서 업적 **100개**의 업로드를 확인한다. API 이름·표시 이름·설명·아이콘이 로컬 정의와 맞는지 확인한다.
2. Steamworks에서 변경 사항을 **게시**하고 게시 완료 상태를 확인한다.
3. 실제 Steam 계정으로 출시 대상 빌드를 실행해 아직 미해제인 업적 **1개를 정상 플레이로 해제**하고 Steam 클라이언트/프로필에 해제가 반영되는지 확인한다. 사용한 계정·업적 API 이름·빌드·시각과 결과를 남긴다.

**사용자 확인 대기.** 위 사용자 단계와 남은 제한의 확인 전에는 공개 출시·태그·Steam·main 작업을 수행하지 않는다.
'''
(OUT/'RELEASE_AUDIT.md').write_text(report,encoding='utf-8')
print(json.dumps(dict(verdict=verdict,local_ok=local_ok,campaigns=campaign_ok,run_count=len(runs),overflow_tested=tested),ensure_ascii=False))
