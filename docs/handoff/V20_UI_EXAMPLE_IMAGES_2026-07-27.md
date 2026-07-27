# V20 UI 예시 이미지 업로드 핸드오프

## 메타데이터

- 작성일: 2026-07-27
- 목표 버전: `2.0.0`
- 작업 브랜치: `test/v20-ui-examples`
- 기준 브랜치와 SHA: `origin/codex/v20-important-revision` / `fb10468b4f48340c0b644d577285409ffd75c565`
- 마지막 커밋 SHA: 이 문서를 포함하는 현재 Git HEAD 참조
- 원격 푸시 여부: `origin/test/v20-ui-examples`

## 요청과 범위

- 요청 사항: UI 예시 이미지를 GitHub에서도 바로 볼 수 있게 올린다.
- 완료 조건: 최종 3단계 시안과 현재 실제 구현 화면을 PNG로 확인할 수 있다.
- 제외: 사용자 피드백 이전 8화면 초안, 정식 runtime 시설 이미지, Web 빌드.

## 완료한 작업

- `건물 배치`, `몬스터 육성`, `수비대 배치` 디자인 예시 3장을 추가했다.
- 현재 구현된 건물 배치 화면의 실제 `1280×720` 캡처 1장을 추가했다.
- 몬스터 육성 시안의 훈련 수치는 예시이며 실제 기능이 아니라는 설명을 README에 기록했다.
- 소스 브랜치의 코드·데이터·게임 runtime 자산은 수정하지 않았다.

## 변경 파일

| 경로 | 목적 |
|---|---|
| `docs/review/v20-ui-examples/README.md` | GitHub 이미지 목록과 주의사항 |
| `docs/review/v20-ui-examples/01_facility_design.png` | 건물 배치 최종 디자인 예시 |
| `docs/review/v20-ui-examples/02_growth_design.png` | 몬스터 육성 최종 디자인 예시 |
| `docs/review/v20-ui-examples/03_guard_placement_design.png` | 수비대 배치 최종 디자인 예시 |
| `docs/review/v20-ui-examples/04_current_facility_implementation.png` | 실제 구현 화면 |

## 자산 기록

- 생성 모델: 해당 없음. 기존 HTML 시안 렌더와 실제 게임 실행 캡처다.
- 생성 원본과 `SOURCE.md`: 해당 없음. 게임 runtime 그래픽이 아니다.
- 최적화 runtime 자산: 없음.
- 실제 연결 확인: 게임에서 읽지 않는 리뷰 전용 파일이다.

## 최소 검수

- Related tests: 코드 변경이 없어 재실행하지 않음. 기준 구현 커밋의 `V20PlacementUxTest` 35개 PASS 결과를 유지한다.
- UI check: 실제 구현 캡처는 Windows OpenGL `1280×720`에서 생성됐으며 겹침·잘림이 없음을 확인했다.
- Unresolved issues: 몬스터 육성과 수비대 배치의 실제 구현 캡처는 아직 없고 디자인 예시만 포함한다. 정식 시설 이미지 20장도 미제작 상태다.

## 다음 작업

1. 정식 그래픽 작업을 시작할 때 바리케이드 4방향 기준 시트를 먼저 제작한다.
2. 실제 성장·수비대 화면 캡처가 필요하면 해당 화면만 추가한다.

## 작업 트리와 원격 상태

- 미커밋 파일: 이 문서를 포함한 리뷰 이미지 변경을 커밋할 예정
- 원격 푸시: `origin/test/v20-ui-examples`
- 제품 브랜치 병합: 금지. 리뷰 전용 브랜치로 유지
