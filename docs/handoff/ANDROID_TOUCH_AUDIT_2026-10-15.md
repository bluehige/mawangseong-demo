# Android 전환 1단계: 터치·글자 자동 측정 (2026-10-15)

## 1. 메타데이터

- 목표: 현재 제품 1.3.0 기반 Android 준비 1단계. 브랜치 `codex/v131-android`.
- 사용자 지정 기준 SHA: `9befdd2afc32bbf1f0a231bae5bd840b09d33cfe`. 측정 도구 검토 SHA: `956c01c0e9c553e21e8f949ec04a6c8b3b9b8ff1`.
- 로컬 main 부재. origin/main 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`; 이번 원격 조회/fetch 없음. 최신 main 권위를 확정하지 않고 사용자가 지정한 HEAD를 측정했다.
- 로컬 영어 커밋만. push·merge·태그·export·Steam 변경 없음.

## 2. 목표·측정 기준

화면 코드를 수정하지 않고 현재 터치 UI를 측정한다. 1920×1080 캔버스·한국어·기본 글자 배율 1.0·자동 레이아웃·`--mobile-touch-ui`를 사용했고 모든 상태에서 `UISettings.is_touch_ui() == true`를 확인했다. touch 모드와 compact 레이아웃은 별개다. 사용자 가정인 6.5인치 20:9 폰·1px≈0.063mm를 판정 근거로 유지한다. 20:9 실기 화면을 직접 렌더하거나 Android APK를 실행한 결과는 아니다.

| 항목 | 기준 | 판정 |
|---|---|---|
| 터치 대상 | 너비·높이 모두 ≥128px (약 8.06mm) | 보이는 클립 영역의 한 변이라도 작으면 미달 |
| 버튼 사이 | 경계 간 최단 거리 ≥20px (약 1.26mm) | 대각선은 유클리드 거리, 겹침은 0px; 부모·자식 쌍 제외 |
| 본문 | ≥36px (약 2.27mm) | 의미상 본문 여부를 자동 추정하지 않고 모든 글자의 `<36`을 별도 표시 |
| 최소 글자 | ≥30px (약 1.89mm) | 실제 테마 글자 크기×렌더 변환 Y배율 |

## 3. 완료 내용과 요약

**34개 화면 상태**를 자동 측정했다. 입력 Control 관측 518건 중 **467건**이 128×128 미달이며, 활성 입력만 보면 487건 중 **439건**이다. Label/RichTextLabel 486건 중 **101건**은 최소30 미달, **389건**은 본문36 미달이다. 20px 미만 인접 쌍은 **396건**이다.

분모는 화면 상태별 관측 수다. 같은 버튼이 여러 탭·스크롤 위치·모달 상태에서 반복되므로 고유 결함 수로 해석하지 않는다. 비활성 버튼은 별도 표시하되 향후 활성화될 같은 화면 대상으로 수집한다. STOP 수동 후보, 맵 판정, 버튼 내 글자는 위 Label 분모와 구분한다. 수치 미달은 관찰 결과이며 측정 테스트의 실패 조건이 아니다.

스토리·게임 데이터·밸런스·저장 형식·UI·그래픽·오디오·출시 파일은 수정하지 않았다. 실제 전투는 DAY1 3.5초 시점까지 진행하고 정지했다. 승리·패배 결산과 의회 DAY16은 기존 화면 빌더에 합성 상태를 전달한 측정 픽스처다. 자연 플레이 완주 증거로 사용하지 않는다.

| 화면 상태 | 입력 수 / 128 미달 | 활성 입력 / 미달 | Label 수 / <30 / <36 | <20px 쌍 | 맵 대상 |
|---|---:|---:|---:|---:|---:|
| `title` | 8 / 8 | 7 / 7 | 2 / 1 / 2 | 5 | 0 |
| `name_entry` | 4 / 4 | 4 / 4 | 8 / 2 / 6 | 0 | 0 |
| `settings_general` | 16 / 15 | 15 / 14 | 17 / 8 / 16 | 11 | 0 |
| `settings_general_bottom` | 17 / 16 | 16 / 15 | 15 / 7 / 14 | 15 | 0 |
| `settings_display` | 13 / 12 | 13 / 12 | 14 / 7 / 13 | 10 | 0 |
| `settings_display_bottom` | 13 / 12 | 13 / 12 | 14 / 7 / 13 | 10 | 0 |
| `settings_audio` | 14 / 13 | 14 / 13 | 16 / 5 / 15 | 9 | 0 |
| `settings_audio_bottom` | 14 / 13 | 14 / 13 | 16 / 5 / 15 | 9 | 0 |
| `settings_accessibility` | 14 / 13 | 14 / 13 | 8 / 1 / 7 | 12 | 0 |
| `settings_accessibility_bottom` | 14 / 13 | 14 / 13 | 7 / 0 / 6 | 15 | 0 |
| `settings_combat` | 14 / 13 | 14 / 13 | 14 / 5 / 13 | 9 | 0 |
| `settings_combat_bottom` | 15 / 14 | 15 / 14 | 13 / 5 / 12 | 11 | 0 |
| `dialogue` | 7 / 6 | 5 / 4 | 6 / 0 / 4 | 4 | 0 |
| `management_build` | 22 / 21 | 21 / 20 | 15 / 0 / 11 | 20 | 11 |
| `management_build_right` | 22 / 21 | 20 / 19 | 17 / 0 / 13 | 20 | 11 |
| `placement_preview` | 24 / 23 | 19 / 18 | 23 / 0 / 19 | 23 | 11 |
| `decoration` | 26 / 25 | 25 / 24 | 20 / 0 / 16 | 25 | 11 |
| `garrison` | 20 / 19 | 19 / 18 | 10 / 0 / 6 | 12 | 11 |
| `management_tactics` | 22 / 21 | 20 / 19 | 9 / 0 / 5 | 16 | 11 |
| `monster` | 15 / 10 | 15 / 10 | 33 / 0 / 25 | 17 | 0 |
| `chronicle_0` | 15 / 13 | 15 / 13 | 3 / 0 / 1 | 5 | 0 |
| `chronicle_1` | 15 / 13 | 15 / 13 | 3 / 0 / 1 | 5 | 0 |
| `chronicle_2` | 16 / 14 | 16 / 14 | 3 / 0 / 1 | 6 | 0 |
| `ending_archive` | 6 / 4 | 6 / 4 | 3 / 0 / 1 | 1 | 0 |
| `memory_archive` | 15 / 10 | 15 / 10 | 25 / 0 / 17 | 17 | 0 |
| `combat_hud` | 17 / 16 | 16 / 15 | 12 / 9 / 12 | 17 | 15 |
| `combat_selected` | 22 / 20 | 18 / 17 | 19 / 13 / 18 | 20 | 15 |
| `combat_tactics_details` | 27 / 24 | 23 / 21 | 25 / 13 / 24 | 22 | 15 |
| `combat_details_bottom` | 27 / 24 | 23 / 21 | 25 / 13 / 24 | 22 | 15 |
| `result` | 4 / 3 | 4 / 3 | 17 / 0 / 10 | 1 | 0 |
| `result_details` | 6 / 4 | 6 / 4 | 21 / 0 / 14 | 3 | 0 |
| `defeat` | 5 / 4 | 5 / 4 | 17 / 0 / 10 | 1 | 0 |
| `defeat_details` | 7 / 5 | 7 / 5 | 21 / 0 / 14 | 3 | 0 |
| `council_management` | 22 / 21 | 21 / 20 | 15 / 0 / 11 | 20 | 10 |

Button/BaseButton만 따로 보면 **457건 중 448건**이 크기 미달이며, 버튼끼리 20px 미만인 쌍은 **282건**이다. 위 입력 총계는 ScrollContainer·ScrollBar·Slider 등의 입력 영역도 포함한다.

맵 3상태의 별도 요약은 다음과 같다. `바닥 외접 미달`은 방의 실제 nearest-cell 폴백 판정 미달과 같지 않다.

| 상태·대상 | 수 | 외접 크기128 미달 | 유닛/방 우선순위·UI 차단 후 128 정사각형 미확보(8px 근사) |
|---|---:|---:|---:|
| `management_build` · 유닛 원형 | 3 | 0 | 3 |
| `management_build` · 방 | 8 | 7 | 2 |
| `combat_hud` · 유닛 원형 | 5 | 0 | 3 |
| `combat_hud` · 방 | 8 | 0 | 2 |
| `council_management` · 유닛 원형 | 0 | 0 | 0 |
| `council_management` · 방 | 10 | 9 | 3 |

## 4. 변경 파일

| 경로 | 변경 목적 |
|---|---|
| `tools/tests/AndroidTouchAuditTest.gd` | 런타임 화면·입력·글자·툴팁·맵 판정 수집 |
| `tools/tests/AndroidTouchAuditTest.tscn` | 재사용 실행 씬 |
| `tools/tests/RunAndroidTouchAudit.ps1` | 개인 저장과 격리, 엔진 1프로세스 실행·전후 검사 |
| `tools/tests/AndroidTouchAuditReport.py` | JSON 구조·기준·커버리지 검증과 이 보고서 재생성 |
| `docs/handoff/ANDROID_TOUCH_AUDIT_2026-10-15.md` | 측정 결과·세션 인계 |
| `docs/handoff/CURRENT.md` | 이번 결과 진입 링크 |

## 5. 자산·대표 캡처

이미지 생성·Sweep·갤러리 미실행. 생성 그래픽/오디오 자산 없음. 아래 PNG는 기존 게임의 실제 1920×1080 뷰포트 캡처다. 캡처는 커밋하지 않으며 JSON과 함께 로컬 `tmp/android_audit/`에 보관한다.

| 화면 | 대표 캡처 |
|---|---|
| `title` | `tmp/android_audit/title.png` |
| `settings_general` | `tmp/android_audit/settings_general.png` |
| `dialogue` | `tmp/android_audit/dialogue.png` |
| `management_build` | `tmp/android_audit/management_build.png` |
| `placement_preview` | `tmp/android_audit/placement_preview.png` |
| `decoration` | `tmp/android_audit/decoration.png` |
| `monster` | `tmp/android_audit/monster.png` |
| `chronicle_0` | `tmp/android_audit/chronicle_0.png` |
| `combat_selected` | `tmp/android_audit/combat_selected.png` |
| `result` | `tmp/android_audit/result.png` |
| `defeat` | `tmp/android_audit/defeat.png` |
| `council_management` | `tmp/android_audit/council_management.png` |

대표12장 모두 직접 열어 대상 화면을 확인했다. 최종 측정은 추가 촬영 없이 기존 대표 PNG를 재사용했다(`capture_reused: true`). 최초 캡처 시점의 정확한 JSON·로그는 `tmp/android_audit/capture_run/`, 최신 보완 JSON은 최상위에 있다. 전투 동적 프레임은 대표 캡처와 최신 측정 사이에 소폭 다를 수 있다. 생성 누적12/20, 재촬영0.

## 6. 실행·검증과 측정 방식

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/tests/RunAndroidTouchAudit.ps1 -Capture
python tools/tests/AndroidTouchAuditReport.py --reviewed-sha 956c01c0e9c553e21e8f949ec04a6c8b3b9b8ff1
```

기존 캡처가 있으면 `-Capture` 실행은 거부하며, 캡처 없이 재측정할 수 있다. Godot GUI 실행 파일은 설치된 `godot-gui.cmd` 내용에서 확인하고 직접 실행한다. 임의의 앱 내부 버전 경로를 추측하지 않는다. APPDATA는 `tmp/android_audit/profile`로 격리하고 자동 캠페인 저장을 끈다.

- Godot 4.6.3-stable (official), OpenGL compatibility / Windows. 스크립트 검사 107건, 실패 0건. JSON/전체 상태 커버리지 검증 PASS.
- 최종 실행 Godot 전0·최대1·후0 (`process_counts.json`). 초기 측정의 콘솔 래퍼는 엔진1+콘솔 보조1 프로세스였으며 이후 직접 GUI 호출로 교정했다. 최초부터 엄격한 1프로세스를 지켰다는 주장은 하지 않는다.
- 초기 실패/진단은 `attempt01/`~`attempt03/`에 보존했다. 첫 시도는 PowerShell이 네이티브 stderr 진단에서 중단했고, 두 번째는 의회 픽스처의 전초기지 선행 조건 누락을 검출했다. 세 번째는 캡처 인자 연결 공백 오류를 검출했다. 검사 기대값을 낮추지 않고 실행기·픽스처를 수정했다.
- 전체 회귀·전체 플레이·검수 에이전트 NOT_REQUESTED. 별도 에이전트는 입력 방식의 읽기 전용 소스 조사만 수행했다.

- 마지막 도구 커밋 SHA: `956c01c0e9c553e21e8f949ec04a6c8b3b9b8ff1`. 이후에는 이 보고서와 CURRENT만 문서 커밋한다.
- 최종 stderr 0bytes. 초기 콘솔 오류/의회 전환/인자 오류를 포함한 이전 로그는 삭제하지 않았다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 956c01c0e9c553e21e8f949ec04a6c8b3b9b8ff1
- Review range: 9befdd2afc32bbf1f0a231bae5bd840b09d33cfe..956c01c0e9c553e21e8f949ec04a6c8b3b9b8ff1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

Control은 `is_visible_in_tree`, 알파0 제외, 뷰포트와 조상 `clip_contents` 교집합 후 수집했다. Button/BaseButton·Slider·ScrollBar·LineEdit·TextEdit·연결된 GUI 입력/링크와 STOP 후보를 기록한다. 테마 상속과 터치 배율이 적용된 `get_theme_font_size`에 `get_stretch_transform() * get_global_transform_with_canvas()`의 Y배율을 곱했다. RichTextLabel은 기본 및 사용된 굵게/기울임/고정폭 테마·명시 font_size 태그를 수집한다. [CanvasItem 좌표 변환 공식 문서](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-get-global-transform-with-canvas), [RichTextLabel 테마/태그 공식 문서](https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html).

맵의 유닛은 실제 선택 함수의 터치 반경(관리104 world px, 전투96 world px), 적 명령 판정은192×220 world px를 현재 카메라/캔버스 배율로 환산했다. 방은 원형 반경이 없으며 `ModuleGraph.room_at_world`가 타일 적중 후 가장 가까운 방 타일로 무제한 폴백한다. 그래서 방 바닥 AABB(축에 평행한 외접 사각형)와 실제 picker의 8px 격자 측정값을 함께 기록했다. 격자에서 UI에 막힌 점과 더 가까운 유닛이 가로채는 점을 제외한 최대 정사각형은 근삿값이다. 방 바닥 경계를 실제 유한 탭 반경으로 해석하면 안 된다.

## 7. 제한·다음 단계 판단

- 겹치는 다른 Control의 불투명 픽셀별 가림/임의 `_has_point` 형상은 수집 사각형에서 빼지 않는다. 클립 후 입력 경계·겹침을 측정한 것이며 모든 지점에 실제 탭을 보내 도달성을 증명한 결과는 아니다. 맵 3상태에만 실제 입력 차단 함수를 적용한 격자 결과를 추가했다.
- 맵 원형의 외접 크기가128 이상이어도 다른 유닛과 겹치면 독립 선택이 어려울 수 있다. 인접 원 간0px 및 격자 도달 정사각형을 함께 판단한다. 미니맵 내부 점은 연속 좌표 이동용이며 독립 Button으로 세지 않는다.
- 커스텀 draw_string, 그림에 포함된 글자, PopupMenu의 직접 그리기 항목, 가상 키보드는 Label/RichTextLabel 분모 밖이다. 버튼/입력 글자는 별도 보충 수집했다. 20:9 레터박스·기기 DPI·시스템 글꼴 배율·손가락 터치 체감은 실기 확인이 필요하다.
- 이번 측정은 현재 초기/지정 회차 상태다. 모든 해금 조합·모든 스토리 문장·언어3종·전체30일은 범위 밖이다. 한국어 기본 배율 결과를 다른 언어/폰 크기에 그대로 일반화하지 않는다.
- 주요 축소 대상은 타이틀 버튼 높이, 관리 상단/하단·설정 탭/슬라이더, 전투40px 메뉴·80px 행동·배속 버튼이다. 수정 우선순위는 다음 단계에서 결정한다. **이번 UI 수정은 0건**.

## 8. 마우스·키보드·hover 의존 목록

| 종류 | 위치·근거 | 동작·실제 문구 | 터치 대체 / 판정 |
|---|---|---|---|
| 가운데 드래그 | `scripts/game/BuildingPlacementController.gd:74–109` | 관리 지도 이동. `휠: 확대·축소 / 휠 버튼 드래그: 이동` | 손가락 이동 분기 미발견. **마우스 전용 이동**. 지도 전체/±는 이동 대체가 아님 |
| 휠 | `scripts/ui/ManagementWorkspaceUI.gd:176` | 관리 지도 확대·축소 | `지도 전체`, `ZoomOutManagementMapButton`, `ZoomInManagementMapButton` 대체 있음 |
| 휠·=/− | `scripts/camera/SpectatorCameraDirector.gd:128`, `scripts/core/InputSettings.gd:59–66` | 전투 확대·축소 | 전투 ± 버튼·핀치 미발견. **포인터/키보드 의존** |
| 왼쪽/손가락 드래그 | `scripts/camera/SpectatorCameraDirector.gd:132–157`, `scripts/ui/CombatMinimap.gd:34` | 전투 카메라 이동 | `ScreenDrag` 및 미니맵 터치 있음. 마우스 전용 아님 |
| 우클릭·ESC | `scripts/game/GameRoot.gd:1642`, `scripts/game/CombatSceneController.gd:960` | 명령 대상 선택 취소, 툴팁 `ESC/우클릭 취소` | 같은 명령 다시 누르기로 취소 가능. 해당 대체 안내는 없음 |
| ESC·R·방향키·Enter/Space | `scripts/game/BuildingPlacementController.gd:303–331`, `scripts/ui/ManagementWorkspaceUI.gd:477–479` | 건설 취소·회전·후보 순환·확정 | 취소/회전 버튼, 지도 위치 터치 존재. **드래그 전용 아님** |
| 장식 위치 터치 | `scripts/map_builder/PlotDecorationSession.gd:59–69,128` | `빈칸 클릭·터치: 배치 / ESC: 취소` | 위치 터치와 별도 취소 버튼 있음. 드래그 전용 아님 |
| 동료 카드/맵 드래그 | `scripts/game/ManagementSceneController.gd:175`, `scripts/game/GameRoot.gd:15212` | 동료 배치·방 이동 | 짧은 클릭→배치 모드→방 선택 대체 있음. 이 경로의 네이티브 터치 분기는 부족하며 마우스 에뮬레이션 의존 가능 |
| 명령 대상 클릭 | `scripts/camera/SpectatorCameraDirector.gd:127`, `scripts/game/GameRoot.gd:1638–1673` | 명령 선택 중 목표 지정 | 해당 네이티브 터치 카메라 처리에서는 빠지고 MouseButton 경로로 지정. 에뮬레이션 의존 가능; 실기 미검증 |
| Space·Tab | `scripts/core/InputSettings.gd:39–45`, `scripts/game/GameRoot.gd:11774` | 전투 일시정지/다음 동료 선택 | 정지 버튼, 지도 유닛 탭 있음. `Space`는 메뉴를 여는 경로도 있어 정지 버튼과 의미 차이 주의 |
| Space·Enter | `scripts/core/InputSettings.gd:46–49` | 대화 진행 | 대화 진행 버튼 있음 |
| H·J·K | `scripts/core/InputSettings.gd:50–58` | 성의 심장·합동기1/2 | 기능이 해금된 회차의 HUD 행동 버튼 존재. DAY1은 잠김 상태 측정 |
| ESC·Alt+Enter | `scripts/game/GameRoot.gd:1552–1566,11781–11815` | 메뉴/닫기/취소, 창 모드 전환 | 메뉴·돌아가기·취소·닫기/설정 대체. Android 시스템 뒤로가기 연동 검증 아님 |
| F3–F9 | `scripts/game/GameRoot.gd:11816–11829` | 맵 디버그 오버레이 | 개발용. 제품 터치 필수 조작 집계에서 제외 |
| 숫자키 | `scripts/game/GameRoot.gd:_handle_key`, `scripts/core/InputSettings.gd:DEFAULT_BINDINGS` | 현재 런타임에서 숫자키 전용 조작 미발견 | 숫자키 기능이 있다고 추정하지 않음 |
| 슬라이더 끌기·방향키 | `scripts/ui/HUDController.gd:1607` | `끌거나 방향키로 값을 변경` | 기본 HSlider. 독립 ±/수치 입력 없음. 실기 테스트 없이 마우스 전용으로 단정하지 않음 |
| 스크롤 휠·스크롤바 끌기 | 설정/건설/기록/상세의 ScrollContainer | 하단/오른쪽 숨은 항목 보기 | 엔진의 터치 스크롤에 의존. 실제 손가락 관성·충돌 미검증 |

툴팁(포인터를 올려 보는 설명)은 `tooltip_text`와 화면 좌표를 아래 화면별 표에 전부 기록했다. 길게 누르기로 설명을 여는 공통 분기는 발견하지 못했다(`scripts/ui/kit/KitButton.gd:62`, `scripts/ui/ReadableTooltipSlider.gd`, `scripts/ui/ReadableTooltipOptionButton.gd`). hover 장식 자체와 설명 접근 의존은 구별한다. `HUDController.gd:1779`는 터치에서 hover 애니메이션만 생략한다.

중요한 설명 의존은 DAY 배지의 공지·부지 요약(`ManagementWorkspaceUI.gd:172`), 성 등급의 평가 계산·전투 효과 없음(`PlotDecorationSession.gd:117`), 명령 효과·대기시간(`CombatWorkspaceUI.gd:382`), 몬스터 성장 준비 효과·전직의 변경 불가 경고(`MonsterWorkspaceUI.gd:294,393`)다. 결과 동료 설명은 상세 기록에도 표시된다(`ResultWorkspaceUI.gd:245`). 전선 선택의 E16 해금 설명은 정적 추가 발견이며 이번 실행 화면 범위 밖이다(`FrontSelectionScreen.gd:98`).


## 9. 작업트리·보존

기존 미커밋1498파일(수정 import1423·미추적 UID75)의 바이트는 작업 시작 지문과 비교한다(`preservation_before.json`, `preservation_check.json`). 해당 파일은 스테이징하지 않는다. Steam-1.3.0-Ready35파일은 경로·크기·수정시각을 대조하고, 저장소 제품·출시 파일의 HEAD 대비 diff가 없음을 확인한다. `tmp/android_audit/`는 미추적 증거이며 커밋 대상이 아니다. stash·별도 작업트리·원격 조치 없음.

## 10. 다음 작업·종료

1. 본 측정 JSON·대표 PNG를 헤드가 검토하고 128/20/36/30 기준에 맞출 수정 우선순위를 정한다.
2. 별도 UI 수정 작업에서 터치 설명 열기·관리 지도 이동·전투 확대/축소의 대체 입력을 설계한다.
3. 다음 단계에서 Android 실기·20:9·가상 키보드와 해금 후 행동을 검증한다. 이번 측정 커밋으로 출시/배포하지 않는다.

체크: 요청 화면 측정·JSON 검증·대표 캡처·핸드오프/CURRENT 갱신·명시 파일만 로컬 영어 커밋. 미달 수정은 요청 범위 밖이다.

## 부록: 화면별 전체 측정 표

각 상태의 원본은 `tmp/android_audit/<상태>.json`, 통합은 `audit.json`, 수치 요약은 `summary.json`이다. 표에서 `(비활성)`과 `(클립)`을 구분한다. `STOP 후보`는 입력을 막거나 hover 설명만 제공할 수 있어 확정 버튼 수와 분리했다. 글자 표는 요청 Label/RichTextLabel 전체와 Button/LineEdit 보충을 함께 표시한다.

### title · title · DAY1

상태 근거: Fresh isolated title. 캡처: `tmp/android_audit/title.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `CampaignNewGameButton` · button | 520×104.4 | 520×104.4 | 미달 | 11.6 / `CampaignContinueButton` |
| `CampaignContinueButton` · button (비활성) | 520×104.4 | 520×104.4 | 미달 | 11.6 / `CampaignNewGameButton` |
| `TitleSettingsButton` · button | 520×104.4 | 520×104.4 | 미달 | 11.6 / `CampaignContinueButton` |
| `EndingArchiveButton` · button | 520×104.4 | 520×104.4 | 미달 | 11.6 / `TitleSettingsButton` |
| `TitleLanguage_ko` · button | 229.5×94.5 | 229.5×94.5 | 미달 | 5.5 / `TitleLanguage_en` |
| `TitleLanguage_en` · button | 229.5×94.5 | 229.5×94.5 | 미달 | 5.5 / `TitleLanguage_ko` |
| `TitleLanguage_zh_CN` · button | 229.5×94.5 | 229.5×94.5 | 미달 | 5.5 / `TitleLanguage_en` |
| `TitleUpdateNotesButton` · button | 64.4×64.4 | 64.4×64.4 | 미달 | 603.96 / `EndingArchiveButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `TitleWorkspace` · Panel | 1920×1080 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `CampaignNewGameButton` 새 게임 | Button(보충) | 49 | 충족 / 충족 |
| `CampaignContinueButton` 이어하기 | Button(보충) | 49 | 충족 / 충족 |
| `TitleSettingsButton` 설정 | Button(보충) | 49 | 충족 / 충족 |
| `EndingArchiveButton` 도감 | Button(보충) | 49 | 충족 / 충족 |
| `TitleLanguage_ko` 한국어 | Button(보충) | 38 | 충족 / 충족 |
| `TitleLanguage_en` English | Button(보충) | 38 | 충족 / 충족 |
| `TitleLanguage_zh_CN` 简体中文 | Button(보충) | 38 | 충족 / 충족 |
| `TitleSaveStatus` 저장 기록 없음 · 새 게임으로 시작하세요. | Label | 32 | 충족 / 미달 |
| `InstalledVersionLabel` v1.3.0 | Label | 24 | 미달 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `CampaignNewGameButton` ↔ `CampaignContinueButton` | 11.6 | 아니오 |
| `CampaignContinueButton` ↔ `TitleSettingsButton` | 11.6 | 아니오 |
| `TitleSettingsButton` ↔ `EndingArchiveButton` | 11.6 | 아니오 |
| `TitleLanguage_ko` ↔ `TitleLanguage_en` | 5.5 | 아니오 |
| `TitleLanguage_en` ↔ `TitleLanguage_zh_CN` | 5.5 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `CampaignNewGameButton` | 700, 476.8, 520, 104.4 | 새 게임 |
| `CampaignContinueButton` | 700, 592.8, 520, 104.4 | 저장 기록 없음 · 새 게임으로 시작하세요. |
| `TitleSettingsButton` | 700, 708.8, 520, 104.4 | 설정 |
| `EndingArchiveButton` | 700, 824.8, 520, 104.4 | 도감 |
| `TitleLanguage_ko` | 1197, 962, 229.5, 94.5 | 언어 · 즉시 적용하고 저장합니다. |
| `TitleLanguage_en` | 1432, 962, 229.5, 94.5 | 언어 · 즉시 적용하고 저장합니다. |
| `TitleLanguage_zh_CN` | 1667, 962, 229.5, 94.5 | 언어 · 즉시 적용하고 저장합니다. |
| `TitleSaveStatus` | 560, 408, 800, 49 | 저장 기록 없음 · 새 게임으로 시작하세요. |
| `InstalledVersionLabel` | 32, 1048.4, 150, 31.6 | v1.3.0 |
| `TitleUpdateNotesButton` | 32, 950, 64.4, 64.4 | 업데이트 내역 |

### name_entry · name_entry · DAY1

