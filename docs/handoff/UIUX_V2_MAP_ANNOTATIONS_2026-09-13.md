# 지도 표식 개선 및 미궁 인터뷰 — 2026-09-13

## 1. 메타데이터

- WORKSTREAM_ID: UIUX-V2-MAP-ANNOTATIONS-20260913
- 목표 버전: 공개 1.2.6 기반 개선. 새 제품 버전 미확정.
- 작업 브랜치: `codex/v126-uiux-u0-u3`
- 기준 main / origin/main / 이번 세션에서 확인한 원격 main: `69a75970b1f8c030aa3a6956e5ca0f5bf15b2112`
- 착수 HEAD: `9b3feb194323d8aa441f6836b24b17ddedb2a9c5` (clean)
- 마지막 구현 커밋: `cb0167ae9ae15207a8685d58470297f7c5faa65a`
- 엔진: Godot 4.6.3, Windows Vulkan / RTX 3060 Ti
- 원격 푸시·PR·제품 통합·배포·태그: 없음. 이전 v20 참고선·출시 태그 불변.
- 권위: main:AGENTS.md와 main:docs/handoff/CURRENT.md 확인. 오래된 AGENTS의 1.2.5 문구보다 최신 사용자 지시와 CURRENT의 공개 1.2.6을 적용했다.

## 2. 이번 세션 목표

사용자 스크린샷의 작은 검은 시설 상태창과 공병 목표/무력화/감시 효과의 큰 직사각형 덮개를 함께 개선한다. 미궁 구조는 사용자 요청대로 grill-me 인터뷰를 먼저 진행한다. 구현 writer는 주 에이전트 한 명이며 서브에이전트는 사용하지 않았다.

지정 참고는 이전 실제 Chrome 확인 기록의 Curse of the Dead Gods / Game UI Database 729, REFERENCE_VERIFIED(2026-09-12)를 계승한다. 이번에는 사용자가 첨부한 두 게임 캡처와 기존 GPT 흑요석 UI 자산을 사용했다. 다른 게임을 같은 원본으로 대체하지 않았다.

## 3. 완료한 작업

- 공병 목표·시설 무력화·감시 적용 방·검수·자산 동결·부채의 직사각형 덮개를 실제 방 타일 외곽에 맞는 선으로 교체했다. 채움색으로 건물을 덮지 않는다.
- 시설/방 지침/명령 대상/통로 편집 표식을 공통 흑요석 이름표로 정리했다. 후반 산성 예고/산성 구역/축성 바닥/검수/예산·스트레스/자산 동결/성가/부채 예고/부채 상태도 같은 표시를 사용한다.
- 이름표는 글자 90/100/115%와 실제 화면 좌표를 사용한다. 확대·축소에도 글자가 함께 작아지지 않으며 HUD와 다른 시설 이름표를 피한다. 끝난 경고의 자리까지 쌓이지 않도록 매번 현재 상태에서 계산한다.
- 캐릭터의 현상금/봉인 사슬/선택 기술 미리보기/시설 교란 이름표도 통일했다. 같은 캐릭터의 이름·그림·동시 상태와 HUD를 피하고 일시정지 중 배율·줌·상세창 변경에도 다시 그린다.
- 병영은 `공격·방어 강화`, 감시는 `감시 · 이동 둔화`, 회복은 실제 단계 수치와 `/초`를 표시한다. 비용·효과·범위 판정·AI·튜토리얼·저장 규칙은 변경하지 않았다.
- 공병 성능 검사에서 네이티브 투명 그림도 Dictionary.get의 기본 인자가 먼저 실행되어 GPU 그림을 다시 읽는 지연을 발견했다. 명시된 투명 속성이 있으면 그 값을 사용하고, 속성이 없는 기존 그림만 원래 감지 경로를 사용한다. 공병 첫 생성 측정은 34,057µs에서 1,105µs로 개선됐다. 단일 Windows 검사 측정이며 전체 성능 벤치마크는 아니다.

