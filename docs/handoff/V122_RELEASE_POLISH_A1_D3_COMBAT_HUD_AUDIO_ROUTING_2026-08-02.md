# v1.2.2 출시 마무리 A1-D3 전투·HUD AudioDirector 라우팅 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

전투에서 자주 발생하는 일반 타격·피격·스킬 효과음과 상층 숨은 층 경보를 공통 `AudioDirector`로 이관했다. 파일 경로를 직접 여는 코드는 제거하고, catalog asset ID와 event ID를 통해 voice 예산·버스·종료 수명을 일관되게 사용한다. 기존 전투 cooldown과 pitch 변형, HUD 경보의 반복 표시 동작은 유지했다.

## 변경 파일

- `scripts/game/CombatSceneController.gd`
- `scenes/ui/hud/MultiFloorHUD.gd`
- `scripts/game/GameRoot.gd`
- `scripts/audio/AudioDirector.gd`
- `tools/tests/CombatAudioDirectorRoutingTest.gd`
- `tools/tests/CombatAudioDirectorRoutingTest.tscn`
- `docs/qa/V122_A1_D3_COMBAT_HUD_AUDIO_ROUTING_2026-08-02.md`
- `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md`
- `docs/handoff/CURRENT.md`

## 코드·데이터·사운드·그래픽 변경

- 코드: CombatSceneController와 MultiFloorHUD의 직접 AudioStreamPlayer 생성을 AudioDirector 호출로 교체했다.
- 데이터: 기존 combat·skill·floor alert event를 그대로 사용했으며 catalog JSON의 사건 수는 변경하지 않았다.
- 사운드: 새 WAV 생성·교체 없음. 기존 음원은 같은 버스와 volume/pitch 계약으로 재생된다.
- 그래픽: 변경하지 않았다.

## 검증

전투·HUD 직접 라우팅 9 assertions, A1-D2 routing 126 assertions, voice allocator 55 assertions, 버스 9 assertions, BGM 27 assertions, Python catalog 6개와 JSON 검사를 통과했다. 전체 회귀·전체 플레이·출시 빌드는 실행하지 않았다.

Related tests: `CombatAudioDirectorRoutingTest.tscn` 9/9 PASS; `SkillAudioPaletteTest.tscn` 126/126 PASS; `AudioVoiceAllocatorTest.tscn` 55/55 PASS; `AudioBusContractTest.tscn` 9/9 PASS; `MusicStateAudioTest.tscn` 27/27 PASS; `tools.audio.test_audio_event_catalog` 6/6 PASS.
UI check: HUD 문구·배치는 변경하지 않았고 headless 음성 수명만 확인했다. 1280×720 OWNER 화면 확인은 남아 있다.
Unresolved issues: A1-E에서 테스트 suite를 등록해야 하며 새 음원 승격, 실제 소유자 청취, 전체 출시 후보 검수와 빌드는 아직 하지 않았다.

## 다음 작업

1. A1-E에서 A1-A~D3 직접 테스트를 `core_verification_suite.json`에 등록하고 각 입구만 한 번 확인한다.
2. 이후 C1 피해·소리·VFX 접촉 동기화와 A2~A5 오디오 자산·믹스 패킷을 계획 순서대로 진행한다.

## 작업 트리·Git

- 이번 핸드오프에서는 stage·commit·push·PR을 실행하지 않았다.
- 사용자가 남긴 기존 `.import`, `V122ResultUISimplificationTest.gd`, `.uid` 변경은 건드리지 않았다.
- 새 변경은 작업 트리에만 있으며 다음 세션에서 의도한 파일만 명시적으로 검토한다.
