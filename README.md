# 마왕성 데모 1.2

Godot 4.5 기반 2D 쿼터뷰 마왕성 방어 데모입니다.

## 저장소 작업 규칙

- 에이전트 필수 규칙: [`AGENTS.md`](AGENTS.md)
- 제품 버전 체계: [`docs/PRODUCT_VERSIONING.md`](docs/PRODUCT_VERSIONING.md)
- 브랜치, 태그, 버전 및 빌드 운영: [`docs/GIT_VERSIONING_WORKFLOW.md`](docs/GIT_VERSIONING_WORKFLOW.md)
- 다음 세션 시작점: [`docs/handoff/CURRENT.md`](docs/handoff/CURRENT.md)
- 세션 인수인계 양식: [`docs/handoff/HANDOFF_TEMPLATE.md`](docs/handoff/HANDOFF_TEMPLATE.md)
- Steam 판매 준비 진입점: [`docs/release/STEAM_RELEASE_MASTER_PLAN.md`](docs/release/STEAM_RELEASE_MASTER_PLAN.md)
- Steamworks 가입·세무·계좌 등 소유자 작업: [`docs/release/OWNER_ACTIONS.md`](docs/release/OWNER_ACTIONS.md)

현재 제품 표시 버전은 `1.2`, 기술 SemVer는 `1.2.0`입니다. `main`은 최신 검수 완료 안정판, `v1.2.0`·`v2.0.0` 태그는 각 출시본의 영구 기준, `release/v1.2`·`release/v2.0`은 버전 통합 브랜치로 사용합니다. 실행 가능한 플레이테스트 Web export는 `test/web-*`에 푸시하고, 정식 Web/Windows 빌드는 버전 태그의 GitHub Release에 보관합니다.

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

- DAY 1~3 온보딩과 DAY 4~30 정규 캠페인
- 용사의 서약·성광 정화·길드 회수 3개 전선과 전선별 DAY 30 결전
- 석골·포식·몽등 심장, 합동기 6종, 연대기와 엔딩 E00~E16
- 베베·코코·톡톡 동료와 셀렌·로만 보스, 3차 업데이트 적 편성
- 관리, 몬스터, 원정, 전투, 결산, 엔딩, 후일담 화면
- 4단계 마왕성 진화와 단계별 구역·시설·왕좌 강화
- 몬스터 성장·승급·특화와 최종장 분기 원정
- 실제 자동 저장, 제목 화면 이어하기, 손상 저장 감지
- RoomGraph/쿼터 모듈 기반 방 이동과 사용자 맵 편집
- 지시 기반 자동 전투, 전체/방 지시, 정보 전용 유닛 선택, x1~x3 속도와 캐릭터별 자동 스킬 모션
- gpt-image-2 생성 기반 캐릭터/방/타일/효과 리소스
- 관리/전투/HUD 컨트롤러 분리
- 독립 프레임 기반 SpriteFrames 애니메이션 구조

## 정규버전 확장 구조

정규버전 1.0 목표와 폴더 정책은 `docs/regular_version/`에 정리했습니다.

- 웹GPT 기획 산출물: `docs/design/`
- 정규버전 콘텐츠 데이터: `data/regular_version/`
- 데이터 로더: `scripts/data/`
- 캠페인/이벤트/저장 등 신규 시스템: `scripts/systems/`
- UI 씬 분리 후보: `scenes/ui/`
- 쿼터뷰 모듈 씬 후보: `scenes/dungeon_quarter/modules/`

현재 완료 상태는 `docs/DEMO_COMPLETION_STATUS.md`, 저장소 전체 최신 인수인계는 `docs/handoff/CURRENT.md`, 구 `v0.3` 기획 묶음의 구현 상세는 `docs/handoff/UPDATE3_IMPLEMENTATION_HANDOFF_2026-07-13.md`, 과거 구현 기록은 기존 `docs/HANDOFF_*.md` 문서를 확인하세요.
