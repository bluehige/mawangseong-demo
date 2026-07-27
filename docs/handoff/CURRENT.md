# 현재 작업 핸드오프

최종 갱신: 2026-07-27

## 지금 바로 알아야 할 것

- 작업 브랜치: `test/v20-ui-examples`
- 기준 브랜치와 SHA: `origin/codex/v20-important-revision`의 `fb10468b4f48340c0b644d577285409ffd75c565`
- 작업 시작 HEAD: `86cee02ab16b6afdab94af7d6152866de4eeed61`
- 현재 목표: 핵심 재미 UI 예시 이미지를 GitHub에서 바로 확인할 수 있게 게시
- 구현 상태: `건물 배치 → 몬스터 육성 → 수비대 배치` 3단계와 성장 상태 저장을 구현하고 관련 최소 검수를 통과했다.
- 그래픽 상태: 기존 v3 시설 그림은 기능 확인용으로 임시 연결했다. 정식판용 시설 5종×4방향 20장은 아직 생성하지 않았고 양산 계획만 확정했다.
- 공개 상태: Web 친구 테스트 빌드는 이번 작업으로 다시 만들거나 배포하지 않았다.

## 현재 기준 문서

- 최소 검수 정책: `docs/TESTING_POLICY.md`
- DAY 1~5 핵심 행동: `docs/design/V20_DAY1_5_VALIDATION_CONTRACT.md`
- 핵심 준비 UI 계획: `docs/design/V20_CORE_FUN_UI_REVISION_PLAN_2026-07-26.md`
- 핵심 준비 화면 시안: `docs/design/V20_CORE_FUN_UI_MOCKUPS_2026-07-26.html`
- 시설 그래픽 양산 계획표: `docs/design/V20_CORE_FUN_ART_PRODUCTION_PLAN_2026-07-26.md`
- 이번 구현 핸드오프: `docs/handoff/V20_CORE_FUN_UI_IMPLEMENTATION_2026-07-26.md`
- 예시 이미지 목록: `docs/review/v20-ui-examples/README.md`
- 예시 이미지 업로드 핸드오프: `docs/handoff/V20_UI_EXAMPLE_IMAGES_2026-07-27.md`
- 친구 테스트 절차: `docs/playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md`

이전 정식판 UI 검토 자료는 `V20_OFFICIAL_UI_*` 문서에 보존한다. 사용자가 폐기한 단순화 초안과 구조 SVG는 구현 기준으로 사용하지 않는다.

## 제품과 브랜치 상태

- `main`은 검수된 안정판만 가리킨다.
- 제품 `1.2.1` 공개 태그·Release·빌드는 유지한다.
- `release/v2.0`은 DAY 1~5 실험선이며 공개 출시선이 아니다.
- 구현은 `origin/codex/v20-important-revision`, 리뷰용 이미지는 `origin/test/v20-ui-examples`에 푸시했다.

## 구현된 준비 흐름

1. 건물 배치
   - 실제 시설 5종만 표시한다.
   - 시설 카드와 지도 설치 토큰에 같은 prop을 재사용한다.
   - 기존 좌표, 비용, 설치·교체·되돌리기 규칙을 유지한다.
2. 몬스터 육성
   - 푸딩·곱·핀의 실제 초상과 실제 특화 두 갈래만 표시한다.
   - `data/specializations.json`의 `facility_synergy`로 추천 건물을 표시한다.
   - 한 번 확정한 특화는 세션과 저장에 보존한다.
   - 레벨·EXP·유대도 저장 왕복한다.
3. 수비대 배치
   - 건물 배치와 같은 지도와 좌표를 사용한다.
   - 설치된 건물 그림을 남긴 채 몬스터만 배치한다.
   - 현재 이름, 역할과 추천 건물만 간단히 표시한다.

기존 저장과 친구 테스트 호환을 위해 세션 schema는 `3`을 유지하고 새 필드는 기본값이 있는 선택 필드로 추가했다. 일일 훈련 횟수와 훈련 비용은 밸런스 계약이 없으므로 이번 구현에서 만들지 않았다.

## 그래픽 양산 범위

- 고정 제작량: 시설 5종×4방향 = runtime PNG 20장
- 생성 원본: 시설별 4방향 시트 1장씩, 총 5장
- 1차 기준: 바리케이드 시트 1장을 먼저 승인
- 2차 양산: 승인된 기준으로 병영·감시 초소·미끼 보물실·회복 둥지 4종
- 재사용: 기존 마왕성 지도, 푸딩·곱·핀 초상
- 코드 처리: 선택 테두리, 설치 가능 빛, 범위, 경고와 카드 배경

## 간소화된 검수 결과

- Related tests: `tools/tests/V20PlacementUxTest.tscn` 35개 항목 PASS
- UI check: Windows OpenGL `1280×720` 실제 렌더 캡처 실행 36개 항목 PASS
- 대표 화면: 건물 배치 단계에서 지도·시설 카드·3단계 탭·하단 행동 버튼의 겹침과 잘림 없음
- Godot 스크립트 확인: headless editor 시작·종료 성공, 파싱 오류 없음
- 전체 회귀·전체 플레이·별도 검수 에이전트: 요청되지 않아 실행하지 않음
- Review task ID: `NOT_REQUESTED`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 미해결과 다음 작업

1. 사용자가 그래픽 생산을 지시하면 바리케이드 4방향 기준 시트부터 생성한다.
2. 기준 시트 승인 뒤 나머지 4종을 한 묶음으로 양산하고 `assets/props/v20/`에 연결한다.
3. 사용자가 친구 테스트 갱신을 요청하면 현재 커밋을 기준으로 Web 데모를 다시 빌드하고 실제 배포본을 확인한다.
4. 일일 훈련 행동은 비용·해금·횟수 계약을 먼저 정한 뒤 별도 작업으로 추가한다.

## 작업 트리와 원격

- 의도한 변경: V20 준비 UI·세션·저장·관련 테스트·계약·시안·양산 계획·핸드오프
- 로컬 캡처와 Godot 자동 생성 잡파일: 커밋하지 않음
- 원격 푸시: `origin/test/v20-ui-examples`
