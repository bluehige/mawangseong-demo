# Tutorial QA Report - General Player Perspective (2026-07-08)

## Verdict

튜토리얼은 현재 내부 데모/플레이테스트 기준으로는 통과 가능하다. 진행 게이트, DAY 01-03 전투, 결과 성장 확인, DAY 04 예고까지 자동 검수에서 막힘 없이 통과했다.

다만 일반 게임 유저 관점에서는 아직 "잘 만든 첫 5분"이라기보다 "기능이 모두 연결된 튜토리얼"에 가깝다. 가장 큰 리스크는 진행 불가가 아니라 안내 문구의 모호함, 전투 직접 조종의 손맛 전달 부족, 결과 성장 화면의 보상감 부족이다.

권장 판정: 다음 내부 플레이테스트 가능. 외부 신규 유저용 튜토리얼로 내기 전에는 P1 항목을 먼저 손봐야 한다.

## Scope

- 검수자 가정: 던전 키퍼/오토배틀러/타워디펜스류를 좋아하지만 이 프로젝트의 사전 지식은 없는 일반 유저.
- 기준 브랜치: `codex/map-custom-2026-07-03`
- 원격 확인: `origin/codex/map-custom-2026-07-03`와 현재 HEAD가 동일한 `421686e Polish tutorial map UX and handoff`
- 참고 문서:
  - `docs/HANDOFF_TUTORIAL_GAME_LOOP_AUDIT_2026-07-07.md`
  - `docs/ONBOARDING_FLOW_IMPLEMENTATION_HANDOFF_2026-07-06.md`
  - `참고자료/onboarding_flow_dialogue_v0.4.json`

## Verification Run

| Check | Result | Notes |
| --- | --- | --- |
| `git fetch --all --prune` | PASS | 현재 작업 브랜치는 원격 브랜치와 동일. `main`은 별도로 4커밋 뒤. |
| `TutorialFlowSmokeTest.tscn` | PASS | 이름 입력 이후 DAY 01-03 튜토리얼 게이트, 성장 확인 차단, DAY 04 예고까지 통과. |
| `OnboardingFlowSmokeTest.tscn` | PASS | 타이틀, 이름 입력, 오프닝, DAY 01/02/03 루프, 데모 승리, DAY 04 프리뷰 통과. |
| `CharacterDataSmokeTest.tscn` | PASS | 핵심 캐릭터/초상/감정 에셋 로드 통과. |
| `BalanceSimulation.tscn -- --assert-tutorial-balance` | PASS | DAY1 56.4s 승리, DAY2 54.1s 승리, DAY3 70.0s 승리. 왕좌 HP 1500 유지. |
| `DemoSmokeTest.tscn` | PASS | 관리 화면, 건설/배치, 직접 조종, 함정, 패배/승리 분기, 3일 데모 클리어 통과. |
| `OnboardingPortraitCapture.tscn` | PASS | 타이틀/이름 입력/대화/4줄 긴 대사/초상 캡처 생성. |
| `git diff --check` | PASS | CRLF 경고만 확인. 공백 에러 없음. |

반복 경고: Godot가 `assets/ui/dark_fantasy/*.png`를 이미지 파일로 직접 로드한다고 경고한다. 현재 플레이어 진행에는 영향이 없지만 export 전에는 Image 리소스 import 방식으로 정리해야 한다.

## User-Facing Scores

| Area | Grade | Reason |
| --- | --- | --- |
| 진행 안정성 | A | 자동 검수 기준으로 튜토리얼 전체 진행 불가 지점 없음. |
| 안내 명확성 | B- | 핵심 액션은 알려주지만 일부 문구가 모호하고 "왜 해야 하는지"가 약함. |
| 전투 재미 | B | DAY3는 스킬 사용량이 있어 살아나지만 DAY1 직접 조종의 손맛 설명이 약함. |
| 보상감 | C+ | 성장 확인은 구현됐지만 결과 화면이 빽빽하고 레벨/EXP의 감정적 보상이 약함. |
| 화면 가독성 | B- | 대화창/초상은 양호. 관리/전투/결과 HUD는 정보량이 많고 일부 패널이 답답함. |
| 온보딩 부담 | B- | 94줄 대사와 17개 튜토리얼 게이트는 데모 스토리로는 가능하지만 스킵 욕구가 생길 수 있음. |

## Findings

### P0

없음. 이번 검수에서 튜토리얼을 막는 진행 불가 버그는 발견하지 못했다.

### P1 - Fix Before External Playtest

1. 첫 몬스터 배치 문구가 모호하다.
   - 현재 `TUT_040_DEPLOY_SLIME` 문구는 "슬라임을 입구 근처에 배치하세요."
   - 일반 유저는 "근처"를 인접 방이나 길목으로 해석할 수 있다.
   - 권장 문구: "슬라임을 입구 방에 배치하세요. 침입자는 입구에서 왕좌로 이동합니다."

2. DAY 01 관리 튜토리얼은 클릭 순서는 알려주지만 전략 이유가 약하다.
   - 슬라임 선택, 배치, 전체 지침, 방 지침 순서는 검증됐다.
   - 하지만 유저가 "왜 입구를 막아야 하는지"를 한 번에 이해하기 어렵다.
   - 권장: 첫 관리 화면에 짧은 목적 안내를 추가한다. "침입자는 노란 경로를 따라 왕좌로 향합니다. 입구에서 시간을 벌어야 합니다."

