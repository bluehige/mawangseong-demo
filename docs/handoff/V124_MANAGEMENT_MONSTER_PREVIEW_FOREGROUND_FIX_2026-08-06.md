# v1.2.4 후보 몬스터 배치 미리보기 전경 레이어 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: 제품 `1.2.4` 후보
- 작업 브랜치: `main` 작업 트리에서 진행
- 기준 커밋 SHA: `5082a86f5a25d098b7f1c040958bd14da703e578`
- 마지막 커밋 SHA: 기준 커밋과 동일. 이번 변경은 아직 미커밋이다.
- 정식 `v1.2.3` 태그·Release는 변경하지 않는다.

## 2. 사용자 요청과 원인

- 요청: 관리 화면에서 몬스터를 배치할 때 몬스터가 맵 뒤에 박혀 보여 배치 위치를 확인하기 어렵다.
- 원인: 몬스터 미리보기를 `GameRoot`의 기본 그리기에 섞어 그렸고, 이후 `FrontWallLayer`·`ObjectFrontLayer`가 더 높은 깊이에서 그려져 미리보기를 가렸다.

## 3. 구현 완료 내용과 변경 파일

| 경로 | 변경 내용 |
|---|---|
| `scripts/map/DungeonRenderer.gd` | 미리보기 그리기 대상을 전달받도록 바꾸고, 배치 전경 오버레이에서도 같은 렌더 함수를 재사용한다. |
| `scripts/game/GameRoot.gd` | 분기 본체에서 미리보기를 제거하고 `WorldOverlayLayer`에서 그리도록 연결했다. 오버레이 깊이를 `60`으로 설정해 맵 전면 벽·소품보다 앞에 표시한다. 전투 유닛 깊이 계약은 변경하지 않았다. |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점과 미해결 직접 확인 항목을 갱신했다. |
| `docs/handoff/V124_MANAGEMENT_MONSTER_PREVIEW_FOREGROUND_FIX_2026-08-06.md` | 이번 수정의 원인·변경·검증 상태를 기록했다. |

## 4. 테스트와 검증

- `git diff --check`: PASS
- 배치 미리보기 정적 계약 검사: `TARGETED_MANAGEMENT_PREVIEW_CONTRACT: PASS`
- 확인한 계약: 미리보기 대상 전달, 관리 오버레이 호출, 기존 기본 그리기 호출 제거, 오버레이 `z=60`
- Godot 직접 실행: BLOCKED. 현재 세션에서 Godot 실행 파일을 찾지 못해 관리 화면 대표 해상도 부팅과 실제 시각 확인을 하지 못했다.
- 전체 회귀·전체 플레이·빌드·배포: 사용자 요청 범위가 아니므로 실행하지 않았다.

## 5. 미해결 문제와 다음 순서

1. Godot 실행 환경에서 관리 화면을 1회 열고 모든 배치 몬스터가 맵 전면에서 보이는지 확인한다.
2. 사용자가 대표 화면을 확인해 승인하면, 그때 필요한 경우에만 후속 시각 보정을 한다.
3. 직접 화면 확인 전에는 빌드·릴리스 완료로 기록하지 않는다.

## 6. 작업 트리·원격 상태

- 기준 브랜치: `main`
- 미커밋 파일: 기존 곱 도둑 AI 수정 파일과 이번 `GameRoot.gd`, `DungeonRenderer.gd`, 핸드오프 문서
- 원격 푸시: 하지 않음
- 정식 출시 태그·Release: 변경 없음

## 7. 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_BLOCKED_GODOT_UNAVAILABLE
