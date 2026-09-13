# UIUX V2 남은 메뉴·후반 캐릭터 구현 및 직접 검증

## 1. 메타데이터

- 작성일: 2026-09-13
- WORKSTREAM_ID: UIUX-V2-COMPLETION-20260913
- 목표 버전: 공개 1.2.6 기반 UIUX V2 개선. 새 제품 버전·출시 미확정.
- 작업 브랜치: `codex/v126-uiux-u0-u3`
- 작업트리: `C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2`
- 기준 main / origin/main / 확인한 원격 main: `69a75970b1f8c030aa3a6956e5ca0f5bf15b2112`
- 세션 시작 HEAD: `f38029c7d406577ca55e97c2a9bedf0e4f7cb607` (깨끗한 작업트리)
- 마지막 구현 커밋 SHA: d446057c5c0e27d947c41a527ab740f80d879968
- 원격 푸시 여부: 미푸시. 로컬 구현 커밋 뒤 핸드오프 문서만 별도 커밋.
- 관련 PR 또는 태그: 이번 작업에서는 생성하지 않음.
- Godot: 4.6.3 stable / Windows / Vulkan Forward+ / RTX 3060 Ti.

착수 시 작업트리·브랜치·HEAD·main·origin/main과 `main:AGENTS.md`, `main:docs/handoff/CURRENT.md`를 확인했다. AGENTS의 오래된 1.2.5 문구보다 최신 사용자 지시와 권위 CURRENT의 공개 1.2.6을 적용했다. 과거 v20 실험 브랜치·출시 태그·제품 main은 변경하지 않았다.

## 2. 이번 세션 목표

사용자의 “일단 그거 다 마무리하고 나서 다시 보고하자”에 따라 직전 CURRENT의 남은 이름 입력·회상·연대기·상층·전초기지 UI와 후반 전투 그림 연결을 하나의 작업으로 완료했다. 사용자의 지시대로 새 서브에이전트 없이 주 에이전트가 직접 구현·화면 확인·검사를 수행했다.

앞선 U0~U5의 실제 건물 카드→드래그→고스트→검토→확정/취소→기존 Undo, 편성/전술 도구함, 시설 단계·방향 그림을 보존하며 관련 검사를 다시 실행했다. 외형만 변경/레이아웃 유지라는 구 문서의 일괄 제한은 적용하지 않았다.

