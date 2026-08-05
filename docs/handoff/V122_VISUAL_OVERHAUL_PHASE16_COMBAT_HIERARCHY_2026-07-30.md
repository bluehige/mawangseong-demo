# v1.2.2 시각 개편 16단계 캐릭터 접지·전투 HUD 계층 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요

## 2. 적용한 시각 원칙

- 전장은 배경·경로·캐릭터가 먼저 읽히고 HUD는 가장자리의 얇은 rail로 남는다.
- 캐릭터 주변 순서는 `접지 → 선택 → 상태 VFX → 체력 → 전술 경고`로 고정한다.
- 이름과 체력은 상시 장식이 아니라 선택·피해·위협을 설명할 때만 사용한다.
- 일반 선택은 저채도 보라, 즉시 판단이 필요한 대상과 경고만 황금·적색을 사용한다.
- 명령 대상은 방 전체를 덮지 않고 실제로 클릭해야 할 anchor만 강조한다.

## 3. 캐릭터 접지·배경 융화

- 지상 유닛에는 화면 바닥 투영과 맞는 `1.0:0.31` contact shadow를 추가했다.
- 비행 유닛은 더 작고 옅은 `0.72:0.20` 그림자로 높이를 구분한다.
- 기존 원형 선택 링을 아이소메트릭 타원형 저채도 보라 marker로 바꿨다.
- 정상 상태의 비선택 유닛은 이름·체력을 숨긴다.
- 선택, 피격, 체력 50% 이하, 목표형 적 위협 때 이름을 표시한다.
- 체력 bar는 선택·피격·위협 또는 실제 체력 손실이 있을 때만 표시한다.
- 이름에는 얇은 암색 outline을 넣어 배경과 섞이되 별도 카드처럼 보이지 않게 했다.

## 4. 전투 HUD 계층

- `V122CombatResultViewModel.design_layout_contract()`를 실제 HUD와 입력 hit 영역의 단일 배치 기준으로 사용한다.
- 1920 Standard:
  - 상단 왕좌 rail `520×58`
  - 하단 명령 rail `912×120`
  - 하단 전체 HUD는 y `944` 이후에 배치
- 1366/1280 Compact:
  - 상단 왕좌 rail `600×68`
  - 하단 명령 rail `1040×148`
  - 하단 전체 HUD는 y `916` 이후에 배치
- Compact는 Standard를 단순 축소하지 않고 버튼 높이·글자 크기를 별도로 확보한다.
- 왕좌·위협·명령 panel 배경 alpha와 황동 경계를 낮춰 전장보다 먼저 보이지 않게 했다.
- 운영 지침, 명령, 속도, 특수 전력을 서로 겹치지 않는 동일 rail 안의 구역으로 정리했다.
- 소형 유닛 inspector와 입력 차단 영역도 같은 배치 계약을 사용한다.

## 5. 명령 대상 표시

- 집결·비상 후퇴의 방어구역 후보는 전체 방 타일을 황금색으로 칠하지 않는다.
- 각 후보의 실제 anchor room 중심에 작은 diamond·bracket·label만 표시한다.
- 시설·적 대상은 기존 직접 클릭 방식과 instance/slot ID를 유지한다.
- 별도 대상 확정 drawer를 열지 않고 전장 클릭 즉시 발동하는 계약을 유지한다.

## 6. 대상 테스트

| 테스트 | 결과 | 범위 |
|---|---|---|
| `V122CombatVisualHierarchyTest.tscn` | PASS | 접지·선택·이름·체력·경고 정보 예산 |
| `V122CombatUISimplificationTest.tscn` | PASS, 85 assertions | 1920 Standard·1366/1280 Compact·명령 HUD 계약 |
| `V122CommandButtonIntegrationTest.tscn` | PASS | 실제 버튼→전장 대상→즉시 명령, inspector, hit 영역 |
| `git diff --check` | PASS | 관련 코드·문서 공백 오류 |

통합 테스트의 구형 단일 전선 fixture는 현재 제품 기본값인 이중 전선의 유효한 방어구역 anchor를 사용하도록 갱신했다. 제품 로직을 구형 fixture에 맞춰 되돌리지 않았다.

Godot 종료 시 기존 ObjectDB/resource leak 경고가 남았지만 테스트 결과는 PASS이며 이번 HUD 변경의 기능 실패는 아니다.

전체 회귀, 실제 플레이·시각 캡처, Windows/Web 빌드는 수행하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 다음 작업

1. 사용자 요청대로 전체 QA와 전체 플레이 검수는 계속 보류한다.
2. `trap` 내부 ID가 사용자 문구로 노출되는 경로를 제거한다.
3. DAY 1 선택과 결산 결과의 인과 설명을 연결한다.
4. 이후 UI·재미 게이트를 다시 확인한다.

## 8. 작업 트리

- 기존 대규모 사용자 변경을 보존했다.
- 이번 단계 파일은 미커밋 상태다.
- 빌드·커밋·푸시하지 않았다.
