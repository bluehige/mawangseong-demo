# V130R Step7 — 몬스터 24종 통합

## 1. 메타데이터

- 작성일: 2026-10-17 KST / WORKSTREAM_ID: V130R_STEP7_MONSTERS
- 목표 버전: 1.3.0 (버전 값 변경 없음).
- 작업 브랜치: `codex/v130r-defense-layout`.
- 기준 브랜치 및 SHA: 사용자 지정 0100 `5fa96c43c8556662667a70309d5948a19da313ba`.
- 마지막 구현 커밋 SHA / Reviewed SHA: `b4bc17544751b8e9147f2ac3949e4cda3a5276c3`.
- 구현 커밋: `92e62e4be2dc70ead6b81099a1fc622bda5eba44` / `Integrate 24 monsters into the approved defense map`.
- 보존 보정 커밋: `b4bc17544751b8e9147f2ac3949e4cda3a5276c3` / `Preserve existing rank four bond memories`.
- 본 인계와 CURRENT만 후속 문서 커밋한다. 문서 포함 마지막 SHA는 `git log -1` 참조.
- 원격 푸시 여부: 없음. PR·병합·태그·Steam·Release·배포 없음. main 브랜치 생성/이동/변경 없음.
- 권위 제한: 로컬 main 부재. 캐시 origin/main=`0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, v1.2.5=`f757ffa9f9e962158f2123856c8568a3163ecb6c` 확인. `git show main:...` 실패 후 origin/main 정책/CURRENT와 지정 브랜치 인계를 읽었다. 원격 조회/fetch 없이 최신 권위는 미확정이다. 사용자의 명시적 브랜치·기준·이번 범위를 따랐다.
- 가져오기: `git checkout codex/v130r-monsters -- <명시 경로>` 사용. merge/cherry-pick 없음. 출처 SHA `d8648efcf80b02261e4baa179e6fe8a1392dccef`, 파일별 PNG SHA256은 `data/v130r/import_provenance.json`.

## 2. 이번 세션 목표

- 요청 사항: 신규10+기존14 데이터·그림·스킬·명단·합류·유지비 통합, 지정6개 DAY 전투 표, 검수11장+문서2개, 영어 로컬 커밋.
- 완료 조건: 현재 승인 지도 런타임에서 24명 등록, 신규 스킬30개 직접 검증, 합동기3개 정상 기억 경로 해금 가능, 실제 화면 확인, 시뮬레이션과 보존 확인.
- 제외: main/원격 쓰기·태그/Steam·수치 튜닝·전체 회귀/전체 플레이/별도 검수 에이전트/성능/export·개인 세이브 접근. 이전 0096/0098 그림 후보·quarter_pilot 폴더는 가져오지 않았다.

## 3. 완료한 작업

- 구현: DataRegistry가 신규 몬스터/개체/캐릭터/스킬/전문화/기억을 명시 병합하고 24종 그림·초상화·유지비·소유 관계를 연결한다. 런타임에서 경로를 연결하여 정답 원문 JSON 문장·스탯을 보존했다. 원문 JSON의 design_only/not_generated는 제작 당시 표기이며 실제 연결 여부는 DataRegistry·파일·본 검사를 기준으로 읽는다.
- 스토리 및 데이터: 신규10종 기억3개·전문화2개, 기존 모리/돌콩/두둠/루미/미미 기억15개와 전문화, 로로 전문화2개 등록. 기존 기본4종의 유효한 rank4 기억도 보존하고 정의 없는 rank4 ID는 생성하지 않는다. 영어/간체444항목씩 및 분해된 합류 대사 본문을 번역 사전에 등록한다.
- 스킬: 액티브18·패시브12를 `V130RMonsterSkills`와 지도 유닛에서 구현. 혀 묶기1.5초와 감속3초 별도 타이머, 함정6초와 이웃+2초, 도발, 도둑 진행/소지금화/순손실 회수, 몬스터 은신/5초 재은신/탐지, 자기 빈 수비칸 순간이동, 가짜 목표 복원, 재조립 전투당1회·3초90%감소→25%회복, 공병 우선 방해, 저주6초/대신 맞기5초 등 원문 효과를 연결했다.
- 전투: 24종 SW/NE 시트와 좌우 반전의4방향. `_sheet_ne.png`도 4×4 프레임으로 분할한다. 입구를 향한 수비 대기, 공통 몸 높이96월드px·벙벙/텅텅/돌콩/톡톡1.15, 기존 보스/대형 적 규칙 유지. 0099/0100 이름표·알파 실루엣 코드를 유지한다.
- UI/UX: 명단24장(12×2), 합류 전 잠금·`--unlock-all`, 능동 스킬만 클릭 가능, 기존 GPT 아이콘 재사용. 높이 정렬은 공통 규칙을 사용한다. 지도 건물 깊이가 HUD/스킬창을 덮던 문제는 조작 계층을4090으로 올려 보완했다.
- 합류: 신규 join_day 조건을 만족하면 join_scenes의4줄을 기존 대화 UI로 표시하고 마지막 줄 종료 후 소유 명단과 시험 저장에 추가한다. 기존 계약2명 선택·전선·의회 조건은 DAY보다 우선한다.
- 식량: MonsterFoodService가 upkeep.json의24종(총48)을 읽는다. 배치만 정산·대기0·미지급 굶주림 등0095 경로를 재사용하며 이번 시험 저장은 step7 전용 경로다.
- 밸런스: 수치 조정 없음. 원본 DAY 웨이브와 기본 추천 배치로6일×10seed를 반복했다. DAY30 공병이 시설을 무력화한 뒤 그 자리에 계속 서던 지도 결함은 무력화 후 옥좌로 이동하도록 수정했다. 수정 전600초 정체를 발견했고 수정 후60회 모두 종료했다.
- 저장 및 호환성: APPDATA/LOCALAPPDATA를 `tmp/v130r_step7/isolated_*`로 격리. 개인 세이브를 열거나 수정하지 않았다. 작업 시작에 해시 기록한 기존1391파일은 모두 동일하다.

### 해석·기획과의 차이

| 항목 | 이번 처리와 한계 |
|---|---|
| 전문화 범위 | 요청1항의 데이터 통합으로 해석했다. 32개 정의와 소유 연결·로로2종을 등록했으며 원문 `stat_multipliers/stat_bonuses/skill_upgrade`의 빈 필드는 추정 채우지 않았다. 이32개 전문화의 별도 효과 핸들러 구현을 완료했다고 주장하지 않는다. |
| 미지정 스킬 값 | 원문 데이터의 마나0/쿨다운0 기본값을 유지했다. 불꽃 탄 등 명시 배율 없는 타격은 기본 공격 계산1.0, 거리 미지정 단일 대상 탐색은3칸을 사용한다. 칸 거리는0091과 같은71.554175월드px 환산이다. |
| 굶주림 지급 순서 | upkeep.json의 선언 순서로 지급한다. 지급 순서는 기획 미명시이며0095의 고정 카탈로그 순서 방식을24종 표에 적용했다. |
| 감정 | 신규 합류 표정은 base/happy/determined 슬롯으로 정규화한다. 단호·결의는determined, 기쁨은happy, 나머지는base로 대체한다. 원문 대사/감정 라벨은 JSON에 그대로 있다. |
| 꼬깃 최종 그림 | 가져올 branch의 quarter_final에는 REJECTED만 있어 GPT2회로 새로 만들었다. 채택 v2는32포즈·SW가 옆면에 가깝고 NE는등판. SW의 한 펼치기 스킬 자세는 등판이 더 드러난다. 기존0101 반려 그림을 채택한 것이 아니다. |
| 지도/진입점 | 기존 승인 지도 진입점을 사용한다. `tools/run_v130r_step7.ps1 -Fresh`는 시험 복사본, `-UnlockAll`은 시험 해금이다. 레거시 기본 캠페인 화면 전체를 새 승인 지도로 전환하는 작업은 이번 범위가 아니다. |
| DAY20 이후 | D/C 확정 도면이 없어0095 정책대로 E 지도를 사용한다. |
| 밸런스 표 | 각 날짜 독립·Lv1·옥좌1500·모리/돌콩 계약·전선/의회 미완료·신규는 join_day 도달분만. 날짜별 누적 성장/부상/원정/칙령/굶주림 이월 없음. seed별 결과가 같아 통계적 캠페인 승률로 해석하지 않는다. |
| 캡처 | roster/DAY15는24명 시험 해금·18명 출전(유지비37), 밸런스의 예산 추천 배치와 다르다. DAY15는 원본 웨이브 첫 접촉. 방향/크기는 가림 없이 비교하려고 길 밖 고정 시험 위치에 실제 게임 유닛을 둔 일시정지 검사다. 스킬6장은 조건을 만든 시험 상황에서 실제 핸들러를 호출했다. 자연 플레이/전체 캠페인 증거가 아니다. |

## 4. 변경 파일

구현 고유 경로 총 362개와 인계/CURRENT2개. 캡처·빌드·tmp 파일은 커밋하지 않았다. 전체 경로는 마지막 부록에 있다.

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v130r/*` | 신규10종·보충·번역·합류·유지비와 immutable import 기록 | 완료 |
| `assets/sprites/v130r/quarter_final/*` | 24종 SW/NE/피격 최종 그림과 검수 출처 | 완료 |
| `assets/sprites/v130r/<신규종>/portrait_*.png` | 신규10종 base/happy/determined/card | 완료 |
| `assets/sprites/v130r/portraits_contract/*` | 계약5종 감정10장 | 완료 |
| `assets/source/imagegen/v130r_step7_crumpled_map/*` | GPT원본2장·정확한 프롬프트·SOURCE | 완료 |
| `scripts/core/DataRegistry.gd`, `LanguageSettings.gd`, `scripts/game/GameRoot.gd` | 카탈로그·현지화·기억 존재 검사 | 완료 |
| `scripts/combat/V130RMonsterSkills.gd`, `scripts/units/ApprovedBattleUnit.gd`, `Unit.gd` | 신규30스킬·방향·NE 시트 분할 | 완료 |
| `scripts/game/ApprovedBattleController.gd`, `CombatSceneController.gd` | 전투·회수·광역/불 피해 문맥·공병 정체 수정 | 완료 |
| `scripts/map_builder/*`, `scripts/systems/MonsterFoodService.gd`, `scripts/ui/ApprovedBattleUI.gd` | 배치/합류/유지비·크기·조작 UI 깊이 | 완료 |
| `scenes/map_builder/ApprovedPlacementPreview.gd`, `tools/run_v130r_step7.ps1` | 격리 진입점·Godot 동시1개 | 완료 |
| `tools/tests/V130RStep7*`, `tools/tests/v130r_step7_audit.py`, `tools/content/validate_v130r_monsters.py`, `tools/art/assemble_v130r_step7_map.py` | 직접·화면·전투 시뮬레이션·보존·정답 대조·결정적 조립 | 완료 |
| `docs/handoff/V130R_STEP7_MONSTERS_2026-10-17.md`, `CURRENT.md` | 본 인계·브랜치 진입점 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용: 꼬깃 신규2회. 채택 v2는 native alpha0..254이며 강제로255로 바꾸지 않았다. v1은0..255이나 앞면 우세/포즈 부족으로 미채택 증거만 보존한다.
- 모델: `GPT internal image generation`. 외부 생성기·API·배경 제거·코드 그림·오디오 변경 없음.
- 원본: `assets/source/imagegen/v130r_step7_crumpled_map/generated_atlas_v2.png`, 미채택 `generated_atlas.png`.
- 출처 문서: 같은 폴더 `SOURCE.md`, 정확한 `PROMPT_V1.txt`/`PROMPT_V2.txt`.
- 런타임: `assets/sprites/v130r/quarter_final/crumpled_map/` 4PNG. 다른23종과 초상화는 지정 source branch의 승인 GPT 자산을 재사용했다. 재사용 원본·과거 제작 기록은 source SHA에 보존하며 이번 worktree에 중간 후보를 복제하지 않았다.
- v2는 생성기가 요청한 균등 행 간격을 지키지 않아 균등 분할본을 버리고,32개 분리된 몸체 연결성분(서로 붙은 몸체 영역) 경계+3px 여백으로 원본 직사각형을 잘라 비율 유지 축소·정렬·조립했다. 알파 마스크를 바꾸거나 픽셀을 그리지 않았다. 재조립은 `python -X utf8 tools/art/assemble_v130r_step7_map.py`.
- 24종×2 시트48장 모두 실제 RGBA·알파 최솟값0 확인. 프레임이 시트 전체가 아닌 단일 셀인지, 살아 있는 모든 등록 프레임의 몸 높이96×배율이 유지되는지 직접 검사했다.
- 실제1920×1080 PNG11장과 최대1000×600 축소본을 한 장씩 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `python -X utf8 tools/content/validate_v130r_monsters.py --design-dir <정답 폴더>` | 2737검사/오류0 | 원문 스탯·문장·참조·444×2번역 대조 |
| 2 | `tools/run_v130r_step7.ps1 -Mode import` | 성공·최종stderr0 | `tmp/v130r_step7/import.*log` |
| 3 | 같은 실행기 `-Mode direct` | **1821검사/실패0·stderr0** | `tmp/v130r_step7/direct_result.json` |
| 4 | 같은 실행기 `-Mode capture` | **100검사/실패0·stderr0** | `tmp/v130r_step7/capture_result.json` |
| 5 | 같은 실행기 `-Mode balance` | **60전투/60검사/실패0·stderr0** | `tmp/v130r_step7/balance_result.json`, 외부 `balance_sim.md` |
| 6 | `python -X utf8 tools/tests/v130r_step7_audit.py` | PNG11·알파48·기존1391SHA256불변 PASS | 외부 `audit.json` |
| 7 | Python AST·PowerShell parser·scoped/cached diff --check | PASS | 실행 명령 출력 |
| 8 | `tmp/v130r_step7/run_join_proof.ps1 -Mode capture` | **합류 보완8검사/실패0·stderr0** | 외부 `join_proof.json`; 최종 join_scene은 퐁당의 원문 두 번째 줄 |
| 9 | 전체 회귀/전체 플레이/별도 검수 에이전트/성능/export | NOT_REQUESTED·미실행 | 표적 범위 밖 |

