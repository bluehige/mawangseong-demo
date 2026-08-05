# v1.2.2 Luna 작업 트리 감사 결과

작성일: 2026-08-02
대상: `codex/v122-ui-simplification`의 `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` 위 미커밋 공유 작업 트리
판정: **확정 사고 수정은 대상 검수 PASS / 현재 작업 트리는 출시 승인 FAIL**

## 결론

Luna 작업에는 실제 런타임 결함과 완료 판정 오류가 함께 있었다. 즉시 안전하게 고칠 수 있는 자산 절단, 투명 이미지 색 삭제, 승급 이미지 덮어쓰기, 캡처 배율, 잘못된 계약 몬스터 전투 노출과 오디오 테스트 수량 고정은 수정했다. 반면 V3/V4를 건너뛴 V5 깊이·벽 가림은 구조 선행 조건이 없어서 숫자만 바꾸지 않고 `DEPTH_OCCLUSION_PENDING`으로 되돌렸다.

## 확인하고 수정한 사고

| 중요도 | 문제 | 원인 | 수정 |
|---|---|---|---|
| P1 | Update 4 6종의 팔·무기·이펙트가 4×4 셀 경계에서 잘림 | 셀을 먼저 자른 뒤 네 모서리만 비었는지 검사 | 전체 시트 연결 성분을 주 프레임에 배정하고, 자산별 공통 정사각 창·공통 축소율·6px 여백으로 16프레임 재포장. 셀 전체 둘레 검사 추가 |
| P1 | Update 4 6종과 실키·포포·왕관 시트의 보라색 일부가 투명해짐 | 파일명이 `_sheet.png`면 투명 RGBA에도 마젠타 셰이더를 다시 적용 | 프로필의 명시값을 우선하고, 나머지는 실제 이미지 알파 유무를 검사해 완전 불투명 legacy 시트에만 셰이더 적용 |
| P1 | 2차 승급·왕관 7종이 기본 슬라임·곱·핀 이미지로 바뀔 수 있음 | 기본 종족 프로필이 등록되지 않은 승급 sprite path까지 덮어씀 | 현재 sprite가 프로필의 runtime/legacy 경로와 정확히 일치할 때만 치환. 미등록 승급 이미지는 원래 경로 보존 |
| P1 | `moon_tracker`가 코볼트 정찰용 전체 불투명 그림으로 계약·방어전에 출전 | 전투 전용 외형이 없는데 계약 데이터에는 준비 상태 gate가 없음 | `BLOCKED_WRONG_IDENTITY_SOURCE`로 표시. 신규 후보와 방어 출전 차단, 기존 저장의 계약 소유·성장 기록은 보존하고 편성 화면에 대기 사유 표시 |
| P2 | 1280×720 캡처가 실제로는 1920×1080 논리 화면의 좌상단 2/3만 사용 | 캡처 도구가 프로젝트 논리 크기를 그대로 사용 | 다섯 캡처 도구에 1280×720 content scale을 고정하고 Update 4 6종 전용 비교판 추가 |
| P2 | 오디오 catalog 테스트가 76/68/66/10, 스킬 24, Update 3 21을 코드에 고정 | 현재 목록 자체를 계약으로 오해 | catalog와 manifest에서 수량을 계산하고, 고정 숫자 대신 ID·이벤트·상태 규칙을 검사 |
| P2 | 생성 기록이 1254×1254 크로마 원본을 런타임 형식으로 적음 | source와 connected runtime 구분 누락 | 1254 원본과 768×768 RGBA runtime, 재포장·despill·셰이더 비적용을 분리 기록 |

## 완료 판정을 취소한 항목

- Update 4 6종은 `RUNTIME_PREP_PASS`다. 최종 `NORMALIZED_PASS`는 V3에서 idle/move/attack/skill/down의 접지 흔들림을 확인한 뒤에만 확정한다.
- A1-B는 과밀 전투 clipping 0을 확인하지 않았다.
- A1-C는 관리·보스곡 130초 재생, loop seam과 소유자 청취가 없다.
- C1은 V3의 발·몸 분리가 없고 실제 1280×720 `예비동작 → 접촉 → 회복` 증거가 없다.
- V5는 catalog/frame 연결만 PASS다. Unit이 월드 Y를 제한 없이 `z_index`로 쓰고 전면 벽은 50, VFX는 `-30/3000` 같은 고정 깊이를 사용해 캐릭터 몸과 효과의 가림이 서로 달라질 수 있다. V4-A에서 실제 Unit+방향별 벽+ground/body/aerial VFX를 함께 고치고 검증해야 한다.
- 신규 suite 등록과 여러 테스트 장면은 현재 HEAD가 아니라 미커밋 작업 트리에만 있다. 현재 PASS를 커밋 SHA 승인으로 사용하지 않는다.

## 대상 검수 결과

| 검수 | 결과 |
|---|---|
| `python -m unittest tools.audio.test_audio_event_catalog -v` | 6/6 PASS |
| `python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-c` | 3 records PASS |
| 같은 명령 `--packet v1-d` | 3 records PASS |
| `V122CombatVisualProfileContractTest.tscn` | PASS |
| `V122CombatVisualRuntimeProfileContractTest.tscn` | PASS — PNG 실측 중앙값, 16셀 전체 둘레, 승급 7종, 투명 시트 material 확인 |
| `V122MoonTrackerCombatAssetGateTest.tscn` | PASS |
| `PopoCombatPhase15Test.tscn` | 20 assertions PASS |
| `SilkyCombatPhase13Test.tscn` | 24 assertions PASS |
| `Update2ContractRosterSmokeTest.tscn` | 68 assertions PASS, 종료 시 기존 resource leak 경고 있음 |
| `godot --headless --editor --quit` | parse/import PASS |
| `V122MoonTrackerGateCapture.tscn` | 1280×720 두 화면 및 gate assertions PASS |
| `git diff --check` | PASS, 줄바꿈 변환 경고만 있음 |

전체 회귀, 전체 플레이, 빌드, 커밋, 푸시는 실행하지 않았다.

## 실제 화면 근거

- Update 4 6종: `tmp/v122_release_polish/v2_p1/v2_p1_update4_runtime_contact_sheet_1280x720.png`
- 신규 계약 후보 4종: `tmp/v122_release_polish/luna_audit/moon_tracker_new_offer_gate_1280x720.png`
- 기존 루미 계약의 예비 처리: `tmp/v122_release_polish/luna_audit/moon_tracker_owned_reserve_gate_1280x720.png`

## 남은 출시 차단 항목

1. V2-P4: `spore_healer/stone_sentinel`, `war_drummer/mimic_porter`가 정체성에 맞지 않는 공유 그림을 사용한다. `moon_tracker` 전투 전용 그림도 필요하다.
2. V3: 모든 지상 캐릭터의 동작별 발 앵커와 그림자 결합을 최종 확인해야 한다.
3. V4-A/V5: 무제한 Unit 깊이와 큰 고정 VFX 깊이를 제한된 슬롯 구조로 교체하고 실제 방향별 벽 가림을 확인해야 한다.
4. A1/C1: 과밀 clipping, 장시간 BGM·loop seam 청취와 실제 접촉 화면 gate를 순서대로 완료해야 한다.

이 항목을 끝내고 최종 기능 SHA에서 관련 검수를 다시 통과하기 전에는 출시 PASS로 기록하지 않는다.
