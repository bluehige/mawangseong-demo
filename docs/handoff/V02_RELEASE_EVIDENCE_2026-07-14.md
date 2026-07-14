# v0.2.2 Web 릴리즈 증빙 호환 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-14
- 목표 버전: v0.2.2
- 작업 브랜치: `hotfix/v0.2.2-release-evidence`, `codex/v022-release-main-lineage`
- 기준 브랜치 및 SHA: `v.02` / `312a649afa5c379101194b23cddcfeec4ecf3815`, `main` / `a2f4349f1070c9589ee21fe42c52238da6ccd290`
- 검증·빌드 소스 SHA: `c8b5a4684d8f55e33e9c4da4b7ea3fab3af7f077`
- `main` 계보 검토 SHA: `966b9dbbb900a6d60b23cd841f3a7e57d3656a8b`
- 원격 푸시 여부: v0.2.2 소스 푸시와 PR #18 병합 완료, main 계보 브랜치는 문서 작성 시점 미푸시
- 관련 PR 또는 태그: PR #18, v0.2.2 태그는 생성 전

## 2. 이번 세션 목표

- 요청 사항: 입력 레이어 버그가 수정된 v0.2 Web을 공개 배포한다.
- 완료 조건: Full 원본 보고서와 Web ZIP이 새 manifest 정책을 만족하고, 태그·Release·Pages 및 공개 클릭 확인이 완료된다.
- 범위에서 제외한 사항: 게임 기능·스토리·데이터·밸런스·그래픽 변경, 별도 검수 에이전트.

## 3. 완료한 작업

- v0.2.1 입력 레이어 수정은 그대로 유지했다.
- v0.2.2에서 Full 러너가 runner 경로, commit SHA, catalog SHA-256, clean tree 상태를 원본 JSON에 직접 기록하도록 보강했다.
- 프로젝트·타이틀·export 메타데이터를 v0.2.2로 정렬했다.
- Full 45/45를 clean candidate SHA에서 다시 통과하고 Release 증빙 준비·Web export·manifest 원본 및 ZIP 재검증을 완료했다.
- PR #18로 `v.02`에 merge commit 통합했다. `main`에는 `ours` merge로 현행 v0.4 트리를 유지하면서 v0.2.2 조상 관계만 기록했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/tests/RunCoreVerification.ps1` | Release 증빙 provenance 기록 | v0.2.2 완료 |
| `project.godot`, `scripts/game/GameRoot.gd`, `export_presets.cfg` | v0.2.2 버전 메타데이터 | v0.2.2 완료 |
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
| 1 | `RunCoreVerification.ps1 -Mode Full` | PASS, 45/45, 808.32초 | v0.2.2 worktree `tmp/core_verification/latest.json` |
| 2 | `prepare_release_evidence.py` | PASS, 45 Full checks | 콘솔 출력 |
| 3 | Godot 4.5.2-stable Web export | PASS | 시스템 Temp release 폴더 |
| 4 | 원본·ZIP 재압축 해제 `validate_build_manifest.py` | PASS, 11 artifacts | `build-manifest.json` |
| 5 | `git merge-base --is-ancestor c8b5a46... 966b9db...` | PASS | exit code 0 |

- provenance: `commit_sha=c8b5a4684d8f55e33e9c4da4b7ea3fab3af7f077`, `catalog_sha256=562164eee28688633edccbd58e3837c110adb370fa9052e09ebc2c41cfbccea8`, `source_tree_clean=true`
- ZIP: `mawangseong-v0.2.2-web.zip`, 162,509,815 bytes, SHA-256 `8c8a6bfbc5134358101a5239b7982c7d9968ebd7115d4643e7c866625956273f`
- 별도 검수 에이전트: 사용자 요청이 없어 실행하지 않음
- 남은 P1/P2 지적: N/A
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `main` 계보 merge 뒤 `docs/handoff/`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 966b9dbbb900a6d60b23cd841f3a7e57d3656a8b
- Review range: a2f4349f1070c9589ee21fe42c52238da6ccd290..966b9dbbb900a6d60b23cd841f3a7e57d3656a8b
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동 검증과 로컬 Web 패키지 검증 범위에서는 없음.
- 밸런스 관찰 항목: 변경 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: GitHub Release·Pages 배포와 공개 URL 확인이 남아 있다.

## 8. 다음 작업 순서

1. `codex/v022-release-main-lineage` PR을 `main`에 merge commit으로 반영한다.
2. `v0.2.2` 태그와 GitHub Release 자산을 게시한다.
3. Pages를 v0.2.2로 배포하고 공개 Web에서 manifest·버전·클릭을 확인한다.
4. 배포 결과와 최종 원격 SHA를 문서에 갱신한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: main 계보 merge 뒤 문서 변경만 존재
- 미커밋 파일: 문서 작성 시점 `docs/handoff/` 2개
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: v0.2.2 전용 worktree `마왕성_v021_web_release`
- 빌드/캡처 산출물 위치: v0.2.2 worktree 비추적 `tmp/`, 시스템 Temp release/ZIP

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·Full 검증 통과
- [x] manifest 원본·ZIP 재검증 통과
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처 변경 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] main 계보 PR merge
- [ ] 태그·GitHub Release·Pages 배포
- [ ] 공개 Web 실제 클릭 확인
