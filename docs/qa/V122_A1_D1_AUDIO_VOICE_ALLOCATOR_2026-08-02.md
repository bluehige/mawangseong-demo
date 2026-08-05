# v1.2.2 A1-D1 효과음 voice allocator·catalog API 계약

검수일: 2026-08-02
대상 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

한꺼번에 발생하는 일회성 효과음의 동시 재생 예산과 우선순위 보호 규칙, 오디오 event·asset을 실제 runtime 파일까지 확인하는 읽기 전용 catalog API만 고정했다. 기존 GameRoot·CombatSceneController·HUD 호출 이관, 새 음원 생성·승격, 전체 출시 검수와 빌드는 이 패킷 범위가 아니다.

## 변경 내용

- `scripts/audio/AudioVoiceAllocator.gd`를 추가했다.
  - global one-shot 최대 24
  - 같은 일반 event 최대 4
  - UI 최대 2
  - 발소리 최대 3
  - 우선순위는 중요 경보·보스 모티프(400), UI 확정(300), 고유 스킬·피격(200), 일반 타격(100), 발소리(50)로 비교한다.
  - 상한에 도달하면 요청보다 낮은 우선순위 중 가장 오래된 voice만 축출하고, 보호된 voice만 남은 경우 요청을 거부한다.
- `scripts/audio/AudioCatalogApi.gd`를 추가했다.
  - event ID와 asset ID를 각각 찾고, event↔asset 연결·runtime 상태·버스·실제 파일 존재를 함께 확인한다.
  - 미등록 event·asset, data-only asset, 연결 불일치는 `AUDIO_CATALOG_*` 진단 로그를 남기고 해석을 거부한다.
- `tools/tests/AudioVoiceAllocatorTest.gd/.tscn`을 추가해 두 계약을 하나의 직접 테스트 입구로 묶었다.

## 검증 결과

- `godot --headless --path . --scene res://tools/tests/AudioVoiceAllocatorTest.tscn --quit-after 1200`: 55/55 PASS
  - global·일반 event·UI·발소리 상한
  - 우선순위 보호, 가장 오래된 낮은 우선순위 축출, release
  - 정상 event·runtime asset·data-only·미등록 ID 진단
- `python -m unittest tools.audio.test_audio_event_catalog -q`: 6/6 PASS
- `python -m json.tool data/audio/audio_event_catalog.json`: PASS
- `git diff --check`: PASS (기존 파일의 CRLF 변환 안내만 출력)
- 전체 회귀, 전체 플레이, Windows export와 빌드는 실행하지 않았다.

Related tests: `AudioVoiceAllocatorTest.tscn` 55/55 PASS; `tools.audio.test_audio_event_catalog` 6/6 PASS.
UI check: UI 배치는 변경하지 않았고 allocator·catalog는 headless 계약만 확인했다. 1280×720 화면 검수는 이 패킷 범위에서 실행하지 않았다.
Unresolved issues: 현재 실제 SFX 호출은 아직 allocator를 거치지 않는다. GameRoot·Update 3/4 routing은 A1-D2, CombatSceneController·HUD 이관은 A1-D3, 실제 소유자 청취와 새 음원 승격은 후속 게이트다.
