이 파일이 왜 필요한지: 데이터 로더 계층을 기존 게임 로직과 분리해 콘텐츠 추가 시 코드 수정 범위를 줄인다.

# Data Loaders

이 폴더는 JSON/CSV 로더와 스키마 검증 코드를 둔다.

예정 파일:

- `CampaignDataLoader.gd`
- `MonsterDataLoader.gd`
- `EnemyDataLoader.gd`
- `ItemDataLoader.gd`
- `EventDataLoader.gd`
- `RoomDataLoader.gd`
- `BalanceDataLoader.gd`

로더는 파일 읽기, 필수 필드 검증, id 중복 검사까지만 맡는다. 전투 계산, 보상 계산, UI 표시는 각 시스템 코드에서 처리한다.
