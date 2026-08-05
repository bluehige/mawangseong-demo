# 현재 작업 핸드오프

최종 갱신: 2026-08-06

이 파일은 다음 세션의 단일 진입점이다.

## 2026-08-06 방 지침 가독성 확대 Fix3 — 현재 최우선 상태

- 최신 권위 핸드오프: `docs/handoff/V122_ROOM_DIRECTIVE_READABILITY_2026-08-06.md`
- 현재 브랜치/커밋 HEAD: `codex/v122-ui-simplification` / `a0973152132b725d7dc4631c1837386fce3244b4`
- 사용자 검수에서 방 지침 선택 글자와 펼침 목록이 너무 작다는 결함을 확인했다. 원인은 1920 가상 좌표계의 13px 글자·36px 버튼이 1280 화면에서 축소되어 체감 약 9px로 표시된 것이다. 오른쪽 패널 폭은 충분했다.
- 현재 미커밋 수정은 전체 전술·방 지침 선택 글자와 펼침 목록을 13px에서 20px, 버튼 높이를 36px에서 46px로 키웠다. 구역 제목은 17px, 설명은 14px로 올리고 지침 패널을 32px 늘려 아래 시설·추가 작전 영역을 같은 만큼 내렸다.
- 수정 전 1280×720 캡처 테스트에서 `height=36`, `button_font=13`, `popup_font=13` 실패를 재현했다. 수정 후 실제 Vulkan 1280×720에서 버튼·펼침 목록·튜토리얼 강조 링·설명·아래 시설 패널이 겹치지 않고 모두 표시됐다.
- `TutorialUxCapture`, `TutorialFlowSmokeTest`, `V122ManagementInteractionTest`, 모바일 터치 UI 84 assertions가 PASS다. Windows release export, ZIP 엔트리 검증, 1280×720 10초 부팅도 PASS다.
- Fix3에는 직전 깊이·벽 수정도 함께 들어 있다. 전역 깊이는 `바닥 0 < 유닛 1..44 < 전면 벽 50`, N/W 후면 벽은 0.94, E/S 전면 벽은 0.46 반투명이다.
- 사용 금지: `WallFix`, `WallTransparency`는 REJECTED다. `UnitAboveFloor-Fix2`는 깊이 수정은 유효하지만 작은 방 지침 때문에 SUPERSEDED됐으므로 더 이상 테스트하지 않는다.
- 현재 유일한 Windows 사용자 테스트 빌드는 `tmp/v122_room_directive_readable_fix3/20260806_013913/MawangCastle-v1.2.2-DirectiveReadable-Fix3-Windows.zip`이다. ZIP SHA-256은 `31751D1CCFFA99A2C43636194E34E7ABDF73CC790E4F46924C497F1C54EC40DF`다.
- 다음 단계는 사용자가 Fix3에서 방 지침 가독성과 초반 전투의 유닛·벽 깊이를 함께 확인하는 것이다. 화면 승인 전에는 공식 Full 검수·커밋·푸시·PR·태그·Release를 재개하지 않는다.

## 2026-08-05 SOL 최종 Windows 후보 — 구조벽 결함 발견 전 직전 상태

- 최신 권위 핸드오프: `docs/handoff/V122_SOL_FINAL_AUDIO_WINDOWS_RC_2026-08-05.md`
- 현재 브랜치/HEAD: `codex/v122-ui-simplification` / `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- SOL 연속 마무리로 시각·UI·오디오·성능·Windows 후보 범위를 처리했다. 아래의 기존 Luna 패킷 상태와 과거 `FAIL` 판정은 역사 기록이며 현재 상태를 덮어쓰지 않는다.
- Lyria 3 최종 유료 생성은 성공 11회, 재시도 0회, 최대 USD 0.56이다. 최종 묶음 31개를 런타임·출처 기록에 승격했고 API 키 패턴은 저장소에서 0건이다.
- 최종 오디오 catalog는 116 assets / 108 events / 106 actual runtime / 10 intentional legacy unresolved다.
- export PCK에서 오디오·VFX가 누락으로 오판되던 `FileAccess.file_exists()` 경로를 `ResourceLoader.exists()`로 수정하고 회귀 테스트를 추가했다.
- 최종 Full core verification은 2026-08-05 23:00~23:20 KST에 156/156 PASS, 1153.01초다. 근거는 `tmp/core_verification/latest.json`이다.
- Windows 후보는 1920×1080 부팅 오류 0건, File/Product version `1.2.2.0`, ZIP 내부 2개 파일 SHA-256 일치 상태다.
- 사용자 전달 후보: `tmp/v122_release_candidate/20260805_225608/MawangCastle-v1.2.2-Windows.zip`
- 해시 목록: `tmp/v122_release_candidate/20260805_225608/SHA256SUMS.txt`
- 10분 Windows Vulkan 성능은 평균 59.996 FPS, frame p95 19.51ms, 정적 메모리 증가 3.36MB로 PASS다.

### 현재 남은 승인·외부 gate

1. 사용자가 후보 EXE의 성 이름 입력란에서 물리 한/영 키 한글 조합, 조합 중 Backspace, Enter 확정을 확인한다.
2. 사용자가 커밋·푸시·PR·병합·`v1.2.2` 태그·GitHub Release 진행을 최종 승인한다.
3. 승인 뒤 의도한 파일만 스테이징해 기능 SHA를 만들고, 그 SHA에서 Full 156개를 재실행해 공식 PASS를 SHA에 묶는다.
4. `release/v1.2.2` PR을 merge commit으로 병합하고 병합 SHA에서 Windows export·부팅·해시를 재확인한 뒤 태그와 Release를 만든다.

현재 자동 범위의 P1/P2는 0/0이다. 다만 미커밋 작업 트리이므로 공식 출시 PASS·태그 상태는 아니며, 코드 서명도 `NotSigned`다.

- 제품 1.2.2 — 2.0 검증 결과 선별 통합 계약: `docs/design/v122/V122_V20_VALIDATED_TRANSPLANT_PLAN.md`
- 제품 1.2.2 P0 통합 기준 고정: `docs/handoff/V122_P0_INTEGRATION_CONTRACT_2026-07-27.md`
- 제품 1.2.2 P1 source audit·대응표 6종: `docs/handoff/V122_P1_SOURCE_AUDIT_2026-07-27.md`
- 제품 1.2.2 P2 건물 호환·전투 대상 연결: `docs/handoff/V122_P2_BUILDING_COMPATIBILITY_2026-07-27.md`
- 제품 1.2.2 P3 공간·배치 adapter: `docs/handoff/V122_P3_SPATIAL_PLACEMENT_2026-07-27.md`
- 제품 1.2.2 P4 전투 규칙 adapter: `docs/handoff/V122_P4_COMBAT_RULE_ADAPTER_2026-07-27.md`
- 제품 1.2.2 P5 DAY 1~5 기준 재현: `docs/handoff/V122_P5_DAY01_05_PARITY_2026-07-27.md`
- 제품 1.2.2 P6 관리·배치 UI 결합: `docs/handoff/V122_P6_UI_MANAGEMENT_2026-07-27.md`
- 제품 1.2.2 P7 전투 HUD·결과 UI 결합: `docs/handoff/V122_P7_UI_COMBAT_RESULT_2026-07-27.md`
- 제품 1.2.2 P8 저장·진행도 호환: `docs/handoff/V122_P8_SAVE_PROGRESSION_2026-07-27.md`
- 제품 1.2.2 P9 DAY 1~5 계산 모델 보정: `docs/handoff/V122_P9_BALANCE_MODEL_2026-07-27.md`
- 제품 1.2.2 P10 DAY 6~10 밸런스 재계산: `docs/handoff/V122_P10_BALANCE_DAY06_10_2026-07-27.md`
- 제품 1.2.2 P11 DAY 11~15 밸런스 재계산: `docs/handoff/V122_P11_BALANCE_DAY11_15_2026-07-27.md`
- 제품 1.2.2 P12 DAY 16~20 밸런스 재계산: `docs/handoff/V122_P12_BALANCE_DAY16_20_2026-07-27.md`
- 제품 1.2.2 P13 DAY 21~25 밸런스 재계산: `docs/handoff/V122_P13_BALANCE_DAY21_25_2026-07-27.md`
- 제품 1.2.2 P14 DAY 26~30 밸런스 재계산: `docs/handoff/V122_P14_BALANCE_DAY26_30_2026-07-27.md`
- 제품 1.2.2 P15 Update 2~4 콘텐츠 호환성 전수 검증: `docs/handoff/V122_P15_CONTENT_COMPATIBILITY_2026-07-27.md`
- 제품 1.2.2 P16 구현 폐쇄·금지 상태 0: `docs/handoff/V122_P16_IMPLEMENTATION_CLOSURE_2026-07-27.md`
- 제품 1.2.2 P17 출시·플랫폼 준비·사용자 최종검수 인계: `docs/handoff/V122_P17_RELEASE_READINESS_2026-07-27.md`
- 제품 1.2.2 정식 출시 마무리 Luna 순차 실행 계획: `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Luna 계획 핸드오프: `docs/handoff/V122_RELEASE_POLISH_LUNA_PLAN_2026-08-02.md`
- 제품 1.2.2 Luna 작업 트리 감사·사고 보정(현재 판정): `docs/handoff/V122_RELEASE_POLISH_LUNA_AUDIT_CORRECTION_2026-08-02.md`
- 제품 1.2.2 Luna 소형 패킷 강제 규칙: `docs/handoff/V122_LUNA_SMALL_PACKET_POLICY_2026-08-02.md`
- 제품 1.2.2 Luna V2-P4A `spore_healer` 원본 발견: `docs/handoff/V122_RELEASE_POLISH_V2_P4A_SPORE_DISCOVERY_2026-08-02.md`
- 제품 1.2.2 Luna V2-P4A `spore_healer` 기본 전투 자산: `docs/handoff/V122_RELEASE_POLISH_V2_P4A_SPORE_ASSET_2026-08-02.md`
- 제품 1.2.2 Luna V2-P4A `spore_healer` 런타임 연결: `docs/handoff/V122_RELEASE_POLISH_V2_P4A_SPORE_CONNECT_2026-08-02.md`
- 제품 1.2.2 Luna V2-P4B `stone_sentinel` 원본 발견: `docs/handoff/V122_RELEASE_POLISH_V2_P4B_STONE_DISCOVERY_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4B `stone_sentinel` 기본 전투 자산: `docs/handoff/V122_RELEASE_POLISH_V2_P4B_STONE_ASSET_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4B `stone_sentinel` 런타임 연결: `docs/handoff/V122_RELEASE_POLISH_V2_P4B_STONE_CONNECT_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4C `war_drummer` 원본 발견: `docs/handoff/V122_RELEASE_POLISH_V2_P4C_WAR_DISCOVERY_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4C `war_drummer` 기본 전투 자산: `docs/handoff/V122_RELEASE_POLISH_V2_P4C_WAR_ASSET_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4C `war_drummer` 런타임 연결: `docs/handoff/V122_RELEASE_POLISH_V2_P4C_WAR_CONNECT_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4D `mimic_porter` 원본 발견: `docs/handoff/V122_RELEASE_POLISH_V2_P4D_MIMIC_DISCOVERY_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4D `mimic_porter` 기본 전투 자산: `docs/handoff/V122_RELEASE_POLISH_V2_P4D_MIMIC_ASSET_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4D `mimic_porter` 런타임 연결: `docs/handoff/V122_RELEASE_POLISH_V2_P4D_MIMIC_CONNECT_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4E `moon_tracker` 전투 자산 발견: `docs/handoff/V122_RELEASE_POLISH_V2_P4E_MOON_DISCOVERY_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4E `moon_tracker` 기본 전투 자산: `docs/handoff/V122_RELEASE_POLISH_V2_P4E_MOON_ASSET_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4E `moon_tracker` 런타임 연결: `docs/handoff/V122_RELEASE_POLISH_V2_P4E_MOON_CONNECT_2026-08-04.md`
- 제품 1.2.2 Luna V2-P4F 다섯 계약 캐릭터 정체성 비교: `docs/handoff/V122_RELEASE_POLISH_V2_P4F_VERIFY_IDENTITY_2026-08-04.md`
- 제품 1.2.2 Luna V3 공통 바닥 root·visual body 접지 구조: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_STRUCTURE_2026-08-04.md`
- 제품 1.2.2 Luna V3 `slime`·`thief` 개별 발 앵커 측정: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_01_2026-08-04.md`
- 제품 1.2.2 Luna V3 `slime`·`thief` 개별 발 앵커 런타임 연결: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_CONNECT_01_2026-08-04.md`
- 제품 1.2.2 Luna V3 `explorer` 개별 발 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_02_2026-08-04.md`
- 제품 1.2.2 Luna V3 `trainee_hero` 개별 발 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_03_2026-08-04.md`
- 제품 1.2.2 Luna V3 `investigator` 개별 발 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_04_2026-08-05.md`
- 제품 1.2.2 Luna V3 `shieldbearer` 개별 발 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_05_2026-08-05.md`
- 제품 1.2.2 Luna V3 `engineer` 개별 발 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_06_2026-08-05.md`
- 제품 1.2.2 Luna V3 `goblin` 개별 발 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_07_2026-08-05.md`
- 제품 1.2.2 Luna V3 `imp` 비행 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_08_2026-08-05.md`
- 제품 1.2.2 Luna V3 `slime_gate_bulwark` 승급 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_09_2026-08-05.md`
- 제품 1.2.2 Luna V3 `goblin_ambush_captain` 승급 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_10_2026-08-05.md`
- 제품 1.2.2 Luna V3 `imp_flame_adept` 승급 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_11_2026-08-05.md`
- 제품 1.2.2 Luna V3 `coal_spark` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_12_2026-08-05.md`
- 제품 1.2.2 Luna V3 `dusk_courier` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_13_2026-08-05.md`
- 제품 1.2.2 Luna V3 `bronze_automaton` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_14_2026-08-05.md`
- 제품 1.2.2 Luna V3 `shadow_duelist` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_15_2026-08-05.md`
- 제품 1.2.2 Luna V3 `spore_doll` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_16_2026-08-05.md`
- 제품 1.2.2 Luna V3 `root_tender` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_17_2026-08-05.md`
- 제품 1.2.2 Luna V3 `spore_healer` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_18_2026-08-05.md`
- 제품 1.2.2 Luna V3 `stone_sentinel` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_19_2026-08-05.md`
- 제품 1.2.2 Luna V3 `stone_sentinel` import sidecar·텍스처 로드: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_19_IMPORT_2026-08-05.md`
- 제품 1.2.2 Luna V3 `war_drummer` import sidecar·텍스처 로드: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_20_IMPORT_2026-08-05.md`
- 제품 1.2.2 Luna V3 `war_drummer` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_20_2026-08-05.md`
- 제품 1.2.2 Luna V3 `mimic_porter` import sidecar·텍스처 로드: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_21_IMPORT_2026-08-05.md`
- 제품 1.2.2 Luna V3 `mimic_porter` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_21_2026-08-05.md`
- 제품 1.2.2 Luna V3 `moon_tracker` import sidecar·텍스처 로드: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_22_IMPORT_2026-08-05.md`
- 제품 1.2.2 Luna V3 `moon_tracker` 시트 앵커·런타임 검증: `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_22_2026-08-05.md`
- 제품 1.2.2 Luna V4-A 전면 벽 깊이 구조 발견: `docs/handoff/V122_RELEASE_POLISH_V4_A_DEPTH_DISCOVERY_2026-08-05.md`
- 제품 1.2.2 Luna V4-A 깊이 슬롯·전면 벽 가림 계약: `docs/handoff/V122_RELEASE_POLISH_V4_A_DEPTH_SLOT_CONTRACT_2026-08-05.md`
- 제품 1.2.2 Luna V4-B 이름·HP·피해 숫자 앵커 구조 발견: `docs/handoff/V122_RELEASE_POLISH_V4_B_UI_ANCHOR_DISCOVERY_2026-08-05.md`
- 제품 1.2.2 Luna V4-B 공통 UI 앵커 계약: `docs/handoff/V122_RELEASE_POLISH_V4_B_UI_ANCHOR_CONTRACT_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 V1-B 전투 시각 비교판·감사: `docs/handoff/V122_RELEASE_POLISH_V1_B_COMBAT_VISUAL_CAPTURE_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 V1-C Update 4 전투 시트 전처리: `docs/handoff/V122_RELEASE_POLISH_V1_C_COMBAT_RUNTIME_SPRITE_PREP_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 V1-D Update 4 전투 시트 전처리: `docs/handoff/V122_RELEASE_POLISH_V1_D_COMBAT_RUNTIME_SPRITE_PREP_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 V2-P1 Update 4 runtime 정규화: `docs/handoff/V122_RELEASE_POLISH_V2_P1_UPDATE4_RUNTIME_NORMALIZATION_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 V2-P2 핵심 아군·DAY12 1차 승급 정규화: `docs/handoff/V122_RELEASE_POLISH_V2_P2_CORE_ALLY_NORMALIZATION_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 V2-P3 일반 적·도둑 및 초기 일반 적 풀 정규화: `docs/handoff/V122_RELEASE_POLISH_V2_P3_REGULAR_ENEMY_THIEF_NORMALIZATION_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 V2-P4 반복 노출 자산 범위 게이트: `docs/handoff/V122_RELEASE_POLISH_V2_P4_RECURRING_ASSET_SCOPE_GATE_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 F0-V 시각 인벤토리: `docs/handoff/V122_RELEASE_POLISH_F0V_VISUAL_INVENTORY_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 F0-A 오디오 인벤토리: `docs/handoff/V122_RELEASE_POLISH_F0A_AUDIO_INVENTORY_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 F0-R 출시 공백 인벤토리: `docs/handoff/V122_RELEASE_POLISH_F0R_RELEASE_GAP_INVENTORY_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Q1-S 저장·복구 상세 감사: `docs/handoff/V122_RELEASE_POLISH_Q1S_SAVE_RECOVERY_AUDIT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Q1-S story overlay·후일담 autosave 경계 재현: `docs/handoff/V122_RELEASE_POLISH_Q1S_STORY_AUTOSAVE_BOUNDARY_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Q1-S Stage 04 투영 계약 재현: `docs/handoff/V122_RELEASE_POLISH_Q1S_STAGE04_PROJECTION_CONTRACT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Q1-I 입력·IME 상세 감사: `docs/handoff/V122_RELEASE_POLISH_Q1I_INPUT_IME_AUDIT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Q1-L UI·현지화·placeholder 상세 감사: `docs/handoff/V122_RELEASE_POLISH_Q1L_UI_LOCALIZATION_PLACEHOLDER_AUDIT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Q1-P 성능·메모리 상세 감사: `docs/handoff/V122_RELEASE_POLISH_Q1P_PERFORMANCE_AUDIT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 Q1-R 권리·출처·deprecated 상세 감사: `docs/handoff/V122_RELEASE_POLISH_Q1R_SOURCE_RIGHTS_DEPRECATED_AUDIT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 I1-1 타이틀·설정 대표 검수: `docs/handoff/V122_RELEASE_POLISH_I1_1_TITLE_SETTINGS_REPRESENTATIVE_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 I1-2 관리 화면 BGM·UI음 대표 검수: `docs/handoff/V122_RELEASE_POLISH_I1_2_MANAGEMENT_AUDIO_REPRESENTATIVE_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 I1-3 DAY 3 도둑·집중·혼잡 타격 대표 검수: `docs/handoff/V122_RELEASE_POLISH_I1_3_DAY3_THIEF_FOCUS_REPRESENTATIVE_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 I1-4 후반 일반 전투 대표 검수: `docs/handoff/V122_RELEASE_POLISH_I1_4_LATE_COMBAT_REPRESENTATIVE_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 I1-5 보스·최종전 음악·VFX 대표 검수: `docs/handoff/V122_RELEASE_POLISH_I1_5_BOSS_FINAL_REPRESENTATIVE_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 I1-5-OWNER-01 전투 VFX 대표 화면 검수: `docs/handoff/V122_RELEASE_POLISH_I1_5_OWNER_VFX_SCREEN_REVIEW_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 I1-5 캐릭터 표시 원인 발견: `docs/handoff/V122_RELEASE_POLISH_I1_5_ACTOR_VISIBILITY_DISCOVERY_2026-08-05.md`
- 제품 1.2.2 Luna V4-A-03 전면 앞가림 범위 보정: `docs/handoff/V122_RELEASE_POLISH_V4_A03_FRONT_OCCLUDER_SCOPE_2026-08-05.md`
  - 제품 1.2.2 Luna V5 깊이·가림 화면 재검수: `docs/handoff/V122_RELEASE_POLISH_V5_DEPTH_OCCLUSION_SCREEN_REVALIDATION_2026-08-05.md`
  - 제품 1.2.2 Luna V4-B UI 앵커 화면 재검수: `docs/handoff/V122_RELEASE_POLISH_V4_B_UI_ANCHOR_SCREEN_REVALIDATION_2026-08-05.md`
  - 제품 1.2.2 Luna I1-5 소유자 화면 재검수: `docs/handoff/V122_RELEASE_POLISH_I1_5_OWNER_SCREEN_REVALIDATION_2026-08-05.md`
  - 제품 1.2.2 정식 출시 마무리 I1-6 Stage 01~04 오디오 공백 감사: `docs/handoff/V122_RELEASE_POLISH_I1_6_STAGE_AUDIO_GAP_AUDIT_2026-08-02.md`
  - 제품 1.2.2 Luna A4 Stage 01 환경 loop 준비 감사: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_READINESS_AUDIT_2026-08-05.md`
  - 제품 1.2.2 Luna A4 Stage 01 감사 테스트 조건 정렬: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_AUDIT_TEST_ALIGNMENT_2026-08-05.md`
  - 제품 1.2.2 Luna A4 Stage 01 환경 loop 출처·승인 게이트: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_SOURCE_AUTHORIZATION_GATE_2026-08-05.md`
  - 제품 1.2.2 Luna A4 Stage 01 환경 loop 생성 시도: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_GENERATION_2026-08-05.md`
  - 제품 1.2.2 A4 Lyria 3 Pro 실제 API smoke: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LYRIA_API_SMOKE_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 환경 loop manifest 계약: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_MANIFEST_CONTRACT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 환경 loop 생성 take 01: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_GENERATION_TAKE01_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 환경 loop 청취 승인: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_LISTENING_GATE_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 환경 loop source/runtime 승격: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_PROMOTE_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 승격 후 manifest 정렬: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_POST_PROMOTE_MANIFEST_ALIGNMENT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 catalog 연결 범위 감사: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_CATALOG_CONNECT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 catalog·계약 테스트 정렬: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_CATALOG_TEST_ALIGNMENT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 runtime 연결 범위 감사: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_RUNTIME_CONNECT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 runtime 연결·계약 테스트 정렬: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_RUNTIME_CONNECT_TEST_ALIGNMENT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 01 대표 화면·청취 확인: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 02 환경 loop manifest 계약: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_MANIFEST_CONTRACT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 02 환경 loop 생성 take 01: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_GENERATION_TAKE01_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 02 환경 loop 청취 승인: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_LISTENING_GATE_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 02 환경 loop source/runtime 승격: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_PROMOTE_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 02 audio event catalog 등록: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_CATALOG_CONNECT_2026-08-05.md`
  - 제품 1.2.2 A4 Stage 02 runtime 재생 연결: `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_RUNTIME_CONNECT_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A0 오디오 manifest·승격 계약: `docs/handoff/V122_RELEASE_POLISH_A0_AUDIO_MANIFEST_CONTRACT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A0 오디오 manifest 계약 재검증: `docs/handoff/V122_RELEASE_POLISH_A0_AUDIO_MANIFEST_CONTRACT_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A1-A 오디오 자산·이벤트 catalog: `docs/handoff/V122_RELEASE_POLISH_A1_A_AUDIO_EVENT_CATALOG_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A1-A 오디오 event catalog 재검증: `docs/handoff/V122_RELEASE_POLISH_A1_A_AUDIO_EVENT_CATALOG_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A1-B 오디오 버스·limiter·설정: `docs/handoff/V122_RELEASE_POLISH_A1_B_AUDIO_BUS_CONTRACT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A1-B 오디오 버스 계약 재검증: `docs/handoff/V122_RELEASE_POLISH_A1_B_AUDIO_BUS_CONTRACT_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A1-C BGM transport: `docs/handoff/V122_RELEASE_POLISH_A1_C_BGM_TRANSPORT_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A1-C BGM transport 재검증: `docs/handoff/V122_RELEASE_POLISH_A1_C_BGM_TRANSPORT_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A1-D1 효과음 voice allocator·catalog API: `docs/handoff/V122_RELEASE_POLISH_A1_D1_AUDIO_VOICE_ALLOCATOR_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A1-D1 효과음 voice allocator·catalog API 재검증: `docs/handoff/V122_RELEASE_POLISH_A1_D1_AUDIO_VOICE_ALLOCATOR_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A1-D2 GameRoot·Update 3/4 AudioDirector routing: `docs/handoff/V122_RELEASE_POLISH_A1_D2_AUDIO_DIRECTOR_ROUTING_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A1-D2 GameRoot·Update 3/4 AudioDirector routing 재검증: `docs/handoff/V122_RELEASE_POLISH_A1_D2_AUDIO_DIRECTOR_ROUTING_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A1-D3 전투·HUD AudioDirector routing: `docs/handoff/V122_RELEASE_POLISH_A1_D3_COMBAT_HUD_AUDIO_ROUTING_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A1-D3 전투·HUD AudioDirector routing 재검증: `docs/handoff/V122_RELEASE_POLISH_A1_D3_COMBAT_HUD_AUDIO_ROUTING_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 A1-E 오디오 suite 등록: `docs/handoff/V122_RELEASE_POLISH_A1_E_AUDIO_SUITE_REGISTRATION_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 A1-E 오디오 suite 등록 재검증: `docs/handoff/V122_RELEASE_POLISH_A1_E_AUDIO_SUITE_REGISTRATION_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 C1 접촉 피드백 동기화: `docs/handoff/V122_RELEASE_POLISH_C1_CONTACT_FEEDBACK_SYNC_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 C1 접촉 피드백 동기화 재검증: `docs/handoff/V122_RELEASE_POLISH_C1_CONTACT_FEEDBACK_SYNC_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 V5 전투 VFX catalog·런타임 연결: `docs/handoff/V122_RELEASE_POLISH_V5_COMBAT_VFX_CATALOG_2026-08-02.md`
