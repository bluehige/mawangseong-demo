# v1.2.5 출시 차단 결함 수정 검수서

- 작성일: 2026-08-10
- 기준 검수: `docs/qa/V124_WINDOWS_FINAL_COMPLETION_REVIEW_2026-08-10.md`
- 기준 SHA: `1bbeaa2d467fe9d8fcaa3d8489096a456ce5048a`
- 대상: Windows 정식판과 동일 소스의 Web 배포판
- 현재 판정: 관련 수정·대표 화면 `TARGETED_PASS`; 최종 Full 및 태그 산출물 검증은 출시 절차에서 1회 수행

## 결함별 조치

| ID | 기존 문제 | v1.2.5 조치 | 직접 근거 |
|---|---|---|---|
| P1-01 | 패배 재도전으로 자원·EXP·유대 반복 축적 | 전투 시작 자원·성장 snapshot을 기록하고 패배 시 복원 | `V125FailedBattleProgressRollbackTest.tscn` PASS |
| P1-02 | DAY 29 선언 반응과 세 번째 선언 도달 불가 | 선언 선택 뒤 전용 trigger를 실행하고 세 분기를 각각 7개 반응 cue로 연결 | `FinaleEveHardeningTest.tscn`, `V122StoryDay06To30Test.tscn` PASS |
| P1-03 | Update 3 전선별 결전 전야 대사 미출력 | DAY 29 공통 3개 장면 뒤 선택 전선의 결전 전야 장면을 순차 실행 | `FinaleEveHardeningTest.tscn` PASS |
| P2-01 | 패배 결산이 다음 행동을 알려주지 않음 | 도난·시설 피해·전멸·돌파 순으로 한 줄 재도전 조언 표시 | `V122CombatResultUIContractTest.tscn` PASS |
| P2-02 | 1280×720 전투 HUD 보조 정보가 너무 작음 | 위협·명령·전술·선택 유닛·지침 글자 확대와 패널 간격 조정 | 실제 `1280x720_day02_tut_130_goblin_control.png` 확인 |
| P2-03 | 필수 성장 선택 버튼이 너무 작음 | 카드 104px, 전용 210px 열, 설계 210×54 버튼으로 확대 | 실제 `1280x720_day02_result_win.png` 확인 |
| P2-04 | DAY 29 단일 장면이 약 5분 | 원본 147개 cue를 공통 3구간과 선언 반응 구간으로 분절 | 스토리 schema·DAY 06~30 검사 PASS |
| P2-05 | 내부 역할명 `나머지몬스터` 노출 | `remaining_core_monsters`를 자연스러운 군중 화자명으로 변환 | 스토리 런타임 검사 PASS |
| P2-06 | 엔딩 문장 중간 절단 | 문장을 `너무 무서워하면 아무도 안 오잖아.`로 완결 | 스토리 schema 검사 PASS |
| P2-07 | 내부 축약어 `고기여` 노출 | 사용자 문구를 `핵심 활약`, `활약도가 높은`으로 교체 | Update 3 데이터 계약 대상 |
| P3-01 | 펼친 선택 목록에 글자 배율 미적용 | popup에도 닫힌 버튼과 같은 scaled/touch 글자 계산 적용 | HUD 실제 화면과 코드 계약 확인 |
| P3-02 | 작은 피해 숫자가 0.82배로 시작 | 기본 생성 배율을 1.0으로 통일 | 전투 접촉 피드백 경로 확인 |
| P3-03 | 대사에 백틱 노출 | DAY 28·29 문구를 한국어 따옴표로 교체 | 스토리 schema 검사 PASS |

## 그래픽 보강

- Stage 02~04 전용 배경 3개와 통로 런타임 자산 18개를 추가했다.
- 생성 원본 9개와 런타임 PNG 21개의 출처·후처리·연결을 `assets/source/imagegen/v125_stage_progression/SOURCE.md`에 기록했다.
- 관리 Stage 01~04와 인위적 전투 Stage 02·04를 1920×1080으로 다시 렌더했다.
- 단계 구분, 입구 HUD 잘림, 외곽 연결, 시설 색 조화와 `바닥 < 유닛 < 반투명 전면 벽` 관계를 확인했다.
- 상세 결과는 `docs/qa/V125_GRAPHICS_RESOURCE_AUDIT_2026-08-10.md`를 따른다.

## 완료된 관련 검증

- `V122StoryDialogueSchemaTest.tscn`: PASS, 19,496 assertions
- `V122StoryDay06To30Test.tscn`: PASS, 7,768 assertions
- `FinaleEveHardeningTest.tscn`: PASS, 64 assertions
- `V125FailedBattleProgressRollbackTest.tscn`: PASS
- `V122CombatResultUIContractTest.tscn`: PASS
- `V125StageProgressionVisualRuntimeTest.tscn`: PASS
- `V122ReleaseReadinessTest.tscn`: PASS, 84 assertions
- `V122Stage11CascadeAudit.tscn`의 1280×720 전용 실행: PASS, 135 assertions

## 남은 출시 절차

제품 변경을 후보 SHA로 고정한 뒤 `main`에 merge commit으로 통합한다. 병합된 최종 SHA에서 Full 핵심 검증을 한 번 실행하고, PASS인 동일 SHA에 `v1.2.5` 태그를 만든다. 이어 Windows/Web 빌드, Release 자산 manifest, Pages 배포와 공개 부팅을 확인한다.
