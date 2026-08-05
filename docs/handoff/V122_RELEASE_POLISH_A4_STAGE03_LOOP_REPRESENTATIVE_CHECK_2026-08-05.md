# v1.2.2 release polish handoff — A4 Stage 03 loop representative check

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 현재 기준 HEAD: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `A4-STAGE-03-LOOP-REPRESENTATIVE-CHECK`
- 작업 결과: `A4_STAGE03_LOOP_REPRESENTATIVE_CHECK_PASS`
- QA: `docs/qa/V122_A4_STAGE03_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`

## 2. 이번 패킷 목표

Stage 03 ambience runtime 연결 결과를 1280×720 대표 화면에서 확인하고, 실제 음원을 사람이 청취할 수 있는 상태까지 준비한다. 이번 패킷은 코드·catalog·manifest·source/runtime 자산·추가 음원·AudioDirector를 변경하지 않는다.

## 3. 완료한 확인

- `tools/V122StructuralWallCapture.tscn`을 Vulkan GUI로 실행했다.
- Stage 03 `stage_03_keep`와 DAY 21 관리 화면을 1280×720으로 렌더링했다.
- 캡처 도구가 `V122_STRUCTURAL_WALL_CAPTURE: PASS`로 종료했다.
- 캡처 화면에서 Stage 03 성채 맵, 상단 HUD, 우측 방 지침, 하단 카드 UI를 확인했다.
- `MusicStateAudioTest`를 재실행했고 48 assertions가 통과했다.
- Stage 03 ambience 이벤트·stream 교체·World Render 재생·Ambience 버스·반복 갱신 중복 방지를 직접 확인했다.

## 4. 오디오 자산

- 자산 ID: `ambience_stage03_keep`
- 이벤트 ID: `ambience.stage03.keep`
- runtime: `assets/audio/ambience/stage03_keep.wav`
- source 기록: `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/SOURCE.md`
- owner: `scripts/game/GameRoot.gd`
- locator: `_update_stage_ambience`

## 5. owner 청취 결과

대표 화면과 자동 runtime 단언을 통과했고, 사용자가 Stage 03 ambience를 실제 청취한 뒤 `승인완료`를 전달했다. 무음·끊김·과도한 반복 피로·화면과 어울리지 않는 음색에 대한 수정 의견은 없었다.

청취 확인 기준:

- 화면이 무음으로 남지 않는가
- 재생 중 끊김이나 갑작스러운 음량 변화가 없는가
- 짧게 반복해도 부자연스러운 seam이 거슬리지 않는가
- Stage 03 성채 화면의 분위기와 어울리는가

결과: `PASS`

## 6. 변경 경로

- `docs/qa/V122_A4_STAGE03_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`
- `docs/handoff/CURRENT.md`

코드·데이터·스토리·밸런스·그래픽·오디오 runtime 변경은 없다.

## 7. 다음 작업 제안

1. 다음 단일 패킷은 `A4-STAGE-04-LOOP-MANIFEST-CONTRACT`로 잠근다.
2. 다음 패킷은 Stage 04 환경 loop 1개를 `planned` manifest에 등록하고 계약 테스트·dry-run만 실행한다.
3. Stage 04 음원 생성·청취·승격·catalog 연결·runtime 연결은 각각 별도 패킷으로 유지한다.

## 8. 작업 트리와 검수 정책

- 기존 사용자·Luna 미커밋 변경이 섞인 혼합 작업 트리를 보존했다.
- 커밋·스테이징·푸시는 하지 않았다.
- 전체 회귀·전체 플레이·검수 에이전트는 요청되지 않아 실행하지 않았다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