직접 검사: 액티브18와 패시브12 각각 발동/효과/조건·지속 종료 또는 범위/체력 조건 해제, 실제 은신 적의 탐지 전/후/이탈, 대신 맞기50피해→15/35 분배,3합동기 정상 유대 기억→조건 서비스→실제 해금, 기존4종 rank4 보존/보충종의 없는 rank4 비발명,24종 전체 방향과 프레임 크기/단일 셀 분할을 포함한다. 최종 후속은 기억 rank4 보존과 감사 표제만 보정했으며 직접 검사를 다시 실행했다. 최종1821이 유효하다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: b4bc17544751b8e9147f2ac3949e4cda3a5276c3
- Review range: 5fa96c43c8556662667a70309d5948a19da313ba..b4bc17544751b8e9147f2ac3949e4cda3a5276c3
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

별도 검수 에이전트 반복 기록: NOT_REQUESTED. 전수 검수/출시 승인 의미가 아니다. 위 SHA 이후에는 본 인계와 CURRENT만 변경했다. 합류 보완은 ignored tmp의 소규모 파생 시험 씬으로 실행하여 퐁당 초상화와 대사37번 요구서를 직접 촬영했고, 대화 종료 전 미소유/종료 후 명단 추가까지8검사를 통과했다. 제품 코드/데이터/자산/도구를 수정하지 않았다.

