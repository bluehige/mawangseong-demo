# 성장형 고정 미궁 구현 — 2026-09-13

## 1. 메타데이터

- WORKSTREAM_ID: UIUX-V2-PREPARED-MAZE-20260913
- 작성일: 2026-09-13
- 목표 버전: 공개 1.2.6 기반 UI·UX 작업본. 새 제품 버전 미확정, 미출시.
- 작업 브랜치: `codex/v126-uiux-u0-u3`
- 기준 main / origin/main / 세션에서 확인한 원격 main: `69a75970b1f8c030aa3a6956e5ca0f5bf15b2112`
- 착수 HEAD: `3d73416590285ccbf81c39a303dd6120f5d8a695`
- 마지막 구현 커밋 / 검수 대상: `484482408f07a89fd89a980a75dafe45ee1040ba`
- 엔진·플랫폼: Godot 4.6.3 / Windows Vulkan / RTX 3060 Ti
- 원격 푸시·PR·제품 통합·배포·태그: 없음. 과거 v20 참고선·출시 태그 불변.
- 권위 main:AGENTS.md / main:docs/handoff/CURRENT.md 확인. 오래된 AGENTS 1.2.5 문구 대신 최신 사용자 지시와 CURRENT의 공개 1.2.6을 적용했다.

## 2. 이번 세션 목표

사용자와 grill-me로 확정한 8개 결정을 실제 미궁으로 연결한다. 준비된 고정 미로, 성장별 확장, 적 목표별 경로 예고, 방 안 시설 구역, 사선 실내 단면·낮은 앞벽·문/아치, 초반 한 진입구에서 후반 두 주요 진입구, 기존 비용·해금의 수비대 전용 샛문을 구현한다. 새 갈림길·우회로는 사용자가 명시적으로 허용한 범위다.

이전 사각형 시설 경고·큰 상태 덮개 개선은 [이전 핸드오프](UIUX_V2_MAP_ANNOTATIONS_2026-09-13.md)의 구현을 그대로 이어간다. 지정 Game UI Database 729는 그 기록의 REFERENCE_VERIFIED(2026-09-12)를 계승하며 다른 작품을 같은 원본으로 대체하지 않았다.

주 에이전트가 직접 구현·검증했다. 서브에이전트·전체 DAY 1~30·8인 검수·공개 배포는 실행하지 않았다.

## 3. 완료한 작업

