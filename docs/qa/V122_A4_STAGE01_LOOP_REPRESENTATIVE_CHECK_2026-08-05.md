# v1.2.2 A4 Stage 01 ambience 대표 화면 확인

검수일: 2026-08-05
대상 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
패킷: `A4-STAGE-01-LOOP-REPRESENTATIVE-CHECK`

## 목적

Stage 01 `World Render`를 대표 해상도에서 실제로 부팅하고, ambience가 월드 화면에서 유지되며 설정 화면 전환에서 멈추고 다시 월드 화면으로 돌아왔을 때 복귀하는지 확인한다. 이번 패킷은 코드·catalog·음원 자산을 수정하지 않는 읽기 전용 대표 확인이다.

## 직접 실행

실행 환경은 Godot `4.5.2`, 대표 viewport `1280×720`이다. 창 테두리를 포함한 실제 창 크기는 `1296×759`였다.

GUI 실행:

```text
godot.cmd --path . --resolution 1280x720 --position 0,0
```

관련 직접 테스트:

```text
godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800
```

실행 결과:

```text
MUSIC_STATE_AUDIO_TEST: PASS (36 assertions)
```

## 화면·전환 판정

- 타이틀 화면이 대표 해상도에서 정상 부팅되고 저장된 `이어하기 · DAY 04`가 표시됐다.
- 이어하기 후 Stage 01 동굴 World Render가 표시되고 맵·HUD·우측 지침 패널이 잘렸다거나 로딩 실패 없이 보였다.
- `Esc`로 관리 화면 pause 메뉴가 열리고 월드 화면이 어두워졌다. 이는 ambience 정지 범위에 해당한다.
- pause 메뉴의 `환경 설정`으로 이동해 설정 화면이 정상 표시됐다.
- 설정을 취소한 뒤 pause 메뉴로 돌아왔고, `Esc`로 메뉴를 닫아 World Render로 복귀했다.
- 최종 캡처에서 World Render가 다시 정상 밝기로 표시됐다. 화면 전환 상태는 PASS다.

임시 화면 증거는 저장소 밖에만 생성했다.

- `C:\Users\blueh\AppData\Local\Temp\godot-stage01-primary.png`
- `C:\Users\blueh\AppData\Local\Temp\godot-stage01-after-continue.png`
- `C:\Users\blueh\AppData\Local\Temp\godot-stage01-settings-open.png`
- `C:\Users\blueh\AppData\Local\Temp\godot-stage01-world-final.png`

## 오디오 판정

- Godot 직접 테스트에서 Stage 01 ambience 전용 player의 event 해석, `Ambience` 버스, 월드 화면 시작, 설정 화면 정지, 월드 화면 복귀를 36개 assertion으로 재확인했다.
- 실제 GUI 실행에서도 해당 화면 전환 순서가 정상 동작했다.
- 소유자가 현재 실행 중인 World Render에서 ambience를 직접 확인했고, 무음·끊김·부자연스러운 loop 이상을 보고하지 않았다.

## 결과

`A4_STAGE01_LOOP_REPRESENTATIVE_CHECK_PASS`

대표 화면·전환과 소유자 청취 확인을 모두 통과했다. 코드·데이터·자산·runtime은 변경하지 않았다. 전체 회귀, 빌드, 커밋, 푸시는 실행하지 않았다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