### 전투 표

| DAY | 시험 수 | 출전(신규) | 유지비/수입 | 승률 | 평균 옥좌 HP | 최소–최대 | 판정 |
|---|---:|---:|---:|---:|---:|---:|---|
| 5 | 10 | 8(2) | 11/15 | 100% | 100.0% | 100.0–100.0% | 너무 쉬움 |
| 10 | 10 | 10(4) | 15/15 | 100% | 100.0% | 100.0–100.0% | 너무 쉬움 |
| 15 | 10 | 13(7) | 21/23 | 100% | 100.0% | 100.0–100.0% | 너무 쉬움 |
| 20 | 10 | 15(9) | 25/30 | 100% | 100.0% | 100.0–100.0% | 너무 쉬움 |
| 25 | 10 | 16(10) | 28/30 | 100% | 100.0% | 100.0–100.0% | 너무 쉬움 |
| 30 | 10 | 16(10) | 28/34 | 100% | 100.0% | 100.0–100.0% | 너무 쉬움 |

모든 날짜는 요청 기준(승률100%·옥좌95%이상)으로 **너무 쉬움** 표시다. 패치로 수치를 바꾸지 않았다. 수정 전 공병600초 정체 표본은 최종60회 표에서 제외했다.

## 7. 미해결 항목과 위험

