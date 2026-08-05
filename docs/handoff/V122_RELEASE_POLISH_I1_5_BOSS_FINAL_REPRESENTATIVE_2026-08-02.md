# v1.2.2 출시 마무리 I1-5 보스·최종전 음악·VFX 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

DAY 30 최종전 대표 장면에서 정식 셀렌을 실제로 소환하고 다음을 확인했다.

- 살아 있는 보스가 있을 때 보스 전용 BGM `combat_boss_council.wav` 선택
- 검수 예고와 0.8초 이상 경고 시간
- HP 65% 이하 축성 바닥 생성 및 화면 효과
- HP 35% 이하 마지막 단계와 자비의 방벽 활성화
- 1280×720 준비·예고·축성 바닥·방벽 캡처 4장

## 결과와 파일

- 대표 검수: 11 assertions PASS, 실패 0건
- 관련 테스트: `OfficialSelenPhase20Test` 26 assertions PASS, `EndingPhase28Test` 45 assertions PASS
- QA 보고서: `docs/qa/V122_I1_5_BOSS_FINAL_REPRESENTATIVE_2026-08-02.md`
- 기계 결과: `tmp/v122_release_polish/i1_5_boss_final/i1_5_inventory.json`
- 실행 로그: `tmp/v122_release_polish/i1_5_boss_final/i1_5_capture.log`
- 캡처: `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_*_1280x720.png`

이번 패킷은 런타임·데이터·자산·빌드를 수정하지 않았다. 생성된 임시 검수 자료는 소스 브랜치에 영구 자산으로 승격하지 않는다.

Related tests: I1BossFinalRepresentative 11 assertions PASS; OfficialSelenPhase20Test 26 assertions PASS; EndingPhase28Test 45 assertions PASS.
UI check: 실제 Godot Vulkan `1280×720`에서 보스 정보 패널과 전투 UI가 유지된 상태로 BGM 전환, 검수 예고, 축성 바닥, 자비의 방벽 고리를 시각 확인했다.
Unresolved issues: 실제 소유자 청취·Windows 후보 조작(`I1-5-OWNER-01`)과 Q1-R 활성 오디오 권리·manifest gate는 다음 검수에서 처리한다.

## 다음 작업

계획 순서상 다음은 I1-6 Stage 01~04 환경음·발소리 전환 대표 검수다. 이후 실제 소유자 승인 전에는 오디오 자산 교체나 출시 빌드 생성을 진행하지 않는다.

## Git 상태

- 커밋·푸시: 수행하지 않음
- 작업 트리: 기존 사용자 변경과 이전 패킷 문서가 함께 있으며, 이번 패킷의 임시 자료는 `tmp/` 아래에만 있다.
