# v1.2.5 정식 출시 완료 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-10
- 목표 버전: `1.2.5`
- 문서 마감 브랜치: `codex/v125-release-closeout`
- 출시 기준 브랜치 및 SHA: `main` / `f757ffa9f9e962158f2123856c8568a3163ecb6c`
- 출시 태그: `v1.2.5` → `f757ffa9f9e962158f2123856c8568a3163ecb6c`
- 관련 PR: `#88` 제품 후보, `#89` 검증 게이트 정합화
- GitHub Release: `https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.5`
- Windows 태그 빌드: `https://github.com/bluehige/mawangseong-demo/actions/runs/31354224753`
- Pages 실행: `https://github.com/bluehige/mawangseong-demo/actions/runs/31354629115`
- 공개 Web: `https://bluehige.github.io/mawangseong-demo/web_Demo/`

## 2. 이번 세션 목표

- 요청 사항: 그래픽·UI·전투·스토리 수정본을 v1.2.5 정식 Windows/Web판으로 빌드하고, 소스와 직접 플레이 Web판을 GitHub에 게시한다.
- 완료 조건: 최종 `main` Full PASS, 같은 SHA의 Windows/Web 패키지와 부팅 확인, 불변 태그·Release·Pages 공개 완료.
- 범위에서 제외한 사항: Steamworks App/Depot ID 발급, 법무·스토어 심사, 유료 Windows 코드 서명 인증서 적용.

## 3. 완료한 작업

- PR `#88`로 v1.2.5 제품·그래픽·UI·스토리·밸런스 수정본을 `main`에 병합했다.
- 첫 Full의 4개 실패가 현재 제품 사양을 따라가지 못한 검사 규칙임을 확인하고, PR `#89`에서 검사 기대값만 정합화했다.
- 최종 `main@f757ffa9f9e962158f2123856c8568a3163ecb6c`에서 Full 158/158을 통과했다.
- 같은 SHA에 주석 태그 `v1.2.5`를 고정하고 Windows Steam/Web export를 생성했다.
- Windows는 로컬 1280×720 10초 부팅과 태그 기반 GitHub Actions 빌드·스모크를 모두 통과했다.
- Web은 Full 원본 보고서와 카탈로그를 포함한 11개 artifact manifest를 검증하고, 로컬·공개 1280×720 타이틀 부팅을 확인했다.
- GitHub Release 자산 3개를 게시했고 서버측 digest가 로컬 SHA-256과 일치했다.
- Pages 실행 `31354629115`로 기존 직접 플레이 링크를 v1.2.5로 교체했다.

## 4. 변경 파일

이번 문서 마감 브랜치는 아래 `docs/handoff/` 두 경로만 변경한다. 출시 태그의 제품 코드·데이터·자산·검증 도구는 바꾸지 않는다.

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/handoff/V125_RELEASE_COMPLETE_2026-08-10.md` | 최종 Full·패키지·Release·Pages 증빙 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점을 v1.2.5 출시 완료 상태로 갱신 | 완료 |

제품 변경 범위는 `docs/handoff/V125_RELEASE_CANDIDATE_2026-08-10.md`, 검증 게이트 수정은 `docs/handoff/V125_RELEASE_GATE_FIX_2026-08-10.md`에 기록돼 있다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예, 제품 후보 작업에서 사용
- 생성 모델: GPT internal image generation
- 생성 원본 및 출처: `assets/source/imagegen/v125_stage_progression/`
- 런타임 최종 자산: `assets/backgrounds/v125/`, `assets/tiles/stage_02/`, `assets/tiles/stage_03/`, `assets/tiles/stage_04/`
- 연결 결과: Stage 02~04 전용 배경·통로와 Stage별 렌더 연결을 Full 그래픽 계약 및 대표 관리·전투 화면에서 확인했다.
- 이 문서 마감 단계의 신규 그래픽·오디오 변경은 없다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 최종 `main` `RunCoreVerification.ps1 -Mode Full` | PASS, 158/158, 실패 0, 1294.99초 | `tmp/core_verification/runs/20260810_123859/report.json` |
| 2 | Full provenance | PASS, commit·catalog·clean 일치 | `tmp/core_verification/latest.json` |
| 3 | `PrepareSteamBuild.ps1 -Version 1.2.5` | PASS | `tmp/v125_release_final/f757ffa/windows/` |
| 4 | Windows 1280×720 10초 부팅 | PASS, 조기 종료 없음, stderr 0바이트, 버전 `1.2.5.0` | `windows_boot.stderr.log` |
| 5 | 태그 기반 Windows GitHub Actions | PASS | 실행 `31354224753` |
| 6 | Web export + 원본 manifest | PASS, 11 artifacts, 158 checks | `web/build-manifest.json` |
| 7 | 두 ZIP 압축 해제 후 공식 검증 | PASS | `verify_web_zip/`, `verify_windows_zip/` |
| 8 | 로컬 Web 1280×720 부팅·육안 확인 | PASS, 콘솔 오류 0 | `local_web_smoke/shot-0.png` |
| 9 | GitHub Release 자산 digest | PASS, 로컬 SHA-256과 3개 모두 일치 | Release assets API |
| 10 | Pages provenance·배포 | PASS | 실행 `31354629115` |
| 11 | 공개 manifest | PASS, `v1.2.5`, `f757ffa…`, 158/158 | 공개 `build-manifest.json` |
| 12 | 공개 Web 1280×720 부팅·육안 확인 | PASS, 콘솔 오류 0 | `public_web_smoke_45s/shot-0.png` |

### 최종 provenance

- `commit_sha`: `f757ffa9f9e962158f2123856c8568a3163ecb6c`
- `catalog_sha256`: `7a6654b268296a99f34a4c37ccb381ffda6ef792bc7a405cdb2ae47e8ff23524`
- `source_tree_clean`: `true`
- Full: `158 passed / 0 failed`

### 정식 패키지

| 파일 | 바이트 | SHA-256 |
|---|---:|---|
| `mawangseong-v1.2.5-web.zip` | 292,582,702 | `ed965832fe6978ce1367d8451da7eab1ab4c2b09c2a7f17be93ed2768f8c18cd` |
| `MawangCastle-v1.2.5-Windows.zip` | 316,977,641 | `9db441c000387381d8a4c6754bcb5a9854e6eccc256ec5c0bc9d2e1a8a745993` |
| `SHA256SUMS.txt` | 193 | `f4393fb221ccdd4e21ed0c95d1f4f9662820300656cbe442d2a9eddef39e3153` |

### 검수 반복 기록

| 회차 | 검수 범위 | 결과 | 조치 |
|---:|---|---|---|
| 1 | 분야별 최종 검수 | P1 3 / P2 7 / P3 3 | 제품·그래픽·UI·스토리·밸런스 일괄 수정 |
| 2 | 제품 후보 직접 재검증 | TARGETED_PASS | PR `#88` 병합 |
| 3 | 첫 `main` Full | 154/158 | 사양이 바뀐 검사 규칙 4개 정합화, 제품 런타임 변경 없음 |
| 4 | 최종 병합 SHA Full | PASS, 158/158 | 출시 판정 확정 |

