from pathlib import Path
import datetime, json, subprocess
P=Path(__file__).resolve().parent
def read(name, default=None):
    f=P/name
    return json.loads(f.read_text(encoding='utf-8-sig')) if f.exists() else default
def link(path,label=None): return f'[{label or path}]({path})'
logs=read('log_summary.json',{})
perf=read('performance_summary.json',[])
runs=read('run_index.json',[])
campaigns=read('campaign_summary.json',[])
build=read('build_files.json',[])
locales=read('localization_runtime.json',{})
total=sum(x['bytes'] for x in build)
performance_rows=[]
for x in perf:
    rss=next((r['peak_rss_bytes'] for r in runs if r['id']==f'perf_1080_day{x["day"]}'),None)
    if rss is None: rss=next((r['peak_rss_bytes'] for r in runs if r['id']==f'perf_final_day{x["day"]}'),0)
    performance_rows.append(f'| {x["grade"]} / {x["day"]} | {x["samples"]} | {x["mean_ms"]:.2f} / {x["mean_fps"]:.1f} | {x["p95_ms"]:.2f} | {x["p99_ms"]:.2f} | {rss/1048576:.0f} / {x["static_memory_bytes"]/1048576:.0f} | {x["max_monsters"]} / {x["max_enemies"]} | {x["layout_msec"]} |')
campaign_rows=[]
for c in campaigns:
    brief=[]
    for r in c['attempts']:
        brief.append(f'D{r["day"]}{" 재시도" if r["retry"] else ""}: {"승" if r["win"] else "패"}, HP {r["hp"]}, 식량 {r["food"]}, 금 {r["gold"]}, 합류/가용 {r["owned"]}')
    campaign_rows.append(f'| {c["seed"]} | '+ '<br>'.join(brief)+f' | DAY{c["max_entered_day"]}; 엔딩 미도달 |')
top=[]
for x in logs.get('top20',[]):
    top.append(f'| {x["count"]} | {x["type"].replace("|","/")} | {link(x["example"],"로그")} |')
exe_trace=read('export_flow.json',[])
manual=read('manual_export_check.json',{})
export_ok=any(x.get('tag')=='saved' for x in exe_trace) or manual.get('saved',False)
export_text='타이틀→새 게임→DAY1 실제 전투→저장→정상 종료 확인' if export_ok else '빌드 생성 PASS. EXE 전체 조작 결과는 아래 실행 기록에 따르며 아직 완료 증거 없음'
if read('user_interruption.json',None): export_text='EXE 실제 타이틀·메뉴까지 확인. 사용자의 물리 Esc로 Computer Use 중단; 새 게임·DAY1 전투·저장·정상 종료는 미검수. 이 작업 소유 EXE는 정리 종료'
names=[]
for language in ['ko','en','zh_CN']:
    for category in ['monsters','enemies','hpbar_names','skills','specializations']:
        row=locales.get(language,{}).get(category,{})
        names.append(f'| {language} | {category} | {row.get("tested","미측정")} | {row.get("untranslated_count","미측정")} |')
