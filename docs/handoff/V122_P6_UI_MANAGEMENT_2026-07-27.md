# v1.2.2 P6 관리·배치 UI 결합

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-ui-management`
- 기준 브랜치 및 SHA: `codex/v122-day01-05-parity@61bea718696975bfd96ec4316316e2d7bf908fef`
- 기능 커밋 SHA: `e344ec124ea085e3fff296506febe0f41ee385ad`
- 원격 푸시: 미실행

## 2. 완료한 작업

- 제품 runtime에서 관리 중앙 지도·선택 room·주 행동·context action을 만드는 view model을 추가했다.
- 건설·몬스터·전투 시작·연대기를 보존하고 합동기·원정·전초기지·상층은 실제 해금 상태에 맞춰 노출한다.
- 연대기와 합동기 UI 버튼이 이 view model의 제품 callback·label·tooltip을 실제 소비하도록 연결했다.
- desktop 3종과 모바일 landscape에서 지도·목록·drawer·주 행동의 경계·비겹침을 고정했다.
- 모바일 portrait에는 회전 안내 계약을 유지한다.

## 3. 테스트

| 방법 | 결과 |
|---|---|
| P6 관리 UI action·layout 직접 테스트 | PASS |
| 제품 전체 `DemoSmokeTest` | PASS |
| callback 없는 action·중복 ID·개발자 문구 | 0 |
| 1920×1080·1366×768·1280×720·844×390 | PASS |
| 390×844 회전 안내 | PASS |
| Quick project import | ENGINE_FLAKY, Godot 4.5.2 Windows native importer 이슈를 P5에서 기록 |
| Full·전체 플레이 | NOT_RUN, RC 이전 정책에 따라 제외 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: e344ec124ea085e3fff296506febe0f41ee385ad
- Review range: 61bea718696975bfd96ec4316316e2d7bf908fef..e344ec124ea085e3fff296506febe0f41ee385ad
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 4. 다음 작업

1. P7 실제 목표·활성 구간·위협·명령 targeting·결과 원인을 전투 UI view model로 연결한다.
2. 기존 보스·심장·합동기·속도·일시정지 상태를 그대로 보존한다.
