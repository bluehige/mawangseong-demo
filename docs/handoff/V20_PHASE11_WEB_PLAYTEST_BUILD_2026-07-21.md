# 제품 2.0 Phase 11 PC Web 플레이테스트 빌드

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 2.0 Phase 11
- 작업 브랜치: `test/web-v20-p11-sellability`
- 기준 브랜치 및 SHA: `origin/release/v2.0@4b687aeea80b487f237e6c153dce8600989ec81b`
- 빌드 최종 SHA: `8086cdd45a82f624a04241e37613d36cd538d629`
- 원격 푸시 여부: 예
- 관련 PR 또는 태그: 소스 빌드는 PR 없이 `test/web-*` 브랜치에 직접 푸시, 공개 Web [PR #7](https://github.com/bluehige/mawangseong-web-playtest/pull/7) merge `7678ca4d5d08c0b75efbe71c78852ab551c7f509`

## 2. 이번 세션 목표

- 요청 사항: Phase 11을 여러 명이 실제 테스트할 수 있도록 독립 PC Web 빌드와 공개 URL을 준비한다.
- 완료 조건: 2.0 타이틀 진입, `2.0 새 시작`, DAY 01 운영 화면, 공개 자산 200, 브라우저 오류 0건을 확인한다.
- 범위에서 제외한 사항: 실제 사람 6~10명의 무설명 블라인드 결과 수집과 Go/No-Go 판정, Phase 12 구현, 전체 회귀·별도 검수 에이전트.

## 3. 완료한 작업

- `release/v2.0` Phase 10 merge SHA에서 Godot 4.5.2 Web release export를 생성했다.
- `web_Demo/index.pck` 231,748,912바이트와 `index.wasm` 38,047,590바이트를 Git LFS로 추적했다.
- `build-version.txt`\, `playtest-build.json`에 채널, 기준 소스, 엔진, 파일 크기와 SHA-256을 기록했다.
- 기존 v1.2.1 루트를 유지하고 Phase 11을 별도 하위 경로에 배포했다.
- 공개 플레이 URL: https://bluehige.github.io/mawangseong-web-playtest/v20-p11/
- Pages 배포 run `29791248121`은 자산 크기·SHA·소스 표식 검사와 배포를 모두 PASS했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.gitattributes` | Web PCK/WASM Git LFS 추적 | 완료 |
| `web_Demo/*` | Phase 11 PC Web 런타임·출처 매니페스트 | 완료 |
| `docs/handoff/V20_PHASE11_WEB_PLAYTEST_BUILD_2026-07-21.md` | 빌드·배포·검증 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 공개 URL과 Phase 11 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 신규 자산: 없음. 기존 Phase 0~10 런타임 자산을 Web export에 포함했다.
- 게임 연결 및 실제 렌더 확인: 공개 Chromium에서 타이틀과 DAY 01 운영 화면을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | Godot `--export-release Web web_Demo/index.html` | PASS | export exit 0 |
| 2 | `--main-pack web_Demo/index.pck --quit-after 5` | PASS | PCK headless boot exit 0 |
| 3 | 매니페스 파일 크기·SHA-256 대조 | PASS | PCK `cc0cc314...920c7fa`, WASM `6ead2ac...9545240` |
| 4 | 로컬 하위 경로 Chromium 타이틀→DAY 01 | PASS | PCK/WASM 200, 오류·경고 0 |
| 5 | GitHub Pages run `29791248121` | PASS | 배포 job 1m11s 완료 |
| 6 | 공개 URL Chromium 타이틀→`2.0 새 시작`→DAY 01 | PASS | 오류·경고 0 |
| 7 | 전체 회귀 테스트 | NOT_REQUESTED | 요청 범위의 Web 배포만 검증 |
| 8 | 별도 검수 에이전트 | NOT_REQUESTED | 사용자 미요청 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 8086cdd45a82f624a04241e37613d36cd538d629
- Review range: 8086cdd45a82f624a04241e37613d36cd538d629..8086cdd45a82f624a04241e37613d36cd538d629
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

빌드 기능 범위의 출처 비교는 `4b687aeea80b487f237e6c153dce8600989ec81b..8086cdd45a82f624a04241e37613d36cd538d629`이다. 정책 필드의 범위는 빌드 SHA 후 핸드오프만 추가하는 푸시 경계와 일치시킨다.

## 7. 미해결 항목과 위험

- Phase 11 판정은 아직 `PENDING`이다. 실제 사람 6~10명의 무설명 플레이 데이터가 없으며, 자동 검증을 재미·이해도 결과로 대체하지 않는다.
- 최초 원격 정책 run `29785016620`은 핸드오프 미추가 상태에서 예상대로 실패했다. 본 문서와 `CURRENT.md`만 빌드 SHA 후에 추가해 재검사한다.
- 공개 Web 런타임은 최초 로드 시 231MB PCK 다운로드 시간이 필요하다.

## 8. 다음 작업 순서

1. 공개 URL을 실제 테스터 6~10명에게 제공하고 `docs/playtest/v20/README.md`의 절차로 각자 무설명 세션을 진행한다.
2. 예약 코드와 세션 ID로 응답을 수집하고 `V20SellabilityEvaluator`로 Go/No-Go/Pending을 계산한다.
3. 6명 이상의 유효한 사람 결과가 Go일 때만 Phase 12 DAY 6~30 선택 이식을 시작한다.

## 9. 작업 트리 상태

- 브랜치: `test/web-v20-p11-sellability`
- 의도한 미커밋: 본 핸드오프와 `CURRENT.md`
- 보존한 기존 미추적 파일: Godot `.gd.uid` 5개. 해당 `.gd`의 정상 sidecar이며 삭제하지 않았다.
- 빌드/캡처 산출물: 추적 중인 `web_Demo/` 빌드, 미추적 `output/playwright/` 로컬 캡처.

## 10. 종료 체크리스트

- [x] Web export와 출처 매니페스 완료
- [x] 로컬 및 공개 URL 타이틀→DAY 01 진입
- [x] Pages 배포 완료
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·별도 검수 에이전트를 실행하지 않음
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋·푸시