3. 직접 조종 튜토리얼이 손맛을 충분히 만들지 못한다.
   - `direct_control_once` 게이트는 통과한다.
   - 하지만 일반 유저 입장에서는 직접 조종이 자동 전투보다 왜 재밌는지 바로 체감하기 어렵다.
   - 권장: 직접 조종 버튼을 누른 뒤 "탐험가를 우클릭하거나 스킬 1을 눌러 한 번 공격"처럼 한 번의 명확한 액션 미션을 준다.

4. 결과 성장 화면의 보상감과 배치가 약하다.
   - 성장 확인 게이트는 DAY 01 결과에서 정상 동작한다.
   - 캡처 기준 EXP 목록, `성장 확인` 버튼, 다음 진행 안내가 오른쪽 패널 안에서 빽빽하다.
   - 권장: 성장 확인을 별도 미니 패널 또는 중앙 모달로 띄우고, `EXP +6`, `Lv.1 (6/50)`를 몬스터별 카드/바 형태로 정리한다.

### P2 - Improve for Better First Impression

1. 타이틀 화면의 분위기는 좋지만 배경 던전이 너무 어둡게 묻힌다.
   - 게임의 핵심인 "내 마왕성을 방어한다"가 첫 화면에서 약하게 보인다.
   - 권장: 중앙 제목 뒤 배경을 조금 더 살리거나 방/왕좌 실루엣을 첫 시선에 보이게 조정한다.

2. 대사량은 데모 스토리로는 가능하지만, impatient player에게는 길 수 있다.
   - 현재 대사 94줄, 튜토리얼 액션 게이트 17개.
   - 긴 대사 4줄 배치는 깨지지 않았지만 첫 플레이 속도를 늦춘다.
   - 권장: 첫 실행 후 스킵, 또는 튜토리얼 재플레이 시 요약 모드가 필요하다.

3. DAY 02 도둑/보물 목표는 좋은 장르적 훅이지만 위협 연출이 약할 수 있다.
   - 밸런스 시뮬레이션에서는 DAY2가 54.1초 승리하고 왕좌 피해가 없다.
   - 너무 안전하면 "보물을 지켜야 한다"는 압박이 약하다.
   - 권장: 도둑이 보물 방 근처까지 접근하는 장면, 보물 경고 핑, 또는 거의 훔칠 뻔한 연출을 추가한다.

4. DAY 03은 스킬 사용량 13회로 피크가 생기지만 보스 HP 튜토리얼 가시성이 중요하다.
   - `boss_hp_50`, `imp_fireball` 게이트는 통과한다.
   - 권장: 보스 HP 50% 시점에 화면 중앙 경고/짧은 슬로우/스킬 추천을 붙여 학습 순간을 강조한다.

5. 길 드래그 편집 UI는 이전보다 훨씬 명확하다.
   - 좌측에 큰 `길 드래그 편집` 버튼이 있고, 연결/해제 상태 안내가 보인다.
   - 다만 이것은 핵심 튜토리얼 1회차에는 아직 부담이 큰 편이다.
   - 권장: DAY 01-03 필수 튜토리얼에는 넣지 말고, 마왕성 확장 튜토리얼에서 별도 소개한다.

## Visual QA Notes

확인 캡처:

- `tmp/onboarding_portrait_verification/01_title.png`
- `tmp/onboarding_portrait_verification/02_name_entry_bati_portrait.png`
- `tmp/onboarding_portrait_verification/11_dialogue_four_line_layout_check.png`
- `tmp/onboarding_portrait_verification/12_dialogue_gob_eager_portrait.png`
- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor_drag_connected.png`
- `tmp/manual_verification/03_combat_start.png`
- `tmp/manual_verification/06_result.png`

시각 결론:

- 대화 초상과 4줄 대사 레이아웃은 깨지지 않는다.
- 관리 화면의 길 드래그 편집 버튼은 이전보다 찾기 쉽다.
- 전투 화면은 기능 버튼이 보이지만 좌측 전장 상태/로그와 우측 유닛 상세가 동시에 많아 초반 유저에게는 복잡하다.
- 결과 화면은 성장 확인 기능이 보이지만 보상 정보를 읽기 전에 장식 프레임과 텍스트 밀도가 먼저 느껴진다.

## Recommended Next Work

1. `TUT_040_DEPLOY_SLIME` 문구를 "입구 방" 기준으로 고친다.
2. DAY 01 첫 관리 화면에 침입 경로와 입구 방어 이유를 한 문장으로 추가한다.
3. 직접 조종 튜토리얼을 "버튼 누르기"가 아니라 "적을 한 번 때리기/스킬 한 번 쓰기"로 바꾼다.
4. 결과 성장 확인 UI를 별도 보상 패널로 분리한다.
5. DAY 02 도둑 위협과 DAY 03 보스 HP 50% 순간을 더 연출한다.

## Final Call

현재 튜토리얼은 시스템 연결성과 안정성은 충분히 확보됐다. 다음 작업은 버그 수정이 아니라 첫 플레이 감정선 개선이다. 일반 유저가 "시키는 대로 했다"에서 끝나지 않고 "내가 배치해서 막았다, 직접 조종해서 이겼다, 몬스터가 성장했다"를 느끼게 만드는 쪽으로 P1 항목을 먼저 처리하는 것이 맞다.
