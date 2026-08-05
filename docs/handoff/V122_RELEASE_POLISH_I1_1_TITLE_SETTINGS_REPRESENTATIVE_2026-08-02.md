# V1.2.2 출시 마무리 I1-1 핸드오프 — 타이틀·설정 대표 검수

- 목표 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 커밋하지 않음)
- 상태: `TARGETED_PASS_WITH_OWNER_LISTENING_PENDING`

## 완료한 내용

- 실제 Godot 렌더링 환경에서 `1280×720` 타이틀 화면을 캡처했다.
- 타이틀에서 설정으로 이동하고 화면·오디오 카테고리를 전환하는 대표 흐름을 4 assertions로 확인했다.
- 화면·오디오 설정 캡처를 함께 남겨 사용자가 직접 확인할 수 있게 했다.
- `V122Stage10LocalizationTest` 42 assertions와 `V122ManagementUIContractTest`를 다시 실행해 현지화·설정 껍데기 계약을 확인했다.
- 런타임 코드·데이터·자산·빌드는 수정하지 않았다.

## 변경 파일

- 추가: `docs/qa/V122_I1_1_TITLE_SETTINGS_REPRESENTATIVE_2026-08-02.md`
- 추가: `docs/handoff/V122_RELEASE_POLISH_I1_1_TITLE_SETTINGS_REPRESENTATIVE_2026-08-02.md`
- 임시·무추적: `tmp/v122_release_polish/i1_1_title_settings/I1TitleSettingsRepresentative.gd`, `.tscn`, 캡처 PNG 3장, 인벤토리 JSON, 실행 로그

## 다음 작업

1. I1-2 관리 화면 BGM·UI음 대표 검수
2. 이후 계획 순서대로 I1-3 DAY 3 도둑·집중·혼잡 타격, I1-4 후반 일반 전투, I1-5 보스/최종전, I1-6 Stage 01~04 환경음·발소리를 각각 별도 패킷으로 실행
3. 각 패킷은 화면 1개 또는 청취 시나리오 1개만 판정하고, 사용자 OWNER 청취 전에는 전체 I1을 완료로 표시하지 않음

## 검수와 미해결

Related tests: `I1TitleSettingsRepresentative` 4 assertions PASS; `V122Stage10LocalizationTest` 42 assertions PASS; `V122ManagementUIContractTest` PASS.

UI check: 타이틀·화면 설정·오디오 설정을 실제 `1280×720`으로 캡처했고 모두 크기 PASS.

Unresolved issues: 헤드폰·일반 스피커 실제 청취와 실제 Windows 후보 조작은 OWNER 검수 대기. Q1-R의 오디오 manifest·출처 release gate도 유지.

## 작업 트리와 원격

- 기존 사용자 변경 `.import` 6개와 `.uid` 7개를 건드리지 않았다.
- I1-1 문서와 계획/CURRENT 갱신은 아직 커밋하지 않았다.
- 원격 푸시는 하지 않았다.
