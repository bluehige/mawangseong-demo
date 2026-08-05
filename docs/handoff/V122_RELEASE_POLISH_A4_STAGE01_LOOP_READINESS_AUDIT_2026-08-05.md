# v1.2.2 A4 Stage 01 환경 loop 준비 감사 핸드오프

## 1. 메타데이터

- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (문서 변경은 미커밋)
- 패킷: `A4-STAGE-01-LOOP-READINESS-AUDIT`
- 결과: `A4_STAGE01_LOOP_READINESS_BLOCKED_STALE_ASSERTION`
- QA: `docs/qa/V122_A4_STAGE01_LOOP_READINESS_AUDIT_2026-08-05.md`

## 2. 확인 내용

Stage 01 식별자와 A0 manifest를 읽고 기존 `I1StageAudioGapAudit` 장면을 한 번 실행했다. Stage 01 환경 loop와 발소리 런타임 파일은 없었고, `Ambience` 버스와 `Ambience → SFX` 라우팅은 이미 존재했다. 발 접촉 scheduler와 Stage 환경음 event 연결은 아직 없다.

## 3. 직접 테스트

```text
godot.cmd --path . --scene res://tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.tscn --quit-after 600
I1_6_STAGE_AUDIO_GAP_AUDIT: assertions=4, failures=1
```

실패 원인은 제품 기능이 아니라 감사 장면의 낡은 기대값이다. 감사 코드가 `Ambience` 버스가 없어야 한다고 단언하지만 현재 `AudioSettings.gd`가 해당 버스를 생성하므로, 현재 상태를 정확히 판정하려면 테스트 조건을 먼저 맞춰야 한다.

## 4. 실제 변경 경로

- `docs/qa/V122_A4_STAGE01_LOOP_READINESS_AUDIT_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_READINESS_AUDIT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

코드·데이터·그래픽·오디오 자산은 변경하지 않았다.

## 5. 미해결 및 다음 패킷

- Stage 01 환경 loop 생성·출처 문서·승격·실제 청취·런타임 event 연결은 남아 있다.
- 현재 패킷은 직접 테스트 실패로 완료하지 않는다.
- 다음 단일 패킷은 `A4-STAGE-01-AUDIT-TEST-ALIGNMENT`로 제안한다. 기존 임시 감사 장면의 Ambience 단언을 현재 라우팅 계약에 맞게 정렬한 뒤 같은 장면을 한 번 재실행한다. 제품 오디오 코드·manifest·자산·런타임 연결은 건드리지 않는다.

## 6. 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_BLOCKED`
- 커밋·푸시·빌드: 수행하지 않음
- 작업 트리: 기존 사용자·Luna 미커밋 변경을 보존함