- 남은 P1/P2 지적: 0건
- 남은 P3 지적: 0건
- 실행하지 못한 필수 검수와 이유: 없음
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 최종 SHA 뒤에는 이 `docs/handoff/` 문서만 추가한다.

### 정책 CI용 최종 승인 필드

- Review task ID: 019fcf24-1f81-7d33-9978-7a13ab667184 / remediation + Full
- Reviewed SHA: f757ffa9f9e962158f2123856c8568a3163ecb6c
- Review range: 5082a86f5a25d098b7f1c040958bd14da703e578..f757ffa9f9e962158f2123856c8568a3163ecb6c
- Remaining P1/P2: 0
- Final review result: PASS

## 7. 미해결 항목과 위험

- v1.2.5 제품·GitHub Release·공개 Web 범위의 필수 미해결 항목: 없음.
- Windows 실행 파일은 `NotSigned`다. 상용 배포용 인증서 구매·보관·서명 파이프라인은 별도 소유자 작업이다.
- Steam 제출에는 App/Depot ID, 법무·지원 연락처, 스토어 심사 등 외부 항목 17개가 남아 있다. 현재 패키지 자체 검사는 `SETUP_PASS`다.
- 공개 Web은 PCK가 약 287MB라 최초 접속에서 로딩 시간이 발생한다. 실제 공개망에서는 약 45초 뒤 정상 타이틀을 확인했다.
- Pages 워크플로의 일부 공식 action에 Node.js 20 폐기 경고가 있지만 이번 실행은 Node.js 24 강제 실행으로 PASS했다.

## 8. 다음 작업 순서

1. v1.2.5는 새 필수 결함이 발견되지 않으면 태그와 Release를 이동·교체하지 않는다.
2. 새 수정은 최신 `main`에서 다음 SemVer 패치 또는 확장 브랜치로 시작한다.
3. Steam 제출을 재개할 때 외부 항목 17개와 Windows 코드 서명을 완료한다.

## 9. 작업 트리 상태

- 격리 작업공간: `tmp/v125_release_main`
- 문서 마감 전 상태: `codex/v125-release-closeout`, clean
- 미커밋 파일: 이 문서와 `docs/handoff/CURRENT.md`만 추가 예정
- 사용자 기본 작업 트리의 기존 `.import`, 캡처, 브라우저 산출물, `progress.md`는 수정·스테이징하지 않았다.
- 로컬 빌드 산출물: `tmp/v125_release_final/f757ffa/`
- 영구 보존 위치: GitHub Release `v1.2.5`

## 10. 종료 체크리스트

- [x] 제품·그래픽·UI·스토리 수정 반영
- [x] 최종 `main` Full 158/158 통과
- [x] Windows/Web 정식 패키지·해시·부팅 통과
- [x] `v1.2.5` 태그와 GitHub Release 게시
- [x] Pages provenance와 공개 Web 부팅 확인
- [x] 검수 SHA와 작업 ID 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 문서 전용 PR 병합
