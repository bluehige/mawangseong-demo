# UIUX 완성도 개선 결과 — 2026-09-13

이번 구현 묶음은 실제 게임에 반영했고 직접 테스트 17종은 통과했다. **전체 게임 완성/최종 출시 승인 판정은 아니다.** 이전 감사의 확정 결함부터 수정하고, 미술과 밸런스의 남은 범위를 아래에 구분했다.

- 브랜치: `codex/v126-uiux-u0-u3`
- 구현 전 SHA: `a5520252532bdb2374ee60ec5396e51c5ab8c00a`
- 구현 SHA: `e73c2b422ad4082026a25a779d89336ad8323425` (로컬 커밋, 미푸시)
- main / origin/main: `69a75970b1f8c030aa3a6956e5ca0f5bf15b2112`, 안정판 1.2.6. 새 버전·main·태그·공개 배포 변경 없음.
- 사용자 순서 준수: 제품 수정과 자산 연결 후 마지막에 검증을 시작했다. 그 단계에서 발견된 결함만 수정·재검증했다. 서브에이전트 없음.
- [실제 화면 전후 모음](C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/tmp/uiux_polish_20260913/index.html) · [17종 최종 로그 목록](C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/tmp/uiux_polish_20260913/test_summary.json) · [검증 구현 파일 해시](C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/tmp/uiux_polish_20260913/source_manifest.json)

## 구현 결과

| 이전 감사 | 실제 변경 | 현재 범위 |
|---|---|---|
| R01 최종전 사건 순서 | 전투 전 62개 원문 대사를 실제 사건 8장면으로 이관하고 준비 브리핑 6줄 작성. 공병·지휘 해제·돌진·외침·맹세/방어막 종료를 실제 상태/카운터로 제한 | 정찰/공병 교란 분기, 사건 전 표시 금지 및 옛 저장 cue 복원 직접 검사 |
| R02 안내 충돌 | 필수 특화 창보다 현재 방 지침 튜토리얼을 먼저 보여주고 하단 행동 안내 일치 | 자동 새 게임→DAY 4 흐름 PASS. 사람 마우스/키보드 두 차례 완주는 미실행 |
| R03 내부 이름 | 역할 공용 표시 함수를 전투/관리창에 사용. 위치는 최초 표시와 매 프레임 갱신 모두 공용 공간 이름 사용 | `blocker`, `path_a_entry_front` 재노출 경로까지 수정 |
| R04 이동 | 남은 이동 거리를 정확한 코너 너머 다음 경유점에 소비. 가까운 첫 점 생략 제거. 실제 이동 거리 기반 흔들림. 방향 자세가 혼재한 진화체 2종은 방향 프레임을 고정 | x1/x3 코너·끝점 직접 검사 및 실제 전투. 모든 캐릭터 4방향 미술 완료는 아님 |
| R05 전장 가독성/미술 | 선택·위협·위급 아군 중심 이름. 같은 대상 0.15초 안 피해 숫자 합산. 진화 초상화 6종 신규 연결과 GPU 축소 필터 | 기본/승리/부상은 같은 새 중립 초상. 군집 몸체 분산은 후속 |
| R06 시설/전술 가치 | 방별 실제 연결 효과 구역 표시. 감시초소 기록 0이면 다음 경로/범위 확인 안내. 동일 전력 위치 비교 | 기여 차이는 확인. 난이도 적정/승률 PASS 아님, 비용·전투 수치 변경 없음 |
| R07 대화 중단 | DAY 5 이후 일반 전투 반응은 입력·정지를 점유하지 않는 짧은 표시. 오래된 반응은 12초로 제한, 중요한 사건 우선. 읽기 시작한 장면은 대화 기록에서 재열람 | DAY 1~3 필수 설명의 정지는 유지. 전투 명령 확인창 추가 없음 |
| R08 낡은 검사 | 현재 성장 선택/튜토리얼 대상/테두리 계약 갱신. 모르는 BalanceSimulation 시나리오는 exit 1. 스토리 원문 보존과 명시적 교정본 대조 | 직접 검사 17종. 전체 출시 회귀로 확대하지 않음 |

## 실제 변경 경로

