# V122 출시 마무리 핸드오프 — V3 root_tender 프로필 패킷 17

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 작업 트리)
- 패킷: `V3-GROUNDING-PROFILES-17`
- 판정: `PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING`
- QA 문서: `docs/qa/V122_V3_GROUNDING_PROFILES_17_2026-08-05.md`

## 2. 목표와 범위

`root_tender` 한 캐릭터의 4×4 투명 런타임 시트에서 idle/down 셀 발 앵커를 측정하고, 기존 `DataRegistry`의 `large_grounded` motion entry 병합과 `Unit.gd`의 AtlasTexture·VisualBody/root 기준이 그 값을 소비하는지 직접 검증했다.

공통 코드, 다른 캐릭터, 자산 재생성, UI/VFX·오디오, 전체 회귀·빌드는 범위에서 제외했다.

## 3. 완료 내용과 변경 파일

- `data/v122/combat_visual_profiles.json`
  - `root_tender` override에 `[192,192]` 프레임 크기와 idle/down 앵커를 추가했다.
  - idle `(0,0)` bbox `[47,31,152,181]`, anchor `[0.5,0.942708]`를 기록했다.
  - down `(2,0)` bbox `[21,69,175,184]`, anchor `[0.5,0.958333]`를 기록했다.
  - 원본·정규화 상태는 `NEEDS_NORMALIZATION`, 런타임 준비는 `RUNTIME_PREP_PASS`, 소비 상태는 `PENDING_V3_PROFILE_CONNECT`로 유지했다.
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`
  - 이번 패킷 대상을 `root_tender` 하나로 잠그고 위 bbox·앵커 계약을 검증하도록 갱신했다.
- `docs/qa/V122_V3_GROUNDING_PROFILES_17_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 4. 자산과 연결 상태

- 기존 런타임 PNG: `res://assets/sprites/enemies/update4/region/normalized/enemy_root_tender_sheet.png`
- 시트는 투명 배경이며 chroma-key material을 재사용하지 않는다.
- 생성 원본이나 런타임 그래픽 파일은 변경하지 않았다. 따라서 원본 권리·생성 기록은 기존 `SOURCE.md`를 그대로 따른다.

## 5. 검증 결과

| 구분 | 실행 | 결과 |
|---|---|---|
| Godot 직접 계약 | `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30` | `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS` |
| JSON·실제 PNG 측정 | root_tender 4×4 idle/down bbox 및 앵커 비교 Python 검사 | `V122_V3_ROOT_TENDER_PROFILE_JSON_TEST: PASS` |
| 공백 검사 | `git diff --check` (대상 파일) | PASS |

전체 회귀, 전체 플레이 검수, 대표 화면 확인, 빌드 및 배포는 사용자가 요청하지 않아 실행하지 않았다.

## 6. 미해결과 다음 작업

1. `NEEDS_NORMALIZATION` 원본 승격과 그래픽 소스 교체 여부는 별도 자산 패킷에서 결정한다.
2. 다음 단일 패킷은 `V3-GROUNDING-PROFILES-18`로 제안하며, `spore_healer` 한 캐릭터의 4×4 런타임 시트 idle/down 앵커를 동일한 계약으로 처리한다.
3. 다음 패킷은 이 핸드오프를 확인한 뒤에만 시작한다.

## 7. 정책 및 작업 트리

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
- 커밋·푸시: 실행하지 않음
- 작업 트리: Luna 및 기존 사용자 변경이 섞인 dirty 상태이며, 이번 패킷의 대상 파일만 수정했다.
