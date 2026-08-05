# v1.2.2 시각 개편 27단계 Windows QA 테스트 빌드 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/codex/v122-ui-simplification@49388876d50009ed87655fffb2bf6974098b2f6c`
- 기능·빌드 소스 SHA: `c0c5871a1d84cdb140358f20dbb522d9ae69d63d`
- 마지막 기능 커밋 SHA: `c0c5871a1d84cdb140358f20dbb522d9ae69d63d`
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 현재 누적 변경을 먼저 커밋하고 사용자 확인용 테스트 빌드 생성
- 완료 조건:
  - Phase 3~26의 의도한 소스·데이터·자산·테스트·문서만 커밋
  - Windows QA debug export 생성
  - EXE/PCK 존재·버전·해시 확인
  - export와 패키지 부팅의 종료 코드 및 Godot 오류 확인
- 범위에서 제외한 사항:
  - 사용자 DAY 1~30 최종 플레이 검수
  - Full 회귀 검증
  - Windows 출시 후보·Steam·Web 후보 export
  - 코드 서명, 태그, Release, 배포, 원격 푸시

## 3. 완료한 작업

- 구현:
  - Phase 3~26 누적 구현과 이중 전선·Stage 01 시각 자산을 커밋 `c0c5871a1d84cdb140358f20dbb522d9ae69d63d`로 고정했다.
  - 211개 파일, 21,507 insertions, 653 deletions를 커밋했다.
  - 대량 `.import` 변경과 로컬 캡처·빌드 산출물은 커밋하지 않았다.
- 스토리 및 데이터:
  - 이번 빌드 단계에서 추가 변경 없음.
- 밸런스:
  - 이번 빌드 단계에서 추가 변경 없음.
- UI/UX:
  - 이번 빌드 단계에서 추가 변경 없음.
- 저장 및 호환성:
  - 이번 빌드 단계에서 추가 변경 없음.
  - 기능 SHA 이후에는 이 핸드오프와 `docs/handoff/CURRENT.md`만 변경했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE27_WINDOWS_QA_BUILD_2026-07-30.md` | 커밋·테스트 빌드·실행 결과 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 고정 source SHA와 다음 사용자 검수 진입점 갱신 | 완료 |

기능 커밋의 상세 파일 범위는 `git show --stat c0c5871a1d84cdb140358f20dbb522d9ae69d63d`과 Phase 3~26 핸드오프를 따른다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: N/A
- 생성 원본 경로: 기존 커밋의 `assets/source/imagegen/v122_stage01_spatial/`
- `SOURCE.md` 경로: 기존 커밋의 자산별 `SOURCE.md`
- 런타임 최종 자산 경로: 기존 커밋의 `assets/props/stage_01/`, `assets/tiles/stage_01/`, `assets/ui/stage_01/`
- 프롬프트/후처리/크롭/알파 처리 요약: 이번 빌드 단계에서 추가 처리 없음
- 게임 연결 및 실제 렌더 확인 결과: Phase 15~26 대상 렌더 PASS를 유지하며 이번 단계에서는 패키지 headless 부팅만 확인

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 명시적 211개 파일 staged 범위 검사 | PASS, `.import`·`tmp`·`builds`·`output`·`web_Demo` 0개 | 커밋 `c0c5871` |
| 2 | `git diff --cached --check` | PASS | 커밋 전 staged diff |
| 3 | 변경 JSON 9개 PowerShell 파싱 | PASS | 소스 트리 |
| 4 | staged 토큰 패턴 검사 | PASS, 일치 0건 | 소스 트리 |
| 5 | Godot 4.5.2 `--export-debug "Windows QA"` | PASS, exit 0 / ERROR 0 | `tmp/v122_windows_qa_c0c5871/` |
| 6 | `MawangCastle_v1.2.2_QA.exe --headless --quit-after 1` | PASS, exit 0 / ERROR 0 | 같은 빌드 폴더 |
| 7 | Windows 파일 메타데이터 | PASS, file/product `1.2.2.0` | QA EXE |
| 8 | 전체 회귀 테스트 | NOT_REQUESTED | 수행하지 않음 |
| 9 | 전체 플레이·시각 검수 | NOT_REQUESTED | 사용자 최종검수 전 |

첫 sandbox export는 패키지 생성과 부팅에는 성공했지만 `%APPDATA%`의 Godot editor settings 저장 제한으로 환경성 오류를 남겼다. 같은 기능 SHA와 출력 경로에서 사용자 설정 경로 접근을 허용한 검증 export를 다시 실행해 최종 `export exit 0 / ERROR 0`을 확인했다.

### Windows QA 테스트 산출물

| 파일 | 크기 | SHA-256 |
|---|---:|---|
| `MawangCastle_v1.2.2_QA.exe` | 94,340,608 bytes | `0632459356a7535a838ac775e79c734d6987f33f53c197c8e8ab2bbdf9ee443a` |
| `MawangCastle_v1.2.2_QA.pck` | 242,576,364 bytes | `137d60726f5a95c04653a3ed36f123b51ed5b522813e76a721fc6d2dd6f1ce14` |

- 제품명: `마왕님, 마왕성은 누가 지켜요? QA`
- 프리셋: `Windows QA`
- export 종류: debug
- 코드 서명: `NotSigned`
- 배포 상태: 로컬 테스트 전용, 업로드하지 않음

### 검수 에이전트 반복 기록

- 사용자가 전체 검수나 별도 검수 에이전트를 요청하지 않아 실행하지 않았다.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 사용자 최종검수는 다음 단계
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `docs/handoff/`만 변경

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `c0c5871a1d84cdb140358f20dbb522d9ae69d63d`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: DAY 1~30·1.2.1 저장·Update 2~4 사용자 최종검수는 아직 수행하지 않았다.
- 밸런스 관찰 항목: 이번 단계에서 추가 관찰 없음.
- 임시 구현 또는 대체 자산: 없음. 다만 이번 산출물은 debug QA 빌드이며 출시 후보가 아니다.
- 외부 환경/도구 제약:
  - Windows 물리 한/영 키 조합 중 상태는 실기 확인이 남아 있다.
  - EXE는 코드 서명되지 않았다.
  - 빌드는 `tmp/`에만 있으며 영구 artifact나 Release로 보관하지 않았다.

## 8. 다음 작업 순서

1. 사용자가 `tmp/v122_windows_qa_c0c5871/MawangCastle_v1.2.2_QA.exe`와 `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md`로 최종검수한다. 완료 조건은 DAY 1~30·1.2.1 저장·Update 2~4·1920/1366/1280·Windows 입력의 PASS/FAIL 기록이다.
2. FAIL이 있으면 재현 범위만 최소 수정하고 새 기능 SHA를 커밋한 뒤 관련 테스트와 Windows QA 빌드를 다시 만든다.
3. 사용자 최종검수 PASS 뒤에만 Full 검증, Windows 출시 후보와 데스크톱 Web 테스트 후보 export, 실행·SHA-256, 태그·Release·배포를 진행한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기능·빌드 소스: `c0c5871a1d84cdb140358f20dbb522d9ae69d63d`
- 미커밋 파일: 기존 대량 `.import` 변경 1,159개와 기존 테스트 스크립트 자동 생성 UID 5개
- 의도하지 않은 기존 변경: 위 `.import`와 UID를 되돌리거나 커밋하지 않고 보존
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치: `tmp/v122_windows_qa_c0c5871/`, 커밋 대상 아님
- 원격 푸시: 하지 않음

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 Windows QA export·부팅 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 유지
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시·PR·태그·Release 미진행 기록
