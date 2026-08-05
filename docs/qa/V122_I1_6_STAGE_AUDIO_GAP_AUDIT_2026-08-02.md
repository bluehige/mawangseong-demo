# v1.2.2 I1-6 Stage 01~04 환경음·발소리 공백 감사

검수일: 2026-08-02
대상 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

I1 통합 대표 검수의 여섯 번째 패킷으로 Stage 01~04 식별자와 현재 환경음·발소리 연결 공백을 읽기 전용으로 확인했다. 새 음원을 만들거나 임시 파일을 런타임 자산처럼 연결하지 않았다.

## 실행 방법

- 임시 감사 장면: `tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.tscn`
- 명령: `godot --path . --scene res://tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.tscn --quit-after 600`
- 기계 결과: `tmp/v122_release_polish/i1_6_stage_audio/i1_6_inventory.json`
- 실행 로그: `tmp/v122_release_polish/i1_6_stage_audio/i1_6_capture.log`

## 확인 결과

- Stage ID `stage_01_cave`, `stage_02_castle`, `stage_03_keep`, `stage_04_citadel` 순서를 확인했다.
- 현재 오디오 버스는 `Master`, `Music`, `SFX` 세 개뿐이며 `Ambience` 버스가 없다.
- Stage 01~04 환경 loop 후보 4개가 아직 없다.
- 거친 동굴석·성벽석·금속 통로 발소리 후보와 normal/heavy 프로필 연결이 아직 없다.
- 발 접촉 scheduler와 환경음 라우터가 아직 없다.
- 총 공백 10건(환경 자산 4, 발소리 자산 4, 버스·scheduler 2)을 고정했다.

이 결과는 제품 결함을 새로 만든 것이 아니라 F0-A와 계획서에 기록된 출시 공백을 I1 대표 순서에서 재확인한 것이다. 음원 생성·승격은 A0 manifest와 출처 승인 뒤 A4에서 수행해야 한다.

참고로 기존 v0.5 Lyria 파이프라인 12개 단위 테스트와 비용 없는 `plan` 명령은 PASS했지만, 이는 v1.2.2 manifest가 생겼다는 뜻이 아니다. 기존 v0.5 manifest와 출처 기록은 보존한다.

Related tests: I1StageAudioGapAudit 4 baseline assertions 실행 완료; `tools/audio/test_lyria_pipeline.py` 12 tests PASS; Stage ID 순서·현재 버스·환경음 버스 부재·발 scheduler 부재를 확인했다(제품 기능 PASS가 아닌 AUDIT_ONLY).
UI check: 이번 패킷은 화면을 바꾸지 않는 오디오 공백 감사라 대표 캡처를 만들지 않았다. Stage 식별자는 DataRegistry 기준으로 읽었다.
Unresolved issues: A0 v1.2.2 audio manifest·출처 승인, A1 Ambience 버스·라우터, A4 Stage 환경 loop 4개와 재질·무게 발소리 생성·연결이 남아 있다.
