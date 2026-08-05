# v1.2.2 A4 Stage 02 ambience 대표 확인

검사일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK`

## 목적

Stage 02 `ambience_stage02_indoor`가 1280×720 대표 실행 화면에서 실제 runtime으로 부팅되고, Stage 02 ambience event가 재생되는지 확인한다. 이번 패킷은 코드·catalog·manifest·source/runtime 자산을 변경하지 않는다.

## 확인 결과

| 항목 | 결과 | 근거 |
|---|---|---|
| 1280×720 대표 실행 부팅 | PASS | Godot 4.5.2 GUI 실행. 게임 창 외곽 1296×759, 내부 대표 viewport 1280×720에서 타이틀 화면과 UI가 정상 표시됨 |
| Stage 02 catalog/runtime 단언 | PASS | `MusicStateAudioTest` 재실행, 54 assertions |
| Stage 02 World Render 신선한 1280×720 화면 | PASS | `tools/V122StructuralWallCapture.tscn` 실행 결과 `tmp/v122_structural_wall_review/stage_02_castle_1280x720.png`에서 Stage 02 World Render와 DAY 16 UI 확인 |
| Stage 02 실제 청취 | PASS | `assets/audio/ambience/stage02_indoor.wav`를 사용자에게 제시했고 `승인완료`를 받음 |
| 기존 Stage 02 시각 산출물 참고 | 참고 확인 | 기존 1920×1080 산출물과 별도로 새 1280×720 캡처를 확보함 |

## 실행한 직접 테스트

```text
godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800
```

결과:

```text
MUSIC_STATE_AUDIO_TEST: PASS (54 assertions)
```

이번 재실행에서 확인한 핵심 단언은 다음과 같다.

- Stage 02 ambience event가 catalog 자산으로 해석됨
- Stage 02 ambience event가 `connected` 상태임
- Stage 01에서 Stage 02 stream으로 교체됨
- World Render 화면에서 Stage 02 ambience가 시작됨
- `Ambience` 버스를 사용함
- 반복 갱신에서 중복 재생하지 않음

## 관찰 사항

- Godot 종료 시 `ObjectDB instances leaked at exit` 및 `1 resources still in use at exit` 경고가 출력됐다. 직접 단언은 모두 통과했으며, 이번 패킷의 판정을 실패로 바꾸는 assertion 오류는 없었다.
- 코드·데이터·자산·runtime은 변경하지 않았다.

## 후속 재시도 기록

- 2026-08-05 후속 turn에서 Windows 앱 목록을 다시 조회했으나 Godot 대표 창이 실행 중으로 반환되지 않았다.
- 새 화면 캡처나 UI 입력은 추가로 수행하지 않았고, 코드·데이터·자산·runtime 변경도 없었다.

## 최신 대표 화면 확인

- 기존 프로젝트 검증 장면 `tools/V122StructuralWallCapture.tscn`을 실행해 Stage 02를 실제 Godot viewport에서 다시 렌더링했다.
- 새 캡처: `tmp/v122_structural_wall_review/stage_02_castle_1280x720.png`
- 캡처 결과: PASS. 1280×720 화면에서 Stage 02 성 외형, DAY 16 HUD, 입구·보물·방어 준비 UI가 확인됐다.
- 이번 확인은 코드·데이터·자산·runtime을 수정하지 않은 읽기·렌더링 검증이다.

## 사용자 청취 기록

- 제시 음원: `assets/audio/ambience/stage02_indoor.wav`
- 사용자 응답: `승인완료`
- 청취 gate: PASS

## 판정

`A4_STAGE02_LOOP_REPRESENTATIVE_CHECK_PASS`

대표 화면, runtime 단언, 실제 청취·사용자 승인을 모두 완료했다. 이 패킷에서 추가 작업은 수행하지 않는다.

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
