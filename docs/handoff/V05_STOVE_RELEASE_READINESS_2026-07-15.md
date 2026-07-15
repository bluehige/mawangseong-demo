# v0.5 STOVE 판매·자체등급분류 준비 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5 STOVE 유료 출시 및 자체등급분류 준비
- 작업 브랜치: `codex/v05-stove-release-readiness`
- 기준 브랜치 및 SHA: `main` / `42bf1f4a5acd5ffa7bacc949f63f9444e0f264aa`
- 마지막 기능 커밋 SHA: `a4e1c963ec2b68fbfb59cf0b7c65a11b11e35dfd`
- 원격 푸시 여부: 미실행
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: STOVE 입점 절차와 사용자가 직접 해야 하는 일을 상세히 정리하고,
  계정·본인확인·약관·최종 승인 외의 제출 기반을 저장소에 준비한다.
- 완료 조건: STOVE 상품 페이지·심의 자료·규격 그래픽과 재생성·검증 도구가 있고,
  사운드 확정 전 빌드는 차단하며, STOVE 등급을 Steam에 유통 통보하는 후속 절차가
  기록돼 있다.
- 범위에서 제외한 사항: STOVE 계정 생성·약관 동의, 개인/사업자·은행 서류 제출,
  사운드 확정 전 Windows 빌드, Uploader 로그인·업로드, 심의 영상 녹화, 실제 심사,
  출시, Steam 유통 통보 제출, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 구현: `stove/release_config.json`과 출시 검증기를 추가해 계정·법적 정보·사운드·
  빌드·심의·출시·Steam 유통 통보를 명시적 게이트로 관리한다.
- 상점: 한국어 한 줄 소개·상세 설명·태그·지원 기능·영문 최소/권장 사양 초안과
  Studio 그룹/프로젝트/상품 입력표를 작성했다.
- 심의: 게임 설명서, 일곱 등급 요소 답변 초안, 초·중·후반 및 모든 엔딩 영상
  촬영표를 작성했다. 현재 소스에서 언어 문자열 5,411개와 런타임 이미지 1,065개
  목록을 생성했다.
- 그래픽: 승인된 기존 게임 일러스트와 Steam 실제 플레이 캡처로 STOVE 타이틀
  이미지 2종, PC 썸네일, ICO, 860×483 스크린샷 6장을 생성했다.
- 법적 흐름: STOVE 자체등급은 STOVE 실제 출시를 전제로 하며, 등급 확정 뒤 Steam
  유통에는 게임물관리위원회 자체등급분류 게임물 유통 통보가 필요함을 기록했다.
