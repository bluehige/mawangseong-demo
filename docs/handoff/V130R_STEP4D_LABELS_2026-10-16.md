# V130R Step4D 이름표·가림 수정 — 사용자 확인 대기

## 1. 메타데이터

- 작성일: 2026-10-16 KST / WORKSTREAM_ID: V130R_STEP4D_LABELS
- 목표 버전: 1.3.0. 버전·출시 설정 변경 없음.
- 작업 브랜치: `codex/v130r-defense-layout`
- 기준 SHA: `4188da2a88e40cf82994c74ebc4324487c1cc56c` (사용자 지정0097).
- 마지막 커밋 SHA(구현·검증 대상): `545b8d84b637104ec472a49f1268cf2512ab3d67` / `Anchor battle labels to alpha heads and reveal occluded units`.
- 이후 변경은 이 인계와 CURRENT뿐이다. 마지막 문서 커밋/최종 HEAD는 `git log -1`로 확인한다.
- 원격 푸시: 없음. 원격 조회/fetch·push·merge·태그·Steam 조치 없음.
- 관련 PR/태그: 생성하지 않음.
- 권위 제한: 로컬 main 부재로 main:AGENTS/CURRENT를 읽을 수 없었다. 저장된 origin/main `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 두 문서를 읽었으나 원격 최신성은 확인하지 않았다. v1.2.5=`f757ffa9f9e962158f2123856c8568a3163ecb6c`. 이번 최신 사용자 지시와0097을 작업 기준으로 사용했다.

## 2. 이번 세션 목표

- 이름표·체력바를 현재 자세의 실제 알파 맨 위−6px에 연결한다. 0097 높이96월드px·large×1.15·boss×1.35·줌 비례 유지.
- 유닛 발 칸과 건물 벽·앞턱·문 아치의 공통 깊이 정렬, 앞 구조물 뒤로 가려진 몸에만 반투명 윤곽.
- 이름표끼리와 선택 스킬창 충돌 회피 유지. 유닛 X를 유지하며 위아래로 비키고 몸까지 연결선을 표시한다.
- 요청4장·거리 표·축소본 개별 확인, 인계 및 영어 로컬 커밋.
- 제외: 전투 수치·AI·웨이브·경제·스토리 변경, 사용자 세이브 읽기/쓰기, 전체 회귀/전체 플레이/별도 검수 에이전트/출시·export.

## 3. 완료한 작업

- **근본 원인:** `AtlasTexture.get_image()`는 잘라낸 그림만 반환하지만 실제 프레임은 `margin` 투명 여백을 포함한다. 기존 공통 외곽 코드가 여백 좌표를 누락해 발과 머리 계산이 실제 몸에서 벗어났다. bounds/외곽에 여백을 복원했다. 같은 공통 경로인 배치의 발 정렬도 함께 바로잡았고 몸 높이/배율은 유지했다.
- 현재 프레임의 알파>0 윤곽을 캐시하고 회전·반전·이동·공격 자세를 적용한다. 머리의 얇은 끝이 축소 화면에서 사라지는 경우를 위해 선형 보간(이웃 픽셀을 섞는 표시)의 화면 샘플과 8비트 알파를 계산해 실제 화면 맨 위를 추적한다. 초기 8~9px 차이는 수정 후 재실측했다.
- 충돌 전 HP 아래~몸 맨 위 목표6 화면px. 최종 **32개 실측6~7px**, 허용6±1.5px. 실제 HP·이름 합친 박스34 UI단위에 맞춰 충돌 사각형도 수정했다.
- 이름표 X는 자기 몸 중심 유지. 선택 우선·기존 위/아래 번갈아 탐색·선택 스킬창 회피를 유지한다. 충돌로 비켜난 경우만 기존 GPT 하이라이트 색조의 얇은 연결선을 표시한다. 살아 있는 유닛만 표시하고 쓰러지면 실루엣/연결선도 숨긴다. 줌/이동 때 매 프레임 갱신, 같은 화면 위치로 카메라가 따라가도 월드 좌표 캐시가 유효하게 바뀌는 것을 검증했다.
- 맵 조립기의 기존 건물 발/문 아치/시설 중심 깊이를 `Presentation.depth()`의 유닛 발Y와 같은 척도로 활성화한다. **활성화 시점은 전투 시작뿐**이어서 건설/배치의 강조 표시 순서는 유지한다.
- 실제 건물 그림 알파와 같은 깊이를 별도 정적 렌더로 저장한다. 몸보다 앞에 있는 구조물 픽셀에만 동일 자세 실루엣을 덧그린다. 함정은 실루엣 마스크에서 제외했다. 몸 전체를 무조건 최상위로 올리지 않는다. 기존 하이라이트의 민트(아군)/산호(적) 색조, 반투명 내부와 더 밝은 가장자리다.
- 스토리·데이터·밸런스·저장 스키마·그림 원본 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/map_builder/ApprovedActorPresentation.gd` | Atlas 투명 여백 복원·정확한 알파 외곽/픽셀 캐시 | 완료 |
| `scripts/map_builder/ApprovedTileAssembler.gd` | 건물/문 아치/함정 발 깊이 메타데이터 | 완료 |
| `scripts/map_builder/ApprovedBattleOcclusion.gd` | 전투에서 깊이 활성화·정적 건물 알파/깊이 렌더 | 완료 |
| `scripts/units/approved_battle_silhouette.gdshader` | 가려진 몸 부분만 기존 하이라이트 색조 반투명 윤곽 | 완료 |
| `scripts/units/ApprovedBattleUnit.gd` | 현재 자세·화면 알파 top−6px·발 깊이·실루엣/연결선 | 완료 |
| `scripts/ui/ApprovedBattleUI.gd` | 매 프레임 추적·X 고정 위아래 충돌 회피·선택 스킬창 회피 | 완료 |
| `scripts/game/ApprovedBattleController.gd` | 전투 시작 때 깊이/실루엣 연결 | 완료 |
| `tools/tests/V130RStep4DLabelsTest.gd` | 직접 검사·실제 E/F/가림·뒷벽 대조·알파 렌더 | 완료 |
| `tools/tests/V130RStep4DLabelsTest.tscn` | 격리 검증 씬 | 완료 |
| `tools/run_v130r_step4d.ps1` | Godot 최대1·개인 APPDATA 격리·오류/시간초과 자기 PID 종료 | 완료 |
| `tools/tests/v130r_step4d_capture_audit.py` | 실제 거리·가림 실측·UTF-8 외부 게시·기존 파일 해시 보존 | 완료 |
| `docs/handoff/V130R_STEP4D_LABELS_2026-10-16.md` | 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 현재 브랜치 진입 링크 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 신규 생성/호출·새 PNG·원본 수정·배경 제거·외부 생성 서비스·오디오 변경 없음. 기존 런타임 그림과 GPT 하이라이트 색조를 재사용했다. 새 SOURCE.md 대상 없음.
- 결과 폴더: `C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step4d_labels/`
- 요청 산출물: `battle_e_day7.png`, `battle_f_day3.png`, `label_check.png`, `occlusion_check.png`.
- `previews/`는 최대1000×600 축소본. **4장 각각 한 장씩 열어 검수했다.** 원본 전투/가림3장은 실제1920×1080 viewport, label_check는 실제 장면 위에 외곽·박스를 표시하고 원본px 거리 표를 붙인1920×1080 진단 그림이다.
- `distance_table.md`에 E/F·가림/뒷벽 대조32행의 충돌 전 간격/이동Y/표시 간격/실루엣 픽셀을 기록했다. `alpha/`, `silhouette/`, manifest/measurements JSON, direct/capture/scale_regression 결과와 capture_audit도 보관했다.
- E/F는14명 전원 시험 해금·자동 배치 후 원본 웨이브 첫 접촉(각 적1명, 총15개체)이다. 전체 웨이브 완주가 아니다. 가림/뒷벽 대조는 실제 길 칸에 푸딩1명만 보이도록 둔 일시정지 검수 배치다.
- 앞턱 뒤 길 칸(19,6): 유닛1120 < 앞턱1184. 실루엣2094px, 실제 몸 영역 켬/끔 차이2068px이며 변화는 가림 마스크 안에만 있다. 다른 곳의 기존 VFX는 몸 영역 비교에서 제외했다.
- 뒷벽 앞 길 칸(26,12): 뒷벽1024 < 유닛1088. 실루엣0px, 몸이 정상 표시됨.