- 제품 1.2.2 정식 출시 마무리 V5 전투 VFX catalog·런타임 연결 재검증: `docs/handoff/V122_RELEASE_POLISH_V5_COMBAT_VFX_CATALOG_REVALIDATION_2026-08-05.md`
- 제품 1.2.2 정식 출시 마무리 V5 전투 VFX live depth·전면 벽 연결: `docs/handoff/V122_RELEASE_POLISH_V5_COMBAT_VFX_DEPTH_LIVE_CONTRACT_2026-08-05.md`
- 제품 1.2.2 작업 범위 잠금·복구 기록: `docs/handoff/V122_WORK_SCOPE_LOCK_AND_ROLLBACK_2026-08-02.md`
- 제품 1.2.2 출시 폴리시 순서 재시작·F0 기준선 재조정: `docs/handoff/V122_RELEASE_POLISH_RESTART_F0_RECONCILIATION_2026-08-02.md`
- 제품 1.2.2 S09 UI·전투·재미 실제 플레이 검수 통합 보고: `docs/qa/V122_S09_PLAY_REVIEW_SUMMARY_2026-07-29.md`
- 제품 1.2.2 S09 그래픽 디자인 감사 통합 보고: `docs/qa/V122_S09_GRAPHIC_DESIGN_AUDIT_SUMMARY_2026-07-29.md`
- 제품 1.2.2 시각 개편 3단계 공통 UI 체계: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE03_COMMON_UI_2026-07-29.md`
- 제품 1.2.2 시각 개편 4단계 Stage 01 조사: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE04_STAGE01_DISCOVERY_2026-07-29.md`
- 제품 1.2.2 시각 개편 5단계 Stage 01 비교 보드: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE05_COMPARISON_BOARD_2026-07-29.md`
- 제품 1.2.2 시각 개편 6단계 Stage 01 exact 투영 guide: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE06_EXACT_GUIDES_2026-07-29.md`
- 제품 1.2.2 시각 개편 7단계 Stage 01 왕좌 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE07_THRONE_SOURCE_2026-07-29.md`
- 제품 1.2.2 시각 개편 8단계 Stage 01 N 문턱 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE08_THRESHOLD_N_SOURCE_2026-07-29.md`
- 제품 1.2.2 시각 개편 9단계 Stage 01 E 문턱 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE09_THRESHOLD_E_SOURCE_2026-07-29.md`
- 제품 1.2.2 시각 개편 10단계 Stage 01 S 문턱 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE10_THRESHOLD_S_SOURCE_2026-07-29.md`
- 제품 1.2.2 시각 개편 11단계 Stage 01 W 문턱 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE11_THRESHOLD_W_SOURCE_2026-07-30.md`
- 제품 1.2.2 시각 개편 12단계 Stage 01 저채도 복도 표면 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE12_CORRIDOR_SURFACE_SOURCE_2026-07-30.md`
- 제품 1.2.2 시각 개편 13단계 Stage 01 공통 폐색 그림자 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE13_OCCLUSION_SHADOW_SOURCE_2026-07-30.md`
- 제품 1.2.2 시각 개편 14단계 Stage 01 암벽 가장자리 마스크 생성 원본: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE14_EDGE_MASK_SOURCE_2026-07-30.md`
- 제품 1.2.2 시각 개편 15단계 Stage 01 공간 자산 런타임 연결: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE15_SPATIAL_RUNTIME_2026-07-30.md`
- 제품 1.2.2 그래픽 통일 Phase 0~2 기준선·기술 시험: `docs/handoff/V122_VISUAL_UNIFICATION_PHASE0_2_BASELINE_2026-08-01.md`
- 제품 1.2.2 그래픽 통일 Phase 3 도로 시안: `docs/handoff/V122_VISUAL_UNIFICATION_PHASE3_ROAD_PROOF_2026-08-01.md`
- 제품 1.2.2 그래픽 통일 Phase 4 도로 런타임 미리보기: `docs/handoff/V122_VISUAL_UNIFICATION_PHASE4_ROAD_RUNTIME_PREVIEW_2026-08-01.md`
- 제품 1.2.2 그래픽 통일 Phase 5~8 연결 도로·통로 런타임 교체: `docs/handoff/V122_VISUAL_UNIFICATION_PHASE5_8_ROAD_PASSAGE_RUNTIME_2026-08-01.md`
- 제품 1.2.2 도로·통로 리소스 수정 및 구현 브리핑: `docs/design/v122/V122_ROAD_AND_PASSAGE_RESOURCE_IMPLEMENTATION_BRIEF_2026-08-01.md`
- 제품 1.2.2 그래픽 통일 Phase 10~13 Stage 01 텍스처 필터·해상도 일관성: `docs/handoff/V122_VISUAL_UNIFICATION_PHASE10_13_TEXTURE_FILTER_2026-08-01.md`
- 제품 1.2.2 Stage 01 던전 통로 구조·연속 석벽 수정: `docs/handoff/V122_DUNGEON_CORRIDOR_TOPOLOGY_FIX_2026-08-01.md`
- 제품 1.2.2 Stage 01~04·사용자 맵 공용 던전 통로·연속 벽 구조: `docs/handoff/V122_SHARED_DUNGEON_CORRIDOR_ARCHITECTURE_2026-08-01.md`
- 제품 1.2.2 구조 벽 자산 분류·연결 시스템: `docs/handoff/V122_STRUCTURAL_WALL_ASSET_SYSTEM_2026-08-01.md`
- 제품 1.2.2 연결 통로 공백·회흑색 구조 벽 V2: `docs/handoff/V122_STRUCTURAL_WALL_V2_EMPTY_OPENINGS_GRAY_PALETTE_2026-08-01.md`
- 제품 1.2.2 구조 벽 실제 화면 치수 보정: `docs/handoff/V122_STRUCTURAL_WALL_RUNTIME_DIMENSION_CORRECTION_2026-08-02.md`
- 제품 1.2.2 구조 벽 V3 상대 비율 보정: `docs/handoff/V122_STRUCTURAL_WALL_V3_RELATIVE_SCALE_CORRECTION_2026-08-02.md`
- 2026-08-02 구조 벽의 현재 기준은 `cave_v2_boundary_v3`다. 절대 화면 픽셀이 아니라 현재 맵 한 칸의 사선 길이 `E`를 기준으로 하며, 실제 직선벽은 길이 `1.13975E`, 중심 단면 높이 `1.60347E`, 낮은 전면 가림 `0.45662E`다. `connected` 통로는 완전 공백으로 두고 `closed`와 `open_placeholder`만 높은 4단 회흑색 벽으로 막는다. 전체 벽 몸체는 유닛 뒤에 한 번, 남·동쪽 낮은 가림만 유닛 앞에 그린다. 긴 팔이 붙은 정점 이미지는 직선벽 위에 중복 합성하지 않고 `edge_overlap`으로 연결한다. 구조 벽 catalog·PNG 비율·텍스처 축소 표시·Stage 01~04와 custom 맵 관련 테스트 및 `1280×720` 실제 렌더가 통과했다. 범위 밖 전체 회귀·출시 빌드·푸시는 요청 전에는 진행하지 않는다.
- 제품 1.2.2 시각 개편 16단계 캐릭터 접지·전투 HUD 계층: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE16_COMBAT_HIERARCHY_2026-07-30.md`
- 제품 1.2.2 시각 개편 17단계 사용자 용어·결산 인과: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE17_RESULT_CAUSALITY_2026-07-30.md`
- 제품 1.2.2 시각 개편 18단계 DAY 1 곱 전열·후열 선택: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE18_DAY1_GOBLIN_CHOICE_2026-07-30.md`
- 제품 1.2.2 시각 개편 19단계 DAY 1 곱 선택 반응형 검증: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE19_DAY1_GOBLIN_RESPONSIVE_2026-07-30.md`
- 제품 1.2.2 시각 개편 20단계 DAY 1 곱 선택 실제 플레이 비교: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE20_DAY1_GOBLIN_PLAY_COMPARE_2026-07-30.md`
- 제품 1.2.2 시각 개편 21단계 튜토리얼 안내 수준·비차단 등록: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE21_TUTORIAL_GUIDANCE_LEVELS_2026-07-30.md`
- 제품 1.2.2 시각 개편 22단계 Stage 10 한국어·영어 카탈로그: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE22_STAGE10_LOCALIZATION_2026-07-30.md`
- 제품 1.2.2 시각 개편 23단계 Stage 10 안내 기록·독립 연습: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE23_STAGE10_PRACTICE_2026-07-30.md`
- 제품 1.2.2 시각 개편 24단계 Stage 11 DAY 2~3 파급 수정: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE24_STAGE11_DAY02_03_CASCADE_2026-07-30.md`
- 제품 1.2.2 시각 개편 25단계 Stage 11 DAY 4~5 파급 수정: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE25_STAGE11_DAY04_05_CASCADE_2026-07-30.md`
- 제품 1.2.2 시각 개편 26단계 Stage 12 누적 UI 통합 검수: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE26_STAGE12_INTEGRATION_2026-07-30.md`
- 제품 1.2.2 시각 개편 27단계 Windows QA 테스트 빌드: `docs/handoff/V122_VISUAL_OVERHAUL_PHASE27_WINDOWS_QA_BUILD_2026-07-30.md`
- 제품 1.2.2 사용자 피드백 전투 오버레이 성능 수정: `docs/handoff/V122_FEEDBACK_COMBAT_OVERLAY_PERFORMANCE_2026-07-30.md`
- 제품 1.2.2 사용자 피드백 수정 Web QA 게시: `docs/handoff/V122_FEEDBACK_WEB_QA_PUBLISH_2026-07-30.md`
- 제품 1.2.2 스토리 대사 Phase 0 원본 승인 gate: `docs/handoff/V122_STORY_DIALOGUE_PHASE0_SOURCE_GATE_2026-07-30.md`
- 제품 1.2.2 스토리 대사 Phase 2 DAY 1~5 런타임·Web 테스트: `docs/handoff/V122_STORY_DIALOGUE_PHASE2_DAY01_05_RUNTIME_2026-07-30.md`
- 제품 1.2.2 스토리 대사 Phase 3 DAY 6~30 런타임·초상화·기본 엔딩: `docs/handoff/V122_STORY_DIALOGUE_PHASE3_DAY06_30_RUNTIME_2026-08-01.md`
- 제품 1.2.2 이중 전선 Phase A 레이아웃 후보: `docs/handoff/V122_DUAL_FRONT_PHASEA_LAYOUT_CANDIDATE_2026-07-29.md`
- 제품 1.2.2 이중 전선 Phase B 런타임 계약: `docs/handoff/V122_DUAL_FRONT_PHASEB_RUNTIME_CONTRACT_2026-07-29.md`
- 제품 1.2.2 이중 전선 Phase C-1 전선 진입 런타임: `docs/handoff/V122_DUAL_FRONT_PHASEC1_LANE_ENTRY_RUNTIME_2026-07-29.md`
- 제품 1.2.2 이중 전선 Phase C-2a DAY 1~5 웨이브: `docs/handoff/V122_DUAL_FRONT_PHASEC2A_DAY01_05_WAVES_2026-07-29.md`
- 제품 1.2.2 이중 전선 Phase C-2b 방어자 전용 연결로: `docs/handoff/V122_DUAL_FRONT_PHASEC2B_DEFENDER_CONNECTOR_2026-07-29.md`
- 제품 1.2.2 이중 전선 Phase C-2c 단계 확장·배치 이관: `docs/handoff/V122_DUAL_FRONT_PHASEC2C_STAGE_MIGRATION_2026-07-29.md`
- 제품 1.2.2 이중 전선 Phase C-2d 제품 기본값 활성화: `docs/handoff/V122_DUAL_FRONT_PHASEC2D_DEFAULT_ACTIVATION_2026-07-29.md`
- 제품 1.2.2 전투 집중·특성 타깃 우선순위 수정: `docs/handoff/V122_COMBAT_TARGET_PRIORITY_FIX_2026-08-01.md`
- 현재 제품 버전 체계: `docs/PRODUCT_VERSIONING.md` (`1.0 → 1.1 → 1.2 → 2.0 → 3.0 → 4.0`)
- 제품 1.2.1 전체 검증·공개 출시 진행: `docs/handoff/V12_1_PUBLIC_RELEASE_2026-07-20.md`
- 제품 1.2.1 태그 Windows LFS·PCK 오디오·부팅 검증 강화: `docs/handoff/V12_1_RELEASE_WORKFLOW_LFS_2026-07-20.md`
- 제품 1.2 이슈 #39 실제 사용자 플레이 검수·P1/P2 수정: `docs/handoff/V12_USER_PLAYTEST_QA_2026-07-20.md`
- 제품 v1.2 공개 출시·PC/모바일 Web 갱신: `docs/handoff/V12_PUBLIC_RELEASE_2026-07-16.md`
- 제품 1.2 최종 검수: `docs/handoff/V12_FINAL_REVIEW_2026-07-16.md`
- 제품 1.2 버전 체계 전환: `docs/handoff/PRODUCT_VERSION_MIGRATION_2026-07-16.md`
- 지시 전용 전투·3배속·UI·PC 한글 입력 구현: `docs/handoff/DIRECTIVE_COMBAT_IMPLEMENTATION_2026-07-16.md`
- 구현 전 원문 계획: `docs/handoff/DIRECTIVE_COMBAT_INPUT_PLAN_2026-07-16.md`
- v0.5 PC·모바일 플랫폼 성능 수정: `docs/handoff/V05_PLATFORM_PERFORMANCE_2026-07-15.md`
- v0.5 모바일 전용 PCK 최적화: `docs/handoff/V05_MOBILE_PCK_OPTIMIZATION_2026-07-15.md`
- v0.5 모바일 터치 UI 개선: `docs/handoff/V05_MOBILE_TOUCH_UI_2026-07-15.md`
- v0.5 공개 Web·모바일 플레이테스트: `docs/handoff/V05_PUBLIC_PLAYTESTS_2026-07-15.md`
- v0.5 Lyria 오디오 정식·Web·모바일 브라우저 빌드 적용: `docs/handoff/V05_LYRIA_AUDIO_BUILD_APPLICATION_2026-07-15.md`
- v0.5 Lyria 3 상황·스킬 오디오 확장: `docs/handoff/V05_LYRIA3_AUDIO_EXPANSION_2026-07-15.md`
- v0.5 Lyria 3 오디오 교체 파이프라인: `docs/handoff/V05_LYRIA3_AUDIO_PIPELINE_2026-07-15.md`
- v0.5 Steam 판매 출시 준비: `docs/handoff/V05_STEAM_RELEASE_READINESS_2026-07-15.md`
- v0.2.3 Pages provenance 수정: `docs/handoff/V02_PAGES_PROVENANCE_2026-07-14.md`
- v0.2.2 Web 릴리즈 증빙 호환: `docs/handoff/V02_RELEASE_EVIDENCE_2026-07-14.md`
- v0.2.1 입력 레이어 핫픽스·Web 릴리즈: `docs/handoff/V02_INPUT_LAYER_WEB_RELEASE_2026-07-14.md`
- v0.4 UI 입력 레이어 방어 작업: `docs/handoff/V04_INPUT_LAYER_GUARD_2026-07-14.md`
- v0.4 순차 개발 마감: `docs/handoff/V04_SEQUENTIAL_FINALIZATION_2026-07-14.md`
- v0.3 순차 개발 마감: `docs/handoff/V03_SEQUENTIAL_FINALIZATION_2026-07-14.md`
- v0.3 최신 튜토리얼 버그픽스·Web 갱신: `docs/handoff/V03_TUTORIAL_ENEMY_CLICK_WEB_2026-07-14.md`
- v0.3 소스 통합: `docs/handoff/V03_MAIN_INTEGRATION_2026-07-13.md`
- 버전별 원문 계획: `docs/design/plans/README.md`

