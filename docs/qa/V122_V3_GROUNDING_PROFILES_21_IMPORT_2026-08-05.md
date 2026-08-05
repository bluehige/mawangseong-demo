# V122 V3-GROUNDING-PROFILES-21-IMPORT QA

검수일: 2026-08-05
목표 버전: 제품 `1.2.2`
패킷: `V3-GROUNDING-PROFILES-21-IMPORT`
판정: **IMPORT_SIDECAR_PASS_PROFILE_PENDING**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-PROFILES-21-IMPORT
GOAL: mimic_porter PNG의 Godot import sidecar를 등록하고 텍스처 로드만 검증
ALLOWED_WRITE_PATHS:
  - assets/sprites/monsters/update4/monster_mimi_sheet.png.import
  - tools/tests/V122CombatVisualRuntimeProfileContractTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_21_IMPORT_2026-08-05.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_21_IMPORT_2026-08-05.md
  - docs/handoff/CURRENT.md
FORBIDDEN: mimic_porter 프로필 앵커 연결, 다른 캐릭터, 공통 코드, 자산 재생성, V4/V5, UI/VFX, 오디오, 다음 패킷, 전체 회귀·빌드
DIRECT_TEST: Godot headless에서 mimic_porter runtime PNG import·텍스처 로드 1종
UI_OR_AUDIO_CHECK: 없음
STOP_AFTER: sidecar와 로드 검증 및 문서 기록 후 중단
```

## 처리 내용

- `assets/sprites/monsters/update4/monster_mimi_sheet.png.import`를 추가했다.
- sidecar는 Godot UID와 destination cache `monster_mimi_sheet.png-a15643e93ea5482cb7237341a42f4104.ctex`를 가리킨다.
- `.godot/imported/` cache는 엔진 생성 파일이며 저장소 변경 대상이 아니다.
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`는 이 패킷에서 `mimic_porter`만 대상으로 삼아 import·runtime path·투명 시트·scale·VisualBody 계층을 확인한다. grounding bbox/anchor 연결은 다음 프로필 패킷에서 처리한다.
- 프로필 JSON과 `grounding_anchors`는 이번 패킷에서 변경하지 않았다.

## 직접 테스트

실행:

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30
```

결과:

```text
V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS
```

확인 항목:

- `monster_mimi_sheet.png` import sidecar와 CompressedTexture2D 로드: PASS
- `mimic_porter` runtime 경로와 Unit sprite 경로: PASS
- 실측 median art height 146.5px 기준 render scale: PASS
- 투명 sheet에 chroma-key material 미적용: PASS
- `AnimatedSprite2D`가 `VisualBody` 아래에 있고 local position이 zero: PASS

## 미해결 및 다음 패킷

`mimic_porter` idle/down 4×4 alpha bbox와 발 앵커를 JSON 프로필에 승격하는 일은 다음 `V3-GROUNDING-PROFILES-21` 패킷의 범위다. 이번 turn에는 실행하지 않았다.

전체 회귀, 전체 플레이, UI 캡처, 빌드, 커밋, 푸시는 요청되지 않아 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (미커밋 혼합 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
