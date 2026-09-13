# 원정 비용·편성 예고·예약 효과 개선

작성 2026-09-14 · WORKSTREAM_ID UIUX-V2-RAID-CHOICE-20260914

## 변경 결과

원정 선택의 비용과 총보상 아래에 **식량을 포함한 순보상**을 표시한다. 출발 전·후의 실제 자원 잔고와 차이는 `last_raid_result.resource_balance`에 보존한다. DAY28 작전은 DAY30 적용임을 선택 화면·하단 안내·완료 보고에서 명시한다.

- `_active_defense_modifiers(day)`는 날짜를 변경하지 않고 해당 방어일의 전선·예약 효과를 조회한다. 인수 없는 기존 전투 호출의 동작은 유지한다.
- 기존 WaveManager로 선택한 원정 적용 전후 편성을 계산하여 적 종류별 수 변화와 첫 등장 지연을 표시한다. 실제 전선 효과를 포함하며 승률이나 보스 효과의 전체 수치 예측은 만들지 않는다. 기타 효과·대가는 기존 설명과 위험 문구에 남긴다.
- 날짜, 완료/양자택일, 필수 그룹, 유효 편성, 최대 인원, 비용 검사를 출발 버튼·출발 처리·브리핑 후 확정이 공유한다. 결제 단계에서 선택 원정을 다른 임무로 자동 대체하지 않는다.
- 미래 원정, 잘못된 인원, 부족한 비용, 중복 실행을 거부한다. 실패가 선택 UI를 정리할 수 있으나 비용·보상·유대·예약 효과는 반영하지 않는다.
- 긴 보상과 위험을 두 줄로 표시하도록 카드 높이를 늘렸다. 상세의 핵심 효과는 첫 화면에 보인다. 브리핑·최근 보고는 기존 상세 스크롤로 접근한다.
- 성광·길드 작전의 별도 설명이 없을 때 ‘영향 없음’으로 표시되던 문구를 실제 작전 설명으로 연결했다.
- 제품 비용·보상·해금 값·AI·스토리 데이터·저장 버전·미술 변경 없음. 기존 원정 결과 딕셔너리에 선택 필드를 추가한다.

## 실제 원정 처리 결과

모든 자원 1,000을 넣은 충분한 자금 시험 설정이다. 아래 수치는 실제 `_commit_selected_raid`를 실행한 잔고 차이다. 원정 12개, 일반 8개와 성광·길드 4개. 로로 고정 지휘가 정의된 기존 원정만 악명 10% 보너스를 포함하며 임의로 다른 원정에 확장하지 않는다. 모든 마력 순변동은 0.

| 원정 | 금화 순변동 | 식량 순변동 | 악명 순변동 | 실제 방어 예고 |
|---|---:|---:|---:|---|
| d04_signpost_flip | 30 | -5 | 22 | DAY 04 방어 적용; 현재 방어 편성 대비 · 탐험가 5→4 / 첫 등장 +4.0초 |
| d05_supply_tag | 45 | -7 | 28 | DAY 06 방어 적용; 현재 방어 편성 대비 · 도둑 2→3 |
| d16_route_recon | 80 | -8 | 39 | DAY 16 방어 적용; 현재 방어 편성 대비 · 왕국 조사관 1→0 / 첫 등장 +4.0초 |
| d16_supply_ambush | 180 | -6 | 88 | DAY 16 방어 적용; 현재 방어 편성 대비 · 도둑 1→2 |
| d18_forged_manifest | 120 | -8 | 50 | DAY 18 방어 적용; 현재 방어 편성 대비 · 탐험가 2→3 / 왕국 조사관 1→0 |
| d18_seal_smuggling_tunnel | 80 | -8 | 77 | DAY 18 방어 적용; 현재 방어 편성 대비 · 도둑 2→1 / 왕국 방패병 1→2 |
| d28_siege_route_recon | 80 | -10 | 50 | DAY 30 방어 적용; 현재 방어 편성 대비 · 왕국 조사관 1→0 / 첫 등장 +5.0초 |
| d28_engineer_supply_disruption | 170 | -14 | 99 | DAY 30 방어 적용; 현재 방어 편성 대비 · 왕국 공병 2→1 |
| d28_holy_relic_registry_swap | 80 | -10 | 4 | DAY 30 방어 적용; 현재 방어 편성 대비 · 성물 수호기사 1→0 / 봉인 사슬병 0→1 |
| d28_holy_pilgrim_detour | 140 | -10 | 2 | DAY 30 방어 적용; 현재 방어 편성 대비 · 성가 퇴마사 1→0 / 첫 등장 +4.0초 |
| d28_guild_ledger_forgery | 0 | -10 | 0 | DAY 30 방어 적용; 현재 방어 편성 대비 · 장부 구속술사 1→0 |
| d28_guild_payroll_cut | 140 | -10 | 3 | DAY 30 방어 적용; 현재 방어 편성 대비 · 현상금 추적자 1→2 |

