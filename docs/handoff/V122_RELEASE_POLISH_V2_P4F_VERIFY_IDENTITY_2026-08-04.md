# v1.2.2 출시 마무리 핸드오프 — V2-P4F 정체성 비교

## 기본 정보

- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V2-P4F-VERIFY-IDENTITY`
- 결과: `IDENTITY_VERIFY_PASS_WITH_NORMALIZATION_PENDING`
- QA 문서: `docs/qa/V122_V2_P4F_VERIFY_IDENTITY_2026-08-04.md`

## 이번 패킷에서 한 일

다섯 계약 캐릭터(`spore_healer`, `stone_sentinel`, `war_drummer`, `mimic_porter`, `moon_tracker`)의 source/runtime 정체성, 시트 규격, 셀 경계, 중앙 아트 높이와 공통 바닥 기준을 읽기 전용으로 대조했다. 다섯 런타임은 모두 768×768 RGBA 4×4 시트이며 16개 셀이 서로 다르고, 셀 외곽 알파 침범은 0이다. 캐릭터별 source/runtime 해시도 모두 고유해 정체성 자산을 잘못 공유하지 않는다.

1280×720 임시 비교판에서 버섯 치유사, 바위 골렘, 해골 북 연주자, 보물상자 미믹, 달빛 박쥐 정찰자의 실루엣과 체격 등급이 구분되는 것을 확인했다. `war_drummer`의 바닥 spread 1픽셀은 계획 허용치 2픽셀 안이다.

제품 데이터, 런타임 자산, 공통 코드, 씬은 이번 패킷에서 수정하지 않았다. 대신 `spore_healer`·`stone_sentinel`·`mimic_porter` 가장자리의 저알파 녹색 계열 잔여(각 517/95/55픽셀)를 다음 자산 정규화 후보로 기록했다. 강한 크로마 기준에서는 다섯 자산 모두 0이다.

## 검증 증거

- Python 직접 감사: `V122_P4F_IDENTITY_DIRECT_TEST: PASS_WITH_FINDINGS`
- Godot 전투 시각 프로필 계약: `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- `git diff --check`: PASS
- 임시 비교판: `C:\Users\blueh\AppData\Local\Temp\v122_p4f_identity_comparison_1280x720.png` (저장소 미추가)

전체 회귀·전체 플레이·정식 빌드·커밋·푸시는 이번 패킷에서 실행하지 않았다. 현재 작업 트리에는 사용자와 Luna의 기존 미커밋 변경이 섞여 있으므로 되돌리거나 정리하지 않았다.

## 변경 파일

이번 패킷의 의도한 변경은 아래 문서 3개뿐이다.

- `docs/qa/V122_V2_P4F_VERIFY_IDENTITY_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V2_P4F_VERIFY_IDENTITY_2026-08-04.md`
- `docs/handoff/CURRENT.md`

## 미해결과 다음 순서

1. 저알파 녹색 잔여는 자산을 다시 만들거나 후처리할 별도 자산 패킷에서만 다룬다.
2. 다음 단일 패킷은 V3 공통 접지 구조다. 유닛 월드 위치를 발 바닥 root로 고정하고 움직이는 body, 그림자·선택 표시의 기준을 분리한 뒤 기존 `V122CombatVisualHierarchyTest`로 직접 확인한다.
3. V3의 동작·발 기준을 통과하기 전에는 V2 자산을 `NORMALIZED_PASS`로 승격하지 않는다.

## 작업 트리와 정책

- 커밋: 생성하지 않음
- 원격 푸시: 하지 않음
- 작업 트리: 기존 미커밋 파일 포함, 혼합 상태 유지
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
