# v1.2.2 A4 Stage 01 감사 테스트 조건 정렬

검수일: 2026-08-05
대상 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
패킷: `A4-STAGE-01-AUDIT-TEST-ALIGNMENT`

## 목적

앞선 감사에서 현재 코드에 이미 존재하는 `Ambience` 버스를 없다고 판정하던 오래된 단언을 현재 오디오 라우팅 계약에 맞게 정렬했다. Stage 01 환경 loop나 발소리 자산을 만들거나 연결하는 작업은 포함하지 않았다.

## 실제 변경

허용된 임시 감사 장면에서 한 단언만 변경했다.

- `tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.gd`
- 이전: `Ambience` 버스가 없어야 통과
- 현재: 런타임 `Ambience` 버스와 `Ambience → SFX` 코드 계약이 있어야 통과

## 직접 테스트

```text
godot.cmd --path . --scene res://tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.tscn --quit-after 600
```

실행 환경은 Godot `4.5.2`, Vulkan, NVIDIA GeForce RTX 3060 Ti이다.

```text
PASS: Stage 01~04 성 단계 식별자가 순서대로 존재
PASS: 현재 오디오 버스 기준선 확인
PASS: 환경음 전용 버스가 현재 연결된 상태를 확인
PASS: 발 접촉 scheduler가 아직 연결되지 않은 공백을 확인
I1_6_STAGE_AUDIO_GAP_AUDIT: assertions=4, failures=0
```

기계 결과는 `Ambience` 버스 존재, 환경 자산 0개, 발소리 자산 0개, `footstep_scheduler_present=false`, `gap_count=9`를 기록했다.

## 결과와 제한

`A4_STAGE01_AUDIT_TEST_ALIGNMENT_PASS`

감사 테스트 조건은 현재 상태와 일치한다. 그러나 이것은 자산 준비 완료 판정이 아니다. Stage 01 환경 loop 출처·생성·승격·사람 청취·런타임 event 연결은 아직 남아 있으며, 이번 패킷에서는 코드·데이터·manifest·오디오 자산·제품 런타임을 수정하지 않았다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
