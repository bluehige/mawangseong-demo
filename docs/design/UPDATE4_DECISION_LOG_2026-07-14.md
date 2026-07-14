# v0.4 결정 로그

원문 계획의 U4-D001~U4-D020을 유지한다. 아래는 현재 저장소와 계획 예시의 차이를 해소하기 위한 추가 결정이다.

| ID | 결정 | 이유 | 영향 검사 |
|---|---|---|---|
| U4-D021 | 신규 카탈로그 경로는 `data/regular_version/update4/` | 기존 Update 3 버전 분리 관례 유지 | Update4 데이터 계약 |
| U4-D022 | 경쟁 마왕 ID와 관계 키를 `rival_brassa`, `rival_vesper`, `rival_mirella`로 통일 | 별도 변환표와 저장 오염 방지 | 관계·저장 v5 |
| U4-D023 | 신규 몬스터 instance ID는 소문자, 푸딩 구조 진화는 `slime_rescue_alchemy_gel` 사용 | 실제 카탈로그와 계획 예시 불일치 해소 | 왕관 branch inheritance |
| U4-D024 | v5를 실제 이어하기의 권위 있는 저장 envelope로 사용 | 기존 v1 primary + v2~v4 sidecar 누적 해소 | v4→v5·복구·GameRoot 이어하기 |
| U4-D025 | 의회 Stage 03만 출전 5명, 전선 회차 Stage 03은 4명 유지 | v0.3 밸런스 회귀 방지 | 모드별 로스터 한도 |
| U4-D026 | Phase 0에서 54회 반복 관측을 실행하지 않음 | 사용자 지시의 과도한 관측 금지 우선 | Phase별 직접 테스트·Phase 36 버그 회귀 |
| U4-D027 | 핵심 16종과 확장 10종을 독립 loader로 먼저 등록 | 후속 캐릭터·전투·자산도 Update 4 root에서 분리하고 Phase 1 런타임 연결 금지 준수 | Update4 데이터 계약 |
| U4-D028 | v5 권위 저장은 `user://campaign_save_v5.json`, 기존 v1~v4 파일은 마이그레이션 원본으로 보존 | 구버전 복구 가능성과 저장 이력 보존 | v4→v5·GameRoot 이어하기 |
| U4-D029 | 전선 연대기 다음 회차는 기존 DAY 4 준비 흐름, 의회 회차는 DAY 1 시작 | v0.3 새 회차 회귀 방지와 신규 30일 의회 상태기계 분리 | 캠페인 모드 선택 |
| U4-D030 | 의회 관리 전용 일정은 DAY 4·29, 나머지 28일은 Phase 4 빈 웨이브 계약 | 실제 지역·적 구현 전에도 DAY 31 차단과 저장 경계를 검증 | 의회 DAY 상태기계 |
