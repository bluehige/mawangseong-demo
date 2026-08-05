# v1.2.3 정식 출시 완료 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: `1.2.3`
- 문서 마감 브랜치: `codex/v123-release-closeout`
- 출시 기준 브랜치 및 SHA: `main` / `a8c79d94d24a284c31ac777f2de65ee2a3538584`
- 출시 태그: `v1.2.3` → `a8c79d94d24a284c31ac777f2de65ee2a3538584`
- 관련 PR: `#84` (`codex/v123-catalog-eol → release/v1.2.3`), `#85` (`release/v1.2.3 → main`)
- GitHub Release: `https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.3`
- Pages 실행: `https://github.com/bluehige/mawangseong-demo/actions/runs/31050839144`
- 공개 Web: `https://bluehige.github.io/mawangseong-demo/web_Demo/`

## 2. 이번 세션 목표

- 요청 사항: 최종 검수를 수행하고 승인 구간을 모두 처리해 정식판 빌드·태그·Release·공개 Web 배포를 완성한다.
- 완료 조건: 독립 검수 P1/P2/P3 0건, 최종 `main` Full 156/156, Web/Windows 패키지 재검증, 불변 태그·Release, Pages provenance와 공개 Chrome 부팅이 모두 PASS한다.
- 범위에서 제외한 사항: Steamworks App/Depot ID 발급·법무·스토어 심사, 유료 코드 서명 인증서 적용, 게임 기능·밸런스·자산 추가 변경.

## 3. 완료한 작업

- 기존 `v1.2.2` 태그와 Release는 교체하지 않고 불변 감사 기록으로 보존했다.
- v1.2.2 Pages 실패 원인이 Windows CRLF 체크아웃과 Ubuntu LF Git blob의 catalog 해시 불일치임을 확정했다.
- v1.2.3에서 catalog LF 고정, Git blob 원시 바이트 해시, provenance 전용 저장소 정책 CI를 적용했다.
- 독립 검수 1회차 P3 1건을 수정하고 재검수에서 P1/P2/P3 모두 0건, PASS를 받았다.
- PR #84를 merge commit `1aa9dffb95babc3312d6e53c6b242ae3ebf6f2a0`으로 `release/v1.2.3`에 병합했다.
- PR #85를 merge commit `a8c79d94d24a284c31ac777f2de65ee2a3538584`으로 `main`에 병합했다.
- 정확한 최종 `main` SHA에서 Full 156/156, Web·Windows 정식 export, 패키지 해시·부팅·manifest를 검증했다.
- `v1.2.3` 태그와 GitHub Release를 게시하고 자산 3개의 GitHub digest가 로컬 SHA-256과 일치함을 확인했다.
- Pages 실행 #31050839144에서 Release 다운로드·manifest·태그 catalog provenance·배포가 모두 PASS했다.
- 공개 URL manifest와 Chrome 1280×720 실제 부팅·육안 화면·콘솔 오류 0건을 확인했다.

## 4. 변경 파일

