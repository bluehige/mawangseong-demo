# V122 V3-GROUNDING-PROFILES-19-IMPORT QA

검수일: 2026-08-05
목표 버전: 제품 `1.2.2`
패킷: `V3-GROUNDING-PROFILES-19-IMPORT`
판정: **IMPORT_SIDECAR_PASS_PROFILE_PENDING**

## 패킷 범위

```text
PACKET_ID: V3-GROUNDING-PROFILES-19-IMPORT
GOAL: stone_sentinel PNG의 Godot import sidecar를 등록하고 텍스처 로드만 검증
ALLOWED_WRITE_PATHS:
  - assets/sprites/monsters/update4/monster_dolkong_sheet.png.import
  - tools/tests/V122CombatVisualRuntimeProfileContractTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_19_IMPORT_2026-08-05.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_19_IMPORT_2026-08-05.md
  - docs/handoff/CURRENT.md
FORBIDDEN: stone_sentinel 프로필 앵커 연결, 다른 캐릭터, 공통 코드, 자산 재생성, V4/V5, UI/VFX, 오디오, 빌드·커밋·푸시
DIRECT_TEST: Godot headless에서 stone_sentinel runtime PNG import·텍스처 로드 1종
UI_OR_AUDIO_CHECK: 없음
STOP_AFTER: sidecar와 로드 검증 및 문서 기록 후 중단
```

## 처리 내용

- `assets/sprites/monsters/update4/monster_dolkong_sheet.png.import`를 기존 Update 4 텍스처 import 형식으로 추가했다.
- Godot가 해당 PNG를 `.godot/imported/monster_dolkong_sheet.png-ac2be506add0b07163e995dd559a682d.ctex`로 임포트하는 것을 확인했다. 이 파일은 엔진 생성 캐시이며 저장소 변경 대상이 아니다.
- 계약 테스트는 import 패킷에서 필요한 runtime parenting·scale·투명 시트·파일 로드만 검사하도록 보호 조건을 추가했다. 4×4 idle/down bbox와 발 앵커 선언은 다음 `V3-GROUNDING-PROFILES-19` 패킷에서 처리한다.
- `stone_sentinel` JSON 프로필과 `grounding_anchors`는 이번 패킷에서 변경하지 않았다.

## 직접 테스트

실행:

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30
```

결과:

```text
V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS
```

추가 확인:

- source PNG: `res://assets/sprites/monsters/update4/monster_dolkong_sheet.png`
- Godot import sidecar 존재: PASS
- `FileAccess.file_exists(runtime_path)`: PASS
- `AnimatedSprite2D`가 `VisualBody` 아래에 있고 local position이 zero: PASS
- transparent sheet가 chroma-key material을 재사용하지 않음: PASS

## 미해결 및 다음 패킷

`stone_sentinel`의 idle/down `[alpha bbox, foot anchor]`를 JSON 프로필에 승격하고 동일 경로를 계약 테스트로 고정하는 일은 다음 패킷 `V3-GROUNDING-PROFILES-19`의 범위다. 이번 turn에는 실행하지 않았다.

전체 회귀, 전체 플레이, UI 캡처, 빌드, 커밋, 푸시는 요청되지 않아 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (미커밋 혼합 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
