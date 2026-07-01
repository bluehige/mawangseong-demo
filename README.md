# 마왕성 데모

Godot 4.5 기반 탑뷰 마왕성 방어 데모입니다.

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

## 현재 포함 범위

- 관리 화면, 몬스터 관리 화면, 전투 화면, 결과 화면
- 3일 웨이브 루프
- 몬스터 3종: 슬라임, 고블린, 임프
- 적 3종: 탐험가, 도둑, 수련생 용사
- RoomGraph 기반 방 이동
- 자동 전투, 전체/방 지침, 직접 조종, 기본 스킬
- gpt-image-2 생성 기반 캐릭터/방/타일/효과 리소스

현재 완료 상태는 `docs/DEMO_COMPLETION_STATUS.md`, 작업 인수인계 상세는 `docs/HANDOFF_DEMO_FOUNDATION.md`를 확인하세요.