상태 근거: Name entry navigation fixture; includes LineEdit. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `NameInput` · line_edit | 910×92 | 910×92 | 미달 | 114 / `RandomNameButton` |
| `RandomNameButton` · button | 340×80 | 340×80 | 미달 | 30 / `ConfirmNameButton` |
| `ConfirmNameButton` · button | 540×80 | 540×80 | 미달 | 30 / `RandomNameButton` |
| `NameGuideDismiss` · button | 230×72 | 230×72 | 미달 | 112 / `ConfirmNameButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `NameEntryScreen` · Panel | 1920×1080 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `NameEntryKicker` 새로운 마왕의 첫날 | Label | 54 | 충족 / 충족 |
| `@Label@40` 바티 | Label | 29 | 미달 / 미달 |
| `NameEntryFeedback` F급 신입 마왕 등록서입니다. 위엄 있는 마왕명을 적어 주십시오. | Label | 32 | 충족 / 미달 |
| `NameEntryTitle` F급 신입 마왕 등록 | Label | 54 | 충족 / 충족 |
| `NameEntryPrompt` 입력창을 누를 때만 키보드가 열립니다 | Label | 35 | 충족 / 미달 |
| `NameLengthHint` 마왕명 · 앞뒤 공백을 제외하고 1~12자 | Label | 30 | 충족 / 미달 |
| `RandomNameButton` 무작위 이름 | Button(보충) | 32 | 충족 / 미달 |
| `ConfirmNameButton` 이 이름으로 시작 | Button(보충) | 32 | 충족 / 미달 |
| `NameEntryKeys` Enter · 이름 확정     Tab · 다음 항목 | Label | 27 | 미달 / 미달 |
| `NameEntryGuideBody` 마왕명은 이후 모든 대사와 결과 화면에 표시됩니다. / 입력창은 지금 바로 사용할 수 있습니다. | Label | 30 | 충족 / 미달 |
| `NameGuideDismiss` 안내 닫기 | Button(보충) | 32 | 충족 / 미달 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `NameEntryKicker` | 120, 120, 580, 80 | 새로운 마왕의 첫날 |
| `@Label@40` | 128, 778, 570, 44 | 바티 |
| `NameEntryFeedback` | 128, 823, 570, 100 | F급 신입 마왕 등록서입니다. 위엄 있는 마왕명을 적어 주십시오. |
| `NameEntryTitle` | 850, 168, 910, 80 | F급 신입 마왕 등록 |
| `NameEntryPrompt` | 850, 255, 910, 60 | 입력창을 누를 때만 키보드가 열립니다 |
| `NameLengthHint` | 850, 472, 910, 52 | 마왕명 · 앞뒤 공백을 제외하고 1~12자 |
| `RandomNameButton` | 850, 570, 340, 80 | 무작위 이름<br>누르면 이 항목을 선택하거나 실행합니다. |
| `ConfirmNameButton` | 1220, 570, 540, 80 | 이 이름으로 시작<br>누르면 이 항목을 선택하거나 실행합니다. |
| `NameEntryKeys` | 850, 668, 910, 42 | Enter · 이름 확정     Tab · 다음 항목 |
| `NameEntryGuideBody` | 850, 740, 650, 132 | 마왕명은 이후 모든 대사와 결과 화면에 표시됩니다.<br>입력창은 지금 바로 사용할 수 있습니다. |
| `NameGuideDismiss` | 1530, 762, 230, 72 | 안내 닫기<br>누르면 이 항목을 선택하거나 실행합니다. |

### settings_general · settings · DAY1

상태 근거: Settings category, initial scroll. 캡처: `tmp/android_audit/settings_general.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `SettingsLanguage_ko` · button | 180×80.4 | 180×80.4 | 미달 | 8 / `SettingsLanguage_en` |
| `SettingsLanguage_en` · button | 180×80.4 | 180×80.4 | 미달 | 8 / `SettingsLanguage_ko` |
| `SettingsLanguage_zh_CN` · button | 180×80.4 | 180×80.4 | 미달 | 8 / `SettingsLanguage_en` |
| `TutorialGuidanceLevelOption` · button | 362×96.4 | 362×96.4 | 미달 | 59.6 / `TutorialPracticeButton` |
| `TutorialPracticeButton` · button | 362×80.4 | 362×80.4 | 미달 | 27.6 / `ResetTutorialHistoryButton` |
| `ResetTutorialHistoryButton` · button (비활성) | 218×76.4 | 218×76.4 | 미달 | 27.6 / `TutorialPracticeButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@94` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@103` 일반 | Label | 31 | 충족 / 미달 |
| `@Label@104` 언어와 안내 수준을 바꿔도 스토리 이벤트와 필수 선택은 그대로 유지됩니다. | Label | 29 | 미달 / 미달 |
| `@Label@105` 언어 | Label | 27 | 미달 / 미달 |
| `SettingsLanguage_ko` 한국어 | Button(보충) | 32 | 충족 / 미달 |
| `SettingsLanguage_en` English | Button(보충) | 32 | 충족 / 미달 |
| `SettingsLanguage_zh_CN` 简体中文 | Button(보충) | 32 | 충족 / 미달 |
| `@Label@106` 화면 문구는 즉시 미리보기되며 적용할 때 저장됩니다. | Label | 30 | 충족 / 미달 |
| `@Label@107` 튜토리얼 안내 | Label | 27 | 미달 / 미달 |
| `TutorialGuidanceLevelOption` 전체 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@116` 필수 조작, 선택 대상, 자동전투 관찰 설명을 모두 표시합니다. | Label | 30 | 충족 / 미달 |
| `@Label@117` 튜토리얼 다시 하기 | Label | 27 | 미달 / 미달 |
| `TutorialPracticeButton` 별도 연습 시작 | Button(보충) | 32 | 충족 / 미달 |
| `@Label@118` 현재 언어와 안내 수준으로 시작하며 캠페인 진행은 바뀌지 않습니다. | Label | 18 | 미달 / 미달 |
| `@Label@119` 안내 기록 | Label | 27 | 미달 / 미달 |
| `TutorialHistoryStatusLabel` 닫은 도움말 없음 | Label | 27 | 미달 / 미달 |
| `ResetTutorialHistoryButton` 안내 기록 초기화 | Button(보충) | 30 | 충족 / 미달 |
| `@Label@121` 말풍선과 도움말 기록만 지웁니다. 취소하면 원래 기록으로 돌아갑니다. | Label | 25 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 튜토리얼 안내 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 필수 조작과 선택 대상을 표시합니다. / 자동전투 관찰 설명도 함께 표시합니다. | Label | 32 | 충족 / 미달 |
| `@Label@129` 현재 안내 수준  전체 | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |
| `SettingsLanguage_ko` ↔ `SettingsLanguage_en` | 8 | 아니오 |
| `SettingsLanguage_en` ↔ `SettingsLanguage_zh_CN` | 8 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `SettingsLanguage_ko` | 498, 398, 180, 80.4 | 언어 선택<br>화면과 대사의 언어를 미리 봅니다. 적용을 눌러 저장합니다. |
| `SettingsLanguage_en` | 686, 398, 180, 80.4 | 언어 선택<br>화면과 대사의 언어를 미리 봅니다. 적용을 눌러 저장합니다. |
| `SettingsLanguage_zh_CN` | 874, 398, 180, 80.4 | 언어 선택<br>화면과 대사의 언어를 미리 봅니다. 적용을 눌러 저장합니다. |
| `TutorialGuidanceLevelOption` | 692, 556, 362, 96.4 | 튜토리얼 안내<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `TutorialPracticeButton` | 692, 712, 362, 80.4 | 별도 연습 시작<br>누르면 이 항목을 선택하거나 실행합니다. |
| `ResetTutorialHistoryButton` | 836, 820, 218, 76.4 | 안내 기록 초기화<br>누르면 이 항목을 선택하거나 실행합니다. |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 튜토리얼 안내 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 필수 조작과 선택 대상을 표시합니다.<br>자동전투 관찰 설명도 함께 표시합니다. |
| `@Label@129` | 1152, 676, 570, 60 | 현재 안내 수준  전체 |

### settings_general_bottom · settings · DAY1

상태 근거: Same category, bottom scroll; repeated elements are intentional. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `SettingsLanguage_ko` · button (클립) | 180×54.4 | 180×80.4 | 미달 | 5.5 / `SettingsCategory_audio` |
| `SettingsLanguage_en` · button (클립) | 180×54.4 | 180×80.4 | 미달 | 5.5 / `SettingsCategory_audio` |
| `SettingsLanguage_zh_CN` · button (클립) | 180×54.4 | 180×80.4 | 미달 | 5.5 / `SettingsCategory_accessibility` |
| `TutorialGuidanceLevelOption` · button | 362×96.4 | 362×96.4 | 미달 | 59.6 / `TutorialPracticeButton` |
| `TutorialPracticeButton` · button | 362×80.4 | 362×80.4 | 미달 | 27.6 / `ResetTutorialHistoryButton` |
| `ResetTutorialHistoryButton` · button (비활성) | 218×76.4 | 218×76.4 | 미달 | 27.6 / `TutorialPracticeButton` |
| `QuickDialogueToggle` · button | 798×96.4 | 798×96.4 | 미달 | 41.6 / `ResetTutorialHistoryButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@94` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@105` 언어 | Label | 27 | 미달 / 미달 |
| `SettingsLanguage_ko` 한국어 | Button(보충) | 32 | 충족 / 미달 |
| `SettingsLanguage_en` English | Button(보충) | 32 | 충족 / 미달 |
| `SettingsLanguage_zh_CN` 简体中文 | Button(보충) | 32 | 충족 / 미달 |
| `@Label@106` 화면 문구는 즉시 미리보기되며 적용할 때 저장됩니다. | Label | 30 | 충족 / 미달 |
| `@Label@107` 튜토리얼 안내 | Label | 27 | 미달 / 미달 |
| `TutorialGuidanceLevelOption` 전체 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@116` 필수 조작, 선택 대상, 자동전투 관찰 설명을 모두 표시합니다. | Label | 30 | 충족 / 미달 |
| `@Label@117` 튜토리얼 다시 하기 | Label | 27 | 미달 / 미달 |
| `TutorialPracticeButton` 별도 연습 시작 | Button(보충) | 32 | 충족 / 미달 |
| `@Label@118` 현재 언어와 안내 수준으로 시작하며 캠페인 진행은 바뀌지 않습니다. | Label | 18 | 미달 / 미달 |
| `@Label@119` 안내 기록 | Label | 27 | 미달 / 미달 |
| `TutorialHistoryStatusLabel` 닫은 도움말 없음 | Label | 27 | 미달 / 미달 |
| `ResetTutorialHistoryButton` 안내 기록 초기화 | Button(보충) | 30 | 충족 / 미달 |
| `@Label@121` 말풍선과 도움말 기록만 지웁니다. 취소하면 원래 기록으로 돌아갑니다. | Label | 25 | 미달 / 미달 |
| `QuickDialogueToggle` 빠른 대사 옵션 | CheckBox(보충) | 26 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 튜토리얼 안내 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 필수 조작과 선택 대상을 표시합니다. / 자동전투 관찰 설명도 함께 표시합니다. | Label | 32 | 충족 / 미달 |
| `@Label@129` 현재 안내 수준  전체 | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsLanguage_ko` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsLanguage_en` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsLanguage_en` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsLanguage_zh_CN` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |
| `SettingsLanguage_ko` ↔ `SettingsLanguage_en` | 8 | 아니오 |
| `SettingsLanguage_en` ↔ `SettingsLanguage_zh_CN` | 8 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `SettingsLanguage_ko` | 498, 254, 180, 54.4 | 언어 선택<br>화면과 대사의 언어를 미리 봅니다. 적용을 눌러 저장합니다. |
| `SettingsLanguage_en` | 686, 254, 180, 54.4 | 언어 선택<br>화면과 대사의 언어를 미리 봅니다. 적용을 눌러 저장합니다. |
| `SettingsLanguage_zh_CN` | 874, 254, 180, 54.4 | 언어 선택<br>화면과 대사의 언어를 미리 봅니다. 적용을 눌러 저장합니다. |
| `TutorialGuidanceLevelOption` | 692, 386, 362, 96.4 | 튜토리얼 안내<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `TutorialPracticeButton` | 692, 542, 362, 80.4 | 별도 연습 시작<br>누르면 이 항목을 선택하거나 실행합니다. |
| `ResetTutorialHistoryButton` | 836, 650, 218, 76.4 | 안내 기록 초기화<br>누르면 이 항목을 선택하거나 실행합니다. |
| `QuickDialogueToggle` | 256, 768, 798, 96.4 | 빠른 대사 옵션 |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 튜토리얼 안내 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 필수 조작과 선택 대상을 표시합니다.<br>자동전투 관찰 설명도 함께 표시합니다. |
| `@Label@129` | 1152, 676, 570, 60 | 현재 안내 수준  전체 |

### settings_display · settings · DAY1

상태 근거: Settings category, initial scroll. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `@HSlider@148` · slider | 842×64 | 842×64 | 미달 | 14 / `LayoutModeOption` |
| `LayoutModeOption` · button | 362×96.4 | 362×96.4 | 미달 | 14 / `@HSlider@148` |
| `WindowModeOption` · button | 362×96.4 | 362×96.4 | 미달 | 39.6 / `LayoutModeOption` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@135` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@144` 화면 | Label | 31 | 충족 / 미달 |
| `@Label@145` 레이아웃과 글자 크기는 즉시 미리보기되며 적용할 때 저장됩니다. | Label | 27 | 미달 / 미달 |
| `@Label@146` 글자 크기 | Label | 27 | 미달 / 미달 |
| `@Label@147` 100% | Label | 27 | 미달 / 미달 |
| `@Label@149` 화면 레이아웃 | Label | 27 | 미달 / 미달 |
| `LayoutModeOption` 자동 · 창 너비에 맞춤 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@158` 1440px 미만에서는 Compact를 자동 적용합니다. | Label | 24 | 미달 / 미달 |
| `@Label@159` 창 모드 | Label | 27 | 미달 / 미달 |
| `WindowModeOption` 창모드 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@168` Alt+Enter로 전환할 수 있습니다. 적용하면 다음 실행에도 유지됩니다. | Label | 27 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 몬스터를 배치해 침입 경로를 지키세요. | Label | 32 | 충족 / 미달 |
| `@Label@174` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |
| `@HSlider@148` ↔ `LayoutModeOption` | 14 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `@HSlider@148` | 212, 452, 842, 64 | 글자 크기<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `LayoutModeOption` | 692, 530, 362, 96.4 | 화면 레이아웃<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `WindowModeOption` | 692, 666, 362, 96.4 | 창 모드<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 49 | 몬스터를 배치해 침입 경로를 지키세요. |
| `@Label@174` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### settings_display_bottom · settings · DAY1

상태 근거: Same category, bottom scroll; repeated elements are intentional. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `@HSlider@148` · slider | 842×64 | 842×64 | 미달 | 14 / `LayoutModeOption` |
| `LayoutModeOption` · button | 362×96.4 | 362×96.4 | 미달 | 14 / `@HSlider@148` |
| `WindowModeOption` · button | 362×96.4 | 362×96.4 | 미달 | 39.6 / `LayoutModeOption` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@135` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@144` 화면 | Label | 31 | 충족 / 미달 |
| `@Label@145` 레이아웃과 글자 크기는 즉시 미리보기되며 적용할 때 저장됩니다. | Label | 27 | 미달 / 미달 |
| `@Label@146` 글자 크기 | Label | 27 | 미달 / 미달 |
| `@Label@147` 100% | Label | 27 | 미달 / 미달 |
| `@Label@149` 화면 레이아웃 | Label | 27 | 미달 / 미달 |
| `LayoutModeOption` 자동 · 창 너비에 맞춤 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@158` 1440px 미만에서는 Compact를 자동 적용합니다. | Label | 24 | 미달 / 미달 |
| `@Label@159` 창 모드 | Label | 27 | 미달 / 미달 |
| `WindowModeOption` 창모드 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@168` Alt+Enter로 전환할 수 있습니다. 적용하면 다음 실행에도 유지됩니다. | Label | 27 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 몬스터를 배치해 침입 경로를 지키세요. | Label | 32 | 충족 / 미달 |
| `@Label@174` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |
| `@HSlider@148` ↔ `LayoutModeOption` | 14 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `@HSlider@148` | 212, 392, 842, 64 | 글자 크기<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `LayoutModeOption` | 692, 470, 362, 96.4 | 화면 레이아웃<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `WindowModeOption` | 692, 606, 362, 96.4 | 창 모드<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 49 | 몬스터를 배치해 침입 경로를 지키세요. |
| `@Label@174` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### settings_audio · settings · DAY1

상태 근거: Settings category, initial scroll. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `@HSlider@193` · slider | 624×64 | 624×64 | 미달 | 80 / `@HSlider@196` |
| `@HSlider@196` · slider | 624×64 | 624×64 | 미달 | 80 / `@HSlider@193` |
| `@HSlider@199` · slider | 624×64 | 624×64 | 미달 | 80 / `@HSlider@196` |
| `@HSlider@202` · slider (클립) | 624×38 | 624×64 | 미달 | 62 / `ResetSettingsCategoryButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@180` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@189` 오디오 | Label | 31 | 충족 / 미달 |
| `@Label@190` 조절 중 바로 들을 수 있으며 적용할 때 저장됩니다. | Label | 27 | 미달 / 미달 |
| `@Label@191` 마스터 음량 | Label | 30 | 충족 / 미달 |
| `@Label@192` 85% | Label | 27 | 미달 / 미달 |
| `@Label@194` 음악 | Label | 30 | 충족 / 미달 |
| `@Label@195` 55% | Label | 27 | 미달 / 미달 |
| `@Label@197` 효과음 | Label | 30 | 충족 / 미달 |
| `@Label@198` 90% | Label | 27 | 미달 / 미달 |
| `@Label@200` 목표 경보 소리 | Label | 30 | 충족 / 미달 |
| `@Label@201` 80% | Label | 27 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. | Label | 32 | 충족 / 미달 |
| `@Label@209` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `@HSlider@193` | 250, 434, 624, 64 | 마스터 음량<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `@HSlider@196` | 250, 578, 624, 64 | 음악<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `@HSlider@199` | 250, 722, 624, 64 | 효과음<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `@HSlider@202` | 250, 866, 624, 38 | 목표 경보 소리<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. |
| `@Label@209` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### settings_audio_bottom · settings · DAY1

상태 근거: Same category, bottom scroll; repeated elements are intentional. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `@HSlider@193` · slider | 624×64 | 624×64 | 미달 | 80 / `@HSlider@196` |
| `@HSlider@196` · slider | 624×64 | 624×64 | 미달 | 80 / `@HSlider@193` |
| `@HSlider@199` · slider | 624×64 | 624×64 | 미달 | 80 / `@HSlider@196` |
| `@HSlider@202` · slider | 624×64 | 624×64 | 미달 | 80 / `@HSlider@199` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@180` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@189` 오디오 | Label | 31 | 충족 / 미달 |
| `@Label@190` 조절 중 바로 들을 수 있으며 적용할 때 저장됩니다. | Label | 27 | 미달 / 미달 |
| `@Label@191` 마스터 음량 | Label | 30 | 충족 / 미달 |
| `@Label@192` 85% | Label | 27 | 미달 / 미달 |
| `@Label@194` 음악 | Label | 30 | 충족 / 미달 |
| `@Label@195` 55% | Label | 27 | 미달 / 미달 |
| `@Label@197` 효과음 | Label | 30 | 충족 / 미달 |
| `@Label@198` 90% | Label | 27 | 미달 / 미달 |
| `@Label@200` 목표 경보 소리 | Label | 30 | 충족 / 미달 |
| `@Label@201` 80% | Label | 27 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. | Label | 32 | 충족 / 미달 |
| `@Label@209` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `@HSlider@193` | 250, 374, 624, 64 | 마스터 음량<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `@HSlider@196` | 250, 518, 624, 64 | 음악<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `@HSlider@199` | 250, 662, 624, 64 | 효과음<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `@HSlider@202` | 250, 806, 624, 64 | 목표 경보 소리<br>값 조정<br>끌거나 방향키로 값을 변경합니다. |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. |
| `@Label@209` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### settings_accessibility · settings · DAY1

상태 근거: Settings category, initial scroll. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `HighContrastIconsToggle` · button | 798×96.4 | 798×96.4 | 미달 | 0 / `ObjectiveSummaryToggle` |
| `ObjectiveSummaryToggle` · button | 798×96.4 | 798×96.4 | 미달 | 0 / `HighContrastIconsToggle` |
| `RegionDetailsToggle` · button | 798×96.4 | 798×96.4 | 미달 | 0 / `ObjectiveSummaryToggle` |
| `ReduceRegionMotionToggle` · button | 798×96.4 | 798×96.4 | 미달 | 0 / `RegionDetailsToggle` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@215` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@224` 조작·접근성 | Label | 34 | 충족 / 미달 |
| `@Label@225` 입력 방식: 터치 | Label | 27 | 미달 / 미달 |
| `HighContrastIconsToggle` 고대비 위험 아이콘 | CheckBox(보충) | 26 | 미달 / 미달 |
| `ObjectiveSummaryToggle` 화면 밖 목표 경보 요약 | CheckBox(보충) | 26 | 미달 / 미달 |
| `RegionDetailsToggle` 지역 추가 정보 | CheckBox(보충) | 26 | 미달 / 미달 |
| `ReduceRegionMotionToggle` 지도 움직임 감소 | CheckBox(보충) | 26 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. | Label | 32 | 충족 / 미달 |
| `@Label@233` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |
| `HighContrastIconsToggle` ↔ `ObjectiveSummaryToggle` | 0 | 예 |
| `ObjectiveSummaryToggle` ↔ `RegionDetailsToggle` | 0 | 예 |
| `RegionDetailsToggle` ↔ `ReduceRegionMotionToggle` | 0 | 예 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `HighContrastIconsToggle` | 256, 398, 798, 96.4 | 고대비 위험 아이콘 |
| `ObjectiveSummaryToggle` | 256, 480, 798, 96.4 | 화면 밖 목표 경보 요약 |
| `RegionDetailsToggle` | 256, 562, 798, 96.4 | 지역 추가 정보 |
| `ReduceRegionMotionToggle` | 256, 644, 798, 96.4 | 지도 움직임 감소 |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. |
| `@Label@233` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### settings_accessibility_bottom · settings · DAY1

상태 근거: Same category, bottom scroll; repeated elements are intentional. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `HighContrastIconsToggle` · button (클립) | 798×70.4 | 798×96.4 | 미달 | 0 / `ObjectiveSummaryToggle` |
| `ObjectiveSummaryToggle` · button | 798×96.4 | 798×96.4 | 미달 | 0 / `HighContrastIconsToggle` |
| `RegionDetailsToggle` · button | 798×96.4 | 798×96.4 | 미달 | 0 / `ObjectiveSummaryToggle` |
| `ReduceRegionMotionToggle` · button | 798×96.4 | 798×96.4 | 미달 | 0 / `RegionDetailsToggle` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@215` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `HighContrastIconsToggle` 고대비 위험 아이콘 | CheckBox(보충) | 26 | 미달 / 미달 |
| `ObjectiveSummaryToggle` 화면 밖 목표 경보 요약 | CheckBox(보충) | 26 | 미달 / 미달 |
| `RegionDetailsToggle` 지역 추가 정보 | CheckBox(보충) | 26 | 미달 / 미달 |
| `ReduceRegionMotionToggle` 지도 움직임 감소 | CheckBox(보충) | 26 | 미달 / 미달 |
| `@Label@230` 현재 키 배치 · game_pause: Space - Physical · next_monster: Tab · dialogue_advanc… | Label | 30 | 충족 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. | Label | 32 | 충족 / 미달 |
| `@Label@233` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_display` ↔ `HighContrastIconsToggle` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `HighContrastIconsToggle` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `HighContrastIconsToggle` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |
| `HighContrastIconsToggle` ↔ `ObjectiveSummaryToggle` | 0 | 예 |
| `ObjectiveSummaryToggle` ↔ `RegionDetailsToggle` | 0 | 예 |
| `RegionDetailsToggle` ↔ `ReduceRegionMotionToggle` | 0 | 예 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `HighContrastIconsToggle` | 256, 254, 798, 70.4 | 고대비 위험 아이콘 |
| `ObjectiveSummaryToggle` | 256, 310, 798, 96.4 | 화면 밖 목표 경보 요약 |
| `RegionDetailsToggle` | 256, 392, 798, 96.4 | 지역 추가 정보 |
| `ReduceRegionMotionToggle` | 256, 474, 798, 96.4 | 지도 움직임 감소 |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. |
| `@Label@233` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### settings_combat · settings · DAY1

상태 근거: Settings category, initial scroll. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `SkillCutscenePolicyOption` · button | 362×96.4 | 362×96.4 | 미달 | 127.6 / `CombatReducedEffectsOption` |
| `SkillCutsceneHistoryResetButton` · button | 350×80.4 | 350×80.4 | 미달 | 130 / `CombatReducedEffectsOption` |
| `CombatReducedEffectsOption` · button | 362×96.4 | 362×96.4 | 미달 | 111.6 / `RememberCombatSpeedOption` |
| `RememberCombatSpeedOption` · button (클립) | 362×54 | 362×96.4 | 미달 | 62 / `SettingsGameMenuButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@239` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@248` 전투 연출 | Label | 35 | 충족 / 미달 |
| `@Label@249` 캐릭터 액션이 약 1초 동안 전투를 멈춥니다. 표시 방식을 언제든 바꿀 수 있습니다. | Label | 26 | 미달 / 미달 |
| `@Label@250` 스킬 컷씬 | Label | 30 | 충족 / 미달 |
| `SkillCutscenePolicyOption` 한번만 보기 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@259` 한번만: 첫 완료 기억 · 계속: 매번 표시 / 끄기: 숫자와 기본 타격 효과 유지 | Label | 25 | 미달 / 미달 |
| `SkillCutsceneHistoryResetButton` 본 기록 초기화 | Button(보충) | 32 | 충족 / 미달 |
| `@Label@260` 기억한 스킬: 4 | Label | 24 | 미달 / 미달 |
| `@Label@261` 효과 줄이기 | Label | 29 | 미달 / 미달 |
| `CombatReducedEffectsOption` 기본 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@270` 캐릭터 액션은 유지하면서 번쩍임과 화면 흔들림을 줄입니다. 숫자와 기본 전투 효과도 유지합니다. | Label | 30 | 충족 / 미달 |
| `@Label@271` 전투 속도 고정 | Label | 27 | 미달 / 미달 |
| `RememberCombatSpeedOption` 마지막 선택 속도 유지 | OptionButton(보충) | 27 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. | Label | 32 | 충족 / 미달 |
| `@Label@296` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `SkillCutscenePolicyOption` | 692, 418, 362, 96.4 | 스킬 컷씬<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `SkillCutsceneHistoryResetButton` | 212, 594, 350, 80.4 | 본 기록 초기화<br>누르면 이 항목을 선택하거나 실행합니다. |
| `CombatReducedEffectsOption` | 692, 642, 362, 96.4 | 효과 줄이기<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `RememberCombatSpeedOption` | 692, 850, 362, 54 | 전투 속도 고정<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. |
| `@Label@296` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### settings_combat_bottom · settings · DAY1

상태 근거: Same category, bottom scroll; repeated elements are intentional. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `SettingsCategory_display` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_audio` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_accessibility` · button | 304×94.5 | 304×94.5 | 미달 | 5.5 / `SettingsFieldsScroll` |
| `SettingsCategory_general` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_accessibility` |
| `SettingsCategory_combat` · button | 304×94.5 | 304×94.5 | 미달 | 14 / `SettingsCategory_general` |
| `ResetSettingsCategoryButton` · button | 310×67.4 | 310×67.4 | 미달 | 16 / `SettingsGameMenuButton` |
| `SettingsGameMenuButton` · button | 256×67.4 | 256×67.4 | 미달 | 16 / `ResetSettingsCategoryButton` |
| `CancelSettingsButton` · button | 270×67.4 | 270×67.4 | 미달 | 22 / `ApplySettingsButton` |
| `ApplySettingsButton` · button | 282×67.4 | 282×67.4 | 미달 | 22 / `CancelSettingsButton` |
| `SettingsFieldsScroll` · scroll_container | 940.8×650 | 940.8×650 | 충족 | 5.5 / `SettingsCategory_display` |
| `SkillCutscenePolicyOption` · button (클립) | 362×10.4 | 362×96.4 | 미달 | 5.5 / `SettingsCategory_audio` |
| `SkillCutsceneHistoryResetButton` · button | 350×80.4 | 350×80.4 | 미달 | 95.5 / `SettingsCategory_display` |
| `CombatReducedEffectsOption` · button | 362×96.4 | 362×96.4 | 미달 | 111.6 / `RememberCombatSpeedOption` |
| `RememberCombatSpeedOption` · button | 362×96.4 | 362×96.4 | 미달 | 111.6 / `CombatReducedEffectsOption` |
| `SpectatorAutoCameraOption` · button (클립) | 362×86 | 362×96.4 | 미달 | 62 / `SettingsGameMenuButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `SettingsWorkspace` · Panel | 1632×1000 | 충족 |
| `@Control@239` · Control | 1576×84 | 미달 |
| `SettingsFieldsPanel` · Panel | 930×650 | 충족 |
| `SettingsFields` · Control | 930×650 | 충족 |
| `SettingsPreviewPanel` · Panel | 622×650 | 충족 |
| `SettingsPreviewCard` · PanelContainer | 574×310 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `SettingsHeading` 환경 설정 | Label | 70 | 충족 / 충족 |
| `SettingsInstalledVersionLabel` v1.3.0 | Label | 32 | 충족 / 미달 |
| `SettingsCategory_display` 화면 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_audio` 소리 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_accessibility` 조작·접근성 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_general` 대화·안내 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsCategory_combat` 전투 연출 | Button(보충) | 24 | 미달 / 미달 |
| `ResetSettingsCategoryButton` 이 항목 기본값 | Button(보충) | 24 | 미달 / 미달 |
| `SettingsGameMenuButton` 게임 메뉴 | Button(보충) | 24 | 미달 / 미달 |
| `CancelSettingsButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `ApplySettingsButton` 적용 | Button(보충) | 24 | 미달 / 미달 |
| `SkillCutscenePolicyOption` 한번만 보기 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@259` 한번만: 첫 완료 기억 · 계속: 매번 표시 / 끄기: 숫자와 기본 타격 효과 유지 | Label | 25 | 미달 / 미달 |
| `SkillCutsceneHistoryResetButton` 본 기록 초기화 | Button(보충) | 32 | 충족 / 미달 |
| `@Label@260` 기억한 스킬: 4 | Label | 24 | 미달 / 미달 |
| `@Label@261` 효과 줄이기 | Label | 29 | 미달 / 미달 |
| `CombatReducedEffectsOption` 기본 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@270` 캐릭터 액션은 유지하면서 번쩍임과 화면 흔들림을 줄입니다. 숫자와 기본 전투 효과도 유지합니다. | Label | 30 | 충족 / 미달 |
| `@Label@271` 전투 속도 고정 | Label | 27 | 미달 / 미달 |
| `RememberCombatSpeedOption` 마지막 선택 속도 유지 | OptionButton(보충) | 27 | 미달 / 미달 |
| `@Label@280` 전투 중 선택한 속도를 다음 전투와 재실행 후에도 유지합니다. 튜토리얼 중에는 1배입니다. | Label | 24 | 미달 / 미달 |
| `@Label@281` 관전 자동 카메라 | Label | 30 | 충족 / 미달 |
| `SpectatorAutoCameraOption` 켜기 | OptionButton(보충) | 27 | 미달 / 미달 |
| `Copy` 미리보기 | Label | 35 | 충족 / 미달 |
| `Copy` 변경 미리보기 | Label | 32 | 충족 / 미달 |
| `SettingsPreviewText` 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. | Label | 32 | 충족 / 미달 |
| `@Label@296` 현재 글자 크기  100% | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `SettingsCategory_display` ↔ `SettingsCategory_audio` | 14 | 아니오 |
| `SettingsCategory_display` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsCategory_accessibility` | 14 | 아니오 |
| `SettingsCategory_audio` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_audio` ↔ `SkillCutscenePolicyOption` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsCategory_general` | 14 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SettingsFieldsScroll` | 5.5 | 아니오 |
| `SettingsCategory_accessibility` ↔ `SkillCutscenePolicyOption` | 5.5 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsCategory_combat` | 14 | 아니오 |
| `SettingsCategory_general` ↔ `SettingsFieldsScroll` | 14.3 | 아니오 |
| `ResetSettingsCategoryButton` ↔ `SettingsGameMenuButton` | 16 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `SettingsHeading` | 384, 58, 1152, 104 | 환경 설정 |
| `SettingsInstalledVersionLabel` | 1544, 62, 200, 49 | v1.3.0 |
| `SettingsCategory_display` | 172, 154, 304, 94.5 | 화면 |
| `SettingsCategory_audio` | 490, 154, 304, 94.5 | 소리 |
| `SettingsCategory_accessibility` | 808, 154, 304, 94.5 | 조작·접근성 |
| `SettingsCategory_general` | 1126, 154, 304, 94.5 | 대화·안내 |
| `SettingsCategory_combat` | 1444, 154, 304, 94.5 | 전투 연출 |
| `ResetSettingsCategoryButton` | 172, 966, 310, 67.4 | 이 항목 기본값 |
| `SettingsGameMenuButton` | 498, 966, 256, 67.4 | 게임 메뉴 |
| `CancelSettingsButton` | 1174, 966, 270, 67.4 | 취소 |
| `ApplySettingsButton` | 1466, 966, 282, 67.4 | 적용 |
| `SkillCutscenePolicyOption` | 692, 254, 362, 10.4 | 스킬 컷씬<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `SkillCutsceneHistoryResetButton` | 212, 344, 350, 80.4 | 본 기록 초기화<br>누르면 이 항목을 선택하거나 실행합니다. |
| `CombatReducedEffectsOption` | 692, 392, 362, 96.4 | 효과 줄이기<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `RememberCombatSpeedOption` | 692, 600, 362, 96.4 | 전투 속도 고정<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `SpectatorAutoCameraOption` | 692, 818, 362, 86 | 관전 자동 카메라<br>선택 변경<br>목록을 열어 사용할 항목을 선택합니다. |
| `Copy` | 1152, 278, 570, 53 | 미리보기 |
| `Copy` | 1172, 358, 530, 49 | 변경 미리보기 |
| `SettingsPreviewText` | 1172, 419, 530, 99 | 적용하면 변경한 값을 저장합니다. 취소하면 열기 전의 값으로 돌아갑니다. |
| `@Label@296` | 1152, 676, 570, 60 | 현재 글자 크기  100% |

### dialogue · dialogue · DAY1