이번 문서 마감 브랜치의 변경은 아래 `docs/handoff/` 두 경로뿐이다. 출시 제품 트리와 태그는 변경하지 않는다.

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/handoff/V123_RELEASE_COMPLETE_2026-08-06.md` | 최종 검수·패키지·태그·Release·Pages 증빙 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 단일 진입점을 v1.2.3 출시 완료 상태로 갱신 | 완료 |

제품 수정 범위는 `docs/handoff/V123_CATALOG_PROVENANCE_FIX_2026-08-06.md`에 기록돼 있다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: N/A
- 생성 원본 경로: 변경 없음
- `SOURCE.md` 경로: 변경 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: Full 자산 계약 PASS, Web 로컬·공개 1280×720 타이틀 실제 렌더 PASS

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 독립 검수 에이전트 재검수 | PASS, P1/P2/P3 0/0/0 | 작업 ID `019fd3c1-c2cf-7431-8962-632b6bacf410` |
| 2 | 최종 `main` `RunCoreVerification.ps1 -Mode Full` | PASS, 156/156, 실패 0, 1177.03초 | `tmp/core_verification/runs/20260806_062649/report.json` |
| 3 | Full provenance | PASS, commit·clean·catalog 일치 | `tmp/core_verification/latest.json` |
| 4 | Web export + 원본 manifest | PASS, 11 artifacts | `tmp/v123_release_final/a8c79d9/web/build-manifest.json` |
| 5 | Web ZIP 압축 해제 후 manifest | PASS, `v1.2.3`, 156 checks | `tmp/v123_release_final/a8c79d9/verify_web_zip/` |
| 6 | Windows 1280×720 10초 부팅 | PASS, 조기 종료 없음, stderr 0바이트 | `tmp/v123_release_final/a8c79d9/windows_boot.stderr.log` |
| 7 | Windows 버전·비밀정보·서명 | PASS, `1.2.3.0`, API key형 0건, `NotSigned` | 콘솔 출력 |
| 8 | Windows ZIP 압축 해제 해시 | PASS, EXE/PCK 2개 일치 | `tmp/v123_release_final/a8c79d9/verify_windows_zip/` |
| 9 | 로컬 Web Chrome 1280×720 | PASS, canvas 1280×720, console error/warning 0 | `output/playwright/v123-final-web-1280x720.png` |
| 10 | GitHub Release 자산 digest | PASS, 로컬 3개 SHA-256과 일치 | Release assets API |
| 11 | Pages workflow | PASS, provenance 포함 | 실행 `31050839144` |
| 12 | 공개 manifest | PASS, `v1.2.3`, `a8c79d94...`, 156/156 | 공개 `build-manifest.json` |
| 13 | 공개 Web Chrome 1280×720 | PASS, canvas 1280×720, console error/warning 0, 육안 정상 | `output/playwright/v123-public-web-1280x720.png` |

### 최종 provenance

- `commit_sha`: `a8c79d94d24a284c31ac777f2de65ee2a3538584`
- `catalog_sha256`: `f286c025739274504e81c7ee9b8a0134b514d0f96cb2a2eb4d6456d8ae0c70a9`
- `source_tree_clean`: `true`
- Full: `156 passed / 0 failed`

### 정식 패키지

| 파일 | 바이트 | SHA-256 |
|---|---:|---|
| `mawangseong-v1.2.3-web.zip` | 287,070,425 | `bcb955cbaef8c8c01317bbac1c3dca18ae6a637e6f381c1d36661a0581ce38d2` |
| `MawangCastle-v1.2.3-Windows.zip` | 311,464,408 | `9bc509c635931d8970ba067fb915e0a4a04c25b6bf96c016898fb3e7a39f130e` |
| `SHA256SUMS.txt` | 191 | `6c50df5f1cd349b06afd39c925ee64f9826af6f119b050a097e18e4002ba3e77` |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 재검수 결과 |
|---:|---|---|---|---|---|---|
| 1 | `019fd3c1-c2cf-7431-8962-632b6bacf410` | `42d763b2ed35a541e163b05426ebdbcc0221913a..5ea473edb64f8c022241c2f16e0a17ff1010c282` | `5ea473edb64f8c022241c2f16e0a17ff1010c282` | Steam 안내 구버전 예시 P3 1건 | 세 곳을 1.2.3으로 정렬 | FAIL |
| 2 | `019fd3c1-c2cf-7431-8962-632b6bacf410` | `42d763b2ed35a541e163b05426ebdbcc0221913a..2929e9cf284bb4b7be0657546efa5ef298af1080` | `2929e9cf284bb4b7be0657546efa5ef298af1080` | 없음 | 재검수 | PASS |

- 남은 P1/P2 지적: 0건
- 남은 P3 지적: 0건
- 실행하지 못한 필수 검수와 이유: 없음
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 검수 SHA 뒤 제품 트리에는 `docs/handoff/`만 추가됐고, 출시 태그 뒤에도 이 문서 마감 변경뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: 019fd3c1-c2cf-7431-8962-632b6bacf410
- Reviewed SHA: 2929e9cf284bb4b7be0657546efa5ef298af1080
- Review range: 42d763b2ed35a541e163b05426ebdbcc0221913a..2929e9cf284bb4b7be0657546efa5ef298af1080
- Remaining P1/P2: 0
- Final review result: PASS

## 7. 미해결 항목과 위험

- 정식 v1.2.3 제품·GitHub 배포 범위의 필수 미해결 항목: 없음.
- Windows 코드 서명: `NotSigned`. 인증서 구매·보관·서명 파이프라인은 Steam/상용 배포 전에 별도 소유자 작업이 필요하다.
- Steam 외부 gate: App/Depot ID, 법무·지원 연락처·스토어 심사 등 17개 항목은 `validate_steam_release.py --strict` 전에 완료해야 한다.
- GitHub Actions 유지보수 경고: 현재 사용 중인 일부 공식 action이 Node.js 20 대상으로 표시되지만 runner가 Node.js 24로 강제 실행해 이번 배포는 PASS했다. 향후 공식 action 새 major가 나오면 갱신한다.

## 8. 다음 작업 순서

1. v1.2.3에는 새 필수 수정이 없으면 손대지 않는다. 새 수정이 필요하면 최신 `main`에서 다음 SemVer 패치 브랜치를 만든다.
2. Steam 판매 준비를 재개할 때 `steam/release_config.json`의 외부 항목과 코드 서명 인증서를 소유자 절차로 완료한다.
3. 다음 확장판은 반드시 최신 `main`에서 새 `release/v2.0` 통합선을 만들어 시작한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 문서 마감 전 `main...origin/main` clean
- 미커밋 파일: 이 문서와 `docs/handoff/CURRENT.md`만 문서 전용 브랜치에서 추가
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: 없음
- 빌드 산출물 위치: `tmp/v123_release_final/a8c79d9/`
- 공개 보존 위치: GitHub Release `v1.2.3`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·독립 검수 완료
- [x] 최종 `main` Full 156/156 통과
- [x] Web/Windows 정식 패키지·해시·부팅 통과
- [x] 검수 대상 SHA와 작업 ID 기록
- [x] 그래픽·오디오 변경 없음 확인
- [x] `v1.2.3` 태그·GitHub Release 게시
- [x] Pages provenance·공개 Chrome 부팅 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 문서 전용 PR merge