## 4. 변경 파일

| 경로 | 변경 목적 |
|---|---|
| scripts/ui/MapStatusLabel.gd + .uid | 화면 좌표의 이름표 크기·배치·공통 렌더 |
| scripts/game/GameRoot.gd | 실제 방 바닥 외곽, 시설/후반 경고, HUD 회피, 정지 중 갱신 |
| scripts/ui/UIUXTheme.gd | 기존 흑요석 이름표의 굵은 직사각형 색 테두리 제거 |
| scripts/units/Unit.gd | 캐릭터 상태 이름표, 불필요한 투명도 읽기 제거 |
| tools/UIUXMapLabelsTest.gd + .uid + .tscn | 실제 전투 상태·표식·배율·줌·캡처 검사 |
| tools/EngineerPerformanceSmokeTest.gd | 네이티브 투명 공병에 색 제거 셰이더 미적용 확인 |
| tools/DemoSmokeTest.gd | 기존 회복 문구 기대값의 단위 변경 |

## 5. 그래픽 및 오디오 자산

신규 그림/음원 생성 없음. 기존 `assets/ui/uiux/obsidian_button.png`와 판석 스타일을 재사용했다. 원본·런타임 PNG 수정, 로컬 배경 제거·축소 저장·픽셀 편집 없음. 바닥 선과 연결선은 실제 게임 상태를 그리는 UI 효과다. 건물·캐릭터 그림 자체는 이전 구현을 유지했다.

## 6. 테스트 및 검수

로그 경로의 접두사는 모두 `tmp/`다. 실제 최종 코드 기준으로 실행했다.

| 검사 | 결과 | 로그 |
|---|---|---|
| UIUXMapLabelsTest | PASS · 5,927개 / 후 66장 | uiux_map_labels_final_UIUXMapLabelsTest.log |
| UIUXCombatInteractionTest | PASS · 210개 | uiux_map_labels_final_UIUXCombatInteractionTest.log |
| UIUXBuildPlacementTest | PASS · 343개 | uiux_map_labels_build_verify.log |
| EngineerPerformanceSmokeTest | PASS · 21개 | uiux_map_labels_final_EngineerPerformanceSmokeTest.log |
| V122FacilityZoneCombatConsumerTest | PASS | uiux_map_labels_final_V122FacilityZoneCombatConsumerTest.log |
| V122FacilityZoneEffectResolverTest | PASS | uiux_map_labels_final_V122FacilityZoneEffectResolverTest.log |
| git diff --check | PASS | 커밋 전 실행 |
| 저장소 정책 | PASS · 639개 최종 경로 / 34커밋, 문서 838a6ef 기준 | uiux_map_annotations_repository_policy_verified.log |
| 전체 회귀·전체 캠페인·8인·사람 사용성·다른 플랫폼 | NOT_REQUESTED / 미실시 | 이번 범위 아님 |

지도 표식: Windows 1920×1080 / 1280×720 × 글자 90/100/115%, 지도 80/125% 줌. 실제 방어 시작 뒤 일시정지하고 기존 전투 상태 컨테이너에 짧은 경고를 넣어 재현했다. 보스 경고도 실제 로만/셀렌 객체를 사용한다. 실제 피해량·AI 전 과정이나 사람 손 조작을 확인한 것으로 확대하지 않는다.

초기 실패도 보존한다. 검사 장면의 자료형과 존재하지 않는 보조 방 ID를 수정했고, 표시 배치 알고리즘의 큰 글자 겹침을 수정했다. 공병 첫 생성 16ms 기준 실패는 위의 불필요한 투명도 읽기로 수정했다. 최종 연속 검사 중 건설 첫 GUI press가 활성화되지 않은 실행(`uiux_map_labels_final_UIUXBuildPlacementTest.log`, 14개 시점 중단)이 있었다. 제품/검사 코드를 바꾸지 않고 별도 APPDATA에서 재실행하여 343개를 통과했다. 그 입력 실패의 정확한 원인은 확정하지 않았으며 초기 실패를 삭제하거나 PASS로 바꾸지 않았다.