## 6. 테스트 및 검수

| 명령/검증 | 결과 | 근거 |
|---|---|---|
| `tools/run_v130r_step4d.ps1 -Mode direct` | **1042 checks / 실패0 / stderr0bytes** | tmp/v130r_step4d/direct_result.json |
| 같은 실행기 `-Mode capture` | **384 checks / 실패0 / stderr0bytes** | capture_result.json |
| 기존 `tools/run_v130r_step4c.ps1 -Mode direct` | **949 checks / 실패0 / stderr0bytes** | tmp/v130r_step4c/direct_result.json; 외부 scale_regression_result.json |
| `python tools/tests/v130r_step4d_capture_audit.py` | **TARGETED_PASS: 32개 실측6~7px·전부화면내·가림/대조 PASS** | 외부 capture_audit.json·distance_table.md |
| Python AST·PowerShell parser·scoped/cached `git diff --check` | PASS | 명령 결과 |
| 요청4장 축소본 시각 확인 | 4/4, 한 장씩 확인 | 외부 previews/ |
| 전체 회귀·전체 플레이·별도 검수 에이전트·전체 FPS/장시간 성능·export | **NOT_REQUESTED / 미실행** | 이번 표적 범위 밖 |

직접 검사는 Atlas 여백 좌표, 비어 있지 않은 살아 있는 자세·줌0.5/0.75/1, 발 깊이145개 맵 조각, 건설 순서 보존, 이름표 모든 쌍 비겹침, 선택창 회피, 카메라 추적 캐시를 포함한다. 기존949개는 배치와 전투의 몸 높이·현재 등록 자세 전체 높이 범위·알파 발·대형/보스·효과/스킬 비례를 확인했다.

