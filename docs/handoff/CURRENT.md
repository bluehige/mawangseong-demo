# 현재 작업 핸드오프

최종 갱신: 2026-07-20

이 파일은 다음 세션의 단일 진입점이다.

- 현재 제품 버전 체계: `docs/PRODUCT_VERSIONING.md` (`1.0 → 1.1 → 1.2 → 2.0 → 3.0 → 4.0`)
- 제품 1.2.1 전체 검증·공개 출시 진행: `docs/handoff/V12_1_PUBLIC_RELEASE_2026-07-20.md`
- 제품 1.2.1 태그 Windows LFS·PCK 오디오·부팅 검증 강화: `docs/handoff/V12_1_RELEASE_WORKFLOW_LFS_2026-07-20.md`
- 제품 1.2 이슈 #39 실제 사용자 플레이 검수·P1/P2 수정: `docs/handoff/V12_USER_PLAYTEST_QA_2026-07-20.md`
- 제품 v1.2 공개 출시·PC/모바일 Web 갱신: `docs/handoff/V12_PUBLIC_RELEASE_2026-07-16.md`
- 제품 1.2 최종 검수: `docs/handoff/V12_FINAL_REVIEW_2026-07-16.md`
- 제품 1.2 버전 체계 전환: `docs/handoff/PRODUCT_VERSION_MIGRATION_2026-07-16.md`
- 지시 전용 전투·3배속·UI·PC 한글 입력 구현: `docs/handoff/DIRECTIVE_COMBAT_IMPLEMENTATION_2026-07-16.md`
- 구현 전 원문 계획: `docs/handoff/DIRECTIVE_COMBAT_INPUT_PLAN_2026-07-16.md`
- v0.5 PC·모바일 플랫폼 성능 수정: `docs/handoff/V05_PLATFORM_PERFORMANCE_2026-07-15.md`
- v0.5 모바일 전용 PCK 최적화: `docs/handoff/V05_MOBILE_PCK_OPTIMIZATION_2026-07-15.md`
- v0.5 모바일 터치 UI 개선: `docs/handoff/V05_MOBILE_TOUCH_UI_2026-07-15.md`
- v0.5 공개 Web·모바일 플레이테스트: `docs/handoff/V05_PUBLIC_PLAYTESTS_2026-07-15.md`
- v0.5 Lyria 오디오 정식·Web·모바일 브라우저 빌드 적용: `docs/handoff/V05_LYRIA_AUDIO_BUILD_APPLICATION_2026-07-15.md`
- v0.5 Lyria 3 상황·스킬 오디오 확장: `docs/handoff/V05_LYRIA3_AUDIO_EXPANSION_2026-07-15.md`
- v0.5 Lyria 3 오디오 교체 파이프라인: `docs/handoff/V05_LYRIA3_AUDIO_PIPELINE_2026-07-15.md`
- v0.5 Steam 판매 출시 준비: `docs/handoff/V05_STEAM_RELEASE_READINESS_2026-07-15.md`
- v0.2.3 Pages provenance 수정: `docs/handoff/V02_PAGES_PROVENANCE_2026-07-14.md`
- v0.2.2 Web 릴리즈 증빙 호환: `docs/handoff/V02_RELEASE_EVIDENCE_2026-07-14.md`
- v0.2.1 입력 레이어 핫픽스·Web 릴리즈: `docs/handoff/V02_INPUT_LAYER_WEB_RELEASE_2026-07-14.md`
- v0.4 UI 입력 레이어 방어 작업: `docs/handoff/V04_INPUT_LAYER_GUARD_2026-07-14.md`
- v0.4 순차 개발 마감: `docs/handoff/V04_SEQUENTIAL_FINALIZATION_2026-07-14.md`
- v0.3 순차 개발 마감: `docs/handoff/V03_SEQUENTIAL_FINALIZATION_2026-07-14.md`
- v0.3 최신 튜토리얼 버그픽스·Web 갱신: `docs/handoff/V03_TUTORIAL_ENEMY_CLICK_WEB_2026-07-14.md`
- v0.3 소스 통합: `docs/handoff/V03_MAIN_INTEGRATION_2026-07-13.md`
- 버전별 원문 계획: `docs/design/plans/README.md`

## 현재 실행 원칙

