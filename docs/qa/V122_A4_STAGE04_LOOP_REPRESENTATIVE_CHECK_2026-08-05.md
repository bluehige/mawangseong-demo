# V1.2.2 Stage 04 환경음 대표 화면·청취 확인 QA

## 1. 패킷과 범위

- 패킷 ID: `A4-STAGE-04-LOOP-REPRESENTATIVE-CHECK`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE04_LOOP_REPRESENTATIVE_CHECK_PASS`

이번 패킷은 Stage 04 `stage_04_citadel` 대표 화면에서 runtime 연결 상태를 확인하고, 사용자가 실제 ambience를 청취해 승인하는 검수 전용 작업이다. 코드·데이터·자산·manifest·source/runtime·AudioDirector는 변경하지 않았다.

## 2. 대표 화면 확인

- 실행 도구: `tools/V122StructuralWallCapture.tscn`
- 대표 해상도: `1280×720`
- 대표 장면: Stage 04 `stage_04_citadel`, DAY 30 관리 화면
- 캡처 명령: `godot.cmd --path . --scene tools/V122StructuralWallCapture.tscn --quit-after 3000`
- 실행 결과: `V122_STRUCTURAL_WALL_CAPTURE: PASS`
- 화면 결과: Stage 04 성채형 맵, 상단 DAY/HP/HUD, 우측 방 지침 패널, 하단 수비대·명령 영역이 정상 표시됐다.
- 캡처 경로: `tmp/v122_structural_wall_review/stage_04_citadel_1280x720.png`

## 3. 오디오 확인

- 자산 ID: `ambience_stage04_citadel`
- 이벤트 ID: `ambience.stage04.citadel`
- runtime 경로: `assets/audio/ambience/stage04_citadel.wav`
- runtime owner: `scripts/game/GameRoot.gd`
- locator: `_update_stage_ambience`
- 버스: `AudioSettings.AMBIENCE_BUS`
- 직접 테스트: `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800`
- 테스트 결과: `MUSIC_STATE_AUDIO_TEST: PASS (54 assertions)`
- 실제 청취: 사용자가 Stage 04 ambience를 청취하고 `승인 완료`를 전달했다.
- 청취 판정: 무음·끊김·과도한 반복 seam·화면 분위기 불일치에 대한 수정 요청 없음.

## 4. 검수 기록

| 검사 | 결과 | 근거 |
|---|---|---|
| Stage 04 대표 캡처 | PASS | `V122_STRUCTURAL_WALL_CAPTURE: PASS` 및 캡처 파일 |
| Stage 04 1280×720 화면 | PASS | `tmp/v122_structural_wall_review/stage_04_citadel_1280x720.png` |
| Stage 04 runtime event·stream·버스 | PASS | `MusicStateAudioTest` 54 assertions |
| Stage 04 실제 청취·소유자 승인 | PASS | 사용자 `승인 완료` |
| 전체 회귀·전체 플레이·검수 에이전트 | `NOT_REQUESTED` | 이번 패킷 범위 아님 |

Godot headless 종료 시 `ObjectDB instances leaked at exit`와 리소스 1건 사용 중 경고가 관찰됐다. 기능 단언과 대표 캡처는 PASS였으며, 기존 teardown 관찰 항목으로 남긴다.

## 5. 변경 경로

이번 패킷에서 변경한 저장소 경로는 문서뿐이다.

- `docs/qa/V122_A4_STAGE04_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE04_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`
- `docs/handoff/CURRENT.md`

코드·데이터·스토리·밸런스·그래픽 자산·오디오 runtime은 변경하지 않았다. 캡처는 기존 `tmp/` 검수 산출물 경로에만 생성했다.

## 6. 미해결과 다음 순서

Stage 04 대표 화면과 실제 청취 gate는 닫혔다. 다음 단일 패킷은 기존에 대표 화면과 runtime 단언은 통과했지만 실제 청취 승인이 남아 있는 `A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK`다. Stage 02 ambience를 실제 청취해 승인하기 전에는 다음 오디오 패킷으로 진행하지 않는다.

## 7. 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
