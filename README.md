# 마왕성 데모

Godot 4.5 기반 2D 쿼터뷰 마왕성 방어 데모입니다.

## 실행

Godot 4.5.2 이상에서 이 폴더의 `project.godot`를 열거나:

```powershell
godot --path .
```

## 자동 체크

필수 데모 루프가 끊기지 않는지 확인하려면:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

실제 렌더링 화면을 캡처해 UI 겹침을 확인하려면:

```powershell
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

## 현재 포함 범위

- 관리 화면, 몬스터 관리 화면, 전투 화면, 결과 화면
- 3일 웨이브 루프
- 몬스터 3종: 슬라임, 고블린, 임프
- 적 3종: 탐험가, 도둑, 수련생 용사
- RoomGraph 기반 방 이동
- 자동 전투, 전체/방 지침, 직접 조종, 기본 스킬
- gpt-image-2 생성 기반 캐릭터/방/타일/효과 리소스
- 관리/전투/HUD 컨트롤러 분리
- 단일 이미지 기반 SpriteFrames 애니메이션 구조

## 정규버전 확장 구조

정규버전 1.0 목표와 폴더 정책은 `docs/regular_version/`에 정리했습니다.

- 웹GPT 기획 산출물: `docs/design/`
- 정규버전 콘텐츠 데이터: `data/regular_version/`
- 데이터 로더: `scripts/data/`
- 캠페인/이벤트/저장 등 신규 시스템: `scripts/systems/`
- UI 씬 분리 후보: `scenes/ui/`
- 쿼터뷰 모듈 씬 후보: `scenes/dungeon_quarter/modules/`

현재 완료 상태는 `docs/DEMO_COMPLETION_STATUS.md`, 최신 작업 인수인계는 `docs/HANDOFF_CURRENT_STATE_2026-07-02.md`, 1차 기반 인수인계는 `docs/HANDOFF_DEMO_FOUNDATION.md`를 확인하세요.