사용자 지정 원본은 [Game UI Database 729](https://www.gameuidatabase.com/gameData.php?id=729), **Curse of the Dead Gods**다. 2026-09-12 실제 확인 기록의 `REFERENCE_VERIFIED`를 계승하며 다른 게임을 같은 원본으로 취급하지 않는다. 공통 판석·금색 상태 표현을 실제 화면에 적용했다.

전체 DAY 1~30, 모든 분기, 사람 사용성 시험, 다른 플랫폼, 8인 검수, 공개 배포·태그는 이번 실행 범위에서 제외했다.

## 3. 완료한 작업

- **이름 입력:** 바티의 큰 초상과 반응, 이름 양식, 1~12자 안내를 분리했다. 빈 입력/긴 입력 이유, 무작위 이름, Enter·Tab, 기존 안내 닫기 이력과 한글 입력 경로를 유지했다. 이전 화면의 중복 확정 호출은 무시한다.
- **회상:** 현재 동료 초상·유대, 기억 목록, 선택한 전문을 나눴다. 긴 본문과 이전 회차 기억을 스크롤로 모두 읽을 수 있고 키보드 선택이 보이는 곳으로 이동한다. 읽기 동작은 성장/저장 데이터를 만들거나 바꾸지 않는다.
- **연대기:** 세 기록 묶음과 설정 탭, 각 묶음의 목차 및 본문으로 재편했다. 기존 기록 내용을 유지하고 세이브 스키마 설명이나 내부 ID 대신 실제 이름을 표시한다. 체크박스·층 전환 키·음량은 기존 저장 콜백을 사용한다.
- **상층:** 세 배치 후보의 목록, 실제 모듈 4개 그림과 연결선, 장단점, 하단 확정을 제공한다. 후보 조회·닫기는 상태를 변경하지 않는다. 기존 서비스가 확정하며 확정된 회차 배치는 다른 후보를 읽어도 바뀌지 않는다.
- **전초기지 방어:** 기존 전초기지의 현재 단계 그림, 진입 경로, 깃발 체력, 경과 시간, 파견 동료 얼굴/이름, 움직이는 침입자와 실제 결과를 연결했다. 기존 EncounterService의 자동 전투·재도전·결산 규칙을 사용하고 중복 결산을 막는다.
- **전투/성장:** 전투 정보창이 16포즈 시트 전체를 표시하던 문제를 고쳤다. 아군은 현재 큰 초상, 적은 실제 유닛의 단일 프레임을 표시한다. 지도/전투 이름은 기존 동료 이름과 일치한다. 긴 역할 설명과 공격·방어 수치를 분리하고 기존 소형 정보창 크기를 유지했다. 큰 글자에서 성장 역할·기술 설명이 잘리던 높이를 늘렸다.
- **포커스:** 타이틀/결과가 다른 화면으로 전환된 뒤 사라진 버튼에 포커스를 주던 문제를 처리했다. 화면에 실제 남아 있는 버튼만 포커스를 받는다.
- **데이터/스토리/밸런스:** 게임 데이터 10개 파일의 변경은 기존 이미지 경로에 한정한다. 키/배열 순서·길이·나머지 값과 기존 체격 프로필을 비교했다. 비용·해금·AI·수치·성장·보상·스토리·방 연결·저장 형식은 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/ui/NameEntryUI.gd`, `MemoryArchiveUI.gd` 및 UID | 실제 이름 입력/회상 화면 | 완료 |
| `scenes/ui/screens/ChronicleScreen.gd`, `UpperFloorScreen.gd` | 기록 목차/설정 및 상층 조회/확정 | 완료 |
| `scenes/outpost/OutpostBattleRoot.gd` | 현재 전초 그림·수비대·침입자·결산 표시 | 완료 |
| `scripts/game/GameRoot.gd`, `ManagementSceneController.gd` | 활성 호출 연결, 현재 초상/이름 | 완료 |
| `scripts/ui/HUDController.gd`, `ManagementWorkspaceUI.gd`, `MonsterWorkspaceUI.gd`, `TitleWorkspaceUI.gd`, `ResultWorkspaceUI.gd` | 단일 전투 포즈, 글자 경계, 포커스 | 완료 |
| `data/characters.json`, `monsters.json`, `enemies.json`, `evolution_rules.json`, update3/update4 관련 표 | 기존 캐릭터 이미지 경로 | 완료 |
| `data/uiux_actor_art.json`, `data/v122/combat_visual_profiles.json` | 실제 프레임 영역/여백/몸체 표시 크기 | 완료 |
| `assets/sprites/uiux3d/`, `assets/sprites/portraits/uiux3d/` | 새 최종 PNG 59장과 import | 완료 |
| `assets/source/imagegen/uiux_completion_20260913/` | 원본 59장·SOURCE·.gdignore | 완료 |
| `tools/UIUXCompletionScreensTest.*`, `UIUXCompletionArtTest.*` | 실제 메뉴/현재 형태/전투 경로 검사 | 완료 |
| `tools/fixtures/uiux_completion_actor_inventory.json` | 확인 대상 47개 ID 고정 목록 | 완료 |
| `tools/tests/UIUXCompletionArtPixelsTest.py`, `UIUXCompletionDataCompatibilityTest.py` | 투명도/원본/프레임 및 데이터 보존 | 완료 |
| `tools/measure_uiux_actor_art.py` | 투명 간격과 비대칭 프레임 영역의 읽기 전용 측정 | 완료 |
| 기존 Onboarding/UIUXActor/Chronicle/Accessibility/WorldArt 관련 테스트 | 바뀐 실제 UI와 필수 성장 선택 경로에 맞춘 검사 | 완료 |

이번 구현의 정확한 221개 경로는 구현 커밋의 `git show --name-status`로 확인한다. 로컬 `tmp/uiux_completion_20260913/commit_paths.json`에도 명시 목록을 남겼다. `tmp/`, 캡처, 빌드 및 실행 파일은 커밋하지 않았다.

## 5. 그래픽 및 오디오 자산

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6
- [원본·프롬프트·생성 결과·SHA-256·런타임 경로](../../assets/source/imagegen/uiux_completion_20260913/SOURCE.md)
- 전투 대상 47개 ID: 적 29개, 동료 6개, 진화/왕관 형태 12개. 적 2개 별칭이 기존 대응 인물의 시트를 공유하여 새 시트는 **45장**이다.
- 큰 대화 초상 **14장**: 로로 4감정, 바티 4감정, 마왕 6감정. 기존 실키·포포·진화·왕관·경쟁 마왕의 큰 초상은 보존하고 현재 형태와 연결을 확인했다.
- 새 채택 파일은 총 **59장**, 런타임 PNG 합계 **116.74 MiB**다. 생성 원본과 런타임은 바이트가 같다. 큰 원본을 작은 PNG로 다시 저장하지 않고 lossless import와 mipmap을 사용한다. 최종 export 용량은 이번에 측정하지 않았다.
- GPT 내부 생성 프롬프트에 실제 투명 PNG를 명시했다. 일부 RGB 체크무늬 후보와 실패 편집은 미채택하고 내부 생성기로 다시 만들어 실제 RGBA만 채택했다. 로컬 배경 제거·색 변환·리사이즈·픽셀 크롭은 하지 않았다.
- 4×4 포즈의 투명 간격을 측정해 AtlasTexture의 영역/여백을 지정한다. 384 논리 프레임, 발 기준과 기존 체격·부유 프로필을 보존한다. 시트 픽셀의 불균일한 간격 때문에 외투·무기가 잘리던 문제는 표시 영역과 중심 여백으로 해결했다.
- 오디오 생성·음원 변경 없음. 온보딩 검사 종료 때 기존 오디오 종료 함수와 짧은 정리를 사용하여 테스트 종료 누수를 없앴다.

전초기지 Encounter 데이터에는 적 종족 ID가 없으므로 침입자는 기존 탐험가 그림을 공통 외형으로 사용한다. 이를 실제 탐험가 유닛/능력치나 새로운 전투 규칙으로 해석하지 않는다.

## 6. 테스트 및 검수

Windows 실제 Godot 창에서 **1920×1080 / 1280×720 × 글자 90/100/115%**를 확인했다. 관련 기존 검사의 1366×768 확인은 별도 표에 포함한다. 테스트는 독립 APPDATA를 사용하며 통제한 저장/해금 fixture를 실제 전체 캠페인 완주로 기록하지 않는다.

| 검사 | 최종 결과 | 로그 (`tmp/` 아래) |
|---|---|---|
| UIUXCompletionScreensTest | PASS · 588개 · 114캡처 | `uiux_completion_screens_final.log` |
| UIUXCompletionArtTest | PASS · 9,865개 · 582캡처 | `uiux_completion_art_final3.log` |
| 같은 테스트 `--inspector-only`, 최종 정보 행/겹침/글자 | PASS · 6,523개 · 204캡처 | `uiux_completion_inspector_verified.log` |
| UIUXCompletionArtPixelsTest.py | PASS · 4,224개 | `uiux_completion_pixels_final2.log` |
| UIUXCompletionDataCompatibilityTest.py | PASS · 2,440개 비교 | `uiux_completion_data_final.log` |
| UIUXBuildPlacementTest | PASS · 343개 | `uiux_completion_final_UIUXBuildPlacementTest.log` |
| UIUXRosterStateTest | PASS · 695개 · 45캡처 | `uiux_completion_final_UIUXRosterStateTest.log` |
| UIUXSecondaryInteractionTest | PASS · 3,284개 | `uiux_completion_final_UIUXSecondaryInteractionTest.log` |
| UIUXCombatInteractionTest | PASS · 210개 | `uiux_completion_final_UIUXCombatInteractionTest.log` |
| UIUXActorArtTest | PASS · 590개 | `uiux_completion_final_UIUXActorArtTest.log` |
| UIUXPortraitArtTest | PASS · 2,314개 · 138캡처 | `uiux_completion_final_UIUXPortraitArtTest.log` |
| UIUXU4InteractionTest | PASS · 517개 | `uiux_completion_u4_final.log` |
| OnboardingFlowSmokeTest | PASS · 57개 출력 확인 | `uiux_completion_onboarding_cleanup.log` |
| ChroniclePhase26Test | PASS · 37개 | `uiux_completion_chronicle.log` |
| Update4ChronicleAccessibilityPhase35Test | PASS · 27개 | `uiux_completion_accessibility.log` |
| Update4WorldArtPhase34Test | PASS · 64개 | `uiux_completion_worldart.log` |
| OutpostBattlePhase8Test | PASS · 18개 | `uiux_completion_outpost.log` |
| MultiFloorHudPhase12Test | PASS · 23개 | `uiux_completion_multifloor.log` |
| V122CombatUISimplificationTest | PASS · 93개 | `uiux_completion_combat_contract_final.log` |
| `git diff --check` | PASS | 추가 공백 오류 없음 |
| 저장소 정책 | PASS · 631개 최종 경로 / 31커밋 (문서 HEAD `28a2188` 기준) | `uiux_completion_repository_policy.log` |
| 전체 회귀 / 전체 DAY 1~30 / 사람 사용성 / 8인 / Web·모바일 | NOT_REQUESTED / NOT_RUN | 이번 완료 판정에 포함하지 않음 |

실행 명령: `Godot_v4.6.3-stable_win64_console.exe --path . --resolution 1920x1080 --scene res://tools/<테스트>.tscn --log-file tmp/<로그>`. 세부 phase 검사는 `res://tools/tests/` 경로를 사용한다. 픽셀/데이터 검사는 제공 Python으로 `tools/tests/<검사>.py`를 실행했다. 화면 검사에는 headless를 사용하지 않았고 온보딩/구조 계약 등 비화면 검사는 headless로 실행했다.

### V2 직접 테스트 표와 연결

| V2 항목 | 이번 최종 확인 |
|---|---|
| B01–B03 | 실제 카드 드래그·가시 고스트·드롭 검토·확정, 미확정 상태 비교, 중복 클릭/Enter 한 번 반영 — BuildPlacement |
| B04–B06 | 비용/해금/고유 시설 거부, UI·밖·고정 방 드롭, 취소·ESC·전환·포커스 상실 무비용 — BuildPlacement |
| B07–B09 | 클릭·키보드 대안, 기존 Undo, 줌/이동/배율 좌표 일치 — BuildPlacement 및 RosterState |
| B10–B12 | 고정 방·기존 교체/경로 판정, 후기 성 단계 그림, 미확정 방어 시작 방지 — BuildPlacement |
| M01 | 동료 실제 출전/예비/지원 구분·배치·Undo·고정 튜토리얼 제한 — RosterState 및 BuildPlacement |
| C01–C02 | 핵심 전투 명령 3개와 시설 가동 분리, 실제 대상 입력, 거부 이유, 대화/정지/속도 — CombatInteraction 및 CombatUISimplification |
| R01 | 실제 기록 기반 결과 모델, 성장 선택 한 번 적용·보상 중복 방지·이전 화면 콜백 거부 — U4Interaction 및 Onboarding |
| T01 | 기존 새 Control/안내 ID와 건설 완료 조건, DAY 1~4 통제 전투에서 DAY 5 저장 진입 — Onboarding 및 BuildPlacement |

온보딩은 기존 검사처럼 전투 결과를 강제로 진행시키는 통제 실행이다. 전체 적을 실제로 이겨 DAY 5까지 사람이 플레이했다는 뜻이 아니다. 아트 검사의 29적 생성도 기존 `_spawn_enemy`에 한 명씩 넣은 통제 경로이며 DAY 25/30 완주가 아니다. 로로는 실제 지원/출격용 경로로 검사하고 지원 전용 동료를 일반 성장 대상으로 꾸미지 않았다.

초기 검사에서 긴 성장 역할/기술 잘림, 전투 정보의 시트 전체 표시/수치 잘림, 화면 전환 뒤 포커스 문제를 고쳤다. 생성 실패 후보, 테스트 helper 누락, 지원 동료/동시 카운터 적 제한을 잘못 설정한 초기 fixture, 잘못된 정보 행 위치는 수정했다. 위 표의 최종 로그만 완료 근거이며 초기 실패 로그도 로컬에 보존한다. 검사 9,865개 이후 바뀐 전투 정보 행은 별도 최종 6,523개 검증과 화면으로 보완했다.

### 증거

- [전후 비교·실제 건설 조작·현재 게임 화면 인덱스](../../tmp/uiux_completion_20260913/index.html)
- 이름/회상/연대기/상층/전초기지: `tmp/uiux_completion_20260913/before/` 66장, `after/` 114장. 같은 상태 전후 66쌍.
- 전투 그림: `tmp/uiux_completion_art_20260913/before/` 96장, `after/` 582장. 인덱스는 24개 대표 전후쌍을 포함한다. 포즈 모음은 몸체 높이를 증거용으로 확대했고 실제 지도 크기는 별도 게임 화면에서 확인했다.
- 최종 전투 정보: `tmp/uiux_completion_art_20260913/inspector/` 204장.
- 실제 건설 입력: `tmp/uiux_completion_20260913/building/02_building_cards.png` → `03_drag_valid.png` → `04_review.png` → `05_built.png` → `06_undo.png`, 취소 `07_cancel.png`, 불가/후기/줌 및 글자 배율 캡처.
- [이전 수비대 배치·Undo·방어 시작과 전후 증거](../../tmp/uiux_roster_state_20260913/index.html)

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: d446057c5c0e27d947c41a527ab740f80d879968
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..d446057c5c0e27d947c41a527ab740f80d879968
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

저장소 정책 실행 명령은 `tools/ci/ValidateRepositoryPolicy.ps1 -BaseRef main`이며 exit 0을 확인했다. 이 정책 결과 기록은 인계 문서만 추가 변경한다.

별도 검수 에이전트 반복 기록은 NOT_REQUESTED다. 위 SHA의 관련 검사만 통과이며 이후에는 `docs/handoff/` 문서만 변경한다.

## 7. 미해결 항목과 위험

- 이번 남은 5개 메뉴 및 목록에 고정한 47개 전투 ID/14초상 연결에서 확인된 필수 기능 실패는 없다.
- 모든 배경·벽·조명과 기존 NPC 초상을 새로 그린 것은 아니다. 기존 실키/포포/왕관/경쟁 마왕 초상은 현재 형태 연결을 검증하여 유지했다. 동작 사이 소품/재질의 미세한 일관성과 배경까지 포함한 최종 미술 취향은 사람 평가를 하지 않았다.
- 실제 유효 SW 건설 슬롯이 없는 방향은 앞선 자산 검사와 동일하게 자산 연결 범위다. 없는 SW 슬롯을 만들거나 설치 성공을 주장하지 않는다.
- 신규 원본 보존으로 자산량이 늘었다. 런타임 PNG 크기만 측정했으며 최종 export 크기·장시간 프레임 시간·모든 후반 인원이 겹친 조건의 성능은 이번에 측정하지 않았다.
- 전체 캠페인/모든 저장 파일/다른 플랫폼의 무결함 판정이 아니다. 현재 관련 검사 범위를 넘어선 PASS는 하지 않는다.

## 8. 다음 작업 순서

1. 이번 구현·미술 연결 묶음은 종료한다. 새 서브에이전트나 추가 미세 패킷을 자동으로 열지 않는다.
2. 전후/조작 증거를 기준으로 사용자의 실제 화면 피드백을 받으면 지적된 화면·자산만 보완한다. 피드백 없이는 새 동작·콘텐츠·시스템을 만들지 않는다.
3. 테스트 빌드 게시 또는 제품 통합/출시를 새로 요청받으면 그 범위의 절차를 적용한다. 현재 main·공개 URL·태그는 그대로다.

## 9. 작업 트리 상태

- 기존 변경 없음에서 시작했고 이번 목표에 속하는 파일만 명시 스테이징했다. `git add -A`를 사용하지 않았다.
- 구현 221개 경로를 로컬 커밋한 뒤 현재 문서/CURRENT/미술 범위 문서만 별도 커밋한다.
- 루트 작업트리 및 다른 브랜치 파일을 되돌리거나 섞지 않았다. 스태시·이력 재작성 없음.
- 로컬 캡처/도구 출력: 이 작업트리의 `tmp/uiux_completion*` 아래. 테스트별 사용자 저장은 별도 APPDATA 아래.
- 원격 미푸시. PR·새 버전·태그·Release·Web/Windows export·공개 배포 없음.

## 10. 종료 체크리스트

- [x] 남은 메뉴·후반 그림·활성 호출 연결과 요구사항 대조
- [x] 관련 테스트와 Windows 두 해상도/세 글자 배율 확인
- [x] 새 그림의 실제 투명도·프레임 경계·원본/런타임 일치 및 출처 기록
- [x] 데이터/체격·기존 건설/편성/전투/결과 규칙 직접 확인
- [x] 실패 수정과 최종 로그/전후 및 조작 증거 기록
- [x] 전체 회귀/사람/8인/플랫폼/출시 미실시를 구분
- [x] Reviewed SHA 및 CURRENT/미술 범위 문서 갱신
- [x] 의도한 파일만 로컬 커밋, 원격 미푸시