- `scripts/units/Unit.gd`: 정확한 경유점 이동, 거리 기반 자세, 방향 프레임, 이름 우선순위.
- `scripts/game/GameRoot.gd`, `scripts/story/StoryDirector.gd`, 신규 `scripts/story/CombatStoryFeed.gd`: 사건 조건, 비차단 반응, 옛 cue 복원, 부분 읽기 기록 재열람.
- `scripts/game/CombatSceneController.gd`: 피해 수치 합산 표시와 결과 시설 목록 기록.
- `scripts/ui/HUDController.gd`, `ManagementWorkspaceUI.gd`, `MonsterWorkspaceUI.gd`, `ResultWorkspaceUI.gd`, `scripts/v122/ui/V122CombatResultViewModel.gd`: 안내 순서, 동적 이름, 적용 구역과 기여 안내.
- `data/story/v122_main/day_*.json`의 해당 전투 반응 메타데이터 및 DAY 30. 동결 원고는 변경하지 않고 `data/story/source/UIUX_POLISH_20260913.json`에 새 6줄/교정문 명시. 기존 cue ID 전부 유지.
- `data/evolution_rules.json`, `data/uiux_actor_art.json`, `assets/sprites/portraits/uiux_evolution/`: 초상화와 방향 메타데이터. 초상 경로를 제외한 진화 규칙/비용은 이전 JSON과 동일함을 비교했다.
- 직접 테스트와 낡은 기대값 수정 경로는 구현 커밋의 57개 파일 목록 및 해시 manifest에 명시.

## 자산

GPT internal image generation으로 1536×1024 원본 하나 생성. 각 512×512 영역을 `.tres` AtlasTexture 6개로 사용한다. 원본/런타임 PNG는 바이트가 동일하며 래스터 축소·외부 배경 제거 없음. Godot 밉맵만 생성한다.

출처: `assets/source/imagegen/uiux_evolution_portraits_20260913/SOURCE.md`. 감정별 별도 그림은 생성하지 않았고 중립 초상을 재사용한다. 이미지 생성 첫 요청은 참조 6개 제한 오류로 실행되지 않았으며, 참조 5개와 보물고 수호자 텍스트 설명으로 재요청했다.

## 마지막 검증

Windows / Godot 4.6.3 / Forward+ / RTX 3060 Ti. 직접 GUI 검사와 내부 상태를 준비한 통합 검사를 구분한다. 모든 실행의 APPDATA는 tmp 아래에 분리했다.

- `direct_final`: UIUX_POLISH_INTEGRATION_TEST: PASS (120 assertions); 최종 로그 ERROR 0.
- `tutorial`: TUTORIAL_FLOW_SMOKE_TEST: PASS; 최종 로그 ERROR 0.
- `UIUXBuildPlacementTest`: UIUX_BUILD_PLACEMENT_TEST: PASS (344 checks); 최종 로그 ERROR 0.
- `UIUXCombatInteractionTest`: UIUX_COMBAT_INTERACTION_TEST: PASS (210 assertions); 최종 로그 ERROR 0.
- `UIUXU4InteractionTest`: UIUX_U4_INTERACTION_TEST: PASS (517 assertions); 최종 로그 ERROR 0.
- `UIUXActorWallDepthTest`: UIUX_ACTOR_WALL_DEPTH_TEST: PASS (975 assertions, 32 captures); 최종 로그 ERROR 0.
- `V122StoryDialogueSchemaTest`: V122_STORY_DIALOGUE_SCHEMA_TEST: PASS (19629 assertions); 최종 로그 ERROR 0.
- `V122StoryDay01To05Test`: V122_STORY_DAY01_TO_05_TEST: PASS (216 assertions); 최종 로그 ERROR 0.
- `V122StoryDay06To30Test`: V122_STORY_DAY06_TO_30_TEST: PASS (7783 assertions); 최종 로그 ERROR 0.
- `V122StoryRuntimeIntegrationTest`: V122_STORY_RUNTIME_INTEGRATION_TEST: PASS (58 assertions); 최종 로그 ERROR 0.
- `V122StorySaveStateTest`: V122_STORY_SAVE_STATE_TEST: PASS; 최종 로그 ERROR 0.
- `V122StoryProductFlowTest`: V122_STORY_PRODUCT_FLOW_TEST: PASS (33 assertions); 최종 로그 ERROR 0.
- `V122PrecombatFlowTest`: V122_PRECOMBAT_FLOW_TEST: PASS (40 assertions); 최종 로그 ERROR 0.
- `V122FacilityZoneEffectResolverTest`: V122_FACILITY_ZONE_EFFECT_RESOLVER_TEST: PASS; 최종 로그 ERROR 0.
- `V122FacilityZoneCombatConsumerTest`: V122_FACILITY_ZONE_COMBAT_CONSUMER_TEST: PASS; 최종 로그 ERROR 0.
- `V122CombatResultUIContractTest`: V122_COMBAT_RESULT_UI_CONTRACT_TEST: PASS; 최종 로그 ERROR 0.
- `V122ResultUISimplificationTest`: V122_RESULT_UI_SIMPLIFICATION_TEST: PASS (37 assertions); 최종 로그 ERROR 0.

