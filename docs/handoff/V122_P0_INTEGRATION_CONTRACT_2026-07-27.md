# v1.2.2 P0 통합 기준 고정

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 표시 1.2 / 기술 버전 1.2.2
- 작업 브랜치: `codex/v122-integration-contract`
- 기준 브랜치 및 SHA: `release/v1.2.2@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: 커밋 전 문서 기준
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 교정된 v1.2.2 선별 통합 계획을 저장소 계약으로 고정한다.
- 완료 조건: 기준 SHA 세 개, 금지 이식 경로, P1 대응표 6종, 브랜치·버전 정책과 다음 진입점을 문서에 고정하고 정책 검사를 통과한다.
- 범위에서 제외한 사항: runtime, data, scene, asset 변경과 전체 회귀·전체 플레이·정식 export·공개 배포.

## 3. 완료한 작업

- 구현: 없음. P0는 문서 전용이다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX: 변경 없음.
- 저장 및 호환성: 변경 없음.
- 기준점:
  - 제품 원본: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`, `v1.2.1@c483d135b13cf9771ee43b045ba2c3dde51573ee`
  - 전투·밸런스 참고: `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`
  - UI 참고: `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`
- 대체된 지시: 기존 `release/v2.0-product` 또는 `v2.0.0` 제품 이식 지시. 기존 `release/v2.0`은 코드 공급선이 아니라 읽기 전용 검증 참고선이다.
- P1 고정 산출물:
  - `docs/design/v122/V122_SOURCE_OF_TRUTH_MATRIX.md`
  - `docs/design/v122/V122_COMBAT_TRANSPLANT_MATRIX.md`
  - `docs/design/v122/V122_UI_TRANSPLANT_MATRIX.md`
  - `docs/design/v122/V122_BUILDING_COMPATIBILITY_MATRIX.md`
  - `docs/design/v122/V122_BALANCE_RECALCULATION_MATRIX.md`
  - `docs/design/v122/V122_SAVE_COMPATIBILITY_MATRIX.md`

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `AGENTS.md` | v1.2.2 활성 작업선과 v20 참고선 경계 | 완료 |
| `docs/PRODUCT_VERSIONING.md` | 1.2.2 SemVer·브랜치 매핑 | 완료 |
| `docs/GIT_VERSIONING_WORKFLOW.md` | 선별 통합 금지·허용 Git 경로 | 완료 |
| `docs/design/v122/V122_V20_VALIDATED_TRANSPLANT_PLAN.md` | 교정 계획서 전문 보존 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점과 P1 작업 | 완료 |
| `docs/handoff/V122_P0_INTEGRATION_CONTRACT_2026-07-27.md` | P0 세션 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: P0 범위 아님

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `git diff --check` | 실행 후 기록 | 로컬 출력 |
| 2 | repository policy | 실행 후 기록 | 로컬 출력 |
| 3 | runtime/data/scene/asset 변경 여부 검사 | 실행 후 기록 | `git diff --name-only` |
| 4 | 전체 회귀 테스트 | NOT_REQUESTED | P0에서 실행 금지 |
| 5 | 시각/실플레이 검수 | NOT_REQUESTED | P0에서 실행 금지 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: P0 문서 커밋 SHA
- Review range: `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..P0 문서 커밋 SHA`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: P0는 런타임을 변경하지 않았다.
- 밸런스 관찰 항목: P1 이후 전투 기준 대응표와 fixture에서 확정한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 이 worktree의 LFS 오디오는 P0 문서 작업 중 네트워크 필터 정지를 피하기 위해 포인터 상태다. 런타임 검증 전 정상 LFS 객체를 복원해야 한다.

## 8. 다음 작업 순서

1. P1에서 세 기준점의 실제 코드·데이터·UI 책임을 감사하여 대응표 6종을 완성한다.
2. 모든 행의 처리 방식을 `KEEP_121`, `PORT_RULE`, `ADAPT_TO_121`, `RECALCULATE`, `DO_NOT_PORT`, `REMOVE_TEST_ONLY` 중 하나로 고정하고 `UNKNOWN`을 0으로 만든다.
3. P2부터 기존 건물 오브젝트·렌더 연결을 감사하고 관련 테스트만 실행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 커밋 전 문서 변경만 존재
- 미커밋 파일: 위 변경 파일
- 의도하지 않은 기존 변경: 없음. 기준 SHA에서 새 worktree를 만들었다.
- 스태시 또는 별도 작업공간: `마왕성_v122` 격리 worktree
- 빌드/캡처 산출물 위치: 없음

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] runtime/data/scene/asset 변경 0 확인 예정
- [x] 전체 회귀·전체 플레이 미실행
- [x] 그래픽·오디오 자산 변경 없음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] `git diff --check`와 repository policy 통과
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR 상태 기록
