# 제품 v1.2 공개 출시 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-16
- 목표 버전: 사용자 표시 `v1.2`, 기술 SemVer `1.2.0`; 다음 확장판 사용자 표시 `v2.0`, 기술 SemVer `2.0.0`
- 작업 브랜치: `codex/v12-public-release`
- 기준 브랜치 및 SHA: `main` / `8c6a7cb6c9f4069ffe318e5a3d878986c8a18913`
- 마지막 비문서 변경 SHA: `9e02b967fce83f1c5bc960b681635b0f2b2058e1`
- 원격 푸시 여부: 소스·PC Web·모바일 Web 원격 반영 완료
- 관련 PR 또는 태그: 불변 태그 `v1.2.0`, 소스 PR #37, PC Web PR #5, 모바일 Web PR #6
- `main` 최종 병합 SHA: `4a02eaac72cb5f45965e6981d0436ed20b6f0561`

## 2. 이번 세션 목표

- 요청 사항: 현재 출시 이름을 `v1.2`, 다음 확장판 이름을 `v2.0`으로 통일하고 출시본·PC Web·모바일 Web을 GitHub에 올린 뒤 공개 주소를 제공한다.
- 완료 조건: v1.2 Windows Release 첨부, 두 Pages 배포 성공, 공개 URL 실제 부팅, 저장소 기록 갱신.
- 범위에서 제외한 사항: 사용자 요청에 따라 전체 회귀·전체 플레이·별도 검수 에이전트는 실행하지 않았다. 아직 개발하지 않은 v2.0 빌드나 태그도 만들지 않았다.

## 3. 완료한 작업

- 구현: `v1.2.0` 태그를 기준 SHA에 고정하고 Windows·PC Web·모바일 Web을 clean worktree에서 내보냈다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음. 기존 최종 검수 결과를 재사용했으며 이번 세션에서 전체 밸런스 검수는 요청되지 않았다.
- UI/UX: PC/모바일 공개 페이지 표시를 `마왕성 v1.2`로 바꾸고 다음 버전을 `v2.0`으로 명시했다.
- 저장 및 호환성: Windows 출시본과 Web 빌드 모두 동일한 소스 SHA `8c6a7cb6c9f4069ffe318e5a3d878986c8a18913`에서 생성했다.
- 배포:
  - GitHub Release: https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.0
  - 소스 PR: https://github.com/bluehige/mawangseong-demo/pull/37
  - PC Web: https://bluehige.github.io/mawangseong-web-playtest/
  - 모바일 Web: https://bluehige.github.io/mawangseong-mobile-playtest/
  - PC Pages 성공 run: https://github.com/bluehige/mawangseong-web-playtest/actions/runs/29484249319
  - 모바일 Pages 성공 run: https://github.com/bluehige/mawangseong-mobile-playtest/actions/runs/29484251041

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.github/workflows/build-windows-steam.yml` | 공식 Godot 4.5.2 Windows ZIP 파일명으로 태그 빌드 다운로드 교정 | 완료 |
| `docs/handoff/CURRENT.md` | v1.2 공개 출시 상태와 다음 진입점 갱신 | 완료 |
| `docs/handoff/V12_PUBLIC_RELEASE_2026-07-16.md` | 출시·배포·검수 근거 기록 | 완료 |
| `mawangseong-web-playtest` 저장소 | v1.2 PC Web 산출물·표시·검증 워크플로 갱신 | PR #5 병합 완료 |
| `mawangseong-mobile-playtest` 저장소 | v1.2 모바일 최적화 산출물·표시·검증 워크플로 갱신 | PR #6 병합 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 미사용
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 기존 자산 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: PC/모바일 공개 Web의 Godot 캔버스 기동 확인

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `OnboardingFlowSmokeTest.tscn` | PASS | 한글 이름 저장, 튜토리얼 x1, 완료 후 x3 소개 포함 |
| 2 | `MobileTouchUISmokeTest.tscn -- --mobile-touch-ui` | PASS | 직접 컨트롤 제거, x3 잠금·해제 포함 |
| 3 | `python -m unittest tools.ci.test_mobile_web_export -v` | PASS (3/3) | 모바일 export 정책 |
| 4 | Windows v1.2 export 및 headless 실행 | PASS | 실행 종료 코드 0 |
| 5 | PC Web export | PASS | PCK 231,378,308바이트 |
| 6 | 모바일 최적화 Web export | PASS | PCK 146,796,228바이트, SHA-256 `d7957025f9c476738c6b7bed053fc472be8cb2c6dd8ccfa527c34a7a74c0fe0c` |
| 7 | 공개 PC Web 브라우저 부팅 | PASS | 1920×1080 캔버스, 콘솔 경고·오류 0건 |
| 8 | 공개 모바일 Web 브라우저 부팅 | PASS | 1280×720 캔버스, 회전 안내·전체화면 UI 존재, 콘솔 경고·오류 0건 |
| 9 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청: “굳이 전체검수는 하지마” |

- Windows ZIP: `MawangCastle-v1.2-Windows.zip`, 263,176,646바이트, SHA-256 `bdb05f73f20b50533fae564e76b4c8d76d38c276d0331ad4e2523be37c80c9c8`
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 명시적으로 제외됐다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 후보 SHA 이후 `docs/handoff/`만 변경했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 9e02b967fce83f1c5bc960b681635b0f2b2058e1
- Review range: 8c6a7cb6c9f4069ffe318e5a3d878986c8a18913..9e02b967fce83f1c5bc960b681635b0f2b2058e1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: `v1.2.0` 태그에서 시작된 자동 Windows artifact run은 공식 Godot 자산명을 잘못 지정해 실패했다. 태그는 불변 원칙에 따라 이동하지 않았고, 검증된 수동 Windows ZIP을 Release에 첨부했다.
- 워크플로 후속 상태: 공식 자산명 `Godot_v4.5.2-stable_win64.exe.zip`을 사용하는 수정은 SHA `9e02b967fce83f1c5bc960b681635b0f2b2058e1`에 반영했다. 다음 새 SemVer 태그부터 적용된다.
- 밸런스 관찰 항목: 이번 공개 작업에서는 밸런스 데이터를 변경하지 않았다.
- 외부 환경/도구 제약: 로컬 OAuth 토큰에 `workflow` scope가 없어 워크플로 파일은 연결된 GitHub 앱으로 안전하게 커밋했다.

## 8. 다음 작업 순서

1. v1.2 사용자 피드백을 수집하고 재현 가능한 문제만 `codex/v12-<topic>`에서 수정한다.
2. 새 수정판이 필요하면 최신 `main`에서 시작하고 기존 `v1.2.0` 태그는 이동하지 않는다.
3. v2.0 확장 개발은 최신 `main`에서 `release/v2.0` 계보로 시작하며 표시 이름은 `v2.0`, 기술 버전은 `2.0.0`을 사용한다.

## 9. 작업 트리 상태

- 미커밋 파일: 사용자가 보유한 추적 외 Godot UID 5개를 보존했다.
- 의도하지 않은 기존 변경: 없음.
- 스태시 또는 별도 작업공간: 기존 `stash@{0}` 보존. clean release worktree `C:\\Users\\LDK-6248\\Desktop\\AI개발\\어시스트프로젝트\\마왕성_v12_release_20260716` 사용.
- 빌드 산출물 위치: 위 release worktree의 `tmp/`에만 생성했으며 소스 브랜치에 커밋하지 않았다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 전체 검수 미요청 상태 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 그래픽 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 소스 PR 상태 기록
