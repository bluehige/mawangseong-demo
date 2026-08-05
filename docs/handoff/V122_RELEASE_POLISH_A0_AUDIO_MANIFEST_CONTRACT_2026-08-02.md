# v1.2.2 출시 마무리 A0 오디오 manifest·승격 계약 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

v0.5 오디오 생성·출처 기록을 건드리지 않고 v1.2.2 전용 manifest를 분리했다. 현재 런타임 WAV 76개를 그대로 선언하고, 향후 source root와 생성 승인 정책을 명시했다.

- `tools/audio/lyria_v122_manifest.json` 추가
- v0.5 manifest는 불변으로 유지
- `assets/audio/bgm/SOURCE.md`의 잘못된 procedural 30초 provenance를 deprecated 처리
- 현재 `combat_dungeon_pressure` runtime 116.909초와 v0.5 render contract 120초 차이를 A1 loop 검증으로 분리
- 비용 없는 validate/plan만 실행

## 결과와 파일

- QA 보고서: `docs/qa/V122_A0_AUDIO_MANIFEST_CONTRACT_2026-08-02.md`
- 신규 manifest: `tools/audio/lyria_v122_manifest.json`
- 실행 결과: `tmp/v122_release_polish/i1_6_stage_audio/lyria_v122_json_check.log`, `lyria_plan_v05.log`
- 기존 v0.5 source record와 manifest는 수정하지 않음

Related tests: v1.2.2 manifest validate PASS(76 assets); plan PASS(estimated `$6.32`); JSON syntax PASS.
UI check: 화면·런타임 동작은 변경하지 않았고 manifest·source 문서 계약만 확인했다.
Unresolved issues: 유료 생성·후보 승격·A1 loop/bus/catalog·A4 Stage 환경음/발소리는 사용자 승인과 별도 패킷이 필요하다.

## 다음 작업

다음은 A1 오디오 기반이다. `Ambience` 버스, asset/event catalog, loop transport, voice cap을 작은 계약 단위로 만들되 실제 새 음원 생성·승격은 별도 승인 전까지 실행하지 않는다.

## Git 상태

- 커밋·푸시: 수행하지 않음
- 기존 사용자 변경과 이전 패킷 문서를 보존함