report=f'''불가 — DAY3 전투 대사 종료 시 실행 오류가 재현되며, 3회 연속 캠페인 모두 엔딩에 도달하지 못했다.

출시 차단 목록(1인 작업량 추정, 수정은 이번 감사에서 하지 않음):

| ID·우선순위 | 문제·근거 | 예상 작업량 |
|---|---|---|
| B01 · P0 | DAY3 전투 대사 종료가 옛 전투 HUD를 재생성한다. `debug_cell_data`/`tile_size` 누락과 해제된 sprite 참조 오류. 고정 시드 13011·13012에서 재현. [오류](logs/campaign_final_13011.stderr.log), [완료 처리](../../scripts/game/GameRoot.gd#L7639), [새 지도](../../scripts/game/ApprovedBattleController.gd#L172) | 0.5~1일 |
| B02 · P1 | 새 전투의 아군 생성은 기본 종족값+전문화만 적용한다. 기존 레벨·집중 성장·전직·칙령·왕관 능력치 계산을 우회한다. [새 생성](../../scripts/game/ApprovedBattleController.gd#L101), [기존 계산](../../scripts/game/GameRoot.gd#L12828) | 연결·비교 검사 1~2일 |
| B03 · P1 | 날짜 이동이 전선·의회 날짜 진입을 우회하고 전투는 기본 waves만 사용한다. 원정/전선/의회 및 다음 회차 지도 초기화에 회귀 위험. [독립 추적](regression_review.md), [날짜 이동](../../scripts/map_builder/ApprovedGradeProgression.gd#L159) | 연결·경계 검사 1~2일 |
| B04 · P1 | 자동 배치 캠페인 3회 완주 0. DAY1도 시드 13013에서 2연패. 이전 STEP10B의 DAY20·21·26 배치 우위, DAY22·23·30 난이도 목표 미달도 해소 근거 없음. DAY30 과거 승률40%/평균HP27.99%. [이번 기록](campaign_day01_30.csv), [이전 목표](../../docs/handoff/V130R_STEP10B_DC_SPREAD_2026-10-17.md#L111) | B02와 중복 고려, 조정·재측정 2~4일 |
| B05 · P1 | 영어·중국어 실제 지도에서 건물·식량·전투 상태 한국어 잔존. 현재 로드된 스킬 설명도 각 3개 미번역. [영어 화면](captures/en_guide.png), [중국어 화면](captures/zh_CN_battle.png), [키 목록](localization_runtime.json) | 문구 연결·표적 검수 0.5~2일, 원어민 교정 별도 |
| G01 · 출시 증빙 게이트 | DAY4~30 연속·엔딩·후기 저장/이어하기를 검수할 수 없음. 실제 1.2.12/Steam 1.3.0에서 만들어진 별도 출처 확인 세이브도 확보되지 않음. | B01 해결 뒤 추가 캠페인/저장 검사 1~2일 |
| G02 · 업적 출시 게이트 | 로컬 100개 판정은 통과하나 Steamworks 7개 추가 세트 ID·게시·실계정 해제는 저장소 기록상 미확인. 현재 요청의 Steam 금지로 접속/변경하지 않음. [등록 기록](../../data/v130r/achievements/README.md), [범위](regression_review.md) | 승인된 별도 담당 확인 0.5~1일 |

공통 연결 수정이 겹치므로 위 작업량을 단순 합산하지 않는다. **최소 선행 순서: B01 → B02/B03 → 캠페인·밸런스 → 번역/실제 출시 증빙.**

크래시 원인 1줄: **전투 대사 닫기의 기본 완료 동작이 `_set_screen("combat")`을 호출해 Approved 지도 뷰를 지우고 옛 HUD를 만들면서, 맞지 않는 지도 API와 이미 해제된 캐릭터 그림을 참조한다.** 엔진 자체 접근 위반 종료를 확인한 것은 아니며, 스크립트 오류 후 감사 실행기가 해당 프로세스를 종료했다.

기준: 2026-10-18 KST, 목표 1.3.0, `codex/v130r-defense-layout`, 제품 SHA `a61404b8e38f659275f591eab0000f481325d81a`. 로컬 main 없음. 캐시 origin/main `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`; 원격 최신성 미확정. 요청한 0113c 이후 STEP14/13B도 포함한 현재 HEAD를 검사했다. 제품 코드·데이터·자산 수정, push·태그·Steam·main 조작 없음.

| 항목 | 판정 | 이번 감사의 근거·한계 |
|---|---|---|
| 1 캠페인 3회 | FAIL | 서로 다른 고정 시드 13011/13012/13013, 새 게임·튜토리얼·자동 배치·x3·정산. DAY2 저장/GameRoot 재생성·이어하기 2/2 성공, 패배→HP1500 복구→같은 배치 재전투 확인. 완주0/3. DAY4~30은 NOT_REACHED. |
| 2 구 세이브 | WARN | 실제 개인 DAY2의 스키마 v1/v4/v5 사본 각1개: Continue·v6 이관·다음 전투 승리 3/3. DAY/HP/식량/금/기존 3종의 레벨·EXP·유대·기억·전문화 차이0. 정확한 제작 출시 버전은 미상. |
| 3 Windows export | {'PASS' if export_ok else 'WARN'} | Windows Desktop release export 성공, {total:,}bytes ({total/1048576:.2f}MiB), 4파일. {export_text}. [파일/해시](build_files.json). |
| 4 ko/en/zh_cn | FAIL | 대표6화면×3언어=18장, 각1280×720 축소본을 한 장씩 확인. 해당 화면에서 글자 넘침 관찰0/기하 검사0. 지도 혼용과 스킬 설명 누락 존재. 모든 화면·대사의 실제 렌더 전수 완료는 아님. |
| 5 성능 | WARN | 1920×1080 실제 창/논리 뷰 확인한 E/D/C 표본. 평균 약46~50FPS, P99 약73~90ms. 내장 그래픽 실측·하한 추정 불가. |
| 6 오류 로그 | FAIL | 등록 실행 {logs.get('runs',0)}회 전체에서 ERROR/SCRIPT ERROR {logs.get('errors',0)}, WARNING {logs.get('warnings',0)}. 진단용 잘못된 실행·구 테스트 단언·시험 상태 경고도 포함. 상세 분류는 아래. |
| 7 데이터 무결성 | FAIL | 몬스터2402검사 PASS, 전문화331검사 PASS, 스토리73027검사 중 보호 원본 해시 drift 2건. 자동 길105137검사/회색상자233058검사 PASS. 이전 기대 개체 수와 새 24종·16합동기 사이의 구 검사 불일치도 남음. |
| 8 기존 잔여 | WARN | STEP1~12의 23문서 전부 대조, STEP13/14 해소 여부 구분. [분류](handoff_review.md), [원문/행 색인](handoff_remainders.md). |
| 9 기존1.2.x 기능 | FAIL | 원정·칙령·전선·의회·다음 회차 경로 우회 확인. 개별 서비스 통과를 일반 플레이 복구로 간주하지 않음. 기존6합동기 전체의 새 지도 실전 PASS 증거 없음. |
| 10 시작 UX | WARN | 타이틀→메뉴→프롤로그7문장→바티2턴→이름→확인→본편→새 지도 안내→전투 순서 정상. 기본 맵에 건물이 있어 건설 실습은 자동 생략. 3일 이후 대사 종료는 B01. |
| 11 Steam 업적 | WARN | 100개/8세트/숨김8, 양성·음성·중복·소급/큐 검사 포함636개 PASS. 오프라인 실제 초기화 실패는 안전 처리. DLL2개 export 포함. 실제 서버 등록·온라인 동기화는 NOT_RUN. |

캠페인 상세(HP 최대1500, 이번 감사가 승패·능력치·자원을 강제로 바꾸지 않은 연속 경로):

| 시드 | 날짜별 결과·잔액 | 중단 |
|---|---|---|
{chr(10).join(campaign_rows)}

DAY2 저장·Continue는 같은 날짜/지도·HP·잔액 복원을 확인했다. 합류/가용은 DAY1 세 동료, DAY2 로로 포함 네 동료다. 모든 날짜의 결과·합류/가용 개수·잔액은 [30일 표](campaign_day01_30.csv), 전체 로스터·정산은 `campaign_<seed>_days.json`에 있다. 재시도마다 1500 회복은 제품의 기존 재시도 동작이다. 13001~13003은 대사 오버레이 처리/초기 RNG 재설정 진단 실행이며 최종3회에 포함하지 않는다.

자동 진행의 선택 가정: 추가 건설/강화·직접 전술 명령 없이 기본 지도와 실제 자동 스킬을 사용했다. 집중 성장은 처음 선택 가능한 대상을 선택하고 확인했다. 패배한 날은 같은 자동 배치로1회 재시도한 뒤에도 패배하면 그 시드를 끝냈다. 따라서 모든 플레이 전략에서 이길 수 없다는 주장은 아니다. 저장 재실행은 같은 엔진 프로세스 안에서 GameRoot를 제거·새로 생성한 검사이며 운영체제 프로세스 재시작과 구분한다.

F→E DAY15, E→D DAY20, D→C DAY27과 DAY29 무전투는 [독립 경계 시험](boundaries_13001_events.json)에 별도 기록했다. **시험 상태에서의 경계 확인을 자연 연속 캠페인 통과로 계산하지 않는다.** DAY30 엔딩·후기 저장/이어하기·원정/의회 자연 해금은 차단으로 미검수다.

구 저장의 데이터 손실/변환:

- [형식별 비교](save_compatibility_comparison.json): 확인한 DAY2 표본의 기존 숫자·로스터 필드 손실0. 정수↔실수 JSON 표현 차이는 값 손실로 세지 않았다.
- 옛 방 좌표/기존 길을 정확히 복제하지 않고 해당 날짜의 안전한 새 기본 지도로 바꾼다. 새 식량 서비스의 수입/상한이 적용된다. 이 표본 식량24는 보존됐지만 상한 초과의 일반 저장은 잘릴 수 있다.
- 5개 원본은 동일 DAY2에서 단계적으로 이관된 파일이므로 독립 출시판 5종이라고 주장하지 않는다. 정확한 1.2.12/Steam1.3.0/다른1.2.x 표본의 전수 호환은 미확인이다.

번역 수치(현재 런타임 번역기로 원문·번역 결과의 한국어 잔존을 검사한 필드 수):

| 언어 | 분류 | 검사 필드 | 미번역 필드 |
|---|---|---:|---:|
{chr(10).join(names)}

미번역 설명 ID: `royal_no_second_cut`, `tricolor_demonfire`, `royal_urgent_courier`. 본편 영어 대사1741/장면216의 ID·치환 토큰 검사는 PASS. 추가3언어 스토리 데이터 검증의 실패2건은 `data/story/v122_main/day_01.json`과 `data/waves.json`의 보존 기준 해시가 후속 의도된 변경과 달라진 건이다. 문장 손상이라고 단정하지 않지만 검증기 FAIL은 유지했다. 검증기 자체13테스트 PASS.

정적 번역 재고8328문자열 중 사전의 정확한 키가 없는 후보는 영어/중국어 각각3164개, 그중 새 Approved 지도 코드 관련 후보144개다. 설명용 데이터·진단문·조합 가능한 템플릿도 포함하므로 **실제 화면 누락3164개라는 뜻은 아니다.** [후보 원문/위치](localization_inventory_result.json). 새 지도 화면의 `결계핵`, `미끼보물실`, `가시 함정`, 수입/창고/옥좌 상태 등은 실제 캡처에서도 한국어로 남았다. 미검수 화면의 넘침 수는 0으로 처리하지 않았다.

성능 표(프레임 간격 ms; 3초 준비 구간 제외, 각 약42초 표본, x3):

| 등급/DAY | 프레임 표본 | 평균ms / 환산FPS | P95ms | P99ms | 최고RSS/정적메모리 MiB | 최대 아군/적 | 지도 준비ms |
|---|---:|---:|---:|---:|---:|---:|---:|
{chr(10).join(performance_rows)}

i5-13500 / RTX3060Ti / RAM 약64GiB / Windows11 / Godot4.6.3 / OpenGL Compatibility. [하드웨어](hardware.json), [측정 원자료](performance_summary.json). 부하 시험은 모든 동료를 시험 해금하고 합법 자동 배치·유지비 한도를 적용했다. 옥좌HP100000·스토리 비활성은 표본 유지용 시험 조건이며 캠페인 밸런스 근거가 아니다. 별도 1280×720 초기 표본은 위 수치에서 제외했다. 다른 프로젝트의 headless Godot가 실행된 구간이 있어 시스템 전체 격리 성능이 아니며, 내장 그래픽 성능으로 환산하지 않는다. GameRoot 로딩 시간은 각 `*_events.json`의 `boot.load_msec`; 프로세스 전체 시작 시간과 구분한다.

오류/경고 상위20유형(감사 전체 원시 발생 횟수, 같은 근본 오류의 후속 연쇄도 각각 센다):

| 횟수 | 유형 | 예시 |
|---:|---|---|
{chr(10).join(top)}

대부분의 자동저장 경고는 날짜만 주입했던 초기 성능 시험의 성 진화 단계 불일치다. 현재 정상 캠페인의 저장 성공2/2와 혼동하지 않는다. 초기 EXE `--path` 거부·보호 프로필명 단언은 감사 도구 조건 문제로 분류했다. `catalog.size()==6/14`류는 구 테스트 기대치 문제다. `DuoLinksPhase10Test`의 실제 발동/대상·배열 오류 등은 별도 재현이 필요한 잔여로 남긴다. [전 실행 명령/종료/메모리](run_index.csv), [전체 유형](log_summary.json). 오류 후 강제 종료한 실행은 정상 종료 PASS로 세지 않았다.

기존 지적의 비차단/조건부 잔여:

| 우선순위 | 잔여·처리 판단 | 예상 |
|---|---|---|
| P1 또는 명세 변경 필요 | 로로 원정 위험−1은 표시/기록뿐이며 실제 실패·피해 규칙에는 작용하지 않음 | 수용 판단1~2시간, 구현1~2일 |
| P2 | E 건설 상한7/기본 도면8 불일치, 전문화 일부 조합 약화, 자연 합동기 해금/모든 조합 미검수 | 각각0.5~1일 |
| P2 | 기존6합동기 실전·엔딩 아카이브 진입, Steam 응답 누락 후 같은 실행의 재전송 회복 미확인 | 연결/검사0.5~1일 |
| P2/P3 | 곱 등 혼잡 이름표의 큰 상하 이동(기존 실측 −129~+172px), 몸/화면 가장자리 가림, 초상/HP바 취향 | 대표 혼잡 화면0.5일 |
| P3/WARN | 누비 바늘은 지정23인계서에서 독립 잔여 지적 문장을 찾지 못함. 별도 모든 스킬 포즈 시각 확인은 이번18화면으로 대체하지 않았으므로 확인 보류 | 관련 자세 확인1~2시간 |
| P2/P3 | 영어·중국어 원어민/연기 톤, 프롤로그 호흡·음원 청취, 일부 감정·배지·적 초상 대체 | 문구 규모/담당자에 따라 별도 |

임시 가격·환불50%·건설 상한 해석·목줄/명령/범위·스킬 기본값·식량 지급순서·이전 규칙·카메라/라벨 예외·그래픽 대체·구 저장 좌표 변경 등 나머지 가정은 [원문 색인](handoff_remainders.md)과 [분류표](handoff_review.md)에 모두 모았다. 과거 ‘미리보기 전용’, 도전과제 버튼 비활성, DAY29 전투 추가 대기는 STEP14/13 및 DAY29 복원으로 대체된 기록이므로 현재 결함으로 다시 계산하지 않는다.

기존 기능 추적 결과: 원정 일반 진입과 전투 변화 누락, 칙령 능력치 일부 누락, 전선 날짜/변형·심장 처리 누락, 의회 날짜/웨이브/목표 연결 불완전, 다음 회차 지도 세션 잔존, 전체 기록실/엔딩 아카이브 진입 누락. 몬스터별 기억과 합동기 편성·J/K/자동 발동 경로는 존재한다. 개별 전선/의회/엔딩 서비스 검사의 통과·실패는 [실행 색인](run_index.csv), 실제 새 경로의 코드 증거는 [독립 추적](regression_review.md)에 있다.

검수 완료 범위는 **부분**이다. 사용자 Esc 이후 Computer Use를 재개하지 않았다. EXE 새 게임/전투/저장, 추가 구 표시 검사10종(`V130RStep2C/D/E`, `Step4B/C/D/E`, `V130Placement/Decoration/PlotProjection`), 별도 `ux_final` 언어 버튼 재확인은 미실행이다. 전체 데이터 검증 스크립트를 모두 통과했다고 주장하지 않는다. 기존6합동기 추가 프레임 검사는 headless 렌더 대기에서 시간 초과했다. [사용자 중단/종료 기록](user_interruption.json).

보존·종료: 제품703파일/시험 원본5파일/사용자 원본5파일 해시 불변은 [검증표](integrity_final.json) 참조. 이 작업의 실행은 직렬로만 수행하며 다른 프로젝트 프로세스를 종료하지 않았다. 새 그래픽/외부 이미지 생성0. 빌드는 `tmp/release_audit_v130/export/`에만 생성했다. 캡처/로그/시험 세이브는 로컬 증거이며 공개 배포하지 않았다. 최종 프로세스/커밋 상태는 지정 인계서와 `final_state.json`에 기록한다.
'''
(P/'RELEASE_AUDIT.md').write_text(report,encoding='utf-8')
print('Wrote RELEASE_AUDIT.md',len(report),'characters; export_flow_saved=',export_ok)