- 과도한 반복 관측은 실행하지 않는다.
- 변경 범위와 직접 관련된 테스트만 실행한다.
- 버전 마감에서는 자동 버그 회귀를 꼼꼼히 실행하고, 전체 플레이·시각 재검수·별도 검수 에이전트는 사용자가 그 작업에서 요청한 경우에만 실행한다.
- 신규 그래픽은 GPT 내부 이미지 생성 도구만 사용하고 `assets/source/imagegen/<version>/` 원본과 `assets/` 런타임 자산을 분리한다.

`v0.*`가 붙은 아래 과거 문서·브랜치·태그는 2026-07-16 이전 구 체계 기록이다. 이름을 바꾸지 않으며 새 릴리스 번호로 재사용하지 않는다.

## 제품 1.2.1 공개 출시 완료 상태

- 플레이 검수 수정 PR #40은 merge commit `25a41a4f08925e35592aca890e0c56a75c5203f9`로 `main`에 병합됐다.
- 새 `main`에서 `hotfix/v1.2.1`을 분기하고 프로젝트·Windows 파일의 기술 버전을 1.2.1로 올렸다. 화면 표시는 1.2, 기존 저장 경로는 그대로 유지한다.
- 기능·버전 SHA `07586e51a7c66d6290602629a54b4cb6ce6b6d40` 뒤 Steam 테스트 픽스처의 구버전 하드코딩을 수정했고, PR #41 merge·출시 SHA `c483d135b13cf9771ee43b045ba2c3dde51573ee`의 깨끗한 작업 트리에서 `RunCoreVerification.ps1 -Mode Full` 89/89를 통과했다.
- 최초 대량 임포트에서 Godot 4.5.2 폰트 임포터가 접근 위반으로 한 번 종료됐지만, 캐시 완성 뒤 동일 SHA의 프로젝트 임포트와 전체 89개 검증은 PASS했다.
- 기능상 남은 P1/P2는 0건이다. Windows 코드 서명과 물리 Microsoft 한국어 IME 한/영 전환은 외부 수동 확인 항목으로 남는다.
- 주석 태그 `v1.2.1`과 [GitHub Release `마왕성 v1.2.1`](https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.1)을 공개했다. Windows ZIP은 263,306,748바이트, SHA-256 `63118100a3b304a1c10c904a6e6b5da2a368ee0d5721dcd9037b982f80f3cb3e`이며 코드 서명은 없다.
- [PC Web](https://bluehige.github.io/mawangseong-web-playtest/)과 [모바일 Web](https://bluehige.github.io/mawangseong-mobile-playtest/)을 같은 태그 소스로 배포했다. PC 1920×1080과 모바일 844×390에서 타이틀→새 게임 등록, 모바일 390×844 회전 안내, 콘솔 오류·경고 0건과 모든 런타임 요청 HTTP 200을 확인했다.
- 모바일 제목 P3 불일치는 PR #8과 Pages run 29733411515로 수정해 공개 `<title>`도 `v1.2.1`로 맞췄다.
- 태그 Actions run 29729582970의 LFS 오디오 누락 artifact는 사용 금지다. 공식 Release에는 태그 SHA clean LFS 빌드만 첨부했고, PR #42 merge `bc7ca8e2b0763814b69beaf0db3ee29bc3cf8d56`에서 다음 태그용 LFS·PCK BGM·Windows 부팅 검사를 강제했다.

## 제품 1.2 이슈 #39 실제 사용자 검수·수정 상태

- `codex/v12-playtest-fixes`의 `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54`에서 이슈 #39의 기존 실제 사용자 검수 결과와 추가 사용자 지적을 합쳐 수정했다.
- DAY 3 승리 결산 저장·재실행 뒤 성장 버튼 진행 불가와, 보스 HP 50% 안내 전 패배 뒤 재전투가 막히는 P1을 수정했다.
- DAY 2 가시 복도에 실제 클릭 중심을 가리키는 큰 노란 마름모·점·배지를 추가하고, 후속 행동을 오른쪽 `[방 지침]`의 `[함정 유도]`로 짧고 일치하게 안내한다.
- 대화 초상화와 텍스트 패널 사이에 28px 간격을 두었고, 자동전투 경로점을 맵 안으로 보정하며 0.75초 정체 시 오래된 경로를 폐기해 재탐색하게 했다.
- 저장 안전 화면 판정을 단일화하고 Windows export에 제품명·설명·1.2.0 버전·아이콘을 지정했다.
- 관련 회귀와 `RunCoreVerification.ps1 -Mode Full`이 89/89 통과했다. 수정 Windows export를 격리 저장공간에서 새 게임부터 DAY 1 완료와 DAY 2 가시 복도·함정 유도 안내까지 Computer Use로 재검증했다.
- 사용자 기존 저장 파일의 SHA-256과 수정 시각은 검수 전후 동일하다. 빌드·캡처는 모두 `tmp/`에 있으며 커밋 대상이 아니다.
- 기능상 재현되는 P1/P2는 0건이다. 불변 검수 SHA `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54`의 분리 작업공간에서 전체 89/89를 다시 통과해 최종 PASS를 고정했다.
- 구현 브랜치는 [PR #40](https://github.com/bluehige/mawangseong-demo/pull/40), merge commit `25a41a4f08925e35592aca890e0c56a75c5203f9`로 `main`에 병합했다.
- 1.2.1 수정판 출시까지 완료했다. 남은 외부 확인은 Windows 코드 서명 인증서와 물리 한국어 IME 조합 중 실기 확인이며 기존 `v1.2.0` 태그와 Release는 변경하지 않았다.

## 제품 v1.2 공개 출시 상태

- 사용자 표시 이름은 `v1.2`, 다음 확장판은 `v2.0`으로 통일했다. 프로젝트·태그의 기술 버전은 SemVer `1.2.0`, `2.0.0`을 사용한다.
- 불변 태그 `v1.2.0`과 GitHub Release `마왕성 v1.2`를 만들고 Windows ZIP을 첨부했다.
- PC Web과 모바일 Web을 각각 v1.2 빌드로 교체해 Pages 배포를 완료했고, 공개 주소에서 캔버스 기동과 브라우저 오류 0건을 확인했다.
- 태그 시점의 자동 Windows 빌드는 공식 Godot ZIP 파일명 불일치로 실패했다. Release에는 로컬 clean worktree에서 검증한 Windows ZIP을 수동 첨부했으며, 이후 태그용 워크플로 파일명은 후보 SHA `9e02b967fce83f1c5bc960b681635b0f2b2058e1`에서 수정해 [PR #37](https://github.com/bluehige/mawangseong-demo/pull/37), merge commit `4a02eaac72cb5f45965e6981d0436ed20b6f0561`로 `main`에 반영했다. 불변 태그는 이동하지 않는다.
- 사용자 요청에 따라 이번 공개 갱신에서는 전체 회귀·전체 플레이·별도 검수 에이전트를 실행하지 않고 출시 대상 관련 테스트와 공개 URL 부팅만 확인했다.

## 제품 1.2 지시 전용 전투 구현 상태

- `codex/v12-directive-combat`에서 단일 유닛 직접 이동·공격·수동 스킬을 제거하고 전역·방 지시 기반 자동 AI로 전환했다.
- 유닛 몸체 충돌·회피·우회를 제거하고 PC·모바일 x1~x3와 일시정지를 연결했다. 공격·스킬 거리와 맵 경계는 유지한다.
- DAY 1~3 튜토리얼은 x1로 고정했다. 완료 뒤 첫 일반 전투를 잠시 멈추고 PC·모바일 속도 버튼 위치와 x1~x3 효과를 한 번 소개하며, 확인 상태는 구형 저장과 호환되게 저장한다.
- DAY 1~3을 배치·방어·함정 유도·후퇴 지점과 자동 행동 관찰 중심으로 줄이고 구형 진행 인덱스를 보정했다.
- 이름 입력창 재생성을 없애고 텍스트 입력 포커스가 전역 키를 소유하게 해 Windows IME 조합 중단 원인을 수정했다. 한글·숫자 혼합 저장 왕복 자동 테스트와 Windows 빌드의 한글 입력·Backspace·재입력·시작 전환을 확인했다. 자동화 제약으로 물리 한/영 키 조합 중 상태만 별도 실기 확인이 남아 있다.
- 확대 글꼴의 상단 자원·DAY·체력·시설 효과와 하단 지시 HUD를 재배치했다. PC·모바일 최대 글꼴의 1920×1080·1366×768·1280×720 렌더 계약이 통과했다.
- 대표 전투는 DAY 1 36.0초, DAY 2 35.6초, DAY 3 68.7초에 승리했다. x3 체감 환산은 약 12.0초·11.9초·22.9초다.
- PC Web 1.2.0은 1280×720에서 타이틀·빠른 시작·튜토리얼 대상·지시 메뉴를 실제 조작했고 오류 0건이다. 빠른 시작 seed 미초기화 경고를 발견해 수정하고 회귀를 추가했다.
- 사용자 요청에 따른 전체 검수는 1차 84/89에서 5건을 수정하고, 후보 검수 88/89에서 베베 자동 구조 테스트 조건 1건을 격리한 뒤 최종 SHA `e0da9591d0e317104f0d021509b6a9ba2b958e75`에서 89/89 전부 통과했다.

## 현재 계보와 구 버전 기록

아래 `v0.*` 항목은 공개·감사 이력을 보존한 구 명칭이다. 현재 제품 버전은 1.2, 기술 SemVer는 1.2.0이다.

| 브랜치·커밋 | SHA | 의미 |
|---|---|---|
| 제품 1.2 지시 전용 전투 `main` 병합 | `93ba159694cf6010f4ec0f93331913c131f749ce` | [PR #35](https://github.com/bluehige/mawangseong-demo/pull/35) merge commit 통합. 최종 검수 SHA `e0da9591d0e317104f0d021509b6a9ba2b958e75`, 전체 89/89와 P1/P2 0건 기준 |
| v0.5 PC·모바일 플랫폼 성능 수정·공개 배포 | `bb61ba99a9403532345d441233a8c59821b3fecd` | [소스 PR #33](https://github.com/bluehige/mawangseong-demo/pull/33) merge commit 통합. 공통 던전 과다 렌더와 Web BGM 선디코딩을 제거하고 native full, PC Web balanced, mobile 경량 프로필을 분리. [PC PR #4](https://github.com/bluehige/mawangseong-web-playtest/pull/4)·[모바일 PR #5](https://github.com/bluehige/mawangseong-mobile-playtest/pull/5)와 Pages 배포 성공, Chrome 공개 부팅 확인 |
| v0.5 모바일 전용 PCK 최적화 | `35abd218a5de01209b4eb4c88bfa7c297c8462d4` | 소스 [PR #31](https://github.com/bluehige/mawangseong-demo/pull/31), 모바일 [PR #4](https://github.com/bluehige/mawangseong-mobile-playtest/pull/4) 병합 완료. Noto 폰트·전투 스프라이트·일반 Web PCK를 유지하고 모바일 일러스트 134개만 품질 0.90 export하여 PCK를 231,477,848에서 149,196,724바이트로 축소 |
| v0.5 모바일 개선 소스 `main` 병합·공개 배포 | `c2400102ce3e1a88760bb944d50c28307419bb66` | 소스 PR #27·#28·[#29](https://github.com/bluehige/mawangseong-demo/pull/29) merge commit 통합 완료. Web `18a6fe1b4d125e19055d07211a4d9954b95c6b70`, 모바일 `4bf82851c6f24a1e12ad8a4b68b47066a66392d3`에서 Pages 배포 성공 |
| v0.5 모바일 터치 UI·가독성·튜토리얼 개선 | `f0c984b680b27c12c8bbf8586afa8c2f743b17ad` | 모바일 큰 터치 대상, 탭 공격·이동, 관리·전투 전용 조작 바, 이름 키보드 자동 재호출 제거, 1.35배 텍스트 확대, 필수 대상 사전 선택과 강조 링 전체 터치 액션 기준 |
| v0.5 Lyria 상황·스킬 오디오 확장 | `6eef61ad89730c7a3ae00e05172c873d88159570` | 선택 BGM·타격음 승격, 관리/일반전/보스전 3상태 음악, 직접 전투 스킬 24개 고유 cue와 출처·LFS·관련 테스트 기준 |
| v0.5 Lyria 3 오디오 파이프라인 | `63d1242624d3d0fff27b53c84fe286de4f372156` | 현재 WAV 50개 전체 매핑, 키 비노출 Interactions 생성·후보 렌더·승인 승격과 출처 기록 기준 |
| `codex/v05-steam-release-readiness` 구현 | `856440c525fec8d82ce5a10d7dc25e3e160cb31c` | Steam 상점·그래픽·Windows depot·SteamPipe·Cloud·출시 게이트 기반과 관련 검증 PASS 기준 |
| Steam 통합 검증 | `63d1242624d3d0fff27b53c84fe286de4f372156` | 진행 중 별도 세션의 오디오 도구 커밋을 보존한 상태에서 Steam clean worktree 빌드·실행을 다시 통과한 기준. 오디오 파이프라인 자체는 이번 검수 범위가 아님 |
| v0.2.3 검증·Web 빌드 소스 | `35b2913cf4d8dbdc1cb0230398b2722e4cd8dfc4` | Full 45/45와 canonical Git blob catalog provenance PASS 기준 |
| v0.2.3 `v.02` 병합 | `7ec0156d6e23197f3256ea13fb1d87e175b50b07` | PR #20으로 v0.2 유지보수 계보에 merge commit 통합 |
| v0.2.3 `main` 계보 기록 | `77d9ede3b5d687795b5157065c236d9cf30d33f1` | 현재 main 트리를 유지하면서 v0.2.3 태그 조상 관계를 기록 |
| v0.2.2 검증·Web 빌드 소스 | `c8b5a4684d8f55e33e9c4da4b7ea3fab3af7f077` | Full 45/45와 새 Release provenance·manifest PASS 기준 |
| v0.2.2 `v.02` 병합 | `94987042485c37ddd005c0eb84a3796f02a2aabf` | PR #18로 v0.2 유지보수 계보에 merge commit 통합 |
| v0.2.2 `main` 계보 기록 | `966b9dbbb900a6d60b23cd841f3a7e57d3656a8b` | 현재 main 트리를 유지하면서 v0.2.2 태그 조상 관계를 기록 |
| v0.2.1 검증 소스 | `3b1a0edd6b0389f7be8b4c88fe8ca45046d623b3` | v0.2 입력 레이어 핫픽스와 Full 45/45 PASS 기준 |
| v0.2.1 `v.02` 병합 | `312a649afa5c379101194b23cddcfeec4ecf3815` | PR #16으로 v0.2 유지보수 계보에 merge commit 통합 |
| v0.2.1 `main` 계보 기록 | `77423e73717c03c3beb9d0aa2377a6436a1d4d33` | v0.4 소스 트리를 유지하면서 v0.2.1 태그 조상 관계만 기록 |
| UI 입력 레이어 `main` 병합 | `592b3a434fde5196d22ee1269e9009d667517264` | PR [#14](https://github.com/bluehige/mawangseong-demo/pull/14)를 merge commit 방식으로 통합 |
| `codex/v04-input-layer-guard` 구현 | `af361d5c64b24e94896a6d31845d0e9fa6e4bda0` | UI 입력 레이어 방어 구현과 직접 영향 테스트 기준 |
| `origin/main` v0.4 병합 | `a8b29e6ee176b96b0f910beb2d5cbf07dc2c4767` | PR #13으로 v0.4 개발본을 merge commit 방식으로 통합한 최신 안정 기준 |
| `codex/v04-sequential-development` 검수 SHA | `51b401fad9d16584a00674e48afdc83bb6219473` | v0.4 Phase 0~36 기능·데이터·자산, 이미지 출처 정책과 최종 버그 테스트 기준 |
| `origin/release/v0.4` | `c0b9534` | PR #12로 v0.4 개발본을 통합한 릴리스 브랜치 기준 |
| `v0.3.0` / PR #10 merge | `ba661015e4bc5be6fec1aa470c5f48d565422597` | v0.3 최종 소스와 최신 튜토리얼 버그픽스를 고정한 정식 태그 |
| `codex/v03-sequential-finalize` 검수 SHA | `0dae916a5354f3df119bae6115c754fc12e1b094` | 전야 마감과 최신 튜토리얼 버그픽스를 함께 검증한 v0.3 소스 |
| `origin/main` v0.3 병합 | `ba661015e4bc5be6fec1aa470c5f48d565422597` | PR #10을 merge commit 방식으로 통합한 안정 기준 |
| 최신 튜토리얼 구현 | `91acdec6ec00c65a438cba9f6cf88e0cfa829744` | 적 우클릭 판정 버그픽스, 위 검수 SHA에 포함 |
| `release/v0.3` | `af34cad42634759088114043760abafad5c3e94a` | 기존 v0.3 통합 계보 |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |

## 구 v0.5 기획 묶음(제품 4.0 대응) PC·모바일 성능 수정 상태

- 공개 테스트판의 느림은 모바일만의 문제가 아니었다. PC Web도 보이지 않는 전체 던전을 계속 그려 타이틀이 약 35.54fps, 프레임당 약 5,631 draw 호출이었다.
- 비월드 화면 렌더 차단, 플랫폼별 던전 품질, 전투 redraw 제한, Web BGM streaming을 적용했다. Windows native는 full 품질, PC Web은 balanced 품질, 모바일 Web은 추가 경량화와 CSS 픽셀 백버퍼를 사용한다.
- 실제 브라우저 계측에서 PC Web과 모바일 DPR 3의 타이틀·관리 화면이 모두 60fps를 유지했다. 모바일 관리 draw 호출은 약 1,304회/프레임, 백버퍼는 844×390이다.
- 모바일 일러스트는 export 시 1280px 상한을 추가해 PCK를 146,803,604바이트로 줄였다. PC Web 231,378,276바이트와 함께 각 테스트 저장소 `main`·Pages에 배포했다.
- 공개 [PC Web](https://bluehige.github.io/mawangseong-web-playtest/)과 [모바일 Web](https://bluehige.github.io/mawangseong-mobile-playtest/)은 workflow의 PCK·WASM·필수 오디오 검증을 통과했고 Chrome에서 타이틀 화면까지 실제 부팅했다.
- STOVE 배포는 사용자의 지시대로 수행하지 않았다.
- 관련 Godot/Python 테스트와 PC·모바일 브라우저 렌더는 `TARGETED_PASS`다. 전체 회귀·전체 플레이·검수 에이전트는 요청되지 않았다.

## Lyria 3 오디오 교체 준비 상태

- 사용자 선택에 따라 전투 BGM Take 1과 기본 타격음 Take 2를 런타임에 승격했다.
- 관리 화면, 일반 전투, 보스 전투의 세 음악 상태를 연결했다. 보스 등장 시 보스곡으로, 보스 격퇴 후 잔여 전투가 있으면 일반 전투곡으로 돌아간다.
- 코어·update3의 직접 전투 스킬 24개에 각각 다른 Lyria WAV를 연결했다. 발동음은 고유 재질·동작/마력·음조 확인 레이어를 가지며 기존 공격·피격 레이어와 함께 재생된다.
- 현재 매니페스트는 런타임 WAV 76개를 `lyria-3-clip-preview` 73개, `lyria-3-pro-preview` 3개로 관리한다. 승격한 28개 자산의 원본·프롬프트·해시는 `assets/source/audio/lyria/v0.5/`에 보존한다.
- 이번 확장 호출은 Clip 24회와 Pro 2회, 예상 USD 1.12이며 최초 후보까지 포함한 누적 예상 요청 비용은 USD 1.36이다. API 키 패턴은 관련 저장소 파일 0건이다.
- 자동 검증은 24개 스킬·3개 음악의 고유 파일, 형식, 비무음과 상황 전환을 통과했다. 실제 플레이의 최종 음량·반복 피로 청취와 기존 보조 cue 48개의 Lyria 재생성은 후속 선택 사항이다.
- 제공된 키는 채팅에 직접 노출됐으므로 즉시 폐기하고 새 키를 발급해야 한다.

## Steam 판매 출시 준비 상태

- Windows 64-bit 유료 정식판, Coming Soon 뒤 Demo, Steam Auto-Cloud를 사용하는 최소 출시 구조를 정했다.
- Steam 상점 문구·콘텐츠 및 사전 생성형 AI 설문 초안, 필수 규격 그래픽, 실제 플레이 스크린샷 6장을 준비했다.
- Godot `Windows Steam` export, 라이선스·해시 매니페스트 포함 depot 생성, SteamPipe 업로드, 태그 artifact CI를 구현했다.
- 통합 SHA `63d1242`의 깨끗한 detached worktree에서 Godot 4.5.2 초기 임포트부터 Windows 패키지 생성까지 PASS했고, 패키지 실행 exit 0·ERROR 0을 확인했다.
- 출시 validator는 기반 설정을 통과하며 App/Depot ID, 공개 연락처, 사용자 승인, 실기기 검수와 Valve 심사를 포함한 외부 항목 17개를 의도적으로 차단한다.
- 사용자 작업의 단일 체크리스트는 `docs/release/OWNER_ACTIONS.md`, 전체 일정과 역할은 `docs/release/STEAM_RELEASE_MASTER_PLAN.md`를 따른다.
- 현재 판매 가능 상태는 아니다. Steamworks 가입·계약·등록비·세금/은행 검증을 가장 먼저 완료해야 한다.

## 구 v0.4 기획 묶음(제품 3.0 대응) 개발 완료 상태

- v0.4 Phase 0~36을 계획 순서대로 구현하고 의회 회차 DAY 1~30 실제 진행 경로를 완성했다.
- 최신 `main`의 v0.3 튜토리얼 적 클릭 버그픽스 `91acdec6`를 포함한다.
- Phase별 관련 자동 테스트 36종, Phase 36 통합 285 assertions, 튜토리얼과 데모 스모크가 PASS다.
- 의결·왕관·최종 선언 UI는 1920×1080과 1366×768에서 확인했다.
- 그래픽은 GPT 내부 생성 도구로 만들고 `assets/source/imagegen/` 원본과 런타임 자산을 분리했다.
- PR #12와 #13으로 `release/v0.4` 및 `main` 통합을 완료했으며 정식 `v0.4.0` 태그는 후속 버그픽스 이후 만든다.
- PR #14로 표시 전용 UI 레이어의 클릭 차단을 방지하고 35개 입력 계약 단언을 추가했다.
- v0.2.3 입력 레이어 핫픽스 Web Release와 Pages 배포를 완료하고 공개 화면의 v0.2.3 표기와 클릭 전환을 확인했다.

## 검수 정책 필드

- Review task ID: FULL_RELEASE_VERIFICATION_2026-07-20_V121
- Reviewed SHA: c483d135b13cf9771ee43b045ba2c3dde51573ee
- Review range: 25a41a4f08925e35592aca890e0c56a75c5203f9..c483d135b13cf9771ee43b045ba2c3dde51573ee
- Remaining P1/P2: 0
- Final review result: PASS

## 다음 작업 순서

1. `v1.2.1` 태그와 Release 자산은 이동·교체하지 않는다. Actions run 29729582970의 오디오 누락 artifact도 계속 사용하지 않는다.
2. 이슈 #39의 마지막 수동 항목인 Windows 물리 한/영 키 조합 중 상태를 실기 확인한다.
3. 실제 Android/iOS 안전 영역과 저사양 PC·모바일에서 타이틀·관리·전투 10분 발열/메모리를 선택 검수한다.
4. 사용자 피드백에서 남는 병목이 있으면 해당 플랫폼 프로필만 조정하고 PC·모바일 Pages를 다시 배포한다.
5. 채팅에 노출된 API 키를 즉시 폐기한다. 나머지 보조 cue 48개를 Lyria로 바꿀 때는 새 키를 가려진 입력으로 사용하고 단계별 청취·승격한다.
6. 실제 전투에서 스킬 24개와 관리·일반전·보스전 BGM의 음량·타이밍·반복 피로를 청취하고 필요한 자산만 재테이크 또는 dB 조정한다.
7. 사용자가 `docs/release/OWNER_ACTIONS.md`에 따라 Steamworks 계약 주체, NDA/SDA, $100 App Credit, 신원·세금·은행 검증을 완료한다.
8. 공개 App/Depot ID, 개발자·퍼블리셔명, 지원 이메일/사이트, 최종 게임명, 가격 방향과 목표 출시일을 받아 설정·개인정보 처리방침·스토어 placeholder를 채운다.
9. 권리·한국 의무·콘텐츠/AI 설문·스토어를 승인하고 Coming Soon을 제출한 뒤 Steam 설치·Cloud·Valve 심사를 진행한다.

## 아직 하지 않은 작업

- Windows 네이티브 Microsoft 한국어 IME의 물리 한/영 키 조합 중 상태 검수(확정 한글 입력·수정·화면 전환은 확인)
- 실제 Android/iOS의 지시 HUD·확대 글꼴 실기 검수(PC Web은 확인)
- v0.5 플랫폼 성능 수정의 실제 Android/iOS·저사양 PC 장시간 발열/메모리 검수
- Steamworks 가입·계약·등록비·세금/은행 검증과 App/Depot ID 발급
- Steamworks 포털 입력, SteamPipe 업로드, 두 PC Cloud 및 설치 검수, Valve 스토어·빌드 승인
- Coming Soon 최소 14일과 정식 Steam 출시
- 정식 `v0.4.0` 태그와 해당 출시 빌드
- Lyria 3 확장 자산의 실제 플레이 믹스 청취와 나머지 기존 보조 cue 48개 후보 생성·승격
- 제품 4.0 이후 확장 개발과 구 `v0.6` 기획 묶음의 제품 출시 번호 확정
