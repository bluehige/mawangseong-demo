# v1.2.3 검증 카탈로그 provenance 수정·독립 검수 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: `1.2.3`
- 작업 브랜치: `codex/v123-catalog-eol`
- 기준 브랜치 및 SHA: `main` / `42d763b2ed35a541e163b05426ebdbcc0221913a`
- 검수 대상 최종 SHA: `2929e9cf284bb4b7be0657546efa5ef298af1080`
- 원격 푸시 여부: 작성 시점 미푸시
- 관련 PR 또는 태그: 작성 시점 없음. 기존 `v1.2.2` 태그와 Release는 불변 감사 기록으로 유지한다.

## 2. 이번 세션 목표

- 요청 사항: 최종 검수를 진행하고 정식판 빌드·배포까지 완료한다.
- 완료 조건: 운영체제 줄바꿈과 무관하게 Full 보고서와 태그의 검증 카탈로그 해시가 일치하고, 독립 검수·최종 `main` Full·Web/Windows 패키지·태그·Release·Pages 공개 부팅이 모두 통과한다.
- 범위에서 제외한 사항: 게임 기능·밸런스·그래픽·오디오 변경, 기존 `v1.2.2` 태그 또는 Release 자산 교체, Steamworks 외부 가입·법무·스토어 심사.

## 3. 완료한 작업

