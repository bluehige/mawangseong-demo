# 마왕성 UI/UX 감사 도구

제품 파일을 수정하지 않고 실제 GameRoot를 실행해 화면과 Control 측정값을 저장한다. 게임 상태 설정은 해당 프로세스의 메모리와 격리된 감사 세이브에만 적용한다. 배포·게임 플레이 테스트·밸런스 평가 도구가 아니다.

## 실행

설치된 `godot.cmd`, Python 3, Pillow를 사용한다. Godot는 그래픽 모드에서 실행한다. 실행은 한 번에 한 프로세스만 사용한다. `tmp/v1213_uiux_audit/command.json`은 공통 명령함이다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/ux_audit/RunAudit.ps1 -Profile new-audit
```

`APPDATA`는 `tmp/v1213_uiux_audit/<Profile>/` 안으로 격리한다. `user://`가 이 경로가 아니면 하네스가 종료한다. 실제 창 크기와 프레임 크기는 1920×1080이다. `-Touch`는 `--mobile-touch-ui`, `-Resume`는 최초 타이틀 캡처 덮어쓰기를 방지한다. 감사 저장은 `audit_campaign*.json`이며 개인 세이브를 읽지 않는다.

## 명령과 측정

```powershell
@'
[{"op":"call","target":"game.continuity","method":"acknowledge_update"},
 {"op":"capture","name":"sample_title","decision":"Start new game","provenance":"actual boot"},
 {"op":"click","name":"CampaignNewGameButton"},
 {"op":"capture","name":"sample_name","decision":"Choose player name","provenance":"actual click"}]
'@ | python tools/ux_audit/client.py
```

- `click`는 Control의 실제 보이는 사각형에 엔진 입력을 보내며 signal을 직접 발동하지 않는다. `point`/`room`도 엔진 입력이다.
- `call`, `set`, `patch`, `eval`, `unit`는 후기 화면 진입용 합성 상태 도구다. 이 경로를 자연 플레이 클릭 수로 계산하지 않는다. `eval`은 감사자가 출처를 확인한 게임 메서드와 상태에만 사용한다.
- `scroll`은 실제 ScrollContainer 위치를 바꾼다. `wait`는 렌더 프레임, `freeze`는 GameRoot 시계만 멈춘다. 별도 컷신 stage는 자체 시계를 가지므로 고정 프레임이 필요할 때 `stage.set_process(false)`를 별도로 호출한다.
- `quit`는 감사 프로세스만 종료한다.
- 캡처마다 PNG와 JSON을 저장한다. JSON에는 라벨/버튼 텍스트, 글자 크기, 사각형, 스크롤 잘림, 보이는 줄 수, 툴팁과 활성 여부가 있다. 최근 하네스는 effect-root의 컷신 Control과 전투 badge layout도 수집한다.
- 모든 명령은 `actions.json`에 누적된다. `profile.log`, `touch.log`, `final.log`에는 실제 렌더 및 합성 상태 경고가 있다. 합성 저장 validator 거절은 제품 회귀로 해석하지 않는다.

수집한 2026-10-14 감사 데이터가 있을 때:

```powershell
python tools/ux_audit/measure.py
```

이 명령은 보고서의 측정표 구간, 960×540 대표 JPG 12장, `tmp/`의 CSV/JSON을 만든다. 텍스트 수는 여러 줄을 한 블록으로 센다. `visible_lines=0`인 라벨, 스크롤 일부 잘림, 화면 경계 잘림을 분리한다. 임의 직사각형 교차를 곧바로 UI 버그로 판정하지 않는다. 모달은 전면 범위만 센다. 직접 그리는 지도 글자·스프라이트 이름·데미지는 Control 집계와 별도다.

2026-10-14 감사의 자연 동선은 첫 프로세스에서 기록했다. 초기에 tools 씬의 기본 저장 차단을 발견해 `_set_campaign_save_path_for_tests()`로 감사 경로를 연결했고, 이후 시작 시 이 경로를 먼저 연결하도록 수정했다. 준비 신호와 종료 응답의 초기 하네스 오류도 보완했다. 최종 도구가 과거 모든 탐색 입력을 동일 순서로 재실행했다는 주장은 하지 않는다.

`tmp/`, Python 캐시, 원본 PNG, 격리 세이브는 커밋하지 않는다. 제품 코드/데이터/런타임 자산에는 변경을 만들지 않는다.

## 병합 뒤 표시 결함 스윕

`Sweep.tscn`은 기존 `Audit.gd`의 캡처·측정을 재사용하며 화면 상수 29종과 설정/관리 탭, DAY12 성장, 성장 스크롤, 실제 유닛별 상세와 터치 상세 스크롤, 컷신/첫 보호 알림, 연대기 4탭, 튜토리얼 마스크를 렌더한다. 후기 진입은 합성 상태다. 전체 회귀나 자연 해금 검사가 아니다.

```powershell
$env:APPDATA = Join-Path $PWD 'tmp/v1213_uiux_fix/check_desktop/profile'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
godot --path . --rendering-method gl_compatibility --resolution 1920x1080 res://tools/ux_audit/Sweep.tscn -- --audit-out=tmp/v1213_uiux_fix/check_desktop
```

터치는 별도 프로세스/새 APPDATA 하위 폴더와 `--mobile-touch-ui`를 사용한다. 한 번에 하나의 스윕을 실행한다. `--audit-out`은 `tmp/` 안의 경로만 사용하며 실제 `user://`가 출력 폴더 안인지 시작 전에 확인한다. 기존 대화형 `RunAudit.ps1`의 기본 출력 경로는 유지한다.

```powershell
python tools/ux_audit/scan.py tmp/v1213_uiux_fix/check_desktop tmp/v1213_uiux_fix/check_touch
```

- `scan.py`는 완료된 `sweep_result.json`을 요구하고 실제 29화면 및 fixture 실패를 확인한다. 0줄 라벨, 형제 Control의 겹침, 지역 인장 라벨의 카드 경계 넘침, 마스크 스타일을 검사한다. 다른 부모/Canvas에 놓인 상세창·배속·명령·컷신·보호 알림은 별도 교차 계약도 검사한다.
- 모든 후보와 제외 이유를 `scan.json`에 남긴다. 그림/색 배경/스크롤바, 내용 없는 라벨, 투명 holder, 내용 전체를 감싸는 시각 패널, 관리 상세 드로어, 대화 프레임 접합, 튜토리얼 강조/그림자만 의도된 겹침으로 분류한다. 불투명한 정보 패널을 일괄 제외하지 않는다.
- 텍스트는 실제 폰트 측정 영역으로 검사한다. 부모·자식 포함, 모달 뒤 배경과 스크롤 밖 항목을 결함으로 세지 않는다. 픽셀 OCR이나 모든 게임 상태의 수학적 증명은 아니다.
- 결함/fixture 실패가 있으면 exit 1, 모두 0이면 exit 0이다. 보호 알림·배속 복구도 fixture가 직접 확인한다. 원본 PNG/JSON은 모두 `tmp/v1213_uiux_fix/`에만 남긴다.
