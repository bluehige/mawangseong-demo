# v1.2.2 Luna 작업 트리 감사·사고 보정 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: 현재 브랜치 HEAD `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 미푸시, 원격 같은 브랜치보다 2커밋 앞섬
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: Luna가 만든 현재 공유 작업 트리를 검수하고 확정 사고를 수정한다.
- 완료 조건: 런타임에서 재현되는 확정 결함을 최소 범위로 고치고 관련 테스트·1280×720 대표 화면을 확인하며, 미완료 페이즈를 완료로 적은 문서를 바로잡는다.
- 범위에서 제외한 사항: 전체 회귀·전체 플레이, V3 접지 전체 구현, V4-A 깊이 구조 전면 교체, 신규 캐릭터 이미지 생성, 빌드·커밋·푸시.

## 3. 완료한 작업

- 구현: Update 4 6종 셀 경계 절단 복구, 투명 sheet 재크로마 방지, 승급·왕관 sprite 보존, `moon_tracker` 신규 계약·방어 출전 차단, 캡처 실제 1280×720 보정.
- 스토리 및 데이터: `moon_tracker.combat_asset_state` 추가. 기존 저장의 계약 소유 기록은 보존하고 잘못된 전투 출전만 해제한다.
- 밸런스: 변경 없음.
- UI/UX: 신규 계약 후보를 준비된 4종으로 제한하고 카드들을 가운데 정렬. 기존 루미는 `예비 · 전투 외형 준비 중`으로 표시하고 출전 버튼을 비활성화한다.
- 저장 및 호환성: 기존 `selected_contract_ids`와 성장 자료는 유지하고 deployment만 제거한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/prepare_v122_combat_runtime_sprites.py` | 셀 경계 관통 성분 복구·공통 여백·전체 둘레 검증 | 완료 |
| `assets/sprites/enemies/update4/region/normalized/` 6종 PNG | 복구된 768×768 RGBA runtime sheet | 완료, V3 최종 접지 대기 |
| `data/v122/combat_visual_profiles.json` | 실측값·runtime 준비 상태·크로마 비적용 | 완료 |
| `scripts/core/DataRegistry.gd` | 정확한 sprite 경로만 profile 치환 | 완료 |
| `scripts/units/Unit.gd` | 실제 알파 기반 크로마 셰이더 선택 | 완료 |
| `data/update2_contracts.json` | 루미 잘못된 전투 원본 차단 상태 | 완료 |
| `scripts/game/GameRoot.gd` | 신규 후보·기존 저장·편성·방어 출전 gate | 완료 |
| `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd` | 실 PNG·셀 둘레·승급·투명 시트 회귀 | 완료 |
| `tools/tests/V122MoonTrackerCombatAssetGateTest.gd/.tscn` | 신규/기존 저장의 전투 노출 차단 회귀 | 완료 |
| `tools/V122CombatUpdate4PacketCapture.gd/.tscn` | Update 4 6종 전용 1280×720 비교판 | 완료 |
| `tools/V122CombatPolishCapture.gd` 및 packet capture 3종 | 실제 1280×720 content scale | 완료 |
| `tools/V122MoonTrackerGateCapture.gd/.tscn` | 계약·편성 실제 1280×720 검수 | 완료 |
| `tools/audio/test_audio_event_catalog.py` | 수량 하드코딩 제거 | 완료 |
| `assets/source/imagegen/update4_region_enemies/SOURCE.md` | source/runtime·후처리 기록 정정 | 완료 |
| `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md` | 순서 위반·미완료 gate·상태 소유권 정정 | 완료 |
| `docs/qa/V122_LUNA_WORK_AUDIT_2026-08-02.md` | 통합 감사 근거 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션의 현재 권위 판정 갱신 | 완료 |

Luna의 오디오·C1·V5 등 기존 미커밋 구현은 되돌리지 않았다. 이번 감사가 직접 수정하지 않은 기존 사용자 변경, 특히 Update 4 원본 `.png.import` 6개와 기존 `.uid`류도 그대로 보존했다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 세션에서는 사용 안 함. 기존 GPT 생성 원본만 결정적으로 재처리했다.
- 생성 모델: 해당 없음. 기존 기록은 `GPT internal image generation`.
- 생성 원본 경로: `assets/source/imagegen/update4_region_enemies/`
- `SOURCE.md` 경로: `assets/source/imagegen/update4_region_enemies/SOURCE.md`
- 런타임 최종 자산 경로: `assets/sprites/enemies/update4/region/normalized/`
- 프롬프트/후처리/크롭/알파 처리 요약: 프롬프트 변경 없음. 전체 시트 연결 성분 재배정, 공통 정사각 창·축소율, 6px 여백, premultiplied LANCZOS와 alpha-preserving despill 적용.
- 게임 연결 및 실제 렌더 확인 결과: Update 4 6종과 계약 화면을 1280×720에서 확인. 최종 접지는 V3 대기.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | sprite prep `v1-c`, `v1-d` check | PASS, 각 3 records | `tmp/v122_release_polish/v1_c/`, `v1_d/` |
| 2 | visual profile/runtime profile 계약 | PASS | `tools/tests/V122CombatVisual*ContractTest.tscn` |
| 3 | moon tracker gate | PASS | `tools/tests/V122MoonTrackerCombatAssetGateTest.tscn` |
| 4 | Popo/Silky 기존 전투 회귀 | PASS, 20/24 assertions | 각 test scene |
| 5 | Update 2 roster smoke | PASS, 68 assertions | `tools/Update2ContractRosterSmokeTest.tscn` |
| 6 | Python audio catalog | PASS, 6 tests | `tools/audio/test_audio_event_catalog.py` |
| 7 | 1280×720 실제 렌더 | PASS, 계약 2화면·Update 4 6종 | `tmp/v122_release_polish/` |
| 8 | Godot editor parse/import | PASS | 대화 실행 로그 |
| 9 | `git diff --check` | PASS, 줄바꿈 변환 경고만 있음 | 대화 실행 로그 |
| 10 | 전체 회귀 테스트 | NOT_REQUESTED | N/A |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `asset_data_audit` | 현재 공유 작업 트리 자산·데이터 | N/A | 셀 절단, 재크로마, 루미 잘못된 원본 | 전처리·shader·gate 수정 | QA 문서 | TARGETED PASS |
| 1 | `runtime_visual_audit` | DataRegistry·Unit·VFX 깊이 | N/A | 승급 덮어쓰기, 실제 벽 가림 미검증 | fallback 수정, V5 완료 취소 | QA 문서 | fallback PASS / V5 OPEN |
| 1 | `scope_docs_audit` | 계획·핸드오프·suite 범위 | N/A | 순서·상태·증거 과장 | 계획·CURRENT 현재 판정 정정 | 본 문서 | 문서 정정 완료 |

- 남은 P1/P2 지적: P1 2건, P2 2건. V2-P4 정체성 자산, V4/V5 깊이·벽 가림, V3 접지, 오디오 실제 gate.
- 실행하지 못한 필수 검수와 이유: 최종 기능 SHA 검수는 사용자가 커밋을 요청하지 않았고 작업 트리가 혼합 미커밋 상태라 실행 불가. 전체 회귀는 요청되지 않음.
- PASS 이후 기능·데이터·자산 변경 여부: 관련 대상 테스트 뒤에는 문서 정정만 했고 `git diff --check`도 통과했다.

### 정책 CI용 최종 승인 필드

- Review task ID: `LUNA-WORKTREE-AUDIT-2026-08-02`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Review range: `N/A — efab13e7f9a2c1e2bd059eb8abf4cc409710380d 위 작업 트리`
- Remaining P1/P2: `P1 2 / P2 2`
- Final review result: `FAIL — 대상 사고 수정은 통과했으나 출시 승인 아님`

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: V4-A/V5의 실제 Unit·전면 벽·VFX 깊이가 아직 불일치한다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 루미 전투 원본 차단. 공유 정체성 자산 4종은 V2-P4에서 전용 자산 필요.
- 외부 환경/도구 제약: 실제 장시간 청취와 소유자 플레이는 이번 범위에서 수행하지 않음.

## 8. 다음 작업 순서

1. 현재 감사 수정 범위를 사용자가 확인하면 의도한 파일만 커밋하고 최종 기능 SHA를 고정한다.
2. 계획 순서대로 V2-P4 정체성 자산을 해결한 뒤 V3 접지, V4-A 깊이·벽 가림을 구현한다.
3. 그 뒤에만 C1/V5 실제 1280×720 gate와 A1 청취 gate를 다시 수행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`, 원격보다 2커밋 앞섬, 대량 수정·미추적 파일 존재.
- 미커밋 파일: Luna 선행 구현, 이번 감사 수정과 문서가 함께 존재.
- 의도하지 않은 기존 변경: Update 4 원본 import·여러 uid 포함. 되돌리지 않음.
- 스태시 또는 별도 작업공간: 사용 안 함.
- 빌드/캡처 산출물 위치: `tmp/v122_release_polish/`; 커밋 대상 아님.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청된 검수 에이전트 감사 완료
- [ ] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록

Related tests: 전처리 2패킷, visual profile/runtime, moon tracker gate, Popo/Silky, Update 2 roster, audio catalog, editor parse가 통과했다.
UI check: 1280×720 Update 4 6종과 계약 후보·기존 루미 예비 화면을 실제 렌더로 확인했다.
Unresolved issues: V2-P4 전용 정체성 자산, V3 접지, V4/V5 깊이·벽 가림, A1/C1 실제 청취·화면 gate가 남아 있다.
