# v0.2.3 Pages provenance 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-14
- 목표 버전: v0.2.3
- 작업 브랜치: `hotfix/v0.2.3-pages-provenance`, `codex/v023-pages-main-lineage`
- 기준 브랜치 및 SHA: `v.02` / `94987042485c37ddd005c0eb84a3796f02a2aabf`, `main` / `5f82f66a736ce0e35147fbe175ac0244f9e9ffb3`
- 검증·빌드 소스 SHA: `35b2913cf4d8dbdc1cb0230398b2722e4cd8dfc4`
- `main` 계보 검토 SHA: `77d9ede3b5d687795b5157065c236d9cf30d33f1`
- 원격 푸시 여부: 소스·문서 푸시, `v.02` PR #20과 `main` PR #21 병합 완료
- 관련 PR 또는 태그: PR #20, PR #21, `v0.2.3`, GitHub Release `v0.2.3`

## 2. 이번 세션 목표

- 요청 사항: 입력 레이어 버그가 수정된 v0.2 Web 릴리스를 실제 Pages에 갱신한다.
- 완료 조건: 태그 원본과 Full 보고서의 카탈로그 SHA가 운영체제 줄바꿈과 무관하게 일치하고, Release ZIP 검증과 Pages 배포 및 공개 클릭 확인이 통과한다.
- 범위에서 제외한 사항: 게임 기능·스토리·데이터·밸런스·그래픽 변경, 별도 검수 에이전트와 요청되지 않은 전체 수동 검수.

## 3. 완료한 작업

- v0.2.1 입력 레이어 클릭 통과 수정은 그대로 유지했다.
- `RunCoreVerification.ps1`이 `HEAD`의 Git blob을 바이너리 스트림으로 SHA-256 계산하도록 보강했다.
- 검증 카탈로그의 체크아웃 줄바꿈을 LF로 고정하고 프로젝트·타이틀·export 메타데이터를 v0.2.3으로 정렬했다.
- Full 45/45를 clean candidate SHA에서 다시 통과하고 Release 증빙 준비·Web export·manifest 원본 및 ZIP 재검증을 완료했다.
- PR #20으로 `v.02`에 merge commit 통합했다. `main`에는 `ours` merge로 현행 v0.4 트리를 유지하면서 v0.2.3 조상 관계만 기록했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.gitattributes` | 검증 카탈로그 LF 고정 | v0.2.3 완료 |
| `tools/tests/RunCoreVerification.ps1` | Git blob 기준 canonical catalog SHA 기록 | v0.2.3 완료 |
| `project.godot`, `scripts/game/GameRoot.gd`, `export_presets.cfg` | v0.2.3 버전 메타데이터 | v0.2.3 완료 |
| `docs/handoff/CURRENT.md`, 이 문서 | 최신 계보·검증·배포 준비 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: Full UI·전투 캡처 PASS

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `RunCoreVerification.ps1 -Mode Full` | PASS, 45/45, 804.29초 | v0.2.3 worktree `tmp/core_verification/latest.json` |
| 2 | `prepare_release_evidence.py` | PASS, 45 Full checks | 콘솔 출력 |
| 3 | Godot 4.5.2-stable Web export | PASS | 시스템 Temp release 폴더 |
| 4 | 원본·ZIP 재압축 해제 `validate_build_manifest.py` | PASS, 11 artifacts | `build-manifest.json` |
| 5 | `git merge-base --is-ancestor 35b2913... 77d9ede...` | PASS | exit code 0 |
| 6 | GitHub Release 자산 digest 재확인 | PASS, 로컬 ZIP과 일치 | `sha256:cdeebcd27fbc855e6a66b626c24adf2886ea7c813af4915bb18f1a74f9a4735d` |
| 7 | Pages workflow #29344205650 | PASS | `https://github.com/bluehige/mawangseong-demo/actions/runs/29344205650` |
| 8 | 공개 `build-manifest.json` cache-bust 조회 | PASS, HTTP 200, v0.2.3, 45/45 | `https://bluehige.github.io/mawangseong-demo/web_Demo/` |
| 9 | 공개 Web Playwright 실제 클릭 | PASS, 새 게임→등록 안내→이름 입력 화면 전환 | 로컬 `tmp/playwright/` 캡처(비추적) |

- provenance: `commit_sha=35b2913cf4d8dbdc1cb0230398b2722e4cd8dfc4`, `catalog_sha256=d19a3ee80db8e38670c11a79d63749031d56d5a7eb4045aa93cc67af2375b2a8`, `source_tree_clean=true`
- ZIP: `mawangseong-v0.2.3-web.zip`, 162,509,744 bytes, SHA-256 `cdeebcd27fbc855e6a66b626c24adf2886ea7c813af4915bb18f1a74f9a4735d`
- 별도 검수 에이전트: 사용자 요청이 없어 실행하지 않음
- 남은 P1/P2 지적: N/A
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `main` 계보 merge 뒤 `docs/handoff/`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 77d9ede3b5d687795b5157065c236d9cf30d33f1
- Review range: 5f82f66a736ce0e35147fbe175ac0244f9e9ffb3..77d9ede3b5d687795b5157065c236d9cf30d33f1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동 검증과 로컬 Web 패키지 검증 범위에서는 없음.
- 밸런스 관찰 항목: 변경 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 없음. GitHub Release·Pages 배포와 공개 URL 클릭 확인 완료.

## 8. 다음 작업 순서

1. 새로 승인된 v0.2 유지보수 항목이 생기면 최신 `v.02`에서 별도 브랜치를 만든다.
2. 변경 범위에 직접 관련된 테스트만 실행하고 새 패치 버전으로 검증한다.
3. 현재 공개 Web 기준은 `v0.2.3`과 Pages 실행 #29344205650이다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: main 계보 merge 뒤 문서 변경만 존재
- 미커밋 파일: 문서 작성 시점 `docs/handoff/` 2개
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: v0.2.3 전용 worktree `마왕성_v021_web_release`
- 빌드/캡처 산출물 위치: v0.2.3 worktree 비추적 `tmp/`, 시스템 Temp release/ZIP

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·Full 검증 통과
- [x] manifest 원본·ZIP 재검증 통과
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처 변경 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] main 계보 PR merge
- [x] 태그·GitHub Release·Pages 배포
- [x] 공개 Web 실제 클릭 확인
