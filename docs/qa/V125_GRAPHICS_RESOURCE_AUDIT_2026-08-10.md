# v1.2.5 그래픽 자원 보강 검수서

- 작성일: 2026-08-10
- 대상 브랜치: `codex/v124-release-candidate`
- 기준 커밋: `1bbeaa2d467fe9d8fcaa3d8489096a456ce5048a`
- 대상 플랫폼: Windows 정식판의 Godot 렌더 경로
- 검수 범위: 마왕성 관리·전투 화면의 Stage 01~04 공간 그래픽, 유닛 가독성, 구조물 배치
- 판정: **그래픽 작업흐름 TARGETED_PASS / 1.2.5 정식 출시 판정 아님**

## 1. 다시 검수한 이유

직전 Windows 최종 검수의 그래픽 항목은 실제로 Stage 01 대표 화면만 확인했다. 따라서 Stage 02~04가 같은 동굴 배경과 회색 통로를 반복하고, 후반 시설만 화면 위에 추가되는 문제를 발견할 수 없는 범위였다. 이 상태에서 그래픽 P1/P2가 없다고 결론 내린 것은 검사 범위가 부족했다.

이번에는 관리 화면 Stage 01~04 전체와 인위적으로 구성한 Stage 02·04 전투 화면을 1920×1080으로 직접 렌더해 비교했다. 버전 번호 변경과 정식 빌드는 하지 않았다.

## 2. 발견 사항과 수정 결과

| 항목 | 기존 상태 | 이번 수정 | 결과 |
|---|---|---|---|
| 단계 구분 | Stage 01~04가 사실상 같은 동굴 배경을 공유 | Stage 02 성곽, Stage 03 요새, Stage 04 최종 성채 전용 배경 추가 | 시설 수가 아니라 공간 자체로 성장 단계 식별 가능 |
| Stage 02 자산 상태 | `production_fallback_v3` | 전용 배경·통로 연결 후 `production`으로 승격 | 임시 자산 상태 해소 |
| 통로 재질 | Stage 02~04가 범용 회색 바닥 반복 | 단계별 2:1 등각 통로와 16방향 연결 atlas 추가 | 성곽→요새→흑요 성채의 재질 변화 확보 |
| 화면 외곽 | 맵 주변에 검은 직사각형 여백이 드러남 | 단계별 배경과 기존 검증된 외곽 마스크의 색 보정 연결 | 화면 끝이 동굴·성채 공간으로 자연스럽게 이어짐 |
| 시설 색 조화 | 후반 보라·금색 시설이 회색 맵에서 과도하게 튐 | 단계별 바닥·벽·시설 색조 보정 | 배경과 시설의 명암·색온도 통일 |
| 입구 구조물 | Stage 03·04 입구가 상단 HUD 뒤로 잘림 | 단계별 크기 제한과 전체 격자 강제 확대 해제 | 입구 전체가 방 안에 들어오고 HUD와 분리됨 |
| 유닛 깊이 | 과거 바닥 뒤로 밀리거나 벽을 완전히 무시한 회귀 위험 | 기존 `바닥 < 유닛 < 반투명 전면 벽` 깊이 계약 유지 | 전투 유닛이 바닥 위에서 보이고 전면 벽에는 반투명하게 가림 |

## 3. 새 그래픽 자원

GPT 내부 이미지 생성으로 원본 9개를 만들고, 결정적 후처리 도구로 게임용 PNG 21개를 생성했다.

- 배경: Stage 02~04 전용 `1536×1024` 이미지 3개
- 통로: Stage별 `256×128` 기준 표면 1개, `128×64` 반복 셀 4개, `2048×256` 16-mask atlas 1개
- 통로 합계: Stage 3개 × 6개 = 18개
- 전체 런타임 이미지: 배경 3개 + 통로 18개 = 21개
- 생성 원본: 배경 선택본 3개 + 크로마 원본 3개 + 알파 선택본 3개 = 9개

출처와 프롬프트, 후처리 및 모든 원본·런타임 경로는 `assets/source/imagegen/v125_stage_progression/SOURCE.md`에 기록했다. 자동 대조 결과는 다음과 같다.

