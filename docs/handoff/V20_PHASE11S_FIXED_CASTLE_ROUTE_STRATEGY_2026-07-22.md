# 제품 2.0 Phase 11S 고정 마왕성 루트·구역 배치 전략 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-22
- 목표 버전: 제품 2.0 Phase 11S 고정 침입로·구역 배치 전략 재설계
- 작업 브랜치: `codex/v20-p11s-castle-route-strategy`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `9a012b3ee364699d0c84193a30cde2e9d5ef44bd`
- 마지막 기능 커밋 SHA: `afa2cc592cffc1c758520f3d9d4c1f8472ab97e0`
- 원격 푸시 여부: 기능·문서, 보존용 Web 빌드, Pages 공개본 모두 푸시·병합 완료
- 관련 PR 또는 태그: 소스 [PR #61](https://github.com/bluehige/mawangseong-demo/pull/61), Pages [PR #10](https://github.com/bluehige/mawangseong-web-playtest/pull/10), 배포 기록 [PR #62](https://github.com/bluehige/mawangseong-demo/pull/62), 태그 변경 없음

## 2. 이번 세션 목표

- 요청 사항: 적의 침입 경로와 각 구역의 길·공간은 미리 고정하고, 어느 구역에 어떤 시설을 짓고 어떤 몬스터를 배치하는지에 따라 전략이 달라지도록 준비·전투 UI와 실제 런타임을 다시 만든다.
- 완료 조건: 상시 건물 설정과 경로 전환 UI 제거, 우리 마왕성 배경 위 고정 침입로 표시, 네 구역의 시설·몬스터 직접 배치, 실제 전투 경로·시설 효과·몬스터 AI anchor 일치, 직관적 난이도 표기, 관련 테스트와 PC Web 실조작 통과.
- 범위에서 제외한 사항: DAY 6~30 확장, 실제 사람 6~10명 재평가 결과, 요청되지 않은 전체 회귀·전체 플레이.

## 3. 완료한 작업

- 고정 침입로와 구역:
  - `입구 → 성문 전초 → 가시 회랑 → 중앙 전투실 → 왕좌 전실 → 왕좌` 하나의 경로를 데이터 계약으로 고정했다.
  - 네 구역의 순서, 실제 공간, 배경 위 route waypoint를 선언하고 시설 비용·위험·seed가 달라도 경로가 바뀌지 않게 했다.
  - 기존 저장 호환을 위해 `north_gate`, `south_gate`, `treasure`, `fallback` section ID는 유지하고 표시 이름과 runtime mapping만 정규화했다.
- 실제 전투 연결:
  - 성문 전초는 `entrance`, 가시 회랑은 `spike_corridor`, 중앙 전투실은 `barracks`, 왕좌 전실은 `throne`에 연결했다.
  - V20 전투는 고정 layout `v20_fixed_castle_route_01`을 사용하고 숨은 legacy 보물·회복 분기를 `v20_empty`로 비운다.
  - 수동 몬스터 배치를 `manual_anchor_node`로 실제 역할 AI에 전달해 서로 다른 구역 배치가 서로 다른 이동 목표와 경로를 만든다.
  - 미끼가 없어도 도둑은 중앙 전투실에서 5초 약탈 뒤 입구로 도주·종료한다. 미끼 발동 중에는 감속 0.55와 약탈 준비 10초가 실제 적용된다.
- 시설 전략:
  - 바리케이드: 구역 감속 0.78, 발동 중 0.48.
  - 병영: 몬스터 공격 1.12·받는 피해 0.88, 발동 중 1.18·0.82.
  - 미끼 보물실: 도둑 감속 0.82·약탈 준비 1.5배, 발동 중 0.55·2.0배.
  - 감시 초소: 적 감속 0.82·몬스터 공격 1.08, 발동 중 감속 0.68.
  - 회복 둥지: 배치 구역 초당 8 회복, 발동 중 초당 14.
  - 선택하지 않은 시설은 실제 전투 효과를 만들지 않고, 공병 무력화 중에는 해당 효과도 제거된다.
- UI/UX:
  - 기존 `gpt2_dungeon_connected_map.png`를 중앙의 주 화면으로 사용하고 그 위에 고정 붉은 침입선과 네 구역 판을 배치했다.
  - 오른쪽 도구함은 `시설 / 몬스터` 두 모드만 유지하며, 현재 도구의 카드만 보여준다.
  - 시설 socket과 몬스터 slot을 구역 판에 직접 표시하고 drag와 click→click을 모두 지원한다.
  - 위치를 선택해도 지도 크기는 변하지 않고, 선택 요약만 같은 도구함 안에서 갱신된다.
  - 상시 건물 설정, 방 inspector, 위협 rail, 단계 ribbon, 경로 전환·예상 경로 패널을 제거했다.
  - 시설 카드에 비용과 핵심 전투 효과를 설치 전에 표시하고, 선택한 구역의 조합 효과를 미리 보여준다.
  - 타이틀 난이도 표시를 `쉬움 / 보통 / 어려움`으로 바꾸고 자원·동시 목표·예고 압박을 한 줄로 설명한다. 내부 저장 ID는 유지한다.
  - 온보딩·결과 문구를 고정 침입로와 구역 배치 기준으로 통일했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/dungeon_layouts.json` | 고정 경로·네 구역·마왕성 배경·route waypoint | 완료 |
| `data/v20/{economy,encounters,facilities,onboarding}.json` | 직관적 난이도·고정 경로 문구·실전 시설 효과 | 완료 |
| `scripts/core/DataRegistry.gd` | V20 고정 전투 layout 등록 | 완료 |
| `scripts/game/{GameRoot,CombatSceneController,ManagementSceneController}.gd` | 실제 공간 mapping·시설/몬스터 런타임·입력 연결 | 완료 |
| `scripts/v20/path/{V20FixedRouteService,V20RoutePreview}.gd` | 고정 경로 선택·표시 | 완료 |
| `scripts/v20/contracts/V20ContractValidator.gd` | 고정 경로·구역·waypoint·전투 효과 계약 검증 | 완료 |
| `scripts/v20/{economy,encounters,facilities,monsters,session}/` | 경제·encounter·효과·AI anchor·저장 정규화 | 완료 |
| `scripts/v20/placement/{V20PlacementBoard,V20PlacementRoomButton}.gd` | 고정 마왕성 지도와 두 배치 도구 | 완료 |
| `scripts/v20/ui/{V20InformationHUD,V20ResultScreen,V20TitleEntryPanel}.gd` | 전투·결과·난이도 정보 구조 | 완료 |
| `tools/fixtures/v20/valid_decision_contracts.json` | 시설 전투 효과 유효 fixture | 완료 |
| `tools/tests/V20*.gd` 관련 8개 | 고정 경로·배치·런타임·UI·저장 회귀 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 세션 신규 생성 없음
- 기존 자산 생성 모델: GPT Image 2
- 생성 원본 및 편집 이력: `assets/sprites/dungeon_gpt2/SOURCE.md`
- 런타임 최종 자산: `assets/sprites/dungeon_gpt2/gpt2_dungeon_connected_map.png`
- 사용 방식: 기존 연결형 마왕성 배경 위에 고정 침입선, 구역 판, 시설·몬스터 슬롯 UI만 합성했다.
- 게임 연결 및 실제 렌더 확인 결과: 1280×720 Godot 렌더와 PC Web에서 배경·경로·네 구역·오른쪽 도구함이 화면 안에 들어오고, 구역 선택 전후 지도 크기가 동일함을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20StrategicRoutingTest.tscn` | PASS, 22 assertions | 고정 경로·첫 교전·동일 signature |
| 2 | `V20DecisionContractsTest.tscn` | PASS, 24 assertions | 고정 경로·시설 효과 계약 |
| 3 | `V20DayOneToFiveEncountersTest.tscn` | PASS, 80 assertions | DAY 1~5 고정 prefix·대응 |
| 4 | `V20FacilityReworkTest.tscn` | PASS, 40 assertions | 시설 passive·activation·무력화·복귀 |
| 5 | `V20DifficultyEconomyTest.tscn` | PASS, 27 assertions | 쉬움·보통·어려움과 경제 압박 |
| 6 | `V20OnboardingRetrySaveTest.tscn` | PASS, 64 assertions | 실제 GameRoot·AI anchor·시설·도둑 종료·저장 |
| 7 | `V20PlacementUxTest.tscn` | PASS, 44 assertions | 두 도구·drag·click·지도 크기 고정 |
| 8 | `V20InformationArchitectureTest.tscn` | PASS, 51 assertions | 3해상도 관리·전투 비겹침 |
| 9 | `V20TacticalCommandsTest.tscn` | PASS, 27 assertions | 명령력·대상 지정·시설 발동 |
| 10 | `V20MonsterRoleGrowthTest.tscn` | PASS, 39 assertions | 역할·표적·시설 synergy·AI 이동 |
| 11 | Godot 1280×720 실제 렌더 | PASS | 관리 기본/선택, 전투, 타이틀 캡처 |
| 12 | 통합 SHA 로컬 PC Web Chromium 1280×720 | PASS | 어려움 선택, 시설 설치 8→5, 도구 전환, 몬스터 drag, 전투 진입, 집결 대상 지정·발동, 오류·경고 0 |
| 13 | Web release·보존 브랜치 | PASS | release merge `8b5022f`에서 build `79d9174`, approval `8e71cf7`, repository-policy run `29894445264` 성공 |
| 14 | Pages 배포·공개 바이너리 | PASS | Pages PR #10 merge `f9710e1`, run `29894714534`, PCK HTTP 231,614,192 bytes·SHA-256 일치 |
| 15 | 공개 PC Web Chromium 1280×720 | PASS | 캐시 우회 URL에서 시설 설치, 몬스터 drag, 방어 시작, 집결 대상 지정·발동, 오류·경고 0 |
| 16 | 전체 회귀·전체 플레이 | NOT_REQUESTED | 직접 관련 범위만 검증 |

- 관련 자동 테스트 합계: 10개 스위트, 418 assertions PASS.
- 최종 정적 P1/P2 재검토: 미끼 없는 도둑 종료와 미끼 발동 실효 문제를 수정한 뒤 남은 P1/P2 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서만 허용한다.
- 소스 통합: PR #61, merge commit `8b5022fa84a2a4697d02168972798f4ed26eac4f`, repository-policy run `29893840673` PASS.
- Web 보존: `test/web-v20-p11s-castle-route-strategy`, build commit `79d9174efebb323dfeeaa00456599a0afa57c8af`, 승인 문서 head `8e71cf7ac56725de52d90edb94d75387150485fb`, repository-policy run `29894445264` PASS.
- Pages 공개: content commit `7a217b1e8b2feaf0eb820cad3d08787b8ceae155`, PR #10 merge commit `f9710e1c2d8c4893acd473ff94be714ba2aef9f2`, deploy run `29894714534` PASS.
- 공개 주소: `https://bluehige.github.io/mawangseong-web-playtest/v20-p11s/`.
- 공개 PCK: 231,614,192 bytes, SHA-256 `9d3a381dab5db66374f607bf920958117186d8a04359b5b1685aaf23132e3284`, HTTP `Content-Length`와 전체 재다운로드 해시 모두 일치.
- 공개 WASM: 38,047,590 bytes, SHA-256 `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240`.
- 깨끗한 worktree의 첫 export는 기존과 같은 폰트 첫 import 크래시가 한 번 발생했지만, 생성된 import cache를 유지한 채 소스 변경 없이 동일 release SHA에서 재시도해 성공했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: afa2cc592cffc1c758520f3d9d4c1f8472ab97e0
- Review range: 9a012b3ee364699d0c84193a30cde2e9d5ef44bd..afa2cc592cffc1c758520f3d9d4c1f8472ab97e0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 자동·Godot 렌더·로컬 Web에서 재현되는 필수 문제는 없다.
- 경로 선택 전략은 의도적으로 제거했다. 현재 전략 축은 같은 고정 침입로 위에서 구역별 시설 효과와 몬스터 배치 위치를 조합하는 것이다.
- production에 사용하는 role-driven layout 원본이 현재 `data/dungeon_quarter/test_layouts/` 아래 있는 구조는 후속 정리 가능한 기술부채다. 런타임 ID와 검증은 고정돼 있어 이번 기능의 차단 항목은 아니다.
- 실제 초회 사용자의 이해도 개선 여부는 공개 `/v20-p11s/`에서 6~10명 무설명 블라인드 테스트를 다시 하기 전까지 확정하지 않는다.

## 8. 다음 작업 순서

1. 공개 `/v20-p11s/`로 6~10명 무설명 블라인드 플레이를 진행해 첫 선택 90초, DAY 1 완료, 이해도, 재도전 의향을 기록한다.
2. 사람 결과가 Go일 때만 Phase 12 DAY 6~30을 시작한다. 결과가 없으면 Pending, 기준 미달이면 No-Go로 유지한다.

## 9. 배포 계보와 작업 트리 상태

- 기능 커밋: `afa2cc592cffc1c758520f3d9d4c1f8472ab97e0`
- release/v2.0 통합: `8b5022fa84a2a4697d02168972798f4ed26eac4f`
- Web 보존 build: `79d9174efebb323dfeeaa00456599a0afa57c8af`
- Pages 공개 merge: `f9710e1c2d8c4893acd473ff94be714ba2aef9f2`
- 최종 배포 기록: `codex/v20-p11s-deployment-record`, 소스 PR #62
- 기능·Web·Pages 작업공간 상태: 각 의도한 커밋 뒤 clean
- 미추적 UID: `V20FixedRouteService.gd.uid`만 필요한 sidecar로 기능 커밋에 포함했다. Godot가 재생성한 무관 UID 5개는 삭제했고 스테이징하지 않았다.
- 스태시 또는 별도 작업공간: 기능·Web 보존·Pages 배포·최종 기록을 각각 분리 worktree에서 처리했다.
- 로컬 캡처: Godot user data의 `v20_phase11s_management_1280x720.png`, `v20_p11s_management_selected_1280x720.png`, `v20_phase11s_combat_1280x720.png`, `v20_phase10_title_entry_1280x720.png`.
- 공개 최종 캡처: `C:\Users\LDK-6248\AppData\Local\Temp\v20p11s-public-command.png`.

## 10. 종료 체크리스트

- [x] 고정 경로·네 구역·시설/몬스터 전략 구현
- [x] 실제 전투 공간·시설 효과·수동 AI anchor 연결
- [x] 관련 10개 스위트 418 assertions 통과
- [x] 1280×720 Godot 렌더·로컬 PC Web 실조작
- [x] 검수 대상 기능 SHA와 정책 필드 기록
- [x] 신규 그래픽 생성 없음과 기존 자산 출처 기록
- [x] 소스 PR #61 merge
- [x] Web 보존 브랜치·Pages 공개 배포
- [x] 공개 `/v20-p11s/` Chromium 최종 확인
- [ ] 실제 사람 6~10명 무설명 블라인드 플레이와 Go/No-Go 판정
