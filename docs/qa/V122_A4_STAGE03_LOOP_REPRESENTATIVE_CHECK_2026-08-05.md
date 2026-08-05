# v1.2.2 Stage 03 ambience 대표 화면·청취 확인 QA

## 1. 패킷과 범위

- 패킷 ID: `A4-STAGE-03-LOOP-REPRESENTATIVE-CHECK`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 현재 기준 HEAD: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE03_LOOP_REPRESENTATIVE_CHECK_PASS`

이번 패킷은 코드·카탈로그·manifest·source/runtime 음원·AudioDirector를 변경하지 않고, Stage 03 대표 화면과 runtime 재생 상태를 확인하는 검수 전용 작업이다.

## 2. 확인 결과

- 대표 화면 도구: `tools/V122StructuralWallCapture.tscn`
- 대표 해상도: `1280×720`
- 대표 장면: Stage 03 `stage_03_keep`, DAY 21 관리 화면
- 화면 캡처: `tmp/v122_structural_wall_review/stage_03_keep_1280x720.png`
- 화면 판정: PASS — 성채형 Stage 03 맵, 상단 자원/HUD, 우측 방 지침 패널과 하단 카드 영역이 정상 렌더링됐다.
- 캡처 실행: `godot.cmd --path . --scene tools/V122StructuralWallCapture.tscn --quit-after 3000`
- 실행 결과: `V122_STRUCTURAL_WALL_CAPTURE: PASS`

## 3. 오디오 직접 확인

- 자산 ID: `ambience_stage03_keep`
- 이벤트 ID: `ambience.stage03.keep`
- runtime 경로: `assets/audio/ambience/stage03_keep.wav`
- runtime owner: `scripts/game/GameRoot.gd`
- locator: `_update_stage_ambience`
- 재생 버스: `Ambience`
- 직접 테스트: `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800`
- 테스트 결과: `MUSIC_STATE_AUDIO_TEST: PASS (48 assertions)`
- 테스트 범위: Stage 03 이벤트 해석, stream 교체, World Render 재생, Ambience 버스, 반복 갱신 중복 방지
- 소유자 실제 청취: `PASS` — 사용자가 Stage 03 ambience를 청취하고 `승인완료`를 전달했다.

## 4. 변경 경로

이번 패킷에서 허용된 문서만 추가·갱신했으며 코드·데이터·자산·runtime은 변경하지 않았다.

- `docs/qa/V122_A4_STAGE03_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 5. 청취 승인 및 다음 조치

- 사용자가 Stage 03 ambience를 실제 청취하고 `승인완료`를 전달했다.
- 무음·끊김·과도한 반복 피로·화면과 어울리지 않는 음색에 대한 수정 요청은 없었다.
- 대표 화면·자동 테스트·소유자 청취 gate를 모두 닫았으며 다음 패킷은 자동 실행하지 않는다.
- 다음 단일 패킷 제안: `A4-STAGE-04-LOOP-MANIFEST-CONTRACT`

## 6. 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
- 전체 회귀·전체 플레이·검수 에이전트: `NOT_REQUESTED`