- 새 게임 기본 레이아웃을 성장형 고정 미궁으로 연결했다. 네 성장 단계에서 기존 방 위치가 유지되고 추가 구역·측문·우회 연결이 열린다.
- 실제 소켓 연결과 보행 타일을 같은 구조로 작성했다. 측문 적이 정문으로 되돌아가던 초기 최단 경로를 수정해 측면 합류 회랑을 통과하게 했다.
- 전술 화면에서 현재 침입 계획의 진입구·목표·적 이름·인원별 예상 경로를 선택한다. 실제 타일 경로를 그리며 메뉴·키보드 변경과 표시 경로가 일치한다.
- 몬스터 카드 드래그 또는 Enter→길목 클릭이 기존 수비 구역 필드에 반영된다. 시설 소속은 보존하고, 실제 전투 위치와 준비 화면 위치를 같은 계획으로 계산한다.
- 수비 구역 직접 배치와 시설 단축 배치에 기존 정원을 적용한다. 중복 입력은 이전 Undo를 보존한다.
- 기존 연결로를 수비대 전용 샛문으로 표시했다. DAY 3 / 금화 1,000 / 마력 100, 아군 전용 경로와 기존 Undo를 유지한다. 적의 공용 보행 지형은 바뀌지 않는다.
- 기존 시설 카드→고스트→드롭 후보→검토→확정/취소→Undo 및 후반 슬롯을 실제 새 지도에서 검사했다.
- 평소 전술 상세창을 닫아 지도를 확보하고, 방 선택과 튜토리얼의 필수 방 지침에서는 해당 상세창을 연다.
- 기존 낮은 앞가림 벽 자산·밝기 조정·실제 연결부 열린 아치로 실내 통로를 읽기 쉽게 했다. 드래그 이름과 길목 이름표 겹침도 줄였다.
- 저장: 새 미궁 저장·기존 출시 지도 저장을 각각 복원한다. 1.2.6 이전 마이그레이션은 기존 출시 지도로 이어지며 새 미궁으로 강제 이동하지 않는다. 사용자 지도·마이그레이션 실패 시 원본 유지도 기존 검사로 확인했다.
- 데이터/밸런스: 기존 파동 카탈로그 별칭으로 DAY 1~5 적 수·수치 보존. 시설·성장·보상·스토리 수치 변경 없음. 동선 변경에 따른 난도 변화는 별도 관찰 대상이다.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| `scripts/core/DataRegistry.gd` | 새 기본 지도·옛 지도 병행 등록, 파동 별칭, 성장 topology 반영 | 완료 |
| `scripts/game/GameRoot.gd` | 실제 경로 예고, 수비대 배치·정원·Undo, 저장 목적지 보존, 필수 튜토리얼 상세창 | 완료 |
| `scripts/ui/ManagementWorkspaceUI.gd` | 전술 경로 선택, 지도 중심 도구함, 샛문 안내 | 완료 |
| `scripts/map/DungeonRenderer.gd` | 실제 수비 위치의 준비 화면 표시 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 낮은 앞벽·바닥·2방향 연결 아치 | 완료 |
| `data/dungeon_quarter/layouts/prepared_maze_growth_01.json` | 네 단계 고정 미궁·시설/수비 구역·소켓 계약 | 완료 |
| `data/dungeon_quarter/prepared_maze_blueprints.json` | 기존 자산을 사용하는 꺾임 회랑 2종 | 완료 |
| `tools/BuildPreparedMazeLayout.py` | 정적 지도 제작 재현 도구 | 완료 |
| `tools/UIUXPreparedMazeTest.gd`, `.gd.uid`, `.tscn` | 실제 미궁·입력·저장·화면 검사 | 완료 |
| `tools/UIUXBuildPlacementTest.gd` | 선택 후 상세창 여는 흐름 검사 | 완료 |
| `tools/tests/V122DualFrontDefaultActivationTest.gd` | 새 기본 지도와 기존 마이그레이션 목적지 구분 | 완료 |
| `assets/dungeon_quarter/prepared_maze/open_arch_atlas.png`, `.png.import` | 실제 투명 열린 아치·밉맵 | 완료 |
| `assets/source/imagegen/prepared_maze_arch_20260913/` | GPT 생성 원본·SOURCE 기록 | 완료 |
| `docs/design/UIUX_PREPARED_MAZE_2026-09-13.md` | 인터뷰 8개 결정·구현/호환 경계 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성: 사용. `GPT internal image generation`.
- 원본: `assets/source/imagegen/prepared_maze_arch_20260913/open_arch_atlas_source.png`
- 출처: `assets/source/imagegen/prepared_maze_arch_20260913/SOURCE.md`
- 런타임: `assets/dungeon_quarter/prepared_maze/open_arch_atlas.png`
- 실제 RGBA 1774×887 / 994,946 bytes / alpha 0..255. 두 파일 byte 일치.
- SHA256: `5d2c49fbfe627f2f8124562c961fc38be3b940a90b6ff906bea592d8ebbd8ee9`
- 생성기가 만든 실제 투명 배경·문 내부를 그대로 사용했다. 배경 제거·리사이즈·로컬 픽셀 편집 없음. Godot AtlasTexture 두 구역·균등 배율·선형 밉맵을 사용한다.
- 실제 네 성 단계에서 아치 렌더를 확인했다. 오디오 변경 없음.

## 6. 테스트 및 검수

아래 최종 로그는 모두 이 작업트리 `tmp/`에 있다. 별도 APPDATA를 사용해 사용자 저장을 건드리지 않았다.