상태 근거: Existing onboarding dialogue presenter with representative line. 캡처: `tmp/android_audit/dialogue.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `DialogueTextPanel` · stop_gui_input | 1872×245.8 | 1872×245.8 | 충족 | 672.8 / `DialogueBacklogButton` |
| `DialogueText` · stop_gui_input | 1678×116 | 1678×116 | 미달 | 16 / `LegacyNextButton` |
| `LegacyNextButton` · button | 113.4×113.4 | 113.4×113.4 | 미달 | 16 / `DialogueText` |
| `DialogueBacklogButton` · button | 113.4×113.4 | 113.4×113.4 | 미달 | 11.6 / `LegacyStoryAutoButton` |
| `LegacyStoryAutoButton` · button (비활성) | 113.4×113.4 | 113.4×113.4 | 미달 | 11.6 / `DialogueBacklogButton` |
| `LegacyStorySkipButton` · button (비활성) | 113.4×113.4 | 113.4×113.4 | 미달 | 11.6 / `LegacyStoryAutoButton` |
| `DialogueMenuButton` · button | 113.4×113.4 | 113.4×113.4 | 미달 | 11.6 / `LegacyStorySkipButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `LegacyDialogueScreen` · Panel | 1920×1080 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `DialogueSpeakerLabel` 골딘 | Label | 38 | 충족 / 충족 |
| `DialogueText` 보상 정산 완료. 악명 +1, 골드 소량. 위엄은 장부상 무형자산입니다. 다음 방어 준비까지 확인하겠습니다. | RichTextLabel | 54 | 충족 / 충족 |
| `DialogueBacklogButtonCaption` 로그 | Label | 32 | 충족 / 미달 |
| `LegacyStoryAutoButtonCaption` 자동 | Label | 32 | 충족 / 미달 |
| `LegacyStorySkipButtonCaption` 넘기기 | Label | 32 | 충족 / 미달 |
| `DialogueMenuButtonCaption` 메뉴 | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `DialogueText` ↔ `LegacyNextButton` | 16 | 아니오 |
| `DialogueBacklogButton` ↔ `LegacyStoryAutoButton` | 11.6 | 아니오 |
| `LegacyStoryAutoButton` ↔ `LegacyStorySkipButton` | 11.6 | 아니오 |
| `LegacyStorySkipButton` ↔ `DialogueMenuButton` | 11.6 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `LegacyNextButton` | 1750.4, 910.2, 113.4, 113.4 | 다음 대사 · 수동 입력은 자동 재생을 끕니다. |
| `DialogueBacklogButton` | 1408, 24, 113.4, 113.4 | 대화 로그 · 읽기 전용, 자동 재생 일시정지 |
| `LegacyStoryAutoButton` | 1533, 24, 113.4, 113.4 | 자동 재생 · 오프닝/관리 진입/전투 직전/승리 후 긴 묶음에 사용 |
| `LegacyStorySkipButton` | 1658, 24, 113.4, 113.4 | 넘기기 · 읽은 대화만 허용 |
| `DialogueMenuButton` | 1783, 24, 113.4, 113.4 | 게임 메뉴 · 대화 자동 재생 일시정지 |

### management_build · management · DAY1

