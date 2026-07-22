# 제품 2.0 Phase 11T 단계 방어·전투 가독성 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-22
- 목표 버전: 제품 2.0 Phase 11T 단계 방어·몬스터 배치·전투 가독성 수정
- 작업 브랜치: `codex/v20-p11t-defense-stages-clarity`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `cf53ed20d97ff07a02f0cc240805cbf7b25fd46b`
- 마지막 기능 커밋 SHA: `d1829eb21951ba8d1b4aebdf3103c148c4524c9e`
- 원격 푸시 여부: 기능·Web 보존·Pages 공개·배포 기록 푸시 완료
- 관련 PR 또는 태그: 소스 [PR #63](https://github.com/bluehige/mawangseong-demo/pull/63), Pages [PR #11](https://github.com/bluehige/mawangseong-web-playtest/pull/11), 태그 변경 없음

## 2. 이번 세션 목표

- 요청 사항: 입구에서 왕좌까지 직행하지 못하게 방마다 순서대로 막고 싸우게 하며, 실제 몬스터 카드를 드래그해 배치하고, 검게 가려진 전투 화면과 이해하기 어려운 방별 전술 UI를 직관적으로 수정한다.
- 완료 조건: `성문 전초 → 가시 회랑 → 중앙 전투실 → 왕좌 전실 → 왕좌` 순차 교전, 몬스터 초상 카드 drag와 방 배치, 밝은 전투 화면, 현재 교전 구역·다음 구역·명령 대상과 효과의 상시 표시, 관련 자동 테스트와 1280×720 실제 렌더 통과.
- 범위에서 제외한 사항: DAY 6~30 확장, 실제 사람 6~10명 재평가 결과, 요청되지 않은 전체 회귀·전체 플레이.

## 3. 완료한 작업

- 단계 방어 경로:
  - 입구에서 왕좌로 연결되던 직접 corridor를 제거하고 각 전투 구역을 독립 checkpoint로 만들었다.
  - 적은 현재 구역의 수비 몬스터와 먼저 교전하고, 돌파 뒤 1.25초 breach 대기 후에만 다음 구역으로 이동한다.
  - `fallback`은 왕좌 직행 별칭이 아니라 독립 전실로 유지하고 최종 목표만 왕좌로 복원한다.
- 몬스터 배치:
  - 몬스터 도구를 열면 푸딩·곱·핀 실제 초상 카드가 항상 보이고 카드 전체에서 drag를 시작할 수 있다.
  - drag 중 실제 초상·이름·역할을 가진 preview를 표시하며, 유효 구역의 monster slot에 놓거나 click→click으로도 배치한다.
  - 배치된 몬스터는 구역 판과 전투 맵에 초상 토큰으로 표시되고 실제 AI anchor와 같은 구역을 사용한다.
- 전투 가독성과 방별 전략:
  - 전투 workspace를 덮던 검은 오버레이를 제거해 마왕성 배경·경로·유닛이 보이게 했다.
  - 왼쪽에 4개 방어 단계를 상시 표시하고, 맵에는 현재 교전 구역·진행 화살표·수비 몬스터·침입자·시설 상태를 직접 그린다.
  - `방 집결`, `적 집중`, `시설 발동`, `후방 철수` 네 명령을 항상 노출하고 각각 선택 대상과 수치 효과를 짧게 표시한다.
  - encounter 안내를 `지금 할 일: 명령 → 대상 클릭` 형식으로 바꿔 다음 조작을 한 줄로 고정했다.
- 불필요한 UID 정리:
  - Godot가 관련 없는 테스트 파일에 생성한 미추적 `.gd.uid` 5개는 소스나 참조가 없어 삭제했다.
  - 기능에 필요한 추적 UID와 기존 worktree 메타데이터는 건드리지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json` | 왕좌 직행 제거와 구역별 checkpoint corridor | 완료 |
| `scripts/game/{CombatSceneController,GameRoot}.gd` | 구역별 순차 교전·돌파 대기·밝은 전투 렌더 | 완료 |
| `scripts/v20/placement/{V20MonsterDragButton,V20PlacementBoard,V20PlacementRoomButton}.gd` | 실제 몬스터 카드·drag preview·구역 토큰 | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 4단계 방어선·현재 구역·명령 대상/효과 표시 | 완료 |
| `scripts/v20/{commands,encounters,session}/` | 직관적 전술 문구·구역 상태 snapshot | 완료 |
| `tools/RoleCombatLayout{Capture,Probe}.gd` | 순차 경로와 실제 전투 화면 검증 | 완료 |
| `tools/tests/V20*.gd` 관련 7개 | 배치·경로·전투·명령·저장 회귀 계약 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 세션 신규 생성 없음
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 기존 마왕성 배경은 `assets/sprites/dungeon_gpt2/SOURCE.md`
- 런타임 최종 자산 경로: 기존 마왕성 배경과 몬스터 초상 자산 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: 신규 자산 수정 없음. 기존 자산 위 UI 합성·오버레이 투명도만 수정했다.
- 게임 연결 및 실제 렌더 확인 결과: 1280×720 관리 화면에서 몬스터 카드 3종과 고정 경로를, 전투 화면에서 밝은 배경·4단계·양측 유닛·4명령을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20DecisionContractsTest.tscn` | PASS, 24 assertions | 고정 데이터 계약 |
| 2 | `V20InformationArchitectureTest.tscn` | PASS, 68 assertions | 관리·전투 UI 배치와 가독성 |
| 3 | `V20PlacementUxTest.tscn` | PASS, 55 assertions | 몬스터 카드·drag preview·유효 drop |
| 4 | `V20StrategicRoutingTest.tscn` | PASS, 25 assertions | 직행 제거·구역 순차 경로 |
| 5 | `V20FacilityReworkTest.tscn` | PASS, 40 assertions | 구역 시설 효과 |
| 6 | `V20MonsterRoleGrowthTest.tscn` | PASS, 39 assertions | 배치 구역과 역할 AI anchor |
| 7 | `V20TacticalCommandsTest.tscn` | PASS, 27 assertions | 네 명령·대상·효과 |
| 8 | `V20DayOneToFiveEncountersTest.tscn` | PASS, 80 assertions | DAY 1~5 순차 encounter |
| 9 | `V20DifficultyEconomyTest.tscn` | PASS, 27 assertions | 난이도·경제 불변 |
| 10 | `V20OnboardingRetrySaveTest.tscn` | PASS, 77 assertions | 실제 GameRoot·재도전·저장 |
| 11 | `RoleCombatLayoutProbe` | PASS | 왕좌 직행 없음과 checkpoint runtime |
| 12 | Godot 1280×720 실제 렌더 | PASS | 관리·전투 캡처 육안 확인 |
| 13 | 통합 SHA 로컬 PC Web Chromium 1280×720 | PASS | 몬스터 초상 drag·첫 구역 drop·밝은 전투·4단계·집결 대상 지정/발동·오류/경고 0 |
| 14 | 소스 통합·Web release 보존 | PASS | 소스 PR #63 merge `4a15d35`, Web build `b2d171a`, LFS 정규화 `d493513`, approval `7c9ae76`, 정책 run `29900164992` 성공 |
| 15 | Pages 배포·공개 바이너리 | PASS | Pages PR #11 merge `7d3548b`, run `29900656084`, 공개 11개 파일의 크기·SHA-256 원본 일치 |
| 16 | 공개 PC Web Chromium 1280×720 | PASS | 실제 고블린 drag/drop, 순차 방어 화면, 집결 대상 지정/발동, 명령력 3/3→2/3, 오류·경고 0 |
| 17 | `git diff --check` | PASS | 기능·문서 소스 공백 오류 없음 |
| 18 | 전체 회귀·전체 플레이 | NOT_REQUESTED | 직접 관련 범위만 검증 |

- 관련 자동 테스트 합계: 10개 스위트, 462 assertions PASS.
- 관련 범위 정적 검토에서 drag preview가 엔진 상태에 의존하던 문제를 수정했고 재검토 결과 남은 P1/P2는 없다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서만 허용한다.
- 소스 통합: PR #63, merge commit `4a15d3559f73e5dc5e6e636be82584d69b7d7a40`, repository-policy run `29898783448` PASS.
- Web 보존: `test/web-v20-p11t-defense-stages-clarity`, runtime build commit `b2d171a3bc12bd07723b57b5ff30846ffc9c5868`, WASM LFS 정규화 `d493513e47cfd0d4c1679092a8e1100179d95cac`, 승인 문서 head `7c9ae767722a3ccb3b8fa6e5c9f30695cea5519f`, repository-policy run `29900164992` PASS.
- Pages 공개: content commit `234e2621dd096f5d2639fbc2566503bb62d91d53`, PR #11 merge commit `7d3548b662a5798ca2c723494cdc153c1330b405`, deploy run `29900656084` PASS.
- 공개 주소: `https://bluehige.github.io/mawangseong-web-playtest/v20-p11t/`.
- 공개 PCK: 231,636,336 bytes, SHA-256 `35572910695d3e957bc3c394ab25a9ef1f950d019d394bbad53befd0cb14366c`.
- 공개 WASM: 38,047,590 bytes, SHA-256 `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240`.
- 공개 런타임 9개와 출처 기록 2개를 모두 다시 다운로드해 Web 보존 원본과 바이트·SHA-256이 동일함을 확인했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: d1829eb21951ba8d1b4aebdf3103c148c4524c9e
- Review range: cf53ed20d97ff07a02f0cc240805cbf7b25fd46b..d1829eb21951ba8d1b4aebdf3103c148c4524c9e
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 자동 테스트, Godot 렌더, 로컬 Web, 공개 Web에서 재현되는 필수 문제는 없다.
- GitHub Pages artifact가 과거 공개본을 함께 보존해 1 GB 권고치를 넘는다는 경고가 있었지만 deploy job과 공개 파일 응답은 모두 성공했다. 이후 공개본이 더 늘면 과거 빌드 보존 정책을 별도 결정해야 한다.
- 실제 초회 사용자의 이해도 개선 여부는 새 공개본에서 6~10명 무설명 블라인드 테스트를 다시 하기 전까지 확정하지 않는다.

## 8. 다음 작업 순서

1. 공개 `/v20-p11t/`로 6~10명 무설명 블라인드 플레이를 진행해 첫 선택 90초, DAY 1 완료, 이해도, 재도전 의향을 기록한다.
2. 사람 결과가 Go일 때만 Phase 12 DAY 6~30을 시작한다. 결과가 없으면 Pending, 기준 미달이면 No-Go로 유지한다.

## 9. 배포 계보와 작업 트리 상태

- 기능 커밋: `d1829eb21951ba8d1b4aebdf3103c148c4524c9e`
- release/v2.0 통합: `4a15d3559f73e5dc5e6e636be82584d69b7d7a40`
- Web runtime build: `b2d171a3bc12bd07723b57b5ff30846ffc9c5868`
- Web LFS·승인 head: `d493513e47cfd0d4c1679092a8e1100179d95cac` / `7c9ae767722a3ccb3b8fa6e5c9f30695cea5519f`
- Pages content·공개 merge: `234e2621dd096f5d2639fbc2566503bb62d91d53` / `7d3548b662a5798ca2c723494cdc153c1330b405`
- 최종 배포 기록: `codex/v20-p11t-deployment-record`
- 기능·Web·Pages 작업공간 상태: 각 의도한 커밋 뒤 clean
- 미추적 UID: 기능에 필요 없는 5개를 참조 0건 확인 후 삭제했으며 스테이징하지 않았다.
- 스태시 또는 별도 작업공간: 기능·Web 보존·Pages 배포·최종 기록을 각각 분리 worktree에서 처리했다.
- 로컬 캡처: Godot user data의 `v20_phase11s_fixed_castle_board_1280x720.png`, `v20_phase11t_defense_stages_combat_1280x720.png`.
- 공개 최종 캡처: `tmp/v20_p11t_web_publish/output/playwright/v20-p11t-public/`의 관리·drag·배치·전투·명령 PNG.

## 10. 종료 체크리스트

- [x] 왕좌 직행 제거와 구역별 순차 교전
- [x] 실제 몬스터 카드·drag preview·방 배치
- [x] 밝은 전투 배경·4단계·4명령 UI
- [x] 관련 10개 스위트 462 assertions와 probe 통과
- [x] 1280×720 Godot 관리·전투 렌더 확인
- [x] 신규 그래픽 생성 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 소스 PR #63 merge
- [x] 통합 SHA Web 보존·로컬 Chromium 실조작
- [x] Pages `/v20-p11t/` 공개·공개 Chromium 최종 확인
- [ ] 실제 사람 6~10명 무설명 블라인드 플레이와 Go/No-Go 판정
