# v1.2.2 A4 Stage 01 환경 loop 준비 감사

검수일: 2026-08-05
대상 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
패킷: `A4-STAGE-01-LOOP-READINESS-AUDIT`

## 목적

Stage 01(`stage_01_cave`) 환경 loop 한 개를 실제 생성하거나 연결하지 않고, 현재 출처·승격 전제와 Ambience 연결 준비 상태만 읽기 전용으로 확인했다.

## 직접 실행

```text
godot.cmd --path . --scene res://tmp/v122_release_polish/i1_6_stage_audio/I1StageAudioGapAudit.tscn --quit-after 600
```

실행 환경은 Godot `4.5.2`, Vulkan, NVIDIA GeForce RTX 3060 Ti이다.

결과:

```text
PASS: Stage 01~04 성 단계 식별자가 순서대로 존재
PASS: 현재 오디오 버스 기준선 확인
PASS: 발 접촉 scheduler가 아직 연결되지 않은 공백을 확인
I1_6_STAGE_AUDIO_GAP_AUDIT: assertions=4, failures=1
ERROR: FAIL: 환경음 전용 버스가 아직 연결되지 않은 공백을 확인
```

기계 inventory에는 Stage ID 4개, 환경 자산 0개, 발소리 자산 0개, `footstep_scheduler_present=false`, `gap_count=9`가 기록됐다. 런타임 버스에는 현재 `Master / Music / SFX / UI / Ambience`가 존재하며 `Ambience`는 SFX로 전송된다.

## 원인과 판정

실패한 한 단언은 `I1StageAudioGapAudit.gd`가 Ambience 버스가 **없어야 한다**고 검사하는 오래된 감사 조건이다. 현재 `scripts/core/AudioSettings.gd`에는 `AMBIENCE_BUS`와 `Ambience → SFX` 라우팅이 이미 존재하므로, 이 실패는 Stage 01 loop가 준비됐다는 뜻이 아니라 테스트가 현재 코드 상태를 따라가지 못한다는 뜻이다.

A0 manifest의 76개 자산과 68개 이벤트에는 `stage_01_cave` 환경 loop나 발소리 자산이 없고, 실제 Stage 01 loop 파일도 없다. 출처·생성 비용·사람 청취 승인·런타임 연결은 여전히 미완료다.

## 결과

`A4_STAGE01_LOOP_READINESS_BLOCKED_STALE_ASSERTION`

직접 테스트가 실패했으므로 이 패킷은 완료 처리하지 않는다. 이번 범위에서 허용되지 않은 테스트 파일·제품 코드·데이터·자산을 수정하지 않았다. 오디오 생성·승격·청취·빌드·커밋·푸시는 실행하지 않았다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_BLOCKED`
