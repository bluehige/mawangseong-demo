# v1.2.2 P15 Update 2~4 콘텐츠 호환성 전수 검증

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-content-compatibility`
- 기준 브랜치 및 SHA: `codex/v122-balance-day26-30@1f433ff3c21828c7db98201e794be311e1dfb06e`
- 기능 커밋 SHA: `a56ff9b33b5700b486d792a971694edb5354f559`
- 원격 푸시: 미실행

## 2. 완료한 작업

- Update 2의 8개, Update 3의 13개, Update 4의 31개 카탈로그를 기계 판독 가능한 호환성 기준으로 고정했다.
- 각 카탈로그를 제품 `DataRegistry`로 병합한 뒤 필수 데이터와 런타임 소비자를 전수 확인하는 자동 테스트를 추가했다.
- Update 4 Phase 5~36 테스트가 존재하지만 핵심 검증 스위트에 빠져 있던 공백을 발견해 32개 검사를 Quick과 Full에 등록했다.
- Update 2~4의 필수 검사 85개가 올바른 모드와 실제 테스트 장면에 연결되는지 검증한다.
- E00~E22의 23개 코드 연속성, 중복·누락, 엔딩 검사 연결과 삽화 리소스 존재를 검증한다.
- 사람이 읽는 감사표와 기계 판독 JSON을 함께 추가했다.

## 3. 테스트

| 방법 | 결과 |
|---|---|
| `V122ContentCompatibilityTest` | PASS, 479 assertions |
| Update 2~4 검사 등록 coverage | PASS, 85/85 (100.0%) |
| E00~E22 연속성·삽화 존재 | PASS, 23/23 |
| Update 4 Phase 5~36 신규 suite 등록 | PASS, 32/32 |
| `RunCoreVerification.ps1 -Mode Quick` | PASS, 114/114 |
| JSON parse·`git diff --check` | PASS |
| Full·DAY 1~30 전체 플레이 | NOT_RUN, 최종검수 전 정책에 따라 제외 |

최초 전체 리임포트 중 Godot 4.5.2가 Windows 접근 위반으로 한 번 종료됐지만, 기능 검사 113개는 모두 통과했다. 캐시 완성 뒤 프로젝트 임포트를 단독으로 통과하고 동일 Quick 전체를 다시 실행해 114/114 PASS를 확정했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: a56ff9b33b5700b486d792a971694edb5354f559
- Review range: 1f433ff3c21828c7db98201e794be311e1dfb06e..a56ff9b33b5700b486d792a971694edb5354f559
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 4. 다음 작업

1. P16에서 P0~P15 구현 항목을 closure matrix로 모으고 미구현·우회·테스트 전용·미연결 상태가 0인지 자동 검증한다.
2. P17에서 버전·export·플랫폼 설정을 정적 점검하고 사용자 최종검수용 RC 준비 상태를 문서화한다.