추가 표적 CPU 측정은 같은 직접 테스트에서 **14명 모두 이동·40회 이름표 배치 평균1.475275ms/P95 2.25ms**였다. 전체 게임 FPS/전후 성능 비교나 지속60fps 보장을 뜻하지 않는다.

초기 가림 칸 검색 조건, Atlas 여백/얇은 머리 끝 샘플링, 카메라 추적 캐시, 빈 기본 애니메이션 및 자료형 오류는 같은 작업흐름에서 수정했다. 최종 결과와 로그에는 실패/스크립트 오류가 없다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 545b8d84b637104ec472a49f1268cf2512ab3d67
- Review range: 4188da2a88e40cf82994c74ebc4324487c1cc56c..545b8d84b637104ec472a49f1268cf2512ab3d67
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- **사용자 확인 대기:** 시각적 취향과 혼잡 시 위/아래 비킴 배치. 실제 검사 장면의 충돌 이동Y는 약−129~+172px다. 충돌 전6px 규칙과 충돌 후 비킴을 구분하며, 비켜난 박스는 연결선으로 누구 것인지 표시한다. 모든 이름표를 항상6px에 두면서 겹치지 않게 만드는 것은 아니다.
- 겹치는 유닛 몸, 화면 가장자리·HUD에 의해 일부가 보이지 않는 것은 이번에 전면 금지하지 않았다. 요청 장면32개 검수용 몸 마스크는 화면내였다. 다른 시점/모든 보스 조합/모든 기기·해상도/개인 캠페인 완주는 검수하지 않았다.
- 기존 셀 조각의 발/문 아치 기준을 쓰는2D 깊이 정렬이다. 건물 그림 자체를 새로 분할하거나3D 지형으로 바꾸지 않았다.
- 로컬 main 부재·원격 최신 권위 미확정 유지.

## 8. 다음 작업 순서

1. 사용자: `_mockup/game_step4d_labels/previews/` 요청4장 및 `distance_table.md` 확인. **사용자 확인 대기.**
2. 추가 시각 지시가 있으면 관련 표시 경로와 표적 실측만 수정·재검증한다.
3. push·merge·태그·Steam은 이번에 허용되지 않았으므로 진행하지 않는다.

## 9. 작업 트리 상태

- 기존 혼합 변경 **1394파일 SHA256 불변**, .import/.uid·docs/design/v131_layout 등 기존 변경은 커밋에서 제외했다. 기존 변경 되돌리기·stash·브랜치 전환 없음.
- 의도한 구현/도구11경로와 문서2경로만 명시적으로 스테이징했다. `git add -A` 미사용.
- 사용자 개인 세이브 접근/수정 없음. APPDATA/LOCALAPPDATA는 ignored tmp에 격리했다. 앞 단계 시험 JSON3개도 실행 전후 바이트 일치를 확인했다.
- Godot 시작0·동시최대1·최종0. 기존 Godot 감지 시 실행 거절, 오류 때 자기 PID만 종료했다.
- 빌드/캡처/로그/투명 보조 렌더는 ignored `tmp/v130r_step4d/`와 외부 `_mockup/game_step4d_labels/`에만 둔다. 그림/빌드 산출물은 소스 커밋에 넣지 않았다.
- 원격 푸시·merge·태그·Steam 없음. 영어 로컬 구현 커밋 후 인계/CURRENT 문서 커밋만 남긴다.

## 10. 종료 체크리스트

- [x] 구현과 요청 범위 대조·관련 테스트 통과
- [x] 실제 E/F·알파 거리·앞턱/뒷벽 대조 확인
- [x] 요청 축소본4장 한 장씩 확인
- [x] 검수 최종 코드 SHA·범위·미실행 전체 검수 기록
- [x] 기존 변경/개인 세이브 보존·Godot 종료0
- [x] CURRENT 진입 링크 갱신·의도한 파일만 영어 로컬 커밋
- [x] push/merge/태그/Steam 금지 유지·사용자 확인 대기