- 이번 요청의 기능·표적 검사 실패는 남지 않았다. 위 표의 전문화 효과 범위·거리 기본값·감정 정규화·지급 순서는 기획 해석으로 남긴다.
- 밸런스60회는 같은 조건의 결정적 결과라 실제 전체 캠페인 난이도를 확정할 수 없다. 모든 시험이 너무 쉬움이다.
- 꼬깃 한 스킬 포즈의 등판 노출과 장시간 애니메이션 취향은 사용자가 판단할 수 있다. 0096/0098/quarter_pilot 대체 채택은 없다.
- 원격 최신 main 권위 미확정. 개인 기존1.2.12/1.3.0 저장에 대한 전체 캠페인 이전·장시간 플레이·모든 조합·다른 장치 검수는 이번에 하지 않았다.

## 8. 다음 작업 순서

1. 헤드는 외부 `roster_24.png`, `directions.png`, `compare_scale.png`, `join_scene.png`, 스킬6장과 꼬깃 v2 자세를 검토한다. 완료 조건: 시각 취향의 수용 여부 확인. 별도 그림 변경은 필요할 때만 수행한다.
2. `balance_sim.md`의 너무 쉬움6개 날짜와 독립 Lv1 조건을 검토한다. 다음 밸런스 변경 요청이 있을 때만 수치를 조정한다. 이번에는 변경 금지였다.
3. 전문화32개 실제 효과 구현 또는 일반 캠페인 전체 진입점 전환이 다음 목표라면 별도 범위로 이어간다. main/공개 배포·태그·Steam은 이번 승인에 포함되지 않는다.

