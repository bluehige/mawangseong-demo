# v1.2.2 출시 마무리 A1-E 오디오 suite 등록 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

A1 오디오 기반 작업의 마지막 패킷으로, 버스·BGM·voice budget·Update 3/4 routing·전투/HUD routing 테스트 5개를 핵심 검증 suite의 `quick`과 `full`에 등록했다. suite가 기존 콘텐츠 check를 잃지 않았는지는 `V122ContentCompatibilityTest`로 확인했고, 새로 등록한 입구도 하나씩 직접 실행했다.

## 변경 파일

- `tools/tests/core_verification_suite.json`
- `docs/qa/V122_A1_E_AUDIO_SUITE_REGISTRATION_2026-08-02.md`
- `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md`
- `docs/handoff/CURRENT.md`

## 코드·데이터·사운드·그래픽 변경

- 코드·데이터·사운드·그래픽은 추가 변경하지 않았다.
- suite JSON에만 5개 오디오 check와 실행 scene 경로를 명시했다.

## 검증

suite coverage 85/85·499 assertions, 등록 오디오 입구 5개 226 assertions, Python catalog 6개와 JSON 문법 검사를 통과했다. Quick/Full 전체 검증과 출시 빌드는 실행하지 않았다.

Related tests: `V122ContentCompatibilityTest.tscn` 499/499 PASS; `AudioBusContractTest.tscn` 9/9 PASS; `MusicStateAudioTest.tscn` 27/27 PASS; `AudioVoiceAllocatorTest.tscn` 55/55 PASS; `SkillAudioPaletteTest.tscn` 126/126 PASS; `CombatAudioDirectorRoutingTest.tscn` 9/9 PASS; `tools.audio.test_audio_event_catalog` 6/6 PASS.
UI check: suite 등록만 수행해 화면·레이아웃은 변경하지 않았다. 1280×720 OWNER 화면 확인은 남아 있다.
Unresolved issues: 새 오디오 자산 생성·승격과 실제 청취·권리 승인, 전체 Quick/Full 검증, C1 피해·소리·VFX 접촉 동기화와 A2~A5 후속 패킷은 아직 진행하지 않았다.

## 다음 작업

1. 계획의 C1에서 피해·타격음·VFX·피격 동작을 같은 접촉 사건으로 묶는다.
2. 이후 V5 VFX catalog, A2 기본 타격·UI음, A3 BGM 확장, A4 환경음·발소리, A5 최종 믹스를 순서대로 진행한다.
3. 사용자가 실제 청취·화면 검수를 요청하기 전까지 Quick/Full 전체 검증과 출시 빌드는 보류한다.

## 작업 트리·Git

- 이번 핸드오프에서는 stage·commit·push·PR을 실행하지 않았다.
- 기존 사용자 `.import`, `V122ResultUISimplificationTest.gd`, `.uid` 변경은 건드리지 않았다.
- 현재 변경은 작업 트리에만 있다.