- 빌드: 사용자 지시에 따라 사운드 확정 전 빌드·업로드를 실행하지 않았다.
- 스토리·데이터·밸런스·게임 런타임: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/release/STOVE_RELEASE_MASTER_PLAN.md` | 공식 절차, 책임 분담, 심의·Steam 통보 흐름 | 완료 |
| `docs/release/STOVE_OWNER_ACTIONS.md` | 사용자가 직접 할 가입·법적 정보·승인 작업 | 완료 |
| `stove/release_config.json` | 공개 메타데이터와 출시 게이트 | 완료, 외부 값 대기 |
| `stove/store/` | 상품 문구와 Studio 입력값 | 완료, 사용자 승인 대기 |
| `stove/ratings/` | 설명서·설문·영상표·언어·CG 목록 | 현재 소스 기준 완료 |
| `marketing/stove/` | 업로드 규격 그래픽과 출처 | 완료 |
| `tools/release/generate_stove_graphics.py` | STOVE 그래픽 결정론적 재생성 | PASS |
| `tools/release/export_stove_rating_materials.py` | 언어·런타임 이미지 목록 재생성 | PASS |
| `tools/release/validate_stove_release.py` | 저장소 기반과 외부 출시 게이트 검증 | SETUP_PASS |
| `tools/ci/test_validate_stove_release.py` | 검증기 관련 회귀 테스트 | 4/4 PASS |
| `README.md` | STOVE 출시 문서 진입점 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 작업에서 신규 생성하지 않음. 승인된 기존
  GPT 내부 생성 게임 자산을 결정론적으로 재사용.
- 생성 모델: 기존 원본 기록값 `GPT internal image generation`
- 생성 원본 경로: `assets/source/imagegen/update4_endings_phase32/ending_e19_minion_crown_source_2026-07-14.png`
- `SOURCE.md` 경로: `assets/source/imagegen/update4_endings_phase32/SOURCE.md`
- 런타임 최종 자산 경로: 기존 `assets/ui/endings/update4/ending_minion_wears_the_crown.png`
- 마케팅 최종 자산 경로: `marketing/stove/`
- 프롬프트/후처리/크롭/알파 처리 요약: 신규 프롬프트 없음. 기존 승인 이미지와
  1920×1080 실제 플레이 캡처를 Pillow로 크롭·리사이즈·타이틀 합성·ICO 변환했다.
- 게임 연결 및 실제 렌더 확인 결과: 게임 런타임 연결 변경 없음. 500×500 정사각,
  757×426 가로 타이틀과 860×483 전투 스크린샷을 원본 해상도로 직접 확인했다.
- 오디오: 변경·빌드 없음. 최종 심의 영상과 빌드는 사운드 확정 뒤 생성한다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | Python `py_compile` 4개 스크립트 | PASS | `tools/release/`, `tools/ci/` |
| 2 | `python tools/release/generate_stove_graphics.py` | PASS, 스크린샷 6장 | `marketing/stove/` |
| 3 | `python tools/release/export_stove_rating_materials.py` | PASS, 문자열 5,411개·이미지 1,065개 | `stove/ratings/*.tsv` |
| 4 | `python tools/release/validate_stove_release.py` | SETUP_PASS, 외부/최종 게이트 26개 대기 | `stove/release_config.json` |
| 5 | `python -m unittest tools.ci.test_validate_stove_release -v` | PASS, 4/4 | 검증기 단위 테스트 |
| 6 | 그래픽 원본 해상도 직접 확인 | PASS | 타이틀 2종·전투 스크린샷 1장 |
| 7 | 재생성 후 `git status --short` | PASS, 변경 없음 | 결정론적 출력 확인 |
| 8 | `git diff --check` | PASS | 공백 오류 없음 |
| 9 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 직접 영향 범위만 검수 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않았고, 실제 빌드와
  플레이 영상은 사용자의 사운드 확정 전 빌드 금지 지시에 따라 범위에서 제외했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. Reviewed SHA 이후에는
  `docs/handoff/` 문서만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: a4e1c963ec2b68fbfb59cf0b7c65a11b11e35dfd
- Review range: 42bf1f4a5acd5ffa7bacc949f63f9444e0f264aa..a4e1c963ec2b68fbfb59cf0b7c65a11b11e35dfd
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 사용자가 그룹명·ID, 공개 개발자/퍼블리셔명, 지원 이메일·페이지와 개인/사업자
  유형을 정하지 않았다.
- 개인 명의 유료 판매는 법정 판매자 정보 노출 범위를 확인한 뒤 선택해야 한다.
- 상품 문구·그래픽은 사용자 최종 승인이 필요하고, 사양은 저사양 실측 전 초안이다.
- 언어와 이미지 목록은 현재 소스 스냅샷이다. 최종 빌드 직전에 다시 생성해야 한다.
- 자체등급 예상은 보장값이 아니다. STOVE가 15세 초과 요소를 판단하면 자체등급
  경로를 사용할 수 없다.
- STOVE 등급 확정만으로 Steam 한국 유통이 자동 완료되지 않는다. 별도 유통 통보와
  빌드 동일성 확인이 필요하다.

## 8. 다음 작업 순서

1. 사용자: `docs/release/STOVE_OWNER_ACTIONS.md`에 따라 Studio 로그인·약관 동의 후
   그룹명/ID와 개인·사업자 선택을 확정한다. 완료 조건은 그룹 생성 화면 진입과
   공개 운영값 전달이다.
2. 공동: `stove/store/STUDIO_PORTAL_VALUES.md`의 ID를 승인하고 그룹·프로젝트·BASIC
   상품을 생성한 뒤 사업자/은행 정보 심사를 요청한다. 완료 조건은 Game ID와 승인
   상태를 `stove/release_config.json`에 반영하는 것이다.
3. 사용자 승인: 상품 문구·그래픽·등급 답변을 검토하고 지원 연락처를 확정한다.
4. 사운드 확정 뒤 저장소 작업: 출시 후보 빌드, STOVE 업로드, 설치·실행 검수와
   초·중·후반·모든 엔딩 영상을 만든다.
5. 사용자가 자체등급·빌드·상품 심사와 출시를 승인한다. STOVE 출시 뒤 등급번호로
   Steam 유통 통보서를 제출한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 기능 커밋 검증 시 깨끗함
- 미커밋 파일: 이 핸드오프와 `CURRENT.md` 문서 갱신만 별도 문서 커밋 예정
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치: 새 게임 빌드 없음. 제출용 추적 자산은 `marketing/stove/`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처와 파생 경로 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 기능 파일만 커밋
- [ ] 원격 푸시 및 PR 미실행
