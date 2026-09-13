# UIUX V2 동료 표정 완성도 개선

- 날짜: 2026-09-13
- WORKSTREAM_ID: UIUX-V2-EMOTION-PORTRAITS-20260913
- 브랜치: `codex/v126-uiux-u0-u3`
- 시작 HEAD: `a8bdb15469b3d427b45115a02e00445577e40f30`
- 권위 main / origin/main / 확인한 원격 main: `69a75970b1f8c030aa3a6956e5ca0f5bf15b2112`
- 제품 기준: 공개 안정판 1.2.6. 구 AGENTS의 1.2.5 문구보다 main CURRENT·최신 사용자 지시를 적용. 새 버전·태그·배포 없음.
- 사용자 순서: 주 에이전트 혼자 구현을 먼저 완료한 뒤 마지막에 관련 검증. 전체 검수·검수 에이전트 미요청.

## 구현 결과

1. 진화체 6종의 승리·부상 12개 초상을 GPT 내부 이미지 생성으로 제작하고 기존 중립 초상과 분리했다.
2. 왕관 6종도 승리·부상 12개를 제작했다. 실제 활성 왕관과 억제 상태를 기존 `_scaled_monster_stats` 경로로 판단한다. 관리 중립/의회 초상은 기존 것을 보존한다.
3. `finish_combat`에서 개별 동료 HP/최대 HP/전투 불능 상태를 기존 `metrics.monster_outcomes`에 기록한다. 35% 기준은 기존 HUD 위험 체력 기준과 같다. 승패만으로 부상을 추정하지 않는다.
4. 결과 성장 카드에서 전투 불능·낮은 HP는 부상, 나머지 승자는 승리 표정을 사용한다. 예전 저장에 개별 HP가 없으면 패배는 중립, 승리는 승리 초상으로 호환한다.
5. 전투 선택 상세는 기존 0.1초 HUD 갱신에서 실제 HP에 맞춰 초상을 바꾸며 회복 시 되돌린다. 경로가 달라질 때만 텍스처를 다시 선택한다.
6. 판정·보상·전투 수치·해금·비용·이동·스토리 이벤트·저장 버전을 변경하지 않았다. 검은 전체 높이 벽, 앞벽 반투명과 돌바닥도 유지한다.

## 실제 변경 경로

| 경로 | 변경 |
|---|---|
| `scripts/game/CombatSceneController.gd` | 결과 시점 개별 체력 스냅샷 |
| `scripts/game/ManagementSceneController.gd` | 상태별 초상, 왕관 부상 분기 |
| `scripts/ui/HUDController.gd` | 선택 상세의 동적 표정 갱신 |
| `scripts/ui/ResultWorkspaceUI.gd` | 실제 결과 성장 카드 표정 |
| `data/evolution_rules.json` | 6종 승리·부상 경로 |
| `data/regular_version/update4/crown_evolutions.json`, `asset_manifest.json` | 6종 왕관 초상 연결 |
| `assets/sprites/portraits/uiux_evolution/`, `uiux_crowns/` | 신규 atlas 4개·512×512 참조 24개, 밉맵 임포트 |
| `assets/source/imagegen/uiux_evolution_emotions_20260913/`, `uiux_crown_emotions_20260913/` | 원본 4개와 프롬프트·출처 |
| `assets/source/imagegen/uiux_evolution_portraits_20260913/SOURCE.md` | 과거 중립 재사용 설명에 후속 작업 연결 |
| `tools/UIUXEmotionPortraitTest.gd`, `.tscn`, `.gd.uid` | 실제 전투·결과·형태·직렬화·해상도 검사 |
| `tools/tests/Update4CrownAssetsPhase29Test.gd` | PNG/TRES 초상 3종 계약 |
| `docs/design/UIUX_DIRECTIONAL_ASSET_REQUEST_2026-09-13.md` | 방향 자산 실패와 남은 요청 명세 |

## 마지막 검사 결과

실행기는 `tmp/godot463/Godot_v4.6.3-stable_win64_console.exe`, 로그 루트는 `tmp/uiux_emotions_20260913/`.

