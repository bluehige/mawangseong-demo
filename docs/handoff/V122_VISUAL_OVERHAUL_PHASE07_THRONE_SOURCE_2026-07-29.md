# v1.2.2 시각 개편 7단계 Stage 01 왕좌 생성 원본 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: exact guide 다음 작업을 진행한다.
- 완료 조건:
  - 왕좌 `SW/open_04` 생성 원본 한 종을 만든다.
  - Stage 01 유지 자산의 화풍과 exact guide의 S 2셀 입구를 함께 사용한다.
  - 초록 key를 alpha로 제거하고 출처·프롬프트를 기록한다.
  - 사용자 승인 전 런타임에 연결하지 않는다.
- 범위 제외: 문턱 4종, 복도 표면, runtime manifest/renderer, 화면·플레이·전체 QA, 빌드·커밋·푸시.

## 3. 완료한 작업

- `imagegen` 스킬과 GPT 내부 이미지 생성 경로를 사용했다.
- reference 역할을 분리했다.
  - exact guide: 5×5 footprint·SW anchor·S 2셀 입구
  - Stage 01 입구: 석재·뼈·천·온광 화풍
  - Stage 01 병영: 실내 바닥·목재 밀도
- 네 회차를 순차 생성했다.
  - 막힌 S 입구 탈락
  - 과도하게 넓은 S 입구 탈락
  - 투영이 깊은 후보는 최종 재생성용 reference로만 보존
  - guide를 edit target으로 사용한 네 번째 후보를 선택
- 선택 후보는 거친 석재·결박 목재·뼈·찢어진 적갈 천·제한된 보라 수정으로 Stage 01 화풍을 맞췄다.
- flat chroma key를 공식 helper로 제거하고 alpha 승인 후보를 만들었다.
- 런타임 자산과 manifest는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_intermediate_projection_reference.png` | 최종 재생성에 사용한 중간 디자인 reference | 보존 |
| `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_raw_chroma.png` | 선택한 GPT 생성 원본 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_alpha_preview.png` | 사용자 승인용 alpha 후보 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/SOURCE.md` | 모델·날짜·프롬프트·후처리 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE07_THRONE_SOURCE_2026-07-29.md` | 이번 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 승인 대기 상태 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본 경로:
  - `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_raw_chroma.png`
- `SOURCE.md` 경로:
  - `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/SOURCE.md`
- 런타임 최종 자산 경로: 없음
- alpha 승인 후보:
  - `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_alpha_preview.png`
- 게임 연결 및 실제 렌더 확인 결과: 미연결

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 생성 결과 원본 시각 확인 | PASS | 선택 raw chroma 원본 |
| 2 | alpha 결과 원본 시각 확인 | PASS | 선택 alpha preview |
| 3 | corner alpha 4곳 | PASS | 모두 `0` |
| 4 | greenish opaque pixel 검사 | PASS | `0` |
| 5 | alpha pixel 분류 | PASS | transparent 764,893 / partial 4,990 / opaque 802,633 |
| 6 | 런타임 관련 테스트 | NOT_REQUIRED | 런타임 미변경 |
| 7 | 전체 회귀·플레이 검수 | NOT_REQUESTED | 사용자 요청 전 보류 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 사용자 화풍 승인 전이다.
- 생성 원본의 floor·socket은 최종 runtime 정합 contact sheet와 slicing에서 exact guide에 다시 맞춰야 한다.
- alpha preview는 런타임 파일이 아니며 manifest에 연결하지 않았다.
- 문턱·복도와 함께 봤을 때 재질 빈도 또는 명암이 달라질 수 있다.

## 8. 다음 작업 순서

1. 사용자가 왕좌 후보의 화풍·재질·실루엣을 승인 또는 수정 지시한다.
2. 승인되면 같은 기준으로 N/E/S/W 문턱 4종을 한꺼번에 만들지 않고 방향별로 순차 생성한다.
3. 문턱 승인 뒤 저채도 복도 표면과 공통 폐색 그림자를 제작한다.
4. 전체 Stage 01 공간 자산 승인 뒤에만 runtime lookup과 1920·1280 정합을 적용한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 HEAD: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 이번 단계 source PNG·문서가 미커밋 상태다.
- 기존 대규모 코드·데이터·`.import` 변경은 보존했다.
- 빌드·커밋·푸시하지 않았다.

## 10. 종료 체크리스트

- [x] imagegen 스킬 사용
- [x] exact guide·Stage 01 reference 분리
- [x] 왕좌 원본 생성
- [x] S 2셀 입구 반복 보정
- [x] alpha 제거·검증
- [x] 생성 출처·프롬프트 기록
- [x] 런타임 미연결
- [x] 전체 회귀·플레이 검수 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사용자 시각 승인
- [ ] 문턱 4종 생성
- [ ] runtime 연결
- [ ] 커밋·푸시