## Luna 작업 트리 감사 보정 — 현재 권위 상태

- 현재 브랜치는 `codex/v122-ui-simplification`, 커밋 HEAD는 `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`다. Luna 구현과 이번 보정이 함께 미커밋된 혼합 작업 트리이므로 출시 승인 SHA가 아니다.
- V2-P4E 연결은 `CONNECT_PASS_WITH_NORMALIZATION_PENDING`이고 P4F 정체성 비교는 `IDENTITY_VERIFY_PASS_WITH_NORMALIZATION_PENDING`이다. V3 공통 구조는 `GROUNDING_STRUCTURE_PASS_WITH_PROFILE_FOLLOWUP`으로 기록했고, `slime`·`thief` 개별 앵커 런타임 병합은 `PROFILE_CONNECT_PASS`, `explorer`·`trainee_hero`·`investigator`·`shieldbearer`·`engineer`·`goblin`·`imp`·`slime_gate_bulwark`·`goblin_ambush_captain`·`imp_flame_adept`·`coal_spark`·`dusk_courier`·`bronze_automaton`·`shadow_duelist`·`spore_doll`·`root_tender`·`spore_healer`·`stone_sentinel`·`war_drummer`·`mimic_porter`·`moon_tracker` 앵커 측정·동일 경로 검증은 `PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING`으로 기록했다. V3 개별 roster 프로필 연결은 끝났지만 대표 동작 검수와 원본 상태 승격이 남아 있다. V4-A/B 구조·화면 패킷과 I1-5 소유자 화면 재검수는 통과했으며 실제 소유자 조작·청취 gate가 남아 있다. 순서 밖에서 선행 구현된 A0/A1/C1/V5는 보존하지만 `UNAPPROVED_WORKTREE_ONLY`로 취급한다. 과거 자동 PASS는 당시 작업 트리 참고 로그이지 현재 커밋 승인 근거가 아니다.
- 이전 감사에서 Update 4 6종의 셀 경계 절단, 투명 시트 재크로마 처리, 2차 승급·왕관 sprite fallback, 1280×720 캡처 배율을 수정했고, 잘못된 전투 원본을 쓰던 `moon_tracker`를 임시 차단했다. 현재는 `V2-P4E-CONNECT-MOON`에서 전용 시트와 `READY` 상태를 연결해 신규 후보·방어 출전을 해제했으며 기존 저장의 소유 기록은 보존한다.
- 초기 핵심 캐릭터 묶음은 `RUNTIME_PREP_PASS`까지만 인정한다. 공통 V3 구조와 `slime`·`thief`·`explorer`·`trainee_hero`·`investigator`·`shieldbearer`·`engineer`·`goblin`·`imp`·`slime_gate_bulwark`·`goblin_ambush_captain`·`imp_flame_adept`·`coal_spark`·`dusk_courier`·`bronze_automaton`·`shadow_duelist`·`spore_doll`·`root_tender`·`spore_healer`·`stone_sentinel`·`war_drummer`·`mimic_porter`·`moon_tracker`의 대상 연결은 통과했지만 원본 상태 승격·대표 동작 검수가 남아 최종 `NORMALIZED_PASS`는 아직 확정하지 않는다.
- V5는 catalog/frame과 live depth 연결, A03 이후 대표 전면 벽 깊이·가림 화면 재검수를 통과했다. 현재 Unit의 월드 Y 기반 깊이와 VFX 슬롯은 계약에 맞게 연결됐지만 출시 승인으로 승격하지 않는다.
- V4-A-01 조사에서 Unit·FrontWallLayer·N/W·E/S 벽 draw 경계를 확인했고, A03에서 전체 구조 벽 본체를 BackWallLayer로 분리했다. 방향 분리와 낮은 front occluder 자산은 유지하며 I1-5 대표 화면 앞뒤 관계 재검증까지 완료했다.
- A1-B 과밀 전투 clipping 0, A1-C 130초·loop seam·소유자 청취, C1 실제 1280×720 접촉 3단계는 아직 남아 있다. V5 선행 기록에서 빠졌던 실제 벽 가림 화면은 이번 A03·V5 재검수에서 완료했으며, 선행 자동 PASS 문구는 현재 판정으로 사용하지 않는다.
- 기존 사용자 변경과 Luna의 다른 미커밋 파일은 되돌리거나 정리하지 않았다. 전체 회귀·빌드·커밋·푸시도 이번 감사 범위에서 실행하지 않는다.

### SOL 연속 작업흐름 상태

사용자 지시에 따라 `AGENTS.md`의 Luna 소형 패킷 제한은 Luna가 실제 writer일 때만 적용하도록 바꿨다. SOL은 관련 구현·자산·테스트·문서화를 하나의 작업흐름으로 연속 처리하고, 사람만 판단할 수 있는 묶음 청취·화면 취향이나 공개 배포 같은 실제 승인 지점에서만 멈춘다. `SOL-V122-FOOTSTEPS-BATCH`에서는 거친 동굴석·다듬은 성벽석·금속 기계 통로의 3변형씩 총 9개를 생성했고 사용자가 표면별 review WAV 3개를 `전체 승인`했다. source/runtime 승격, manifest 89개, catalog 89 assets·81 events, normal/heavy·정지/비행 무음·voice 3·x3 밀도 감소 scheduler 연결을 완료했다. Lyria 19 tests, catalog 11 tests, Godot 발소리 31 assertions와 기존 오디오 회귀를 통과했다.

```text
LAST_COMPLETED_WORKSTREAM_STAGE: SOL-V122-FOOTSTEPS-RUNTIME-AND-SCHEDULER
RESULT: TARGETED_PASS
ACTIVE_WORKSTREAM_ID: SOL-V122-RELEASE-CLOSURE
NEXT_STATUS: IN_PROGRESS
NEXT_GOAL: A2·A3·A5와 Q1 출시 공백을 현재 작업 트리 기준으로 다시 대조하고, 유료 생성 전 가능한 코드·데이터·권리 정렬을 연속 처리한다.
NEXT_DIRECT_TEST: 오디오 manifest/catalog, 관련 Godot 계약, Q1 직접 검사
LATEST_QA: docs/qa/V122_SOL_FOOTSTEP_RUNTIME_AND_SCHEDULER_2026-08-05.md
LATEST_HANDOFF: docs/handoff/V122_SOL_FOOTSTEP_RUNTIME_AND_SCHEDULER_2026-08-05.md
```

- `V3-GROUNDING-PROFILES-19`는 `stone_sentinel` 앵커 연결과 동일 경로 계약 테스트까지 통과했다. 원본 정규화 승격과 대표 화면 검수는 남아 있다.
- `V3-GROUNDING-PROFILES-20`는 `war_drummer` 앵커 연결과 동일 경로 계약 테스트까지 통과했다. 원본 정규화 승격과 대표 화면 검수는 남아 있다.
- `V3-GROUNDING-PROFILES-21`는 `mimic_porter` 앵커 연결과 동일 경로 계약 테스트까지 통과했다. 원본 정규화 승격과 대표 화면 검수는 남아 있다.
- `V3-GROUNDING-PROFILES-22`는 `moon_tracker` 비행 앵커 연결과 동일 경로 계약 테스트까지 통과했다. 원본 정규화 승격과 대표 화면 검수는 남아 있다.
- `V4-A-01-DISCOVERY`는 Unit raw world-Y 깊이와 FrontWallLayer·방향별 벽 계층을 읽기 전용으로 확인했다. 이어서 `V4-A-02-DEPTH-SLOT-CONTRACT`가 유한 슬롯과 `wall_front` occlusion 조회 계약을 구현·검증했다. 실제 전면 벽 가림 화면과 VFX 연결은 남아 있다.
- `V4-B-01-UI-ANCHOR-DISCOVERY`는 이름·HP·피해 숫자가 서로 다른 고정 좌표·부모·z 계층을 사용한다는 원인을 확인했다. `V4-B-02-UI-ANCHOR-CONTRACT`와 `V4-B-03-UI-ANCHOR-SCREEN-REVALIDATION`은 공통 `foot/body/head` 앵커와 대표 1280×720 화면을 통과했다. 실제 소유자 조작 gate는 별도로 남아 있다.
- `A0-AUDIO-MANIFEST-CONTRACT` 재검증은 manifest 76/76 coverage, plan 152 requests·`$6.32`, 이전 v0.5 manifest SHA 유지, 생성·승격 명시 승인 게이트를 확인했다. 선행 A0 구현을 출시 승인으로 승격하지 않았으며 사람 청취와 실제 생성은 남아 있다.
- `A1-A-AUDIO-EVENT-CATALOG` 재검증은 manifest/catalog 76/76, event 68개, 실제 runtime 66개, `data_only` 0개, `unconnected` 10개를 확인했다. 2026-08-02 선행 문서의 54/12/10 수치는 현재 catalog와 달라 현재 승인 근거로 사용하지 않는다.
- `A1-B-AUDIO-BUS-CONTRACT` 재검증은 Music/SFX→Master, UI/Ambience→SFX, Master limiter 단일 유지, SFX 설정 전파를 12개 직접 단언과 27개 음악 상태 보조 테스트로 통과했다. 실제 청취와 출시 승인은 남아 있다.
- `A1-C-BGM-TRANSPORT` 재검증은 세 BGM import의 전진 반복, 관리·일반 전투·보스 crossfade, 설정 미리듣기 중복 방지를 27개 직접 단언과 catalog 7개 보조 테스트로 통과했다. 종료 teardown 경고와 130초 loop seam·소유자 청취는 남아 있다.
- `A1-D1-AUDIO-VOICE-ALLOCATOR` 재검증은 전역 24·일반 event 4·UI 2·발소리 3 상한, 우선순위 축출·보호·해제, catalog 연결·미등록 진단을 55개 직접 단언으로 통과했다. 실제 GameRoot·전투·HUD 호출부 이관과 소유자 청취는 남아 있다.
- `A1-D2-AUDIO-DIRECTOR-ROUTING` 재검증은 GameRoot의 공통 AudioDirector, Update 3 경보·Update 4 스킬/왕관/경쟁 보스 catalog 라우팅과 instance token 중복 차단을 126개 직접 단언으로 통과했다. 종료 teardown 경고, 전투·HUD 이관과 소유자 청취는 남아 있다.
- `A1-D3-COMBAT-HUD-AUDIO-ROUTING` 재검증은 CombatSceneController 타격·스킬음과 MultiFloorHUD 층 경보의 공통 AudioDirector 라우팅, cooldown·voice 교체·HUD 제거 정리를 9개 직접 단언으로 통과했다. 새 음원 승격·소유자 청취는 남아 있다.
- `A1-E-AUDIO-SUITE-REGISTRATION` 재검증은 오디오 계약 테스트 5개의 quick/full 등록·scene 경로와 콘텐츠 호환성 coverage 85/85를 compatibility 501개 단언 및 JSON 검사로 통과했다. Quick/Full 전체 실행과 실제 소유자 청취·권리 승인은 남아 있다.
- `C1-CONTACT-FEEDBACK-SYNC` 재검증은 일반 공격·투사체·돌진·광역의 단일 접촉 사건, 다섯 채널 순서와 x1·x2·x3 simulation frame 불변성을 23개 직접 단언으로 통과했다. 실제 화면·장시간 플레이와 V5 연결은 남아 있다.
- `V5-COMBAT-VFX-CATALOG` 재검증은 활성 VFX 34종·미해결 ID 0건, 실제 프레임·Update 4 연결, anchor·depth·강도·접근성 축소 계약을 57개 직접 단언으로 통과했다. 실제 Windows 1280×720 화면과 소유자 시각 승인은 남아 있다.
- `I1-5-OWNER-01`은 Windows Vulkan 1280×720 대표 화면을 실행해 상태 단언 11개와 캡처 4개를 통과했지만, 캐릭터·VFX의 wall_front 앞뒤 관계가 끊겨 `I1_5_OWNER_SCREEN_BLOCKED`로 닫았다. `V5-DEPTH-OCCLUSION-LIVE-CONTRACT` 보정이 필요하다.
- `V5-DEPTH-OCCLUSION-LIVE-CONTRACT`는 VFX 고정 z를 renderer 유닛 슬롯·`wall_front` 경계로 전환하고 투사체·근접·피격·burst 호출을 연결해 21개 단언을 통과했다. 대표 캡처는 생성됐지만 캐릭터가 벽에 묻혀 시각 gate는 남아 있다.
- `I1-5-ACTOR-VISIBILITY-DISCOVERY`는 I1-5 대표 장면 11개 단언·4개 캡처를 재실행하고, GameRoot 부모 draw(z=0)의 전체 벽 본체와 UnitYSort 음수 깊이 슬롯이 충돌하는 계층 불일치를 원인으로 발견했다. 코드·자산은 수정하지 않았고 다음은 `V4-A-03-FRONT-OCCLUDER-SCOPE`로 잠갔다.
- `V4-A-03-FRONT-OCCLUDER-SCOPE`는 전체 구조 벽 본체를 `BackWallLayer/CorridorBackWallCanvas`로 이동하고 E/S 낮은 `front_occluder`만 `FrontWallLayer/CorridorFrontWallCanvas`에 유지했다. 전용 계약 테스트 16개 단언과 I1-5 대표 화면 11개 단언·4개 캡처를 통과했으며 캐릭터 몸체가 다시 보인다.
- `V5-DEPTH-OCCLUSION-SCREEN-REVALIDATION`은 VFX live depth 계약 21개 단언과 A03 이후 I1-5 대표 화면 11개 단언·4개 캡처를 통과했다. 캐릭터·지면/몸/공중 VFX·FrontWall의 앞뒤 관계가 대표 1280×720에서 의도대로 보인다.
- `V4-B-03-UI-ANCHOR-SCREEN-REVALIDATION`은 UI 앵커 계약 12개 검사, 보스 대표 화면 11개 단언·4개 캡처, 피해 숫자를 발생시키는 후반 전투 대표 화면 13개 단언·5개 캡처를 통과했다. 이름·HP·피해 숫자가 공통 `head` 앵커를 따라가며 캐릭터·벽·바닥과 겹치지 않는다.
- `I1-5-OWNER-SCREEN-REVALIDATION`은 A03·V5·V4-B 이후 I1-5 보스 대표 `1280×720` 화면에서 11개 단언·4개 캡처를 통과했다. 캐릭터·VFX·UI 앞뒤 관계가 화면에서 의도대로 보이며 이전 벽 가림·VFX 분리 현상은 재현되지 않았다.
- `A4-STAGE-01-LOOP-READINESS-AUDIT`는 Stage ID와 현재 오디오 상태를 읽었고 환경 loop·발소리 자산은 없음을 확인했다. 다만 `I1StageAudioGapAudit`가 현재 존재하는 `Ambience` 버스를 없다고 단언해 4개 중 1개가 실패했으므로 stale 테스트 조건 차단으로 완료하지 않았다.
- `A4-STAGE-01-AUDIT-TEST-ALIGNMENT`는 임시 감사 장면의 Ambience 단언을 현재 `Ambience → SFX` 라우팅 계약에 맞게 정렬하고 4개 단언·실패 0건을 통과했다. Stage 01 환경 loop·발소리 자산과 event 연결은 아직 없다.
- `A4-STAGE-01-LOOP-SOURCE-AUTHORIZATION-GATE`는 A0 manifest 76개 coverage, Stage 01 loop 등록 0개, source_root 부재, `plan-only-until-owner-approval` 정책을 확인했다. 생성·비용·청취 승인이 없으므로 실제 자산 패킷은 승인 전 잠근다.
- `A4-STAGE-01-LOOP-GENERATION`은 사용자 생성 승인을 받은 뒤 Lyria 준비를 확인했지만 `google.genai`, `miniaudio`, `GEMINI_API_KEY`가 없어 생성하지 못했다. 비용 호출·임의 음원 대체는 하지 않았고 환경 준비조건 차단으로 남겼다.
- `A4-STAGE-01-LYRIA-PREREQUISITE-GATE`는 동일한 준비조건을 읽기 전용으로 재확인했고 `google.genai`, `miniaudio`, `GEMINI_API_KEY`가 없음을 기록했다. 채팅에 노출된 키는 사용하지 않았으며 외부 호출은 없었다.
- `A4-STAGE-01-LYRIA-API-SMOKE`는 전용 venv와 보안 키 전달을 준비한 뒤 `lyria-3-pro-preview` 실제 요청 1회로 기존 관리 BGM 후보를 생성했다. MP3·WAV 해시와 111.842초 스테레오 미리듣기, 키 패턴 0건을 확인했다. Stage 01 자산은 아직 manifest에 없으므로 제품 runtime에는 승격하지 않았다.
- `A4-STAGE-01-LOOP-MANIFEST-CONTRACT`는 `ambience_loop`와 `active/planned` 상태를 추가하고 `ambience_stage01_cave` 계획 항목을 v1.2.2 manifest에 등록했다. 13개 단위 테스트, 77개 manifest 검증, 유료 호출 없는 Stage 01 dry-run을 통과했다.
- `A4-STAGE-01-LOOP-GENERATION-TAKE01`은 계획된 `ambience_stage01_cave`를 Lyria 3 Pro 요청 1회로 생성했다. 112.887초 WAV와 MP3/WAV 해시·비밀 패턴 0건을 확인했으며 사람 청취와 runtime 승격은 남아 있다.
- `A4-STAGE-01-LOOP-LISTENING-GATE`는 사용자의 `승인`을 기록하고 후보 hash·WAV 형식을 재확인했다. 다음은 승인 후보 1개만 source/runtime으로 승격하는 패킷이다.
- `A4-STAGE-01-LOOP-PROMOTE`는 승인 후보 source/runtime·`SOURCE.md`·generation 기록과 manifest `active` 전환을 완료했다. v1.2.2 coverage는 통과했지만 legacy v0.5 manifest를 읽는 전체 단위 테스트 정렬이 남아 있다.
- `A4-STAGE-01-POST-PROMOTE-MANIFEST-ALIGNMENT`는 테스트 fixture를 현재 v1.2.2 manifest로 정렬하고 77개 coverage·13개 관련 단위 테스트를 통과시켰다. 음원·runtime·catalog는 변경하지 않았다.
- `A4-STAGE-01-LOOP-CATALOG-CONNECT`는 catalog와 직접 테스트를 확인했지만, catalog 추가 뒤 필요한 테스트 fixture 정렬이 허용 경로 밖이라 catalog를 변경하지 않고 BLOCKED로 닫았다.
- `A4-STAGE-01-LOOP-CATALOG-TEST-ALIGNMENT`는 `ambience_stage01_cave`를 catalog에 등록하고 `unconnected=11` snapshot을 정렬했으며 7개 catalog 계약 테스트를 통과했다. 실제 재생 연결은 다음 패킷이다.
- `A4-STAGE-01-LOOP-RUNTIME-CONNECT`는 기준 catalog 7개·MusicStateAudioTest 27개를 통과했지만, runtime 연결 후 필요한 catalog 테스트 snapshot 정렬이 허용 경로 밖이라 구현하지 않고 BLOCKED로 닫았다.
- `A4-STAGE-01-LOOP-RUNTIME-CONNECT-TEST-ALIGNMENT`는 `ambience.stage01.cave` event와 GameRoot 전용 Stage 01 ambience loop player를 연결하고 catalog snapshot을 actual_runtime 67개·unconnected 10개·event 69개로 정렬했다. Python catalog 7개와 Godot `MusicStateAudioTest` 36 assertions가 통과했으며 최종 실행에서 loader 오류·누수 경고가 없었다. 다음은 대표 화면·청취 확인이다.
- `A4-STAGE-01-LOOP-REPRESENTATIVE-CHECK`는 `1280×720` GUI에서 타이틀·이어하기·Stage 01 World Render·pause·환경 설정·복귀 전환과 Godot `MusicStateAudioTest` 36 assertions를 확인했다. 사용자가 최종 World Render의 ambience를 직접 청취해 이상을 보고하지 않아 대표 화면·전환·소유자 청취까지 `TARGETED_PASS`로 닫았다.
- `V3-GROUNDING-PROFILES-CONNECT-01`는 두 캐릭터 런타임 연결 완료 기록으로, `V3-GROUNDING-PROFILES-02`·`03`·`04`·`05`·`06`·`07`·`08`·`09`·`10`·`11`·`12`·`13`·`14`·`15`·`16`·`17`·`18`는 explorer·trainee_hero·investigator·shieldbearer·engineer·goblin·imp·slime_gate_bulwark·goblin_ambush_captain·imp_flame_adept·coal_spark·dusk_courier·bronze_automaton·shadow_duelist·spore_doll·root_tender·spore_healer의 앵커·동일 경로 검증 기록으로 보존한다. 원본 상태 승격과 나머지 개별 프로필·대표 동작 검수가 끝나기 전에는 V2 자산을 최종 `NORMALIZED_PASS`로 승격하지 않는다.
- 상세 권위 문서는 `AGENTS.md`의 `Luna 소형 패킷 강제 규칙`과 `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md` 5절이다.
- 이번 패킷의 직접 검수: `docs/qa/V122_A4_STAGE01_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`, `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`.

