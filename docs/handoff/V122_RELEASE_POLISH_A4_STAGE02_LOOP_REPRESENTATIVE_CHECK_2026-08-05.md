# v1.2.2 A4 Stage 02 ambience 대표 확인 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK`
- 작업 결과: `A4_STAGE02_LOOP_REPRESENTATIVE_CHECK_PASS`

## 2. 이번 패킷 목표와 범위

Stage 02 ambience runtime 연결 결과를 1280×720 대표 화면에서 확인하고 실제 청취 결과를 기록한다. 이번 패킷은 코드·catalog·manifest·source/runtime 자산·추가 take·추가 음원·AudioDirector를 변경하지 않는 검수 전용 패킷이다.

## 3. 완료·확인 내용

- Godot 4.5.2 GUI를 1280×720 대표 크기로 실행했다.
- 타이틀 화면과 대표 UI가 정상 부팅되는 것을 확인했다. 게임 창 외곽은 1296×759이며 내부 viewport는 1280×720이다.
- `MusicStateAudioTest`를 이번 세션에 재실행했고 54 assertions가 통과했다.
- Stage 02 catalog event 해석, `connected` 상태, Stage 01→Stage 02 stream 교체, World Render 시작, `Ambience` 버스, 반복 갱신 중복 방지를 모두 직접 단언으로 확인했다.
- `tmp/v122_structural_wall_review/stage_02_castle_1280x720.png`에서 신선한 1280×720 Stage 02 World Render를 확인했다.
- `assets/audio/ambience/stage02_indoor.wav`를 사용자에게 제시했고 사용자가 `승인완료`로 실제 청취를 승인했다.

## 4. 변경 경로

| 경로 | 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_A4_STAGE02_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md` | 대표 화면·runtime·청취 확인 기록 | 추가 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md` | 다음 세션 진입점과 미해결 gate 기록 | 추가 |
| `docs/handoff/CURRENT.md` | 현재 패킷 상태와 다음 작업 갱신 | 갱신 |

코드·데이터·스토리·밸런스·그래픽 자산·오디오 runtime은 이번 패킷에서 변경하지 않았다.

## 5. 오디오 자산 및 연결 상태

- 자산 ID: `ambience_stage02_indoor`
- 이벤트 ID: `ambience.stage02.indoor`
- runtime 경로: `assets/audio/ambience/stage02_indoor.wav`
- source 기록: `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/SOURCE.md`
- runtime owner: `scripts/game/GameRoot.gd`
- locator: `_update_stage_ambience`
- 버스: `Ambience`
- 직접 runtime 단언: PASS
- 소유자 실제 청취: PASS — 사용자 `승인완료`

## 6. 테스트 및 검수

| 순서 | 확인 방법 | 결과 | 비고 |
|---:|---|---|---|
| 1 | `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS | `MUSIC_STATE_AUDIO_TEST: PASS (54 assertions)` |
| 2 | Godot 대표 GUI 부팅 | PASS | 1280×720 viewport에서 타이틀 UI 표시 |
| 3 | Stage 02 World Render 신선한 1280×720 화면 | PASS | `tools/V122StructuralWallCapture.tscn` 실행 결과 `tmp/v122_structural_wall_review/stage_02_castle_1280x720.png` 확인 |
| 4 | Stage 02 ambience 실제 청취 | PASS | `assets/audio/ambience/stage02_indoor.wav` 제시 후 사용자 `승인완료` |
| 5 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 밖 |

Godot 종료 시 `ObjectDB instances leaked at exit` 및 `1 resources still in use at exit` 경고가 출력됐다. `MusicStateAudioTest`의 54개 직접 단언은 모두 통과했으며, assertion 실패는 없었다.

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 관찰 사항과 미해결 문제

- 이번 패킷 범위의 미해결 gate는 없다.
- Godot 종료 teardown 경고는 관찰 항목으로 남긴다. 직접 테스트 assertion 실패는 아니다.
- 코드·데이터·자산·runtime은 변경하지 않았다.

## 8. 다음 작업 순서

1. Stage 02 대표 확인 패킷을 종료한다.
2. 다음 단일 패킷으로 Stage 01~04 발소리 자산 작업의 출처·범위 승인 gate를 제안한다.
3. 다음 패킷은 별도 사용자 승인 전 시작하지 않는다.

## 9. 작업 트리와 원격 상태

- 현재 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 동기화: 원격 대비 `HEAD`가 2커밋 앞섬
- 미커밋 파일: 기존 사용자·Luna 변경이 다수 섞여 있음. 이번 패킷은 문서 3개만 의도적으로 추가·갱신했다.
- 커밋·푸시: 실행하지 않음

## 10. 종료 체크리스트

- [x] 직접 runtime 테스트 재실행
- [x] 대표 viewport 부팅 확인
- [x] Stage 02 대표 World Render 신선한 화면 확인
- [x] Stage 02 실제 청취·소유자 승인
- [x] 전체 검수 미요청 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 다음 패킷 자동 실행 금지

## 최신 대표 화면 보정

- `tools/V122StructuralWallCapture.tscn`을 실행해 Stage 02 대표 화면을 새로 렌더링했다.
- `tmp/v122_structural_wall_review/stage_02_castle_1280x720.png`에서 1280×720 Stage 02 World Render, DAY 16 HUD, 입구·보물·방어 준비 UI를 확인했다.
- `assets/audio/ambience/stage02_indoor.wav` 실제 청취 후 사용자 `승인완료`를 받아 대표 확인 gate를 닫았다.
- 코드·데이터·자산·runtime 변경은 없으며, 다음 패킷은 시작하지 않는다.
