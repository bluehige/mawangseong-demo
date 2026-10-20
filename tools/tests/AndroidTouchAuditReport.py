"""Validate AndroidTouchAuditTest evidence and write its Korean measurement report.

Run after RunAndroidTouchAudit.ps1; does not launch Godot or modify product files.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "tmp/android_audit"
REPORT = ROOT / "docs/handoff/ANDROID_TOUCH_AUDIT_2026-10-15.md"
BASE = "9befdd2afc32bbf1f0a231bae5bd840b09d33cfe"
EXPECTED = {
    "title", "name_entry", "dialogue", "management_build", "management_build_right",
    "placement_preview", "decoration", "garrison", "management_tactics", "monster",
    "chronicle_0", "chronicle_1", "chronicle_2", "ending_archive", "memory_archive",
    "combat_hud", "combat_selected", "combat_tactics_details", "combat_details_bottom",
    "result", "result_details", "defeat", "defeat_details", "council_management",
} | {f"settings_{tab}{suffix}" for tab in ("general", "display", "audio", "accessibility", "combat") for suffix in ("", "_bottom")}


def fmt(value):
    if value is None:
        return "—"
    return f"{value:.2f}".rstrip("0").rstrip(".")


def cell(value):
    return str(value).replace("|", "\\|").replace("\r", "").replace("\n", "<br>")


def short(value, limit=76):
    value = str(value).replace("\n", " / ")
    return cell(value[:limit] + ("…" if len(value) > limit else ""))


def dimensions(rect):
    return f"{fmt(rect[2])}×{fmt(rect[3])}"


def validate(data):
    assert data["base_sha"] == BASE
    assert not data["failures"], data["failures"]
    assert data["criteria"] == {"touch_px": 128, "gap_px": 20, "body_font_px": 36, "minimum_font_px": 30, "mm_per_px": .063}
    assert {s["id"] for s in data["screens"]} == EXPECTED
    assert len(data["screens"]) == len(EXPECTED)
    assert len(data["captures"]) <= 20
    expected_screen = {name: name for name in ("title", "name_entry", "dialogue", "monster", "ending_archive", "memory_archive")}
    expected_screen.update({name: "management" for name in ("management_build", "management_build_right", "placement_preview", "decoration", "garrison", "management_tactics", "council_management")})
    expected_screen.update({name: "settings" for name in EXPECTED if name.startswith("settings_")})
    expected_screen.update({name: "combat" for name in EXPECTED if name.startswith("combat_")})
    expected_screen.update({name: "chronicle" for name in EXPECTED if name.startswith("chronicle_")})
    expected_screen.update({name: "result" for name in ("result", "result_details", "defeat", "defeat_details")})
    for screen in data["screens"]:
        assert screen["touch_ui"] and screen["window_px"] == [1920, 1080]
        assert screen["controls"] and screen["labels"]
        assert screen["screen"] == expected_screen[screen["id"]]
        for row in screen["controls"] + screen["passive_stop_candidates"]:
            rect = row["visible_rect_px"]
            assert all(math.isfinite(v) for v in rect)
            assert rect[2] > 0 and rect[3] > 0
            assert row["below_target"] == (rect[2] < 128 or rect[3] < 128)
        for row in screen["labels"]:
            assert row["font_px"] and all(math.isfinite(v) and v > 0 for v in row["font_px"])
            assert row["below_minimum_30"] == (min(row["font_px"]) < 30)
            assert row["below_body_36"] == (min(row["font_px"]) < 36)
        for pair in screen["gap_pairs_below_20"]:
            assert 0 <= pair["gap_px"] < 20
        assert len({r["id"] for r in screen["world_targets"]}) == len(screen["world_targets"])
        if screen["capture"]:
            assert (ROOT / screen["capture"]).is_file()
    combat = next(s for s in data["screens"] if s["id"] == "combat_selected")
    assert {"CombatMinimap", "CombatUnitInspectorClose", "CombatRepresentativeSkill"} <= {r["name"] for r in combat["controls"]}
    assert any(r["shape"] == "circle" for r in combat["world_targets"])
    assert len([s for s in data["screens"] if s["map_sample"]]) == 3
    assert (EVIDENCE / "stderr.log").read_text(encoding="utf-8").strip() == ""
    processes = json.loads((EVIDENCE / "process_counts.json").read_text(encoding="utf-8-sig"))
    assert processes == {"before": 0, "maximum": 1, "after": 0, "exit_code": 0}


MOUSE_FINDINGS = """| 종류 | 위치·근거 | 동작·실제 문구 | 터치 대체 / 판정 |
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
"""


def generate(data, reviewed_sha):
    screens = data["screens"]
    controls = [r for s in screens for r in s["controls"]]
    labels = [r for s in screens for r in s["labels"] if r["label_required"]]
    gaps = [p for s in screens for p in s["gap_pairs_below_20"]]
    tips = [r for s in screens for r in s["tooltips"]]
    totals = {"states": len(screens), "control_observations": len(controls), "small_controls": sum(r["below_target"] for r in controls), "enabled_controls": sum(not r["disabled"] for r in controls), "small_enabled_controls": sum(r["below_target"] and not r["disabled"] for r in controls), "label_observations": len(labels), "labels_below_30": sum(r["below_minimum_30"] for r in labels), "labels_below_36": sum(r["below_body_36"] for r in labels), "gap_pairs_below_20": len(gaps), "tooltip_observations": len(tips), "captures": len(data["captures"])}
    buttons = [r for r in controls if r["kind"] == "button"]
    button_gaps = 0
    for screen in screens:
        by_path = {r["path"]: r for r in screen["controls"]}
        button_gaps += sum(by_path[p["a"]]["kind"] == by_path[p["b"]]["kind"] == "button" for p in screen["gap_pairs_below_20"])
    totals.update(button_observations=len(buttons), small_buttons=sum(r["below_target"] for r in buttons), button_gap_pairs_below_20=button_gaps)
    (EVIDENCE / "summary.json").write_text(json.dumps(totals, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["# Android 전환 1단계: 터치·글자 자동 측정 (2026-10-15)", "", "## 1. 메타데이터", "", f"- 목표: 현재 제품 1.3.0 기반 Android 준비 1단계. 브랜치 `codex/v131-android`.", f"- 사용자 지정 기준 SHA: `{BASE}`. 측정 도구 검토 SHA: `{reviewed_sha}`.", "- 로컬 main 부재. origin/main 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`; 이번 원격 조회/fetch 없음. 최신 main 권위를 확정하지 않고 사용자가 지정한 HEAD를 측정했다.", "- 로컬 영어 커밋만. push·merge·태그·export·Steam 변경 없음.", "", "## 2. 목표·측정 기준", "", "화면 코드를 수정하지 않고 현재 터치 UI를 측정한다. 1920×1080 캔버스·한국어·기본 글자 배율 1.0·자동 레이아웃·`--mobile-touch-ui`를 사용했고 모든 상태에서 `UISettings.is_touch_ui() == true`를 확인했다. touch 모드와 compact 레이아웃은 별개다. 사용자 가정인 6.5인치 20:9 폰·1px≈0.063mm를 판정 근거로 유지한다. 20:9 실기 화면을 직접 렌더하거나 Android APK를 실행한 결과는 아니다.", "", "| 항목 | 기준 | 판정 |", "|---|---|---|", "| 터치 대상 | 너비·높이 모두 ≥128px (약 8.06mm) | 보이는 클립 영역의 한 변이라도 작으면 미달 |", "| 버튼 사이 | 경계 간 최단 거리 ≥20px (약 1.26mm) | 대각선은 유클리드 거리, 겹침은 0px; 부모·자식 쌍 제외 |", "| 본문 | ≥36px (약 2.27mm) | 의미상 본문 여부를 자동 추정하지 않고 모든 글자의 `<36`을 별도 표시 |", "| 최소 글자 | ≥30px (약 1.89mm) | 실제 테마 글자 크기×렌더 변환 Y배율 |", "", "## 3. 완료 내용과 요약", "", f"**{len(screens)}개 화면 상태**를 자동 측정했다. 입력 Control 관측 {len(controls)}건 중 **{totals['small_controls']}건**이 128×128 미달이며, 활성 입력만 보면 {totals['enabled_controls']}건 중 **{totals['small_enabled_controls']}건**이다. Label/RichTextLabel {len(labels)}건 중 **{totals['labels_below_30']}건**은 최소30 미달, **{totals['labels_below_36']}건**은 본문36 미달이다. 20px 미만 인접 쌍은 **{len(gaps)}건**이다.", "", "분모는 화면 상태별 관측 수다. 같은 버튼이 여러 탭·스크롤 위치·모달 상태에서 반복되므로 고유 결함 수로 해석하지 않는다. 비활성 버튼은 별도 표시하되 향후 활성화될 같은 화면 대상으로 수집한다. STOP 수동 후보, 맵 판정, 버튼 내 글자는 위 Label 분모와 구분한다. 수치 미달은 관찰 결과이며 측정 테스트의 실패 조건이 아니다.", "", "스토리·게임 데이터·밸런스·저장 형식·UI·그래픽·오디오·출시 파일은 수정하지 않았다. 실제 전투는 DAY1 3.5초 시점까지 진행하고 정지했다. 승리·패배 결산과 의회 DAY16은 기존 화면 빌더에 합성 상태를 전달한 측정 픽스처다. 자연 플레이 완주 증거로 사용하지 않는다.", "", "| 화면 상태 | 입력 수 / 128 미달 | 활성 입력 / 미달 | Label 수 / <30 / <36 | <20px 쌍 | 맵 대상 |", "|---|---:|---:|---:|---:|---:|"]
    for s in screens:
        cs = s["controls"]; ls = [r for r in s["labels"] if r["label_required"]]; enabled = [r for r in cs if not r["disabled"]]
        lines.append(f"| `{s['id']}` | {len(cs)} / {sum(r['below_target'] for r in cs)} | {len(enabled)} / {sum(r['below_target'] for r in enabled)} | {len(ls)} / {sum(r['below_minimum_30'] for r in ls)} / {sum(r['below_body_36'] for r in ls)} | {len(s['gap_pairs_below_20'])} | {len(s['world_targets'])} |")
    lines += ["", "## 4. 변경 파일", "", "| 경로 | 변경 목적 |", "|---|---|", "| `tools/tests/AndroidTouchAuditTest.gd` | 런타임 화면·입력·글자·툴팁·맵 판정 수집 |", "| `tools/tests/AndroidTouchAuditTest.tscn` | 재사용 실행 씬 |", "| `tools/tests/RunAndroidTouchAudit.ps1` | 개인 저장과 격리, 엔진 1프로세스 실행·전후 검사 |", "| `tools/tests/AndroidTouchAuditReport.py` | JSON 구조·기준·커버리지 검증과 이 보고서 재생성 |", "| `docs/handoff/ANDROID_TOUCH_AUDIT_2026-10-15.md` | 측정 결과·세션 인계 |", "| `docs/handoff/CURRENT.md` | 이번 결과 진입 링크 |", "", "## 5. 자산·대표 캡처", "", "이미지 생성·Sweep·갤러리 미실행. 생성 그래픽/오디오 자산 없음. 아래 PNG는 기존 게임의 실제 1920×1080 뷰포트 캡처다. 캡처는 커밋하지 않으며 JSON과 함께 로컬 `tmp/android_audit/`에 보관한다.", "", "| 화면 | 대표 캡처 |", "|---|---|"]
    for s in screens:
        if s["capture"]:
            lines.append(f"| `{s['id']}` | `{s['capture']}` |")
    lines += ["", "## 6. 실행·검증과 측정 방식", "", "```powershell", "powershell -NoProfile -ExecutionPolicy Bypass -File tools/tests/RunAndroidTouchAudit.ps1 -Capture", f"python tools/tests/AndroidTouchAuditReport.py --reviewed-sha {reviewed_sha}", "```", "", "기존 캡처가 있으면 `-Capture` 실행은 거부하며, 캡처 없이 재측정할 수 있다. Godot GUI 실행 파일은 설치된 `godot-gui.cmd` 내용에서 확인하고 직접 실행한다. 임의의 앱 내부 버전 경로를 추측하지 않는다. APPDATA는 `tmp/android_audit/profile`로 격리하고 자동 캠페인 저장을 끈다.", "", f"- Godot {data['engine']['string']}, OpenGL compatibility / {data['renderer']}. 스크립트 검사 {data['checks']}건, 실패 0건. JSON/전체 상태 커버리지 검증 PASS.", "- 최종 실행 Godot 전0·최대1·후0 (`process_counts.json`). 초기 측정의 콘솔 래퍼는 엔진1+콘솔 보조1 프로세스였으며 이후 직접 GUI 호출로 교정했다. 최초부터 엄격한 1프로세스를 지켰다는 주장은 하지 않는다.", "- 초기 실패/진단은 `attempt01/`~`attempt03/`에 보존했다. 첫 시도는 PowerShell이 네이티브 stderr 진단에서 중단했고, 두 번째는 의회 픽스처의 전초기지 선행 조건 누락을 검출했다. 세 번째는 캡처 인자 연결 공백 오류를 검출했다. 검사 기대값을 낮추지 않고 실행기·픽스처를 수정했다.", "- 전체 회귀·전체 플레이·검수 에이전트 NOT_REQUESTED. 별도 에이전트는 입력 방식의 읽기 전용 소스 조사만 수행했다.", "", "- Review task ID: NOT_REQUESTED", f"- Reviewed SHA: {reviewed_sha}", f"- Review range: {BASE}..{reviewed_sha}", "- Remaining P1/P2: N/A", "- Final review result: TARGETED_PASS", "", "Control은 `is_visible_in_tree`, 알파0 제외, 뷰포트와 조상 `clip_contents` 교집합 후 수집했다. Button/BaseButton·Slider·ScrollBar·LineEdit·TextEdit·연결된 GUI 입력/링크와 STOP 후보를 기록한다. 테마 상속과 터치 배율이 적용된 `get_theme_font_size`에 `get_stretch_transform() * get_global_transform_with_canvas()`의 Y배율을 곱했다. RichTextLabel은 기본 및 사용된 굵게/기울임/고정폭 테마·명시 font_size 태그를 수집한다. [CanvasItem 좌표 변환 공식 문서](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-get-global-transform-with-canvas), [RichTextLabel 테마/태그 공식 문서](https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html).", "", "맵의 유닛은 실제 선택 함수의 터치 반경(관리104 world px, 전투96 world px), 적 명령 판정은192×220 world px를 현재 카메라/캔버스 배율로 환산했다. 방은 원형 반경이 없으며 `ModuleGraph.room_at_world`가 타일 적중 후 가장 가까운 방 타일로 무제한 폴백한다. 그래서 방 바닥 AABB(축에 평행한 외접 사각형)와 실제 picker의 8px 격자 측정값을 함께 기록했다. 격자에서 UI에 막힌 점과 더 가까운 유닛이 가로채는 점을 제외한 최대 정사각형은 근삿값이다. 방 바닥 경계를 실제 유한 탭 반경으로 해석하면 안 된다.", "", "## 7. 제한·다음 단계 판단", "", "- 겹치는 다른 Control의 불투명 픽셀별 가림/임의 `_has_point` 형상은 수집 사각형에서 빼지 않는다. 클립 후 입력 경계·겹침을 측정한 것이며 모든 지점에 실제 탭을 보내 도달성을 증명한 결과는 아니다. 맵 3상태에만 실제 입력 차단 함수를 적용한 격자 결과를 추가했다.", "- 맵 원형의 외접 크기가128 이상이어도 다른 유닛과 겹치면 독립 선택이 어려울 수 있다. 인접 원 간0px 및 격자 도달 정사각형을 함께 판단한다. 미니맵 내부 점은 연속 좌표 이동용이며 독립 Button으로 세지 않는다.", "- 커스텀 draw_string, 그림에 포함된 글자, PopupMenu의 직접 그리기 항목, 가상 키보드는 Label/RichTextLabel 분모 밖이다. 버튼/입력 글자는 별도 보충 수집했다. 20:9 레터박스·기기 DPI·시스템 글꼴 배율·손가락 터치 체감은 실기 확인이 필요하다.", "- 이번 측정은 현재 초기/지정 회차 상태다. 모든 해금 조합·모든 스토리 문장·언어3종·전체30일은 범위 밖이다. 한국어 기본 배율 결과를 다른 언어/폰 크기에 그대로 일반화하지 않는다.", "- 주요 축소 대상은 타이틀 버튼 높이, 관리 상단/하단·설정 탭/슬라이더, 전투40px 메뉴·80px 행동·배속 버튼이다. 수정 우선순위는 다음 단계에서 결정한다. **이번 UI 수정은 0건**.", "", "## 8. 마우스·키보드·hover 의존 목록", "", MOUSE_FINDINGS, "", "## 9. 작업트리·보존", "", "기존 미커밋1498파일(수정 import1423·미추적 UID75)의 바이트는 작업 시작 지문과 비교한다(`preservation_before.json`, `preservation_check.json`). 해당 파일은 스테이징하지 않는다. Steam-1.3.0-Ready35파일은 경로·크기·수정시각을 대조하고, 저장소 제품·출시 파일의 HEAD 대비 diff가 없음을 확인한다. `tmp/android_audit/`는 미추적 증거이며 커밋 대상이 아니다. stash·별도 작업트리·원격 조치 없음.", "", "## 10. 다음 작업·종료", "", "1. 본 측정 JSON·대표 PNG를 헤드가 검토하고 128/20/36/30 기준에 맞출 수정 우선순위를 정한다.", "2. 별도 UI 수정 작업에서 터치 설명 열기·관리 지도 이동·전투 확대/축소의 대체 입력을 설계한다.", "3. 다음 단계에서 Android 실기·20:9·가상 키보드와 해금 후 행동을 검증한다. 이번 측정 커밋으로 출시/배포하지 않는다.", "", "체크: 요청 화면 측정·JSON 검증·대표 캡처·핸드오프/CURRENT 갱신·명시 파일만 로컬 영어 커밋. 미달 수정은 요청 범위 밖이다.", "", "## 부록: 화면별 전체 측정 표", "", "각 상태의 원본은 `tmp/android_audit/<상태>.json`, 통합은 `audit.json`, 수치 요약은 `summary.json`이다. 표에서 `(비활성)`과 `(클립)`을 구분한다. `STOP 후보`는 입력을 막거나 hover 설명만 제공할 수 있어 확정 버튼 수와 분리했다. 글자 표는 요청 Label/RichTextLabel 전체와 Button/LineEdit 보충을 함께 표시한다."]
    index = lines.index("## 4. 변경 파일")
    map_summary = [f"Button/BaseButton만 따로 보면 **{len(buttons)}건 중 {totals['small_buttons']}건**이 크기 미달이며, 버튼끼리 20px 미만인 쌍은 **{button_gaps}건**이다. 위 입력 총계는 ScrollContainer·ScrollBar·Slider 등의 입력 영역도 포함한다.", "", "맵 3상태의 별도 요약은 다음과 같다. `바닥 외접 미달`은 방의 실제 nearest-cell 폴백 판정 미달과 같지 않다.", "", "| 상태·대상 | 수 | 외접 크기128 미달 | 유닛/방 우선순위·UI 차단 후 128 정사각형 미확보(8px 근사) |", "|---|---:|---:|---:|"]
    for screen in screens:
        if not screen["map_sample"]:
            continue
        for shape, caption in (("circle", "유닛 원형"), ("room_floor_bounds_with_nearest_cell_fallback", "방")):
            rows = [r for r in screen["world_targets"] if r["shape"] == shape]
            map_summary.append(f"| `{screen['id']}` · {caption} | {len(rows)} | {sum(r['below_target'] for r in rows)} | {sum(r['reachable_square_px'] < 128 for r in rows)} |")
    lines[index:index] = map_summary + [""]
    index = lines.index("## 6. 실행·검증과 측정 방식")
    lines[index:index] = ["대표12장 모두 직접 열어 대상 화면을 확인했다. 최종 측정은 추가 촬영 없이 기존 대표 PNG를 재사용했다(`capture_reused: true`). 최초 캡처 시점의 정확한 JSON·로그는 `tmp/android_audit/capture_run/`, 최신 보완 JSON은 최상위에 있다. 전투 동적 프레임은 대표 캡처와 최신 측정 사이에 소폭 다를 수 있다. 생성 누적12/20, 재촬영0.", ""]
    index = lines.index("- Review task ID: NOT_REQUESTED")
    lines[index:index] = [f"- 마지막 도구 커밋 SHA: `{reviewed_sha}`. 이후에는 이 보고서와 CURRENT만 문서 커밋한다.", "- 최종 stderr 0bytes. 초기 콘솔 오류/의회 전환/인자 오류를 포함한 이전 로그는 삭제하지 않았다.", ""]
    for s in screens:
        lines += ["", f"### {s['id']} · {s['screen']} · DAY{s['day']}", "", f"상태 근거: {cell(s['provenance'])}. 캡처: `{s['capture'] or '추가 캡처 없음(20장 상한 내 대표만 보관)'}`.", "", "| 입력 요소·종류 | 현재 보이는 크기 px | 원래 크기 px | 128×128 미달 | 최근접 간격 px / 상대 |", "|---|---:|---:|---|---|"]
        for r in s["controls"]:
            state = (" (비활성)" if r["disabled"] else "") + (" (클립)" if r["clipped"] else "")
            lines.append(f"| `{cell(r['name'])}` · {r['kind']}{state} | {dimensions(r['visible_rect_px'])} | {dimensions(r['rect_px'])} | {'미달' if r['below_target'] else '충족'} | {fmt(r['nearest_gap_px'])} / `{cell(r['nearest_neighbor'].split('/')[-1])}` |")
        if s["passive_stop_candidates"]:
            lines += ["", "| STOP 후보(클릭 확정 아님) | 보이는 크기 px | 128 미달 |", "|---|---:|---|"]
            for r in s["passive_stop_candidates"]:
                lines.append(f"| `{cell(r['name'])}` · {r['type']} | {dimensions(r['visible_rect_px'])} | {'미달' if r['below_target'] else '충족'} |")
        lines += ["", "| 글자 요소·내용 | 종류 | 최종 font_size px | 최소30 / 본문36 |", "|---|---|---:|---|"]
        for r in s["labels"]:
            lines.append(f"| `{cell(r['name'])}` {short(r['text'])} | {r['type']}{'' if r['label_required'] else '(보충)'} | {' / '.join(map(fmt,r['font_px']))} | {'미달' if r['below_minimum_30'] else '충족'} / {'미달' if r['below_body_36'] else '충족'} |")
        if s["gap_pairs_below_20"]:
            lines += ["", "| 20px 미만 인접 요소 쌍 | 간격 px | 겹침 |", "|---|---:|---|"]
            for p in s["gap_pairs_below_20"]:
                lines.append(f"| `{cell(p['a'].split('/')[-1])}` ↔ `{cell(p['b'].split('/')[-1])}` | {fmt(p['gap_px'])} | {'예' if p['overlap'] else '아니오'} |")
        if s["world_targets"]:
            lines += ["", "| 맵 대상 | 형상 / 반경 px | 보이는 외접 크기 px | 128 미달 | 원 간격 px | 실제 picker 최대 정사각형 근사 px |", "|---|---|---:|---|---:|---:|"]
            for r in s["world_targets"]:
                lines.append(f"| `{r['id']}` | {r['shape']} / {fmt(r.get('radius_px'))} | {dimensions(r['visible_rect_px'])} | {'미달' if r['below_target'] else '충족'} | {fmt(r.get('nearest_gap_px'))} | {fmt(r.get('reachable_square_px'))} |")
        if s["tooltips"]:
            lines += ["", "| hover 설명 요소 | 위치·크기 [x,y,w,h] px | 전체 tooltip_text |", "|---|---|---|"]
            for r in s["tooltips"]:
                lines.append(f"| `{cell(r['name'])}` | {', '.join(map(fmt,r['visible_rect_px']))} | {cell(r['tooltip'])} |")
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(totals, ensure_ascii=False))
    print(f"AndroidTouchAuditReport PASS: {len(EXPECTED)} states; {REPORT.relative_to(ROOT)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reviewed-sha", default=BASE)
    args = parser.parse_args()
    assert len(args.reviewed_sha) == 40 and all(c in "0123456789abcdef" for c in args.reviewed_sha)
    data = json.loads((EVIDENCE / "audit.json").read_text(encoding="utf-8"))
    validate(data)
    generate(data, args.reviewed_sha)