상태 근거: DAY1 initial build palette. 캡처: `tmp/android_audit/management_build.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `OpenIntrusionBriefButton` · button | 180×67.4 | 180×67.4 | 미달 | 32 / `FitManagementMapButton` |
| `FitManagementMapButton` · button | 226×67.4 | 226×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ZoomOutManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `FitManagementMapButton` |
| `ZoomInManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ManagementSettingsButton` · button | 78×58 | 78×58 | 미달 | 12 / `ZoomInManagementMapButton` |
| `ManagementMenuButton` · button | 78×58 | 78×58 | 미달 | 14 / `ManagementSettingsButton` |
| `ManagementRecordsButton` · button | 78×58 | 78×58 | 미달 | 0 / `CommonGameMenuButton` |
| `DecorationStatusButton` · button | 340×67.4 | 340×67.4 | 미달 | 557.84 / `BuildingCardScroll` |
| `ManagementTab_build` · button | 210.8×96.4 | 210.8×96.4 | 미달 | 8 / `DecorationPaletteButton` |
| `ManagementTab_roster` · button | 241.8×96.4 | 241.8×96.4 | 미달 | 9.2 / `ManagementTab_build` |
| `ManagementTab_tactics` · button | 208.8×96.4 | 208.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterManagementButton` · button | 237.8×96.4 | 237.8×96.4 | 미달 | 9.2 / `ManagementTab_tactics` |
| `StartCombatButton` · button | 284.8×96.4 | 284.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `BuildingCardScroll` · scroll_container | 1072×132.8 | 1072×132.8 | 충족 | 19.2 / `ManagementTab_build` |
| `FacilityCard_barracks` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_treasure` |
| `FacilityCard_treasure` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_barracks` |
| `FacilityCard_recovery` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_treasure` |
| `FacilityCard_watch_post` · button (클립) | 76×122 | 320×122 | 미달 | 12 / `FacilityCard_recovery` |
| `DecorationPaletteButton` · button | 316×88.4 | 316×88.4 | 미달 | 0 / `PlacementUndoButton` |
| `PlacementUndoButton` · button (비활성) | 280×96.4 | 280×96.4 | 미달 | 0 / `DecorationPaletteButton` |
| `OpenManagementContextButton` · button (클립) | 90×96.4 | 128.8×96.4 | 미달 | 368 / `ManagementRecordsButton` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 0 / `ManagementRecordsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ResourceStatusRail` · Panel | 1888×60 | 미달 |
| `DayStatusBadge` · Label | 170×53 | 미달 |
| `BossHpBar` · Panel | 340×100 | 미달 |
| `ManagementToolTabs` · Panel | 1200×96 | 미달 |
| `BuildingToolbox` · Panel | 1088×144 | 충족 |
| `BuildingSlotCount` · Panel | 340×144 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResourceValue_gold` 1245 | Label | 38 | 충족 / 충족 |
| `ResourceValue_mana` 320 | Label | 38 | 충족 / 충족 |
| `ResourceValue_food` 18 | Label | 38 | 충족 / 충족 |
| `ResourceValue_infamy` 620 | Label | 38 | 충족 / 충족 |
| `DayStatusBadge` DAY 01 | Label | 35 | 충족 / 미달 |
| `OpenIntrusionBriefButton` × 3 | Button(보충) | 24 | 미달 / 미달 |
| `FitManagementMapButton` 지도 전체 | Button(보충) | 24 | 미달 / 미달 |
| `ZoomOutManagementMapButton` − | Button(보충) | 24 | 미달 / 미달 |
| `ZoomInManagementMapButton` + | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 1500 / 1500 | Label | 32 | 충족 / 미달 |
| `@Label@348` 250 / 250 | Label | 32 | 충족 / 미달 |
| `DecorationStatusButton` 성 등급 F · 위압감 0 | Button(보충) | 24 | 미달 / 미달 |
| `ManagementTab_build` 건설 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_roster` 수비대 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_tactics` 전술 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterManagementButton` 몬스터 | Button(보충) | 38 | 충족 / 충족 |
| `StartCombatButton` 전투 시작 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 병영 | Label | 32 | 충족 / 미달 |
| `@Label@371` 100 | Label | 32 | 충족 / 미달 |
| `@Label@373` 2 | Label | 32 | 충족 / 미달 |
| `Copy` 보물 보관실 | Label | 32 | 충족 / 미달 |
| `@Label@378` 120 | Label | 32 | 충족 / 미달 |
| `Copy` 회복 둥지 | Label | 32 | 충족 / 미달 |
| `@Label@383` 80 | Label | 32 | 충족 / 미달 |
| `BuildingSlotCountLabel` 설치 3 / 열린 구역 4 | Label | 32 | 충족 / 미달 |
| `DecorationPaletteButton` 꾸미기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementUndoButton` 되돌리기 | Button(보충) | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `FitManagementMapButton` ↔ `ZoomOutManagementMapButton` | 10 | 아니오 |
| `ZoomOutManagementMapButton` ↔ `ZoomInManagementMapButton` | 10 | 아니오 |
| `ZoomInManagementMapButton` ↔ `ManagementSettingsButton` | 12 | 아니오 |
| `ManagementSettingsButton` ↔ `ManagementMenuButton` | 14 | 아니오 |
| `ManagementMenuButton` ↔ `ManagementRecordsButton` | 14 | 아니오 |
| `ManagementRecordsButton` ↔ `CommonGameMenuButton` | 0 | 예 |
| `ManagementTab_build` ↔ `ManagementTab_roster` | 9.2 | 아니오 |
| `ManagementTab_build` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_build` ↔ `DecorationPaletteButton` | 8 | 아니오 |
| `ManagementTab_roster` ↔ `ManagementTab_tactics` | 9.2 | 아니오 |
| `ManagementTab_roster` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_tactics` ↔ `MonsterManagementButton` | 9.2 | 아니오 |
| `ManagementTab_tactics` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `MonsterManagementButton` ↔ `StartCombatButton` | 9.2 | 아니오 |
| `MonsterManagementButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `StartCombatButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `FacilityCard_barracks` ↔ `FacilityCard_treasure` | 12 | 아니오 |
| `FacilityCard_treasure` ↔ `FacilityCard_recovery` | 12 | 아니오 |
| `FacilityCard_recovery` ↔ `FacilityCard_watch_post` | 12 | 아니오 |
| `DecorationPaletteButton` ↔ `PlacementUndoButton` | 0 | 예 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | 80 |
| `unit:goblin` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | 80 |
| `unit:imp` | circle / 73.47 | 146.93×146.93 | 충족 | 191.49 | 104 |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | 160 |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | 32 |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | 272 |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | 216 |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | 192 |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | 248 |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | 200 |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 210.51×170.95 | 충족 | — | 0 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@TextureRect@332` | 36, 17, 40, 40 | 금화 |
| `ResourceValue_gold` | 82, 15, 120, 57 | 1245 |
| `@TextureRect@333` | 230, 17, 40, 40 | 마력 |
| `ResourceValue_mana` | 276, 15, 120, 57 | 320 |
| `@TextureRect@334` | 424, 17, 40, 40 | 식량 |
| `ResourceValue_food` | 470, 15, 120, 57 | 18 |
| `@TextureRect@335` | 618, 17, 40, 40 | 악명 |
| `ResourceValue_infamy` | 664, 15, 120, 57 | 620 |
| `DayStatusBadge` | 858, 15, 170, 53 | <br>마왕성 1/4 · 신생 마굴<br>구역 6 · 시설 Lv.2 |
| `OpenIntrusionBriefButton` | 1036, 8, 180, 67.4 | 오늘의 침입 · 편대와 실제 경로 보기 |
| `FitManagementMapButton` | 1248, 8, 226, 67.4 | 지도 전체 |
| `ZoomOutManagementMapButton` | 1484, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ZoomInManagementMapButton` | 1554, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ManagementSettingsButton` | 1626, 8, 78, 58 | 설정 |
| `ManagementMenuButton` | 1718, 8, 78, 58 | 메뉴 |
| `ManagementRecordsButton` | 1810, 8, 78, 58 | 기록실 |
| `BossHpBar` | 24, 80, 340, 100 | 현재 보호 목표 체력 |
| `Copy` | 82, 82, 268, 49 | 1500 / 1500 |
| `@Label@348` | 82, 134, 268, 49 | 250 / 250 |
| `DecorationStatusButton` | 24, 194, 340, 67.4 | 마왕성 1/4 · 신생 마굴<br>평가 0 = 성장 0 + 꾸밈 0/10<br>전투 효과 없음 · 부지 확장은 기존 승급 조건 유지 |
| `ManagementTab_build` | 360, 968, 210.8, 96.4 | 건설 |
| `ManagementTab_roster` | 580, 968, 241.8, 96.4 | 수비대 |
| `ManagementTab_tactics` | 831, 968, 208.8, 96.4 | 전술 |
| `MonsterManagementButton` | 1049, 968, 237.8, 96.4 | 몬스터 |
| `StartCombatButton` | 1296, 968, 284.8, 96.4 | 현재 배치와 전술로 전투 시작 |
| `FacilityCard_barracks` | 424, 816, 320, 122 | 병영<br>체력 450 / 몬스터 4명 배치. 연결 구역: 정원 +1 · 공격 +10% · 받는 피해 -8%.<br>입구와 왕좌 사이의 필수 길목, 또는 여러 길이 합쳐지는 방에 적합합니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 532, 822, 204, 60 | 병영 |
| `FacilityCard_treasure` | 756, 816, 320, 122 | 보물 보관실<br>체력 250 / 몬스터 2명 배치. 도둑은 이 방을 목표로 이동합니다. 5초 방치되면 금화 100을 잃습니다.<br>왕좌 직전보다 한 칸 바깥에 두고, 병영이나 감시 초소가 바로 덮을 수 있게 두세요.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 864, 822, 204, 60 | 보물 보관실 |
| `FacilityCard_recovery` | 1088, 816, 320, 122 | 회복 둥지<br>체력 350 / 몬스터 2명 배치. 연결 구역: 초당 8.0 회복.<br>주력 교전 방 뒤쪽이나 왕좌 근처에 두면 후퇴 동선이 짧아집니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 1196, 822, 204, 60 | 회복 둥지 |
| `FacilityCard_watch_post` | 1420, 816, 76, 122 | 감시 초소<br>체력 380 / 몬스터 3명 배치. 연결 구역: 적 이동 -18%. 같은 전선: 적 노출 · 적이 받는 피해 +12%.<br>입구 가까운 긴 경로, 보물 방으로 가는 우회로, 새로 만든 분기 앞에 적합합니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `BuildingSlotCountLabel` | 36, 822, 316, 49 | 설치 3 / 열린 구역 4 |
| `DecorationPaletteButton` | 36, 883, 316, 88.4 | 꾸미기 |
| `PlacementUndoButton` | 24, 968, 280, 96.4 | 마지막 건설·배치 1회와 자원 복원 |
| `OpenManagementContextButton` | 1830, 434, 90, 96.4 | 선택 상세 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### management_build_right · management · DAY1

상태 근거: DAY1 build palette right edge. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `OpenIntrusionBriefButton` · button | 180×67.4 | 180×67.4 | 미달 | 32 / `FitManagementMapButton` |
| `FitManagementMapButton` · button | 226×67.4 | 226×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ZoomOutManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `FitManagementMapButton` |
| `ZoomInManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ManagementSettingsButton` · button | 78×58 | 78×58 | 미달 | 12 / `ZoomInManagementMapButton` |
| `ManagementMenuButton` · button | 78×58 | 78×58 | 미달 | 14 / `ManagementSettingsButton` |
| `ManagementRecordsButton` · button | 78×58 | 78×58 | 미달 | 0 / `CommonGameMenuButton` |
| `DecorationStatusButton` · button | 340×67.4 | 340×67.4 | 미달 | 557.84 / `BuildingCardScroll` |
| `ManagementTab_build` · button | 210.8×96.4 | 210.8×96.4 | 미달 | 8 / `DecorationPaletteButton` |
| `ManagementTab_roster` · button | 241.8×96.4 | 241.8×96.4 | 미달 | 9.2 / `ManagementTab_build` |
| `ManagementTab_tactics` · button | 208.8×96.4 | 208.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterManagementButton` · button | 237.8×96.4 | 237.8×96.4 | 미달 | 9.2 / `ManagementTab_tactics` |
| `StartCombatButton` · button | 284.8×96.4 | 284.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `BuildingCardScroll` · scroll_container | 1072×132.8 | 1072×132.8 | 충족 | 19.2 / `ManagementTab_build` |
| `FacilityCard_recovery` · button (클립) | 76×122 | 320×122 | 미달 | 12 / `FacilityCard_watch_post` |
| `FacilityCard_watch_post` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_recovery` |
| `FacilityCard_ward_core` · button (비활성) | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_watch_post` |
| `FacilityCard_build_slot` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_ward_core` |
| `DecorationPaletteButton` · button | 316×88.4 | 316×88.4 | 미달 | 0 / `PlacementUndoButton` |
| `PlacementUndoButton` · button (비활성) | 280×96.4 | 280×96.4 | 미달 | 0 / `DecorationPaletteButton` |
| `OpenManagementContextButton` · button (클립) | 90×96.4 | 128.8×96.4 | 미달 | 368 / `ManagementRecordsButton` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 0 / `ManagementRecordsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ResourceStatusRail` · Panel | 1888×60 | 미달 |
| `DayStatusBadge` · Label | 170×53 | 미달 |
| `BossHpBar` · Panel | 340×100 | 미달 |
| `ManagementToolTabs` · Panel | 1200×96 | 미달 |
| `BuildingToolbox` · Panel | 1088×144 | 충족 |
| `BuildingSlotCount` · Panel | 340×144 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResourceValue_gold` 1245 | Label | 38 | 충족 / 충족 |
| `ResourceValue_mana` 320 | Label | 38 | 충족 / 충족 |
| `ResourceValue_food` 18 | Label | 38 | 충족 / 충족 |
| `ResourceValue_infamy` 620 | Label | 38 | 충족 / 충족 |
| `DayStatusBadge` DAY 01 | Label | 35 | 충족 / 미달 |
| `OpenIntrusionBriefButton` × 3 | Button(보충) | 24 | 미달 / 미달 |
| `FitManagementMapButton` 지도 전체 | Button(보충) | 24 | 미달 / 미달 |
| `ZoomOutManagementMapButton` − | Button(보충) | 24 | 미달 / 미달 |
| `ZoomInManagementMapButton` + | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 1500 / 1500 | Label | 32 | 충족 / 미달 |
| `@Label@348` 250 / 250 | Label | 32 | 충족 / 미달 |
| `DecorationStatusButton` 성 등급 F · 위압감 0 | Button(보충) | 24 | 미달 / 미달 |
| `ManagementTab_build` 건설 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_roster` 수비대 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_tactics` 전술 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterManagementButton` 몬스터 | Button(보충) | 38 | 충족 / 충족 |
| `StartCombatButton` 전투 시작 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 회복 둥지 | Label | 32 | 충족 / 미달 |
| `Copy` 감시 초소 | Label | 32 | 충족 / 미달 |
| `@Label@388` 100 | Label | 32 | 충족 / 미달 |
| `@Label@390` 50 | Label | 32 | 충족 / 미달 |
| `Copy` 마력 수호핵 | Label | 32 | 충족 / 미달 |
| `@Label@395` 180 | Label | 32 | 충족 / 미달 |
| `@Label@397` 140 | Label | 32 | 충족 / 미달 |
| `Copy` 건설 슬롯 | Label | 32 | 충족 / 미달 |
| `Copy` 무료 | Label | 32 | 충족 / 미달 |
| `BuildingSlotCountLabel` 설치 3 / 열린 구역 4 | Label | 32 | 충족 / 미달 |
| `DecorationPaletteButton` 꾸미기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementUndoButton` 되돌리기 | Button(보충) | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `FitManagementMapButton` ↔ `ZoomOutManagementMapButton` | 10 | 아니오 |
| `ZoomOutManagementMapButton` ↔ `ZoomInManagementMapButton` | 10 | 아니오 |
| `ZoomInManagementMapButton` ↔ `ManagementSettingsButton` | 12 | 아니오 |
| `ManagementSettingsButton` ↔ `ManagementMenuButton` | 14 | 아니오 |
| `ManagementMenuButton` ↔ `ManagementRecordsButton` | 14 | 아니오 |
| `ManagementRecordsButton` ↔ `CommonGameMenuButton` | 0 | 예 |
| `ManagementTab_build` ↔ `ManagementTab_roster` | 9.2 | 아니오 |
| `ManagementTab_build` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_build` ↔ `DecorationPaletteButton` | 8 | 아니오 |
| `ManagementTab_roster` ↔ `ManagementTab_tactics` | 9.2 | 아니오 |
| `ManagementTab_roster` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_tactics` ↔ `MonsterManagementButton` | 9.2 | 아니오 |
| `ManagementTab_tactics` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `MonsterManagementButton` ↔ `StartCombatButton` | 9.2 | 아니오 |
| `MonsterManagementButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `StartCombatButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `FacilityCard_recovery` ↔ `FacilityCard_watch_post` | 12 | 아니오 |
| `FacilityCard_watch_post` ↔ `FacilityCard_ward_core` | 12 | 아니오 |
| `FacilityCard_ward_core` ↔ `FacilityCard_build_slot` | 12 | 아니오 |
| `DecorationPaletteButton` ↔ `PlacementUndoButton` | 0 | 예 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:goblin` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:imp` | circle / 73.47 | 146.93×146.93 | 충족 | 191.49 | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 210.51×170.95 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@TextureRect@332` | 36, 17, 40, 40 | 금화 |
| `ResourceValue_gold` | 82, 15, 120, 57 | 1245 |
| `@TextureRect@333` | 230, 17, 40, 40 | 마력 |
| `ResourceValue_mana` | 276, 15, 120, 57 | 320 |
| `@TextureRect@334` | 424, 17, 40, 40 | 식량 |
| `ResourceValue_food` | 470, 15, 120, 57 | 18 |
| `@TextureRect@335` | 618, 17, 40, 40 | 악명 |
| `ResourceValue_infamy` | 664, 15, 120, 57 | 620 |
| `DayStatusBadge` | 858, 15, 170, 53 | <br>마왕성 1/4 · 신생 마굴<br>구역 6 · 시설 Lv.2 |
| `OpenIntrusionBriefButton` | 1036, 8, 180, 67.4 | 오늘의 침입 · 편대와 실제 경로 보기 |
| `FitManagementMapButton` | 1248, 8, 226, 67.4 | 지도 전체 |
| `ZoomOutManagementMapButton` | 1484, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ZoomInManagementMapButton` | 1554, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ManagementSettingsButton` | 1626, 8, 78, 58 | 설정 |
| `ManagementMenuButton` | 1718, 8, 78, 58 | 메뉴 |
| `ManagementRecordsButton` | 1810, 8, 78, 58 | 기록실 |
| `BossHpBar` | 24, 80, 340, 100 | 현재 보호 목표 체력 |
| `Copy` | 82, 82, 268, 49 | 1500 / 1500 |
| `@Label@348` | 82, 134, 268, 49 | 250 / 250 |
| `DecorationStatusButton` | 24, 194, 340, 67.4 | 마왕성 1/4 · 신생 마굴<br>평가 0 = 성장 0 + 꾸밈 0/10<br>전투 효과 없음 · 부지 확장은 기존 승급 조건 유지 |
| `ManagementTab_build` | 360, 968, 210.8, 96.4 | 건설 |
| `ManagementTab_roster` | 580, 968, 241.8, 96.4 | 수비대 |
| `ManagementTab_tactics` | 831, 968, 208.8, 96.4 | 전술 |
| `MonsterManagementButton` | 1049, 968, 237.8, 96.4 | 몬스터 |
| `StartCombatButton` | 1296, 968, 284.8, 96.4 | 현재 배치와 전술로 전투 시작 |
| `FacilityCard_recovery` | 424, 816, 76, 122 | 회복 둥지<br>체력 350 / 몬스터 2명 배치. 연결 구역: 초당 8.0 회복.<br>주력 교전 방 뒤쪽이나 왕좌 근처에 두면 후퇴 동선이 짧아집니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 424, 822, 68, 60 | 회복 둥지 |
| `FacilityCard_watch_post` | 512, 816, 320, 122 | 감시 초소<br>체력 380 / 몬스터 3명 배치. 연결 구역: 적 이동 -18%. 같은 전선: 적 노출 · 적이 받는 피해 +12%.<br>입구 가까운 긴 경로, 보물 방으로 가는 우회로, 새로 만든 분기 앞에 적합합니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 620, 822, 204, 60 | 감시 초소 |
| `FacilityCard_ward_core` | 844, 816, 320, 122 | 마력 수호핵<br>체력 420 / 몬스터 1명 배치. 모든 방어 구역: 받는 피해 -10%.<br>후방 분기에 두고 병영과 회복 둥지를 함께 보호하면 오래 버틸 수 있습니다.<br>클릭·드롭 즉시 설치 / ESC 취소<br>잠김 |
| `Copy` | 952, 822, 204, 60 | 마력 수호핵 |
| `FacilityCard_build_slot` | 1176, 816, 320, 122 | 건설 슬롯<br>비용 없이 시설을 제거합니다. 완성 방이 아니므로 몬스터 배치는 막힙니다.<br>보물고나 회복 둥지처럼 하나만 유지되는 시설을 옮길 때 임시 공간으로 쓰세요.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 1284, 822, 204, 60 | 건설 슬롯 |
| `Copy` | 1284, 942, 204, 6.8 | 무료 |
| `BuildingSlotCountLabel` | 36, 822, 316, 49 | 설치 3 / 열린 구역 4 |
| `DecorationPaletteButton` | 36, 883, 316, 88.4 | 꾸미기 |
| `PlacementUndoButton` | 24, 968, 280, 96.4 | 마지막 건설·배치 1회와 자원 복원 |
| `OpenManagementContextButton` | 1830, 434, 90, 96.4 | 선택 상세 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### placement_preview · management · DAY1

상태 근거: DAY1 placement ghost on existing build slot; no commit. 캡처: `tmp/android_audit/placement_preview.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `OpenIntrusionBriefButton` · button | 180×67.4 | 180×67.4 | 미달 | 32 / `FitManagementMapButton` |
| `FitManagementMapButton` · button (비활성) | 226×67.4 | 226×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ZoomOutManagementMapButton` · button (비활성) | 60×67.4 | 60×67.4 | 미달 | 10 / `FitManagementMapButton` |
| `ZoomInManagementMapButton` · button (비활성) | 60×67.4 | 60×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ManagementSettingsButton` · button | 78×58 | 78×58 | 미달 | 12 / `ZoomInManagementMapButton` |
| `ManagementMenuButton` · button | 78×58 | 78×58 | 미달 | 14 / `ManagementSettingsButton` |
| `ManagementRecordsButton` · button | 78×58 | 78×58 | 미달 | 0 / `CommonGameMenuButton` |
| `DecorationStatusButton` · button | 340×67.4 | 340×67.4 | 미달 | 323.6 / `BuildDetailImpactScroll` |
| `ManagementTab_build` · button | 210.8×96.4 | 210.8×96.4 | 미달 | 8 / `DecorationPaletteButton` |
| `ManagementTab_roster` · button | 241.8×96.4 | 241.8×96.4 | 미달 | 9.2 / `ManagementTab_build` |
| `ManagementTab_tactics` · button | 208.8×96.4 | 208.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterManagementButton` · button | 237.8×96.4 | 237.8×96.4 | 미달 | 9.2 / `ManagementTab_tactics` |
| `StartCombatButton` · button (비활성) | 284.8×96.4 | 284.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `BuildingCardScroll` · scroll_container | 1072×132.8 | 1072×132.8 | 충족 | 19.2 / `ManagementTab_build` |
| `FacilityCard_barracks` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_treasure` |
| `FacilityCard_treasure` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_barracks` |
| `FacilityCard_recovery` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_treasure` |
| `FacilityCard_watch_post` · button (클립) | 76×122 | 320×122 | 미달 | 12 / `FacilityCard_recovery` |
| `DecorationPaletteButton` · button | 316×88.4 | 316×88.4 | 미달 | 0 / `PlacementUndoButton` |
| `PlacementUndoButton` · button (비활성) | 280×96.4 | 280×96.4 | 미달 | 0 / `DecorationPaletteButton` |
| `BuildDetailImpactScroll` · scroll_container | 608×77 | 608×77 | 미달 | 12 / `CancelBuildingButton` |
| `CancelBuildingButton` · button | 315.8×96.4 | 315.8×96.4 | 미달 | 11.2 / `PlotPreviewRotateButton` |
| `PlotPreviewRotateButton` · button | 192.8×96 | 192.8×96 | 미달 | 11.2 / `CancelBuildingButton` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 0 / `ManagementRecordsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ResourceStatusRail` · Panel | 1888×60 | 미달 |
| `DayStatusBadge` · Label | 170×53 | 미달 |
| `BossHpBar` · Panel | 340×100 | 미달 |
| `ManagementToolTabs` · Panel | 1200×96 | 미달 |
| `BuildingToolbox` · Panel | 1088×144 | 충족 |
| `BuildingSlotCount` · Panel | 340×144 | 충족 |
| `ManagementPrimaryBar` · Panel | 1040×84 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResourceValue_gold` 1245 | Label | 38 | 충족 / 충족 |
| `ResourceValue_mana` 320 | Label | 38 | 충족 / 충족 |
| `ResourceValue_food` 18 | Label | 38 | 충족 / 충족 |
| `ResourceValue_infamy` 620 | Label | 38 | 충족 / 충족 |
| `DayStatusBadge` DAY 01 | Label | 35 | 충족 / 미달 |
| `OpenIntrusionBriefButton` × 3 | Button(보충) | 24 | 미달 / 미달 |
| `FitManagementMapButton` 지도 전체 | Button(보충) | 24 | 미달 / 미달 |
| `ZoomOutManagementMapButton` − | Button(보충) | 24 | 미달 / 미달 |
| `ZoomInManagementMapButton` + | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 1500 / 1500 | Label | 32 | 충족 / 미달 |
| `@Label@421` 250 / 250 | Label | 32 | 충족 / 미달 |
| `DecorationStatusButton` 성 등급 F · 위압감 0 | Button(보충) | 24 | 미달 / 미달 |
| `ManagementTab_build` 건설 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_roster` 수비대 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_tactics` 전술 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterManagementButton` 몬스터 | Button(보충) | 38 | 충족 / 충족 |
| `StartCombatButton` 전투 시작 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 병영 | Label | 32 | 충족 / 미달 |
| `@Label@444` 100 | Label | 32 | 충족 / 미달 |
| `@Label@446` 2 | Label | 32 | 충족 / 미달 |
| `Copy` 보물 보관실 | Label | 32 | 충족 / 미달 |
| `@Label@451` 120 | Label | 32 | 충족 / 미달 |
| `Copy` 회복 둥지 | Label | 32 | 충족 / 미달 |
| `@Label@456` 80 | Label | 32 | 충족 / 미달 |
| `BuildingSlotCountLabel` 설치 3 / 열린 구역 4 | Label | 32 | 충족 / 미달 |
| `DecorationPaletteButton` 꾸미기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementUndoButton` 되돌리기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementFeedbackLabel` 설치할 위치를 클릭하거나 끌어다 놓으세요 · ESC 취소 | Label | 32 | 충족 / 미달 |
| `BuildReviewSummary` 감시 초소 | Label | 32 | 충족 / 미달 |
| `@Label@485` 100 | Label | 32 | 충족 / 미달 |
| `@Label@487` 50 | Label | 32 | 충족 / 미달 |
| `BuildDetailPlacementCount` 배치 0 / 4 | Label | 32 | 충족 / 미달 |
| `BuildDetailEffect` 연결 구역: 적 이동 -18% | Label | 32 | 충족 / 미달 |
| `BuildDetailInstallHint` 클릭·놓기 즉시 설치 / ESC 취소 | Label | 32 | 충족 / 미달 |
| `BuildReviewEffects` 체력 380 / 몬스터 3명 배치. 연결 구역: 적 이동 -18%. 같은 전선: 적 노출 · 적이 받는 피해 +12%. / 경로: 후보 … | Label | 32 | 충족 / 미달 |
| `CancelBuildingButton` 취소 · ESC | Button(보충) | 38 | 충족 / 충족 |
| `PlotPreviewRotateButton` 회전 · R | Button(보충) | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `FitManagementMapButton` ↔ `ZoomOutManagementMapButton` | 10 | 아니오 |
| `ZoomOutManagementMapButton` ↔ `ZoomInManagementMapButton` | 10 | 아니오 |
| `ZoomInManagementMapButton` ↔ `ManagementSettingsButton` | 12 | 아니오 |
| `ManagementSettingsButton` ↔ `ManagementMenuButton` | 14 | 아니오 |
| `ManagementMenuButton` ↔ `ManagementRecordsButton` | 14 | 아니오 |
| `ManagementRecordsButton` ↔ `CommonGameMenuButton` | 0 | 예 |
| `ManagementTab_build` ↔ `ManagementTab_roster` | 9.2 | 아니오 |
| `ManagementTab_build` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_build` ↔ `DecorationPaletteButton` | 8 | 아니오 |
| `ManagementTab_roster` ↔ `ManagementTab_tactics` | 9.2 | 아니오 |
| `ManagementTab_roster` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_tactics` ↔ `MonsterManagementButton` | 9.2 | 아니오 |
| `ManagementTab_tactics` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `MonsterManagementButton` ↔ `StartCombatButton` | 9.2 | 아니오 |
| `MonsterManagementButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `StartCombatButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `FacilityCard_barracks` ↔ `FacilityCard_treasure` | 12 | 아니오 |
| `FacilityCard_treasure` ↔ `FacilityCard_recovery` | 12 | 아니오 |
| `FacilityCard_recovery` ↔ `FacilityCard_watch_post` | 12 | 아니오 |
| `DecorationPaletteButton` ↔ `PlacementUndoButton` | 0 | 예 |
| `BuildDetailImpactScroll` ↔ `CancelBuildingButton` | 12 | 아니오 |
| `BuildDetailImpactScroll` ↔ `PlotPreviewRotateButton` | 12 | 아니오 |
| `CancelBuildingButton` ↔ `PlotPreviewRotateButton` | 11.2 | 아니오 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:goblin` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:imp` | circle / 73.47 | 146.93×146.93 | 충족 | 191.49 | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 210.51×170.95 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@TextureRect@405` | 36, 17, 40, 40 | 금화 |
| `ResourceValue_gold` | 82, 15, 120, 57 | 1245 |
| `@TextureRect@406` | 230, 17, 40, 40 | 마력 |
| `ResourceValue_mana` | 276, 15, 120, 57 | 320 |
| `@TextureRect@407` | 424, 17, 40, 40 | 식량 |
| `ResourceValue_food` | 470, 15, 120, 57 | 18 |
| `@TextureRect@408` | 618, 17, 40, 40 | 악명 |
| `ResourceValue_infamy` | 664, 15, 120, 57 | 620 |
| `DayStatusBadge` | 858, 15, 170, 53 | <br>마왕성 1/4 · 신생 마굴<br>구역 6 · 시설 Lv.2 |
| `OpenIntrusionBriefButton` | 1036, 8, 180, 67.4 | 오늘의 침입 · 편대와 실제 경로 보기 |
| `FitManagementMapButton` | 1248, 8, 226, 67.4 | 지도 전체 |
| `ZoomOutManagementMapButton` | 1484, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ZoomInManagementMapButton` | 1554, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ManagementSettingsButton` | 1626, 8, 78, 58 | 설정 |
| `ManagementMenuButton` | 1718, 8, 78, 58 | 메뉴 |
| `ManagementRecordsButton` | 1810, 8, 78, 58 | 기록실 |
| `BossHpBar` | 24, 80, 340, 100 | 현재 보호 목표 체력 |
| `Copy` | 82, 82, 268, 49 | 1500 / 1500 |
| `@Label@421` | 82, 134, 268, 49 | 250 / 250 |
| `DecorationStatusButton` | 24, 194, 340, 67.4 | 마왕성 1/4 · 신생 마굴<br>평가 0 = 성장 0 + 꾸밈 0/10<br>전투 효과 없음 · 부지 확장은 기존 승급 조건 유지 |
| `ManagementTab_build` | 360, 968, 210.8, 96.4 | 건설 |
| `ManagementTab_roster` | 580, 968, 241.8, 96.4 | 수비대 |
| `ManagementTab_tactics` | 831, 968, 208.8, 96.4 | 전술 |
| `MonsterManagementButton` | 1049, 968, 237.8, 96.4 | 몬스터 |
| `StartCombatButton` | 1296, 968, 284.8, 96.4 | 설치할 위치를 클릭하거나 끌어다 놓으세요 · ESC 취소 |
| `FacilityCard_barracks` | 424, 816, 320, 122 | 병영<br>체력 450 / 몬스터 4명 배치. 연결 구역: 정원 +1 · 공격 +10% · 받는 피해 -8%.<br>입구와 왕좌 사이의 필수 길목, 또는 여러 길이 합쳐지는 방에 적합합니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 532, 822, 204, 60 | 병영 |
| `FacilityCard_treasure` | 756, 816, 320, 122 | 보물 보관실<br>체력 250 / 몬스터 2명 배치. 도둑은 이 방을 목표로 이동합니다. 5초 방치되면 금화 100을 잃습니다.<br>왕좌 직전보다 한 칸 바깥에 두고, 병영이나 감시 초소가 바로 덮을 수 있게 두세요.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 864, 822, 204, 60 | 보물 보관실 |
| `FacilityCard_recovery` | 1088, 816, 320, 122 | 회복 둥지<br>체력 350 / 몬스터 2명 배치. 연결 구역: 초당 8.0 회복.<br>주력 교전 방 뒤쪽이나 왕좌 근처에 두면 후퇴 동선이 짧아집니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 1196, 822, 204, 60 | 회복 둥지 |
| `FacilityCard_watch_post` | 1420, 816, 76, 122 | 감시 초소<br>체력 380 / 몬스터 3명 배치. 연결 구역: 적 이동 -18%. 같은 전선: 적 노출 · 적이 받는 피해 +12%.<br>입구 가까운 긴 경로, 보물 방으로 가는 우회로, 새로 만든 분기 앞에 적합합니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `BuildingSlotCountLabel` | 36, 822, 316, 49 | 설치 3 / 열린 구역 4 |
| `DecorationPaletteButton` | 36, 883, 316, 88.4 | 꾸미기 |
| `PlacementUndoButton` | 24, 968, 280, 96.4 | 마지막 건설·배치 1회와 자원 복원 |
| `PlacementFeedbackLabel` | 392, 88, 1024, 49 | 설치할 위치를 클릭하거나 끌어다 놓으세요 · ESC 취소 |
| `BuildReviewSummary` | 180, 280, 468, 49 | 감시 초소 |
| `BuildDetailPlacementCount` | 180, 402, 468, 49 | 시설 수 / 기존 고유 시설 제한 또는 열린 건설 구역 수 |
| `BuildDetailEffect` | 40, 463, 608, 49 | 체력 380 / 몬스터 3명 배치. 연결 구역: 적 이동 -18%. 같은 전선: 적 노출 · 적이 받는 피해 +12%. |
| `BuildDetailInstallHint` | 40, 524, 608, 49 | 클릭·놓기 즉시 설치 / ESC 취소 |
| `CancelBuildingButton` | 40, 674, 315.8, 96.4 | 취소 · ESC |
| `PlotPreviewRotateButton` | 367, 674, 192.8, 96 | 회전 · R |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### decoration · management · DAY1

상태 근거: DAY1 decoration palette; no placement. 캡처: `tmp/android_audit/decoration.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `OpenIntrusionBriefButton` · button | 180×67.4 | 180×67.4 | 미달 | 32 / `FitManagementMapButton` |
| `FitManagementMapButton` · button | 226×67.4 | 226×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ZoomOutManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `FitManagementMapButton` |
| `ZoomInManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ManagementSettingsButton` · button | 78×58 | 78×58 | 미달 | 12 / `ZoomInManagementMapButton` |
| `ManagementMenuButton` · button | 78×58 | 78×58 | 미달 | 14 / `ManagementSettingsButton` |
| `ManagementRecordsButton` · button | 78×58 | 78×58 | 미달 | 0 / `CommonGameMenuButton` |
| `DecorationStatusButton` · button | 340×67.4 | 340×67.4 | 미달 | 556.6 / `DecorationBackButton` |
| `ManagementTab_build` · button | 210.8×96.4 | 210.8×96.4 | 미달 | 9.2 / `ManagementTab_roster` |
| `ManagementTab_roster` · button | 241.8×96.4 | 241.8×96.4 | 미달 | 9.2 / `ManagementTab_build` |
| `ManagementTab_tactics` · button | 208.8×96.4 | 208.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterManagementButton` · button | 237.8×96.4 | 237.8×96.4 | 미달 | 9.2 / `ManagementTab_tactics` |
| `StartCombatButton` · button | 284.8×96.4 | 284.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `@ScrollContainer@603` · scroll_container | 1072×132.8 | 1072×132.8 | 충족 | 19.2 / `ManagementTab_build` |
| `DecorationCard_torch` · button | 170×122 | 170×122 | 미달 | 12 / `DecorationCard_banner` |
| `DecorationCard_banner` · button | 170×122 | 170×122 | 미달 | 12 / `DecorationCard_torch` |
| `DecorationCard_skulls` · button | 170×122 | 170×122 | 미달 | 12 / `DecorationCard_banner` |
| `DecorationCard_crystal` · button | 170×122 | 170×122 | 미달 | 12 / `DecorationCard_skulls` |
| `DecorationCard_statue` · button | 170×122 | 170×122 | 미달 | 12 / `DecorationCard_crystal` |
| `DecorationCard_brazier` · button (클립) | 162×122 | 170×122 | 미달 | 12 / `DecorationCard_statue` |
| `DecorationBackButton` · button | 156×67.4 | 156×67.4 | 미달 | 2.6 / `DecorationCancelButton` |
| `DecorationRemoveButton` · button | 156×67.4 | 156×67.4 | 미달 | 2.6 / `DecorationCancelButton` |
| `DecorationCancelButton` · button | 322×67.4 | 322×67.4 | 미달 | 2.6 / `DecorationBackButton` |
| `PlacementUndoButton` · button (비활성) | 280×96.4 | 280×96.4 | 미달 | 12.6 / `DecorationCancelButton` |
| `OpenManagementContextButton` · button (클립) | 90×96.4 | 128.8×96.4 | 미달 | 368 / `ManagementRecordsButton` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 0 / `ManagementRecordsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ResourceStatusRail` · Panel | 1888×60 | 미달 |
| `DayStatusBadge` · Label | 170×53 | 미달 |
| `BossHpBar` · Panel | 340×100 | 미달 |
| `ManagementToolTabs` · Panel | 1200×96 | 미달 |
| `DecorationToolbox` · Panel | 1088×144 | 충족 |
| `DecorationActions` · Panel | 340×144 | 충족 |
| `ManagementPrimaryBar` · Panel | 1040×84 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResourceValue_gold` 1245 | Label | 38 | 충족 / 충족 |
| `ResourceValue_mana` 320 | Label | 38 | 충족 / 충족 |
| `ResourceValue_food` 18 | Label | 38 | 충족 / 충족 |
| `ResourceValue_infamy` 620 | Label | 38 | 충족 / 충족 |
| `DayStatusBadge` DAY 01 | Label | 35 | 충족 / 미달 |
| `OpenIntrusionBriefButton` × 3 | Button(보충) | 24 | 미달 / 미달 |
| `FitManagementMapButton` 지도 전체 | Button(보충) | 24 | 미달 / 미달 |
| `ZoomOutManagementMapButton` − | Button(보충) | 24 | 미달 / 미달 |
| `ZoomInManagementMapButton` + | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 1500 / 1500 | Label | 32 | 충족 / 미달 |
| `@Label@589` 250 / 250 | Label | 32 | 충족 / 미달 |
| `DecorationStatusButton` 성 등급 F · 위압감 0 | Button(보충) | 24 | 미달 / 미달 |
| `ManagementTab_build` 건설 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_roster` 수비대 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_tactics` 전술 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterManagementButton` 몬스터 | Button(보충) | 38 | 충족 / 충족 |
| `StartCombatButton` 전투 시작 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 횃불 | Label | 32 | 충족 / 미달 |
| `@Label@606` +1 | Label | 32 | 충족 / 미달 |
| `Copy` 마왕 깃발 | Label | 30 | 충족 / 미달 |
| `@Label@608` +2 | Label | 32 | 충족 / 미달 |
| `Copy` 해골 더미 | Label | 30 | 충족 / 미달 |
| `@Label@610` +1 | Label | 32 | 충족 / 미달 |
| `Copy` 자수정 | Label | 32 | 충족 / 미달 |
| `@Label@612` +2 | Label | 32 | 충족 / 미달 |
| `Copy` 수호 동상 | Label | 32 | 충족 / 미달 |
| `@Label@614` +3 | Label | 32 | 충족 / 미달 |
| `Copy` 용암 화로 | Label | 31 | 충족 / 미달 |
| `@Label@616` +2 | Label | 32 | 충족 / 미달 |
| `DecorationBackButton` 건설 | Button(보충) | 24 | 미달 / 미달 |
| `DecorationRemoveButton` 제거 | Button(보충) | 24 | 미달 / 미달 |
| `DecorationCancelButton` 취소 | Button(보충) | 24 | 미달 / 미달 |
| `PlacementUndoButton` 되돌리기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementFeedbackLabel` 배치를 취소했습니다. 비용은 사용하지 않았습니다. | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `FitManagementMapButton` ↔ `ZoomOutManagementMapButton` | 10 | 아니오 |
| `ZoomOutManagementMapButton` ↔ `ZoomInManagementMapButton` | 10 | 아니오 |
| `ZoomInManagementMapButton` ↔ `ManagementSettingsButton` | 12 | 아니오 |
| `ManagementSettingsButton` ↔ `ManagementMenuButton` | 14 | 아니오 |
| `ManagementMenuButton` ↔ `ManagementRecordsButton` | 14 | 아니오 |
| `ManagementRecordsButton` ↔ `CommonGameMenuButton` | 0 | 예 |
| `ManagementTab_build` ↔ `ManagementTab_roster` | 9.2 | 아니오 |
| `ManagementTab_build` ↔ `@ScrollContainer@603` | 19.2 | 아니오 |
| `ManagementTab_build` ↔ `DecorationCancelButton` | 13.96 | 아니오 |
| `ManagementTab_roster` ↔ `ManagementTab_tactics` | 9.2 | 아니오 |
| `ManagementTab_roster` ↔ `@ScrollContainer@603` | 19.2 | 아니오 |
| `ManagementTab_tactics` ↔ `MonsterManagementButton` | 9.2 | 아니오 |
| `ManagementTab_tactics` ↔ `@ScrollContainer@603` | 19.2 | 아니오 |
| `MonsterManagementButton` ↔ `StartCombatButton` | 9.2 | 아니오 |
| `MonsterManagementButton` ↔ `@ScrollContainer@603` | 19.2 | 아니오 |
| `StartCombatButton` ↔ `@ScrollContainer@603` | 19.2 | 아니오 |
| `DecorationCard_torch` ↔ `DecorationCard_banner` | 12 | 아니오 |
| `DecorationCard_banner` ↔ `DecorationCard_skulls` | 12 | 아니오 |
| `DecorationCard_skulls` ↔ `DecorationCard_crystal` | 12 | 아니오 |
| `DecorationCard_crystal` ↔ `DecorationCard_statue` | 12 | 아니오 |
| `DecorationCard_statue` ↔ `DecorationCard_brazier` | 12 | 아니오 |
| `DecorationBackButton` ↔ `DecorationRemoveButton` | 10 | 아니오 |
| `DecorationBackButton` ↔ `DecorationCancelButton` | 2.6 | 아니오 |
| `DecorationRemoveButton` ↔ `DecorationCancelButton` | 2.6 | 아니오 |
| `DecorationCancelButton` ↔ `PlacementUndoButton` | 12.6 | 아니오 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:goblin` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:imp` | circle / 73.47 | 146.93×146.93 | 충족 | 191.49 | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 210.51×170.95 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@TextureRect@573` | 36, 17, 40, 40 | 금화 |
| `ResourceValue_gold` | 82, 15, 120, 57 | 1245 |
| `@TextureRect@574` | 230, 17, 40, 40 | 마력 |
| `ResourceValue_mana` | 276, 15, 120, 57 | 320 |
| `@TextureRect@575` | 424, 17, 40, 40 | 식량 |
| `ResourceValue_food` | 470, 15, 120, 57 | 18 |
| `@TextureRect@576` | 618, 17, 40, 40 | 악명 |
| `ResourceValue_infamy` | 664, 15, 120, 57 | 620 |
| `DayStatusBadge` | 858, 15, 170, 53 | <br>마왕성 1/4 · 신생 마굴<br>구역 6 · 시설 Lv.2 |
| `OpenIntrusionBriefButton` | 1036, 8, 180, 67.4 | 오늘의 침입 · 편대와 실제 경로 보기 |
| `FitManagementMapButton` | 1248, 8, 226, 67.4 | 지도 전체 |
| `ZoomOutManagementMapButton` | 1484, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ZoomInManagementMapButton` | 1554, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ManagementSettingsButton` | 1626, 8, 78, 58 | 설정 |
| `ManagementMenuButton` | 1718, 8, 78, 58 | 메뉴 |
| `ManagementRecordsButton` | 1810, 8, 78, 58 | 기록실 |
| `BossHpBar` | 24, 80, 340, 100 | 현재 보호 목표 체력 |
| `Copy` | 82, 82, 268, 49 | 1500 / 1500 |
| `@Label@589` | 82, 134, 268, 49 | 250 / 250 |
| `DecorationStatusButton` | 24, 194, 340, 67.4 | 마왕성 1/4 · 신생 마굴<br>평가 0 = 성장 0 + 꾸밈 0/10<br>전투 효과 없음 · 부지 확장은 기존 승급 조건 유지 |
| `ManagementTab_build` | 360, 968, 210.8, 96.4 | 건설 |
| `ManagementTab_roster` | 580, 968, 241.8, 96.4 | 수비대 |
| `ManagementTab_tactics` | 831, 968, 208.8, 96.4 | 전술 |
| `MonsterManagementButton` | 1049, 968, 237.8, 96.4 | 몬스터 |
| `StartCombatButton` | 1296, 968, 284.8, 96.4 | 현재 배치와 전술로 전투 시작 |
| `DecorationCard_torch` | 424, 816, 170, 122 | 횃불 · 위압감 +1<br>빈칸 클릭·터치: 배치 / ESC: 취소<br>전투 효과 없음 |
| `Copy` | 474, 824, 114, 68 | 횃불 |
| `@Label@606` | 482, 894, 104, 49 | +1 |
| `DecorationCard_banner` | 606, 816, 170, 122 | 마왕 깃발 · 위압감 +2<br>빈칸 클릭·터치: 배치 / ESC: 취소<br>전투 효과 없음 |
| `Copy` | 656, 824, 114, 68 | 마왕 깃발 |
| `@Label@608` | 664, 894, 104, 49 | +2 |
| `DecorationCard_skulls` | 788, 816, 170, 122 | 해골 더미 · 위압감 +1<br>빈칸 클릭·터치: 배치 / ESC: 취소<br>전투 효과 없음 |
| `Copy` | 838, 824, 114, 68 | 해골 더미 |
| `@Label@610` | 846, 894, 104, 49 | +1 |
| `DecorationCard_crystal` | 970, 816, 170, 122 | 자수정 · 위압감 +2<br>빈칸 클릭·터치: 배치 / ESC: 취소<br>전투 효과 없음 |
| `Copy` | 1020, 824, 114, 68 | 자수정 |
| `@Label@612` | 1028, 894, 104, 49 | +2 |
| `DecorationCard_statue` | 1152, 816, 170, 122 | 수호 동상 · 위압감 +3<br>빈칸 클릭·터치: 배치 / ESC: 취소<br>전투 효과 없음 |
| `Copy` | 1202, 824, 114, 68 | 수호 동상 |
| `@Label@614` | 1210, 894, 104, 49 | +3 |
| `DecorationCard_brazier` | 1334, 816, 162, 122 | 용암 화로 · 위압감 +2<br>빈칸 클릭·터치: 배치 / ESC: 취소<br>전투 효과 없음 |
| `Copy` | 1384, 824, 112, 68 | 용암 화로 |
| `@Label@616` | 1392, 894, 104, 49 | +2 |
| `DecorationBackButton` | 32, 818, 156, 67.4 | 건설 |
| `DecorationRemoveButton` | 198, 818, 156, 67.4 | 제거 |
| `DecorationCancelButton` | 32, 888, 322, 67.4 | 취소 |
| `PlacementUndoButton` | 24, 968, 280, 96.4 | 마지막 건설·배치 1회와 자원 복원 |
| `PlacementFeedbackLabel` | 392, 88, 1024, 49 | 배치를 취소했습니다. 비용은 사용하지 않았습니다. |
| `OpenManagementContextButton` | 1830, 434, 90, 96.4 | 선택 상세 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### garrison · management · DAY1

상태 근거: DAY1 garrison dock. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `OpenIntrusionBriefButton` · button | 180×67.4 | 180×67.4 | 미달 | 32 / `FitManagementMapButton` |
| `FitManagementMapButton` · button | 226×67.4 | 226×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ZoomOutManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `FitManagementMapButton` |
| `ZoomInManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ManagementSettingsButton` · button | 78×58 | 78×58 | 미달 | 12 / `ZoomInManagementMapButton` |
| `ManagementMenuButton` · button | 78×58 | 78×58 | 미달 | 14 / `ManagementSettingsButton` |
| `ManagementRecordsButton` · button | 78×58 | 78×58 | 미달 | 0 / `CommonGameMenuButton` |
| `DecorationStatusButton` · button | 340×67.4 | 340×67.4 | 미달 | 557.84 / `MonsterRosterScroll` |
| `ManagementTab_build` · button | 210.8×96.4 | 210.8×96.4 | 미달 | 9.2 / `ManagementTab_roster` |
| `ManagementTab_roster` · button | 241.8×96.4 | 241.8×96.4 | 미달 | 9.2 / `ManagementTab_build` |
| `ManagementTab_tactics` · button | 208.8×96.4 | 208.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterManagementButton` · button | 237.8×96.4 | 237.8×96.4 | 미달 | 9.2 / `ManagementTab_tactics` |
| `StartCombatButton` · button | 284.8×96.4 | 284.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterRosterScroll` · scroll_container | 1072×132 | 1072×132 | 충족 | 20 / `ManagementTab_build` |
| `MonsterCard_slime` · button | 330×122 | 330×122 | 미달 | 12 / `MonsterCard_goblin` |
| `MonsterCard_goblin` · button | 330×122 | 330×122 | 미달 | 12 / `MonsterCard_slime` |
| `MonsterCard_imp` · button | 330×122 | 330×122 | 미달 | 12 / `MonsterCard_goblin` |
| `PlacementUndoButton` · button (비활성) | 280×96.4 | 280×96.4 | 미달 | 56 / `ManagementTab_build` |
| `OpenManagementContextButton` · button (클립) | 90×96.4 | 128.8×96.4 | 미달 | 368 / `ManagementRecordsButton` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 0 / `ManagementRecordsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ResourceStatusRail` · Panel | 1888×60 | 미달 |
| `DayStatusBadge` · Label | 170×53 | 미달 |
| `BossHpBar` · Panel | 340×100 | 미달 |
| `ManagementToolTabs` · Panel | 1200×96 | 미달 |
| `MonsterRosterDock` · Panel | 1088×144 | 충족 |
| `RosterStatus` · Panel | 360×164 | 충족 |
| `ManagementPrimaryBar` · Panel | 1040×84 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResourceValue_gold` 1245 | Label | 38 | 충족 / 충족 |
| `ResourceValue_mana` 320 | Label | 38 | 충족 / 충족 |
| `ResourceValue_food` 18 | Label | 38 | 충족 / 충족 |
| `ResourceValue_infamy` 620 | Label | 38 | 충족 / 충족 |
| `DayStatusBadge` DAY 01 | Label | 35 | 충족 / 미달 |
| `OpenIntrusionBriefButton` × 3 | Button(보충) | 24 | 미달 / 미달 |
| `FitManagementMapButton` 지도 전체 | Button(보충) | 24 | 미달 / 미달 |
| `ZoomOutManagementMapButton` − | Button(보충) | 24 | 미달 / 미달 |
| `ZoomInManagementMapButton` + | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 1500 / 1500 | Label | 32 | 충족 / 미달 |
| `@Label@644` 250 / 250 | Label | 32 | 충족 / 미달 |
| `DecorationStatusButton` 성 등급 F · 위압감 0 | Button(보충) | 24 | 미달 / 미달 |
| `ManagementTab_build` 건설 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_roster` 수비대 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_tactics` 전술 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterManagementButton` 몬스터 | Button(보충) | 38 | 충족 / 충족 |
| `StartCombatButton` 전투 시작 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterCard_slime` 푸딩 · Lv.1 / 정문 가시 길목 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterCard_goblin` 곱 · Lv.1 / 정문 가시 길목 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterCard_imp` 핀 · Lv.1 / 왕좌 앞 회랑 | Button(보충) | 38 | 충족 / 충족 |
| `RosterActiveCount` 출전 3 | Label | 32 | 충족 / 미달 |
| `RosterReserveCount` 예비 0 · 지원 0 | Label | 32 | 충족 / 미달 |
| `PlacementUndoButton` 되돌리기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementFeedbackLabel` 배치를 취소했습니다. 비용은 사용하지 않았습니다. | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `FitManagementMapButton` ↔ `ZoomOutManagementMapButton` | 10 | 아니오 |
| `ZoomOutManagementMapButton` ↔ `ZoomInManagementMapButton` | 10 | 아니오 |
| `ZoomInManagementMapButton` ↔ `ManagementSettingsButton` | 12 | 아니오 |
| `ManagementSettingsButton` ↔ `ManagementMenuButton` | 14 | 아니오 |
| `ManagementMenuButton` ↔ `ManagementRecordsButton` | 14 | 아니오 |
| `ManagementRecordsButton` ↔ `CommonGameMenuButton` | 0 | 예 |
| `ManagementTab_build` ↔ `ManagementTab_roster` | 9.2 | 아니오 |
| `ManagementTab_roster` ↔ `ManagementTab_tactics` | 9.2 | 아니오 |
| `ManagementTab_tactics` ↔ `MonsterManagementButton` | 9.2 | 아니오 |
| `MonsterManagementButton` ↔ `StartCombatButton` | 9.2 | 아니오 |
| `MonsterCard_slime` ↔ `MonsterCard_goblin` | 12 | 아니오 |
| `MonsterCard_goblin` ↔ `MonsterCard_imp` | 12 | 아니오 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:goblin` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:imp` | circle / 73.47 | 146.93×146.93 | 충족 | 191.49 | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 210.51×170.95 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@TextureRect@628` | 36, 17, 40, 40 | 금화 |
| `ResourceValue_gold` | 82, 15, 120, 57 | 1245 |
| `@TextureRect@629` | 230, 17, 40, 40 | 마력 |
| `ResourceValue_mana` | 276, 15, 120, 57 | 320 |
| `@TextureRect@630` | 424, 17, 40, 40 | 식량 |
| `ResourceValue_food` | 470, 15, 120, 57 | 18 |
| `@TextureRect@631` | 618, 17, 40, 40 | 악명 |
| `ResourceValue_infamy` | 664, 15, 120, 57 | 620 |
| `DayStatusBadge` | 858, 15, 170, 53 | <br>마왕성 1/4 · 신생 마굴<br>구역 6 · 시설 Lv.2 |
| `OpenIntrusionBriefButton` | 1036, 8, 180, 67.4 | 오늘의 침입 · 편대와 실제 경로 보기 |
| `FitManagementMapButton` | 1248, 8, 226, 67.4 | 지도 전체 |
| `ZoomOutManagementMapButton` | 1484, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ZoomInManagementMapButton` | 1554, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ManagementSettingsButton` | 1626, 8, 78, 58 | 설정 |
| `ManagementMenuButton` | 1718, 8, 78, 58 | 메뉴 |
| `ManagementRecordsButton` | 1810, 8, 78, 58 | 기록실 |
| `BossHpBar` | 24, 80, 340, 100 | 현재 보호 목표 체력 |
| `Copy` | 82, 82, 268, 49 | 1500 / 1500 |
| `@Label@644` | 82, 134, 268, 49 | 250 / 250 |
| `DecorationStatusButton` | 24, 194, 340, 67.4 | 마왕성 1/4 · 신생 마굴<br>평가 0 = 성장 0 + 꾸밈 0/10<br>전투 효과 없음 · 부지 확장은 기존 승급 조건 유지 |
| `ManagementTab_build` | 360, 968, 210.8, 96.4 | 건설 |
| `ManagementTab_roster` | 580, 968, 241.8, 96.4 | 수비대 |
| `ManagementTab_tactics` | 831, 968, 208.8, 96.4 | 전술 |
| `MonsterManagementButton` | 1049, 968, 237.8, 96.4 | 몬스터 |
| `StartCombatButton` | 1296, 968, 284.8, 96.4 | 현재 배치와 전술로 전투 시작 |
| `MonsterCard_slime` | 424, 816, 330, 122 | 카드→방 또는 드래그로 배치 / 정원은 지도에 표시 |
| `MonsterCard_goblin` | 766, 816, 330, 122 | 카드→방 또는 드래그로 배치 / 정원은 지도에 표시 |
| `MonsterCard_imp` | 1108, 816, 330, 122 | 카드→방 또는 드래그로 배치 / 정원은 지도에 표시 |
| `RosterActiveCount` | 36, 802, 336, 49 | 출전 3 |
| `RosterReserveCount` | 36, 863, 336, 49 | 예비 0 · 지원 0 |
| `PlacementUndoButton` | 24, 968, 280, 96.4 | 마지막 건설·배치 1회와 자원 복원 |
| `PlacementFeedbackLabel` | 392, 88, 1024, 49 | 배치를 취소했습니다. 비용은 사용하지 않았습니다. |
| `OpenManagementContextButton` | 1830, 434, 90, 96.4 | 선택 상세 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### management_tactics · management · DAY1

