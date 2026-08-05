# V122 V2-P4F — 다섯 계약 캐릭터 정체성 비교 검수

검수일: 2026-08-04
대상 버전: 제품 1.2.2
패킷: `V2-P4F-VERIFY-IDENTITY`
판정: **IDENTITY_VERIFY_PASS_WITH_NORMALIZATION_PENDING**

## 패킷 카드

```text
PACKET_ID: V2-P4F-VERIFY-IDENTITY
GOAL: 다섯 계약 캐릭터의 정체성·크기 비교판 한 장만 검수하고 제품 변경 없이 결과를 기록
ALLOWED_WRITE_PATHS:
  - docs/qa/V122_V2_P4F_VERIFY_IDENTITY_2026-08-04.md
  - docs/handoff/V122_RELEASE_POLISH_V2_P4F_VERIFY_IDENTITY_2026-08-04.md
  - docs/handoff/CURRENT.md
FORBIDDEN: 제품 데이터·런타임 자산·공통 코드·씬·초상화·VFX·오디오·V3 정규화·다음 패킷
DIRECT_TEST: 다섯 캐릭터의 source/runtime 정체성·RGBA·셀 경계·중앙값·공통 발 기준선 비교와 1280×720 비교판 1장
UI_OR_AUDIO_CHECK: 없음 — 읽기 전용 자산 비교판만 확인
STOP_AFTER: 비교판 1장과 읽기 전용 직접 검수 문서화 후 중단
```

## 확인 범위와 결과

V2-P4에서 연결된 다섯 캐릭터를 source/runtime 쌍으로 읽고, 제품 파일은 수정하지 않았다. 다섯 런타임 시트는 모두 768×768 RGBA, 4×4 셀(16/16 프레임)이며 셀 외곽 알파 침범은 0이다. 원본은 모두 1254×1254이고, source와 runtime 해시는 캐릭터별로 서로 달라 같은 그림을 돌려 쓰지 않는다.

| 캐릭터 | 체격·이동 | 중앙 아트 높이(px) | 바닥 spread | runtime SHA | source SHA | 정체성 확인 |
|---|---|---:|---:|---|---|---|
| `spore_healer` | `normal_grounded` | 161.0 | 0 | `675a6497ff47ea50` | `50b729d38f28098a` | 버섯 치유사로 구분 |
| `stone_sentinel` | `large_grounded` | 170.5 | 0 | `2843186f68430475` | `bb48c0743d11506e` | 바위 골렘으로 구분 |
| `war_drummer` | `normal_grounded` | 144.0 | 1 | `50dd94d1594b62ae` | `00e1486edcdd67d4` | 해골 북 연주자로 구분 |
| `mimic_porter` | `normal_grounded` | 146.5 | 0 | `b9cec0d3405d76e6` | `92db92e6d77d1b84` | 보물상자 미믹으로 구분 |
| `moon_tracker` | `small_flying` | 125.0 | 0 | `cc3f18b342c0c934` | `3801fa7aad0f2f56` | 달빛 박쥐 정찰자로 구분 |

`war_drummer`의 셀별 바닥 차이 1픽셀은 계획의 2픽셀 허용치 안이다. 따라서 접지 실패로 판정하지 않는다. 다섯 캐릭터 모두 프로필의 의도한 체격 등급과 움직임 형태가 비교판에서 서로 구분된다.

## 발견 사항 — 다음 자산 정규화에서 처리

강한 크로마 기준(알파 24 이상, G 100 이상, R/B 25 이하)의 녹색 픽셀은 다섯 자산 모두 0이다. 다만 가장자리를 넓게 보는 저알파 진단에서는 기존 생성 시트 세 장에 잔여 녹색 계열 픽셀이 남아 있다.

| 캐릭터 | 저알파 녹색 계열 픽셀 |
|---|---:|
| `spore_healer` | 517 |
| `stone_sentinel` | 95 |
| `mimic_porter` | 55 |
| `war_drummer` | 0 |
| `moon_tracker` | 0 |

이 항목은 이번 패킷의 읽기 전용 진단 결과다. 자산·원본·연결 데이터를 고치는 것은 패킷 범위를 벗어나므로 수정하지 않았으며, V3 접지 검수 뒤 필요한 경우 캐릭터 하나씩 별도 자산 패킷으로 처리한다.

## 비교판

1280×720 비교판은 임시 경로에만 생성했으며 저장소에 추가하지 않았다.

`C:\Users\blueh\AppData\Local\Temp\v122_p4f_identity_comparison_1280x720.png`

비교판에서 다섯 실루엣과 체격 차이(소형 비행, 일반 지상, 대형 지상)가 한 화면에 겹치지 않고 읽힌다.

## 직접 실행한 검수

- Python 읽기 전용 감사: `V122_P4F_IDENTITY_DIRECT_TEST: PASS_WITH_FINDINGS`
  - source/runtime 해시 고유성, 768×768 RGBA, 4×4 셀, 셀 경계, 알파 외곽 0, 공통 바닥 기준을 확인했다.
  - findings는 위의 저알파 녹색 잔여와 `war_drummer` 1픽셀 spread이며, 후자는 허용치 이내다.
- Godot: `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- `git diff --check`: PASS

전체 회귀, 전체 플레이, 빌드, 커밋, 푸시는 요청 범위가 아니므로 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (혼합 미커밋 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
