# Handoff: Raid Loop and Kobold Scout Captain (2026-07-08)

## Session Summary

튜토리얼 이후 첫 진행을 `DAY 04 악명 원정`으로 연결했다. 플레이어는 로로를 새 부하로 얻고, 원정 지도에서 첫 임무를 보내 악명과 금화를 얻으며, 그 결과가 다음 방어전 웨이브에도 실제로 반영된다.

초보자 설명:

- `웨이브`는 전투에서 어떤 적이 언제 몇 명 나오는지 적은 일정표다.
- `스모크 테스트`는 전체 게임을 오래 플레이하지 않고 핵심 흐름이 깨졌는지 빠르게 확인하는 자동검사다.
- `modifier`는 기존 데이터에 덧씌우는 작은 보정치다. 이번에는 원정 결과가 다음 방어전 적 등장 시간과 수를 바꾼다.

## User Direction Covered

- 최신 관리 루프 직접 검증.
- 건물 배치 UX 단순화: 빈 슬롯/변경 가능한 방 클릭 시 시설 팔레트가 자연스럽게 열림.
- 몬스터 배치 UX 개선: 방 수용량과 여러 마리 배치 가능성을 더 잘 보이게 정리.
- 시설 효과 피드백: 감시초소, 병영, 회복 둥지 효과를 전투/결과 통계에 표시.
- 성 업그레이드 비주얼은 UI 확장 전에 렌더러 데이터 구조와 비주얼 방향을 먼저 정리.
- 튜토리얼 이후 스토리 계획표 작성.
- 악명 원정 기획 및 구현.
- 장난기 많은 코볼트 척후대장 `로로`를 새 원정대장 부하로 추가.
- 로로 일러스트와 표정 변형을 추가하고 스토리 대사에 연결.

## Image Rule

중요: 앞으로 이 프로젝트에서 로로, 몬스터, 방, 성 업그레이드, 원정 관련 신규 이미지는 반드시 `gpt imagen 2`로 생성해야 한다.

이번 로로 이미지는 세션 내 이미지 생성 경로를 통해 만들었고, 원본 생성물은 다음 폴더에서 확인했다.

- `C:/Users/blueh/.codex/generated_images/019f4195-148f-73e2-8460-e722ccb8a935`

프로젝트에 복사된 런타임 이미지:

- `assets/sprites/portraits/onboarding/portrait_rolo.png`
- `assets/sprites/portraits/onboarding/CHR_ROLO_portrait_mischief.png`
- `assets/sprites/portraits/onboarding/CHR_ROLO_portrait_briefing.png`
- `assets/sprites/portraits/onboarding/CHR_ROLO_portrait_flustered.png`
- `assets/sprites/monsters/monster_kobold_scout_idle_down_00.png`

현재 전투 스프라이트는 로로 초상 기반 임시 런타임 스프라이트다. 추후 전투 애니메이션 시트를 만들 때도 반드시 `gpt imagen 2`를 사용하고, 8방향/이동/공격 프레임 규격을 별도 승인 후 잘라야 한다.

## Implemented

### Raid Data and Flow

- `data/raid_missions.json`
  - `d04_signpost_flip`: DAY 04 첫 원정, 표지판 돌리기.
  - `d05_supply_tag`: DAY 05 후보 데이터. DAY 04에는 실제 목록에 뜨지 않도록 제한.
  - 원정 보상, 비용, 브리핑, 성공 문구, 다음 방어전 보정치를 데이터화.

- `scripts/core/Constants.gd`
  - `SCREEN_RAID` 추가.

- `scripts/core/DataRegistry.gd`
  - `raid_missions` 로드와 `raid_mission()` 조회 추가.

- `scripts/game/GameRoot.gd`
  - 원정 화면, 원정 선택, 원정대 편성, 비용 지불, 보상 지급, 결과 보고 패널 추가.
  - DAY 04 원정 화면 진입 시 로로 자동 합류.
  - 로로 포함 시 원정 악명 보상 +10%.
  - DAY 04에는 DAY 04 원정만 실제 목록에 노출되도록 정리.
  - 원정 완료 후 `next_defense_modifiers`에 다음 방어전 영향 저장.