상태 근거: DAY1 tactics and room directive. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `OpenIntrusionBriefButton` · button | 180×67.4 | 180×67.4 | 미달 | 32 / `FitManagementMapButton` |
| `FitManagementMapButton` · button | 226×67.4 | 226×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ZoomOutManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `FitManagementMapButton` |
| `ZoomInManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ManagementSettingsButton` · button | 78×58 | 78×58 | 미달 | 12 / `ZoomInManagementMapButton` |
| `ManagementMenuButton` · button | 78×58 | 78×58 | 미달 | 14 / `ManagementSettingsButton` |
| `ManagementRecordsButton` · button | 78×58 | 78×58 | 미달 | 0 / `CommonGameMenuButton` |
| `DecorationStatusButton` · button | 340×67.4 | 340×67.4 | 미달 | 425.44 / `@ScrollContainer@702` |
| `ManagementTab_build` · button | 210.8×96.4 | 210.8×96.4 | 미달 | 9.2 / `ManagementTab_roster` |
| `ManagementTab_roster` · button | 241.8×96.4 | 241.8×96.4 | 미달 | 9.2 / `ManagementTab_build` |
| `ManagementTab_tactics` · button | 208.8×96.4 | 208.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterManagementButton` · button | 237.8×96.4 | 237.8×96.4 | 미달 | 9.2 / `ManagementTab_tactics` |
| `StartCombatButton` · button | 284.8×96.4 | 284.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `@ScrollContainer@702` · scroll_container | 1064×260 | 1064×260 | 충족 | 26 / `ManagementTab_build` |
| `GlobalDirective_defense` · button | 343×96.4 | 343×96.4 | 미달 | 11.6 / `ManagementContextAction_defender_connector` |
| `GlobalDirective_all_out` · button | 343×96.4 | 343×96.4 | 미달 | 11.6 / `ManagementContextAction_chronicle` |
| `GlobalDirective_survival` · button | 344×96.4 | 344×96.4 | 미달 | 12 / `GlobalDirective_all_out` |
| `ManagementContextAction_defender_connector` · button (비활성) (클립) | 200.8×91 | 200.8×94.5 | 미달 | 11.2 / `ManagementContextAction_chronicle` |
| `ManagementContextAction_chronicle` · button (클립) | 241.8×91 | 241.8×94.5 | 미달 | 11.2 / `ManagementContextAction_defender_connector` |
| `PlacementUndoButton` · button (비활성) | 280×96.4 | 280×96.4 | 미달 | 56 / `ManagementTab_build` |
| `OpenManagementContextButton` · button (클립) | 90×96.4 | 128.8×96.4 | 미달 | 368 / `ManagementRecordsButton` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 0 / `ManagementRecordsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ResourceStatusRail` · Panel | 1888×60 | 미달 |
| `DayStatusBadge` · Label | 170×53 | 미달 |
| `BossHpBar` · Panel | 340×100 | 미달 |
| `ManagementToolTabs` · Panel | 1200×96 | 미달 |
| `TacticsToolbox` · Panel | 1088×284 | 충족 |
| `ManagementPrimaryBar` · Panel | 1040×84 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResourceValue_gold` 1245 | Label | 38 | 충족 / 충족 |
| `ResourceValue_mana` 320 | Label | 38 | 충족 / 충족 |
| `ResourceValue_food` 18 | Label | 38 | 충족 / 충족 |
| `ResourceValue_infamy` 620 | Label | 38 | 충족 / 충족 |
| `DayStatusBadge` DAY 01 | Label | 35 | 충족 / 미달 |
| `OpenIntrusionBriefButton` × 3 | Button(보충) | 24 | 미달 / 미달 |
| `FitManagementMapButton` 지도 전체 | Button(보충) | 24 | 미달 / 미달 |
| `ZoomOutManagementMapButton` − | Button(보충) | 24 | 미달 / 미달 |
| `ZoomInManagementMapButton` + | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 1500 / 1500 | Label | 32 | 충족 / 미달 |
| `@Label@688` 250 / 250 | Label | 32 | 충족 / 미달 |
| `DecorationStatusButton` 성 등급 F · 위압감 0 | Button(보충) | 24 | 미달 / 미달 |
| `ManagementTab_build` 건설 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_roster` 수비대 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_tactics` 전술 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterManagementButton` 몬스터 | Button(보충) | 38 | 충족 / 충족 |
| `StartCombatButton` 전투 시작 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 전체 전술 · 모든 방 | Label | 32 | 충족 / 미달 |
| `GlobalDirective_defense` 사수 | Button(보충) | 38 | 충족 / 충족 |
| `GlobalDirective_all_out` 총공격 | Button(보충) | 38 | 충족 / 충족 |
| `GlobalDirective_survival` 생존 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementContextAction_defender_connector` 샛문 복구 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementContextAction_chronicle` 전선 연대기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementUndoButton` 되돌리기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementFeedbackLabel` 배치를 취소했습니다. 비용은 사용하지 않았습니다. | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `FitManagementMapButton` ↔ `ZoomOutManagementMapButton` | 10 | 아니오 |
| `ZoomOutManagementMapButton` ↔ `ZoomInManagementMapButton` | 10 | 아니오 |
| `ZoomInManagementMapButton` ↔ `ManagementSettingsButton` | 12 | 아니오 |
| `ManagementSettingsButton` ↔ `ManagementMenuButton` | 14 | 아니오 |
| `ManagementMenuButton` ↔ `ManagementRecordsButton` | 14 | 아니오 |
| `ManagementRecordsButton` ↔ `CommonGameMenuButton` | 0 | 예 |
| `ManagementTab_build` ↔ `ManagementTab_roster` | 9.2 | 아니오 |
| `ManagementTab_roster` ↔ `ManagementTab_tactics` | 9.2 | 아니오 |
| `ManagementTab_tactics` ↔ `MonsterManagementButton` | 9.2 | 아니오 |
| `MonsterManagementButton` ↔ `StartCombatButton` | 9.2 | 아니오 |
| `GlobalDirective_defense` ↔ `GlobalDirective_all_out` | 12 | 아니오 |
| `GlobalDirective_defense` ↔ `ManagementContextAction_defender_connector` | 11.6 | 아니오 |
| `GlobalDirective_defense` ↔ `ManagementContextAction_chronicle` | 11.6 | 아니오 |
| `GlobalDirective_all_out` ↔ `GlobalDirective_survival` | 12 | 아니오 |
| `GlobalDirective_all_out` ↔ `ManagementContextAction_chronicle` | 11.6 | 아니오 |
| `ManagementContextAction_defender_connector` ↔ `ManagementContextAction_chronicle` | 11.2 | 아니오 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:goblin` | circle / 73.47 | 146.93×146.93 | 충족 | 0 | — |
| `unit:imp` | circle / 73.47 | 146.93×146.93 | 충족 | 191.49 | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 189.88×94.94 | 미달 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 210.51×170.95 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@TextureRect@672` | 36, 17, 40, 40 | 금화 |
| `ResourceValue_gold` | 82, 15, 120, 57 | 1245 |
| `@TextureRect@673` | 230, 17, 40, 40 | 마력 |
| `ResourceValue_mana` | 276, 15, 120, 57 | 320 |
| `@TextureRect@674` | 424, 17, 40, 40 | 식량 |
| `ResourceValue_food` | 470, 15, 120, 57 | 18 |
| `@TextureRect@675` | 618, 17, 40, 40 | 악명 |
| `ResourceValue_infamy` | 664, 15, 120, 57 | 620 |
| `DayStatusBadge` | 858, 15, 170, 53 | <br>마왕성 1/4 · 신생 마굴<br>구역 6 · 시설 Lv.2 |
| `OpenIntrusionBriefButton` | 1036, 8, 180, 67.4 | 오늘의 침입 · 편대와 실제 경로 보기 |
| `FitManagementMapButton` | 1248, 8, 226, 67.4 | 지도 전체 |
| `ZoomOutManagementMapButton` | 1484, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ZoomInManagementMapButton` | 1554, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ManagementSettingsButton` | 1626, 8, 78, 58 | 설정 |
| `ManagementMenuButton` | 1718, 8, 78, 58 | 메뉴 |
| `ManagementRecordsButton` | 1810, 8, 78, 58 | 기록실 |
| `BossHpBar` | 24, 80, 340, 100 | 현재 보호 목표 체력 |
| `Copy` | 82, 82, 268, 49 | 1500 / 1500 |
| `@Label@688` | 82, 134, 268, 49 | 250 / 250 |
| `DecorationStatusButton` | 24, 194, 340, 67.4 | 마왕성 1/4 · 신생 마굴<br>평가 0 = 성장 0 + 꾸밈 0/10<br>전투 효과 없음 · 부지 확장은 기존 승급 조건 유지 |
| `ManagementTab_build` | 360, 968, 210.8, 96.4 | 건설 |
| `ManagementTab_roster` | 580, 968, 241.8, 96.4 | 수비대 |
| `ManagementTab_tactics` | 831, 968, 208.8, 96.4 | 전술 |
| `MonsterManagementButton` | 1049, 968, 237.8, 96.4 | 몬스터 |
| `StartCombatButton` | 1296, 968, 284.8, 96.4 | 현재 배치와 전술로 전투 시작 |
| `Copy` | 428, 682, 1054, 49 | 전체 전술 · 모든 방 |
| `GlobalDirective_defense` | 428, 743, 343, 96.4 | 배치 방과 이웃 방까지만 교전 · 저체력 방어막과 방어선 복귀 |
| `GlobalDirective_all_out` | 783, 743, 343, 96.4 | 배치 방을 벗어나 우선 적을 전장 전체에서 추격 · 공격↑/피해↑ |
| `GlobalDirective_survival` | 1138, 743, 344, 96.4 | 체력이 낮으면 회복 시설로 이탈 · 피해 감소와 생존 우선 |
| `ManagementContextAction_defender_connector` | 428, 851, 200.8, 91 | 금화 1000 / 마력 100 |
| `ManagementContextAction_chronicle` | 640, 851, 241.8, 91 | 전선·심장 숙련, 라이벌 관계, 합동 기억, 최근 회차와 후일담을 확인합니다. |
| `PlacementUndoButton` | 24, 968, 280, 96.4 | 마지막 건설·배치 1회와 자원 복원 |
| `PlacementFeedbackLabel` | 392, 88, 1024, 49 | 배치를 취소했습니다. 비용은 사용하지 않았습니다. |
| `OpenManagementContextButton` | 1830, 434, 90, 96.4 | 선택 상세 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### monster · monster · DAY1

상태 근거: DAY1 monster management. 캡처: `tmp/android_audit/monster.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `MonsterScope_owned` · button | 170×94.5 | 170×94.5 | 미달 | 11.5 / `MonsterRosterScroll` |
| `MonsterScope_codex` · button | 173×94.5 | 173×94.5 | 미달 | 11.5 / `MonsterRosterScroll` |
| `MonsterRosterScroll` · scroll_container | 360×642 | 360×642 | 충족 | 11.5 / `MonsterScope_owned` |
| `CHR_PUDDING` · button | 360×148 | 360×148 | 충족 | 11.5 / `MonsterScope_owned` |
| `CHR_GOB` · button | 360×148 | 360×148 | 충족 | 12 / `CHR_PUDDING` |
| `CHR_PYNN` · button | 360×148 | 360×148 | 충족 | 12 / `CHR_GOB` |
| `MonsterBackButton` · button | 360×96.4 | 360×96.4 | 미달 | 12 / `MonsterRosterScroll` |
| `MonsterTab_training` · button | 136.6×105.3 | 136.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_skills` · button | 135.6×105.3 | 135.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_promotion` · button | 138.6×105.3 | 138.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_duo` · button | 157.6×105.3 | 157.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_memory` · button | 138.6×105.3 | 138.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterGrowthScroll` · scroll_container | 976×607 | 976×607 | 충족 | 11.7 / `MonsterTab_training` |
| `MonsterTrainingButton` · button | 976×112 | 976×112 | 미달 | 72 / `MonsterGrowthScroll` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 179 / `MonsterGrowthScroll` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `MonsterResourceRail` · Panel | 1750×68 | 미달 |
| `MonsterRosterPanel` · Panel | 400×956 | 충족 |
| `MonsterGrowthTools` · Panel | 1448×956 | 충족 |
| `MonsterHero` · Control | 400×908 | 충족 |
| `MonsterSelectedDetail` · Control | 384×300 | 충족 |
| `TrainingPreviewCard` · PanelContainer | 966×264 | 충족 |
| `@Control@779` · Control | 817×48 | 미달 |
| `@ProgressBar@782` · ProgressBar | 696.6×32.4 | 미달 |
| `@Control@786` · Control | 817×48 | 미달 |
| `@ProgressBar@789` · ProgressBar | 677.6×32.4 | 미달 |
| `TrainingStatsCard` · PanelContainer | 520×204 | 충족 |
| `TrainingCostCard` · PanelContainer | 434×204 | 충족 |
| `FocusGrowthExplanationChip` · PanelContainer | 966×68 | 미달 |
| `FocusPreparationChip` · PanelContainer | 966×35 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `MonsterResource_gold` 1245 | Label | 38 | 충족 / 충족 |
| `MonsterResource_mana` 320 | Label | 38 | 충족 / 충족 |
| `MonsterResource_food` 18 | Label | 38 | 충족 / 충족 |
| `MonsterResource_infamy` 620 | Label | 38 | 충족 / 충족 |
| `Copy` DAY 01 | Label | 38 | 충족 / 충족 |
| `Copy` 동료 | Label | 32 | 충족 / 미달 |
| `MonsterScope_owned` 보유 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterScope_codex` 도감 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 푸딩 | Label | 32 | 충족 / 미달 |
| `@Label@744` Lv.1 · 출전 | Label | 32 | 충족 / 미달 |
| `Copy` 곱 | Label | 32 | 충족 / 미달 |
| `@Label@750` Lv.1 · 출전 | Label | 32 | 충족 / 미달 |
| `Copy` 핀 | Label | 32 | 충족 / 미달 |
| `@Label@756` Lv.1 · 출전 | Label | 32 | 충족 / 미달 |
| `MonsterBackButton` 관리로 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterName` 푸딩 | Label | 57 | 충족 / 충족 |
| `MonsterRole` 근접 탱커 | Label | 41 | 충족 / 충족 |
| `MonsterLevel` Lv.1 | Label | 49 | 충족 / 충족 |
| `MonsterBond` 유대 0/100 · 낯섦 | Label | 35 | 충족 / 미달 |
| `MonsterDeployment` 출전 · 정문 가시 길목 | Label | 32 | 충족 / 미달 |
| `MonsterTab_training` 훈련 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_skills` 스킬 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_promotion` 전직 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_duo` 합동기 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_memory` 기억 | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 훈련 미리보기 | Label | 32 | 충족 / 미달 |
| `TrainingExpPreview` Lv.1 → Lv.1 | Label | 32 | 충족 / 미달 |
| `@Label@778` 현재 | Label | 32 | 충족 / 미달 |
| `@Label@783` 0 / 50 | Label | 32 | 충족 / 미달 |
| `@Label@785` 훈련 후 | Label | 32 | 충족 / 미달 |
| `@Label@790` 20 / 50 | Label | 32 | 충족 / 미달 |
| `TrainingStats_max_hp` 체력  180 → 180  (+0) | Label | 32 | 충족 / 미달 |
| `TrainingStats_atk` 공격  8 → 8  (+0) | Label | 32 | 충족 / 미달 |
| `TrainingStats_def` 방어  8 → 8  (+0) | Label | 32 | 충족 / 미달 |
| `TrainingPrice` 금화 30 | Label | 32 | 충족 / 미달 |
| `TrainingGain` EXP +20 | Label | 32 | 충족 / 미달 |
| `TrainingLimits` 오늘 0/2 · 하루 2회 | Label | 32 | 충족 / 미달 |
| `FocusGrowthExplanation` 영구 성장 · EXP +20 | Label | 32 | 충족 / 미달 |
| `FocusPreparation` 다음 전투 준비 · 별도 효과 | Label | 32 | 충족 / 미달 |
| `TrainingCap` 현재 장 훈련 상한 Lv.3 | Label | 32 | 충족 / 미달 |
| `TrainingButtonCaption` 훈련하기 | Label | 30 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `MonsterScope_owned` ↔ `MonsterScope_codex` | 16 | 아니오 |
| `MonsterScope_owned` ↔ `MonsterRosterScroll` | 11.5 | 아니오 |
| `MonsterScope_owned` ↔ `CHR_PUDDING` | 11.5 | 아니오 |
| `MonsterScope_codex` ↔ `MonsterRosterScroll` | 11.5 | 아니오 |
| `MonsterScope_codex` ↔ `CHR_PUDDING` | 11.5 | 아니오 |
| `MonsterRosterScroll` ↔ `MonsterBackButton` | 12 | 아니오 |
| `CHR_PUDDING` ↔ `CHR_GOB` | 12 | 아니오 |
| `CHR_GOB` ↔ `CHR_PYNN` | 12 | 아니오 |
| `MonsterTab_training` ↔ `MonsterTab_skills` | 15.4 | 아니오 |
| `MonsterTab_training` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_skills` ↔ `MonsterTab_promotion` | 15.4 | 아니오 |
| `MonsterTab_skills` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_promotion` ↔ `MonsterTab_duo` | 15.4 | 아니오 |
| `MonsterTab_promotion` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_duo` ↔ `MonsterTab_memory` | 15.4 | 아니오 |
| `MonsterTab_duo` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_memory` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `MonsterResource_gold` | 102, 28, 220, 56 | 1245 |
| `MonsterResource_mana` | 422, 28, 220, 56 | 320 |
| `MonsterResource_food` | 742, 28, 220, 56 | 18 |
| `MonsterResource_infamy` | 1062, 28, 220, 56 | 620 |
| `Copy` | 1474, 28, 250, 56 | DAY 01 |
| `Copy` | 44, 120, 360, 48 | 동료 |
| `MonsterScope_owned` | 44, 180, 170, 94.5 | 보유 |
| `MonsterScope_codex` | 230, 180, 173, 94.5 | 도감 |
| `CHR_PUDDING` | 44, 286, 360, 148 | 푸딩 · Lv.1 · 출전 |
| `Copy` | 148, 296, 246, 48 | 푸딩 |
| `@Label@744` | 148, 356, 246, 48 | Lv.1 · 출전 |
| `CHR_GOB` | 44, 446, 360, 148 | 곱 · Lv.1 · 출전 |
| `Copy` | 148, 456, 246, 48 | 곱 |
| `@Label@750` | 148, 516, 246, 48 | Lv.1 · 출전 |
| `CHR_PYNN` | 44, 606, 360, 148 | 핀 · Lv.1 · 출전 |
| `Copy` | 148, 616, 246, 48 | 핀 |
| `@Label@756` | 148, 676, 246, 48 | Lv.1 · 출전 |
| `MonsterBackButton` | 44, 940, 360, 96.4 | 관리로 |
| `MonsterName` | 480, 132, 384, 84 | 푸딩 |
| `MonsterRole` | 480, 202, 384, 80 | 근접 탱커 |
| `MonsterLevel` | 480, 292, 384, 72 | Lv.1 |
| `MonsterBond` | 480, 356, 384, 68 | 유대 0/100 · 낯섦 |
| `MonsterDeployment` | 480, 920, 384, 92 | 출전 · 정문 가시 길목 |
| `MonsterTab_training` | 896, 124, 136.6, 105.3 | 훈련 |
| `MonsterTab_skills` | 1048, 124, 135.6, 105.3 | 스킬 |
| `MonsterTab_promotion` | 1199, 124, 138.6, 105.3 | 전직 |
| `MonsterTab_duo` | 1353, 124, 157.6, 105.3 | 합동기 |
| `MonsterTab_memory` | 1526, 124, 138.6, 105.3 | 기억 |
| `Copy` | 914, 259, 930, 48 | 훈련 미리보기 |
| `TrainingExpPreview` | 914, 319, 930, 48 | Lv.1 → Lv.1 |
| `@ProgressBar@782` | 1027, 384.4, 696.6, 32.4 | 현재 · EXP 0 / 50 · Lv.1 |
| `@ProgressBar@789` | 1027, 444.4, 677.6, 32.4 | 훈련 후 · EXP 20 / 50 · Lv.1 |
| `TrainingStats_max_hp` | 962, 535, 436, 48 | 같은 현재 준비 효과를 포함한 수치 비교 |
| `TrainingStats_atk` | 962, 595, 436, 48 | 같은 현재 준비 효과를 포함한 수치 비교 |
| `TrainingStats_def` | 962, 655, 436, 48 | 같은 현재 준비 효과를 포함한 수치 비교 |
| `TrainingPrice` | 1498, 535, 346, 48 | 금화 30 |
| `TrainingGain` | 1446, 595, 398, 48 | EXP +20 |
| `TrainingLimits` | 1446, 655, 398, 48 | 오늘 0/2 · 하루 2회 |
| `FocusGrowthExplanation` | 950, 743, 902, 48 | 훈련: 유료 EXP +20. 집중성장: 승리 결과에서 1명, 무료 EXP +8. EXP는 날짜가 지나도 유지됩니다. |
| `FocusPreparation` | 950, 823, 902, 25 | 집중성장의 준비 효과는 지정된 다음 방어 DAY에만 적용됩니다.<br>HP+24 · 방어+1 |
| `TrainingCap` | 896, 860, 976, 48 | 현재 장 훈련 상한 Lv.3 |
| `MonsterTrainingButton` | 896, 920, 976, 112 | 훈련하기 |
| `TrainingButtonCaption` | 906, 930, 956, 44 | 훈련하기 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### chronicle_0 · chronicle · DAY1

상태 근거: Chronicle tab 0, current profile. 캡처: `tmp/android_audit/chronicle_0.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `ChronicleTab0` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab1` |
| `ChronicleTab1` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab0` |
| `ChronicleTab2` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab1` |
| `ChronicleTab3` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab2` |
| `ChronicleSectionList` · scroll_container | 354×720 | 354×720 | 충족 | 34 / `ChronicleScroll0` |
| `ChronicleSection0` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection1` |
| `ChronicleSection1` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection0` |
| `ChronicleSection2` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection1` |
| `ChronicleScroll0` · scroll_container | 1362×624 | 1362×624 | 충족 | 34 / `ChronicleSectionList` |
| `ChronicleSettingsShortcut` · button | 250×70 | 250×70 | 미달 | 26 / `RecordCompanionOption` |
| `RecordCompanionOption` · button (클립) | 260×72 | 260×96.4 | 미달 | 24 / `RecordsMemoryButton` |
| `RecordsMemoryButton` · button | 230×70 | 230×70 | 미달 | 22 / `RecordsCompanionButton` |
| `RecordsCompanionButton` · button | 250×70 | 250×70 | 미달 | 22 / `RecordsMemoryButton` |
| `ChronicleCloseButton` · button | 220×70 | 220×70 | 미달 | 46 / `ChronicleScroll0` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 70 / `ChronicleTab3` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ChronicleScreen` · Control | 1920×1080 | 충족 |
| `RecordsTitleBanner` · Panel | 1812×98 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `@Label@854` 기록실 · 연대기 | Label | 65 | 충족 / 충족 |
| `ChronicleTab0` 전선·심장 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab1` 라이벌·합동 기억 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab2` 회차·후일담 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab3` 엔딩 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection0` 전선 숙련 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection1` 심장 숙련 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection2` 의회 지역 숙련 · 0~3등급 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@873` 전선 숙련 | Label | 43 | 충족 / 충족 |
| `ChroniclePageText0` • 용사의 서약 /   0% · 클리어 0회 /  / • 성광 정화 /   잠김 · 셀렌 관계 45 · 관련 엔딩/교리 격파 · 첫 초대… | Label | 34 | 충족 / 미달 |
| `ChronicleSettingsShortcut` 조작·접근성 설정 | Button(보충) | 24 | 미달 / 미달 |
| `RecordCompanionOption` 슬라임 | OptionButton(보충) | 24 | 미달 / 미달 |
| `RecordsMemoryButton` 동료 기억 | Button(보충) | 24 | 미달 / 미달 |
| `RecordsCompanionButton` 동료 도감 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleCloseButton` 돌아가기 | Button(보충) | 24 | 미달 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `ChronicleTab0` ↔ `ChronicleTab1` | 14 | 아니오 |
| `ChronicleTab1` ↔ `ChronicleTab2` | 14 | 아니오 |
| `ChronicleTab2` ↔ `ChronicleTab3` | 14 | 아니오 |
| `ChronicleSection0` ↔ `ChronicleSection1` | 12 | 아니오 |
| `ChronicleSection1` ↔ `ChronicleSection2` | 12 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@Label@854` | 74, 20, 1772, 95 | 기록실 · 연대기 |
| `ChronicleTab0` | 54, 132, 442.5, 70 | 전선·심장 |
| `ChronicleTab1` | 510.5, 132, 442.5, 70 | 라이벌·합동 기억 |
| `ChronicleTab2` | 967, 132, 442.5, 70 | 회차·후일담 |
| `ChronicleTab3` | 1423.5, 132, 442.5, 70 | 엔딩 |
| `ChronicleSection0` | 76, 244, 354, 94 | 전선 숙련 |
| `ChronicleSection1` | 76, 350, 354, 94 | 심장 숙련 |
| `ChronicleSection2` | 76, 456, 354, 94 | 의회 지역 숙련 · 0~3등급 |
| `@Label@873` | 464, 246, 1368, 64 | 전선 숙련 |
| `ChronicleSettingsShortcut` | 54, 1008, 250, 70 | 조작·접근성 설정 |
| `RecordCompanionOption` | 330, 1008, 260, 72 | 동료 기록 선택 |
| `RecordsMemoryButton` | 614, 1008, 230, 70 | 동료 기억 |
| `RecordsCompanionButton` | 866, 1008, 250, 70 | 동료 도감 |
| `ChronicleCloseButton` | 1646, 1008, 220, 70 | 돌아가기 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### chronicle_1 · chronicle · DAY1

상태 근거: Chronicle tab 1, current profile. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `ChronicleTab0` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab1` |
| `ChronicleTab1` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab0` |
| `ChronicleTab2` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab1` |
| `ChronicleTab3` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab2` |
| `ChronicleSectionList` · scroll_container | 354×720 | 354×720 | 충족 | 34 / `ChronicleScroll1` |
| `ChronicleSection0` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection1` |
| `ChronicleSection1` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection0` |
| `ChronicleSection2` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection1` |
| `ChronicleScroll1` · scroll_container | 1362×624 | 1362×624 | 충족 | 34 / `ChronicleSectionList` |
| `ChronicleSettingsShortcut` · button | 250×70 | 250×70 | 미달 | 26 / `RecordCompanionOption` |
| `RecordCompanionOption` · button (클립) | 260×72 | 260×96.4 | 미달 | 24 / `RecordsMemoryButton` |
| `RecordsMemoryButton` · button | 230×70 | 230×70 | 미달 | 22 / `RecordsCompanionButton` |
| `RecordsCompanionButton` · button | 250×70 | 250×70 | 미달 | 22 / `RecordsMemoryButton` |
| `ChronicleCloseButton` · button | 220×70 | 220×70 | 미달 | 46 / `ChronicleScroll1` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 70 / `ChronicleTab3` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ChronicleScreen` · Control | 1920×1080 | 충족 |
| `RecordsTitleBanner` · Panel | 1812×98 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `@Label@893` 기록실 · 연대기 | Label | 65 | 충족 / 충족 |
| `ChronicleTab0` 전선·심장 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab1` 라이벌·합동 기억 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab2` 회차·후일담 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab3` 엔딩 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection0` 라이벌 관계 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection1` 합동 기억 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection2` 경쟁 마왕 서신 · 각 5개 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@912` 라이벌 관계 | Label | 43 | 충족 / 충족 |
| `ChroniclePageText1` • 레온  0/100 /   관계 사건에서 상승 /  / • 셀렌  0/100 /   관계 45에서 전선 해금 /  / • 로만  0/1… | Label | 34 | 충족 / 미달 |
| `ChronicleSettingsShortcut` 조작·접근성 설정 | Button(보충) | 24 | 미달 / 미달 |
| `RecordCompanionOption` 슬라임 | OptionButton(보충) | 24 | 미달 / 미달 |
| `RecordsMemoryButton` 동료 기억 | Button(보충) | 24 | 미달 / 미달 |
| `RecordsCompanionButton` 동료 도감 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleCloseButton` 돌아가기 | Button(보충) | 24 | 미달 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `ChronicleTab0` ↔ `ChronicleTab1` | 14 | 아니오 |
| `ChronicleTab1` ↔ `ChronicleTab2` | 14 | 아니오 |
| `ChronicleTab2` ↔ `ChronicleTab3` | 14 | 아니오 |
| `ChronicleSection0` ↔ `ChronicleSection1` | 12 | 아니오 |
| `ChronicleSection1` ↔ `ChronicleSection2` | 12 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@Label@893` | 74, 20, 1772, 95 | 기록실 · 연대기 |
| `ChronicleTab0` | 54, 132, 442.5, 70 | 전선·심장 |
| `ChronicleTab1` | 510.5, 132, 442.5, 70 | 라이벌·합동 기억 |
| `ChronicleTab2` | 967, 132, 442.5, 70 | 회차·후일담 |
| `ChronicleTab3` | 1423.5, 132, 442.5, 70 | 엔딩 |
| `ChronicleSection0` | 76, 244, 354, 94 | 라이벌 관계 |
| `ChronicleSection1` | 76, 350, 354, 94 | 합동 기억 |
| `ChronicleSection2` | 76, 456, 354, 94 | 경쟁 마왕 서신 · 각 5개 |
| `@Label@912` | 464, 246, 1368, 64 | 라이벌 관계 |
| `ChronicleSettingsShortcut` | 54, 1008, 250, 70 | 조작·접근성 설정 |
| `RecordCompanionOption` | 330, 1008, 260, 72 | 동료 기록 선택 |
| `RecordsMemoryButton` | 614, 1008, 230, 70 | 동료 기억 |
| `RecordsCompanionButton` | 866, 1008, 250, 70 | 동료 도감 |
| `ChronicleCloseButton` | 1646, 1008, 220, 70 | 돌아가기 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### chronicle_2 · chronicle · DAY1

