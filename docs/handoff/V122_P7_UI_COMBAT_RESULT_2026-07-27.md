# v1.2.2 P7 전투 HUD·결과 UI 결합

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-ui-combat-result`
- 기준 브랜치 및 SHA: `codex/v122-ui-management@c32136e66b2a434b87ca1bdb13961155cc8378de`
- 기능 커밋 SHA: `04048611516193d420f24ef529a8b1c957d8d23e`
- 원격 푸시: 미실행

## 2. 완료한 작업

- 제품 `ModuleGraph`·wave·room/facility anchor에서 실제 목표, 활성 경로, 방어 구간과 예정 위협을 만드는 전투 view model을 추가했다.
- 위협이 존재할 때만 telegraph를 표시하고 도둑·공병·보스를 실제 제품 대상에 연결했다.
- 집결·집중·시설 발동·비상 후퇴 네 제한 명령을 CP·cooldown·room/enemy/facility targeting과 함께 desktop·touch HUD에 연결했다.
- 제한 명령이 기존 전체·방 지침을 보존하면서 이동 속도, 받는 피해, 집중 피해, 시설 증폭을 실제 전투에 적용하고 기여도를 ledger에 기록한다.
- 기존 보스 HP, 심장·합동기 상태, 속도·일시정지, 방 지침을 제거하지 않았다.
- 결과 화면이 왕좌 피해·돌파·보물 손실 ledger에서 핵심 원인을 표시하면서 성장·보상·스토리·메타 진행·엔딩·다음 DAY 흐름을 유지한다.

## 3. 테스트

| 방법 | 결과 |
|---|---|
| P7 전투·결과 UI view model·명령 target 직접 테스트 | PASS |
| 제품 전체 `DemoSmokeTest` | PASS |
| 네 제한 명령·실제 facility anchor·cooldown | PASS |
| telegraph 없음 숨김·도둑/공병/보스 표시 | PASS |
| 기존 성장·보상·스토리·엔딩·다음 DAY 보존 | PASS |
| 1920×1080·1366×768·1280×720·844×390 | PASS |
| 390×844 회전 안내 | PASS |
| 첫 실행 project import | ENGINE_FLAKY, Godot 4.5.2 Windows native importer 이슈를 P5에서 기록 |
| Full·전체 플레이 | NOT_RUN, RC 이전 정책에 따라 제외 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 04048611516193d420f24ef529a8b1c957d8d23e
- Review range: c32136e66b2a434b87ca1bdb13961155cc8378de..04048611516193d420f24ef529a8b1c957d8d23e
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 4. 다음 작업

1. P8에서 `CampaignSaveStore`의 기존 schema를 확장해 battle plan·배치·retry·명령 설정·최소 UI 상태를 저장한다.
2. v1.2.0/v1.2.1·DAY 1~30·엔딩·Update 4·corrupt/tmp/bak fixture를 손실 없이 통과시킨다.
