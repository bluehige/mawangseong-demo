# v1.2.2 A4 발소리 출처·생성 범위 승인 gate

검사일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-FOOTSTEP-SOURCE-AUTHORIZATION-GATE`

## 목적

Stage 01~04 ambience loop 4개 연결·대표 청취가 완료된 뒤 남은 A4 발소리 범위를 읽기 전용으로 감사한다. 이번 패킷은 유료 Lyria 호출, manifest 등록, source/runtime 생성, catalog 연결, scheduler 구현을 하지 않고 첫 후보의 이름·품질 목표·예상 비용·승인 순서만 고정한다.

## 읽기 전용 감사 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| v1.2.2 Lyria manifest | 발소리 0개 | 전체 80개 중 `footstep_*`, `assets/audio/sfx/footsteps/`, `kind=footstep` 일치 0개 |
| audio event catalog | 발소리 자산 0개·event 0개 | 전체 80 assets/72 events에서 전용 발소리 항목 없음 |
| runtime 자산 | 0개 | `assets/audio/` 아래 전용 `footstep_*` 또는 `footsteps/` 파일 없음 |
| source 기록 | 0개 | `assets/source/audio/` 아래 전용 발소리 source 기록 없음 |
| 기존 환경 loop | 4개 완료 | Stage 01~04 ambience runtime·대표 화면·사용자 청취 승인 완료 |
| Lyria 짧은 cue 단가 | 요청당 `$0.04` | manifest의 `lyria-3-clip-preview.usd_per_request` |

`false_footprints.wav`는 스킬 효과음이며 보행 scheduler가 사용하는 바닥 발소리가 아니므로 발소리 자산으로 계산하지 않았다.

## 최대 품질 기준 범위

권위 계획 `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md`의 A4 계약을 기준으로 다음 범위를 제안한다.

- surface 3종: 거친 동굴석, 다듬은 성벽석, 금속·기계 통로
- surface별 변형 3개: 총 9개 짧은 cue
- weight 2종: `normal`, `heavy`
- `heavy`는 별도 바닥 음원을 다시 만드는 방식이 아니라 같은 surface cue에 저음·음량·간격 프로필을 적용한다.
- 정지 캐릭터는 재생하지 않고, 보이는 주요 유닛만 재생하며, 동시 발소리는 최대 3개다.
- x3에서는 재생 밀도를 줄여 타격·경고음을 덮지 않는다.

2026-08-02 I1-6 감사의 “발소리 후보 4개”는 당시 공백 수를 요약한 값이며 surface별 3변형과 weight 프로필을 구현할 수 있는 최종 자산 계약이 아니다. 최대 품질 마무리 기준은 위 9개 cue와 2개 weight 프로필로 고정한다.

## 첫 후보 계약

다음 생성 계열의 첫 자산은 아래 한 개로 제한한다.

| 필드 | 제안 값 |
|---|---|
| asset ID | `footstep_cave_rough_01` |
| runtime path | `assets/audio/sfx/footsteps/footstep_cave_rough_01.wav` |
| kind | `one_shot` |
| model | `lyria-3-clip-preview` |
| 채널·샘플레이트 | mono, 44.1kHz |
| 목표 길이 | 약 0.20~0.35초 |
| 방향 | 거친 동굴석 위의 가볍고 건조한 한 걸음, 짧은 돌가루 질감, 금속·목재·보컬·음악 없음 |
| 요청 수·예상 비용 | 1회, `$0.04` |

첫 manifest 패킷은 `planned` 계약만 등록하고 API를 호출하지 않는다. 그 다음 생성 패킷에서 사용자가 다시 승인한 경우에만 Lyria 요청 1회를 실행한다. 생성 뒤에는 실제 청취 승인, source/runtime 승격, catalog 연결, scheduler 연결을 서로 다른 소형 패킷으로 나눈다.

## 실행한 직접 확인

```text
PowerShell JSON 감사: tools/audio/lyria_v122_manifest.json
PowerShell JSON 감사: data/audio/audio_event_catalog.json
파일 감사: assets/audio, assets/source/audio
계획 계약 확인: docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md A4
```

결과: 발소리 manifest/catalog/runtime/source 항목 모두 0개. 이번 패킷에서 API 호출과 파일 생성은 0회다.

## 판정

`A4_FOOTSTEP_SOURCE_AUTHORIZATION_GATE_PASS_PENDING_MANIFEST_APPROVAL`

발소리 공백과 최대 품질 범위, 첫 후보, 요청당 예상 비용을 고정했다. 다음 `A4-FOOTSTEP-CAVE-ROUGH-01-MANIFEST-CONTRACT`는 사용자의 새 진행 승인 전 시작하지 않는다.

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 읽기 전용 감사와 문서 갱신, 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