| 검사 | 실제 결과 | 증거 |
|---|---|---|
| Godot headless editor import | 오류·구문 오류 없음 | `import.log` |
| UIUXEmotionPortraitTest | PASS 206 assertions | `direct.log`, `direct/*.png` |
| Update4CrownAssetsPhase29Test | PASS 61 assertions | 동명 `.log` |
| V122CombatResultUIContractTest | PASS | 동명 `.log` |
| V122ResultUISimplificationTest | PASS 37 assertions | 동명 `.log` |
| CampaignSaveLoadSmokeTest | PASS 246 assertions | 동명 `.log` |
| JSON 비교·자산 검사 | 초상 연결 외 규칙 데이터 동일, 4개 원본/런타임 SHA 동일, 1536×1024, 밉맵 활성 | `asset_data_checks.json` |
| `git diff --check` | PASS | 실행 출력 |

첫 직접 검사의 체력 변경 2개 assertion은 검사에서 GameRoot physics 자체를 꺼 HUD 갱신까지 정지시킨 탓에 실패했다. 제품 코드는 변경하지 않고 게임의 기존 `combat_paused`를 사용해 UI 주기 갱신을 유지했다. 왕관 실제 결과 텍스처 검사·캡처를 보강한 최종 직접 검사는 206항목을 통과했다.

왕관 기존 검사에는 원본 PNG를 Image.load로 읽는 export 경고 6건이 있다. 새 제품 경로는 Texture2D를 정상 로드하며, 이 경고는 기존 검사의 원본 프레임 검사에 한정된다. 저장 검사의 자동 저장 실패 경고 1건은 파일 쓰기 실패를 의도적으로 재현한 검사다. 전체 로그를 경고 0건으로 표현하지 않는다.

## 화면 증거와 해석 한계

- 로컬 모음: `tmp/uiux_emotions_20260913/index.html`.
- 1920×1080 / 글자 100%, 1280×720 / 글자 115%, Windows Forward+ RTX 3060 Ti에서 실제 게임 UI를 실행했다.
- 같은 전투 상세에서 정상 체력→20%→회복을 검사했다. 건강/부상 캡처는 상태 비교이며 구 버전 실행 캡처가 아니다.
- 결과 화면은 실제 `_start_combat`→`finish_combat` 경로에 통제된 HP·승리 상태를 넣어 얻었다. DAY 30을 사람이 완주한 증거가 아니다.
- 왕관 화면은 형태별 UI 검사용 결과 fixture다. 0/0 생존·기록 없음 표시는 실제 전투를 수행하지 않은 fixture의 값이며 밸런스 자료로 쓰지 않는다.
- 진화체 6종·왕관 6종의 전체 24개 초상 텍스처 크기와 경로를 검사했고, 왕관 12개 표정은 실제 결과 화면에서도 확인했다. 대표 결과·전투·지원 왕관 화면을 직접 열어 시각 확인했다.
- 1280 결과의 긴 관찰 문구는 줄바꿈되며 기능을 가리지 않는다. 모든 화면의 문구·미술 완성도나 사람 가독성 검수를 완료했다는 뜻은 아니다.

## 그래픽 근거와 미완료

- 채택된 UI 초상은 의도적으로 불투명 RGB이며 전장 스프라이트가 아니다. 생성 원본을 그대로 복사하고 Godot AtlasTexture 영역으로 연결했으며 로컬 래스터 편집은 하지 않았다.
- 방향 시트는 GPT 내부 생성 1회와 투명화 재요청 1회 모두 RGB 1448×1086, 알파 채널 없음. 체크무늬가 그림에 포함되어 런타임에 채택하지 않았다. 슬라임의 좌우 방향도 불명확했다.
- 상태: `ASSET_BLOCKED_NATIVE_ALPHA`. `direction_rejected.png`, `direction_retry_rejected.png`, `direction_prompts.json`에 증거 보존. 도구의 현재 호출 인터페이스에는 별도 background 파라미터가 없고 투명 요구는 실제 prompt에 명시했다. 모델 일반 기능의 부재로 단정하지 않는다.
- 방향 미술·일부 적 미술, 연속 성장 전력 비교·밸런스, 전체 캠페인/사람/Web/저사양/장시간 검증은 남았다. 이번 관련 검사를 전체 출시 승인으로 바꾸지 않는다.
- 공개 배포·태그·버전 확정·원격 푸시 없음. 전체 출시 판정 HOLD.