추가 확인: 존재하지 않는 시나리오는 결과 없이 성공하지 않고 exit 1. `git diff --check` 통과. 생성 PNG 동일성과 진화 규칙/비용 불변 비교 통과.

일부 테스트는 순수 표시 후속 수정 전에 실행됐고, 마지막 동적 위치/역할·초상화 변경은 `UIUXPolishIntegrationTest` 120항목과 `final_live/` 실제 전투로 다시 확인했다. 전체 회귀를 반복했다고 기록하지 않는다.

처음 마지막 검증 단계에서 타입 추론 누락과 첫 경유점 생략을 발견해 수정했다. `import.log`, `direct.log`는 당시 실패 기록이며, 최종 결과는 `direct_final.log` 및 목록에 지정한 로그다. Windows 가상 키보드 지원 경고는 초반 검사에 남는다.

## 이동·시설 관측

| 관측 | 이전 | 수정 후 |
|---|---:|---:|
| DAY 2 경유점 직후 속도 0·경로 잔존 전환 | 105 | 0 |
| DAY 30 같은 계측 | 545 | 0 |

이 값은 모든 정지/전환을 결함으로 센 것이 아니다. 실제 전투에서 AI 판단·공격으로 생기는 방향 전환과 몸체 겹침은 남는다. DAY 2 평균 16.67ms/p95 17.59ms/최대 110.94ms, 최종 DAY 30 평균 16.67ms/p95 17.19ms/최대 93.62ms. 평균 약 60fps이나 긴 프레임이 없는 것은 아니다. 독립 DAY 2/30 시나리오 둘 다 승리했고, 연속 캠페인 평균 전력/일반 승률로 해석하지 않는다.

시설 비교는 DAY 2 동일 roster/자원, seed 20260913, 사수, 능동 스킬 없음. 두 후보 방에서 병영을 공통으로 제외하고 감시초소 위치만 바꾼 준비 시나리오다.

| 감시초소 연결 구역 | 추가 피해 | 둔화 | 아군 잔여 HP | 종료 시간 |
|---|---:|---:|---:|---:|
| 정문 가시 길목 | 58 | 6회 | 380/451 | 40.73초 |
| 보물고 진입로 | 3 | 0회 | 373/451 | 39.67초 |

기여가 커져도 두 경우 모두 승리했고, 종료 시간도 일방적으로 좋아지지 않았다. 시설을 올바른 전선에 연결할 이유는 확인했지만 난이도 조정의 근거로 충분하지 않다. `watch.log`의 준비 단계 자동 저장 경고는 임시 도구 초기화 전에 저장을 차단해 `watch_final.log`에서 제거했다. **후자의 종료에는 ObjectDB/리소스 5개 정리 경고가 남아 해당 비교를 PASS로 분류하지 않았다.** 실제 게임 전투/17종 직접 검사 최종 로그에는 같은 ERROR가 없었다.

## 남은 범위와 다음 순서

1. 모든 캐릭터의 앞/뒤/좌/우 이동 그림과 군집 교전 몸체 겹침. 이번에는 2개 시트의 방향 혼재만 바로잡았다. 물리 위치 분산은 길/공격 거리 규칙과 함께 별도 설계가 필요하다.
2. 진화 승리/부상 표정, 일부 왕관·적 미술의 전장/상세 일관성. 이번 6종 이외 전체 미술 완료라고 하지 않는다.
3. 실제 연속 성장 기준 중후반 반복 플레이와 초보자 사용성. 적 수치를 올리기 전에 두 전선 운영/시설 위치/명령의 결과 차이를 확인한다.
4. 임시 비교 도구 종료 리소스 정리 경고 추적. 측정값은 보존하되 정식 출시 테스트 성공으로 사용하지 않는다.
5. 최종 후보의 플랫폼·저사양·장시간 검증과 사람 DAY 1~30 완주는 미수행. 공개 배포와 태그는 실행하지 않았다.

현재 묶음은 **TARGETED_PASS**, 최종 출시 판정은 **HOLD 유지**다. 사용자와 지인의 직접 플레이 결과를 포함한 최종 승인까지 완료했다는 의미가 아니다.