상태 근거: Chronicle tab 2, current profile. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `ChronicleTab0` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab1` |
| `ChronicleTab1` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab0` |
| `ChronicleTab2` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab1` |
| `ChronicleTab3` · button | 442.5×70 | 442.5×70 | 미달 | 14 / `ChronicleTab2` |
| `ChronicleSectionList` · scroll_container | 354×720 | 354×720 | 충족 | 34 / `ChronicleScroll2` |
| `ChronicleSection0` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection1` |
| `ChronicleSection1` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection0` |
| `ChronicleSection2` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection1` |
| `ChronicleSection3` · button | 354×94 | 354×94 | 미달 | 12 / `ChronicleSection2` |
| `ChronicleScroll2` · scroll_container | 1362×624 | 1362×624 | 충족 | 34 / `ChronicleSectionList` |
| `ChronicleSettingsShortcut` · button | 250×70 | 250×70 | 미달 | 26 / `RecordCompanionOption` |
| `RecordCompanionOption` · button (클립) | 260×72 | 260×96.4 | 미달 | 24 / `RecordsMemoryButton` |
| `RecordsMemoryButton` · button | 230×70 | 230×70 | 미달 | 22 / `RecordsCompanionButton` |
| `RecordsCompanionButton` · button | 250×70 | 250×70 | 미달 | 22 / `RecordsMemoryButton` |
| `ChronicleCloseButton` · button | 220×70 | 220×70 | 미달 | 46 / `ChronicleScroll2` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 70 / `ChronicleTab3` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ChronicleScreen` · Control | 1920×1080 | 충족 |
| `RecordsTitleBanner` · Panel | 1812×98 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `@Label@932` 기록실 · 연대기 | Label | 65 | 충족 / 충족 |
| `ChronicleTab0` 전선·심장 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab1` 라이벌·합동 기억 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab2` 회차·후일담 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleTab3` 엔딩 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection0` 최근 5회차 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection1` 최근 5회 의회 회차 비교 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection2` 왕관 진화 도감 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleSection3` 후일담 카드 | Button(보충) | 24 | 미달 / 미달 |
| `@Label@953` 최근 5회차 | Label | 43 | 충족 / 충족 |
| `ChroniclePageText2` • 아직 완료한 회차가 없습니다. | Label | 34 | 충족 / 미달 |
| `ChronicleSettingsShortcut` 조작·접근성 설정 | Button(보충) | 24 | 미달 / 미달 |
| `RecordCompanionOption` 슬라임 | OptionButton(보충) | 24 | 미달 / 미달 |
| `RecordsMemoryButton` 동료 기억 | Button(보충) | 24 | 미달 / 미달 |
| `RecordsCompanionButton` 동료 도감 | Button(보충) | 24 | 미달 / 미달 |
| `ChronicleCloseButton` 돌아가기 | Button(보충) | 24 | 미달 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `ChronicleTab0` ↔ `ChronicleTab1` | 14 | 아니오 |
| `ChronicleTab1` ↔ `ChronicleTab2` | 14 | 아니오 |
| `ChronicleTab2` ↔ `ChronicleTab3` | 14 | 아니오 |
| `ChronicleSection0` ↔ `ChronicleSection1` | 12 | 아니오 |
| `ChronicleSection1` ↔ `ChronicleSection2` | 12 | 아니오 |
| `ChronicleSection2` ↔ `ChronicleSection3` | 12 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@Label@932` | 74, 20, 1772, 95 | 기록실 · 연대기 |
| `ChronicleTab0` | 54, 132, 442.5, 70 | 전선·심장 |
| `ChronicleTab1` | 510.5, 132, 442.5, 70 | 라이벌·합동 기억 |
| `ChronicleTab2` | 967, 132, 442.5, 70 | 회차·후일담 |
| `ChronicleTab3` | 1423.5, 132, 442.5, 70 | 엔딩 |
| `ChronicleSection0` | 76, 244, 354, 94 | 최근 5회차 |
| `ChronicleSection1` | 76, 350, 354, 94 | 최근 5회 의회 회차 비교 |
| `ChronicleSection2` | 76, 456, 354, 94 | 왕관 진화 도감 |
| `ChronicleSection3` | 76, 562, 354, 94 | 후일담 카드 |
| `@Label@953` | 464, 246, 1368, 64 | 최근 5회차 |
| `ChronicleSettingsShortcut` | 54, 1008, 250, 70 | 조작·접근성 설정 |
| `RecordCompanionOption` | 330, 1008, 260, 72 | 동료 기록 선택 |
| `RecordsMemoryButton` | 614, 1008, 230, 70 | 동료 기억 |
| `RecordsCompanionButton` | 866, 1008, 250, 70 | 동료 도감 |
| `ChronicleCloseButton` | 1646, 1008, 220, 70 | 돌아가기 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### ending_archive · ending_archive · DAY1

상태 근거: Ending record archive, current profile. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `RecordsEndingTab` · button | 892×67.4 | 892×67.4 | 미달 | 14 / `RecordsChronicleTab` |
| `RecordsChronicleTab` · button | 906×67.4 | 906×67.4 | 미달 | 14 / `RecordsEndingTab` |
| `CampaignConfirmButton` · button | 400×67.4 | 400×67.4 | 미달 | 76 / `CampaignDetailScroll` |
| `CampaignChoiceScroll` · scroll_container | 524×672 | 524×672 | 충족 | 36.6 / `RecordsEndingTab` |
| `CampaignDetailScroll` · scroll_container | 1196×656 | 1196×656 | 충족 | 44.6 / `RecordsEndingTab` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 70 / `RecordsChronicleTab` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `CampaignWorkspace` · Panel | 1920×1080 | 충족 |
| `RecordsTitleBanner` · Panel | 1812×98 | 미달 |
| `CampaignChoiceList` · Panel | 556×704 | 충족 |
| `CampaignChoiceDetail` · Panel | 1260×704 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `RecordsEndingTab` 엔딩 | Button(보충) | 24 | 미달 / 미달 |
| `RecordsChronicleTab` 연대기 | Button(보충) | 24 | 미달 / 미달 |
| `CampaignActionNotice` 발견한 결말만 표시합니다. | Label | 32 | 충족 / 미달 |
| `CampaignConfirmButton` 돌아가기 | Button(보충) | 24 | 미달 / 미달 |
| `RecordsHeading` 기록실 · 엔딩 | Label | 65 | 충족 / 충족 |
| `@Label@985` 아직 발견한 엔딩이 없습니다. | Label | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `RecordsEndingTab` ↔ `RecordsChronicleTab` | 14 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `RecordsEndingTab` | 54, 132, 892, 67.4 | 엔딩 |
| `RecordsChronicleTab` | 960, 132, 906, 67.4 | 연대기 |
| `CampaignActionNotice` | 40, 950, 1200, 72 | 발견한 결말만 표시합니다. |
| `CampaignConfirmButton` | 1480, 976, 400, 67.4 | 돌아가기 |
| `RecordsHeading` | 74, 20, 1772, 96 | 기록실 · 엔딩 |
| `@Label@985` | 652, 244, 1196, 72 | 아직 발견한 엔딩이 없습니다. |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### memory_archive · memory_archive · DAY1

상태 근거: Companion memory record, current profile. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `MonsterScope_owned` · button | 170×94.5 | 170×94.5 | 미달 | 11.5 / `MonsterRosterScroll` |
| `MonsterScope_codex` · button | 173×94.5 | 173×94.5 | 미달 | 11.5 / `MonsterRosterScroll` |
| `MonsterRosterScroll` · scroll_container | 360×642 | 360×642 | 충족 | 11.5 / `MonsterScope_owned` |
| `CHR_PUDDING` · button | 360×148 | 360×148 | 충족 | 11.5 / `MonsterScope_owned` |
| `CHR_GOB` · button | 360×148 | 360×148 | 충족 | 12 / `CHR_PUDDING` |
| `CHR_PYNN` · button | 360×148 | 360×148 | 충족 | 12 / `CHR_GOB` |
| `MonsterBackButton` · button | 360×96.4 | 360×96.4 | 미달 | 12 / `MonsterRosterScroll` |
| `MonsterTab_training` · button | 136.6×105.3 | 136.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_skills` · button | 135.6×105.3 | 135.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_promotion` · button | 138.6×105.3 | 138.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_duo` · button | 157.6×105.3 | 157.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterTab_memory` · button | 138.6×105.3 | 138.6×105.3 | 미달 | 11.7 / `MonsterGrowthScroll` |
| `MonsterGrowthScroll` · scroll_container | 976×779 | 976×779 | 충족 | 11.7 / `MonsterTab_training` |
| `MemoryDuoButton` · button | 976×94.5 | 976×94.5 | 미달 | 443.7 / `MonsterTab_training` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 179 / `MonsterGrowthScroll` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `MonsterResourceRail` · Panel | 1750×68 | 미달 |
| `MonsterRosterPanel` · Panel | 400×956 | 충족 |
| `MonsterGrowthTools` · Panel | 1448×956 | 충족 |
| `MonsterHero` · Control | 400×908 | 충족 |
| `MonsterSelectedDetail` · Control | 384×300 | 충족 |
| `MemoryOverviewCard` · PanelContainer | 976×204 | 충족 |
| `MemoryLocked1Chip` · PanelContainer | 482×68 | 미달 |
| `MemoryLocked2Chip` · PanelContainer | 482×68 | 미달 |
| `MemoryLocked3Chip` · PanelContainer | 482×68 | 미달 |
| `MemoryLocked4Chip` · PanelContainer | 482×68 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `MonsterResource_gold` 1245 | Label | 38 | 충족 / 충족 |
| `MonsterResource_mana` 320 | Label | 38 | 충족 / 충족 |
| `MonsterResource_food` 18 | Label | 38 | 충족 / 충족 |
| `MonsterResource_infamy` 620 | Label | 38 | 충족 / 충족 |
| `Copy` DAY 01 | Label | 38 | 충족 / 충족 |
| `Copy` 동료 | Label | 32 | 충족 / 미달 |
| `MonsterScope_owned` 보유 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterScope_codex` 도감 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 푸딩 | Label | 32 | 충족 / 미달 |
| `@Label@1005` Lv.1 · 출전 | Label | 32 | 충족 / 미달 |
| `Copy` 곱 | Label | 32 | 충족 / 미달 |
| `@Label@1011` Lv.1 · 출전 | Label | 32 | 충족 / 미달 |
| `Copy` 핀 | Label | 32 | 충족 / 미달 |
| `@Label@1017` Lv.1 · 출전 | Label | 32 | 충족 / 미달 |
| `MonsterBackButton` 관리로 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterName` 푸딩 | Label | 57 | 충족 / 충족 |
| `MonsterRole` 근접 탱커 | Label | 41 | 충족 / 충족 |
| `MonsterLevel` Lv.1 | Label | 49 | 충족 / 충족 |
| `MonsterBond` 유대 0/100 · 낯섦 | Label | 35 | 충족 / 미달 |
| `MonsterDeployment` 출전 · 정문 가시 길목 | Label | 32 | 충족 / 미달 |
| `MonsterTab_training` 훈련 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_skills` 스킬 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_promotion` 전직 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_duo` 합동기 | Button(보충) | 24 | 미달 / 미달 |
| `MonsterTab_memory` 기억 | Button(보충) | 24 | 미달 / 미달 |
| `MemoryArchiveTitle` 기억 조각 · 유대 기억 / 회차 계승 / 합동 기억 | Label | 32 | 충족 / 미달 |
| `MemoryBond` 유대 0/100 · 해금된 기억 0개 | Label | 32 | 충족 / 미달 |
| `MemorySource` 함께한 시간 → 유대 → 기억 | Label | 32 | 충족 / 미달 |
| `MemoryLocked1` 미해금 · 유대 25에서 기억 단계 1 | Label | 32 | 충족 / 미달 |
| `MemoryLocked2` 미해금 · 유대 50에서 기억 단계 2 | Label | 32 | 충족 / 미달 |
| `MemoryLocked3` 미해금 · 유대 75에서 기억 단계 3 | Label | 32 | 충족 / 미달 |
| `MemoryLocked4` 미해금 · 유대 100에서 기억 단계 4 | Label | 32 | 충족 / 미달 |
| `MemoryEmptyState` 아직 해금된 기억이 없습니다. | Label | 32 | 충족 / 미달 |
| `MemoryDuoButton` 합동 기억의 해금 상태 보기 | Button(보충) | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `MonsterScope_owned` ↔ `MonsterScope_codex` | 16 | 아니오 |
| `MonsterScope_owned` ↔ `MonsterRosterScroll` | 11.5 | 아니오 |
| `MonsterScope_owned` ↔ `CHR_PUDDING` | 11.5 | 아니오 |
| `MonsterScope_codex` ↔ `MonsterRosterScroll` | 11.5 | 아니오 |
| `MonsterScope_codex` ↔ `CHR_PUDDING` | 11.5 | 아니오 |
| `MonsterRosterScroll` ↔ `MonsterBackButton` | 12 | 아니오 |
| `CHR_PUDDING` ↔ `CHR_GOB` | 12 | 아니오 |
| `CHR_GOB` ↔ `CHR_PYNN` | 12 | 아니오 |
| `MonsterTab_training` ↔ `MonsterTab_skills` | 15.4 | 아니오 |
| `MonsterTab_training` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_skills` ↔ `MonsterTab_promotion` | 15.4 | 아니오 |
| `MonsterTab_skills` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_promotion` ↔ `MonsterTab_duo` | 15.4 | 아니오 |
| `MonsterTab_promotion` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_duo` ↔ `MonsterTab_memory` | 15.4 | 아니오 |
| `MonsterTab_duo` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |
| `MonsterTab_memory` ↔ `MonsterGrowthScroll` | 11.7 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `MonsterResource_gold` | 102, 28, 220, 56 | 1245 |
| `MonsterResource_mana` | 422, 28, 220, 56 | 320 |
| `MonsterResource_food` | 742, 28, 220, 56 | 18 |
| `MonsterResource_infamy` | 1062, 28, 220, 56 | 620 |
| `Copy` | 1474, 28, 250, 56 | DAY 01 |
| `Copy` | 44, 120, 360, 48 | 동료 |
| `MonsterScope_owned` | 44, 180, 170, 94.5 | 보유 |
| `MonsterScope_codex` | 230, 180, 173, 94.5 | 도감 |
| `CHR_PUDDING` | 44, 286, 360, 148 | 푸딩 · Lv.1 · 출전 |
| `Copy` | 148, 296, 246, 48 | 푸딩 |
| `@Label@1005` | 148, 356, 246, 48 | Lv.1 · 출전 |
| `CHR_GOB` | 44, 446, 360, 148 | 곱 · Lv.1 · 출전 |
| `Copy` | 148, 456, 246, 48 | 곱 |
| `@Label@1011` | 148, 516, 246, 48 | Lv.1 · 출전 |
| `CHR_PYNN` | 44, 606, 360, 148 | 핀 · Lv.1 · 출전 |
| `Copy` | 148, 616, 246, 48 | 핀 |
| `@Label@1017` | 148, 676, 246, 48 | Lv.1 · 출전 |
| `MonsterBackButton` | 44, 940, 360, 96.4 | 관리로 |
| `MonsterName` | 480, 132, 384, 84 | 푸딩 |
| `MonsterRole` | 480, 202, 384, 80 | 근접 탱커 |
| `MonsterLevel` | 480, 292, 384, 72 | Lv.1 |
| `MonsterBond` | 480, 356, 384, 68 | 유대 0/100 · 낯섦 |
| `MonsterDeployment` | 480, 920, 384, 92 | 출전 · 정문 가시 길목 |
| `MonsterTab_training` | 896, 124, 136.6, 105.3 | 훈련 |
| `MonsterTab_skills` | 1048, 124, 135.6, 105.3 | 스킬 |
| `MonsterTab_promotion` | 1199, 124, 138.6, 105.3 | 전직 |
| `MonsterTab_duo` | 1353, 124, 157.6, 105.3 | 합동기 |
| `MonsterTab_memory` | 1526, 124, 138.6, 105.3 | 기억 |
| `MemoryArchiveTitle` | 914, 259, 940, 48 | 기억 조각 · 유대 기억 / 회차 계승 / 합동 기억 |
| `MemoryBond` | 914, 319, 940, 48 | 유대 0/100 · 해금된 기억 0개 |
| `MemorySource` | 914, 379, 940, 48 | 함께 방어·원정 → 유대 단계 → 기억 ID 저장. 읽기는 보상 재지급이나 장착이 아닙니다. |
| `MemoryLocked1` | 906, 467, 462, 48 | 미해금 · 유대 25에서 기억 단계 1 |
| `MemoryLocked2` | 1400, 467, 462, 48 | 미해금 · 유대 50에서 기억 단계 2 |
| `MemoryLocked3` | 906, 543, 462, 48 | 미해금 · 유대 75에서 기억 단계 3 |
| `MemoryLocked4` | 1400, 543, 462, 48 | 미해금 · 유대 100에서 기억 단계 4 |
| `MemoryEmptyState` | 896, 613, 976, 48 | 아직 해금된 기억이 없습니다. |
| `MemoryDuoButton` | 896, 673, 976, 94.5 | 합동 기억의 해금 상태 보기 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### combat_hud · combat · DAY1

상태 근거: Real DAY1 combat 3.5s, paused, initial HUD. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `CombatMenu` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatSave` · button | 40×40 | 40×40 | 미달 | 12 / `CombatMenu` |
| `CombatDetails` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatRoomTacticsToggle` |
| `CombatRoomTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatTacticsToggle` |
| `CombatActionScroll` · scroll_container | 930×80 | 930×80 | 미달 | 20 / `CombatRoomTacticsToggle` |
| `GLOBAL_DIRECTIVE_DEFEND` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `V122_COMMAND_FOCUS` · button | 80×80 | 80×80 | 미달 | 10 / `GLOBAL_DIRECTIVE_DEFEND` |
| `V122_COMMAND_FALLBACK` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `CombatDuoLocked` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FALLBACK` |
| `CombatSpeed1x` · button | 97×65.4 | 97×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed15x` · button | 111.8×65.4 | 111.8×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed2x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed15x` |
| `CombatSpeed3x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed2x` |
| `CombatPause` · button | 98×65 | 98×65 | 미달 | 3.2 / `CombatSpeed3x` |
| `CombatCameraMode` · button | 190×67.4 | 190×67.4 | 미달 | 0 / `CombatSpeed1x` |
| `CombatMinimap` · stop_gui_input | 300×156 | 300×156 | 충족 | 4 / `CombatSpeed2x` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `CombatThroneStatus` · Panel | 1888×40 | 미달 |
| `CombatCommandBar` · Panel | 946×88 | 미달 |
| `CombatSpeedPanel` · Panel | 524×88 | 미달 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `@Label@1252` -1 | Label | 32 | 충족 / 미달 |
| `@Label@1254` -8 | Label | 34.82 | 충족 / 미달 |
| `@Label@1256` -14 | Label | 34.09 | 충족 / 미달 |
| `CombatDay` DAY 01 | Label | 22 | 미달 / 미달 |
| `CombatGoalHP` 1500 / 1500 | Label | 22 | 미달 / 미달 |
| `CombatCommandPoints` 명령 3 / 3 | Label | 22 | 미달 / 미달 |
| `CombatMana` 320 | Label | 22 | 미달 / 미달 |
| `CombatDefenseProgress` 남은 적 5 | Label | 22 | 미달 / 미달 |
| `CombatTacticsToggle` 사수 | Button(보충) | 20 | 미달 / 미달 |
| `CombatRoomTacticsToggle` 기본 | Button(보충) | 20 | 미달 / 미달 |
| `ActionCaption` 집결 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 집중 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 비상 후퇴 / CP 2 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 합동기 | Label | 18 | 미달 / 미달 |
| `CombatSpeed1x` ×1 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed15x` ×1.5 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed2x` ×2 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed3x` ×3 | Button(보충) | 22 | 미달 / 미달 |
| `CombatCameraMode` 자동 | Button(보충) | 24 | 미달 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `CombatMenu` ↔ `CombatSave` | 12 | 아니오 |
| `CombatSave` ↔ `CombatDetails` | 12 | 아니오 |
| `CombatTacticsToggle` ↔ `CombatRoomTacticsToggle` | 8 | 아니오 |
| `GLOBAL_DIRECTIVE_DEFEND` ↔ `V122_COMMAND_FOCUS` | 10 | 아니오 |
| `V122_COMMAND_FOCUS` ↔ `V122_COMMAND_FALLBACK` | 10 | 아니오 |
| `V122_COMMAND_FALLBACK` ↔ `CombatDuoLocked` | 10 | 아니오 |
| `CombatSpeed1x` ↔ `CombatSpeed15x` | 4 | 아니오 |
| `CombatSpeed1x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatSpeed2x` | 3.2 | 아니오 |
| `CombatSpeed15x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatMinimap` | 8.24 | 아니오 |
| `CombatSpeed2x` ↔ `CombatSpeed3x` | 3.2 | 아니오 |
| `CombatSpeed2x` ↔ `CombatCameraMode` | 16 | 아니오 |
| `CombatSpeed2x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatSpeed3x` ↔ `CombatPause` | 3.2 | 아니오 |
| `CombatSpeed3x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatPause` ↔ `CombatMinimap` | 4 | 아니오 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime:0` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | 88 |
| `unit:goblin:1` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | 120 |
| `unit:imp:2` | circle / 129.6 | 259.2×259.2 | 충족 | 374.45 | 184 |
| `unit:explorer:3` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | 64 |
| `enemy_command:explorer:3` | rect / — | 259.2×297 | 충족 | — | — |
| `unit:explorer:4` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | 136 |
| `enemy_command:explorer:4` | rect / — | 259.2×297 | 충족 | — | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | 296 |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | 48 |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | 384 |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 289.13×181.44 | 충족 | — | 208 |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | 304 |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 216.56×181.44 | 충족 | — | 216 |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | 344 |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 402.3×326.7 | 충족 | — | 0 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `CombatDay` | 16, 3, 276, 34 | DAY 01 |
| `@ProgressBar@1270` | 348, 3, 200, 32.4 | 왕좌 체력 |
| `CombatMana` | 1182, 3, 277, 34 | 320 |
| `CombatDefenseProgress` | 1471, 3, 276, 34 | 방어 43%<br>3초 후 · 탐험가 · 정문 진입 → 왕좌의 방 · 해당 전선의 첫 방어 구역에서 진입을 지연하세요. |
| `CombatMenu` | 1759, 0, 40, 40 | 설정 · 메뉴 |
| `CombatSave` | 1811, 0, 40, 40 | 저장 · 전투 중에는 마지막 체크포인트만 복원할 수 있습니다. |
| `CombatDetails` | 1863, 0, 40, 40 | 전투 기록 |
| `CombatTacticsToggle` | 16, 1010, 194, 64 | 성 전체 · 사수 |
| `CombatRoomTacticsToggle` | 218, 1010, 194, 64 | 이 방 · 기본 |
| `GLOBAL_DIRECTIVE_DEFEND` | 432, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 이동하고 도착 후 그 방을 사수합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 434, 1016, 76, 60 | 집결<br>CP 1 |
| `V122_COMMAND_FOCUS` | 522, 996, 80, 80 | 모든 수비 몬스터가 선택한 적을 전술 우선 대상으로 삼고 받는 피해를 증폭합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 524, 1016, 76, 60 | 집중<br>CP 1 |
| `V122_COMMAND_FALLBACK` | 612, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 즉시 이탈하고 이동 중 받는 피해를 줄입니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 614, 1016, 76, 60 | 비상 후퇴<br>CP 2 |
| `CombatDuoLocked` | 702, 996, 80, 80 | 합동기 장착 필요 |
| `ActionCaption` | 704, 1016, 76, 60 | 합동기 |
| `CombatSpeed1x` | 1384, 996, 97, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed15x` | 1485, 996, 111.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed2x` | 1600, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed3x` | 1701, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatPause` | 1802, 996, 98, 65 | 일시정지 / 재개 |
| `CombatCameraMode` | 1394, 936, 190, 67.4 | 자동/수동 전환 · 드래그/휠 후 5초 무조작 시 자동 복귀 |
| `CombatMinimap` | 1604, 836, 300, 156 | 미니맵 · 클릭/터치로 카메라 이동 |

### combat_selected · combat · DAY1

