이 파일이 왜 필요한지: 정규버전 1.0으로 확장할 때 파일이 흩어지지 않도록, 폴더별 책임과 추가 규칙을 정한다.

# 정규버전 폴더 구조

작성일: 2026-07-02

## 변경 원칙

현재 데모는 실행 가능한 상태이므로 기존 `scripts/core`, `scripts/game`, `scripts/combat`, `scripts/dungeon_quarter` 경로를 당장 옮기지 않는다.

이번 구조 변경은 다음 작업부터 들어갈 안정적인 자리 만들기다. 실제 코드 이동은 기능 단위 테스트를 붙인 뒤 작게 진행한다.

## 문서

```text
docs/design/
docs/regular_version/
```

- `docs/design/`: 웹GPT가 작성하는 기획 산출물 자리.
- `docs/regular_version/`: Codex가 구현 기준으로 참조하는 정규버전 목표, 폴더 정책, 단계 계획 자리.

`docs/design` 문서는 반드시 아래 형식으로 끝낸다.

1. 구현 대상
2. 데이터 구조
3. UI에 표시할 정보
4. Codex에 넘길 JSON 예시
5. 완료 조건
6. 확장판 후보
7. 결정 로그

## 데이터

```text
data/regular_version/campaign/
data/regular_version/events/
data/regular_version/monsters/
data/regular_version/enemies/
data/regular_version/items/
data/regular_version/rooms/
data/regular_version/traps/
data/regular_version/balance/
data/regular_version/progression/
data/regular_version/localization/
```

- 데모 호환용 기존 파일은 당분간 `data/monsters.json`, `data/enemies.json`, `data/rooms.json`, `data/skills.json`, `data/waves.json`에 둔다.
- 정규버전 신규 데이터는 `data/regular_version` 아래에 먼저 추가한다.
- 로더가 안정되면 기존 데모 데이터도 정규버전 구조로 단계적으로 이동한다.
- 밸런스 수치와 콘텐츠 정의는 분리한다. 예를 들어 몬스터 목록은 `monsters`, 난이도별 보정은 `balance`에 둔다.

## 코드

```text
scripts/data/
scripts/systems/campaign/
scripts/systems/events/
scripts/systems/economy/
scripts/systems/progression/
scripts/systems/save/
scripts/systems/tutorial/
scripts/systems/content/
```

- `scripts/data/`: JSON/CSV 로더와 스키마 검증 코드.
- `scripts/systems/campaign/`: 30일 진행, 챕터 전환, 하루 시작/종료.
- `scripts/systems/events/`: 메인/랜덤/몬스터/보스 이벤트 선택과 결과 적용.
- `scripts/systems/economy/`: 금화, 마력, 식량, 보상, 비용 계산.
- `scripts/systems/progression/`: 마왕성 등급, 악명, 마계 명성, 해금.
- `scripts/systems/save/`: 저장/불러오기, 버전 마이그레이션.
- `scripts/systems/tutorial/`: 초반 안내와 도움말 조건.
- `scripts/systems/content/`: 데이터 id 해석, 콘텐츠 카탈로그, 도감 후보.

새 시스템은 바로 오토로드로 올리지 않는다. 먼저 일반 Node/RefCounted 클래스로 만들고 테스트 씬에서 검증한 뒤 `GameRoot`에 연결한다.

## 씬

```text
scenes/ui/screens/
scenes/ui/components/
scenes/ui/popups/
scenes/dungeon_quarter/modules/
```

- `screens`: 관리, 전투, 도감, 이벤트, 결과처럼 화면 단위 씬.
- `components`: 자원 바, 카드, 리스트 행, 툴팁처럼 재사용 UI.
- `popups`: 확인창, 보상창, 선택지 창.
- `dungeon_quarter/modules`: 방/복도/교차로/장식 모듈 씬.

현재 데모 UI는 대부분 코드 생성 방식이므로, 씬 분리는 UI가 커지는 시점에 진행한다.

## 리소스

```text
assets/sprites/dungeon_quarter/modules/variants/
assets/sprites/dungeon_quarter/modules/foreground/
assets/sprites/dungeon_quarter/modules/walk_debug/
assets/sprites/portraits/
assets/sprites/items/
assets/sprites/ui/icons/
assets/audio/
assets/vfx/
```

- `variants`: 같은 모듈의 소켓 연결 조합별 이미지.
- `foreground`: 앞벽, 기둥처럼 유닛보다 위에 그릴 레이어.
- `walk_debug`: 보행 셀 검수용 임시 이미지.
- `portraits`: 이벤트/도감/보스 대화용 초상.
- `items`: 아이템 아이콘.
- `ui/icons`: UI용 소형 아이콘.

이미지 생성 원본과 프롬프트 출처는 각 리소스 폴더의 `SOURCE.md` 또는 작업 로그에 남긴다.

## 도구

```text
tools/content/
tools/tests/
```

- `tools/content`: 기획 JSON 검증, CSV 변환, id 중복 검사, 데이터 통계.
- `tools/tests`: 기능별 테스트 씬과 스모크 테스트 보조 코드.

기존 `tools/DemoSmokeTest.tscn`, `tools/QuarterModuleSmokeTest.tscn`은 당장 이동하지 않는다. 새 테스트부터 `tools/tests` 기준으로 정리한다.