## 9. 작업 트리 상태

- 영어 로컬 구현 커밋2개 + 본 인계/CURRENT의 후속 문서 커밋만. 원격 쓰기 없음.
- 시작 때 해시 기록한 기존1391파일 SHA256 불변. 기존 혼합 변경은 스테이징/되돌림/삭제하지 않았다.
- 인계 시 기존1391개 외 미추적 경로7개도 보였다: `docs/design/v131_layout/`(이번 범위 밖, 미접근·비변경), Godot 생성 `.uid`6개(아래). 어느 것도 이번 커밋에 섞지 않았다.
- 추가 UID: `scripts/map_builder/ApprovedBattleOcclusion.gd.uid`, `scripts/units/approved_battle_silhouette.gdshader.uid`, `tools/tests/V130RStep4BScaleTest.gd.uid`, `tools/tests/V130RStep4CScaleTest.gd.uid`, `tools/tests/V130RStep4DLabelsTest.gd.uid`, `tools/tests/V130RStep4ESilhouetteTest.gd.uid`.
- 스태시·브랜치 전환·별도 worktree 생성 없음. 첫 Godot0/동시 최대1/최종0. 실패 진단 때도 식별한 자기 프로세스만 종료했다.
- 결과/로그/개인 저장 격리/시험 저장은 `tmp/v130r_step7/` 및 지정 외부 `_mockup/game_step7_monsters/`. 소스 브랜치에 PNG 캡처·빌드 파일을 커밋하지 않았다.
- 외부 필수 결과: `roster_24.png`, `battle_new_day15.png`, `directions.png`, `join_scene.png`, `compare_scale.png`, `skill_tongue_snag.png`, `skill_no_passage.png`, `skill_peekaboo.png`, `skill_tunnel_hop.png`, `skill_cheese_reclaim.png`, `skill_reassemble.png`, `duo_unlock_test.md`, `balance_sim.md`.