이 표는 원정 단위 결산/편성의 정확성이다. 이동·전투 AI를 끝까지 돌리거나 DAY1~30에서 이 자원을 실제 확보한 증거가 아니다. 원정 비용은 전투 시작 전이므로 전투 `resource_balance`에 중복 포함하지 않는다.

## 마지막 관련 검사

| 검사 | 결과 | 증거 |
|---|---|---|
| UIUXRaidChoiceTest | PASS 320 checks | `tmp/uiux_raid_choice_20260914/direct.log`, `results.json` |
| FinaleEveHardeningTest | PASS 64 assertions | `FinaleEveHardeningTest_final.log` |
| HolyPurificationPhase19Test | PASS 49 assertions | `HolyPurificationPhase19Test_final.log` |
| GuildRepossessionPhase21Test | PASS 37 assertions | `GuildRepossessionPhase21Test_final.log` |
| V122SaveProgressionTest | PASS | `V122SaveProgressionTest_final.log` |
| git diff --check | PASS | 최종 변경 검사 |

Godot 4.6.3 Windows 네이티브 Forward+, RTX3060Ti. 실제 출발 처리, 정확한 지출/보상, 원정별 활성 WaveManager 일정 일치, 읽기 전용 미리보기, 중복 호출 및 편성/날짜/필수 그룹/자원 거부, DAY28·29의 미래 효과 보존, DAY30 소비와 재도전 무과금 복원 확인.

UI: 1920×1080 글자100%, 1280×720 글자115%에서 DAY16 급습/DAY28 공병/성광 목록/길드 급여 총8화면. 잘림·효과 위치·하단 행동 확인. 캡처는 게임에서 생성했다. `before_1920_day28.png`는 이전 RaidWorkspaceUI만 현재 GameRoot에 연결한 비교이므로 하단 안내는 현재 문구이며 과거 전체 빌드 캡처로 주장하지 않는다. 비교용 이전 스크립트가 없으면 테스트는 before 캡처만 생략한다.

초기 검사 스크립트 타입 선언 및 전선 시험 설정의 심장 선택 누락을 수정했다. 초기 8개 검사 통과 후 전선 예고도 실제 전선 효과를 반영하도록 확장했다. 저장 검사 종료 경고는 미처 끝나지 않은 UI 타이머를 0.3초 기다리도록 시험 정리를 수정해 해소했다. 최종 관련 로그에서 저장 손상 복구 시험의 예상 JSON 파싱 오류3건 외 실행/정리 오류 없음.

## 변경 경로와 제한

- `scripts/game/GameRoot.gd`: 검증 공통화, 원정 실제 결산, 날짜별 효과 조회·WaveManager 예고.
- `scripts/ui/RaidWorkspaceUI.gd`: 순보상·적 편성·날짜, 긴 카드 문구.
- `tools/UIUXRaidChoiceTest.gd/.gd.uid/.tscn`: 직접 재현/캡처.
- `tools/tests/V122SaveProgressionTest.gd`: 종료 정리.
- 로컬 모음 `tmp/uiux_raid_choice_20260914/index.html` 및 동일 폴더 JSON/PNG/log. tmp는 커밋 제외.

전체 회귀, 전체 DAY1~30, 사람 사용성, Web·저사양·장시간 검증·출시·배포·태그는 실행하지 않았다. 연속 캠페인에서 시설 투자와 원정 비용까지 합친 경제 적정성은 미확정이다. 방향별 캐릭터 원화의 ASSET_BLOCKED_NATIVE_ALPHA는 유지한다. 최종 출시 HOLD.
