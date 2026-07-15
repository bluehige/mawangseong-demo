# 현재 작업 핸드오프

최종 갱신: 2026-07-15

이 파일은 다음 세션의 단일 진입점이다.

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

## 현재 계보

| 브랜치·커밋 | SHA | 의미 |
|---|---|---|
| v0.5 모바일 터치 UI 개선 | `01ad524f9f0896448a5344b984fda6595326478b` | 모바일 큰 터치 대상, 탭 공격·이동, 관리·전투 전용 조작 바, 이름 키보드 자동 재호출 제거와 관련 테스트 기준 |
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

## v0.4 개발 완료 상태

- v0.4 Phase 0~36을 계획 순서대로 구현하고 의회 회차 DAY 1~30 실제 진행 경로를 완성했다.
- 최신 `main`의 v0.3 튜토리얼 적 클릭 버그픽스 `91acdec6`를 포함한다.
- Phase별 관련 자동 테스트 36종, Phase 36 통합 285 assertions, 튜토리얼과 데모 스모크가 PASS다.
- 의결·왕관·최종 선언 UI는 1920×1080과 1366×768에서 확인했다.
- 그래픽은 GPT 내부 생성 도구로 만들고 `assets/source/imagegen/` 원본과 런타임 자산을 분리했다.
- PR #12와 #13으로 `release/v0.4` 및 `main` 통합을 완료했으며 정식 `v0.4.0` 태그는 후속 버그픽스 이후 만든다.
- PR #14로 표시 전용 UI 레이어의 클릭 차단을 방지하고 35개 입력 계약 단언을 추가했다.
- v0.2.3 입력 레이어 핫픽스 Web Release와 Pages 배포를 완료하고 공개 화면의 v0.2.3 표기와 클릭 전환을 확인했다.

## 검수 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 01ad524f9f0896448a5344b984fda6595326478b
- Review range: 0390ebe1866101a65db97fe18fd22321a08523ea..01ad524f9f0896448a5344b984fda6595326478b
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 다음 작업 순서

1. 모바일 터치 UI PR을 `main`에 병합하고 Web·모바일 공개 플레이테스트 Pages를 최종 `main` 빌드로 갱신한다.
2. 실제 전투에서 스킬 24개와 관리·일반전·보스전 BGM의 음량·타이밍·반복 피로를 청취하고 필요한 자산만 재테이크 또는 dB 조정한다.
3. 채팅에 노출된 API 키를 즉시 폐기한다. 나머지 보조 cue 48개를 Lyria로 바꿀 때는 새 키를 가려진 입력으로 사용하고 단계별 청취·승격한다.
4. 사용자가 `docs/release/OWNER_ACTIONS.md`에 따라 Steamworks 계약 주체, NDA/SDA, $100 App Credit, 신원·세금·은행 검증을 완료한다.
5. 공개 App/Depot ID, 개발자·퍼블리셔명, 지원 이메일/사이트, 최종 게임명, 가격 방향과 목표 출시일을 받아 설정·개인정보 처리방침·스토어 placeholder를 채운다.
6. 권리·한국 의무·콘텐츠/AI 설문·스토어를 승인하고 Coming Soon을 제출한 뒤 Steam 설치·Cloud·Valve 심사를 진행한다.

## 아직 하지 않은 작업

- Steamworks 가입·계약·등록비·세금/은행 검증과 App/Depot ID 발급
- Steamworks 포털 입력, SteamPipe 업로드, 두 PC Cloud 및 설치 검수, Valve 스토어·빌드 승인
- Coming Soon 최소 14일과 정식 Steam 출시
- 정식 `v0.4.0` 태그와 해당 출시 빌드
- Lyria 3 확장 자산의 실제 플레이 믹스 청취와 나머지 기존 보조 cue 48개 후보 생성·승격
- v0.5 및 v0.6 순차 개발