## 10. 종료 체크리스트

- [x] 구현과 요청 범위 대조·차이/가정 명시
- [x] 관련 테스트·사용자 지정 전투60회·실제 화면 검사 통과
- [x] 전체 회귀·전체 플레이·검수 에이전트 미요청/미실행 기록
- [x] 최종 코드 SHA·정책 필드 기록
- [x] 생성 출처·실제 알파·런타임 연결 기록
- [x] CURRENT 갱신·기존 혼합 변경 보존
- [x] 의도한 파일만 영어 로컬 커밋
- [x] main/원격/PR/태그/Steam 비변경·Godot0 기록

## 부록: 구현 전체 경로

- `assets/source/imagegen/v130r_step7_crumpled_map/PROMPT_V1.txt`
- `assets/source/imagegen/v130r_step7_crumpled_map/PROMPT_V2.txt`
- `assets/source/imagegen/v130r_step7_crumpled_map/SOURCE.md`
- `assets/source/imagegen/v130r_step7_crumpled_map/generated_atlas.png`
- `assets/source/imagegen/v130r_step7_crumpled_map/generated_atlas_v2.png`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_base.png`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_base.png.import`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_card.png`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_card.png.import`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_determined.png`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_determined.png.import`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_happy.png`
- `assets/sprites/v130r/bridge_troll/portrait_bridge_troll_happy.png.import`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_base.png`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_base.png.import`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_card.png`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_card.png.import`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_determined.png`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_determined.png.import`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_happy.png`
- `assets/sprites/v130r/candle_wisp/portrait_candle_wisp_happy.png.import`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_base.png`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_base.png.import`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_card.png`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_card.png.import`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_determined.png`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_determined.png.import`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_happy.png`
- `assets/sprites/v130r/crumpled_map/portrait_crumpled_map_happy.png.import`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_base.png`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_base.png.import`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_card.png`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_card.png.import`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_determined.png`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_determined.png.import`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_happy.png`
- `assets/sprites/v130r/curse_doll/portrait_curse_doll_happy.png.import`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_base.png`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_base.png.import`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_card.png`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_card.png.import`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_determined.png`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_determined.png.import`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_happy.png`
- `assets/sprites/v130r/glue_snail/portrait_glue_snail_happy.png.import`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_base.png`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_base.png.import`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_card.png`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_card.png.import`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_determined.png`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_determined.png.import`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_happy.png`
- `assets/sprites/v130r/hollow_armor/portrait_hollow_armor_happy.png.import`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_base.png`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_base.png.import`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_card.png`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_card.png.import`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_determined.png`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_determined.png.import`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_happy.png`
- `assets/sprites/v130r/mole_digger/portrait_mole_digger_happy.png.import`
- `assets/sprites/v130r/portraits_contract/dolkong_determined.png`
- `assets/sprites/v130r/portraits_contract/dolkong_determined.png.import`
- `assets/sprites/v130r/portraits_contract/dolkong_happy.png`
- `assets/sprites/v130r/portraits_contract/dolkong_happy.png.import`
- `assets/sprites/v130r/portraits_contract/dudum_determined.png`
- `assets/sprites/v130r/portraits_contract/dudum_determined.png.import`
- `assets/sprites/v130r/portraits_contract/dudum_happy.png`
- `assets/sprites/v130r/portraits_contract/dudum_happy.png.import`
- `assets/sprites/v130r/portraits_contract/mimi_determined.png`
- `assets/sprites/v130r/portraits_contract/mimi_determined.png.import`
- `assets/sprites/v130r/portraits_contract/mimi_happy.png`
- `assets/sprites/v130r/portraits_contract/mimi_happy.png.import`
- `assets/sprites/v130r/portraits_contract/moon_determined.png`
- `assets/sprites/v130r/portraits_contract/moon_determined.png.import`
- `assets/sprites/v130r/portraits_contract/moon_happy.png`
- `assets/sprites/v130r/portraits_contract/moon_happy.png.import`
- `assets/sprites/v130r/portraits_contract/mori_determined.png`
- `assets/sprites/v130r/portraits_contract/mori_determined.png.import`
- `assets/sprites/v130r/portraits_contract/mori_happy.png`
- `assets/sprites/v130r/portraits_contract/mori_happy.png.import`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_sheet.png`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_sheet.png.import`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/armored_beetle/armored_beetle_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/armored_beetle/art_review.json`
- `assets/sprites/v130r/quarter_final/bat_courier/art_review.json`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_sheet.png`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_sheet.png.import`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/bridge_troll/art_review.json`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_sheet.png`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_sheet.png.import`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/candle_wisp/art_review.json`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_sheet.png`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_sheet.png.import`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/candle_wisp/candle_wisp_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/crumpled_map/REJECTED.md`
- `assets/sprites/v130r/quarter_final/crumpled_map/art_review.json`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet.png`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet.png.import`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/curse_doll/art_review.json`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_sheet.png`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_sheet.png.import`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/curse_doll/curse_doll_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/art_review.json`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_sheet.png`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_sheet.png.import`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/ghost_housemaid/ghost_housemaid_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/glue_snail/art_review.json`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_sheet.png`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_sheet.png.import`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/glue_snail/glue_snail_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/goblin/art_review.json`
- `assets/sprites/v130r/quarter_final/goblin/goblin_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/goblin/goblin_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/goblin/goblin_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/goblin/goblin_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/goblin/goblin_sheet.png`
- `assets/sprites/v130r/quarter_final/goblin/goblin_sheet.png.import`
- `assets/sprites/v130r/quarter_final/goblin/goblin_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/goblin/goblin_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/graveyard_hound/art_review.json`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_sheet.png`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_sheet.png.import`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/hollow_armor/art_review.json`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_sheet.png`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_sheet.png.import`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/hollow_armor/hollow_armor_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/imp/art_review.json`
- `assets/sprites/v130r/quarter_final/imp/imp_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/imp/imp_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/imp/imp_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/imp/imp_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/imp/imp_sheet.png`
- `assets/sprites/v130r/quarter_final/imp/imp_sheet.png.import`
- `assets/sprites/v130r/quarter_final/imp/imp_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/imp/imp_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/kobold_scout/art_review.json`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_sheet.png`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_sheet.png.import`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/kobold_scout/kobold_scout_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/mimic_porter/art_review.json`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_sheet.png`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_sheet.png.import`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/mole_digger/art_review.json`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_sheet.png`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_sheet.png.import`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/mole_digger/mole_digger_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/moon_tracker/art_review.json`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_sheet.png`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_sheet.png.import`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/rat_union/art_review.json`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_sheet.png`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_sheet.png.import`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/rat_union/rat_union_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/river_frog/art_review.json`
- `assets/sprites/v130r/quarter_final/river_frog/assemble_0101a.py`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_sheet.png`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_sheet.png.import`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/river_frog/river_frog_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/slime/art_review.json`
- `assets/sprites/v130r/quarter_final/slime/slime_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/slime/slime_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/slime/slime_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/slime/slime_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/slime/slime_sheet.png`
- `assets/sprites/v130r/quarter_final/slime/slime_sheet.png.import`
- `assets/sprites/v130r/quarter_final/slime/slime_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/slime/slime_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/spider_tailor/art_review.json`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_sheet.png`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_sheet.png.import`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/spider_tailor/spider_tailor_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/spore_healer/art_review.json`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_sheet.png`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_sheet.png.import`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/stone_sentinel/art_review.json`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_sheet.png`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_sheet.png.import`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/stone_sentinel/stone_sentinel_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/art_review.json`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_sheet.png`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_sheet.png.import`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/under_bed_shadow/under_bed_shadow_sheet_ne.png.import`
- `assets/sprites/v130r/quarter_final/war_drummer/art_review.json`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_hurt_ne.png`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_hurt_ne.png.import`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_hurt_sw.png`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_hurt_sw.png.import`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_sheet.png`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_sheet.png.import`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_sheet_ne.png`
- `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_sheet_ne.png.import`
- `assets/sprites/v130r/rat_union/portrait_rat_union_base.png`
- `assets/sprites/v130r/rat_union/portrait_rat_union_base.png.import`
- `assets/sprites/v130r/rat_union/portrait_rat_union_card.png`
- `assets/sprites/v130r/rat_union/portrait_rat_union_card.png.import`
- `assets/sprites/v130r/rat_union/portrait_rat_union_determined.png`
- `assets/sprites/v130r/rat_union/portrait_rat_union_determined.png.import`
- `assets/sprites/v130r/rat_union/portrait_rat_union_happy.png`
- `assets/sprites/v130r/rat_union/portrait_rat_union_happy.png.import`
- `assets/sprites/v130r/river_frog/portrait_river_frog_base.png`
- `assets/sprites/v130r/river_frog/portrait_river_frog_base.png.import`
- `assets/sprites/v130r/river_frog/portrait_river_frog_card.png`
- `assets/sprites/v130r/river_frog/portrait_river_frog_card.png.import`
- `assets/sprites/v130r/river_frog/portrait_river_frog_determined.png`
- `assets/sprites/v130r/river_frog/portrait_river_frog_determined.png.import`
- `assets/sprites/v130r/river_frog/portrait_river_frog_happy.png`
- `assets/sprites/v130r/river_frog/portrait_river_frog_happy.png.import`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_base.png`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_base.png.import`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_card.png`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_card.png.import`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_determined.png`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_determined.png.import`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_happy.png`
- `assets/sprites/v130r/under_bed_shadow/portrait_under_bed_shadow_happy.png.import`
- `data/v130r/characters_new.json`
- `data/v130r/import_provenance.json`
- `data/v130r/join_scenes.json`
- `data/v130r/localization_en.json`
- `data/v130r/localization_zh_cn.json`
- `data/v130r/memory_entries_new.json`
- `data/v130r/monster_instances_new.json`
- `data/v130r/monsters_new.json`
- `data/v130r/skills_new.json`
- `data/v130r/specializations_new.json`
- `data/v130r/upkeep.json`
- `scenes/map_builder/ApprovedPlacementPreview.gd`
- `scripts/combat/V130RMonsterSkills.gd`
- `scripts/combat/V130RMonsterSkills.gd.uid`
- `scripts/core/DataRegistry.gd`
- `scripts/core/LanguageSettings.gd`
- `scripts/game/ApprovedBattleController.gd`
- `scripts/game/CombatSceneController.gd`
- `scripts/game/GameRoot.gd`
- `scripts/map_builder/ApprovedActorPresentation.gd`
- `scripts/map_builder/ApprovedActorPresentation.gd.uid`
- `scripts/map_builder/ApprovedGradeProgression.gd`
- `scripts/map_builder/ApprovedMonsterPlacement.gd`
- `scripts/map_builder/ApprovedMonsterPlacementUI.gd`
- `scripts/map_builder/ApprovedPlacementView.gd`
- `scripts/map_builder/ApprovedRecruitment.gd`
- `scripts/systems/MonsterFoodService.gd`
- `scripts/ui/ApprovedBattleUI.gd`
- `scripts/units/ApprovedBattleUnit.gd`
- `scripts/units/Unit.gd`
- `tools/art/assemble_v130r_step7_map.py`
- `tools/content/validate_v130r_monsters.py`
- `tools/run_v130r_step7.ps1`
- `tools/tests/V130RStep7MonstersTest.gd`
- `tools/tests/V130RStep7MonstersTest.gd.uid`
- `tools/tests/V130RStep7MonstersTest.tscn`
- `tools/tests/V130RStep7Simulation.gd`
- `tools/tests/V130RStep7Simulation.gd.uid`
- `tools/tests/v130r_step7_audit.py`
