# Handoff: Tutorial P1 Verification and Finish Pass (2026-07-09)

## Session Summary

최신 GitHub 변경사항을 pull한 뒤, 인수인계 문서 기준 작업 순서 1, 2를 마무리했다.

완료 범위:

1. 최신 pull 기준선 검증.
2. 외부 플레이테스트 전 튜토리얼 P1 항목 확인 및 마감 수정.

이번 세션에서 확인한 최신 HEAD:

- Branch: `codex/map-custom-2026-07-03`
- Pulled HEAD before local edits: `eea53d6 Polish combat and management UI feedback`

## Important Project Rules

- 신규 로로, 몬스터, 방, 성 업그레이드, 원정 관련 이미지는 반드시 `gpt imagen 2`로 생성한다.
- 실패/격리된 콘셉트 이미지는 런타임 에셋처럼 제시하거나 재사용하지 않는다.
- 튜토리얼 UI를 바꿀 때도 튜토리얼 타깃 ID는 유지한다.
- 작업 종료 전에는 자동 검증을 돌리고, 검수 에이전트 리뷰를 받은 뒤 지적 사항을 반영한다.

## What Was Already Done In Pulled HEAD

`docs/TUTORIAL_QA_REPORT_2026-07-08.md`의 P1 중 상당수는 pull된 최신 HEAD에 이미 반영되어 있었다.

- `TUT_030_SELECT_SLIME`
  - 노란 경로와 입구 방어 이유를 안내한다.
- `TUT_040_DEPLOY_SLIME`
  - "입구 근처"가 아니라 "입구 방 클릭 / 드래그"로 안내한다.
- `TUT_070_DIRECT_CONTROL` / `TUT_075_DIRECT_ATTACK`
  - 직접 조종 버튼만 누르는 흐름에서, 적 우클릭 공격 또는 스킬 1 사용을 요구하는 흐름으로 바뀌어 있다.
- 결과 성장 UI
  - 몬스터별 `EXP +n`, 레벨, EXP 바를 카드 형태로 보여주는 성장 패널이 있다.

관련 파일:

- `scripts/game/GameRoot.gd`
- `scripts/game/ManagementSceneController.gd`
- `tools/TutorialFlowSmokeTest.gd`
- `tools/TutorialUxCapture.gd`

## Implemented This Pass

### Growth Review Gate UI

File: `scripts/game/ManagementSceneController.gd`

문제:

- DAY 01 결과 화면에서 `성장 확인`을 누르기 전에는 `_continue_from_result()`가 다음 진행을 막고 있었다.
- 하지만 하단 `다음 날 진행` 버튼은 활성 버튼처럼 보였기 때문에, 실제 게이트와 UI 상태가 어긋날 수 있었다.

수정:

- 튜토리얼이 `growth_reviewed` 액션을 기다리는 동안 하단 진행 버튼을 비활성화한다.
- 버튼 문구를 `성장 확인 필요`로 바꾼다.
- 성장 확인 후에는 기존 흐름대로 다음 진행이 가능하다.

### Regression Test

File: `tools/TutorialFlowSmokeTest.gd`

추가 검증:

- DAY 01 결과 화면에서 성장 확인 전 하단 진행 버튼이 `성장 확인 필요` 상태이며 disabled인지 확인한다.

새 PASS 문구:

```text
PASS: DAY 01 result disables next-day button until growth review
```

## Verification

기준선 및 수정 후 확인:

```powershell
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
godot --path . --run res://tools/TutorialUxCapture.tscn
godot --headless --path . --import
```

현재 확인된 PASS:

- `DEMO_SMOKE_TEST: PASS`
- `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `QUARTER_MODULE_SMOKE_TEST: PASS`
- `MANUAL_VERIFICATION_CAPTURE`
- `TUTORIAL_UX_CAPTURE`

눈으로 확인한 캡처:

- `tmp/tutorial_ux_verification/01_first_task_card.png`
  - 노란 경로와 입구 방어 이유가 보인다.
- `tmp/tutorial_ux_verification/02_deploy_task_card.png`
  - 슬라임을 입구 방에 배치하라는 안내가 보인다.
- `tmp/tutorial_ux_verification/04_result_growth_panel.png`
  - 몬스터별 EXP 카드와 바가 읽힌다.

## Known Warning

pull 직후에는 새 로로 PNG와 코볼트 스카우트 PNG의 `.godot/imported/*.ctex` 캐시가 없어 Godot가 원본 PNG fallback 경고를 냈다.

예:

- `CHR_ROLO_portrait_mischief.png`
- `CHR_ROLO_portrait_briefing.png`
- `monster_kobold_scout_idle_down_00.png`

이번 세션에서 다음을 실행해 import 캐시를 생성했다.

```powershell
godot --headless --path . --import
```

주의:

- 이 캐시는 로컬 `.godot` 하위 산출물이라 Git에는 포함되지 않는다.
- 기존부터 반복되던 `Loaded resource as image file, this will not work on export` 경고는 여전히 별도 기술 부채다.
- 정식 export 전에는 런타임 PNG 직접 로딩을 `ResourceLoader` 기반 임포트 리소스 로딩으로 정리해야 한다.

## Review Agent Result

작업 종료 전 검수 에이전트를 실행했다.

결론:

- 차단급 문제 없음.
- 성장 확인 전 진행 버튼 비활성화 조건은 기존 `_continue_from_result()` 하드 가드와 동일해 튜토리얼 외 결과 화면을 새로 막는 변경으로 보이지 않는다.
- `TutorialFlowSmokeTest.gd`의 새 검증은 버튼 문구와 disabled 상태, 직접 `_continue_from_result()` 차단을 함께 확인한다.
- 핸드오프 문서는 P1 완료 범위와 다음 시작점 DAY 05~07을 명확히 분리했다.

잔여 리스크:

- 튜토리얼 외 결과 화면을 직접 여는 별도 회귀 테스트는 없다. 현재 판단은 코드 조건 정합성에 기반한다.
- 테스트가 `성장 확인 필요` 문구에 의존하므로, 나중에 UX 문구를 바꾸면 테스트도 함께 갱신해야 한다.

## Next Work Order

다음 구현 순서는 `docs/STORY_PLAN_AFTER_TUTORIAL_2026-07-08.md` 기준으로 3번 묶음에 들어가면 된다.

1. DAY 05 원정 후 첫 반응 구현.
   - DAY 04 원정 결과가 DAY 05 방어전/대사에 자연스럽게 이어지게 한다.
   - 밀로가 길을 잃었다는 짧은 반응을 넣는다.

2. DAY 06 니아 재등장 이벤트.
   - 보안 평점과 보물 손실/방어 결과를 다시 보여준다.
   - 도둑 위협 연출은 `docs/TUTORIAL_QA_REPORT_2026-07-08.md`의 P2 항목도 참고한다.

3. DAY 07 첫 시설 업그레이드 상담.
   - 골딘 비용 대사와 바티 추천 대사를 넣는다.
   - 시설 1개 강화 저장까지 작은 범위로 마무리한다.

4. 계속 검증.
   - 각 묶음 종료 시 자동 테스트를 돌린다.
   - 작업 종료 후 검수 에이전트 리뷰를 받고 지적 사항을 반영한다.

## Exact Start Sentence For Next Session

> 최신 튜토리얼 P1 마감 핸드오프를 읽었습니다. DAY 01~04 기준 검증과 P1 보완은 끝났고, 다음 목표는 DAY 05~07을 작은 묶음으로 구현해 원정 결과 반응, 니아 재등장, 첫 시설 업그레이드 상담까지 연결하는 것입니다.