## 현재 실행 원칙

- 현재 활성 통합선은 `release/v1.2.2`, 구현선은 `codex/v122-*`다. 기준은 `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`다.
- `v1.2.1@c483d135b13cf9771ee43b045ba2c3dde51573ee`가 제품 원본이다. `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`은 전투·밸런스 참고, `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`은 UI 참고 기준이다.
- 기존 `release/v2.0`은 검증 참고선이며 제품에 병합하거나 커밋 범위를 cherry-pick하지 않는다. 기존 `release/v2.0-product`·`v2.0.0` 이식 지시는 v1.2.2 선별 통합 계약으로 대체됐다.
- P2에서 제품 room·module·manifest 기반 건물 호환 descriptor와 자동 검사를 추가했다. `watch_post`의 기존 전투 pressure·slow·bonus damage·공병 목표·무력화·결산 연결을 제품 ID와 기존 prop 기준으로 고정했고 건물 출시 금지 상태는 0이다.
- P3에서 제품 ModuleGraph의 room·corridor·socket route·object slot을 전투 계획 snapshot, 배치 slot, 방어 구간으로 변환했다. Stage 1~4와 custom layout, 저장 재생성 뒤 좌표 일치를 검증했고 별도 v20 지도·zone translation table은 사용하지 않는다.
- P4에서 제품 ID 기반 제한 명령 4종, 실제 anchor 범위 시설 효과, 기존 행동 우선 AI adapter, 공병·도둑 목표, object damage 돌파와 event ledger를 구현했다. DAY 1 제품 fixture와 Quick 75/75가 통과했다.
- P5에서 DAY 1~5 제품 wave·성장·경로를 사용하는 A/B/C/D fixture와 parity model을 추가했다. 각 DAY의 두 승리, 명확한 실패, 한 slot 변경의 두 metric 이상 인과와 DAY 6 제품 진행을 검증했다.
- P6에서 중앙 성 지도를 주 작업면으로 유지하면서 제품 callback 기반 주 행동·context drawer view model을 연결했다. desktop·mobile landscape 경계와 portrait 회전 안내를 고정했다.
- P7에서 제품 목표·활성 경로·예정 위협과 네 제한 명령을 실제 room/enemy/facility target에 연결했다. 명령의 이동·피해·시설 효과와 ledger 기여를 runtime에 적용하고, 결과 화면이 왕좌 피해·돌파·보물 손실의 핵심 원인을 표시하면서 기존 성장·보상·스토리·엔딩·다음 DAY를 유지한다.
- P8에서 정식 `CampaignSaveStore`의 optional payload로 battle plan·시설/몬스터 배치·마지막 확정 배치·일반/최종전 retry·명령 설정·최소 UI 상태를 저장한다. v1.2.0/v1.2.1·DAY/엔딩/Update 4·corrupt/tmp/bak fixture, 기존 저장 252 assertions, v5 migration 37 assertions와 제품 스모크가 통과했다.
- P9에서 2.0 실제 A/B ledger 10개와 제품 DAY 1~5 성장·배치 P_DPS로 계산 모델을 보정했다. 복잡도 계수와 P_EHP/P_CONTROL/P_FACILITY/P_COMMAND, wave·unit 예산식을 고정했고 최대 시간 오차 5.9030%, E_HP 피해 예산 오차 0.0001%로 ±10% gate를 통과했다.
- P10에서 DAY 6~10 sheet·A/B/C/D·seed 3·x3 gate와 제품 물리 대표 전투를 대조했다. DAY 7은 전력 지시의 과도한 병력 손실을 확인하고 방어+감시 대응으로 손실 0·도난 0을 확보했다.
- P11에서 DAY 11~15 sheet와 제품 물리 대표 전투를 대조했다. 셀렌 DAY 15는 선발대/보스 HP·시간, 예고·집중 기준·목표 압력·회복 창을 별도 phase budget으로 고정했다.
- P12에서 DAY 16~20을 Stage 02 순차 fixture로 바로잡아 원정 선택·이중 침투·봉쇄 계승·공병/로만을 검증했다. DAY 20 승리 뒤 Stage 03 9-room/왕좌 2,100 전환까지 확인했다.
- P13에서 DAY 21~25를 Stage 03·두 번째 승급 상태로 검증했다. DAY 25 총공격의 전멸성 승리를 발견하고 방어 지시로 손실 1을 확보했으며 레온 돌진·함성 phase budget을 고정했다.
- P14에서 DAY 26~30을 Stage 04까지 검증했다. DAY 29를 관리 전용으로 분리하고 DAY 28·30 두 경로, 최종 레온 3단계 phase budget, Quick 81/81을 고정했다.
- P15에서 Update 2~4의 카탈로그 52개와 필수 검사 85개, E00~E22 23개를 제품 런타임으로 전수 연결했다. 누락돼 있던 Update 4 Phase 5~36 검사 32개를 핵심 검증 스위트에 등록했고 Quick 114/114를 통과했다.
- P16에서 제품 기능군 15개의 요구 문서·데이터·runtime consumer·UI·handler·저장·결과·테스트·실행 증거를 closure matrix로 고정했다. Update 4 지역 적 6종의 임시 그래픽을 GPT 내장 이미지 생성 실자산으로 교체하고 전초기지 시험 명칭과 노출 TODO·준비 중 문구를 제품 표현으로 정리했다. 자동 폐쇄 검사 665 assertions, 금지 상태 0, Quick 115/115를 통과했다.
- P17에서 기술 버전 1.2.2, Windows file/product version 1.2.2.0, 4개 export preset과 artifact 예정명을 정합화했다. 전용 검사 84 assertions, 저장 진행, Steam setup validator, Quick 116/116이 통과했고 소스 상태를 `READY_FOR_OWNER_FINAL_QA`로 확정했다. 실제 후보 export·hash·태그·Release·배포는 만들지 않았다.
- 2026-07-28 DAY 1~2 사용자 피드백을 S00~S09로 반영해 관리·전투 UI, 직접 대상 명령, 지침 범위, 문맥형 시설 교체, 몬스터 드래그 배치, 복도 순찰, 전투 액터 숨김, DAY 2 가시 복도 안내 비가림을 구현 커밋 `d7f5051b4adda50f85aa26553c5dc2b1471f330f`로 고정했다. 상세 기록은 `docs/handoff/V122_UI_SIMPLIFICATION_S00_S09_2026-07-28.md`에 있다. 공개 QA는 `v122-ui-s09-day2-overlay-playtest` 하나만 유지하며 사용자 직접 최종검수 전에는 전체 회귀·출시 절차를 진행하지 않는다.
- 2026-07-29 공개 QA를 UI·전투·재미 세 트랙으로 실제 플레이 검수했다. 사용자 PC를 점유하지 않는 headless Chromium에서 DAY 1~2를 실제 좌표 클릭·드래그로 진행했고 Computer Use·사용자 Chrome·내부 함수·디버그 스킵은 사용하지 않았다. UI는 S09 가시 복도 비가림·클릭 진행 PASS와 `trap` 내부 ID 노출 P3 한 건, 전투는 집결 대상 선택 중 전투 종료와 건물 단위가 아닌 과도한 대상 강조 P2 두 건으로 FAIL, DAY 1 초회 재미는 평균 2.5/5로 FAIL이다. 통합 보고는 `docs/qa/V122_S09_PLAY_REVIEW_SUMMARY_2026-07-29.md`를 따른다.
- 2026-07-29 기존 1920×1080·1280×720 실제 플레이 캡처와 핵심 런타임 그래픽 원본을 UI 조형, 컬러 아트디렉션, 배경·캐릭터 통합의 세 분야로 정적 감사했다. 평균은 27.7/50이며 `GRAPHIC_DIRECTION_REVISION_REQUIRED`다. 타이틀·왕좌실·방 랜드마크의 기반 미감은 강하지만, 성 지도의 검은 셸·황금색 과잉·1280 단순 축소·픽셀아트 왕좌와 회화형 방 혼재·캐릭터 접지 부족·전투 시각 레이어 중첩을 수정해야 한다. 추가 플레이와 Computer Use는 사용하지 않았고 소스·자산은 변경하지 않았다. 통합 보고는 `docs/qa/V122_S09_GRAPHIC_DESIGN_AUDIT_SUMMARY_2026-07-29.md`를 따른다.
- 2026-07-29 시각 개편 0~3단계에서 1920 full-canvas와 1366/1280 compact 선택, 전체형 환경설정, 공통 UI 버튼 등급·상태·상단 자원 레일을 구현했다. 관리·환경설정 화면은 화면당 Primary 1개 원칙과 Primary/Tactical/Utility/Danger 역할을 따르며 대상 테스트가 PASS했다. 사용자 PC를 점유하지 않는 headless 실제 렌더 캡처는 프레임 신호를 받지 못해 `UNKNOWN`으로 남겼다. 전체 QA·빌드·커밋은 수행하지 않았고 다음 구현은 4단계 성 배경·공간 연결이다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE03_COMMON_UI_2026-07-29.md`를 따른다.
- 2026-07-29 시각 개편 4단계 조사에서 Stage 01 기본 지도가 connected background가 아닌 `QuarterDungeonRenderer + ModuleGraph + DungeonWalkMap`의 셀 조립식 구조임을 확인했다. 28×26 마스터 그리드, 방 5×5, 복도 2셀, floor/walk 88셀은 유지해야 한다. 입구·병영·회복실·보물실·건설 슬롯은 유지 후보, 픽셀 밀도가 다른 왕좌는 교체 후보로 분류했다. 추천 제작 범위는 왕좌·4방향 2셀 문턱·복도 표면·공통 폐색 그림자·가장자리 마스크만 교체하는 Option A이며 사용자 승인 전 런타임 자산은 변경하지 않는다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE04_STAGE01_DISCOVERY_2026-07-29.md`를 따른다.
- 2026-07-29 전투 구조 개편을 그래픽보다 먼저 진행하기로 확정했다. 정문 A와 서비스 침입 균열 B, 왕좌 직전 5×5 전실, A 3셀 협폭·실제 가시 6셀, B 5셀 광폭·약 25% 장거리, 측면 교체식 시설 슬롯 4개, 고정 방어구역 5개를 별도 `stage01_dual_front_candidate_01` 레이아웃으로 구현했다. 전용 `ModuleGraph` 계약 테스트는 PASS다. 현재 적 spawn과 이동이 단일 `entrance/active_route`에 묶여 있으므로 제품 기본 레이아웃은 아직 바꾸지 않았다. 다음 작업은 defense zone·시설 상태·구역 효과·명령 대상을 함께 분리하는 Phase B이며, 이후 전선별 적 진입·DAY 1~5·방어자 전용 연결로·저장 마이그레이션을 연결한 뒤 후보를 제품 기본값으로 활성화한다. 상세 내용은 `docs/handoff/V122_DUAL_FRONT_PHASEA_LAYOUT_CANDIDATE_2026-07-29.md`를 따른다.
- 2026-07-29 이중 전선 Phase B에서 A/B 복수 route, 고정 방어구역 5개, 교체식 시설 슬롯 4개를 전투 snapshot과 저장에 분리했다. 두 입구·두 통로·왕좌는 고정이지만 병영·회복실·금고 등의 시설 내용은 네 슬롯 사이에서 교체 가능하다. 시설의 `local/adjacent/lane/global` 범위와 같은 계열 최강 1개 규칙을 병영 공격·방어, 회복, 감시 감속·탐지·노출 피해, 수호핵 방어의 실제 전투 계산에 연결했다. 집결·후퇴는 방어구역, 집중은 적 instance, 시설 발동은 시설 slot을 전장에서 직접 대상으로 삼으며 zone·slot 저장과 legacy room·retry 호환을 유지한다. 관련 집중 테스트는 PASS고 전체 QA·플레이·빌드는 수행하지 않았다. 후보는 여전히 제품 기본값이 아니며 다음 작업은 전선별 적 spawn·specialist 목표 전선·DAY 1~5·방어자 전용 연결로를 묶는 Phase C다. 상세 내용은 `docs/handoff/V122_DUAL_FRONT_PHASEB_RUNTIME_CONTRACT_2026-07-29.md`를 따른다.
- 2026-07-29 이중 전선 Phase C-1에서 웨이브 schedule의 전선·실제 진입점·목표 시설·이탈점 계약을 실제 적 생성에 연결했다. 일반 적은 지정된 A/B 전선에서 생성되고, 도둑은 금고 슬롯 전선으로 들어와 같은 전선으로 이탈하며, 공병은 목표 시설 슬롯 전선으로 들어와 무력화 뒤 그 전선의 왕좌 공격에 합류한다. 출현 6초 전 적·전선·진입점·목표를 예고하고 전선별 돌파 깊이를 결과 ledger에 기록한다. 전용 적 생성 소비자, 기존 DAY 1~5 parity, 명령·전투 UI, zone·저장 호환 테스트는 PASS다. 후보는 여전히 제품 기본값이 아니며 기존 wave의 무지정 일반 적은 A 전선으로 호환 실행된다. 다음 작업은 후보 전용 DAY 1~5 양면 wave와 DAY 3 방어자 전용 연결로다. 상세 내용은 `docs/handoff/V122_DUAL_FRONT_PHASEC1_LANE_ENTRY_RUNTIME_2026-07-29.md`를 따른다.
- 2026-07-29 이중 전선 Phase C-2a에서 후보 전용 DAY 1~5 웨이브를 별도 카탈로그로 추가하고 현재 레이아웃 ID에 따라 실제 전투가 선택하게 연결했다. DAY 1은 A 전선만 사용하고, DAY 2는 8초 B 전선 도둑 경고 뒤 14초 침입과 22~30초 A/B 동시 증원을 사용한다. DAY 3~5는 총 적 수 5→6→8로 양면 압력을 높이되 연결로 보유를 전투 시작 조건으로 사용하지 않는다. 기존 `data/waves.json`, 기존 레이아웃, 후보 DAY 6 이후는 바뀌지 않으며 관련 전용·기존 parity·전선·시설 소비자 테스트는 PASS다. 실제 체감 밸런스는 사용자 플레이 피드백 전까지 미확정이고 후보도 여전히 제품 기본값이 아니다. 다음 작업은 DAY 3 방어자 전용 연결로다. 상세 내용은 `docs/handoff/V122_DUAL_FRONT_PHASEC2A_DAY01_05_WAVES_2026-07-29.md`를 따른다.
- 2026-07-29 이중 전선 Phase C-2b에서 DAY 3 금화 1000·마나 100의 영구 방어자 전용 연결로를 구현했다. 연결로는 공용 `ModuleGraph`와 적 walk map에 추가하지 않고, 건설 뒤 방어 몬스터가 반대 전선으로 이동할 때만 경로와 보행면으로 사용한다. 관리 되돌리기·확정 저장·retry가 건설 상태와 자원을 보존하며 필드가 없는 구저장은 미건설 상태로 열린다. 연결로·적 경로·레이아웃·저장·관리·기존 전투 집중 테스트는 PASS다. 후보의 Stage 2~4 확장 모듈과 후보 방/통로 좌표가 일부 겹치는 사실을 확인했으므로 후보는 여전히 제품 기본값이 아니다. 다음 작업은 후보 전용 room descriptor와 Stage 2~4 확장·시설 socket migration이다. 상세 내용은 `docs/handoff/V122_DUAL_FRONT_PHASEC2B_DEFENDER_CONNECTOR_2026-07-29.md`를 따른다.
- 2026-07-29 이중 전선 Phase C-2c에서 후보 전용 Stage 2~4 room·branch corridor·시설 slot·grid override를 추가해 기존 확장 모듈과 후보 방/통로의 좌표 중복을 제거했다. 두 입구·두 주 통로·왕좌와 Stage 1의 A/B 전선 경로는 Stage 4까지 고정했고, 기존 `watch_post_01`·`ward_core_01`·`slot_02`·`elite_garrison_01`·`slot_03` ID를 보존하면서 각 시설 슬롯과 방어구역을 결정적으로 매핑했다. 일반 저장·구저장 정규화·retry·Stage 1~4 재생성·전선·Day 1~5 집중 테스트는 PASS다. 후보는 여전히 제품 기본값이 아니며 다음 작업은 새 게임과 기존 캠페인의 활성화·실패 fallback 정책을 고정한 뒤 기본값 전환을 별도 단계로 수행하는 것이다. 상세 내용은 `docs/handoff/V122_DUAL_FRONT_PHASEC2C_STAGE_MIGRATION_2026-07-29.md`를 따른다.
- 2026-07-29 이중 전선 Phase C-2d에서 `data/dungeon_quarter/layouts/stage01_dual_front_01.json`을 제품 기본값으로 활성화했다. 새 게임은 즉시 이중 전선으로 시작하고, 안전 체크포인트의 구형 제품 기본 레이아웃 `current_demo_v2_master_grid_01` 저장만 구조 검증 뒤 자동 전환한다. 사용자·커스텀 레이아웃은 유지하며 전환 후보 검증 실패 시 유효한 원본 레이아웃으로 fallback한다. 구형 6개 방 정밀 좌표·소켓 회귀는 `quarter_starting_layout` 픽스처로 분리했고 기본값·저장·retry·DAY 1~5·전선·시설·구형 모듈 스모크 집중 테스트는 PASS다. 전체 QA·실제 플레이·빌드·커밋은 수행하지 않았다. 상세 내용은 `docs/handoff/V122_DUAL_FRONT_PHASEC2D_DEFAULT_ACTIVATION_2026-07-29.md`를 따른다.
- 2026-08-01 DAY 3 도둑 침입 상황에서 집중 명령과 도둑 사냥꾼 특성이 이동 목표만 정하고 실제 공격·자동 스킬은 가까운 일반 적을 다시 고르는 문제를 수정했다. 집중, 도둑·부상자·금고 침입자 사냥, 코코 위험 추적, 현상금 추적이 공통 우선 타깃 경로를 사용하며 우선 타깃이 사거리 밖이면 가까운 적을 때리느라 추격을 중단하지 않는다. 집중 피해 배율은 관련 스킬과 미리보기에도 일관되게 적용된다. 관련 전투 테스트 10종과 1280×720 포함 전투 UI 계약 테스트 1종은 PASS이며 전체 회귀·실제 DAY 3 플레이·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_COMBAT_TARGET_PRIORITY_FIX_2026-08-01.md`를 따른다.
- 2026-07-29 시각 개편 5단계에서 제품 기본 이중 전선 데이터를 읽어 1920 full-canvas·1280 compact, UI 프레임 3등급, 7개 팔레트 역할, Stage 01 환경 6종·DAY 1 캐릭터 4종, 전투 합성 순서를 한 장의 2400×3000 비교 보드로 만들었다. drawer 진입 시 지도 카메라가 안전 작업영역으로 재중심되어 두 입구·두 전선·왕좌를 가리지 않는 규칙도 고정했다. 원본 해상도 시각 확인은 PASS이며 런타임 코드·데이터·자산과 빌드는 변경하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE05_COMPARISON_BOARD_2026-07-29.md`를 따른다.
- 2026-07-29 사용자의 `진행해`로 Stage 01 비교 보드 방향을 승인받고 시각 개편 6단계 exact 투영 guide를 만들었다. 실제 `IsoMath`와 제품 기본 이중 전선의 blueprint·layout에서 왕좌 5×5 `640×320`, S 2셀 socket, 문턱 2×2 `256×128`, N/W `back`·E/S `front`를 추출했다. 2400×2200 보드와 개별 1024 guide 5종을 원본 확인했고 생성 도구의 runtime drift assertion은 PASS다. 신규 그래픽·런타임·빌드는 변경하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE06_EXACT_GUIDES_2026-07-29.md`를 따른다.
- 2026-07-29 시각 개편 7단계에서 exact guide와 Stage 01 유지 자산을 기준으로 왕좌 `SW/open_04`를 네 차례 생성했다. S 2셀 개구부가 막힌 1차, 과도하게 넓어진 2차, 바닥 투영이 깊어진 3차를 제외하고 4차를 사용자 승인 후보로 선별했다. 원본 chroma와 투명 배경 preview, 생성 prompt·반복 사유·출처를 `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/`에 보존했고, preview의 네 모서리 alpha 0·green spill 0을 확인했다. 후보는 아직 manifest나 런타임에 연결하지 않았고, 사용자 화풍·재질·실루엣 승인을 기다린다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE07_THRONE_SOURCE_2026-07-29.md`를 따른다.
- 2026-07-29 사용자의 `다음꺼 진행해`를 왕좌 시각 방향 승인으로 기록하고 시각 개편 8단계 N 2셀 문턱을 생성했다. 첫 후보는 patch가 크고 황동 띠가 장애물처럼 보여 제외했고, 두 번째 후보에서 경계를 바닥 매입형 목재·제한된 황동 plate로 평탄화해 선택했다. 원본 chroma와 alpha preview, prompt·보정 사유를 `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/`에 보존했으며 네 모서리 alpha 0·green spill 0을 확인했다. 생성 결과의 alpha bbox는 guide보다 커 native `256×128` exact fit은 전체 자산 승인 뒤 slicing 단계로 유보했다. 후보는 아직 manifest나 런타임에 연결하지 않았고 사용자 N 문턱 승인을 기다린다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE08_THRESHOLD_N_SOURCE_2026-07-29.md`를 따른다.
- 2026-07-29 사용자의 `다음진행해`를 N 문턱 시각 방향 승인으로 기록하고 시각 개편 9단계 E 2셀 문턱을 생성했다. 첫 후보는 N과 같은 seam 방향으로 생성돼 제외했고, 두 번째 후보에서 seam을 좌하단→우상단으로 반전해 screen lower-right passage를 확보했다. 원본 chroma와 alpha preview, prompt·보정 사유를 `assets/source/imagegen/v122_stage01_spatial/threshold_e_2cell/`에 보존했으며 네 모서리 alpha 0·green spill 0을 확인했다. native `256×128` exact fit은 전체 자산 승인 뒤 slicing 단계로 유보했다. 후보는 아직 manifest나 런타임에 연결하지 않았고 사용자 E 문턱 승인을 기다린다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE09_THRESHOLD_E_SOURCE_2026-07-29.md`를 따른다.
- 2026-07-29 사용자의 `다음거 진행해`를 E 문턱 시각 방향 승인으로 기록하고 시각 개편 10단계 S 2셀 문턱을 생성했다. S seam은 좌상단→우하단, passage는 screen lower-left로 고정했고 upper-right 대형 slab·lower-left 소형 slab으로 N과 surface side를 반대로 배치했다. 첫 후보 중앙 목재의 녹갈색 얼룩을 발견해 보존하고, 두 번째 precise edit에서 형상은 유지한 채 적갈 목재로 교정했다. 원본 chroma와 alpha preview, prompt·보정 사유를 `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/`에 보존했으며 네 모서리 alpha 0·green spill 0을 확인했다. native `256×128` exact fit은 slicing 단계로 유보했고 런타임에는 연결하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE10_THRESHOLD_S_SOURCE_2026-07-29.md`를 따른다.
- 2026-07-30 사용자의 `다음 진해ㅇ`을 S 문턱 시각 방향 승인으로 기록하고 시각 개편 11단계 W 2셀 문턱을 생성했다. W seam은 좌하단→우상단, passage는 screen upper-left로 고정했고 upper-left 소형 corridor slab·lower-right 대형 room slab으로 E와 surface side를 반대로 배치했다. 첫 후보가 형상·재질을 모두 지켜 선택했으며 원본 chroma와 alpha preview, prompt를 `assets/source/imagegen/v122_stage01_spatial/threshold_w_2cell/`에 보존했다. 네 모서리 alpha 0·green spill 0을 확인했고 native `256×128` exact fit은 slicing 단계로 유보했으며 런타임에는 연결하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE11_THRESHOLD_W_SOURCE_2026-07-30.md`를 따른다.
- 2026-07-30 사용자의 `진행해`를 W 문턱 시각 승인으로 기록하고 시각 개편 12단계 저채도 2셀 복도 표면을 생성했다. 첫 후보는 석재 수가 지나치게 많아 native 축소 시 자갈처럼 뭉칠 위험이 있어 중간본으로 보존했고, 두 번째 precise edit에서 다이아몬드·저채도·광원을 유지한 채 slab 수만 줄였다. 선택본은 전체가 seam 없는 charcoal·violet-gray·iron-gray 연속 표면이며 황금 경로선·목재·황동·중앙 문양이 없다. 원본 chroma와 alpha preview, 두 프롬프트를 `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/`에 보존했고 네 모서리 alpha 0·green spill 0을 확인했다. native `256×128` exact fit은 slicing 단계로 유보했으며 런타임에는 연결하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE12_CORRIDOR_SURFACE_SOURCE_2026-07-30.md`를 따른다.
- 2026-07-30 사용자의 `내가 직접 선택해야하는 상황이 오기전까지 지금까지했던대로 순차적으로 계속 진행해`를 복도 표면 승인과 정해진 source 제작·연결 순서의 계속 승인으로 기록했다. 시각 개편 13단계에서 화면 하단 두 변만 따라가는 공통 2셀 폐색 그림자를 만들고 중앙·상단·외부를 비운 shadow-only alpha로 분리했다. 첫 후보가 좌상단 광원·하단 V형 폐색·우하단 심도 차를 충족해 선택했으며 원본과 prompt를 `assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/`에 보존했다. 네 모서리 alpha 0·green spill 0을 확인했고 exact fit·runtime 합성 강도는 후속 단계로 넘겼다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE13_OCCLUSION_SHADOW_SOURCE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 14단계에서 1920 full-canvas와 1366/1280 compact가 공유하는 Stage 01 9-slice 암벽 frame을 생성했다. 첫 후보의 두꺼운 하단·높은 보라 휘도를 줄이고 middle strip을 단순화했으며, chroma와 섞여 청록회색으로 남는 안개 protrusion은 제거하고 암벽 표면의 저채도 보라 반사만 유지했다. 암벽이 canvas border에 닿아 auto-key가 검정을 고르는 문제는 `#00ff00` 명시 key로 교정했다. 중앙은 `draw_center=false`, 저채도 보라 feather는 code-native gradient로 분리하는 계약을 고정했다. 원본·alpha·prompt는 `assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/`에 보존했고 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE14_EDGE_MASK_SOURCE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 15단계에서 승인된 Stage 01 왕좌·문턱 4종·복도·폐색·암벽 frame을 exact runtime 자산으로 분리하고 manifest·renderer에 Stage 01 한정으로 연결했다. 복도는 번호가 고정된 4셀 lookup으로 반복하고, N/W 문턱은 후면 벽 전·E/S 문턱은 전면 벽 뒤에 합성한다. 외곽 frame은 중앙 비표시·입력 비차단이며 world보다 앞, HUD보다 뒤에서 저채도 보라 feather와 함께 보인다. 생성 원본과 runtime은 분리했고 결정적 변환 스크립트를 추가했다. 크기·lookup·Stage 비침범·레이어·입력 계약의 전용 테스트는 PASS이며 전체 회귀·플레이·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE15_SPATIAL_RUNTIME_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 16단계에서 지상·비행 캐릭터 contact shadow, 아이소메트릭 선택 marker, 이름·체력 정보 예산을 적용했다. 정상 비선택 유닛은 이름·체력을 상시 노출하지 않고 선택·피해·위협 때만 표시한다. 실제 HUD와 입력 hit 영역은 하나의 Standard/Compact 배치 계약을 사용하며, 1920은 하단 120px rail, 1366/1280은 별도 148px 조작 rail로 구성한다. 방어구역 명령 후보는 방 전체 황금 overlay 대신 클릭 anchor만 강조한다. 시각 계층·3개 해상도 계약·실제 명령 버튼 통합 테스트는 PASS이며 전체 회귀·플레이·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE16_COMBAT_HIERARCHY_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 17단계에서 `trap` 등 내부 구조 역할 ID를 사용자용 시설·함정 이름으로 교체하고, 확정 배치·고정 지침·실제 몬스터 기여도를 결산의 `내 선택의 결과` 문구로 연결했다. 관련 대상 테스트는 PASS했고 전체 회귀·플레이·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE17_RESULT_CAUSALITY_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 18단계에서 DAY 1 선택을 푸딩이 아닌 곱으로 확정했다. 푸딩은 전열, 핀은 후열에 고정하고 곱이 `전열 봉쇄` 또는 `후열 화력`에 합류한다. 두 물리 슬롯만 지도에서 직접 선택하게 했고, 확정 zone anchor를 실제 전투 생성과 결산 인과에 연결했다. legacy 튜토리얼 step ID를 유지해 저장 호환을 보존했으며 튜토리얼·결산 대상 테스트는 PASS했다. 전체 회귀·실제 플레이·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE18_DAY1_GOBLIN_CHOICE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 19단계에서 1920 full-canvas와 1366/1280 compact의 DAY 1 곱 선택을 실제 렌더로 확인했다. 강조 프레임 하단선이 `후열 화력` 표식을 덮던 문제를 formation focus의 하단 여백 28px로 수정했고, 세 해상도 모두 곱 카드·두 노란 대상·안내 카드 비겹침과 표식 가독성을 확인했다. 튜토리얼·결산 관련 테스트는 다시 PASS했으며 전체 회귀·실제 플레이·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE19_DAY1_GOBLIN_RESPONSIVE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 20단계에서 DAY 1 곱 전열·후열을 동일 seed 실제 런타임으로 비교했다. 수정 전 후열은 공격 0·`교전 기록 없음`이어서 `zone_a_rear` anchor를 능력치 보너스 없이 기존 연결 통로 `path_a_front_rear`로 당겼다. 최종 연속 실행에서 전열은 2.933초, 후열은 4.133초에 첫 타격했고 두 선택 모두 실제 공격 기여와 `전방 봉쇄/곱 → 전열`, `후방 화력/곱 → 후열` 결산 문구를 남겼다. 공간·저장·결산 관련 대상 테스트는 PASS했고 전체 회귀·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE20_DAY1_GOBLIN_PLAY_COMPARE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 21단계에서 튜토리얼 안내 수준 `전체/핵심만/끄기`를 `UISettings` 저장·일반 설정 페이지·이름 등록·런타임 오버레이에 연결했다. `전체`는 필수 조작과 자동전투 관찰까지, `핵심만`은 필수 조작만, `끄기`는 시각 안내 없이도 스토리와 필수 선택 진행을 유지한다. 이름 도움말은 입력창을 숨기지 않는 옆 카드로 바꿨고, 실제 1280 캡처에서 발견한 곱 안내의 푸딩 카드 오지정은 컨테이너 배치 전 고정 좌표 대신 살아 있는 `Control.global_rect`를 조회하도록 수정했다. 설정·등록·DAY 1~3 튜토리얼 테스트와 1920/1366/1280 GUI 캡처는 PASS했으며 전체 회귀·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE21_TUTORIAL_GUIDANCE_LEVELS_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 22단계에서 설정 전체, 이름 등록, DAY 1~3 튜토리얼을 `settings./name./tutorial.` 키와 Stage 10 `ko/en` 카탈로그에 연결했다. 일반 설정의 `한국어/English` 선택은 즉시 화면을 다시 구성하고 적용 시 저장·취소 시 snapshot 복원을 유지한다. `TUT_010_NAME`~`TUT_240_BOSS_HP` 단계 ID와 순서는 보존했으며 클릭/탭 배지까지 현지화했다. DAY 3 안내 카드와 클릭 배지는 실제 회복 둥지·우측 상세 서랍을 가리지 않게 보정했다. 두 언어의 검증 범위 누락 키는 0이고 전용 42 assertions, 안내 수준 20 assertions, 설정 상호작용 18 assertions, DAY 1~3 흐름과 1920/1366/1280 42장 GUI 캡처가 PASS했다. 범위 밖 전체 캠페인 문구의 영어화는 아직 완료되지 않았고 전체 회귀·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE22_STAGE10_LOCALIZATION_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 23단계에서 이름 등록 도움말 닫기 기록을 `user://settings.cfg`의 기기별 `TutorialGuidanceHistory`로 분리하고 일반 설정의 적용·취소 가능한 초기화에 연결했다. DAY 1~3 기존 12개 ID를 복제하는 별도 연습 세션은 live `TutorialManager`·캠페인 payload·세이브를 건드리지 않는다. `전체`는 12개, `핵심만`은 관찰 3개를 제외한 9개, `끄기`는 현지화 빈 상태를 사용한다. 전용 22 assertions에서 적용·취소·재진입·payload/파일 불변을 확인했고, 기존 현지화 42 assertions·안내 수준 20 assertions·DAY 1~3·DAY 5 저장 스모크와 한국어/영어 1920/1366/1280 18장 GUI 캡처 54 checks가 PASS했다. 전체 회귀·빌드는 수행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE23_STAGE10_PRACTICE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 24단계에서 DAY 2~3 관리·전투·결산의 9개 대표 상태를 1920/1366/1280에서 27장으로 캡처했다. 지도 클릭 단계와 전술 특화 필수 드로어가 경쟁하던 상태, 방 지침 클릭 배지가 드로어 내부를 가리던 상태, 개편된 전투 HUD의 `BossHpBar` target alias 누락으로 DAY 3 관찰 카드가 사라지던 상태를 공통 UI 파급으로 분리해 최소 수정했다. 최종 405 assertions와 안내·현지화·관리·전투·결산·DAY 1~3 대상 테스트가 PASS했고 DAY 전용 규칙·밸런스·기존 단계 ID는 유지했다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE24_STAGE11_DAY02_03_CASCADE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 25단계에서 DAY 4 원정 미리보기부터 DAY 5 패배 결산까지 13개 실제 상태를 1920/1366/1280에서 39장으로 캡처했다. 원정 미리보기 오른쪽 한국어 설명의 잘림을 bounded `RichTextLabel`과 의미 단위 줄바꿈으로 최소 수정했다. 관리 원정은 하단 주 행동이 아니라 `전술·상세` 문맥 서랍에 있는 선택 행동이라는 기존 계약을 확인했고 제품 구조는 바꾸지 않았다. 최종 417 assertions와 튜토리얼·침입 전 흐름·관리·전투·결산·DAY 1~5 대상 테스트가 PASS했으며 DAY 규칙·밸런스·튜토리얼 ID·저장 호환은 유지했다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE25_STAGE11_DAY04_05_CASCADE_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 26단계에서 확정 사양에는 있으나 타이틀에만 연결돼 있던 환경 설정을 관리 ESC와 전투 일시정지 메뉴에 연결했다. 현재 화면을 어둡게 남기는 단일 modal에서 `계속`만 primary, `환경 설정`은 utility로 고정했고 관리 배치·전투 유닛 physics·음악 stream·설정 return screen을 보존한다. 설정→연습→침입→원정→전투→결산→저장 경로를 1920/1366/1280의 27장과 243 assertions로 검증했고 현지화·연습·관리·침입·전투·결산·저장·입력 대상 테스트가 PASS했다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE26_STAGE12_INTEGRATION_2026-07-30.md`를 따른다.
- 2026-07-30 시각 개편 27단계에서 Phase 3~26 누적 의도 파일 211개를 `c0c5871a1d84cdb140358f20dbb522d9ae69d63d`로 커밋하고 같은 SHA의 Windows QA debug 빌드를 생성했다. 최종 export와 패키지 headless 부팅은 각각 exit 0·ERROR 0이며 file/product version은 1.2.2.0이다. EXE/PCK와 SHA-256은 `tmp/v122_windows_qa_c0c5871/` 및 상세 핸드오프에 기록했다. 빌드는 미서명 로컬 테스트 전용이며 Full·Web·Steam·태그·Release·푸시는 진행하지 않았다. 상세 내용은 `docs/handoff/V122_VISUAL_OVERHAUL_PHASE27_WINDOWS_QA_BUILD_2026-07-30.md`를 따른다.
- 2026-07-30 사용자 피드백 3건과 전투 프레임 병목을 `5b423c9ef734c310cd5c9c688f9e6d4cf9ffd146`으로 커밋·푸시했다. 모든 수비 몬스터가 샛길을 사용하고 중간 진입 시 재탐색하며, 금고 침입자 접근·공격과 왕좌 공격 모션을 보강했다. 동적 전투 표식과 함정 애니메이션은 정적 던전 전체 redraw에서 분리했다. 직접 영향 테스트와 20 assertions 성능 스모크가 PASS했고 소스 draft PR #80을 열었다.
- 같은 소스 SHA를 Godot Web으로 export해 1920×1080 Full-canvas와 1366×768/1280×720 Compact에서 DAY 1 곱 카드·전열/후열 표식·안내 UI를 실제 조작 검증했다. 오류·경고 0, 런타임 요청 HTTP 200을 확인한 뒤 테스트 저장소 PR #17을 병합했고 Pages run 30520912798이 PASS했다. 공개 테스트 주소는 `https://bluehige.github.io/mawangseong-web-playtest/`이며 상세 내용은 `docs/handoff/V122_FEEDBACK_WEB_QA_PUBLISH_2026-07-30.md`를 따른다.
- 2026-07-30 승인된 대사집의 DAY 1~5를 `a5679c0fe2b092dd745d0fdb0d3fbe27b2708a22`에서 실제 관리·배치·전투·결산·원정 흐름에 연결했다. 초회 스킵 금지·재열람 스킵·선택형 Auto·`대화 알람`·전투 완전 정지·optional 저장 호환·battle/raid 재도전 범위를 구현했고 DAY 4 필수 표지판 원정과 로로 고정 지휘관 계약을 적용했다. 대상 테스트와 최종 정적 검토의 P0/P1/P2는 0건이다.
- 같은 소스 SHA의 빠른 Web 테스트를 배포 커밋 `097eea72c6ae6d9bee0e5a7728674e33a9ac1e63`으로 게시했고 Pages run 30541955986이 PASS했다. 공개 1280×720 1회 부팅에서 canvas `1280×720`, 내부 `1920×1080`, loading 종료와 browser error 0을 확인했다. 상세 내용은 `docs/handoff/V122_STORY_DIALOGUE_PHASE2_DAY01_05_RUNTIME_2026-07-30.md`를 따른다.
- 현재 우선 작업은 사용자가 공개 Web 후보에서 DAY 1~5를 직접 테스트하는 것이다. DAY 1~5가 완벽하다는 사용자 확인 뒤 같은 기준으로 DAY 6~30을 진행하며, 확인 전에는 DAY 6 이후 대사 연결을 시작하지 않는다.
- 2026-07-30 사용자 지시에 따라 비정식 테스트 빌드 절차를 `export 성공 → 공개 URL 대표 해상도 1회 부팅 → 즉시 게시`로 축소했다. 다중 해상도·전체 흐름·회귀 재실행·장시간 성능·clean worktree·별도 PR·상세 해시 감사는 정식 후보이거나 사용자가 명시한 경우에만 수행한다.
- 과도한 반복 관측은 실행하지 않는다.
- 변경 범위와 직접 관련된 테스트만 실행한다.
- 버전 마감에서는 자동 버그 회귀를 꼼꼼히 실행하고, 전체 플레이·시각 재검수·별도 검수 에이전트는 사용자가 그 작업에서 요청한 경우에만 실행한다.
- 신규 그래픽은 GPT 내부 이미지 생성 도구만 사용하고 `assets/source/imagegen/<version>/` 원본과 `assets/` 런타임 자산을 분리한다.

