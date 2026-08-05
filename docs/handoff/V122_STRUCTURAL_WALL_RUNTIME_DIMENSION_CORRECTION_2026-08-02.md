# V1.2.2 구조 벽 실제 화면 치수 보정 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 변경은 미커밋)
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 이전에 설명한 벽의 두께·너비·높이가 실제 화면 크기와 다르다는 지적을 바로잡고 실제 화면 기준으로 수정한다.
- 완료 조건: 원본 PNG 수치와 화면 수치를 분리하고, `1280×720` 실제 표시 크기를 자동 검사하며, Stage 01~04와 분기형 맵을 다시 렌더한다.
- 범위에서 제외한 사항: 전체 회귀·전체 플레이·출시 빌드·커밋·푸시.

## 3. 완료한 작업

- 구현: 긴 직선 원본의 8블록을 한 칸으로 압축하던 절단을 중앙 3블록 절단으로 바꿨다. 접속점 좌표와 한 칸 길이는 유지하면서 직선 몸체와 방향별 모서리·끝·T분기 폭만 재조정했다.
- 스토리 및 데이터: `wall_asset_catalog.json`에서 잘못된 `occlusion_height_px` 명칭을 `source_anchor_extent_px`로 교체했다. 이 값이 화면 높이가 아닌 원본 PNG 내부 좌표임을 명시했다.
- 밸런스: 변경 없음.
- UI/UX: `1280×720` 기준 셀 경계 간격 `19.5~20.5px`, 겹침 포함 connector span `22~22.5px`, 벽축 직각 중심 두께 `9~10px`, 중심 세로 alpha 외곽 `10~11px`, 전체 bitmap 세로 외곽 `20~21.5px`로 구분해 고정했다.
- 저장 및 호환성: 접속점·anchor·catalog 자산 ID와 저장 데이터는 바꾸지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/prepare_v122_structural_wall_kit_v2.py` | 직선 절단 범위와 모서리·끝·T분기 폭 보정 | 완료 |
| `assets/tiles/cave_v2/structural_walls_v2/*.png` | 기존 GPT 원본에서 런타임 구조 벽 14종 재절단 | 완료 |
| `data/dungeon_quarter/wall_asset_catalog.json` | 원본 좌표와 실제 화면 치수 계약 분리 | 완료 |
| `scripts/dungeon_quarter/WallAssetCatalog.gd` | 새 source extent와 화면 계약 필드 검증 | 완료 |
| `tools/tests/V122StructuralWallPixelContractTest.gd` | 실제 PNG bbox와 source extent 검증 | 완료 |
| `tools/tests/V122WallAssetCatalogTest.gd` | 잘못된 source extent 거부 검사 | 완료 |
| `tools/tests/V122CorridorWallTopologyTest.gd` | 실제 렌더 공식으로 1280×720 길이·두께·높이·정점 폭 검사 | 완료 |
| `docs/design/v122/V122_STRUCTURAL_WALL_RESOURCE_CONTRACT_2026-08-01.md` | 잘못된 80px 설명을 실제 화면 계약으로 교정 | 완료 |
| `assets/source/imagegen/v122_structural_wall_kit_v2/SOURCE.md` | 재절단 범위·날짜·목표 화면값 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 보정에서는 새로 생성하지 않음. 2026-08-01에 만든 GPT 내부 이미지 생성 원본을 재사용함.
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/v122_structural_wall_kit_v2/`
- `SOURCE.md` 경로: `assets/source/imagegen/v122_structural_wall_kit_v2/SOURCE.md`
- 런타임 최종 자산 경로: `assets/tiles/cave_v2/structural_walls_v2/`
- 프롬프트/후처리/크롭/알파 처리 요약: alpha 원본의 중앙 `(730, 250, 1030, 680)`을 사용하고 직선 폭 `177px`, 모서리 `132px`, 끝 `90px`, T분기 `156px`로 재절단했다. 접속점과 팔레트는 유지했다.
- 게임 연결 및 실제 렌더 확인 결과: Stage 01~04와 custom branch map을 각각 `1280×720`로 다시 캡처했고 열린 통로에 구형 문틀·석주가 돌아오지 않은 것을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `CorridorTopologyBuilderTest.tscn` | PASS | Godot 출력 |
| 2 | `V122WallAssetCatalogTest.tscn` | PASS | Godot 출력 |
| 3 | `V122StructuralWallPixelContractTest.tscn` | PASS, 223 assertions | Godot 출력 |
| 4 | `V122CorridorWallTopologyTest.tscn` | PASS | Godot 출력 |
| 5 | `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS | Godot 출력 |
| 6 | `V122StructuralWallCapture.tscn` | PASS | `tmp/v122_structural_wall_review/` |
| 7 | 전체 회귀·전체 플레이 | NOT_REQUESTED | 실행하지 않음 |

Related tests: 구조 생성기, 자산 catalog, PNG 픽셀, 실제 화면 치수, Stage 01~04·custom topology 관련 테스트 통과
UI check: Stage 01~04와 custom branch map을 `1280×720`로 실제 렌더해 연결 벽과 빈 통로를 확인
Unresolved issues: 사용자의 최종 시각 판정 대기, 전체 회귀·전체 플레이는 요청되지 않아 실행하지 않음

- 최종 런타임 수치 출력: 셀 경계 `20.04px`, connector `22.28px`, 벽축 직각 중심 두께 `9.16px`, 중심 세로 alpha 외곽 `10.41px`, 전체 bitmap 세로 외곽 `20.60px`

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 화면 계약은 16:9 `1280×720` 대표 화면 기준이다. 다른 화면 비율은 이번 최소 검수 범위가 아니다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음. 기존 GPT 생성 원본을 결정적으로 재절단했다.
- 외부 환경/도구 제약: 없음.

## 8. 다음 작업 순서

1. 사용자가 `tmp/v122_structural_wall_review/stage_01_cave_1280x720.png`에서 보정된 벽의 체감 두께와 중심 세로 외곽을 판정한다.
2. 추가 시각 피드백이 있으면 `tools/prepare_v122_structural_wall_kit_v2.py`의 source crop과 본체 폭만 조정하고 같은 다섯 관련 테스트와 대표 화면을 다시 확인한다.
3. 사용자가 요청할 때만 전체 검수·빌드·커밋·푸시를 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification...origin/codex/v122-ui-simplification [ahead 1]`, 다수의 기존 미커밋·미추적 파일과 이번 변경이 함께 존재함.
- 미커밋 파일: 이번 구조 벽 자산·catalog·검증 코드·테스트·문서.
- 의도하지 않은 기존 변경: 이전 시각 개편과 전투 작업의 `.import`, 코드, 데이터, 자산 변경을 보존함.
- 스태시 또는 별도 작업공간: 사용하지 않음.
- 빌드/캡처 산출물 위치: `tmp/v122_structural_wall_review/` (커밋 대상 아님).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀는 실행하지 않았다고 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋 (요청되지 않음)
- [ ] 원격 푸시 및 PR/태그 상태 기록 (요청되지 않음)