| 방법 | 결과 | 최종 근거 |
|---|---|---|
| `UIUXPreparedMazeTest.tscn`, Windows 네 성장 단계·두 해상도·세 글자 배율 | PASS · 19,219 assertions / 고유 캡처 98장 | `tmp/uiux_maze_complete.log`, `tmp/uiux_prepared_maze_20260913/after/results.json` |
| `UIUXBuildPlacementTest.tscn`, 실제 시설 드래그/검토/확정/취소/Undo, 모든 유효 시설·후반 슬롯 | PASS · 344 checks | `tmp/uiux_maze_build_final.log`, `build_verification/` |
| `UIUXCombatInteractionTest.tscn`, 실제 시작·상시 3명령·별도 시설 가동·일시정지·배속·대화 복귀 | PASS · 210 assertions / 24장 | `tmp/uiux_maze_combat.log`, `combat_verification/` |
| `V122DualFrontDefaultActivationTest.tscn`, 기존 저장·사용자 지도·실패 복구 | PASS | `tmp/maze_V122DualFrontDefaultActivationTest.log` |
| `V122DefenderConnectorTest.tscn`, 옛 지도 아군 연결로 계약 | PASS | `tmp/maze_V122DefenderConnectorTest.log` |
| `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `tmp/maze_V122FacilityZoneCombatConsumerTest.log` |
| `V122FacilityZoneEffectResolverTest.tscn` | PASS | `tmp/maze_V122FacilityZoneEffectResolverTest.log` |
| 정적 JSON 제작 도구 재실행 SHA 일치 / 실제 원본 alpha·파일 일치 / `git diff --check` | PASS | 실행 출력 및 위 이미지 SHA |
| 저장소 정책 | 아래 최종 기록 참조 | `tmp/uiux_maze_repository_policy.log` |
| 전체 회귀·전체 캠페인·8인·사람 사용성·다른 플랫폼 | NOT_REQUESTED / 미실시 | 현재 범위 밖 |

Windows 1920×1080 / 1280×720, 기존 글자 90/100/115%. 미궁 화면 비교는 **DAY 2 침입 계획을 네 성장 단계에 적용한 검사 자료**다. 저장 왕복에는 실제 단계에 맞는 DAY 2/16/21/28과 기존 성장 플래그를 사용했다. 캠페인을 그 날짜까지 모두 플레이한 결과가 아니다.

물리 보행 검사는 각 방까지 실제 타일 경로 존재, 벽 통과·타일 점프 없음, 열린 소켓 이용, 목표 도착을 확인했다. 실제 몬스터/적 객체를 생성해 준비 위치·진입구·목표를 대조했고 아군/적의 런타임 경로 함수로 샛문 통과 여부를 검사했다. 전체 전투를 끝까지 재생해 모든 적의 동선을 관찰한 것은 아니다.

초기 실패는 보존했다. 지도 초기 측문→정문 회귀 경로, 일반 전술 진입 후 상세창을 당연히 열려 있다고 가정한 기존 검사, 튜토리얼 필수 상세창 보장이 없던 부분을 수정했다. 검사 자료의 이름·시설 초기화·성장 이력·저장 날짜 조건, native 팝업 입력 window ID, 실제 포인터 위치 및 경로별 고유 캡처 파일명을 교정했다. 이전 신호 모의 입력이 경로 캡션만 바꾸던 캡처는 최종 증거에 포함하지 않는다. 최종 메뉴는 실제 팝업 창의 키 입력까지 통과했다.

- 전후 8쌍 + 실제 조작 비교: `tmp/uiux_prepared_maze_20260913/index.html`
- 미궁 캡처 목록: `after/results.json`에 기록된 98개만 최종 증거다. 폴더에는 초기 실패·이전 시도 파일도 남아 있다.
- 이전 사각형 표식 전후: `tmp/uiux_map_labels_20260913/index.html`

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 484482408f07a89fd89a980a75dafe45ee1040ba
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..484482408f07a89fd89a980a75dafe45ee1040ba
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

검수 이후 기능·데이터·자산 변경 없음. 이후 기록은 `docs/handoff/`만 수정한다. 별도 검수 에이전트는 요청받지 않아 실행하지 않았다.

## 7. 미해결 항목과 위험

- 새 동선의 거리·합류 시점으로 인한 전투 난도는 사람 플레이/캠페인 관찰이 남는다. 파동 수치를 보존했다는 사실이 기존 난도와 동일함을 뜻하지 않는다.
- 기존 저장은 기존 지도를 보존한다. 새 미궁을 보려면 이 작업본에서 새 게임을 시작한다. 진행 중 저장을 강제 이주시키지 않았다.
- 기존 절벽 배경·뒤쪽 벽 미술은 재사용했다. 모든 배경을 새 실내 미술로 교체했다고 주장하지 않는다.
- Web/다른 플랫폼·출시용 export·공개 URL 갱신은 미실시.
- 실행 가능한 로컬 미궁 구현과 관련 검증은 완료했다. 요청받은 전체 출시·통합 작업은 없다.

## 8. 다음 작업 순서

1. 위 비교 페이지 또는 로컬 새 게임에서 미궁·수비 배치 결과를 확인한다. 시설/몬스터/경로 취향 피드백은 실제 장면 기준으로 받는다.
2. 난도 조정이 필요하면 실제 전투 기록을 모아 동선별 교전·합류를 비교한다. 기존 수치·콘텐츠는 근거 없이 변경하지 않는다.
3. 제품 통합·테스트 빌드·공개 배포·버전/태그는 해당 요청이 있을 때 별도로 진행한다.

## 9. 작업 트리 상태

- 작업트리: `C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2`
- 구현 18개 경로 명시적 스테이징·로컬 커밋 완료. 캡처·로그·APPDATA는 `tmp/`의 무시된 파일로 남긴다.
- 기존 다른 작업트리/출시 브랜치 변경 없음. 원격 미푸시.
- 종료 문서 커밋 후 추적 대상 작업트리는 clean으로 확인한다.

## 10. 종료 체크리스트

- [x] 사용자 확정 8개 결정과 구현 대조
- [x] 관련 미궁·건설·전투·저장·시설·샛문 검사 통과
- [x] 두 해상도·기존 글자 배율 실제 실행 증거
- [x] 검수 대상 최종 SHA와 NOT_REQUESTED 범위 기록
- [x] 생성 원본·실제 alpha·게임 연결 출처 기록
- [x] CURRENT 갱신 및 의도한 파일만 로컬 커밋
- [x] 전체 캠페인/사람 검수·미술 재사용·미배포 상태 구분