`v0.*`가 붙은 아래 과거 문서·브랜치·태그는 2026-07-16 이전 구 체계 기록이다. 이름을 바꾸지 않으며 새 릴리스 번호로 재사용하지 않는다.

## 제품 1.2.1 공개 출시 완료 상태

- 플레이 검수 수정 PR #40은 merge commit `25a41a4f08925e35592aca890e0c56a75c5203f9`로 `main`에 병합됐다.
- 새 `main`에서 `hotfix/v1.2.1`을 분기하고 프로젝트·Windows 파일의 기술 버전을 1.2.1로 올렸다. 화면 표시는 1.2, 기존 저장 경로는 그대로 유지한다.
- 기능·버전 SHA `07586e51a7c66d6290602629a54b4cb6ce6b6d40` 뒤 Steam 테스트 픽스처의 구버전 하드코딩을 수정했고, PR #41 merge·출시 SHA `c483d135b13cf9771ee43b045ba2c3dde51573ee`의 깨끗한 작업 트리에서 `RunCoreVerification.ps1 -Mode Full` 89/89를 통과했다.
- 최초 대량 임포트에서 Godot 4.5.2 폰트 임포터가 접근 위반으로 한 번 종료됐지만, 캐시 완성 뒤 동일 SHA의 프로젝트 임포트와 전체 89개 검증은 PASS했다.
- 기능상 남은 P1/P2는 0건이다. Windows 코드 서명과 물리 Microsoft 한국어 IME 한/영 전환은 외부 수동 확인 항목으로 남는다.
- 주석 태그 `v1.2.1`과 [GitHub Release `마왕성 v1.2.1`](https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.1)을 공개했다. Windows ZIP은 263,306,748바이트, SHA-256 `63118100a3b304a1c10c904a6e6b5da2a368ee0d5721dcd9037b982f80f3cb3e`이며 코드 서명은 없다.
- [PC Web](https://bluehige.github.io/mawangseong-web-playtest/)과 [모바일 Web](https://bluehige.github.io/mawangseong-mobile-playtest/)을 같은 태그 소스로 배포했다. PC 1920×1080과 모바일 844×390에서 타이틀→새 게임 등록, 모바일 390×844 회전 안내, 콘솔 오류·경고 0건과 모든 런타임 요청 HTTP 200을 확인했다.
- 모바일 제목 P3 불일치는 PR #8과 Pages run 29733411515로 수정해 공개 `<title>`도 `v1.2.1`로 맞췄다.
- 태그 Actions run 29729582970의 LFS 오디오 누락 artifact는 사용 금지다. 공식 Release에는 태그 SHA clean LFS 빌드만 첨부했고, PR #42 merge `bc7ca8e2b0763814b69beaf0db3ee29bc3cf8d56`에서 다음 태그용 LFS·PCK BGM·Windows 부팅 검사를 강제했다.

## 제품 1.2 이슈 #39 실제 사용자 검수·수정 상태

- `codex/v12-playtest-fixes`의 `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54`에서 이슈 #39의 기존 실제 사용자 검수 결과와 추가 사용자 지적을 합쳐 수정했다.
- DAY 3 승리 결산 저장·재실행 뒤 성장 버튼 진행 불가와, 보스 HP 50% 안내 전 패배 뒤 재전투가 막히는 P1을 수정했다.
- DAY 2 가시 복도에 실제 클릭 중심을 가리키는 큰 노란 마름모·점·배지를 추가하고, 후속 행동을 오른쪽 `[방 지침]`의 `[함정 유도]`로 짧고 일치하게 안내한다.
- 대화 초상화와 텍스트 패널 사이에 28px 간격을 두었고, 자동전투 경로점을 맵 안으로 보정하며 0.75초 정체 시 오래된 경로를 폐기해 재탐색하게 했다.
- 저장 안전 화면 판정을 단일화하고 Windows export에 제품명·설명·1.2.0 버전·아이콘을 지정했다.
- 관련 회귀와 `RunCoreVerification.ps1 -Mode Full`이 89/89 통과했다. 수정 Windows export를 격리 저장공간에서 새 게임부터 DAY 1 완료와 DAY 2 가시 복도·함정 유도 안내까지 Computer Use로 재검증했다.
- 사용자 기존 저장 파일의 SHA-256과 수정 시각은 검수 전후 동일하다. 빌드·캡처는 모두 `tmp/`에 있으며 커밋 대상이 아니다.
- 기능상 재현되는 P1/P2는 0건이다. 불변 검수 SHA `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54`의 분리 작업공간에서 전체 89/89를 다시 통과해 최종 PASS를 고정했다.
- 구현 브랜치는 [PR #40](https://github.com/bluehige/mawangseong-demo/pull/40), merge commit `25a41a4f08925e35592aca890e0c56a75c5203f9`로 `main`에 병합했다.
- 1.2.1 수정판 출시까지 완료했다. 남은 외부 확인은 Windows 코드 서명 인증서와 물리 한국어 IME 조합 중 실기 확인이며 기존 `v1.2.0` 태그와 Release는 변경하지 않았다.

## 제품 v1.2 공개 출시 상태

- 사용자 표시 이름은 `v1.2`, 다음 확장판은 `v2.0`으로 통일했다. 프로젝트·태그의 기술 버전은 SemVer `1.2.0`, `2.0.0`을 사용한다.
- 불변 태그 `v1.2.0`과 GitHub Release `마왕성 v1.2`를 만들고 Windows ZIP을 첨부했다.
- PC Web과 모바일 Web을 각각 v1.2 빌드로 교체해 Pages 배포를 완료했고, 공개 주소에서 캔버스 기동과 브라우저 오류 0건을 확인했다.
- 태그 시점의 자동 Windows 빌드는 공식 Godot ZIP 파일명 불일치로 실패했다. Release에는 로컬 clean worktree에서 검증한 Windows ZIP을 수동 첨부했으며, 이후 태그용 워크플로 파일명은 후보 SHA `9e02b967fce83f1c5bc960b681635b0f2b2058e1`에서 수정해 [PR #37](https://github.com/bluehige/mawangseong-demo/pull/37), merge commit `4a02eaac72cb5f45965e6981d0436ed20b6f0561`로 `main`에 반영했다. 불변 태그는 이동하지 않는다.
- 사용자 요청에 따라 이번 공개 갱신에서는 전체 회귀·전체 플레이·별도 검수 에이전트를 실행하지 않고 출시 대상 관련 테스트와 공개 URL 부팅만 확인했다.

## 제품 1.2 지시 전용 전투 구현 상태

- `codex/v12-directive-combat`에서 단일 유닛 직접 이동·공격·수동 스킬을 제거하고 전역·방 지시 기반 자동 AI로 전환했다.
- 유닛 몸체 충돌·회피·우회를 제거하고 PC·모바일 x1~x3와 일시정지를 연결했다. 공격·스킬 거리와 맵 경계는 유지한다.
- DAY 1~3 튜토리얼은 x1로 고정했다. 완료 뒤 첫 일반 전투를 잠시 멈추고 PC·모바일 속도 버튼 위치와 x1~x3 효과를 한 번 소개하며, 확인 상태는 구형 저장과 호환되게 저장한다.
- DAY 1~3을 배치·방어·함정 유도·후퇴 지점과 자동 행동 관찰 중심으로 줄이고 구형 진행 인덱스를 보정했다.
- 이름 입력창 재생성을 없애고 텍스트 입력 포커스가 전역 키를 소유하게 해 Windows IME 조합 중단 원인을 수정했다. 한글·숫자 혼합 저장 왕복 자동 테스트와 Windows 빌드의 한글 입력·Backspace·재입력·시작 전환을 확인했다. 자동화 제약으로 물리 한/영 키 조합 중 상태만 별도 실기 확인이 남아 있다.
- 확대 글꼴의 상단 자원·DAY·체력·시설 효과와 하단 지시 HUD를 재배치했다. PC·모바일 최대 글꼴의 1920×1080·1366×768·1280×720 렌더 계약이 통과했다.
- 대표 전투는 DAY 1 36.0초, DAY 2 35.6초, DAY 3 68.7초에 승리했다. x3 체감 환산은 약 12.0초·11.9초·22.9초다.
- PC Web 1.2.0은 1280×720에서 타이틀·빠른 시작·튜토리얼 대상·지시 메뉴를 실제 조작했고 오류 0건이다. 빠른 시작 seed 미초기화 경고를 발견해 수정하고 회귀를 추가했다.
- 사용자 요청에 따른 전체 검수는 1차 84/89에서 5건을 수정하고, 후보 검수 88/89에서 베베 자동 구조 테스트 조건 1건을 격리한 뒤 최종 SHA `e0da9591d0e317104f0d021509b6a9ba2b958e75`에서 89/89 전부 통과했다.

## 현재 계보와 구 버전 기록

아래 `v0.*` 항목은 공개·감사 이력을 보존한 구 명칭이다. 현재 제품 버전은 1.2, 기술 SemVer는 1.2.0이다.

| 브랜치·커밋 | SHA | 의미 |
|---|---|---|
| 제품 1.2 지시 전용 전투 `main` 병합 | `93ba159694cf6010f4ec0f93331913c131f749ce` | [PR #35](https://github.com/bluehige/mawangseong-demo/pull/35) merge commit 통합. 최종 검수 SHA `e0da9591d0e317104f0d021509b6a9ba2b958e75`, 전체 89/89와 P1/P2 0건 기준 |
| v0.5 PC·모바일 플랫폼 성능 수정·공개 배포 | `bb61ba99a9403532345d441233a8c59821b3fecd` | [소스 PR #33](https://github.com/bluehige/mawangseong-demo/pull/33) merge commit 통합. 공통 던전 과다 렌더와 Web BGM 선디코딩을 제거하고 native full, PC Web balanced, mobile 경량 프로필을 분리. [PC PR #4](https://github.com/bluehige/mawangseong-web-playtest/pull/4)·[모바일 PR #5](https://github.com/bluehige/mawangseong-mobile-playtest/pull/5)와 Pages 배포 성공, Chrome 공개 부팅 확인 |
| v0.5 모바일 전용 PCK 최적화 | `35abd218a5de01209b4eb4c88bfa7c297c8462d4` | 소스 [PR #31](https://github.com/bluehige/mawangseong-demo/pull/31), 모바일 [PR #4](https://github.com/bluehige/mawangseong-mobile-playtest/pull/4) 병합 완료. Noto 폰트·전투 스프라이트·일반 Web PCK를 유지하고 모바일 일러스트 134개만 품질 0.90 export하여 PCK를 231,477,848에서 149,196,724바이트로 축소 |
| v0.5 모바일 개선 소스 `main` 병합·공개 배포 | `c2400102ce3e1a88760bb944d50c28307419bb66` | 소스 PR #27·#28·[#29](https://github.com/bluehige/mawangseong-demo/pull/29) merge commit 통합 완료. Web `18a6fe1b4d125e19055d07211a4d9954b95c6b70`, 모바일 `4bf82851c6f24a1e12ad8a4b68b47066a66392d3`에서 Pages 배포 성공 |
| v0.5 모바일 터치 UI·가독성·튜토리얼 개선 | `f0c984b680b27c12c8bbf8586afa8c2f743b17ad` | 모바일 큰 터치 대상, 탭 공격·이동, 관리·전투 전용 조작 바, 이름 키보드 자동 재호출 제거, 1.35배 텍스트 확대, 필수 대상 사전 선택과 강조 링 전체 터치 액션 기준 |
| v0.5 Lyria 상황·스킬 오디오 확장 | `6eef61ad89730c7a3ae00e05172c873d88159570` | 선택 BGM·타격음 승격, 관리/일반전/보스전 3상태 음악, 직접 전투 스킬 24개 고유 cue와 출처·LFS·관련 테스트 기준 |
| v0.5 Lyria 3 오디오 파이프라인 | `63d1242624d3d0fff27b53c84fe286de4f372156` | 현재 WAV 50개 전체 매핑, 키 비노출 Interactions 생성·후보 렌더·승인 승격과 출처 기록 기준 |
| `codex/v05-steam-release-readiness` 구현 | `856440c525fec8d82ce5a10d7dc25e3e160cb31c` | Steam 상점·그래픽·Windows depot·SteamPipe·Cloud·출시 게이트 기반과 관련 검증 PASS 기준 |
| Steam 통합 검증 | `63d1242624d3d0fff27b53c84fe286de4f372156` | 진행 중 별도 세션의 오디오 도구 커밋을 보존한 상태에서 Steam clean worktree 빌드·실행을 다시 통과한 기준. 오디오 파이프라인 자체는 이번 검수 범위가 아님 |
| v0.2.3 검증·Web 빌드 소스 | `35b2913cf4d8dbdc1cb0230398b2722e4cd8dfc4` | Full 45/45와 canonical Git blob catalog provenance PASS 기준 |
| v0.2.3 `v.02` 병합 | `7ec0156d6e23197f3256ea13fb1d87e175b50b07` | PR #20으로 v0.2 유지보수 계보에 merge commit 통합 |
| v0.2.3 `main` 계보 기록 | `77d9ede3b5d687795b5157065c236d9cf30d33f1` | 현재 main 트리를 유지하면서 v0.2.3 태그 조상 관계를 기록 |
| v0.2.2 검증·Web 빌드 소스 | `c8b5a4684d8f55e33e9c4da4b7ea3fab3af7f077` | Full 45/45와 새 Release provenance·manifest PASS 기준 |
| v0.2.2 `v.02` 병합 | `94987042485c37ddd005c0eb84a3796f02a2aabf` | PR #18로 v0.2 유지보수 계보에 merge commit 통합 |
| v0.2.2 `main` 계보 기록 | `966b9dbbb900a6d60b23cd841f3a7e57d3656a8b` | 현재 main 트리를 유지하면서 v0.2.2 태그 조상 관계를 기록 |
| v0.2.1 검증 소스 | `3b1a0edd6b0389f7be8b4c88fe8ca45046d623b3` | v0.2 입력 레이어 핫픽스와 Full 45/45 PASS 기준 |
| v0.2.1 `v.02` 병합 | `312a649afa5c379101194b23cddcfeec4ecf3815` | PR #16으로 v0.2 유지보수 계보에 merge commit 통합 |
| v0.2.1 `main` 계보 기록 | `77423e73717c03c3beb9d0aa2377a6436a1d4d33` | v0.4 소스 트리를 유지하면서 v0.2.1 태그 조상 관계만 기록 |
| UI 입력 레이어 `main` 병합 | `592b3a434fde5196d22ee1269e9009d667517264` | PR [#14](https://github.com/bluehige/mawangseong-demo/pull/14)를 merge commit 방식으로 통합 |
| `codex/v04-input-layer-guard` 구현 | `af361d5c64b24e94896a6d31845d0e9fa6e4bda0` | UI 입력 레이어 방어 구현과 직접 영향 테스트 기준 |
| `origin/main` v0.4 병합 | `a8b29e6ee176b96b0f910beb2d5cbf07dc2c4767` | PR #13으로 v0.4 개발본을 merge commit 방식으로 통합한 최신 안정 기준 |
| `codex/v04-sequential-development` 검수 SHA | `51b401fad9d16584a00674e48afdc83bb6219473` | v0.4 Phase 0~36 기능·데이터·자산, 이미지 출처 정책과 최종 버그 테스트 기준 |
| `origin/release/v0.4` | `c0b9534` | PR #12로 v0.4 개발본을 통합한 릴리스 브랜치 기준 |
| `v0.3.0` / PR #10 merge | `ba661015e4bc5be6fec1aa470c5f48d565422597` | v0.3 최종 소스와 최신 튜토리얼 버그픽스를 고정한 정식 태그 |
| `codex/v03-sequential-finalize` 검수 SHA | `0dae916a5354f3df119bae6115c754fc12e1b094` | 전야 마감과 최신 튜토리얼 버그픽스를 함께 검증한 v0.3 소스 |
| `origin/main` v0.3 병합 | `ba661015e4bc5be6fec1aa470c5f48d565422597` | PR #10을 merge commit 방식으로 통합한 안정 기준 |
| 최신 튜토리얼 구현 | `91acdec6ec00c65a438cba9f6cf88e0cfa829744` | 적 우클릭 판정 버그픽스, 위 검수 SHA에 포함 |
| `release/v0.3` | `af34cad42634759088114043760abafad5c3e94a` | 기존 v0.3 통합 계보 |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |

## 구 v0.5 기획 묶음(제품 4.0 대응) PC·모바일 성능 수정 상태

- 공개 테스트판의 느림은 모바일만의 문제가 아니었다. PC Web도 보이지 않는 전체 던전을 계속 그려 타이틀이 약 35.54fps, 프레임당 약 5,631 draw 호출이었다.
- 비월드 화면 렌더 차단, 플랫폼별 던전 품질, 전투 redraw 제한, Web BGM streaming을 적용했다. Windows native는 full 품질, PC Web은 balanced 품질, 모바일 Web은 추가 경량화와 CSS 픽셀 백버퍼를 사용한다.
- 실제 브라우저 계측에서 PC Web과 모바일 DPR 3의 타이틀·관리 화면이 모두 60fps를 유지했다. 모바일 관리 draw 호출은 약 1,304회/프레임, 백버퍼는 844×390이다.
- 모바일 일러스트는 export 시 1280px 상한을 추가해 PCK를 146,803,604바이트로 줄였다. PC Web 231,378,276바이트와 함께 각 테스트 저장소 `main`·Pages에 배포했다.
- 공개 [PC Web](https://bluehige.github.io/mawangseong-web-playtest/)과 [모바일 Web](https://bluehige.github.io/mawangseong-mobile-playtest/)은 workflow의 PCK·WASM·필수 오디오 검증을 통과했고 Chrome에서 타이틀 화면까지 실제 부팅했다.
- STOVE 배포는 사용자의 지시대로 수행하지 않았다.
- 관련 Godot/Python 테스트와 PC·모바일 브라우저 렌더는 `TARGETED_PASS`다. 전체 회귀·전체 플레이·검수 에이전트는 요청되지 않았다.

## Lyria 3 오디오 교체 준비 상태

- 사용자 선택에 따라 전투 BGM Take 1과 기본 타격음 Take 2를 런타임에 승격했다.
- 관리 화면, 일반 전투, 보스 전투의 세 음악 상태를 연결했다. 보스 등장 시 보스곡으로, 보스 격퇴 후 잔여 전투가 있으면 일반 전투곡으로 돌아간다.
- 코어·update3의 직접 전투 스킬 24개에 각각 다른 Lyria WAV를 연결했다. 발동음은 고유 재질·동작/마력·음조 확인 레이어를 가지며 기존 공격·피격 레이어와 함께 재생된다.
- 현재 매니페스트는 런타임 WAV 76개를 `lyria-3-clip-preview` 73개, `lyria-3-pro-preview` 3개로 관리한다. 승격한 28개 자산의 원본·프롬프트·해시는 `assets/source/audio/lyria/v0.5/`에 보존한다.
- 이번 확장 호출은 Clip 24회와 Pro 2회, 예상 USD 1.12이며 최초 후보까지 포함한 누적 예상 요청 비용은 USD 1.36이다. API 키 패턴은 관련 저장소 파일 0건이다.
- 자동 검증은 24개 스킬·3개 음악의 고유 파일, 형식, 비무음과 상황 전환을 통과했다. 실제 플레이의 최종 음량·반복 피로 청취와 기존 보조 cue 48개의 Lyria 재생성은 후속 선택 사항이다.
- 제공된 키는 채팅에 직접 노출됐으므로 즉시 폐기하고 새 키를 발급해야 한다.

## Steam 판매 출시 준비 상태

- Windows 64-bit 유료 정식판, Coming Soon 뒤 Demo, Steam Auto-Cloud를 사용하는 최소 출시 구조를 정했다.
- Steam 상점 문구·콘텐츠 및 사전 생성형 AI 설문 초안, 필수 규격 그래픽, 실제 플레이 스크린샷 6장을 준비했다.
- Godot `Windows Steam` export, 라이선스·해시 매니페스트 포함 depot 생성, SteamPipe 업로드, 태그 artifact CI를 구현했다.
- 통합 SHA `63d1242`의 깨끗한 detached worktree에서 Godot 4.5.2 초기 임포트부터 Windows 패키지 생성까지 PASS했고, 패키지 실행 exit 0·ERROR 0을 확인했다.
- 출시 validator는 기반 설정을 통과하며 App/Depot ID, 공개 연락처, 사용자 승인, 실기기 검수와 Valve 심사를 포함한 외부 항목 17개를 의도적으로 차단한다.
- 사용자 작업의 단일 체크리스트는 `docs/release/OWNER_ACTIONS.md`, 전체 일정과 역할은 `docs/release/STEAM_RELEASE_MASTER_PLAN.md`를 따른다.
- 현재 판매 가능 상태는 아니다. Steamworks 가입·계약·등록비·세금/은행 검증을 가장 먼저 완료해야 한다.

## 구 v0.4 기획 묶음(제품 3.0 대응) 개발 완료 상태

- v0.4 Phase 0~36을 계획 순서대로 구현하고 의회 회차 DAY 1~30 실제 진행 경로를 완성했다.
- 최신 `main`의 v0.3 튜토리얼 적 클릭 버그픽스 `91acdec6`를 포함한다.
- Phase별 관련 자동 테스트 36종, Phase 36 통합 285 assertions, 튜토리얼과 데모 스모크가 PASS다.
- 의결·왕관·최종 선언 UI는 1920×1080과 1366×768에서 확인했다.
- 그래픽은 GPT 내부 생성 도구로 만들고 `assets/source/imagegen/` 원본과 런타임 자산을 분리했다.
- PR #12와 #13으로 `release/v0.4` 및 `main` 통합을 완료했으며 정식 `v0.4.0` 태그는 후속 버그픽스 이후 만든다.
- PR #14로 표시 전용 UI 레이어의 클릭 차단을 방지하고 35개 입력 계약 단언을 추가했다.
- v0.2.3 입력 레이어 핫픽스 Web Release와 Pages 배포를 완료하고 공개 화면의 v0.2.3 표기와 클릭 전환을 확인했다.

## 검수 정책 필드

- Review task ID: `LUNA-WORKTREE-AUDIT-2026-08-02`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Review range: `N/A — HEAD efab13e7f9a2c1e2bd059eb8abf4cc409710380d 위 작업 트리`
- Remaining P1/P2: `P1 2건 / P2 2건 — V2-P4 정체성 자산, I1-5 실제 조작·청취, V3 접지, 오디오 실제 청취 gate`
- Final review result: `FAIL — 확정 사고의 대상 수정은 통과했으나 현재 트리는 출시 승인 상태가 아님`

## 다음 작업 순서

현재 Luna 구현은 감사·보정 중이며 출시 승인 상태가 아니다. V2-P4E 연결은 `CONNECT_PASS_WITH_NORMALIZATION_PENDING`이고 V2-P4F 정체성 비교 검수와 V3 대표 동작·원본 승격이 남아 있다. V4-A/B 구조·화면 패킷은 통과했지만 I1-5 소유자 화면 gate가 남아 있다. A0/A1/C1/V5는 순서 밖 선행 구현으로 보존하되 `UNAPPROVED_WORKTREE_ONLY`로 격리한다. 기존 자동 PASS는 해당 dirty-worktree 시점의 참고 로그일 뿐 현재 SHA 승인 근거가 아니다. 상세: `docs/handoff/V122_RELEASE_POLISH_LUNA_AUDIT_CORRECTION_2026-08-02.md`.

감사 보정 뒤 허용된 다음 순서는 `현재 잠긴 I1-5 소유자 화면 재검증 → 미해결 gate 문서 고정 → 사용자 요청 시 최종 기능 SHA 커밋`이다. 그 전에는 A1 후속, 전체 회귀 또는 빌드로 넘어가지 않는다. `moon_tracker`는 전용 런타임 시트와 `READY` 계약 연결을 마쳤고, 최종 프레임 정규화만 V3 범위에 남아 있다.

역사적 실행 로그(현재 승인 근거 아님): 아래 F0·Q1·I1·A0·A1·C1·V5 결과는 당시 실행 사실을 보존하기 위한 기록이다. 계획 전제, 실제 화면·청취 gate와 최종 SHA가 없는 항목은 현재 완료 판정으로 사용하지 않는다.

1. `F0-V 시각 인벤토리`를 완료했다. 활성 전투 유닛 44개, 원본·프레임 크기, 투명 여백, 발끝 추정, 데이터/런타임 비행 판정과 DAY 3 1280×720 기준 캡처를 `docs/qa/V122_F0V_VISUAL_INVENTORY_2026-08-02.md`에 고정했다. 런타임·원본 그래픽은 수정하지 않았다.
2. `F0-A 오디오 인벤토리`도 완료했다. WAV 76개를 실제 런타임 54개, 데이터-only 12개, 호출 미확인 10개로 구분하고 Lyria 28개·절차적 합성 48개, 루프·버스·해시·출처·청취 상태를 `docs/qa/V122_F0A_AUDIO_INVENTORY_2026-08-02.md`에 고정했다. 오디오와 런타임은 수정하지 않았다.
3. `F0-R 출시 공백 인벤토리`를 완료했다. Q1-S·Q1-I·Q1-L·Q1-P·Q1-R의 권위 문서, 현재 근거, 재현 입구, 미검수 경계를 `docs/qa/V122_F0R_RELEASE_GAP_INVENTORY_2026-08-02.md`와 `tmp/v122_release_polish/f0_r/f0_r_inventory.{json,tsv}`에 고정했다. Q1-S·I·L·P는 `OWNER_QA_PENDING`, Q1-R은 `SOURCE_AUDIT_PARTIAL_WITH_RELEASE_GATE`다.
4. Q1-S 저장·복구와 두 P2 재현을 완료했다. Stage 04 투영은 `service_entrance` 포함 여부를 제품 계약으로 결정해야 한다.
5. Q1-I 입력·IME 자동·합성 감사는 `Q1IInputImeRepro` 12 assertions와 관련 UI/출시 계약 PASS로 완료했다. 실제 Windows 한/영 IME·Backspace·Enter와 모바일 회전·탭은 소유자 검수 대기이며 `docs/qa/V122_Q1I_INPUT_IME_AUDIT_2026-08-02.md`에 기록했다.
6. Q1-L UI·현지화·placeholder 자동·합성 감사는 카탈로그 ko/en 각 142개 키의 누락·빈 값 0, 관련 UI 계약 PASS를 확인했다. 왕관 후보 instance ID, 전투 목표·경로 room ID, 미지 room fallback 노출은 P3 별도 수정 패킷으로 분리했고, 전체 버튼·최장 문구·dead click·실제 Windows 후보 화면은 `OWNER_QA_PENDING`이다. 상세 결과는 `docs/qa/V122_Q1L_UI_LOCALIZATION_PLACEHOLDER_AUDIT_2026-08-02.md`와 `tmp/v122_release_polish/q1_l/q1_l_inventory.{json,tsv}`에 기록했다.
7. Q1-P 성능·메모리 상세 감사는 기존 20 assertions 스모크, 시각 계층 계약, 6개 headless 시나리오(각 120프레임)로 완료했다. 동적 표식·타격·함정·시설·복합 효과의 정적 맵 전체 redraw는 모두 0회였고, 실제 Windows GPU·저사양 RSS·장시간 전투는 `OWNER_QA_PENDING`이다. 상세 결과는 `docs/qa/V122_Q1P_PERFORMANCE_AUDIT_2026-08-02.md`와 `tmp/v122_release_polish/q1_p/q1_p_inventory.{json,tsv}`에 기록했다.
8. Q1-R 권리·출처·deprecated 감사는 활성 그래픽 37개 고유 스프라이트·구조 벽 14개·오디오 76개의 파일과 source record 존재를 확인했다. legacy wall/proof-only 런타임 적중은 0개였지만, 활성 오디오 76개 OWNER 청취·권리·승격 검수와 event catalog 연결 미완료를 `SOURCE_AUDIT_PARTIAL_WITH_RELEASE_GATE`로 남겼다. 상세 결과는 `docs/qa/V122_Q1R_SOURCE_RIGHTS_DEPRECATED_AUDIT_2026-08-02.md`와 `tmp/v122_release_polish/q1_r/q1_r_inventory.{json,tsv}`에 기록했다. 다음은 I1 통합 대표 검수다.
9. I1-1 타이틀·설정 대표 검수는 실제 `1280×720` 캡처 3장과 4 assertions, 현지화·관리 UI 계약 PASS로 완료했다. 헤드폰·일반 스피커 청취와 실제 Windows 후보 조작은 `OWNER_QA_PENDING`이다. 상세 결과는 `docs/qa/V122_I1_1_TITLE_SETTINGS_REPRESENTATIVE_2026-08-02.md`에 기록했다. 다음은 I1-2 관리 화면 BGM·UI음이다.
10. I1-2 관리 화면 BGM·UI음 대표 검수는 `1280×720` 관리 캡처와 `management_castle_bustle.wav` 선택·재생 4 assertions PASS로 완료했다. 전용 관리 UI 클릭·탭 효과음 hook은 없음을 확인해 `I1-2-UI-SFX-GAP`으로 남겼고, 실제 청취는 `OWNER_QA_PENDING`이다. 상세 결과는 `docs/qa/V122_I1_2_MANAGEMENT_AUDIO_REPRESENTATIVE_2026-08-02.md`다.
11. I1-3 DAY 3 도둑 침입·집중 명령·도둑 사냥꾼 특성·혼잡 타격 대표 검수를 완료했다. 실제 소유자 플레이는 `I1-3-OWNER-01`로 남겼다.
12. I1-4 후반 일반 전투 대표 검수를 완료했다. 기본 공격·화염구·피격·결과 화면과 일반전→관리 BGM 전환을 확인했으며 실제 소유자 청취는 `I1-4-OWNER-01`로 남겼다.
13. I1-5 보스·최종전 음악·VFX 대표 검수를 완료했다. 보스 BGM·검수 예고·축성 바닥·자비의 방벽을 확인했으며 실제 소유자 청취는 `I1-5-OWNER-01`로 남겼다.
14. I1-6 Stage 01~04 오디오 공백 감사를 완료했다. 환경 loop 4개, 발소리 후보 4개, Ambience 버스·발 scheduler 부재를 확인했으며 A4 자산·A1 라우팅 대기 상태로 남겼다.
15. A0/A1/C1/V5의 선행 구현과 자동 테스트 로그는 당시 작업 사실로 보존한다. 그러나 A1-B 과밀 clipping, A1-C 130초·loop seam 청취, C1의 V3 전제·실제 접촉 화면, V5의 V4 전제·실제 전면 벽 가림이 빠졌고 같은 기능 파일도 이후 다시 바뀌었다. 따라서 당시 PASS 수치는 현재 승인에 사용하지 않으며 A1/C1/V5는 각각 계획 순서와 실제 gate에서 다시 검증한다.
16. 사용자가 DAY 3에서 가까운 일반 탐험가와 도둑이 함께 있을 때 집중 명령과 도둑 사냥꾼 특성을 실제 플레이로 확인한다.
17. 사용자가 DAY 6~30을 실제 플레이하며 대사 타이밍, 분기, 실제 승급자 초상화, DAY 29 선언, DAY 30 기본 엔딩을 확인한다.
18. 피드백이 있으면 해당 DAY/분기 또는 전투 상황만 최소 재현 테스트로 고정한 뒤 수정하고 대상 테스트를 다시 실행한다.
19. 사용자 최종검수 후에만 Full 검증과 테스트 빌드/배포 여부를 결정한다.
20. 사용자 최종검수 PASS 뒤에만 Full 검증, Windows 출시 후보 export, 실행 확인, SHA-256, 태그·Release를 진행한다. 출시판은 Windows이며 현재 Web은 테스트 전용이다.
21. `v1.2.1` 태그와 Release 자산은 이동·교체하지 않는다. Actions run 29729582970의 오디오 누락 artifact도 계속 사용하지 않는다.
22. 이슈 #39의 마지막 수동 항목인 Windows 물리 한/영 키 조합 중 상태를 실기 확인한다.
23. 실제 Android/iOS 안전 영역과 저사양 PC·모바일에서 타이틀·관리·전투 10분 발열/메모리를 선택 검수한다.
24. 채팅에 노출된 API 키를 즉시 폐기한다. 나머지 보조 cue 48개를 Lyria로 바꿀 때는 새 키를 가려진 입력으로 사용하고 단계별 청취·승격한다.
25. 실제 전투에서 스킬 24개와 관리·일반전·보스전 BGM의 음량·타이밍·반복 피로를 청취하고 필요한 자산만 재테이크 또는 dB 조정한다.
26. 사용자가 `docs/release/OWNER_ACTIONS.md`에 따라 Steamworks 계약 주체, NDA/SDA, $100 App Credit, 신원·세금/은행 검증을 완료한다.
27. 공개 App/Depot ID, 개발자·퍼블리셔명, 지원 이메일/사이트, 최종 게임명, 가격 방향과 목표 출시일을 받아 설정·개인정보 처리방침·스토어 placeholder를 채운다.
28. 권리·한국 의무·콘텐츠/AI 설문·스토어를 승인하고 Coming Soon을 제출한 뒤 Steam 설치·Cloud·Valve 심사를 진행한다.

## 아직 하지 않은 작업

- Q1-S Stage 04 투영 계약의 제품 결정 1건: `service_entrance` 포함 여부와 구역 계약/시각 object assertion 분리
- Q1-I 실제 Windows 한/영 IME·조합 중 Backspace·Enter 제출과 Mobile Web/기기 회전·탭 검수
- Q1-L P3 수정 패킷: 의회 왕관 후보 `instance_id`, 전투 목표·활성 경로 room ID, 미지 room fallback의 사용자 용어 매핑
- Q1-L 실제 UI 소유자 검수: 현재 후보와 DAY 2 `trap` 재확인, 1280×720 버튼·최대 글꼴·최장 문구·dead click 확인
- Q1-P 실제 Windows GPU·저사양 메모리/RSS·최소 10분 혼잡 전투 프레임·발열 검수
- I1-1 헤드폰·일반 스피커 실제 청취와 실제 Windows 후보의 타이틀·설정 조작·문구·음량 체감
- I1-2 관리 화면 헤드폰·일반 스피커 실제 청취와 UI 전용 클릭·탭 효과음 공백 해소
- I1-3 실제 DAY 3 도둑·집중·도둑 사냥꾼·혼잡 타격 소유자 플레이
- I1-4 후반 일반 전투 실제 소유자 청취·Windows 후보 조작
- I1-5 보스·최종전 음악·VFX 대표 검수의 실제 소유자 청취·Windows 후보 조작
- I1-6 Stage 01~04 환경음은 A4 ambience loop 4개와 연결까지 완료했다. 최대 품질 기준 남은 범위는 surface 3종 × 변형 3개 = 9개 발소리 cue, normal/heavy runtime 프로필, 발 scheduler, 최종 청취다.
- A1-C: `REVALIDATED/UNAPPROVED` — 자동 transport 계약은 재검증했지만 130초 재생·loop seam·소유자 청취가 미완료다.
- A1-D1: `REVALIDATED/UNAPPROVED` — voice cap·catalog API는 재검증했지만 실제 호출부 이관과 최종 SHA 승인은 남아 있다.
- A1-D2: `REVALIDATED/UNAPPROVED` — GameRoot·Update 3/4 라우팅은 재검증했지만 테스트 종료 teardown 정리, 전투·HUD 이관과 최종 SHA 승인은 남아 있다.
- A1-D3: `REVALIDATED/UNAPPROVED` — 전투·HUD 라우팅은 재검증했지만 실제 소유자 청취와 최종 SHA 승인은 남아 있다.
- A1-E: `REVALIDATED/UNAPPROVED` — 오디오 suite 등록·coverage는 재검증했지만 Quick/Full 전체 실행과 실제 소유자 청취·권리 승인은 남아 있다.
- C1: `REVALIDATED/UNAPPROVED` — 접촉 사건 동기화는 재검증했지만 실제 화면·장시간 배속 플레이와 최종 SHA 승인은 남아 있다.
- V5: `CATALOG_PASS / LIVE_DEPTH_PASS / SCREEN_TARGETED_PASS` — VFX 깊이 연결과 A03 이후 대표 `1280×720` 전면 벽 가림 비교를 통과했다. 정식 출시 승격은 남아 있다.
- I1-5-OWNER-01: `TARGETED_BLOCKED (historical)` — A03 이전 1280×720 캡처에서 캐릭터가 전면 벽에 묻히고 VFX가 벽 위에 분리되어 시각 승인을 보류했던 기록이다.
- V5-DEPTH-OCCLUSION-LIVE-CONTRACT: `TARGETED_PASS` — VFX depth 슬롯 연결과 21개 계약 테스트를 통과했고, A03 이후 대표 화면 재검증도 완료했다.
- I1-5-ACTOR-VISIBILITY-DISCOVERY: `TARGETED_PASS` — 대표 화면 재실행과 소스·픽셀 원인 감사를 통과했고, 벽 본체가 부모 draw에 그려지고 유닛 음수 슬롯이 그 뒤로 내려가는 계층 불일치를 발견했다. 이 원인은 다음 A03 패킷에서 보정했다.
- V4-A-03-FRONT-OCCLUDER-SCOPE: `TARGETED_PASS` — 전체 구조 벽 본체를 BackWallLayer로 분리하고 E/S 낮은 front occluder만 FrontWallLayer에 남겼다. 전용 16개 단언과 대표 화면 11개 단언·4개 캡처가 통과했고 캐릭터 몸체가 다시 보인다.
- V5-DEPTH-OCCLUSION-SCREEN-REVALIDATION: `TARGETED_PASS` — VFX live depth 21개 단언과 대표 1280×720 11개 단언·4개 캡처를 통과했고 캐릭터·지면/몸/공중 VFX·FrontWall 앞뒤 관계를 확인했다.
- V4-B-03-UI-ANCHOR-SCREEN-REVALIDATION: `TARGETED_PASS` — UI 앵커 12개 검사, 보스 대표 화면 11개 단언·4개 캡처, 피해 숫자 후반 전투 화면 13개 단언·5개 캡처를 통과했고 이름·HP·피해 숫자의 head 앵커와 겹침 여부를 확인했다.
- I1-5-OWNER-SCREEN-REVALIDATION: `TARGETED_PASS` — A03·V5·V4-B 이후 I1-5 보스 대표 `1280×720` 화면의 11개 단언·4개 캡처를 통과했고 캐릭터·VFX·UI 앞뒤 관계와 이전 벽 가림·VFX 분리 해소를 확인했다. 실제 소유자 조작·청취는 별도 gate다.
- A4-STAGE-01-LOOP-READINESS-AUDIT: `TARGETED_BLOCKED (historical)` — Stage 01 환경 loop·발소리 자산과 이벤트는 아직 없고, 기존 감사 장면의 Ambience 부재 단언이 현재 버스 상태와 어긋났던 기록이다. 다음 정렬 패킷에서 보정했다.
- A4-STAGE-01-AUDIT-TEST-ALIGNMENT: `TARGETED_PASS` — 현재 Ambience 라우팅 계약에 맞게 감사 단언 한 곳을 정렬하고 4개 단언·실패 0건을 통과했다. Stage 01 loop 자산 생성·승격·연결은 별도 승인 gate다.
- A4-STAGE-01-LOOP-SOURCE-AUTHORIZATION-GATE: `TARGETED_PASS_PENDING_APPROVAL` — A0 manifest 검증은 통과했지만 Stage 01 loop 등록·출처 원본·생성·청취·승격은 아직 없다. 다음 생성 패킷은 사용자 승인 전 실행하지 않는다.
- A4-STAGE-01-LOOP-GENERATION: `TARGETED_BLOCKED` — 사용자 승인은 받았지만 `google.genai`, `miniaudio`, `GEMINI_API_KEY`가 없어 Lyria 생성 호출을 시작하지 못했다. 환경 준비 후 재개한다.
- A4-STAGE-01-LYRIA-PREREQUISITE-GATE: `TARGETED_BLOCKED` — doctor 결과 `google.genai=MISSING`, `miniaudio=MISSING`, `GEMINI_API_KEY=NOT_SET`, 네트워크 호출 없음. 노출된 키는 사용하지 않았고 로컬 환경 준비 후 재시도한다.
- A4-STAGE-01-LYRIA-API-SMOKE: `TARGETED_PASS` — `lyria-3-pro-preview` 유료 요청 1회·예상 `$0.08`, 후보 MP3/WAV·111.842초 변환·비밀 패턴 0건을 확인했다. 제품 runtime 승격과 Stage 01 환경 loop 생성은 아직 하지 않았다.
- A4-STAGE-01-LOOP-MANIFEST-CONTRACT: `TARGETED_PASS` — `ambience_stage01_cave` planned 항목과 환경음 전용 prompt/render 계약을 추가했고 13개 단위 테스트, manifest 77개 coverage, 유료 호출 없는 1개 dry-run을 통과했다.
- A4-STAGE-01-LOOP-GENERATION-TAKE01: `TARGETED_PASS_PENDING_LISTENING` — Lyria 3 Pro 요청 1회·예상 `$0.08`, 112.887초 후보 WAV와 MP3/WAV 해시, 비밀 패턴 0건을 확인했다. 사람 청취·runtime 승격은 남아 있다.
- A4-STAGE-01-LOOP-LISTENING-GATE: `TARGETED_PASS_PENDING_PROMOTION` — 사용자 `approve`를 기록하고 후보 파일·hash·WAV 형식을 재확인했다. runtime·출처·catalog 승격은 다음 단일 패킷으로 남겼다.
- A4-STAGE-01-LOOP-PROMOTE: `TARGETED_BLOCKED` — 승인 후보 source/runtime·`SOURCE.md`·generation 기록과 v1.2.2 manifest 77개 coverage는 통과했다. 기존 단위 테스트가 기본 v0.5 manifest의 새 runtime 누락으로 차단되어 다음 정렬 패킷으로 넘겼다.
- A4-STAGE-01-POST-PROMOTE-MANIFEST-ALIGNMENT: `TARGETED_PASS` — `test_lyria_pipeline.py`가 v1.2.2 manifest와 현재 77개 runtime을 기준으로 검증하도록 정렬됐고 관련 13개 테스트가 통과했다. 다음은 event catalog 한 개 연결이다.
- A4-STAGE-01-LOOP-CATALOG-CONNECT: `TARGETED_BLOCKED` — manifest에는 77번째 `ambience_stage01_cave`가 있지만 catalog는 76개이고, 추가 후 필요한 `test_audio_event_catalog.py` 기대값 정렬이 이번 허용 경로 밖이다. catalog는 변경하지 않았다.
- A4-STAGE-01-LOOP-CATALOG-TEST-ALIGNMENT: `TARGETED_PASS` — catalog를 77개 manifest와 정렬하고 `ambience_stage01_cave`를 실제 호출 없는 `unconnected`로 등록했다. catalog 계약 테스트 7개가 통과했으며 다음은 GameRoot runtime 연결이다.
- A4-STAGE-01-LOOP-RUNTIME-CONNECT: `TARGETED_BLOCKED (historical)` — 기준 catalog 계약 7개와 MusicStateAudioTest 27개는 통과했지만, event 연결 시 필요한 Python catalog snapshot 테스트가 허용 경로 밖이라 catalog·GameRoot를 변경하지 않았다. 다음 패킷에서 허용 경로를 확장해 해소했다.
- A4-STAGE-01-LOOP-RUNTIME-CONNECT-TEST-ALIGNMENT: `TARGETED_PASS` — Stage 01 ambience event·GameRoot loop player·catalog snapshot을 정렬했고 Python catalog 7개와 Godot `MusicStateAudioTest` 36 assertions를 통과했다. loader 오류와 teardown 누수 경고가 없으며 다음은 대표 화면·청취 확인이다.
- A4-STAGE-01-LOOP-REPRESENTATIVE-CHECK: `TARGETED_PASS` — 대표 `1280×720` GUI에서 타이틀·World Render·pause·환경 설정·복귀를 확인했고 Godot `MusicStateAudioTest` 36 assertions를 통과했다. 사용자가 현재 World Render의 ambience를 직접 확인해 이상을 보고하지 않아 소유자 청취 gate까지 닫았다.
- A4-STAGE-02-LOOP-MANIFEST-CONTRACT: `TARGETED_PASS` — `ambience_stage02_indoor` planned 항목을 추가하고 active runtime 77개 coverage, Lyria 파이프라인 14개 테스트, manifest validate, 유료 없는 1개 dry-run을 통과했다. 다음은 별도 승인 후 Stage 02 후보 1개를 생성하는 패킷이다.
- A4-STAGE-02-LOOP-GENERATION-TAKE01: `TARGETED_PASS_PENDING_LISTENING` — Lyria 3 Pro 요청 1회·예상 `$0.08`로 Stage 02 후보 MP3/WAV를 생성했고, 2채널 44.1kHz·114.428초 WAV, SHA-256 일치, 키 패턴 0건을 확인했다. 사람 청취·승인과 runtime 승격은 남아 있다.
- A4-STAGE-02-LOOP-LISTENING-GATE: `TARGETED_PASS` — 사용자가 Stage 02 take 01 preview를 청취하고 `승인`했다. 후보 WAV 메타데이터와 source/preview SHA-256 일치를 재확인했으며, 다음은 source/runtime 승격 패킷이다.
- A4-STAGE-02-LOOP-PROMOTE: `TARGETED_PASS` — 승인된 take 01을 source/runtime으로 승격하고 `SOURCE.md`·generation 기록·manifest active 상태를 정렬했다. manifest validate, Lyria 파이프라인 14개 단위 테스트, source/runtime SHA·WAV 메타데이터·비밀값 패턴 검사를 통과했으며 다음은 Stage 02 event catalog 한 개 연결이다.
- A4-STAGE-02-LOOP-CATALOG-CONNECT: `TARGETED_PASS` — `ambience_stage02_indoor`를 catalog에 `lyria`·`SFX`·`unconnected`·`events=[]`로 등록하고 출처·미해결 목록·요약을 v1.2.2 manifest 78개와 정렬했다. catalog 계약 테스트 8개와 JSON 파싱을 통과했으며 다음은 실제 runtime owner·이벤트 연결이다.
- A4-STAGE-02-LOOP-RUNTIME-CONNECT: `TARGETED_PASS` — GameRoot StageAmbiencePlayer가 Stage 01/02 catalog event를 성 단계에 따라 선택하도록 연결하고 Stage 02 event를 `actual_runtime`으로 전환했다. catalog 계약 8개와 Godot `MusicStateAudioTest` 42 assertions가 통과했으며 다음은 대표 화면·실제 청취 확인이다.
- A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK: `TARGETED_PASS` — `V122StructuralWallCapture.tscn`으로 Stage 02 DAY 16 관리 화면을 1280×720에서 재렌더링하고 `MusicStateAudioTest` 54 assertions를 통과했으며, 사용자가 `assets/audio/ambience/stage02_indoor.wav`를 청취하고 `승인완료`했다.
- A4-STAGE-03-LOOP-GENERATION-TAKE01: `TARGETED_PASS_PENDING_LISTENING` — Lyria 3 Pro 요청 1회·예상 `$0.08`로 Stage 03 후보 MP3/WAV를 생성했고, 2채널 44.1kHz·112.285714초 WAV, SHA-256 일치, 키 패턴 0건을 확인했다. 사람 청취·승인은 다음 패킷으로 남겼다.
- A4-STAGE-03-LOOP-LISTENING-GATE: `TARGETED_PASS` — 사용자가 Stage 03 take 01 preview를 청취하고 `승인`했다. 후보 WAV 메타데이터와 source/preview SHA-256 일치를 재확인했으며, 다음은 source/runtime 승격 패킷이다.
- A4-STAGE-03-LOOP-PROMOTE: `TARGETED_PASS` — 승인된 take 01을 source/runtime으로 승격하고 `SOURCE.md`·generation 기록·manifest active 상태를 정렬했다. manifest validate, Lyria 파이프라인 15개 단위 테스트, source/runtime SHA·WAV 메타데이터·비밀값 패턴 검사를 통과했으며 다음은 Stage 03 event catalog 한 개 연결이다.
- A4-STAGE-03-LOOP-CATALOG-CONNECT: `TARGETED_PASS` — `ambience_stage03_keep`를 catalog에 `lyria`·`SFX`·`unconnected`·`events=[]`로 등록하고 출처·미해결 목록·요약을 manifest 79개와 정렬했다. catalog 계약 테스트 9개와 JSON 파싱을 통과했으며 다음은 실제 GameRoot runtime owner 연결이다.
- A4-STAGE-03-LOOP-RUNTIME-CONNECT: `TARGETED_PASS` — `GameRoot`의 Stage 03 ambience 분기와 `ambience.stage03.keep` 실제 이벤트를 연결하고 Stage 01·02·03 stream 교체·Ambience 버스·반복 갱신 중복 방지를 Python 9개·Godot 48개 직접 단언으로 통과했다. 기존 management 음악 teardown warning 1건은 관찰 항목으로 남겼으며 다음은 대표 화면·실제 청취 확인이다.
- A4-STAGE-03-LOOP-REPRESENTATIVE-CHECK: `TARGETED_PASS` — `V122StructuralWallCapture.tscn`으로 Stage 03 DAY 21 관리 화면을 1280×720에서 렌더링하고 화면을 확인했으며, `MusicStateAudioTest` 48 assertions와 실제 소유자 청취 승인을 통과했다. 다음은 `A4-STAGE-04-LOOP-MANIFEST-CONTRACT`다.
- A4-STAGE-04-LOOP-MANIFEST-CONTRACT: `TARGETED_PASS` — `ambience_stage04_citadel` planned 항목을 등록하고 16개 Lyria 파이프라인 테스트, manifest 80개·활성 runtime 79개 검증, 유료 없는 1회 dry-run(`$0.08` 예상)을 통과했다. 다음은 사용자 승인 후 Stage 04 후보 1개 생성이다.
- A4-STAGE-04-LOOP-GENERATION-TAKE01: `TARGETED_PASS` — v1.2.2 manifest를 명시해 `lyria-3-pro-preview` 유료 요청 1회로 take 01을 생성하고 MP3/WAV 메타데이터·SHA-256·민감정보 패턴 검사와 16개 단위 테스트를 통과했다. 후보 WAV 실제 길이는 113.800816초로 청취 승인이 남아 있으며, 다음은 `A4-STAGE-04-LOOP-LISTENING-GATE`다.
- A4-STAGE-04-LOOP-LISTENING-GATE: `TARGETED_PASS` — 사용자가 Stage 04 take 01 preview를 직접 청취하고 `승인`했다. preview SHA-256을 재확인했으며 runtime·source는 아직 미승격이다. 다음은 `A4-STAGE-04-LOOP-PROMOTE`다.
- A4-STAGE-04-LOOP-PROMOTE: `TARGETED_BLOCKED` — 승인된 take 01을 source/runtime으로 승격하고 manifest active·출처·해시·메타데이터·민감정보 검사를 통과했지만, 기존 `test_v122_planned_stage04_ambience_has_generation_contract`가 `planned`를 기대해 16개 중 1개가 실패했다. 테스트 파일은 이번 허용 경로 밖이라 다음 `A4-STAGE-04-LOOP-PROMOTE-TEST-ALIGNMENT`로 넘겼다.
- A4-STAGE-04-LOOP-PROMOTE-TEST-ALIGNMENT: `TARGETED_PASS` — Stage 04 active runtime 상태에 맞게 stale 테스트를 정렬하고 Lyria 파이프라인 16개·manifest 80개 coverage·diff check를 통과했다. 다음은 `A4-STAGE-04-LOOP-CATALOG-CONNECT`다.
- A4-STAGE-04-LOOP-CATALOG-CONNECT: `TARGETED_PASS` — `ambience_stage04_citadel`을 catalog에 `lyria`·`SFX`·`unconnected`·`events=[]`로 등록하고 summary 80 assets/71 events/11 unresolved를 manifest와 정렬했다. catalog 계약 테스트 10개와 JSON 파싱을 통과했으며 다음은 GameRoot runtime 연결이다.
- A4-STAGE-04-LOOP-RUNTIME-CONNECT: `TARGETED_PASS` — `GameRoot`에 Stage 04 ambience 분기와 `ambience.stage04.citadel` 실제 event를 연결하고 catalog를 `actual_runtime`으로 정렬했다. Stage 01~04 stream 교체·Ambience 버스·반복 갱신 중복 방지를 Python 10개·Godot 54개 직접 단언으로 통과했으며 다음은 대표 화면·실제 청취 확인이다.
- A4-STAGE-04-LOOP-REPRESENTATIVE-CHECK: `TARGETED_PASS` — `V122StructuralWallCapture.tscn`으로 Stage 04 DAY 30 관리 화면을 1280×720에서 렌더링하고 `MusicStateAudioTest` 54 assertions를 통과했으며, 사용자가 Stage 04 ambience를 `승인 완료`했다. Stage 02 대표 확인도 승인 완료되어 다음은 Stage 01~04 발소리 자산의 출처·범위 승인 gate다.
- A4-FOOTSTEP-SOURCE-AUTHORIZATION-GATE: `TARGETED_PASS_PENDING_MANIFEST_APPROVAL` — manifest 80개·catalog 80 assets/72 events·runtime·source에서 전용 발소리 0개를 확인했다. 최대 품질 범위를 surface 3종 × 변형 3개 = 9 cue와 normal/heavy runtime 프로필로 고정하고 첫 후보를 `footstep_cave_rough_01`, Lyria clip 1회 예상 `$0.04`로 제안했다. 이번 패킷의 API 호출·유료 생성은 0회다.
- A4-FOOTSTEP-CAVE-ROUGH-01-MANIFEST-CONTRACT: `TARGETED_PASS_PENDING_GENERATION_APPROVAL` — `footstep_cave_rough_01`을 mono 44.1kHz·0.28초·-6 dBFS·`planned`로 등록하고 manifest 81개/active coverage 80개, 단위 테스트 17개, 유료 호출 없는 1회 `$0.04` dry-run을 통과했다. 다음은 사용자 승인 후 Lyria clip 유료 생성 1회다.
- SOL-V122-FOOTSTEPS-BATCH-GENERATE-AND-VERIFY: `TARGETED_PASS_PENDING_USER_LISTENING` — SOL 연속 작업흐름으로 manifest 89개·발소리 9개 계약과 테스트 18개를 정렬했다. Lyria Clip 성공 요청 4회·예상 `$0.16`, 일반 필터 차단 2회·출력 0개를 기록하고 4개 source reel에서 mono 44.1kHz·16bit 고유 preview 9개를 추출했다. 세 표면 review WAV와 후보 해시·키 패턴 0건을 확인했으며 다음은 사용자 묶음 청취다.
- Q1-R P2 release gate: manifest 기반 활성 오디오 76개 일대일 event 매핑과 OWNER 권리·청취·승격 검수
- A1 `combat_dungeon_pressure` 116.909초 runtime과 v0.5 120초 계약 차이의 loop 검증
- Q1-R 활성 오디오 76개 청취·권리·1.2.2 승격 OWNER 검수와 활성 source 문서 고정 필드 보완
- 사용자 제공 1.2.1 원본의 SHA-256·수정 시각 전후 비교와 후보 Windows 빌드 실제 이어하기
- 서로 다른 해상도·명암·그림체를 가진 나머지 대표 그래픽 목록화와 종류별 교체
- DAY 3에서 가까운 일반 탐험가와 도둑이 함께 있을 때 집중 명령·도둑 사냥꾼 특성의 실제 플레이 체감 확인
- v1.2.2 사용자 최종검수 체크리스트의 DAY 1~30·1.2.1 저장 호환·Update 2~4·화면·입력 실기 확인
- v1.2.2 Full 검증, Windows·Steam 후보 export, 실행 확인, hash, 태그·Release·배포
- Windows 네이티브 Microsoft 한국어 IME의 물리 한/영 키 조합 중 상태 검수(확정 한글 입력·수정·화면 전환은 확인)
- 실제 Android/iOS의 지시 HUD·확대 글꼴 실기 검수(PC Web은 확인)
- v0.5 플랫폼 성능 수정의 실제 Android/iOS·저사양 PC 장시간 발열/메모리 검수
- Steamworks 가입·계약·등록비·세금/은행 검증과 App/Depot ID 발급
- Steamworks 포털 입력, SteamPipe 업로드, 두 PC Cloud 및 설치 검수, Valve 스토어·빌드 승인
- Coming Soon 최소 14일과 정식 Steam 출시
- 정식 `v0.4.0` 태그와 해당 출시 빌드
- Lyria 3 확장 자산의 실제 플레이 믹스 청취와 나머지 기존 보조 cue 48개 후보 생성·승격
- 제품 4.0 이후 확장 개발과 구 `v0.6` 기획 묶음의 제품 출시 번호 확정
