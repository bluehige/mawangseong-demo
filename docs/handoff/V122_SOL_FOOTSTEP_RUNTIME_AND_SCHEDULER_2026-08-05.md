# v1.2.2 SOL 발소리 runtime·scheduler 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 미실행
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 사용자가 전체 승인한 발소리 9개를 제품 source/runtime로 승격한다.
- manifest·catalog·런타임 호출을 원자적으로 연결한다.
- normal/heavy, 정지·비행 무음, 동시 voice 3개, x3 밀도 감소를 직접 검증한다.

## 3. 완료한 작업

- Windows BOM 메타데이터와 신규 runtime 하위 폴더를 처리하도록 Lyria 승격 파이프라인을 보강했다.
- 파생 clip의 source reel asset·run·anchor seconds를 `SOURCE.md`에 기록했다.
- 승인 9개를 `assets/audio/sfx/footsteps/`와 `assets/source/audio/lyria/v1.2.2/footstep_*/`에 승격했다.
- manifest 9개를 `active`, catalog 9개를 `approved`·`actual_runtime`으로 전환하고 event 9개를 추가했다.
- 중앙 `FootstepScheduler`를 GameRoot에 연결해 Stage surface·체급·이동·화면·배속 조건을 적용했다.
- 새 직접 테스트를 quick/full suite에 등록했다.

## 4. 주요 변경 경로

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/audio/lyria_pipeline.py` | BOM·runtime 폴더·파생 lineage | 완료 |
| `tools/audio/lyria_v122_manifest.json` | 발소리 9개 active | 완료 |
| `data/audio/audio_event_catalog.json` | 발소리 9 assets/events 연결 | 완료 |
| `scripts/audio/FootstepScheduler.gd` | Stage·weight·배속 scheduler | 완료 |
| `scripts/game/GameRoot.gd` | runtime scheduler 소유·호출 | 완료 |
| `tools/tests/FootstepSchedulerTest.gd/.tscn` | 31개 직접 계약 | 완료 |
| `assets/audio/sfx/footsteps/` | 승인 runtime WAV 9개 | 완료 |
| `assets/source/audio/lyria/v1.2.2/footstep_*/` | source·generation·SOURCE 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음
- 오디오 생성 모델: `lyria-3-clip-preview`
- 생성 원본: 승인된 source reel 4개를 9개 source 디렉터리에 lineage와 함께 보존
- 런타임: mono 44.1kHz 16bit WAV 9개
- 게임 연결: Stage 01 동굴석, Stage 02/03 성벽석, Stage 04 금속 통로
- 실제 청취: 표면별 review WAV 3개 사용자 `전체 승인`

## 6. 테스트 및 검수

| 순서 | 검수 | 결과 |
|---:|---|---|
| 1 | Lyria pipeline | PASS, 19 tests |
| 2 | manifest validate | PASS, 89 assets |
| 3 | event catalog | PASS, 11 tests |
| 4 | FootstepScheduler | PASS, 31 assertions |
| 5 | MusicStateAudio | PASS, 54 assertions |
| 6 | AudioVoiceAllocator | PASS, 55 assertions |
| 7 | CombatAudioDirectorRouting | PASS, 9 assertions |
| 8 | 전체 회귀 | 아직 미실행 — 최종 기능 SHA 단계에서 수행 |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 작업 트리는 기존 Luna·사용자 변경과 섞여 있으며 아직 출시 승인 SHA가 아니다.
- 발소리 개별 청취는 승인됐지만 최종 BGM·타격·UI·환경음과의 장시간 mix gate는 A5/I2에 남아 있다.
- 정식 Full·Windows export·hash는 기능 동결 뒤 수행해야 한다.

## 8. 다음 작업 순서

1. 발소리 완료 상태를 CURRENT와 출시 오디오 인벤토리에 반영한다.
2. A2 기본 타격·핵심 UI음과 A3 6상태 BGM의 실제 미완료 범위·생성 비용을 고정한다.
3. 비용 승인 전 가능한 Q1-L P3, Q1-S 계약, 오디오 review 상태·출처 정렬을 처리한다.
4. 다음 유료 생성 범위가 필요하면 호출 수·최대 비용·묶음 청취 파일을 한 번에 제시한다.

## 9. 작업 트리 상태

- 커밋·푸시·PR·태그·Release: 미실행
- 기존 혼합 변경: 보존
- 임시 후보·Godot 로그: `tmp/`, Git 무시
- 빌드 산출물: 생성하지 않음

## 10. 종료 체크리스트

- [x] 사용자 묶음 승인 기록
- [x] source/runtime 승격
- [x] manifest·catalog 연결
- [x] scheduler·직접 테스트
- [x] QA·핸드오프
- [ ] 전체 기능 동결
- [ ] Full·Windows 정식 후보