- `scripts/combat/WaveManager.gd`
  - 방어전 modifier를 받아 적 수, 등장 지연, 등장 간격, 추가 웨이브를 적용할 수 있게 확장.

- `scripts/game/CombatSceneController.gd`
  - 전투 시작 시 원정 modifier를 웨이브에 적용하고 한 번 사용한 뒤 소모.
  - DAY 04 전투가 기존 DAY 03 데모 클리어 판정으로 잘못 처리되지 않도록 승리 조건을 `GameState.day == GameState.max_day`로 좁힘.

- `data/waves.json`
  - DAY 04 기본 방어전 웨이브 추가.
  - 첫 원정 성공 시 탐험가 수가 1명 줄고, 첫 침입이 늦어지며, 탐험가 간격이 늘어난다.

### Kobold Scout Captain

- `data/monsters.json`
  - `kobold_scout` 추가.
  - 역할: `원정대장 / 교란 보조`.
  - 밸런스 의도: 기존 전투 부하보다 직접 화력은 낮고, 원정 보너스와 교란 스킬로 존재감 부여.

- `data/skills.json`
  - `false_footprints`: 주변 적을 느리게 만드는 교란 스킬.
  - `rumor_boost`: 전투 중 악명 보상을 조금 추가하는 소문 과장 스킬.

- `scripts/game/CombatSceneController.gd`
  - 로로 스킬 효과 구현.

- `data/characters.json`
  - `CHR_ROLO` 추가.
  - 표정 변형: `base`, `mischief`, `briefing`, `flustered`.
  - 감정 alias도 같이 연결.

### Story

- `참고자료/onboarding_flow_dialogue_v0.4.json`
  - DAY 04 원정 프리뷰에 로로 소개 대사 추가.
  - 바티가 로로를 코볼트 척후대장으로 소개하고, 표지판 장난이 첫 원정 목표가 되도록 연결.

- `docs/STORY_PLAN_AFTER_TUTORIAL_2026-07-08.md`
  - 튜토리얼 이후 DAY 04 진행 계획에 로로 합류, 원정 지도, 악명 보상 루프를 반영.

### UI and Management Loop

- `scripts/game/ManagementSceneController.gd`
  - 관리 화면 하단에 원정 버튼 추가.
  - 원정 해금 이후 안내 문구를 원정/방어 준비 흐름에 맞게 변경.

- `scripts/ui/HUDController.gd`
  - 선택 방 몬스터 배치 패널을 2열로 정리해 다수 몬스터 보유 시 넘침을 줄임.

- `tools/ManualVerificationCapture.gd`
  - 원정 화면과 원정 결과 캡처 추가.
  - 최신 확인 캡처:
    - `tmp/manual_verification/02_raid_screen.png`
    - `tmp/manual_verification/02_raid_result.png`

## Verification

통과한 검사:

- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`

눈으로 확인한 화면:

- DAY 04 원정 지도에는 첫 원정만 표시된다.
- 로로 카드와 초상화가 오른쪽 원정대 패널에 표시된다.
- 보상 줄에 `악명 22 (로로 +2)`가 표시된다.
- 원정 결과 보고서에 획득 보상과 다음 방어 영향이 표시된다.

## Known Follow-Up

- DAY 05 이후 본편 진행은 아직 별도 캠페인 확장 작업으로 남겨두는 것이 좋다. 현재는 DAY 04 첫 원정과 그 다음 방어전까지 동작한다.
- `d05_supply_tag` 데이터와 modifier 구조는 준비되어 있지만, DAY 05 전용 진행 화면/날짜 전환/전용 웨이브는 다음 캠페인 확장에서 묶어 구현하는 편이 안전하다.
- 로로 전투용 정식 애니메이션 시트가 필요하면, 반드시 `gpt imagen 2`로 생성한 뒤 기존 애니메이션 규격에 맞춰 분할해야 한다.
