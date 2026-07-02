이 파일이 왜 필요한지: 정규버전 목표 첨부문서를 바탕으로 확장 가능한 프로젝트 폴더 구조를 만든 작업 내용을 백업한다.

# 정규버전 폴더 구조 작업 로그

작성일: 2026-07-02

## 요청

첨부된 정규버전 목표를 구현하기 위해 앞으로 확장, 수정, 추가가 쉽도록 폴더를 구성한다.

## 확인한 기준

- 정규버전 1.0은 30일, 5챕터, 4~6시간 규모의 소규모 정규판이다.
- 핵심 제작 방식은 웹GPT가 기획 문서를 만들고, Codex가 그 문서를 JSON과 Godot 코드로 흡수하는 구조다.
- 콘텐츠는 코드에 직접 넣지 않고 JSON/CSV 기반으로 관리한다.
- 먼저 해야 할 구현은 데모 안정화, 데이터 기반 구조 전환, CampaignManager, Day 1~3 캠페인 데이터화, 저장 구조 설계다.

## 변경 내용

- `docs/design/`를 추가해 웹GPT 기획 산출물 위치와 작성 형식을 고정했다.
- `docs/regular_version/`를 추가해 정규버전 목표 요약과 폴더 정책을 기록했다.
- `data/regular_version/` 아래에 캠페인, 이벤트, 몬스터, 적, 아이템, 방, 함정, 밸런스, 진행도, 로컬라이즈 데이터 위치를 만들었다.
- `scripts/data/`를 추가해 JSON/CSV 로더와 스키마 검증 코드 위치를 분리했다.
- `scripts/systems/` 아래에 campaign, events, economy, progression, save, tutorial, content 시스템 위치를 만들었다.
- `scenes/ui/`와 `scenes/dungeon_quarter/modules/` 하위 구조를 추가해 UI 씬과 쿼터뷰 모듈 씬 확장 위치를 만들었다.
- 정규버전 리소스 확장을 위해 portraits, items, ui/icons, audio, vfx, dungeon_quarter module variants/foreground/walk_debug 위치를 추가했다.
- `tools/content/`, `tools/tests/`를 추가해 데이터 검증 도구와 신규 테스트 위치를 분리했다.
- `web_Demo/.gdignore`를 추가해 Godot import가 웹 배포 산출물을 프로젝트 리소스로 다시 훑는 일을 막았다.
- `README.md`의 프로젝트 설명을 현재 목표인 2D 쿼터뷰 기준으로 수정하고 정규버전 확장 구조를 안내했다.

## 의도적으로 하지 않은 일

- 기존 데모 실행 경로와 오토로드는 변경하지 않았다.
- 기존 `scripts/core/DataRegistry.gd`, `scripts/game/*`, `scripts/combat/*` 파일은 이동하지 않았다.
- 기존 `data/*.json` 데모 파일도 아직 이동하지 않았다.
- 실제 CampaignManager, SaveManager, 데이터 로더 구현은 다음 기능 세션으로 남겼다.

## 다음 작업

1. `scripts/data`에 1차 데이터 로더와 공통 검증 유틸을 만든다.
2. 기존 Day 1~3 데모 웨이브를 `data/regular_version/campaign/campaign_days.json` 초안으로 변환한다.
3. `scripts/systems/campaign`에 CampaignManager 기본 구조를 만든다.
4. 저장 데이터 스키마를 `docs/regular_version`에 먼저 정리한 뒤 `scripts/systems/save`에 구현한다.

## 검증

이번 작업은 폴더와 문서 중심 변경이다. 런타임 파일을 이동하지 않았으므로 기존 데모 실행 경로는 유지된다.

검증 명령:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
```

결과:

- Godot import 종료 코드 0
- `QuarterModuleSmokeTest.tscn` 종료 코드 0, `QUARTER_MODULE_SMOKE_TEST: PASS`
- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`