재검사 1회는 자동 승인 검토의 사용량 한도 오류로 실행 자체가 거절됐다. 사용자의 `다시 진행해` 뒤 같은 검사를 정상 실행했다. 우회 실행·크레딧 재설정은 하지 않았다.

- 전후 비교: `tmp/uiux_map_labels_20260913/index.html` (36쌍)
- 추가 후반·동시 상태 캡처: 같은 폴더 `after/` (30장)
- 건설 실제 GUI 드래그/확정/취소/Undo: 같은 폴더 `build_verification/`
- 변경 전 통과: `tmp/uiux_map_labels_before_fixed.log` (37개/36장)
- 검사 후 기능 변경: 없음. 이후 이 묶음의 승인 기록은 인계 문서만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: cb0167ae9ae15207a8685d58470297f7c5faa65a
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..cb0167ae9ae15207a8685d58470297f7c5faa65a
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 범위

지도 표식 개선은 위 코드와 직접 검사 범위에서 완료했다. 모든 UI의 주관적 미술 승인이나 전체 적 밀집 상황의 이름표 교차 배치, 장시간 성능·전 캠페인 검수를 완료했다고 주장하지 않는다. 실제 미궁 구조·벽·문·갈림길·우회로는 아직 변경하지 않았다. 저장 호환을 포함한 다음 구현은 별도 검증이 필요하다.

## 8. 미궁 인터뷰 확정 사항과 다음 작업

사용자는 grill-me 질문 7개에 다음과 같이 답했다.

1. 외형만 바꾸는 던전이 아니라 갈림길·우회로 자체를 새로 설계한다.
2. 플레이어는 준비된 미로에 시설·몬스터를 배치한다.
3. 성장 단계에 따라 확장되는 고정 미로다.
4. 적은 목표에 따라 경로를 고르고, 방어 준비 때 예상 경로를 표시한다.
5. 시설은 방 안의 지정 건설 구역에 배치한다.
6. 현재 사선 시점에 지붕 없는 실내 단면을 사용한다. 문/아치와 낮은 앞벽으로 연결과 내부를 읽게 한다.
7. 초반은 단순한 주 경로, 후반은 주요 진입로 2~3개로 늘린다.

최신 답은 V2의 과거 경로 보존 범위를 미궁 설계에 한해 변경한다. 새 제품 버전·자유 타일 건설·새 저장 시스템·배포까지 승인한 것으로 확대하지 않는다.

다음은 현재 ModuleGraph/타일 보행 지도/성 단계 콘텐츠/저장 복원과 예상 진입로의 실제 연결을 조사하고, 기존 방 ID·시설·몬스터·비용을 보존하는 고정 미궁을 구현·검증한다. 기존 사용자 저장을 임의로 덮어쓰거나 손실시키지 않는다. 주 에이전트가 이어서 수행한다.

## 9. 작업 트리 상태

이 작업 시작은 clean이며 기존 혼합 변경이 없었다. 제품 변경 10개 파일은 cb0167a에 명시적으로 스테이징·커밋했다. 이 문서와 CURRENT는 후속 문서 커밋으로 기록한다. 전체 브랜치는 로컬 미푸시다. 빌드/캡처는 무시되는 tmp에만 두었다.

## 10. 종료 체크리스트

- [x] 지도 표식 요청과 구현 대조
- [x] 관련 직접 테스트·Windows 실제 렌더 확인
- [x] 실제 수행 범위와 초기 실패를 구분해 기록
- [x] 구현 최종 SHA·원격 미푸시·자산 무변경 기록
- [x] 사용자 미궁 인터뷰 확정 사항 기록
- [x] CURRENT 갱신
- [x] 의도한 제품 파일만 로컬 커밋
- [ ] 미궁 구현·저장 호환·직접 조작 검증 (다음 작업)
