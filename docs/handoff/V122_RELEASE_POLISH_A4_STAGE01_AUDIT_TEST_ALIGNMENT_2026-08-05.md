# v1.2.2 A4 Stage 01 감사 테스트 조건 정렬 핸드오프

## 1. 메타데이터

- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (문서·임시 테스트 변경은 미커밋)
- 패킷: `A4-STAGE-01-AUDIT-TEST-ALIGNMENT`
- 결과: `A4_STAGE01_AUDIT_TEST_ALIGNMENT_PASS`
- QA: `docs/qa/V122_A4_STAGE01_AUDIT_TEST_ALIGNMENT_2026-08-05.md`

## 2. 완료 내용

`I1StageAudioGapAudit.gd`의 낡은 Ambience 부재 단언 한 곳을 현재 `Ambience → SFX` 라우팅 계약에 맞게 정렬했다. 같은 감사 장면을 한 번 실행해 4개 단언·실패 0건을 확인했다.

현재 상태는 다음과 같다.

- Stage ID `stage_01_cave` 포함 01~04 순서: 확인
- 런타임 오디오 버스 `Master / Music / SFX / UI / Ambience`: 확인
- Stage 01 환경 loop 파일: 없음
- 발소리 파일과 발 접촉 scheduler: 없음
- 환경음·발소리 event 연결: 없음

## 3. 직접 테스트

```text
godot.cmd --path . --scene res://tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.tscn --quit-after 600
I1_6_STAGE_AUDIO_GAP_AUDIT: assertions=4, failures=0
```

## 4. 실제 변경 경로

- `tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.gd`
- `docs/qa/V122_A4_STAGE01_AUDIT_TEST_ALIGNMENT_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_AUDIT_TEST_ALIGNMENT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

제품 코드·데이터·manifest·오디오 자산·런타임 연결은 변경하지 않았다.

## 5. 미해결 및 다음 패킷

- Stage 01 환경 loop의 출처·생성 비용·승격·실제 청취·런타임 연결이 남아 있다.
- 다음 단일 패킷은 `A4-STAGE-01-LOOP-SOURCE-AUTHORIZATION-GATE`로 제안한다. Stage 01 loop 한 개의 manifest 등록·출처 문서·승인 전제만 읽기 전용으로 확인하고, 실제 생성·승격·런타임 연결은 하지 않는다.

## 6. 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
- 커밋·푸시·빌드: 수행하지 않음
- 작업 트리: 기존 사용자·Luna 미커밋 변경을 보존함
