# V1.2.2 출시 마무리 I1-3 핸드오프 — DAY 3 도둑·집중·혼잡 타격

- 목표 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 커밋하지 않음)
- 상태: `TARGETED_PASS_WITH_OWNER_PLAY_PENDING`

## 완료한 내용

- DAY 3·도둑 사냥꾼 특성을 적용한 실제 runtime 전투 화면을 만들었다.
- 일반 탐험가보다 도둑을 집중 대상으로 선택하고, 선택 대상 instance가 AI에 보존되는지 확인했다.
- 더 가까운 일반 탐험가가 있어도 기본 공격이 도둑에게만 들어가는 것을 확인했다(도둑 `-21`, 탐험가 `0`).
- 집중 대상 선택·공격 직후 `1280×720` 캡처를 남겼다.
- 기존 전투 우선순위·명령 버튼 통합 테스트를 다시 실행해 PASS했다.
- 런타임 코드·데이터·자산·빌드는 수정하지 않았다.

## 변경 파일

- 추가: `docs/qa/V122_I1_3_DAY3_THIEF_FOCUS_REPRESENTATIVE_2026-08-02.md`
- 추가: `docs/handoff/V122_RELEASE_POLISH_I1_3_DAY3_THIEF_FOCUS_REPRESENTATIVE_2026-08-02.md`
- 임시·무추적: `tmp/v122_release_polish/i1_3_day3_focus/I1Day3FocusRepresentative.gd`, `.tscn`, 캡처 PNG 2장, 인벤토리 JSON, 실행 로그

## 다음 작업

1. I1-4 후반 일반 전투 대표 검수
2. 사용자 실제 DAY 3 체감 확인은 자동 PASS와 별도 OWNER 항목으로 유지
3. 우선순위 로직은 이번 패킷에서 다시 고치지 않음. 새 실패가 나오면 해당 상황만 별도 재현 패킷으로 분리

## 검수와 미해결

Related tests: `I1Day3FocusRepresentative` 7 assertions PASS; `V122DefenderConnectorTest` PASS; `V122CommandButtonIntegrationTest` PASS.

UI check: DAY 3 집중 대상·공격 직후 실제 `1280×720` 캡처 2장 PASS.

Unresolved issues: 실제 DAY 3 OWNER 플레이·도둑 사냥꾼 체감·결산 문구 대기, Q1-R 오디오 manifest·권리 gate, I1-2 UI 전용 효과음 공백.

## 작업 트리와 원격

- 기존 사용자 변경 `.import` 6개와 `.uid` 7개를 건드리지 않았다.
- I1-3 문서와 계획/CURRENT 갱신은 아직 커밋하지 않았다.
- 원격 푸시는 하지 않았다.
