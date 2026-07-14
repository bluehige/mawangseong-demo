# Update 4 data root

`v0.4` 전용 카탈로그를 기존 런타임 데이터와 분리해 보관한다.

- Phase 1에서는 모든 JSON이 빈 `{}` fixture다.
- `Update4CatalogLoader`와 `ValidateUpdate4Content`만 이 경로를 읽는다.
- `DataRegistry`, 저장 버전과 실제 화면에는 Phase 1에서 연결하지 않는다.
- 각 후속 Phase가 소유한 카탈로그만 채우고 해당 Phase 테스트를 통과시킨다.
- 최종 수량 계약은 `ValidateUpdate4Content.FINAL_REQUIRED_COUNTS`가 관리한다.

카탈로그는 캠페인·의회·지역·경쟁 마왕·전초기지·상층·왕관·엔딩의 핵심 16종과, 캐릭터·전투·사건·자산을 버전별로 분리하기 위한 확장 10종으로 구성한다.