- `.gitattributes`에서 검증 카탈로그를 `LF`로 고정했다.
- Full 보고서의 카탈로그 SHA-256을 체크아웃 파일이 아니라 `HEAD` Git blob의 원시 바이트로 계산하도록 수정했다.
- 빠른 provenance 전용 검사와 Ubuntu 저장소 정책 CI 단계를 추가했다.
- 프로젝트·export preset·출시 준비 계약·문서·릴리스 노트를 기술 버전 `1.2.3`으로 정렬했다.
- 독립 검수 1회차에서 발견된 Steam 명령 예시 `1.2.2` 잔존 P3 1건을 `1.2.3`으로 수정하고 같은 에이전트의 재검수를 통과했다.
- 게임 코드·데이터·씬·밸런스·그래픽·오디오는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.gitattributes` | 검증 카탈로그의 체크아웃 줄바꿈을 LF로 고정 | 완료 |
| `tools/tests/RunCoreVerification.ps1` | Git blob 원시 바이트 해시 및 provenance 전용 검사 | 완료 |
| `.github/workflows/repository-policy.yml` | Ubuntu CI에서 provenance 회귀 조기 차단 | 완료 |
| `tools/tests/core_verification_suite.json` | v1.2.3 출시 준비 항목·canonical catalog | 완료 |
| `project.godot`, `export_presets.cfg` | 기술 버전·내보내기 경로를 1.2.3으로 정렬 | 완료 |
| `tools/tests/V122ReleaseReadinessTest.gd`, `docs/audit/v122/V122_RELEASE_READINESS.json` | 1.2.3 출시 산출물 계약 | 완료 |
| `AGENTS.md`, `README.md`, `docs/PRODUCT_VERSIONING.md`, `docs/GIT_VERSIONING_WORKFLOW.md` | 공개 안정판·Git 절차 기록 | 완료 |
| `docs/release/V1_2_3_RELEASE_NOTES_2026-08-06.md` | v1.2.3 수정판 릴리스 노트 | 완료 |
| `steam/README.md` | Steam 빌드·업로드 명령 예시를 1.2.3으로 정렬 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: N/A
- 생성 원본 경로: 변경 없음
- `SOURCE.md` 경로: 변경 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: 제품 자산 변경 없음. 최종 `main` Web/Windows 빌드에서 대표 부팅을 별도로 확인한다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `RunCoreVerification.ps1 -CatalogProvenanceOnly` | PASS, `f286c025739274504e81c7ee9b8a0134b514d0f96cb2a2eb4d6456d8ae0c70a9` | 콘솔 출력 |
| 2 | `python -m unittest tools.ci.test_validate_build_manifest` | PASS, 13/13 | 콘솔 출력 |
| 3 | `tools/ci/TestRepositoryPolicy.ps1` | PASS, 12/12 | 콘솔 출력 |
| 4 | Godot `V122ReleaseReadinessTest.tscn` | PASS, 84/84, target `1.2.3` | 콘솔 출력 |
| 5 | `tools/release/validate_steam_release.py` | SETUP_PASS, 예정된 외부 항목 17개 | 콘솔 출력 |
| 6 | 별도 읽기 전용 검수 에이전트 | 재검수 PASS, P1/P2/P3 모두 0 | 아래 반복 기록 |
| 7 | 최종 `main` SHA Full 156개 | 통합 뒤 실행 예정 | `tmp/core_verification/latest.json` |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `019fd3c1-c2cf-7431-8962-632b6bacf410` | `42d763b2ed35a541e163b05426ebdbcc0221913a..5ea473edb64f8c022241c2f16e0a17ff1010c282` | `5ea473edb64f8c022241c2f16e0a17ff1010c282` | Steam 안내의 1.2.2 잔존 P3 1건 | `steam/README.md` 세 곳을 1.2.3으로 정렬 | `steam/README.md` | FAIL |
| 2 | `019fd3c1-c2cf-7431-8962-632b6bacf410` | `42d763b2ed35a541e163b05426ebdbcc0221913a..2929e9cf284bb4b7be0657546efa5ef298af1080` | `2929e9cf284bb4b7be0657546efa5ef298af1080` | 없음 | 재검수 | 에이전트 최종 보고 | PASS |

- 남은 P1/P2 지적: 0건
- 남은 P3 지적: 0건
- 실행하지 못한 필수 검수와 이유: 최종 `main` SHA Full 156개·정식 export·공개 Pages 부팅은 merge commit 확정 뒤에만 유효하므로 통합 뒤 실행한다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이 SHA 이후에는 `docs/handoff/`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: 019fd3c1-c2cf-7431-8962-632b6bacf410
- Reviewed SHA: 2929e9cf284bb4b7be0657546efa5ef298af1080
- Review range: 42d763b2ed35a541e163b05426ebdbcc0221913a..2929e9cf284bb4b7be0657546efa5ef298af1080
- Remaining P1/P2: 0
- Final review result: PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 독립 검수 범위에서는 없음. 최종 `main` SHA의 Full·패키지·공개 배포 검증이 남아 있다.
- 밸런스 관찰 항목: 변경 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: Steam App/Depot ID·법무·스토어 심사 등 17개 소유자 항목은 Steam 판매 출시 때 별도 완료해야 한다. Windows 코드 서명 인증서는 아직 적용하지 않는다.

## 8. 다음 작업 순서

1. 이 브랜치를 `release/v1.2.3`에 merge commit PR로 통합하고 필수 CI를 통과한다.
2. `release/v1.2.3`을 `main`에 merge commit PR로 통합해 최종 제품 SHA를 확정한다.
3. 최종 `main` SHA에서 Full 156개를 실행하고 Web/Windows 1.2.3 패키지·manifest·압축 해제 해시·대표 부팅을 검증한다.
4. 불변 태그 `v1.2.3`과 GitHub Release를 게시하고 Pages workflow 및 공개 1280×720 부팅을 확인한다.
5. 실제 Release URL·workflow run·패키지 SHA-256을 출시 완료 핸드오프에 기록한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 검수 SHA에서는 clean, 이 문서와 `CURRENT.md`만 검수 후 추가한다.
- 미커밋 파일: 작성 시점 `docs/handoff/` 2개
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치: 최종 통합 뒤 `tmp/v123_release_final/<main-short-sha>/`에 생성 예정

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 독립 검수와 재검수 완료
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽·오디오 변경 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 원격 푸시 및 PR 통합
- [ ] 최종 `main` SHA Full·정식 패키지 검증
- [ ] `v1.2.3` 태그·GitHub Release·Pages 공개 부팅
