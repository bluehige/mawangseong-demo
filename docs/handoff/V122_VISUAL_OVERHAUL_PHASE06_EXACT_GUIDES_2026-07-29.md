# v1.2.2 시각 개편 6단계 Stage 01 exact 투영 guide 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 승인된 Stage 01 비교 보드를 기준으로 다음 작업을 진행한다.
- 완료 조건:
  - 현재 제품 기본 이중 전선 데이터에서 왕좌 5×5 제작 좌표를 추출한다.
  - N/E/S/W 2셀 문턱의 방·복도 셀과 레이어를 고정한다.
  - guide 데이터와 런타임 데이터의 drift를 자동 검사한다.
  - 사용자 승인 전 신규 그래픽과 런타임은 변경하지 않는다.
- 범위 제외: 신규 그래픽 생성, 런타임 연결, 기능·밸런스·저장 변경, 화면·플레이·전체 QA, 빌드·커밋·푸시.

## 3. 완료한 작업

- 사용자의 `진행해`를 Stage 01 비교 보드 방향 승인으로 기록했다.
- `IsoMath.cell_to_iso_world()`와 renderer의 diamond·socket·layer 계산을 직접 대조했다.
- 왕좌:
  - native 5×5 투영면 `640×320`
  - `SW`, `open_mask 04`, S socket `[2,4] [3,4]`
  - 1024 원본의 바닥 guide `960×480`
- 문턱:
  - native 2×2 patch `256×128`
  - 2셀 개구부 길이 `143.108`
  - N/W `back`, E/S `front`
- guide JSON과 실제 layout·blueprint·grade rule을 함께 읽는 생성 도구를 추가했다.
- 2400×2200 보드와 개별 1024 guide 5종을 생성하고 원본 해상도로 확인했다.
- 런타임 코드·데이터·자산은 바꾸지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/design/v122/guides/stage01_spatial_exact_guide.json` | 단일 exact 좌표 원본 | 완료 |
| `docs/design/v122/V122_STAGE01_SPATIAL_EXACT_GUIDE_CONTRACT_2026-07-29.md` | 제작·레이어·합격 계약 | 완료 |
| `tools/build_stage01_spatial_exact_guide.mjs` | 실제 런타임 데이터 drift 검사와 guide 생성 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE06_EXACT_GUIDES_2026-07-29.md` | 이번 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- guide 산출물:
  - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\`
- 게임 연결 및 실제 렌더 확인 결과: 런타임 미변경

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | guide 생성 도구의 layout·blueprint·projection assertion | PASS | `tools/build_stage01_spatial_exact_guide.mjs` |
| 2 | 2400×2200 보드 생성 | PASS | 시각화 경로의 `v122_stage01_spatial_exact_guide_board_2026-07-29.png` |
| 3 | 보드 원본 해상도 시각 확인 | PASS | 텍스트·도형 잘림 없음 |
| 4 | 왕좌 개별 1024 guide 원본 확인 | PASS | footprint·S 2셀 socket·alpha guide 확인 |
| 5 | 런타임 관련 테스트 | NOT_REQUIRED | 런타임 미변경 |
| 6 | 전체 회귀·플레이 검수 | NOT_REQUESTED | 사용자 요청 전 보류 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- guide는 좌표 기준이며 최종 그래픽이 아니다.
- GPT 생성 결과가 guide의 바닥과 socket을 지키지 못할 수 있으므로 원본을 바로 런타임에 연결하면 안 된다.
- 현행 화면 scale `0.42`는 full-canvas 카메라 변경 뒤 달라질 수 있으므로 제작 원본의 기준으로 사용하지 않는다.
- 왕좌 생성 뒤에도 alpha·바닥 접지·S 개구부를 후처리 도구로 다시 맞춰야 한다.

## 8. 다음 작업 순서

1. exact guide와 기존 유지 자산 5종을 reference로 왕좌 `SW/open_04` 원본을 GPT 내부 이미지 생성으로 만든다.
2. 같은 재질·광원으로 N/E/S/W 2셀 문턱 transition 4종을 순차 생성한다.
3. 생성 원본의 alpha·투영·socket 정합 contact sheet를 만든 뒤 사용자 승인받는다.
4. 승인된 자산만 runtime path와 manifest/renderer lookup에 연결한다.
5. 런타임 연결 뒤에만 1920·1280 정합과 이동 경로 일치를 집중 확인한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 HEAD: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 이번 단계 파일은 미커밋 상태다.
- 기존 대규모 코드·데이터·`.import` 변경을 보존했고 되돌리거나 스테이징하지 않았다.
- 빌드 산출물은 없다.
- guide PNG는 저장소 밖 시각화 경로에만 있다.

## 10. 종료 체크리스트

- [x] 승인된 비교 보드 기준 반영
- [x] 왕좌 5×5 exact 좌표 고정
- [x] N/E/S/W 2셀 문턱 exact 좌표 고정
- [x] 런타임 데이터 drift assertion
- [x] 보드·개별 guide 원본 확인
- [x] 런타임 미변경
- [x] 전체 회귀·플레이 검수 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 신규 그래픽 생성
- [ ] 런타임 연결
- [ ] 커밋·푸시
