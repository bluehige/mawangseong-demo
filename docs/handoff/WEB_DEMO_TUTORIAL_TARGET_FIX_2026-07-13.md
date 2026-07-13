# Web 튜토리얼 지침 포커스 배포 수정

## 1. 메타데이터

- 작성일: 2026-07-13
- 목표 버전: v0.3 Web 데모
- 작업 브랜치: `test/web-v0.3`
- 기준 브랜치 및 SHA: `origin/test/web-v0.3` / `02f5cbd2ce889fb435ff552158bbfcf686d634b0`
- 마지막 구현 커밋 SHA: `b4cf3f681fac0bd6b3b2bba542ed87f1ae978bf0`
- 원격 푸시 여부: 핸드오프 커밋 후 진행
- 관련 배포: `update3-web-20260713` Release 자산 및 GitHub Pages

## 2. 이번 세션 목표

- 요청 사항: 공개 Web 데모에서 `함정 유도` 튜토리얼 포커스가 실제 드롭다운이 아닌 과거 고정 좌표를 가리키는 현상을 수정하고 다시 배포한다.
- 완료 조건: 수정 소스에서 생성된 PCK를 식별 가능한 Web ZIP으로 재게시하고 공개 Pages 주소에서 새 빌드가 로드된다.
- 범위에서 제외한 사항: 전체 게임 회귀 및 전체 플레이 검수.

## 3. 완료한 작업

- 공개 Pages가 최신 Web 브랜치가 아니라 이전 Release ZIP의 206,275,120바이트 PCK를 제공하고 있음을 확인했다.
- `test/web-v0.3`을 최신 `main`과 merge commit으로 동기화했다.
- Web 브랜치의 수정 PCK가 181,257,848바이트이며 SHA-256 `2b6d72f9e9f4606b0b92e571c32ba35e49c85c71420ea3b29dd959d672478731`임을 확인했다.
- 배포본 식별을 위해 `web_Demo/build-version.txt`를 추가했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `web_Demo/build-version.txt` | 공개 배포본의 소스·PCK 식별 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |
| `docs/handoff/WEB_DEMO_TUTORIAL_TARGET_FIX_2026-07-13.md` | 수정 및 배포 근거 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 게임 연결 및 실제 렌더 확인 결과: 기존 수정 소스에서 튜토리얼 링이 실제 지침 컨트롤을 감싸고 안내 배지가 컨트롤과 겹치지 않음을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `TutorialFlowSmokeTest` | PASS | 대화 세션 실행 로그 |
| 2 | `OnboardingFlowSmokeTest` | PASS | 대화 세션 실행 로그 |
| 3 | 실제 렌더 캡처 및 브라우저 부팅 | PASS | `tmp/tutorial_ux_verification`, 로컬 Web 실행 |
| 4 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

- Review task ID: NOT_REQUESTED
- Reviewed SHA: b4cf3f681fac0bd6b3b2bba542ed87f1ae978bf0
- Review range: 02f5cbd2ce889fb435ff552158bbfcf686d634b0..b4cf3f681fac0bd6b3b2bba542ed87f1ae978bf0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 새 작업 트리의 전체 자산 초기 임포트가 제한 시간을 넘겨 중단됐다. 검증된 기존 Web PCK를 사용하므로 배포 파일 자체에는 영향이 없다.
- GitHub Pages와 브라우저 캐시는 최대 약 10분간 이전 파일을 보일 수 있다.

## 8. 다음 작업 순서

1. Release ZIP 자산을 수정 빌드로 교체한다.
2. 배포 워크플로 체크섬을 새 ZIP과 일치시킨다.
3. Pages 재배포 후 공개 주소의 `build-version.txt`와 PCK 크기를 확인한다.

## 9. 작업 트리 상태

- 미커밋 파일: 이 핸드오프 문서와 `CURRENT.md`만 남긴 뒤 문서 커밋 예정
- 의도하지 않은 기존 변경: 없음
- 빌드/캡처 산출물 위치: `web_Demo/`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행
- [x] 검수 대상 최종 SHA 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 원격 푸시 및 공개 Pages 재배포