상태 근거: Real first allied unit selected, actual inspector. 캡처: `tmp/android_audit/combat_selected.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `CombatMenu` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatSave` · button | 40×40 | 40×40 | 미달 | 12 / `CombatMenu` |
| `CombatDetails` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatRoomTacticsToggle` |
| `CombatRoomTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatTacticsToggle` |
| `CombatActionScroll` · scroll_container | 930×80 | 930×80 | 미달 | 20 / `CombatRoomTacticsToggle` |
| `GLOBAL_DIRECTIVE_DEFEND` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `V122_COMMAND_FOCUS` · button | 80×80 | 80×80 | 미달 | 10 / `GLOBAL_DIRECTIVE_DEFEND` |
| `V122_COMMAND_FALLBACK` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `ManualCast_slime_shield` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FALLBACK` |
| `ManualCast_hold_corridor` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `ManualCast_slime_shield` |
| `CombatDuoLocked` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `ManualCast_hold_corridor` |
| `CombatSpeed1x` · button | 97×65.4 | 97×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed15x` · button | 111.8×65.4 | 111.8×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed2x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed15x` |
| `CombatSpeed3x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed2x` |
| `CombatPause` · button | 98×65 | 98×65 | 미달 | 3.2 / `CombatSpeed3x` |
| `CombatCameraMode` · button | 190×67.4 | 190×67.4 | 미달 | 0 / `CombatSpeed1x` |
| `CombatMinimap` · stop_gui_input | 300×156 | 300×156 | 충족 | 4 / `CombatSpeed2x` |
| `CombatUnitInspectorClose` · button | 48×48 | 48×48 | 미달 | 156 / `CombatSave` |
| `CombatRepresentativeSkill` · button (비활성) | 168×168 | 168×168 | 충족 | 10 / `CombatUnitDetailsToggle` |
| `CombatUnitDetailsToggle` · button | 424×67.4 | 424×67.4 | 미달 | 10 / `CombatRepresentativeSkill` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `CombatThroneStatus` · Panel | 1888×40 | 미달 |
| `CombatCommandBar` · Panel | 946×88 | 미달 |
| `CombatSpeedPanel` · Panel | 524×88 | 미달 |
| `CombatUnitInspector` · Panel | 460×640 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `@Label@1068` 푸딩 | Label | 32.4 | 충족 / 미달 |
| `@Label@1252` -1 | Label | 32 | 충족 / 미달 |
| `@Label@1254` -8 | Label | 34.82 | 충족 / 미달 |
| `@Label@1256` -14 | Label | 34.09 | 충족 / 미달 |
| `CombatDay` DAY 01 | Label | 22 | 미달 / 미달 |
| `CombatGoalHP` 1500 / 1500 | Label | 22 | 미달 / 미달 |
| `CombatCommandPoints` 명령 3 / 3 | Label | 22 | 미달 / 미달 |
| `CombatMana` 320 | Label | 22 | 미달 / 미달 |
| `CombatDefenseProgress` 남은 적 5 | Label | 22 | 미달 / 미달 |
| `CombatTacticsToggle` 사수 | Button(보충) | 20 | 미달 / 미달 |
| `CombatRoomTacticsToggle` 기본 | Button(보충) | 20 | 미달 / 미달 |
| `ActionCaption` 집결 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 집중 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 비상 후퇴 / CP 2 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 점액 방패 / 대기 8.5초 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 통로 막기 / 대기 4.8초 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 합동기 | Label | 18 | 미달 / 미달 |
| `CombatSpeed1x` ×1 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed15x` ×1.5 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed2x` ×2 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed3x` ×3 | Button(보충) | 22 | 미달 / 미달 |
| `CombatCameraMode` 자동 | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 선택 유닛 | Label | 35 | 충족 / 미달 |
| `CombatSelected_name` 슬라임 | Label | 38 | 충족 / 충족 |
| `CombatSelected_hp` 178 / 180 | Label | 24 | 미달 / 미달 |
| `ActionCaption` 점액 방패 / 대기 8.5초 | Label | 27 | 미달 / 미달 |
| `CombatUnitDetailsToggle` 상세 보기 | Button(보충) | 24 | 미달 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `CombatMenu` ↔ `CombatSave` | 12 | 아니오 |
| `CombatSave` ↔ `CombatDetails` | 12 | 아니오 |
| `CombatTacticsToggle` ↔ `CombatRoomTacticsToggle` | 8 | 아니오 |
| `GLOBAL_DIRECTIVE_DEFEND` ↔ `V122_COMMAND_FOCUS` | 10 | 아니오 |
| `V122_COMMAND_FOCUS` ↔ `V122_COMMAND_FALLBACK` | 10 | 아니오 |
| `V122_COMMAND_FALLBACK` ↔ `ManualCast_slime_shield` | 10 | 아니오 |
| `ManualCast_slime_shield` ↔ `ManualCast_hold_corridor` | 10 | 아니오 |
| `ManualCast_hold_corridor` ↔ `CombatDuoLocked` | 10 | 아니오 |
| `CombatSpeed1x` ↔ `CombatSpeed15x` | 4 | 아니오 |
| `CombatSpeed1x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatSpeed2x` | 3.2 | 아니오 |
| `CombatSpeed15x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatMinimap` | 8.24 | 아니오 |
| `CombatSpeed2x` ↔ `CombatSpeed3x` | 3.2 | 아니오 |
| `CombatSpeed2x` ↔ `CombatCameraMode` | 16 | 아니오 |
| `CombatSpeed2x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatSpeed3x` ↔ `CombatPause` | 3.2 | 아니오 |
| `CombatSpeed3x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatPause` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatRepresentativeSkill` ↔ `CombatUnitDetailsToggle` | 10 | 아니오 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime:0` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `unit:goblin:1` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `unit:imp:2` | circle / 129.6 | 259.2×259.2 | 충족 | 374.45 | — |
| `unit:explorer:3` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `enemy_command:explorer:3` | rect / — | 259.2×297 | 충족 | — | — |
| `unit:explorer:4` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `enemy_command:explorer:4` | rect / — | 259.2×297 | 충족 | — | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 289.13×181.44 | 충족 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 216.56×181.44 | 충족 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 402.3×326.7 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `CombatDay` | 16, 3, 276, 34 | DAY 01 |
| `@ProgressBar@1300` | 348, 3, 200, 32.4 | 왕좌 체력 |
| `CombatMana` | 1182, 3, 277, 34 | 320 |
| `CombatDefenseProgress` | 1471, 3, 276, 34 | 방어 43%<br>3초 후 · 탐험가 · 정문 진입 → 왕좌의 방 · 해당 전선의 첫 방어 구역에서 진입을 지연하세요. |
| `CombatMenu` | 1759, 0, 40, 40 | 설정 · 메뉴 |
| `CombatSave` | 1811, 0, 40, 40 | 저장 · 전투 중에는 마지막 체크포인트만 복원할 수 있습니다. |
| `CombatDetails` | 1863, 0, 40, 40 | 전투 기록 |
| `CombatTacticsToggle` | 16, 1010, 194, 64 | 성 전체 · 사수 |
| `CombatRoomTacticsToggle` | 218, 1010, 194, 64 | 이 방 · 기본 |
| `GLOBAL_DIRECTIVE_DEFEND` | 432, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 이동하고 도착 후 그 방을 사수합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 434, 1016, 76, 60 | 집결<br>CP 1 |
| `V122_COMMAND_FOCUS` | 522, 996, 80, 80 | 모든 수비 몬스터가 선택한 적을 전술 우선 대상으로 삼고 받는 피해를 증폭합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 524, 1016, 76, 60 | 집중<br>CP 1 |
| `V122_COMMAND_FALLBACK` | 612, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 즉시 이탈하고 이동 중 받는 피해를 줄입니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 614, 1016, 76, 60 | 비상 후퇴<br>CP 2 |
| `ManualCast_slime_shield` | 702, 996, 80, 80 | 5초 동안 받는 피해를 40% 줄입니다. |
| `ActionCaption` | 704, 1016, 76, 60 | 점액 방패<br>대기 8.5초 |
| `ManualCast_hold_corridor` | 792, 996, 80, 80 | 현재 방 방어 중 방어력을 올립니다. |
| `ActionCaption` | 794, 1016, 76, 60 | 통로 막기<br>대기 4.8초 |
| `CombatDuoLocked` | 882, 996, 80, 80 | 합동기 장착 필요 |
| `ActionCaption` | 884, 1016, 76, 60 | 합동기 |
| `CombatSpeed1x` | 1384, 996, 97, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed15x` | 1485, 996, 111.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed2x` | 1600, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed3x` | 1701, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatPause` | 1802, 996, 98, 65 | 일시정지 / 재개 |
| `CombatCameraMode` | 1394, 936, 190, 67.4 | 자동/수동 전환 · 드래그/휠 후 5초 무조작 시 자동 복귀 |
| `CombatMinimap` | 1604, 836, 300, 156 | 미니맵 · 클릭/터치로 카메라 이동 |
| `Copy` | 1462, 196, 370, 53 | 선택 유닛 |
| `CombatUnitInspectorClose` | 1840, 196, 48, 48 | 닫기 |
| `CombatSelected_name` | 1462, 452, 424, 57 | 슬라임 |
| `CombatSelectedHPBar` | 1462, 500, 424, 27 | 선택 유닛 체력 |
| `CombatSelected_hp` | 1462, 528, 424, 36 | 178 / 180 |
| `CombatRepresentativeSkill` | 1590, 566, 168, 168 | 5초 동안 받는 피해를 40% 줄입니다. |
| `ActionCaption` | 1598, 621.44, 152, 106.56 | 점액 방패<br>대기 8.5초 |
| `CombatUnitDetailsToggle` | 1462, 744, 424, 67.4 | 상세 보기 |

### combat_tactics_details · combat · DAY1

상태 근거: Tactics and selected unit details expanded. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `CombatMenu` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatSave` · button | 40×40 | 40×40 | 미달 | 12 / `CombatMenu` |
| `CombatDetails` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatRoomTacticsToggle` |
| `CombatRoomTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatTacticsToggle` |
| `CombatActionScroll` · scroll_container | 930×80 | 930×80 | 미달 | 20 / `CombatRoomTacticsToggle` |
| `GLOBAL_DIRECTIVE_DEFEND` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `V122_COMMAND_FOCUS` · button | 80×80 | 80×80 | 미달 | 10 / `GLOBAL_DIRECTIVE_DEFEND` |
| `V122_COMMAND_FALLBACK` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `ManualCast_slime_shield` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FALLBACK` |
| `ManualCast_hold_corridor` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `ManualCast_slime_shield` |
| `CombatDuoLocked` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `ManualCast_hold_corridor` |
| `CombatSpeed1x` · button | 97×65.4 | 97×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed15x` · button | 111.8×65.4 | 111.8×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed2x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed15x` |
| `CombatSpeed3x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed2x` |
| `CombatPause` · button | 98×65 | 98×65 | 미달 | 3.2 / `CombatSpeed3x` |
| `CombatCameraMode` · button | 190×67.4 | 190×67.4 | 미달 | 0 / `CombatSpeed1x` |
| `CombatMinimap` · stop_gui_input | 300×156 | 300×156 | 충족 | 4 / `CombatSpeed2x` |
| `CombatTacticsClose` · button | 164×100 | 164×100 | 미달 | 16 / `CombatTacticsPanelScroll` |
| `CombatTacticsPanelScroll` · scroll_container | 604×410 | 604×410 | 충족 | 16 / `CombatTacticsClose` |
| `CombatGlobalDirective` · button | 594×96.4 | 594×96.4 | 미달 | 72.6 / `CombatSelectedRoomDirective` |
| `CombatSelectedRoomDirective` · button | 594×96.4 | 594×96.4 | 미달 | 72.6 / `CombatGlobalDirective` |
| `CombatUnitInspectorClose` · button | 48×48 | 48×48 | 미달 | 84 / `CombatSave` |
| `CombatRepresentativeSkill` · button (비활성) | 168×168 | 168×168 | 충족 | 10 / `CombatUnitDetailsToggle` |
| `CombatUnitDetailsToggle` · button | 424×67.4 | 424×67.4 | 미달 | 0 / `CombatUnitInspectorScroll` |
| `CombatUnitInspectorScroll` · scroll_container | 424×68 | 424×68 | 미달 | 0 / `CombatUnitDetailsToggle` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `CombatThroneStatus` · Panel | 1888×40 | 미달 |
| `CombatCommandBar` · Panel | 946×88 | 미달 |
| `CombatSpeedPanel` · Panel | 524×88 | 미달 |
| `CombatTacticsPanel` · Panel | 640×560 | 충족 |
| `CombatUnitInspector` · Panel | 460×692 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `@Label@1068` 푸딩 | Label | 32.4 | 충족 / 미달 |
| `@Label@1252` -1 | Label | 32 | 충족 / 미달 |
| `@Label@1254` -8 | Label | 34.82 | 충족 / 미달 |
| `@Label@1256` -14 | Label | 34.09 | 충족 / 미달 |
| `CombatDay` DAY 01 | Label | 22 | 미달 / 미달 |
| `CombatGoalHP` 1500 / 1500 | Label | 22 | 미달 / 미달 |
| `CombatCommandPoints` 명령 3 / 3 | Label | 22 | 미달 / 미달 |
| `CombatMana` 320 | Label | 22 | 미달 / 미달 |
| `CombatDefenseProgress` 남은 적 5 | Label | 22 | 미달 / 미달 |
| `CombatTacticsToggle` 사수 | Button(보충) | 20 | 미달 / 미달 |
| `CombatRoomTacticsToggle` 기본 | Button(보충) | 20 | 미달 / 미달 |
| `ActionCaption` 집결 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 집중 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 비상 후퇴 / CP 2 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 점액 방패 / 대기 8.5초 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 통로 막기 / 대기 4.8초 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 합동기 | Label | 18 | 미달 / 미달 |
| `CombatSpeed1x` ×1 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed15x` ×1.5 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed2x` ×2 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed3x` ×3 | Button(보충) | 22 | 미달 / 미달 |
| `CombatCameraMode` 자동 | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 전술 · 지속 정책 | Label | 35 | 충족 / 미달 |
| `CombatTacticsClose` 닫기 | Button(보충) | 38 | 충족 / 충족 |
| `CombatCopy` 성 전체 | Label | 32 | 충족 / 미달 |
| `CombatGlobalDirective` 사수 | OptionButton(보충) | 35 | 충족 / 미달 |
| `@Label@1377` 이 방 · 입구 | Label | 32 | 충족 / 미달 |
| `CombatSelectedRoomDirective` 기본 · 전체 전술 따름 | OptionButton(보충) | 35 | 충족 / 미달 |
| `@Label@1386` 선택 유닛 · 스킬은 자동 사용을 유지하며 아래 행동으로 직접 발동할 수 있습니다. | Label | 32 | 충족 / 미달 |
| `Copy` 선택 유닛 | Label | 35 | 충족 / 미달 |
| `CombatSelected_name` 슬라임 | Label | 38 | 충족 / 충족 |
| `CombatSelected_hp` 178 / 180 | Label | 24 | 미달 / 미달 |
| `ActionCaption` 점액 방패 / 대기 8.5초 | Label | 27 | 미달 / 미달 |
| `CombatUnitDetailsToggle` 상세 접기 | Button(보충) | 24 | 미달 / 미달 |
| `CombatSelected_role` 근접 탱커 | Label | 32 | 충족 / 미달 |
| `CombatSelected_stats` 공격 8 · 방어 8 | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `CombatMenu` ↔ `CombatSave` | 12 | 아니오 |
| `CombatSave` ↔ `CombatDetails` | 12 | 아니오 |
| `CombatTacticsToggle` ↔ `CombatRoomTacticsToggle` | 8 | 아니오 |
| `GLOBAL_DIRECTIVE_DEFEND` ↔ `V122_COMMAND_FOCUS` | 10 | 아니오 |
| `V122_COMMAND_FOCUS` ↔ `V122_COMMAND_FALLBACK` | 10 | 아니오 |
| `V122_COMMAND_FALLBACK` ↔ `ManualCast_slime_shield` | 10 | 아니오 |
| `ManualCast_slime_shield` ↔ `ManualCast_hold_corridor` | 10 | 아니오 |
| `ManualCast_hold_corridor` ↔ `CombatDuoLocked` | 10 | 아니오 |
| `CombatSpeed1x` ↔ `CombatSpeed15x` | 4 | 아니오 |
| `CombatSpeed1x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatSpeed2x` | 3.2 | 아니오 |
| `CombatSpeed15x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatMinimap` | 8.24 | 아니오 |
| `CombatSpeed2x` ↔ `CombatSpeed3x` | 3.2 | 아니오 |
| `CombatSpeed2x` ↔ `CombatCameraMode` | 16 | 아니오 |
| `CombatSpeed2x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatSpeed3x` ↔ `CombatPause` | 3.2 | 아니오 |
| `CombatSpeed3x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatPause` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatTacticsClose` ↔ `CombatTacticsPanelScroll` | 16 | 아니오 |
| `CombatRepresentativeSkill` ↔ `CombatUnitDetailsToggle` | 10 | 아니오 |
| `CombatUnitDetailsToggle` ↔ `CombatUnitInspectorScroll` | 0 | 예 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime:0` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `unit:goblin:1` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `unit:imp:2` | circle / 129.6 | 259.2×259.2 | 충족 | 374.45 | — |
| `unit:explorer:3` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `enemy_command:explorer:3` | rect / — | 259.2×297 | 충족 | — | — |
| `unit:explorer:4` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `enemy_command:explorer:4` | rect / — | 259.2×297 | 충족 | — | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 289.13×181.44 | 충족 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 216.56×181.44 | 충족 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 402.3×326.7 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `CombatDay` | 16, 3, 276, 34 | DAY 01 |
| `@ProgressBar@1337` | 348, 3, 200, 32.4 | 왕좌 체력 |
| `CombatMana` | 1182, 3, 277, 34 | 320 |
| `CombatDefenseProgress` | 1471, 3, 276, 34 | 방어 43%<br>3초 후 · 탐험가 · 정문 진입 → 왕좌의 방 · 해당 전선의 첫 방어 구역에서 진입을 지연하세요. |
| `CombatMenu` | 1759, 0, 40, 40 | 설정 · 메뉴 |
| `CombatSave` | 1811, 0, 40, 40 | 저장 · 전투 중에는 마지막 체크포인트만 복원할 수 있습니다. |
| `CombatDetails` | 1863, 0, 40, 40 | 전투 기록 |
| `CombatTacticsToggle` | 16, 1010, 194, 64 | 성 전체 · 사수 |
| `CombatRoomTacticsToggle` | 218, 1010, 194, 64 | 이 방 · 기본 |
| `GLOBAL_DIRECTIVE_DEFEND` | 432, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 이동하고 도착 후 그 방을 사수합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 434, 1016, 76, 60 | 집결<br>CP 1 |
| `V122_COMMAND_FOCUS` | 522, 996, 80, 80 | 모든 수비 몬스터가 선택한 적을 전술 우선 대상으로 삼고 받는 피해를 증폭합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 524, 1016, 76, 60 | 집중<br>CP 1 |
| `V122_COMMAND_FALLBACK` | 612, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 즉시 이탈하고 이동 중 받는 피해를 줄입니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 614, 1016, 76, 60 | 비상 후퇴<br>CP 2 |
| `ManualCast_slime_shield` | 702, 996, 80, 80 | 5초 동안 받는 피해를 40% 줄입니다. |
| `ActionCaption` | 704, 1016, 76, 60 | 점액 방패<br>대기 8.5초 |
| `ManualCast_hold_corridor` | 792, 996, 80, 80 | 현재 방 방어 중 방어력을 올립니다. |
| `ActionCaption` | 794, 1016, 76, 60 | 통로 막기<br>대기 4.8초 |
| `CombatDuoLocked` | 882, 996, 80, 80 | 합동기 장착 필요 |
| `ActionCaption` | 884, 1016, 76, 60 | 합동기 |
| `CombatSpeed1x` | 1384, 996, 97, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed15x` | 1485, 996, 111.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed2x` | 1600, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed3x` | 1701, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatPause` | 1802, 996, 98, 65 | 일시정지 / 재개 |
| `CombatCameraMode` | 1394, 936, 190, 67.4 | 자동/수동 전환 · 드래그/휠 후 5초 무조작 시 자동 복귀 |
| `CombatMinimap` | 1604, 836, 300, 156 | 미니맵 · 클릭/터치로 카메라 이동 |
| `Copy` | 34, 200, 422, 62 | 전술 · 지속 정책 |
| `CombatTacticsClose` | 474, 200, 164, 100 | 닫기 |
| `CombatCopy` | 34, 316, 594, 49 | 성 전체 |
| `CombatGlobalDirective` | 34, 377, 594, 96.4 | 성 전체 지침. DAY 01은 사수로 고정됩니다. |
| `@Label@1377` | 34, 485, 594, 49 | 이 방 · 입구 |
| `CombatSelectedRoomDirective` | 34, 546, 594, 96.4 | 선택한 방의 지속 지침 |
| `@Label@1386` | 34, 654, 594, 72 | 선택 유닛 · 스킬은 자동 사용을 유지하며 아래 행동으로 직접 발동할 수 있습니다. |
| `Copy` | 1462, 124, 370, 53 | 선택 유닛 |
| `CombatUnitInspectorClose` | 1840, 124, 48, 48 | 닫기 |
| `CombatSelected_name` | 1462, 380, 424, 57 | 슬라임 |
| `CombatSelectedHPBar` | 1462, 428, 424, 27 | 선택 유닛 체력 |
| `CombatSelected_hp` | 1462, 456, 424, 36 | 178 / 180 |
| `CombatRepresentativeSkill` | 1590, 494, 168, 168 | 5초 동안 받는 피해를 40% 줄입니다. |
| `ActionCaption` | 1598, 549.44, 152, 106.56 | 점액 방패<br>대기 8.5초 |
| `CombatUnitDetailsToggle` | 1462, 672, 424, 67.4 | 상세 접기 |
| `CombatSelected_role` | 1462, 720, 414, 49 | 근접 탱커 |
| `CombatSelected_stats` | 1462, 781, 414, 7 | 공격 8 · 방어 8 |

### combat_details_bottom · combat · DAY1

상태 근거: Selected unit details bottom scroll. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `CombatMenu` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatSave` · button | 40×40 | 40×40 | 미달 | 12 / `CombatMenu` |
| `CombatDetails` · button | 40×40 | 40×40 | 미달 | 12 / `CombatSave` |
| `CombatTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatRoomTacticsToggle` |
| `CombatRoomTacticsToggle` · button | 194×64 | 194×64 | 미달 | 8 / `CombatTacticsToggle` |
| `CombatActionScroll` · scroll_container | 930×80 | 930×80 | 미달 | 20 / `CombatRoomTacticsToggle` |
| `GLOBAL_DIRECTIVE_DEFEND` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `V122_COMMAND_FOCUS` · button | 80×80 | 80×80 | 미달 | 10 / `GLOBAL_DIRECTIVE_DEFEND` |
| `V122_COMMAND_FALLBACK` · button | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FOCUS` |
| `ManualCast_slime_shield` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `V122_COMMAND_FALLBACK` |
| `ManualCast_hold_corridor` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `ManualCast_slime_shield` |
| `CombatDuoLocked` · button (비활성) | 80×80 | 80×80 | 미달 | 10 / `ManualCast_hold_corridor` |
| `CombatSpeed1x` · button | 97×65.4 | 97×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed15x` · button | 111.8×65.4 | 111.8×65.4 | 미달 | 0 / `CombatCameraMode` |
| `CombatSpeed2x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed15x` |
| `CombatSpeed3x` · button | 97.8×65.4 | 97.8×65.4 | 미달 | 3.2 / `CombatSpeed2x` |
| `CombatPause` · button | 98×65 | 98×65 | 미달 | 3.2 / `CombatSpeed3x` |
| `CombatCameraMode` · button | 190×67.4 | 190×67.4 | 미달 | 0 / `CombatSpeed1x` |
| `CombatMinimap` · stop_gui_input | 300×156 | 300×156 | 충족 | 4 / `CombatSpeed2x` |
| `CombatTacticsClose` · button | 164×100 | 164×100 | 미달 | 16 / `CombatTacticsPanelScroll` |
| `CombatTacticsPanelScroll` · scroll_container | 604×410 | 604×410 | 충족 | 16 / `CombatTacticsClose` |
| `CombatGlobalDirective` · button | 594×96.4 | 594×96.4 | 미달 | 72.6 / `CombatSelectedRoomDirective` |
| `CombatSelectedRoomDirective` · button | 594×96.4 | 594×96.4 | 미달 | 72.6 / `CombatGlobalDirective` |
| `CombatUnitInspectorClose` · button | 48×48 | 48×48 | 미달 | 84 / `CombatSave` |
| `CombatRepresentativeSkill` · button (비활성) | 168×168 | 168×168 | 충족 | 10 / `CombatUnitDetailsToggle` |
| `CombatUnitDetailsToggle` · button | 424×67.4 | 424×67.4 | 미달 | 0 / `CombatUnitInspectorScroll` |
| `CombatUnitInspectorScroll` · scroll_container | 424×68 | 424×68 | 미달 | 0 / `CombatUnitDetailsToggle` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `CombatThroneStatus` · Panel | 1888×40 | 미달 |
| `CombatCommandBar` · Panel | 946×88 | 미달 |
| `CombatSpeedPanel` · Panel | 524×88 | 미달 |
| `CombatTacticsPanel` · Panel | 640×560 | 충족 |
| `CombatUnitInspector` · Panel | 460×692 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `@Label@1068` 푸딩 | Label | 32.4 | 충족 / 미달 |
| `@Label@1252` -1 | Label | 32 | 충족 / 미달 |
| `@Label@1254` -8 | Label | 34.82 | 충족 / 미달 |
| `@Label@1256` -14 | Label | 34.09 | 충족 / 미달 |
| `CombatDay` DAY 01 | Label | 22 | 미달 / 미달 |
| `CombatGoalHP` 1500 / 1500 | Label | 22 | 미달 / 미달 |
| `CombatCommandPoints` 명령 3 / 3 | Label | 22 | 미달 / 미달 |
| `CombatMana` 320 | Label | 22 | 미달 / 미달 |
| `CombatDefenseProgress` 남은 적 5 | Label | 22 | 미달 / 미달 |
| `CombatTacticsToggle` 사수 | Button(보충) | 20 | 미달 / 미달 |
| `CombatRoomTacticsToggle` 기본 | Button(보충) | 20 | 미달 / 미달 |
| `ActionCaption` 집결 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 집중 / CP 1 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 비상 후퇴 / CP 2 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 점액 방패 / 대기 8.5초 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 통로 막기 / 대기 4.8초 | Label | 18 | 미달 / 미달 |
| `ActionCaption` 합동기 | Label | 18 | 미달 / 미달 |
| `CombatSpeed1x` ×1 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed15x` ×1.5 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed2x` ×2 | Button(보충) | 22 | 미달 / 미달 |
| `CombatSpeed3x` ×3 | Button(보충) | 22 | 미달 / 미달 |
| `CombatCameraMode` 자동 | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 전술 · 지속 정책 | Label | 35 | 충족 / 미달 |
| `CombatTacticsClose` 닫기 | Button(보충) | 38 | 충족 / 충족 |
| `CombatCopy` 성 전체 | Label | 32 | 충족 / 미달 |
| `CombatGlobalDirective` 사수 | OptionButton(보충) | 35 | 충족 / 미달 |
| `@Label@1377` 이 방 · 입구 | Label | 32 | 충족 / 미달 |
| `CombatSelectedRoomDirective` 기본 · 전체 전술 따름 | OptionButton(보충) | 35 | 충족 / 미달 |
| `@Label@1386` 선택 유닛 · 스킬은 자동 사용을 유지하며 아래 행동으로 직접 발동할 수 있습니다. | Label | 32 | 충족 / 미달 |
| `Copy` 선택 유닛 | Label | 35 | 충족 / 미달 |
| `CombatSelected_name` 슬라임 | Label | 38 | 충족 / 충족 |
| `CombatSelected_hp` 178 / 180 | Label | 24 | 미달 / 미달 |
| `ActionCaption` 점액 방패 / 대기 8.5초 | Label | 27 | 미달 / 미달 |
| `CombatUnitDetailsToggle` 상세 접기 | Button(보충) | 24 | 미달 / 미달 |
| `CombatSelected_objective` 방 기본 · 교전 유지 | Label | 32 | 충족 / 미달 |
| `CombatSelected_status` 대상 · 탐험가 | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `CombatMenu` ↔ `CombatSave` | 12 | 아니오 |
| `CombatSave` ↔ `CombatDetails` | 12 | 아니오 |
| `CombatTacticsToggle` ↔ `CombatRoomTacticsToggle` | 8 | 아니오 |
| `GLOBAL_DIRECTIVE_DEFEND` ↔ `V122_COMMAND_FOCUS` | 10 | 아니오 |
| `V122_COMMAND_FOCUS` ↔ `V122_COMMAND_FALLBACK` | 10 | 아니오 |
| `V122_COMMAND_FALLBACK` ↔ `ManualCast_slime_shield` | 10 | 아니오 |
| `ManualCast_slime_shield` ↔ `ManualCast_hold_corridor` | 10 | 아니오 |
| `ManualCast_hold_corridor` ↔ `CombatDuoLocked` | 10 | 아니오 |
| `CombatSpeed1x` ↔ `CombatSpeed15x` | 4 | 아니오 |
| `CombatSpeed1x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatSpeed2x` | 3.2 | 아니오 |
| `CombatSpeed15x` ↔ `CombatCameraMode` | 0 | 예 |
| `CombatSpeed15x` ↔ `CombatMinimap` | 8.24 | 아니오 |
| `CombatSpeed2x` ↔ `CombatSpeed3x` | 3.2 | 아니오 |
| `CombatSpeed2x` ↔ `CombatCameraMode` | 16 | 아니오 |
| `CombatSpeed2x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatSpeed3x` ↔ `CombatPause` | 3.2 | 아니오 |
| `CombatSpeed3x` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatPause` ↔ `CombatMinimap` | 4 | 아니오 |
| `CombatTacticsClose` ↔ `CombatTacticsPanelScroll` | 16 | 아니오 |
| `CombatRepresentativeSkill` ↔ `CombatUnitDetailsToggle` | 10 | 아니오 |
| `CombatUnitDetailsToggle` ↔ `CombatUnitInspectorScroll` | 0 | 예 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `unit:slime:0` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `unit:goblin:1` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `unit:imp:2` | circle / 129.6 | 259.2×259.2 | 충족 | 374.45 | — |
| `unit:explorer:3` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `enemy_command:explorer:3` | rect / — | 259.2×297 | 충족 | — | — |
| `unit:explorer:4` | circle / 129.6 | 259.2×259.2 | 충족 | 0 | — |
| `enemy_command:explorer:4` | rect / — | 259.2×297 | 충족 | — | — |
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 289.13×181.44 | 충족 | — | — |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 216.56×181.44 | 충족 | — | — |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 362.88×181.44 | 충족 | — | — |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 402.3×326.7 | 충족 | — | — |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `CombatDay` | 16, 3, 276, 34 | DAY 01 |
| `@ProgressBar@1337` | 348, 3, 200, 32.4 | 왕좌 체력 |
| `CombatMana` | 1182, 3, 277, 34 | 320 |
| `CombatDefenseProgress` | 1471, 3, 276, 34 | 방어 43%<br>3초 후 · 탐험가 · 정문 진입 → 왕좌의 방 · 해당 전선의 첫 방어 구역에서 진입을 지연하세요. |
| `CombatMenu` | 1759, 0, 40, 40 | 설정 · 메뉴 |
| `CombatSave` | 1811, 0, 40, 40 | 저장 · 전투 중에는 마지막 체크포인트만 복원할 수 있습니다. |
| `CombatDetails` | 1863, 0, 40, 40 | 전투 기록 |
| `CombatTacticsToggle` | 16, 1010, 194, 64 | 성 전체 · 사수 |
| `CombatRoomTacticsToggle` | 218, 1010, 194, 64 | 이 방 · 기본 |
| `GLOBAL_DIRECTIVE_DEFEND` | 432, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 이동하고 도착 후 그 방을 사수합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 434, 1016, 76, 60 | 집결<br>CP 1 |
| `V122_COMMAND_FOCUS` | 522, 996, 80, 80 | 모든 수비 몬스터가 선택한 적을 전술 우선 대상으로 삼고 받는 피해를 증폭합니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 524, 1016, 76, 60 | 집중<br>CP 1 |
| `V122_COMMAND_FALLBACK` | 612, 996, 80, 80 | 모든 수비 몬스터가 선택 방으로 즉시 이탈하고 이동 중 받는 피해를 줄입니다.<br><br>명령 선택 → 노란 대상 선택. ESC/우클릭 취소. |
| `ActionCaption` | 614, 1016, 76, 60 | 비상 후퇴<br>CP 2 |
| `ManualCast_slime_shield` | 702, 996, 80, 80 | 5초 동안 받는 피해를 40% 줄입니다. |
| `ActionCaption` | 704, 1016, 76, 60 | 점액 방패<br>대기 8.5초 |
| `ManualCast_hold_corridor` | 792, 996, 80, 80 | 현재 방 방어 중 방어력을 올립니다. |
| `ActionCaption` | 794, 1016, 76, 60 | 통로 막기<br>대기 4.8초 |
| `CombatDuoLocked` | 882, 996, 80, 80 | 합동기 장착 필요 |
| `ActionCaption` | 884, 1016, 76, 60 | 합동기 |
| `CombatSpeed1x` | 1384, 996, 97, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed15x` | 1485, 996, 111.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed2x` | 1600, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatSpeed3x` | 1701, 996, 97.8, 65.4 | 전투 속도 · 튜토리얼 후 해금 |
| `CombatPause` | 1802, 996, 98, 65 | 일시정지 / 재개 |
| `CombatCameraMode` | 1394, 936, 190, 67.4 | 자동/수동 전환 · 드래그/휠 후 5초 무조작 시 자동 복귀 |
| `CombatMinimap` | 1604, 836, 300, 156 | 미니맵 · 클릭/터치로 카메라 이동 |
| `Copy` | 34, 200, 422, 62 | 전술 · 지속 정책 |
| `CombatTacticsClose` | 474, 200, 164, 100 | 닫기 |
| `CombatCopy` | 34, 316, 594, 49 | 성 전체 |
| `CombatGlobalDirective` | 34, 377, 594, 96.4 | 성 전체 지침. DAY 01은 사수로 고정됩니다. |
| `@Label@1377` | 34, 485, 594, 49 | 이 방 · 입구 |
| `CombatSelectedRoomDirective` | 34, 546, 594, 96.4 | 선택한 방의 지속 지침 |
| `@Label@1386` | 34, 654, 594, 72 | 선택 유닛 · 스킬은 자동 사용을 유지하며 아래 행동으로 직접 발동할 수 있습니다. |
| `Copy` | 1462, 124, 370, 53 | 선택 유닛 |
| `CombatUnitInspectorClose` | 1840, 124, 48, 48 | 닫기 |
| `CombatSelected_name` | 1462, 380, 424, 57 | 슬라임 |
| `CombatSelectedHPBar` | 1462, 428, 424, 27 | 선택 유닛 체력 |
| `CombatSelected_hp` | 1462, 456, 424, 36 | 178 / 180 |
| `CombatRepresentativeSkill` | 1590, 494, 168, 168 | 5초 동안 받는 피해를 40% 줄입니다. |
| `ActionCaption` | 1598, 549.44, 152, 106.56 | 점액 방패<br>대기 8.5초 |
| `CombatUnitDetailsToggle` | 1462, 672, 424, 67.4 | 상세 접기 |
| `CombatSelected_objective` | 1462, 720, 414, 7 | 방 기본 · 교전 유지 |
| `CombatSelected_status` | 1462, 739, 414, 49 | 대상 · 탐험가 |

### result · result · DAY1

