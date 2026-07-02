이 파일이 왜 필요한지: 2026-07-02 백업 버전 HTML 웹 빌드에서 한글 텍스트가 깨져 보인 문제의 원인, 수정 범위, 검증 결과를 남긴다.

# 작업 로그: Web HTML 한글 폰트 수정

## 요청

사용자가 기존 백업 버전을 HTML 웹 빌드로 열었을 때 텍스트가 깨진다고 보고했다.

## 원인

- 소스 문자열은 UTF-8 기준 정상 한글이었다.
- Godot Web export에서는 Windows 시스템 한글 폰트 fallback을 기대할 수 없어, 기본 fallback 폰트만 사용한 UI/캔버스 텍스트가 한글 glyph를 제대로 렌더링하지 못했다.

## 수정

- `assets/fonts/NotoSansCJKkr-Regular.otf` 추가.
- `assets/fonts/NotoSansCJKkr-Regular.otf.import` 추가.
- `assets/fonts/NotoSansCJK_LICENSE.txt` 추가.
- UI Control 텍스트:
  - `scripts/ui/HUDController.gd`의 Label/Button 생성 시 Noto Sans CJK KR 폰트 override 적용.
- 캔버스 직접 그리기 텍스트:
  - `scripts/map/DungeonRenderer.gd`의 방 라벨/몬스터 프리뷰 라벨에 같은 폰트 적용.
  - `scripts/game/GameRoot.gd`의 드래그 중 몬스터 이름 라벨에 같은 폰트 적용.
- 유닛 이름 라벨:
  - `scripts/units/Unit.gd`의 `name_label`에 같은 폰트 적용.

## 빌드

- 백업 기준 커밋: `1f7fc62 Adjust combat scale and zoom`
- 깨끗한 별도 worktree:
  - `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성_web_worktrees\mawang_1f7fc62_web_fontfix`
- 새 Web HTML 빌드:
  - `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성_web_builds\2026-07-02_1f7fc62_html_fontfix`
- ZIP:
  - `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성_web_builds\2026-07-02_1f7fc62_html_fontfix.zip`

## 검증

- `godot --headless --path . --import`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
  - 결과: `DEMO_SMOKE_TEST: PASS`
- Web export 성공.
- 새 빌드 서버:
  - `http://127.0.0.1:8097/index.html`
- HTTP 확인:
  - `index.html` 응답 `200 OK`
- Playwright Chrome 채널 스크린샷:
  - `output/playwright/web_fontfix.png`
  - 관리 화면의 상단 자원바, 방 목록, 방 라벨, 오른쪽 선택 방 패널, 하단 버튼의 한글이 정상 렌더링됨.

## 참고

- `project.godot`의 `gui/theme/custom_font`에 OTF 원본을 직접 지정하면 ThemeDB 초기화 시 loader 경고가 발생했다.
- 현재 데모 UI는 대부분 스크립트로 생성되므로, 실제 텍스트 생성 지점에서 명시적으로 폰트를 override하는 방식이 더 안정적이다.
