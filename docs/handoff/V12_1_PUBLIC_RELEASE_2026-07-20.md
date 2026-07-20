# 제품 1.2.1 공개 출시 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-20
- 목표 버전: 제품 표시 1.2 / 기술 SemVer 1.2.1
- 작업 브랜치: `hotfix/v1.2.1`
- 기준 브랜치 및 SHA: `origin/main` / `25a41a4f08925e35592aca890e0c56a75c5203f9`
- 마지막 기능·버전 커밋 SHA: `07586e51a7c66d6290602629a54b4cb6ce6b6d40`
- 원격 푸시 여부: 이 문서 작성 시점 미푸시
- 관련 이슈·PR: [이슈 #39](https://github.com/bluehige/mawangseong-demo/issues/39), 수정 PR [#40](https://github.com/bluehige/mawangseong-demo/pull/40) 병합 완료

## 2. 이번 세션 목표

- PR #40의 플레이 검수 수정분을 `main`에 merge commit으로 통합한다.
- 기존 불변 태그 `v1.2.0`을 유지하고 기술 수정판 `v1.2.1`을 별도 PR·태그·GitHub Release로 출시한다.
- 정확한 출시 태그에서 Windows 패키지, PC Web, 모바일 Web을 생성한다.
- Windows는 GitHub Release 자산으로 제공하고 PC·모바일 Web은 각각 공개 Pages 링크에서 바로 체험할 수 있게 한다.
- 사용자가 요청한 전체 검수와 실제 플레이 검수 결과를 합쳐 출시 차단 P1/P2가 없는지 확인한다.

## 3. 완료한 작업

- PR #40을 ready 상태로 전환하고 필수 `repository-policy` 통과 뒤 merge commit `25a41a4f08925e35592aca890e0c56a75c5203f9`로 `main`에 병합했다.
- `hotfix/v1.2.1`을 새 `main`에서 분기했다.
- `project.godot` 기술 버전을 `1.2.1`로 올렸고 화면 표시와 기존 사용자 저장 경로는 1.2로 유지했다.
- Windows 및 Steam export의 파일·제품 버전을 `1.2.1.0`으로 맞추고 Windows 출력 경로를 1.2.1 패키지명으로 변경했다.
- 버전 정책, README, Steam 예시와 `docs/release/V1_2_1_RELEASE_NOTES_2026-07-20.md`를 갱신했다.
- 기능·버전 SHA `07586e51a7c66d6290602629a54b4cb6ce6b6d40`의 깨끗한 분리 작업공간에서 전체 코어 검증 89/89를 통과했다.
- 이전 수정 Windows 빌드에서 이름 `마왕성` 입력, 대화 표시, 저장 JSON 반영, 종료·재실행, 이어하기 복원을 확인했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `AGENTS.md` | 현재 수정판 기술 SemVer와 불변 태그 정책에 1.2.1 반영 | 완료 |
| `project.godot` | 프로젝트 기술 버전 1.2.1 | 완료 |
| `export_presets.cfg` | Windows 출력명 및 파일·제품 버전 1.2.1.0 | 완료 |
| `README.md` | 최신 기술 SemVer 안내 | 완료 |
| `docs/PRODUCT_VERSIONING.md` | 1.2.1 안정화 수정판 계보 | 완료 |
| `steam/README.md` | 1.2.1 패키지 예시 | 완료 |
| `docs/release/V1_2_1_RELEASE_NOTES_2026-07-20.md` | 공개 변경점·링크·제한 | 완료 |
| `docs/handoff/V12_1_PUBLIC_RELEASE_2026-07-20.md` | 검수·출시 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

기능 수정 파일은 PR #40과 `docs/handoff/V12_USER_PLAYTEST_QA_2026-07-20.md`에 기록돼 있으며 이번 버전 브랜치에서는 다시 수정하지 않았다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델·원본·`SOURCE.md`: 해당 없음
- 런타임 자산 변경: 없음
- 게임 연결 및 실제 렌더 확인: PR #40 검수에서 튜토리얼 표식·대화 UI·전투 화면을 확인했고 이번 버전 커밋은 자산을 바꾸지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `python tools/release/validate_steam_release.py` | `SETUP_PASS`; 외부 Steam 소유자 작업 17건은 예상대로 미완료 | 콘솔 기록 |
| 2 | `tools/tests/RunCoreVerification.ps1 -Mode Full` 1차 | 기능 88개 PASS, 최초 프로젝트 임포트만 Godot 접근 위반으로 FAIL | `tmp/core_verification/runs/20260720_163039/` |
| 3 | 동일 SHA 프로젝트 임포트 재시도 | PASS, 1,248단계 완료 | `tmp/v121_project_import_retry.log` |
| 4 | 깨끗한 작업 트리에서 `tools/tests/RunCoreVerification.ps1 -Mode Full` 재실행 | PASS, 89/89, `source_tree_clean=true` | `tmp/core_verification/latest.md`, `tmp/core_verification/latest.json` |
| 5 | 이전 수정 Windows export Computer Use | PASS: `마왕성` 입력·대화·저장·재실행·이어하기 | 격리 프로필 `tmp/ime_appdata_20260720_001/` |

최종 전체 검증은 2026-07-20 16:46:51~17:00:13 KST에 실행됐고 802.75초가 걸렸다. 보고서의 커밋 SHA는 `07586e51a7c66d6290602629a54b4cb6ce6b6d40`, 전체 89개 중 PASS 89개·FAIL 0개다.

### 검수 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 | 주요 지적 | 수정·대응 | 근거 | 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `FULL_USER_PLAYTEST_2026-07-20_V12` | 이슈 #39 및 사용자 추가 지적 | `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54` | DAY 3 진행 불가, 튜토리얼·대화 UI, 자동전투 정체 | PR #40에서 수정 | `docs/handoff/V12_USER_PLAYTEST_QA_2026-07-20.md` | PASS |
| 2 | `FULL_RELEASE_VERIFICATION_2026-07-20_V121` | `25a41a4f08925e35592aca890e0c56a75c5203f9..07586e51a7c66d6290602629a54b4cb6ce6b6d40` | `07586e51a7c66d6290602629a54b4cb6ce6b6d40` | 최초 OTF 임포트 시 Godot 4.5.2 접근 위반 | 동일 blob 캐시 완성 뒤 깨끗한 작업 트리에서 전체 재실행 | `tmp/core_verification/latest.md` | 89/89 PASS |

- 남은 P1/P2 지적: 0건
- 실행하지 못한 필수 검수와 이유: Computer Use 드라이버가 물리 한/영 키 코드를 제공하지 않아 Microsoft 한국어 IME의 실제 한/영 전환 동작은 수동 실기 확인이 필요하다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 이 핸드오프와 `CURRENT.md`뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: FULL_RELEASE_VERIFICATION_2026-07-20_V121
- Reviewed SHA: 07586e51a7c66d6290602629a54b4cb6ce6b6d40
- Review range: 25a41a4f08925e35592aca890e0c56a75c5203f9..07586e51a7c66d6290602629a54b4cb6ce6b6d40
- Remaining P1/P2: 0
- Final review result: PASS

## 7. 미해결 항목과 위험

- Windows 코드 서명 인증서가 없어 공개 패키지는 서명되지 않는다. 릴리스 노트에 이를 명시한다.
- 물리 Microsoft 한국어 IME 한/영 키 전환은 수동 실기 확인 항목이다. 확정 한글 `마왕성`의 게임 입력·저장·재실행 복원은 확인했다.
- Godot 4.5.2가 최초 대량 임포트에서 `NEXON_Maplestory_Bold.otf` 처리 중 `c0000005`로 비결정적으로 종료됐다. 자산이나 출시 게임 충돌은 아니며 캐시를 완성한 뒤 동일 SHA의 프로젝트 임포트와 전체 89개 검증이 통과했다.
- 모바일 버전은 APK/AAB가 아니라 모바일 브라우저용 Web 빌드다.

## 8. 다음 작업 순서

1. `hotfix/v1.2.1`을 푸시하고 `main` 대상 PR을 열어 `repository-policy`를 통과시킨다.
2. merge commit 방식으로 병합한 정확한 `main` SHA에서 전체 89개 검증을 다시 통과시킨다.
3. 주석 태그 `v1.2.1`을 만들고 태그 SHA에서 Windows 패키지를 생성·실행 검증한 뒤 GitHub Release에 첨부한다.
4. 태그 SHA에서 PC Web과 모바일 Web을 각각 export해 전용 Pages 저장소의 PR로 병합·배포한다.
5. 공개 PC·모바일 URL을 실제 브라우저에서 부팅·조작하고 콘솔 오류가 없는지 확인한다.
6. 실제 Release URL, 파일 SHA-256, Pages 커밋과 공개 검증 결과를 이 문서와 `CURRENT.md`에 docs-only 후속 PR로 기록한다.

## 9. 작업 트리 상태

- 브랜치: `hotfix/v1.2.1`
- 기능·버전 커밋: `07586e51a7c66d6290602629a54b4cb6ce6b6d40`
- 이 문서 작성 전 상태: 깨끗함
- 빌드·검수 산출물: `tmp/` 아래에만 존재하며 커밋하지 않는다.
- 주 작업공간의 사용자 소유 미추적 UID 5개는 수정·스테이징하지 않았다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 전체 자동 회귀·검수 통과
- [x] 검수 대상 불변 기능 SHA 기록
- [x] 그래픽·오디오 자산 변경 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] `hotfix/v1.2.1` 원격 푸시와 PR 병합
- [ ] `v1.2.1` 태그와 Windows GitHub Release
- [ ] PC·모바일 Web Pages 배포와 공개 URL 검증