상태 근거: Synthetic victory summary, actual result builder. 캡처: `tmp/android_audit/result.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `ResultGrowthScroll` · scroll_container | 1824×276 | 1824×276 | 충족 | 8 / `ResultDetailsButton` |
| `ResultDetailsButton` · button | 270×52 | 270×52 | 미달 | 8 / `ResultGrowthScroll` |
| `NextDayButton` · button | 516×116 | 516×116 | 미달 | 48 / `ResultGrowthScroll` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 486 / `ResultDetailsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `V122ResultScreen` · Panel | 1920×1080 | 충족 |
| `ResultHero` · Panel | 1872×510 | 충족 |
| `ResultTitleBanner` · Panel | 880×242 | 충족 |
| `ResultMetricsBanner` · Panel | 880×62 | 미달 |
| `ResultRewards` · Panel | 624×168 | 충족 |
| `ResultGrowthPanel` · Panel | 1872×350 | 충족 |
| `ResultTrainingPreview` · Panel | 1000×140 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResultDay` DAY 1 | Label | 49 | 충족 / 충족 |
| `ResultTitle` 방어 성공 | Label | 119 | 충족 / 충족 |
| `ResultCoreMetrics` 왕좌 피해 0 · 생존 3 / 3 | Label | 38 | 충족 / 충족 |
| `ResultRewardHeading` 획득 보상 | Label | 32 | 충족 / 미달 |
| `ResultRewardValue_gold` +20 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_mana` +10 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_infamy` +1 | Label | 49 | 충족 / 충족 |
| `ResultColumn_0` 동료 | Label | 32 | 충족 / 미달 |
| `ResultColumn_1` 피해 | Label | 32 | 충족 / 미달 |
| `ResultColumn_2` 회복 | Label | 32 | 충족 / 미달 |
| `ResultColumn_3` 보호 | Label | 32 | 충족 / 미달 |
| `ResultColumn_4` 합동기 | Label | 32 | 충족 / 미달 |
| `ResultColumn_5` EXP | Label | 32 | 충족 / 미달 |
| `ResultColumn_6` 비고 | Label | 32 | 충족 / 미달 |
| `ResultEmptyGrowth` 이번 전투 성장 기록이 없습니다. | Label | 32 | 충족 / 미달 |
| `ResultDetailsButton` 상세 기록 | Button(보충) | 24 | 미달 / 미달 |
| `ResultPreviewHeading` 결산 확인 | Label | 38 | 충족 / 충족 |
| `ResultPreviewUnavailable` 결산을 확인하고 다음 일정으로 진행하세요. | Label | 32 | 충족 / 미달 |
| `NextDayButton` 다음 DAY | Button(보충) | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `ResultGrowthScroll` ↔ `ResultDetailsButton` | 8 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `ResultDay` | 544, 38, 832, 72 | DAY 1 |
| `ResultTitle` | 544, 100, 832, 174 | 방어 성공 |
| `ResultCoreMetrics` | 536, 286, 848, 56 | 왕좌 피해 0 · 생존 3 / 3 |
| `ResultRewardHeading` | 792, 360, 592, 48 | 획득 보상 |
| `ResultRewardValue_gold` | 792, 466, 197.33, 72 | +20 |
| `ResultRewardValue_mana` | 989.33, 466, 197.33, 72 | +10 |
| `ResultRewardValue_infamy` | 1186.67, 466, 197.33, 72 | +1 |
| `ResultGrowthPanel` | 24, 546, 1872, 350 | 동료 성과 · 승리 후 한 명 집중성장 +8 · 세부는 상세 기록 |
| `ResultColumn_0` | 48, 554, 300, 48 | 동료 |
| `ResultColumn_1` | 348, 554, 150, 48 | 피해 |
| `ResultColumn_2` | 498, 554, 150, 48 | 회복 |
| `ResultColumn_3` | 648, 554, 170, 48 | 보호 |
| `ResultColumn_4` | 818, 554, 160, 48 | 합동기 |
| `ResultColumn_5` | 978, 554, 350, 48 | EXP |
| `ResultColumn_6` | 1328, 554, 240, 48 | 비고 |
| `ResultEmptyGrowth` | 48, 608, 1824, 48 | 이번 전투 성장 기록이 없습니다. |
| `ResultDetailsButton` | 1596, 548, 270, 52 | 동료 상세 성과·배치·시설·자원 순변동 기록 |
| `ResultPreviewHeading` | 160, 928, 848, 56 | 결산 확인 |
| `ResultPreviewUnavailable` | 160, 978, 848, 64 | 결산을 확인하고 다음 일정으로 진행하세요. |
| `NextDayButton` | 1380, 932, 516, 116 | 다음 DAY |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### result_details · result · DAY1

상태 근거: Victory detailed record overlay. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `ResultGrowthScroll` · scroll_container | 1824×276 | 1824×276 | 충족 | 0 / `@ScrollContainer@1418` |
| `ResultDetailsButton` · button | 270×52 | 270×52 | 미달 | 8 / `ResultGrowthScroll` |
| `NextDayButton` · button | 516×116 | 516×116 | 미달 | 48 / `ResultGrowthScroll` |
| `ResultDetailsClose` · button | 1032×94.5 | 1032×94.5 | 미달 | 11.5 / `@ScrollContainer@1418` |
| `@ScrollContainer@1418` · scroll_container | 1032×346 | 1032×346 | 충족 | 0 / `ResultGrowthScroll` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 469.46 / `ResultDetailsClose` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `V122ResultScreen` · Panel | 1920×1080 | 충족 |
| `ResultHero` · Panel | 1872×510 | 충족 |
| `ResultTitleBanner` · Panel | 880×242 | 충족 |
| `ResultMetricsBanner` · Panel | 880×62 | 미달 |
| `ResultRewards` · Panel | 624×168 | 충족 |
| `ResultGrowthPanel` · Panel | 1872×350 | 충족 |
| `ResultTrainingPreview` · Panel | 1000×140 | 충족 |
| `ResultDetailsPanel` · Panel | 1080×500 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResultDay` DAY 1 | Label | 49 | 충족 / 충족 |
| `ResultTitle` 방어 성공 | Label | 119 | 충족 / 충족 |
| `ResultCoreMetrics` 왕좌 피해 0 · 생존 3 / 3 | Label | 38 | 충족 / 충족 |
| `ResultRewardHeading` 획득 보상 | Label | 32 | 충족 / 미달 |
| `ResultRewardValue_gold` +20 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_mana` +10 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_infamy` +1 | Label | 49 | 충족 / 충족 |
| `ResultColumn_0` 동료 | Label | 32 | 충족 / 미달 |
| `ResultColumn_1` 피해 | Label | 32 | 충족 / 미달 |
| `ResultColumn_2` 회복 | Label | 32 | 충족 / 미달 |
| `ResultColumn_3` 보호 | Label | 32 | 충족 / 미달 |
| `ResultColumn_4` 합동기 | Label | 32 | 충족 / 미달 |
| `ResultColumn_5` EXP | Label | 32 | 충족 / 미달 |
| `ResultColumn_6` 비고 | Label | 32 | 충족 / 미달 |
| `ResultEmptyGrowth` 이번 전투 성장 기록이 없습니다. | Label | 32 | 충족 / 미달 |
| `ResultDetailsButton` 상세 기록 | Button(보충) | 24 | 미달 / 미달 |
| `ResultPreviewHeading` 결산 확인 | Label | 38 | 충족 / 충족 |
| `ResultPreviewUnavailable` 결산을 확인하고 다음 일정으로 진행하세요. | Label | 32 | 충족 / 미달 |
| `NextDayButton` 다음 DAY | Button(보충) | 38 | 충족 / 충족 |
| `ResultDetailsClose` 닫기 | Button(보충) | 38 | 충족 / 충족 |
| `ResultObservation` 관찰 · 몬스터 생존 3/3 | Label | 32 | 충족 / 미달 |
| `Copy` 왕좌 피해 0 | Label | 32 | 충족 / 미달 |
| `@Label@1420` 몬스터 생존 3 / 3 | Label | 32 | 충족 / 미달 |
| `@Label@1421` 최종 돌파 구간 돌파 없음 | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `ResultGrowthScroll` ↔ `ResultDetailsButton` | 8 | 아니오 |
| `ResultGrowthScroll` ↔ `@ScrollContainer@1418` | 0 | 예 |
| `ResultDetailsClose` ↔ `@ScrollContainer@1418` | 11.5 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `ResultDay` | 544, 38, 832, 72 | DAY 1 |
| `ResultTitle` | 544, 100, 832, 174 | 방어 성공 |
| `ResultCoreMetrics` | 536, 286, 848, 56 | 왕좌 피해 0 · 생존 3 / 3 |
| `ResultRewardHeading` | 792, 360, 592, 48 | 획득 보상 |
| `ResultRewardValue_gold` | 792, 466, 197.33, 72 | +20 |
| `ResultRewardValue_mana` | 989.33, 466, 197.33, 72 | +10 |
| `ResultRewardValue_infamy` | 1186.67, 466, 197.33, 72 | +1 |
| `ResultGrowthPanel` | 24, 546, 1872, 350 | 동료 성과 · 승리 후 한 명 집중성장 +8 · 세부는 상세 기록 |
| `ResultColumn_0` | 48, 554, 300, 48 | 동료 |
| `ResultColumn_1` | 348, 554, 150, 48 | 피해 |
| `ResultColumn_2` | 498, 554, 150, 48 | 회복 |
| `ResultColumn_3` | 648, 554, 170, 48 | 보호 |
| `ResultColumn_4` | 818, 554, 160, 48 | 합동기 |
| `ResultColumn_5` | 978, 554, 350, 48 | EXP |
| `ResultColumn_6` | 1328, 554, 240, 48 | 비고 |
| `ResultEmptyGrowth` | 48, 608, 1824, 48 | 이번 전투 성장 기록이 없습니다. |
| `ResultDetailsButton` | 1596, 548, 270, 52 | 동료 상세 성과·배치·시설·자원 순변동 기록 |
| `ResultPreviewHeading` | 160, 928, 848, 56 | 결산 확인 |
| `ResultPreviewUnavailable` | 160, 978, 848, 64 | 결산을 확인하고 다음 일정으로 진행하세요. |
| `NextDayButton` | 1380, 932, 516, 116 | 다음 DAY |
| `ResultDetailsClose` | 444, 356, 1032, 94.5 | 닫기 |
| `ResultObservation` | 444, 462, 1022, 48 | 관찰 · 몬스터 생존 3/3 |
| `Copy` | 444, 642, 1022, 48 | 왕좌 피해 0 |
| `@Label@1420` | 444, 702, 1022, 48 | 몬스터 생존 3 / 3 |
| `@Label@1421` | 444, 762, 1022, 46 | 최종 돌파 구간 돌파 없음 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### defeat · result · DAY1

상태 근거: Synthetic defeat summary, actual result builder. 캡처: `tmp/android_audit/defeat.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `ResultGrowthScroll` · scroll_container | 1824×276 | 1824×276 | 충족 | 8 / `ResultDetailsButton` |
| `ResultDetailsButton` · button | 270×52 | 270×52 | 미달 | 8 / `ResultGrowthScroll` |
| `ResultEditPlacement` · button | 454×100 | 454×100 | 미달 | 24 / `ResultRetrySamePlacement` |
| `ResultRetrySamePlacement` · button | 454×100 | 454×100 | 미달 | 24 / `ResultEditPlacement` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 486 / `ResultDetailsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `V122ResultScreen` · Panel | 1920×1080 | 충족 |
| `ResultHero` · Panel | 1872×510 | 충족 |
| `ResultTitleBanner` · Panel | 880×242 | 충족 |
| `ResultMetricsBanner` · Panel | 880×62 | 미달 |
| `ResultRewards` · Panel | 624×168 | 충족 |
| `ResultGrowthPanel` · Panel | 1872×350 | 충족 |
| `ResultTrainingPreview` · Panel | 890×140 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResultDay` DAY 1 | Label | 49 | 충족 / 충족 |
| `ResultTitle` 방어 실패 | Label | 119 | 충족 / 충족 |
| `ResultCoreMetrics` 왕좌 피해 125 · 생존 1 / 3 | Label | 38 | 충족 / 충족 |
| `ResultRewardHeading` 획득 보상 | Label | 32 | 충족 / 미달 |
| `ResultRewardValue_gold` +0 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_mana` +0 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_infamy` +0 | Label | 49 | 충족 / 충족 |
| `ResultColumn_0` 동료 | Label | 32 | 충족 / 미달 |
| `ResultColumn_1` 피해 | Label | 32 | 충족 / 미달 |
| `ResultColumn_2` 회복 | Label | 32 | 충족 / 미달 |
| `ResultColumn_3` 보호 | Label | 32 | 충족 / 미달 |
| `ResultColumn_4` 합동기 | Label | 32 | 충족 / 미달 |
| `ResultColumn_5` EXP | Label | 32 | 충족 / 미달 |
| `ResultColumn_6` 비고 | Label | 32 | 충족 / 미달 |
| `ResultEmptyGrowth` 이번 전투 성장 기록이 없습니다. | Label | 32 | 충족 / 미달 |
| `ResultDetailsButton` 상세 기록 | Button(보충) | 24 | 미달 / 미달 |
| `ResultPreviewHeading` 재도전 준비 | Label | 38 | 충족 / 충족 |
| `ResultPreviewUnavailable` 배치를 수정하거나 같은 배치로 재도전하세요. | Label | 32 | 충족 / 미달 |
| `ResultEditPlacement` 배치 수정 | Button(보충) | 38 | 충족 / 충족 |
| `ResultRetrySamePlacement` 동일 배치 재도전 | Button(보충) | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `ResultGrowthScroll` ↔ `ResultDetailsButton` | 8 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `ResultDay` | 544, 38, 832, 72 | DAY 1 |
| `ResultTitle` | 544, 100, 832, 174 | 방어 실패 |
| `ResultCoreMetrics` | 536, 286, 848, 56 | 왕좌 피해 125 · 생존 1 / 3 |
| `ResultRewardHeading` | 792, 360, 592, 48 | 획득 보상 |
| `ResultRewardValue_gold` | 792, 466, 197.33, 72 | +0 |
| `ResultRewardValue_mana` | 989.33, 466, 197.33, 72 | +0 |
| `ResultRewardValue_infamy` | 1186.67, 466, 197.33, 72 | +0 |
| `ResultGrowthPanel` | 24, 546, 1872, 350 | 동료 성과 · 승리 후 한 명 집중성장 +8 · 세부는 상세 기록 |
| `ResultColumn_0` | 48, 554, 300, 48 | 동료 |
| `ResultColumn_1` | 348, 554, 150, 48 | 피해 |
| `ResultColumn_2` | 498, 554, 150, 48 | 회복 |
| `ResultColumn_3` | 648, 554, 170, 48 | 보호 |
| `ResultColumn_4` | 818, 554, 160, 48 | 합동기 |
| `ResultColumn_5` | 978, 554, 350, 48 | EXP |
| `ResultColumn_6` | 1328, 554, 240, 48 | 비고 |
| `ResultEmptyGrowth` | 48, 608, 1824, 48 | 이번 전투 성장 기록이 없습니다. |
| `ResultDetailsButton` | 1596, 548, 270, 52 | 동료 상세 성과·배치·시설·자원 순변동 기록 |
| `ResultPreviewHeading` | 160, 928, 738, 56 | 재도전 준비 |
| `ResultPreviewUnavailable` | 160, 978, 738, 64 | 배치를 수정하거나 같은 배치로 재도전하세요. |
| `ResultEditPlacement` | 940, 948, 454, 100 | 배치 수정 |
| `ResultRetrySamePlacement` | 1418, 948, 454, 100 | 동일 배치 재도전 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### defeat_details · result · DAY1

상태 근거: Defeat detailed record overlay. 캡처: `추가 캡처 없음(20장 상한 내 대표만 보관)`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `ResultGrowthScroll` · scroll_container | 1824×276 | 1824×276 | 충족 | 0 / `@ScrollContainer@1446` |
| `ResultDetailsButton` · button | 270×52 | 270×52 | 미달 | 8 / `ResultGrowthScroll` |
| `ResultEditPlacement` · button | 454×100 | 454×100 | 미달 | 24 / `ResultRetrySamePlacement` |
| `ResultRetrySamePlacement` · button | 454×100 | 454×100 | 미달 | 24 / `ResultEditPlacement` |
| `ResultDetailsClose` · button | 1032×94.5 | 1032×94.5 | 미달 | 11.5 / `@ScrollContainer@1446` |
| `@ScrollContainer@1446` · scroll_container | 1032×346 | 1032×346 | 충족 | 0 / `ResultGrowthScroll` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 469.46 / `ResultDetailsClose` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `V122ResultScreen` · Panel | 1920×1080 | 충족 |
| `ResultHero` · Panel | 1872×510 | 충족 |
| `ResultTitleBanner` · Panel | 880×242 | 충족 |
| `ResultMetricsBanner` · Panel | 880×62 | 미달 |
| `ResultRewards` · Panel | 624×168 | 충족 |
| `ResultGrowthPanel` · Panel | 1872×350 | 충족 |
| `ResultTrainingPreview` · Panel | 890×140 | 충족 |
| `ResultDetailsPanel` · Panel | 1080×500 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResultDay` DAY 1 | Label | 49 | 충족 / 충족 |
| `ResultTitle` 방어 실패 | Label | 119 | 충족 / 충족 |
| `ResultCoreMetrics` 왕좌 피해 125 · 생존 1 / 3 | Label | 38 | 충족 / 충족 |
| `ResultRewardHeading` 획득 보상 | Label | 32 | 충족 / 미달 |
| `ResultRewardValue_gold` +0 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_mana` +0 | Label | 49 | 충족 / 충족 |
| `ResultRewardValue_infamy` +0 | Label | 49 | 충족 / 충족 |
| `ResultColumn_0` 동료 | Label | 32 | 충족 / 미달 |
| `ResultColumn_1` 피해 | Label | 32 | 충족 / 미달 |
| `ResultColumn_2` 회복 | Label | 32 | 충족 / 미달 |
| `ResultColumn_3` 보호 | Label | 32 | 충족 / 미달 |
| `ResultColumn_4` 합동기 | Label | 32 | 충족 / 미달 |
| `ResultColumn_5` EXP | Label | 32 | 충족 / 미달 |
| `ResultColumn_6` 비고 | Label | 32 | 충족 / 미달 |
| `ResultEmptyGrowth` 이번 전투 성장 기록이 없습니다. | Label | 32 | 충족 / 미달 |
| `ResultDetailsButton` 상세 기록 | Button(보충) | 24 | 미달 / 미달 |
| `ResultPreviewHeading` 재도전 준비 | Label | 38 | 충족 / 충족 |
| `ResultPreviewUnavailable` 배치를 수정하거나 같은 배치로 재도전하세요. | Label | 32 | 충족 / 미달 |
| `ResultEditPlacement` 배치 수정 | Button(보충) | 38 | 충족 / 충족 |
| `ResultRetrySamePlacement` 동일 배치 재도전 | Button(보충) | 38 | 충족 / 충족 |
| `ResultDetailsClose` 닫기 | Button(보충) | 38 | 충족 / 충족 |
| `ResultObservation` 관찰 · 왕좌 피해 125 | Label | 32 | 충족 / 미달 |
| `Copy` 왕좌 피해 125 | Label | 32 | 충족 / 미달 |
| `@Label@1448` 몬스터 생존 1 / 3 | Label | 32 | 충족 / 미달 |
| `@Label@1449` 최종 돌파 구간 돌파 없음 | Label | 32 | 충족 / 미달 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `ResultGrowthScroll` ↔ `ResultDetailsButton` | 8 | 아니오 |
| `ResultGrowthScroll` ↔ `@ScrollContainer@1446` | 0 | 예 |
| `ResultDetailsClose` ↔ `@ScrollContainer@1446` | 11.5 | 아니오 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `ResultDay` | 544, 38, 832, 72 | DAY 1 |
| `ResultTitle` | 544, 100, 832, 174 | 방어 실패 |
| `ResultCoreMetrics` | 536, 286, 848, 56 | 왕좌 피해 125 · 생존 1 / 3 |
| `ResultRewardHeading` | 792, 360, 592, 48 | 획득 보상 |
| `ResultRewardValue_gold` | 792, 466, 197.33, 72 | +0 |
| `ResultRewardValue_mana` | 989.33, 466, 197.33, 72 | +0 |
| `ResultRewardValue_infamy` | 1186.67, 466, 197.33, 72 | +0 |
| `ResultGrowthPanel` | 24, 546, 1872, 350 | 동료 성과 · 승리 후 한 명 집중성장 +8 · 세부는 상세 기록 |
| `ResultColumn_0` | 48, 554, 300, 48 | 동료 |
| `ResultColumn_1` | 348, 554, 150, 48 | 피해 |
| `ResultColumn_2` | 498, 554, 150, 48 | 회복 |
| `ResultColumn_3` | 648, 554, 170, 48 | 보호 |
| `ResultColumn_4` | 818, 554, 160, 48 | 합동기 |
| `ResultColumn_5` | 978, 554, 350, 48 | EXP |
| `ResultColumn_6` | 1328, 554, 240, 48 | 비고 |
| `ResultEmptyGrowth` | 48, 608, 1824, 48 | 이번 전투 성장 기록이 없습니다. |
| `ResultDetailsButton` | 1596, 548, 270, 52 | 동료 상세 성과·배치·시설·자원 순변동 기록 |
| `ResultPreviewHeading` | 160, 928, 738, 56 | 재도전 준비 |
| `ResultPreviewUnavailable` | 160, 978, 738, 64 | 배치를 수정하거나 같은 배치로 재도전하세요. |
| `ResultEditPlacement` | 940, 948, 454, 100 | 배치 수정 |
| `ResultRetrySamePlacement` | 1418, 948, 454, 100 | 동일 배치 재도전 |
| `ResultDetailsClose` | 444, 356, 1032, 94.5 | 닫기 |
| `ResultObservation` | 444, 462, 1022, 48 | 관찰 · 왕좌 피해 125 |
| `Copy` | 444, 642, 1022, 48 | 왕좌 피해 125 |
| `@Label@1448` | 444, 702, 1022, 48 | 몬스터 생존 1 / 3 |
| `@Label@1449` | 444, 762, 1022, 46 | 최종 돌파 구간 돌파 없음 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |

### council_management · management · DAY16

상태 근거: Council season DAY16 management, temporary 1F expansion fixture. 캡처: `tmp/android_audit/council_management.png`.

| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |
|---|---:|---:|---|---|
| `OpenIntrusionBriefButton` · button | 180×67.4 | 180×67.4 | 미달 | 32 / `FitManagementMapButton` |
| `FitManagementMapButton` · button | 226×67.4 | 226×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ZoomOutManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `FitManagementMapButton` |
| `ZoomInManagementMapButton` · button | 60×67.4 | 60×67.4 | 미달 | 10 / `ZoomOutManagementMapButton` |
| `ManagementSettingsButton` · button | 78×58 | 78×58 | 미달 | 12 / `ZoomInManagementMapButton` |
| `ManagementMenuButton` · button | 78×58 | 78×58 | 미달 | 14 / `ManagementSettingsButton` |
| `ManagementRecordsButton` · button | 78×58 | 78×58 | 미달 | 0 / `CommonGameMenuButton` |
| `DecorationStatusButton` · button | 340×67.4 | 340×67.4 | 미달 | 557.84 / `BuildingCardScroll` |
| `ManagementTab_build` · button | 210.8×96.4 | 210.8×96.4 | 미달 | 8 / `DecorationPaletteButton` |
| `ManagementTab_roster` · button | 241.8×96.4 | 241.8×96.4 | 미달 | 9.2 / `ManagementTab_build` |
| `ManagementTab_tactics` · button | 208.8×96.4 | 208.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `MonsterManagementButton` · button | 237.8×96.4 | 237.8×96.4 | 미달 | 9.2 / `ManagementTab_tactics` |
| `StartCombatButton` · button | 284.8×96.4 | 284.8×96.4 | 미달 | 9.2 / `MonsterManagementButton` |
| `BuildingCardScroll` · scroll_container | 1072×132.8 | 1072×132.8 | 충족 | 19.2 / `ManagementTab_build` |
| `FacilityCard_barracks` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_treasure` |
| `FacilityCard_treasure` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_barracks` |
| `FacilityCard_recovery` · button | 320×122 | 320×122 | 미달 | 12 / `FacilityCard_treasure` |
| `FacilityCard_watch_post` · button (클립) | 76×122 | 320×122 | 미달 | 12 / `FacilityCard_recovery` |
| `DecorationPaletteButton` · button | 316×88.4 | 316×88.4 | 미달 | 0 / `PlacementUndoButton` |
| `PlacementUndoButton` · button (비활성) | 280×96.4 | 280×96.4 | 미달 | 0 / `DecorationPaletteButton` |
| `OpenManagementContextButton` · button (클립) | 90×96.4 | 128.8×96.4 | 미달 | 368 / `ManagementRecordsButton` |
| `CommonGameMenuButton` · button | 48×48 | 48×48 | 미달 | 0 / `ManagementRecordsButton` |

| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |
|---|---:|---|
| `ResourceStatusRail` · Panel | 1888×60 | 미달 |
| `DayStatusBadge` · Label | 170×53 | 미달 |
| `BossHpBar` · Panel | 340×100 | 미달 |
| `ManagementToolTabs` · Panel | 1200×96 | 미달 |
| `BuildingToolbox` · Panel | 1088×144 | 충족 |
| `BuildingSlotCount` · Panel | 340×144 | 충족 |

| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |
|---|---|---:|---|
| `ResourceValue_gold` 1245 | Label | 38 | 충족 / 충족 |
| `ResourceValue_mana` 320 | Label | 38 | 충족 / 충족 |
| `ResourceValue_food` 18 | Label | 38 | 충족 / 충족 |
| `ResourceValue_infamy` 620 | Label | 38 | 충족 / 충족 |
| `DayStatusBadge` DAY 16 | Label | 35 | 충족 / 미달 |
| `OpenIntrusionBriefButton` × 4 | Button(보충) | 24 | 미달 / 미달 |
| `FitManagementMapButton` 지도 전체 | Button(보충) | 24 | 미달 / 미달 |
| `ZoomOutManagementMapButton` − | Button(보충) | 24 | 미달 / 미달 |
| `ZoomInManagementMapButton` + | Button(보충) | 24 | 미달 / 미달 |
| `Copy` 1500 / 1500 | Label | 32 | 충족 / 미달 |
| `@Label@1485` 250 / 250 | Label | 32 | 충족 / 미달 |
| `DecorationStatusButton` 성 등급 F · 위압감 0 | Button(보충) | 24 | 미달 / 미달 |
| `ManagementTab_build` 건설 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_roster` 수비대 | Button(보충) | 38 | 충족 / 충족 |
| `ManagementTab_tactics` 전술 | Button(보충) | 38 | 충족 / 충족 |
| `MonsterManagementButton` 몬스터 | Button(보충) | 38 | 충족 / 충족 |
| `StartCombatButton` 전투 시작 | Button(보충) | 38 | 충족 / 충족 |
| `Copy` 병영 | Label | 32 | 충족 / 미달 |
| `@Label@1508` 100 | Label | 32 | 충족 / 미달 |
| `@Label@1510` 2 | Label | 32 | 충족 / 미달 |
| `Copy` 보물 보관실 | Label | 32 | 충족 / 미달 |
| `@Label@1515` 120 | Label | 32 | 충족 / 미달 |
| `Copy` 회복 둥지 | Label | 32 | 충족 / 미달 |
| `@Label@1520` 80 | Label | 32 | 충족 / 미달 |
| `BuildingSlotCountLabel` 설치 5 / 열린 구역 6 | Label | 32 | 충족 / 미달 |
| `DecorationPaletteButton` 꾸미기 | Button(보충) | 38 | 충족 / 충족 |
| `PlacementUndoButton` 되돌리기 | Button(보충) | 38 | 충족 / 충족 |

| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |
|---|---:|---|
| `FitManagementMapButton` ↔ `ZoomOutManagementMapButton` | 10 | 아니오 |
| `ZoomOutManagementMapButton` ↔ `ZoomInManagementMapButton` | 10 | 아니오 |
| `ZoomInManagementMapButton` ↔ `ManagementSettingsButton` | 12 | 아니오 |
| `ManagementSettingsButton` ↔ `ManagementMenuButton` | 14 | 아니오 |
| `ManagementMenuButton` ↔ `ManagementRecordsButton` | 14 | 아니오 |
| `ManagementRecordsButton` ↔ `CommonGameMenuButton` | 0 | 예 |
| `ManagementTab_build` ↔ `ManagementTab_roster` | 9.2 | 아니오 |
| `ManagementTab_build` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_build` ↔ `DecorationPaletteButton` | 8 | 아니오 |
| `ManagementTab_roster` ↔ `ManagementTab_tactics` | 9.2 | 아니오 |
| `ManagementTab_roster` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `ManagementTab_tactics` ↔ `MonsterManagementButton` | 9.2 | 아니오 |
| `ManagementTab_tactics` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `MonsterManagementButton` ↔ `StartCombatButton` | 9.2 | 아니오 |
| `MonsterManagementButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `StartCombatButton` ↔ `BuildingCardScroll` | 19.2 | 아니오 |
| `FacilityCard_barracks` ↔ `FacilityCard_treasure` | 12 | 아니오 |
| `FacilityCard_treasure` ↔ `FacilityCard_recovery` | 12 | 아니오 |
| `FacilityCard_recovery` ↔ `FacilityCard_watch_post` | 12 | 아니오 |
| `DecorationPaletteButton` ↔ `PlacementUndoButton` | 0 | 예 |

| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |
|---|---|---:|---|---:|---:|
| `room:entrance` | room_floor_bounds_with_nearest_cell_fallback / — | 173.14×86.57 | 미달 | — | 80 |
| `room:spike_corridor` | room_floor_bounds_with_nearest_cell_fallback / — | 190.46×86.57 | 미달 | — | 72 |
| `room:barracks` | room_floor_bounds_with_nearest_cell_fallback / — | 173.14×86.57 | 미달 | — | 168 |
| `room:recovery` | room_floor_bounds_with_nearest_cell_fallback / — | 173.14×86.57 | 미달 | — | 208 |
| `room:treasure` | room_floor_bounds_with_nearest_cell_fallback / — | 173.14×86.57 | 미달 | — | 200 |
| `room:throne` | room_floor_bounds_with_nearest_cell_fallback / — | 173.14×86.57 | 미달 | — | 232 |
| `room:slot_01` | room_floor_bounds_with_nearest_cell_fallback / — | 173.14×86.57 | 미달 | — | 232 |
| `room:center` | room_floor_bounds_with_nearest_cell_fallback / — | 191.95×155.88 | 충족 | — | 0 |
| `room:crown_sanctum` | room_floor_bounds_with_nearest_cell_fallback / — | 103.89×51.94 | 미달 | — | 504 |
| `room:seal_vault` | room_floor_bounds_with_nearest_cell_fallback / — | 103.89×51.94 | 미달 | — | 176 |

| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |
|---|---|---|
| `@TextureRect@1469` | 36, 17, 40, 40 | 금화 |
| `ResourceValue_gold` | 82, 15, 120, 57 | 1245 |
| `@TextureRect@1470` | 230, 17, 40, 40 | 마력 |
| `ResourceValue_mana` | 276, 15, 120, 57 | 320 |
| `@TextureRect@1471` | 424, 17, 40, 40 | 식량 |
| `ResourceValue_food` | 470, 15, 120, 57 | 18 |
| `@TextureRect@1472` | 618, 17, 40, 40 | 악명 |
| `ResourceValue_infamy` | 664, 15, 120, 57 | 620 |
| `DayStatusBadge` | 858, 15, 170, 53 | 성 등급으로 열린 1층 구역 검수; 왕관실·금고 자유 배치와 자동 길 학습<br>마왕성 1/4 · 신생 마굴<br>구역 6 · 시설 Lv.2 |
| `OpenIntrusionBriefButton` | 1036, 8, 180, 67.4 | 오늘의 침입 · 편대와 실제 경로 보기 |
| `FitManagementMapButton` | 1248, 8, 226, 67.4 | 지도 전체 |
| `ZoomOutManagementMapButton` | 1484, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ZoomInManagementMapButton` | 1554, 8, 60, 67.4 | 휠: 확대·축소 / 휠 버튼 드래그: 이동 |
| `ManagementSettingsButton` | 1626, 8, 78, 58 | 설정 |
| `ManagementMenuButton` | 1718, 8, 78, 58 | 메뉴 |
| `ManagementRecordsButton` | 1810, 8, 78, 58 | 기록실 |
| `BossHpBar` | 24, 80, 340, 100 | 현재 보호 목표 체력 |
| `Copy` | 82, 82, 268, 49 | 1500 / 1500 |
| `@Label@1485` | 82, 134, 268, 49 | 250 / 250 |
| `DecorationStatusButton` | 24, 194, 340, 67.4 | 마왕성 1/4 · 신생 마굴<br>평가 0 = 성장 0 + 꾸밈 0/10<br>전투 효과 없음 · 부지 확장은 기존 승급 조건 유지 |
| `ManagementTab_build` | 360, 968, 210.8, 96.4 | 건설 |
| `ManagementTab_roster` | 580, 968, 241.8, 96.4 | 수비대 |
| `ManagementTab_tactics` | 831, 968, 208.8, 96.4 | 전술 |
| `MonsterManagementButton` | 1049, 968, 237.8, 96.4 | 몬스터 |
| `StartCombatButton` | 1296, 968, 284.8, 96.4 | 현재 배치와 전술로 전투 시작 |
| `FacilityCard_barracks` | 424, 816, 320, 122 | 병영<br>체력 450 / 몬스터 4명 배치. 연결 구역: 정원 +1 · 공격 +10% · 받는 피해 -8%.<br>입구와 왕좌 사이의 필수 길목, 또는 여러 길이 합쳐지는 방에 적합합니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 532, 822, 204, 60 | 병영 |
| `FacilityCard_treasure` | 756, 816, 320, 122 | 보물 보관실<br>체력 250 / 몬스터 2명 배치. 도둑은 이 방을 목표로 이동합니다. 5초 방치되면 금화 100을 잃습니다.<br>왕좌 직전보다 한 칸 바깥에 두고, 병영이나 감시 초소가 바로 덮을 수 있게 두세요.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 864, 822, 204, 60 | 보물 보관실 |
| `FacilityCard_recovery` | 1088, 816, 320, 122 | 회복 둥지<br>체력 350 / 몬스터 2명 배치. 연결 구역: 초당 8.0 회복.<br>주력 교전 방 뒤쪽이나 왕좌 근처에 두면 후퇴 동선이 짧아집니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `Copy` | 1196, 822, 204, 60 | 회복 둥지 |
| `FacilityCard_watch_post` | 1420, 816, 76, 122 | 감시 초소<br>체력 380 / 몬스터 3명 배치. 연결 구역: 적 이동 -18%. 같은 전선: 적 노출 · 적이 받는 피해 +12%.<br>입구 가까운 긴 경로, 보물 방으로 가는 우회로, 새로 만든 분기 앞에 적합합니다.<br>클릭·드롭 즉시 설치 / ESC 취소 |
| `BuildingSlotCountLabel` | 36, 822, 316, 49 | 설치 5 / 열린 구역 6 |
| `DecorationPaletteButton` | 36, 883, 316, 88.4 | 꾸미기 |
| `PlacementUndoButton` | 24, 968, 280, 96.4 | 마지막 건설·배치 1회와 자원 복원 |
| `OpenManagementContextButton` | 1830, 434, 90, 96.4 | 선택 상세 |
| `CommonGameMenuButton` | 1842, 14, 48, 48 | 게임 메뉴<br>계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다. |