```text
source_count=9
runtime_count=21
missing=0
duplicate_paths=0
duplicate_runtime_content=0
```

## 4. 단계별 시각 목표와 확인 결과

### Stage 01 — 초기 동굴

기존의 거친 동굴, 낮은 구조벽, 초창기 시설 분위기를 유지했다. 새 단계 자산 연결로 Stage 01의 통로·문턱·유닛 깊이가 변하지 않는지 회귀 검사를 통과했다.

### Stage 02 — 초창기 성곽

정돈된 현무암 통로와 철제 고정구, 절제된 버건디 장식이 보인다. 자연 동굴에서 축조된 첫 성곽이라는 단계가 Stage 01과 분명히 구분된다.

### Stage 03 — 방어 요새

차가운 현무암, 암철 보강, 낮은 보라 수호석으로 공성 대비 요새의 무게를 강화했다. 입구 구조물은 상단 HUD 아래의 방 내부에 완전히 표시된다.

### Stage 04 — 최종 성채

흑요석·암철·얇은 고금 테두리와 절제된 보라 마력선으로 최종 단계의 위계를 만들었다. 넓은 금판이나 네온처럼 유닛보다 먼저 튀는 장식은 피했고, 전투 중 캐릭터 실루엣과 피해 숫자를 읽을 수 있다.

## 5. 실행한 관련 검증

| 검증 | 결과 | 확인 내용 |
|---|---|---|
| `V125StageProgressionVisualRuntimeTest.tscn` | PASS | 배경·통로 규격, atlas 연결, Stage 03·04 입구 배치 계약 |
| `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | Stage 01 공간 그래픽 회귀 없음 |
| `CastleStageVisualReview.tscn` | PASS | Stage 01~04 관리 화면 1920×1080 렌더 |
| `V125StageProgressionCombatVisualReview.tscn` | PASS | Stage 02·04 인위적 후반 전투 렌더와 유닛 가독성 |
| `V122VisualTextureConsistencyTest.tscn` | PASS | 텍스처 일관성 계약 |
| `V122CombatVisualProfileContractTest.tscn` | PASS | 전투 시각 프로필 계약 |
| `V122CombatVisualRuntimeProfileContractTest.tscn` | PASS | 런타임 프로필 연결 |
| `V122CombatVisualHierarchyTest.tscn` | PASS | 바닥·유닛·전면 구조물 깊이 계층 |
| `V122WallAssetCatalogTest.tscn` | PASS | 구조벽 자산 카탈로그 |

대표 캡처:

- `tmp/castle_stage_review/stage_01_cave_1920x1080.png`
- `tmp/castle_stage_review/stage_02_castle_1920x1080.png`
- `tmp/castle_stage_review/stage_03_keep_1920x1080.png`
- `tmp/castle_stage_review/stage_04_citadel_1920x1080.png`
- `tmp/v125_stage_progression_combat/stage_02_castle_combat_1920x1080.png`
- `tmp/v125_stage_progression_combat/stage_04_citadel_combat_1920x1080.png`

## 6. 판정과 남은 출시 조건

이번에 다룬 Stage 01~04 공간 그래픽 범위의 P1/P2는 0건이다. 다만 이것은 그래픽 작업흐름의 관련 검증 결과이며, 게임 전체 정식 출시 PASS가 아니다.

1. 사용자가 위 대표 화면의 방향과 단계별 분위기를 직접 확인해야 한다.
2. 승인 전에는 제품 버전을 1.2.5로 바꾸거나 Windows 정식 빌드를 만들지 않는다.
3. 직전 전체 검수에서 별도로 남은 재도전 보상, DAY 29/Update 3 대사 라우팅, UI P2 등은 그래픽 수정으로 해결되지 않는다.
4. 기본 캠페인 화면에서 사용하지 않는 일부 맵 편집용 방향별 시설 변형은 기술 부채로 남아 있으며, 현재 기본 Stage 01~04 진행을 막지는 않는다.
5. 대표 화면 승인과 별도 출시 차단 항목 수정 뒤, 정식 태그 직전에 Windows 전체 검증을 한 번만 실행한다.
