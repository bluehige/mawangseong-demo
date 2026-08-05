# v1.2.2 출시 마무리 V4-B UI 앵커 계약 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `V4-B-02-UI-ANCHOR-CONTRACT`
QA: `docs/qa/V122_V4_B_UI_ANCHOR_CONTRACT_2026-08-05.md`

## 완료 내용

V4-B-01 조사에서 확인한 고정 오프셋 문제를 공통 앵커 계약으로 좁혀 구현했다. 유닛 root를 발(`foot`) 기준으로 유지하고, 프로필로 계산한 몸(`body`) 위치와 프레임 높이로 머리(`head`) 기준점을 만든다. 이름·HP·피해 숫자는 모두 `head`를 소비하므로 캐릭터별 크기와 포즈가 바뀌어도 서로 다른 유닛 원점 오프셋을 다시 만들지 않는다.

## 실제 변경 경로

- `scripts/units/Unit.gd`
- `scripts/game/CombatSceneController.gd`
- `tools/tests/V122V4BUIAnchorContractTest.gd`
- `docs/qa/V122_V4_B_UI_ANCHOR_CONTRACT_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V4_B_UI_ANCHOR_CONTRACT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 실행한 직접 테스트

- `godot.cmd --headless --path . --check-only --quit` — PASS
- `godot.cmd --headless --path . --script tools/tests/V122V4BUIAnchorContractTest.gd --quit-after 30` — `PASS (12 checks)`

화면 캡처, 전체 회귀, 빌드, 오디오 청취는 사용자 요청 범위를 넘어 이번 패킷에서 실행하지 않았다.

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드: Unit UI 앵커 계산과 CombatSceneController 피해 숫자 소비 경로만 수정했다.
- 데이터/스토리/밸런스: 변경 없음.
- 그래픽 자산/VFX/오디오: 변경 없음.

## 미해결 문제와 다음 작업 순서

- 실제 N/E/S/W 전면 벽 뒤에서 Unit과 ground/body/aerial VFX가 함께 가려지는 화면 검수는 남아 있다.
- 대표 1280×720 화면에서 이름·HP·피해 숫자 간격을 확인하는 후속 시각 검수가 필요하다.
- 다음 제안 패킷은 계획 순서를 지키기 위한 `A0-AUDIO-MANIFEST-CONTRACT` 재검증이다. 이번 turn에는 시작하지 않는다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 보존했으며 이번 패킷에서 정리하거나 되돌리지 않았다.
- 커밋·푸시: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
