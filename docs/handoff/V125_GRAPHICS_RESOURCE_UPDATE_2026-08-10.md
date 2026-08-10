# v1.2.5 그래픽 자원 보강 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-10
- 목표 버전: 1.2.5 후보의 그래픽 선행 작업
- 작업 브랜치: `codex/v124-release-candidate`
- 기준 브랜치 및 SHA: `codex/v124-release-candidate@1bbeaa2d467fe9d8fcaa3d8489096a456ce5048a`
- 마지막 커밋 SHA: `1bbeaa2d467fe9d8fcaa3d8489096a456ce5048a` (이번 변경은 미커밋)
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 1.2.5 버전업에 앞서 미흡했던 그래픽 자원 검수를 Stage 01~04 전체로 다시 수행하고 필요한 자산을 업데이트한다.
- 완료 조건: 단계별 공간 차별화, 검은 외곽 제거, 시설 색 조화, 입구 HUD 잘림 해소, 전투 유닛 가독성 유지, 관련 그래픽 테스트 통과.
- 범위에서 제외한 사항: 버전 번호 변경, Windows 정식 export, Git 태그·Release, 직전 전체 검수의 비그래픽 P1/P2 수정, 반복 전체 회귀.

## 3. 완료한 작업

- 구현: 렌더러가 현재 성장 단계의 배경·통로 atlas·바닥·벽·시설 색조·외곽 마스크를 선택하도록 일반화했다.
- 스토리 및 데이터: 스토리는 변경하지 않았다. Stage 02~04 시각 프로필과 전용 공간 자산 연결을 manifest에 추가했고 Stage 02를 `production`으로 승격했다.
- 밸런스: 변경하지 않았다.
- UI/UX: Stage 03·04 입구 구조물이 상단 HUD 뒤로 잘리지 않도록 단계별 배치 크기와 강제 확대 여부를 분리했다.
- 저장 및 호환성: 저장 데이터 형식은 변경하지 않았다. 캡처 도구는 저장 쓰기를 비활성화했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/asset_manifest.json` | Stage 02~04 전용 배경·통로·색조·배치 연결 | 완료 |
| `data/castle_evolution_stages.json` | Stage 02 그래픽 상태를 production으로 승격 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 활성 단계별 공간 렌더와 입구 배치 지원 | 완료 |
| `tools/prepare_v125_stage_progression_assets.py` | 원본에서 런타임 배경·셀·atlas 결정적 생성 | 완료 |
| `tools/tests/V125StageProgressionVisualRuntimeTest.gd` | 자산·렌더·입구 배치 계약 검사 | 완료 |
| `tools/tests/V125StageProgressionVisualRuntimeTest.tscn` | 위 테스트 실행 씬 | 완료 |
| `tools/V125StageProgressionCombatVisualReview.gd` | Stage 02·04 인위적 전투 캡처 | 완료 |
| `tools/V125StageProgressionCombatVisualReview.tscn` | 위 캡처 실행 씬 | 완료 |
| `assets/backgrounds/v125/` | Stage 02~04 런타임 배경 3개와 import 정보 | 완료 |
| `assets/tiles/stage_02/` | Stage 02 통로 표면·셀·atlas | 완료 |
| `assets/tiles/stage_03/` | Stage 03 통로 표면·셀·atlas | 완료 |
| `assets/tiles/stage_04/` | Stage 04 통로 표면·셀·atlas | 완료 |
| `assets/source/imagegen/v125_stage_progression/` | 생성 원본 9개와 출처 기록 | 완료 |
| `docs/qa/V125_GRAPHICS_RESOURCE_AUDIT_2026-08-10.md` | 그래픽 검수 결과 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 작업 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/v125_stage_progression/backgrounds/`, `assets/source/imagegen/v125_stage_progression/corridor_surfaces/`
- `SOURCE.md` 경로: `assets/source/imagegen/v125_stage_progression/SOURCE.md`
- 런타임 최종 자산 경로: `assets/backgrounds/v125/`, `assets/tiles/stage_02/`, `assets/tiles/stage_03/`, `assets/tiles/stage_04/`
- 프롬프트/후처리/크롭/알파 처리 요약: Stage 01 카메라·중앙 여백을 기준으로 Stage 02~04 배경을 순차 강화했다. 통로 크로마 원본은 부드러운 매트와 despill로 알파화하고, 정확한 2:1 등각 셀과 16-mask atlas로 정규화했다.
- 게임 연결 및 실제 렌더 확인 결과: 관리 Stage 01~04와 인위적 전투 Stage 02·04를 Windows Godot 실행 환경의 1920×1080에서 확인했다. 단계 구분, 외곽 연결, 입구 배치, 유닛 깊이와 가독성이 의도와 일치한다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V125StageProgressionVisualRuntimeTest.tscn` | PASS | `tools/tests/V125StageProgressionVisualRuntimeTest.gd` |
| 2 | Stage 01 및 기존 그래픽 계약 테스트 6종 | PASS | `tools/tests/` |
| 3 | 관리 Stage 01~04 1920×1080 렌더 | PASS | `tmp/castle_stage_review/` |
| 4 | 인위적 Stage 02·04 전투 1920×1080 렌더 | PASS | `tmp/v125_stage_progression_combat/` |
| 5 | 생성 출처 경로·파일·중복 대조 | PASS | 원본 9 / 런타임 21 / 누락 0 / 중복 0 |
| 6 | 전체 회귀 테스트 | NOT_REQUESTED | 정식 태그 직전 1회로 유보 |

### 검수 에이전트 반복 기록

사용자가 이번 작업에서 별도 검수 에이전트를 요청하지 않았으므로 실행하지 않았다. 직접 관련 그래픽 테스트와 화면 검수만 수행했다.

- 남은 P1/P2 지적: 이번 그래픽 범위는 0건. 직전 전체 검수의 비그래픽 P1/P2는 별도 미해결 상태다.
- 실행하지 못한 필수 검수와 이유: 사용자 대표 화면 승인 전이라 Windows 정식 export와 전체 출시 검증은 실행하지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 문서만 추가했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 그래픽 범위 밖의 직전 Windows 최종 검수 P1/P2가 남아 있으므로 1.2.5 정식판으로 판정할 수 없다.
- 밸런스 관찰 항목: 없음. 이번 세션에서 밸런스를 변경하지 않았다.
- 임시 구현 또는 대체 자산: 기본 캠페인에서 사용하지 않는 일부 맵 편집용 방향별 시설 변형은 기존 기술 부채로 남는다.
- 외부 환경/도구 제약: 없음. 정식 export는 승인 경계 때문에 의도적으로 보류했다.

## 8. 다음 작업 순서

1. 사용자가 `tmp/castle_stage_review/`와 `tmp/v125_stage_progression_combat/` 대표 화면을 확인한다. 완료 조건은 Stage 02~04 성장감과 전투 가독성 승인이다.
2. 승인 후 직전 전체 검수의 비그래픽 출시 차단 항목을 한 작업흐름으로 수정한다. 예상 경로는 보상·스토리 라우팅·UI 관련 코드와 직접 테스트다.
3. 완료 SHA에서 관련 Windows 확인을 마친 뒤 제품 버전을 1.2.5로 변경하고 정식 Windows 빌드를 만든다.
4. 태그 직전에만 전체 검증 1회를 수행하고 PASS일 때 커밋·PR·태그·Release를 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v124-release-candidate`에 이번 그래픽 변경과 세션 시작 전 변경이 함께 존재한다.
- 미커밋 파일: 위 4절의 그래픽 자산·코드·도구·문서 전체.
- 의도하지 않은 기존 변경: 다수의 기존 `.import`, `project.godot`, 이전 최종 검수 문서, Playwright 캡처 폴더 및 로컬 이미지가 이미 변경·미추적 상태였으며 되돌리거나 섞지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/castle_stage_review/`, `tmp/v125_stage_progression_combat/`. 정식 빌드 없음.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 사실 기록
- [ ] 커밋 후 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
