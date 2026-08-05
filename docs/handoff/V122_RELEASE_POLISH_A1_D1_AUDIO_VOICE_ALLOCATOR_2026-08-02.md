# v1.2.2 출시 마무리 A1-D1 효과음 voice allocator·catalog API 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

일회성 효과음 동시 재생을 위한 순수 예산 관리자와 오디오 catalog 해석 API를 추가했다. allocator는 실제 플레이어를 만들지 않고 승인·축출 결과만 반환하므로 다음 패킷에서 GameRoot와 전투 호출이 같은 규칙을 사용할 수 있다. catalog API는 event와 asset의 연결, runtime 상태, 버스, 실제 파일을 확인하고 미해결 대상을 진단 로그로 남긴다.

변경 파일:

- `scripts/audio/AudioVoiceAllocator.gd`
- `scripts/audio/AudioCatalogApi.gd`
- `tools/tests/AudioVoiceAllocatorTest.gd`
- `tools/tests/AudioVoiceAllocatorTest.tscn`
- `docs/qa/V122_A1_D1_AUDIO_VOICE_ALLOCATOR_2026-08-02.md`
- `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md`
- `docs/handoff/CURRENT.md`

## 검증

직접 Godot 테스트 55 assertions와 기존 Python catalog 테스트 6개, JSON 문법 검사를 통과했다. 미등록 ID를 의도적으로 조회하는 테스트에서는 `AUDIO_CATALOG_MISSING_*` 진단 로그가 발생하며, 테스트는 빈 해석 결과를 확인해 조용한 폴백이 없음을 검증한다.

Related tests: `AudioVoiceAllocatorTest.tscn` 55/55 PASS; `python -m unittest tools.audio.test_audio_event_catalog -q` 6/6 PASS.
UI check: 화면·레이아웃 변경 없음. headless 계약만 확인했으며 1280×720 OWNER 화면 검수는 남아 있다.
Unresolved issues: 기존 GameRoot·CombatSceneController·HUD의 실제 AudioStreamPlayer 생성은 아직 이전 경로다. A1-D2에서 GameRoot·Update 3/4를 연결하고 A1-D3에서 전투·HUD를 이관해야 한다. A4 환경음·발소리와 새 음원 승격, 소유자 청취도 대기 중이다.

## 다음 작업

1. A1-D2에서 GameRoot 및 Update 3/4 사건을 catalog·AudioDirector 경로로 연결한다.
2. A1-D3에서 전투·HUD의 하드코딩 SFX를 allocator와 공통 catalog 경로로 이관한다.
3. A1-E에서 직접 통과한 테스트를 핵심 검증 suite에 등록한다.

## Git 상태

- 이번 핸드오프에서는 stage·commit·push·PR을 실행하지 않았다.
- 사용자가 남긴 기존 `.import`, `V122ResultUISimplificationTest.gd`, `.uid` 변경은 건드리지 않았다.
