# v1.2.2 V2-P4D 미미 자산 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치/기준 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 패킷: `V2-P4D-ASSET-MIMIC`
- 커밋/푸시: 이번 turn에서는 수행하지 않음

## 2. 목표와 완료 조건

문서에 잠긴 현재 패킷 하나만 처리해 `mimic_porter` 전용 기본 전투 자산을 만들었다. 생성 원본, 출처 기록, 4×4 16프레임 RGBA 런타임 시트와 직접 자산 검수를 완료했다.

제품 데이터, 전투 프로필, 씬, 공통 렌더러는 변경하지 않았다. 실제 게임 연결과 전투 화면 확인은 `V2-P4D-CONNECT-MIMIC`의 범위다.

## 3. 구현 완료

- 보물상자형 미미 캐릭터를 GPT 내부 이미지 생성으로 생성했다.
- `idle_down 2 + down 2 / move_down 4 / attack_down 4 / skill_down 4` 순서의 16프레임을 구성했다.
- 크로마키를 투명화하고 프레임별 캐릭터 영역을 공통 크기로 맞췄다.
- 모든 런타임 셀의 발 기준선을 `y=183`으로 통일했고, 셀 외곽 침범과 초록색 잔류를 제거했다.

## 4. 변경 파일

| 경로 | 변경 내용 | 상태 |
|---|---|---|
| `assets/source/imagegen/update4_contract_monsters/mimi/mimi_combat_sheet_chroma_2026-08-04.png` | 생성 원본 RGB 1254×1254 | 완료 |
| `assets/source/imagegen/update4_contract_monsters/mimi/SOURCE.md` | 생성 모델·날짜·버전·원본/런타임 경로·후처리 기록 | 완료 |
| `assets/sprites/monsters/update4/monster_mimi_sheet.png` | RGBA 768×768, 192×192 셀 16프레임 | 완료 |
| `docs/qa/V122_V2_P4D_MIMIC_ASSET_2026-08-04.md` | 직접 자산 검수 결과 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 패킷 잠금 갱신 | 완료 |

## 5. 실행한 테스트와 확인

- Pillow 단일 자산 직접 검사: `MIMI_ASSET_DIRECT_TEST: PASS`
- 확인 항목: 원본/런타임 크기·모드, 16셀 visible/unique, 셀 외곽 알파, 공통 발 기준선, 초록색 잔류 픽셀
- 결과: visible `16/16`, unique `16/16`, foot bottom spread `0px`, perimeter bad `0`, green residual `0`
- 전체 회귀·전체 플레이·검수 에이전트: `NOT_REQUESTED`

## 6. 미해결 및 다음 작업

- 미미 제품 데이터/profile 연결과 실제 전투 화면 표시는 아직 하지 않았다.
- 다음 패킷 제안은 `V2-P4D-CONNECT-MIMIC` 하나다.
- 다음 패킷에서는 `data/monsters.json`과 `data/v122/combat_visual_profiles.json`의 미미 1개 항목만 연결하고 직접 계약 검사를 수행한다.

## 7. 정책 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 8. 작업 트리와 인계

- 작업 트리는 기존 Luna/사용자 변경을 포함한 dirty 상태이며, 이번 패킷의 파일만 추가했다.
- 기존 변경을 되돌리거나 정리하지 않았다.
- 원격 푸시: `NOT_REQUESTED`
