# 제품 버전 체계

최종 갱신: 2026-10-15

이 문서는 2026-07-16 이후 새로 만드는 프로젝트 표기, 브랜치, 태그, 빌드와 릴리스의 단일 버전 기준이다.

## 현재 제품 계보

| 의미 | 화면·문서 표시 | 프로젝트 SemVer | Git 태그 |
|---|---:|---:|---:|
| 최초 출시 기준 | 1.0 | 1.0.0 | `v1.0.0` |
| 첫 수정판 | 1.1 | 1.1.0 | `v1.1.0` |
| 1.2 최초 출시 | 1.2 | 1.2.0 | `v1.2.0` |
| 1.2 안정화 패치 | 1.2 | 1.2.1 | `v1.2.1` |
| 2.0 검증 결과 선별 통합 패치 | 1.2 | 1.2.2 | `v1.2.2` |
| 출시 증빙 정규화 패치 | 1.2 | 1.2.3 | `v1.2.3` |
| 긴급 플레이 버그 수정 | 1.2 | 1.2.4 | `v1.2.4` |
| 그래픽·스토리·결산 완성도 패치 | 1.2 | 1.2.5 | `v1.2.5` |
| 전투 지휘·AI·관리 UX 신뢰성 패치 | 1.2 | 1.2.6 | `v1.2.6` |
| UI·UX 전면 개선·준비된 미궁 품질 패치 | 1.2 | 1.2.7 | `v1.2.7` |
| 첫 확장판 | 2.0 | 2.0.0 | `v2.0.0` |
| 두 번째 확장판 | 3.0 | 3.0.0 | `v3.0.0` |
| 세 번째 확장판 | 4.0 | 4.0.0 | `v4.0.0` |

## 2026-10-15 사용자 확정

2026-10-15 00:08 KST, 사용자가 [콘텐츠 대응표](design/CONTENT_VERSION_MAP_2026-10-14.md)의 선택지 1을 채택했다. 위 계보 표와 아래 기존 기록은 삭제하지 않고 이력으로 보존한다. 버전·출시 계획이 충돌하면 이 결정이 우선하며, 구 `2.0/3.0/4.0` 확장판 번호 체계를 대체한다.

| 구분 | 제품 버전 | 확정 내용·상태 |
|---|---|---|
| 준비된 유지보수판 | `1.2.12` | 준비됨 / 미업로드 |
| 다음 출시 | `1.3.0` | UI 개편 + 1층 자유 배치 맵 개편 + 의회 2층→1층 부지 확장 전환. 1.x 패치 라인 |
| 다음 DLC | `1.5.0` (화면 1.5) | v0.5 「연맹 주간과 일곱 밤」 기획 |
| v0.6 이후 | 미정 | 제품 버전 추후 결정 |

- 이미 공개된 전선 연대기(`v0.3`)·마왕 의회 회차(`v0.4`)는 **본편의 완주 후 회차**로 인정한다. 별도 DLC로 재분리하지 않는다.
- 내부 작업명은 제품 2.0과 혼동되지 않도록 **맵 개편(map overhaul)**으로 부르며, 제품 버전은 **1.3.0**, 브랜치는 `codex/v130-map-overhaul`이다.
- 이 기록은 버전·콘텐츠 경계 결정이며, 업로드·구현·배포 완료를 뜻하지 않는다.

### 1.3.0 빌드 준비 — 2026-10-15 09:33 사용자 확정

- 전투 수치·성장 자격·장식의 비전투 역할을 유지한다. 성 승격 금화 720·악명 720은 보유 조건이며 차감하지 않는다는 안내를 세 언어로 명확히 한다.
- 프로젝트·게임 내 버전/공지/manifest는 1.3.0, Windows 파일·제품 버전은 1.3.0.0으로 갱신한다. 이번 지시는 기존 두 자리 화면 표시 관례보다 우선한다.
- `codex/v130-map-overhaul`에서 영어 로컬 커밋과 `Windows Steam` export·웹 업로드용 ZIP까지만 준비한다. push·merge·태그·Steam 업로드/Commit/default 전환·공지 게시를 수행하지 않는다. manifest의 의도한 `v1.3.0`은 태그 생성 증거가 아니며 `tag_state=not_created`를 기록한다.
- 보류한 재설계·미술·장기 검증은 [1.5.0 DLC 백로그](design/plans/V150_DLC_BACKLOG_2026-10-15.md)에 모은다. 빌드 준비 결과와 미해결 BGM 상태는 [출시 빌드 인계](handoff/V130_RELEASE_BUILD_2026-10-15.md)에 기록한다.

### 이전 버전 체계 기록 (위 결정 우선)

- 사용자에게 보이는 버전은 `1.2`, `2.0`처럼 두 자리로 표시한다.
- Godot 프로젝트, Windows 파일 버전, manifest와 Git 태그는 SemVer에 맞춰 `1.2.1`, `2.0.0`처럼 세 자리로 기록한다.
- `1.1`과 `1.2`는 1.0 출시선의 수정판이다. 콘텐츠 확장판 번호로 해석하지 않는다.
- `2.0`, `3.0`, `4.0`은 순서대로 다음 확장 출시선이다.

## 1.2.2 선별 통합 계약

- `1.2.2`는 `1.2.1`의 DAY 1~30 제품 구조, 건물 ID·오브젝트, 해금·업그레이드, 성장, 저장과 플랫폼을 보존하는 패치다.
- 기존 `release/v2.0`의 DAY 1~5 결과는 정식 `2.0` 제품 소스가 아니라 전투·배치·밸런스 행동의 참고 기준이다. U1~U5 결과도 UI 행동과 정보 구조의 참고 기준으로만 사용한다.
- `release/v2.0` 또는 관련 커밋 범위를 병합·cherry-pick하지 않는다. `1.2.1` 구조 안에 필요한 규칙만 adapter 방식으로 구현한다.
- 기존 `release/v2.0-product` 또는 `v2.0.0` 이식 지시는 `docs/design/v122/V122_V20_VALIDATED_TRANSPLANT_PLAN.md`가 대체한다.
- `1.2.2` 기능 통합은 완료됐으며 정식 `2.0` 확장 작업은 후속 증빙 패치 `1.2.3`까지 `main`에 돌아온 뒤 최신 `main`에서 다시 시작한다.

## 1.2.3 출시 증빙 정규화 계약

- `1.2.3`은 `1.2.2`의 게임 기능, 저장 호환성과 화면 표시 `1.2`를 그대로 유지한다.
- 정식 검증 카탈로그는 운영체제와 무관하게 LF로 체크아웃하며 Full 보고서는 현재 커밋의 Git blob SHA-256을 기록한다.
- 공개된 `v1.2.2` 태그와 Release 자산은 감사 기록으로 보존하고 이동·삭제·교체하지 않는다.
- 정식 `2.0` 확장 작업은 `1.2.3` 출시 완료 뒤 최신 `main`에서 새로 시작한다.

## 1.2.4~1.2.6 유지보수 계약

- `1.2.4`는 몬스터 배치 깊이, 집결·집중 입력과 도둑 추격 등 출시 직후 플레이 차단 버그를 고친 긴급 패치다.
- `1.2.5`는 Stage 02~04 전용 공간 그래픽, 패배 시 자원·성장 롤백, DAY 29 결전 전야 대사 흐름, 결과·전투 HUD 가독성을 완성하는 품질 패치다.
- `1.2.6`은 명령 수락·거부 피드백과 0.3초 우선 반응, 역할 AI·방별 지침의 행동/표시 일치, 건설 슬롯 미리보기·확정, 방 이름표 가독성을 보강하는 품질 패치다.
- 세 패치는 화면 표시 `1.2`와 기존 저장 경로·저장 형식을 유지하며, 이전 `v1.2.*` 태그와 Release를 이동하거나 덮어쓰지 않는다.
- 정식 `2.0` 확장 작업은 `1.2.6` 출시 완료 뒤 최신 `main`에서 새로 시작한다.

## 구 버전 표기와의 관계

2026-07-16 이전 저장소에는 `v0.2`, `v0.3`, `v0.4`, `v0.5`, `v0.6`이 출시 버전과 기획 묶음 이름으로 혼용됐다. 새 제품 버전은 다음 기준으로 읽는다.

| 구 표기 | 새 제품 계보에서의 의미 |
|---|---|
| `v0.2` 출시 기준 | `1.0` 출시 기준 |
| `v0.2.1` 수정 | `1.1` 수정판에 대응하는 과거 작업 기록 |
| 현재 지시 전용 전투·UI·입력 수정 | `1.2` 현재 수정판 |
| `v0.3` 확장 기획 묶음 | `2.0` 확장판 기획 원본 |
| `v0.4` 확장 기획 묶음 | `3.0` 확장판 기획 원본 |
| `v0.5` 확장 기획 묶음 | `4.0` 확장판 기획 원본 |
| `v0.6` 기획 묶음 | 역사적 기획 원본이며 제품 출시 번호는 추후 결정 |

기존 `v0.2.0`~`v0.3.0` 태그, GitHub Release, `v.02`·`v.03` 브랜치와 날짜별 핸드오프는 공개·감사 기록이므로 삭제하거나 이동하거나 이름을 바꾸지 않는다. 새 빌드와 릴리스는 기존 `v0.*` 태그를 재사용하지 않는다.

## 브랜치와 빌드 이름

- 현재 공개 유지보수 기준: `v1.2.6@1f36c8a775b471c4dbc7c7714f85f33efb00876d`가 포함된 최신 공개 `main`
- 현재 출시 후보: 없음 — `v1.2.6` 출시 완료
- 다음 구현·검수: 새 사용자 지시를 받은 뒤 최신 `main`에서 별도 브랜치·worktree 생성
- 기존 `release/v2.0`: DAY 1~5 검증 참고선, 제품 통합 대상 아님
- 다음 정식 확장 통합: `1.2.6` 출시 뒤 최신 `main`에서 새로 시작하는 `release/v2.0`, 이후 `release/v3.0`, `release/v4.0`
- 출시 빌드 예: `mawangseong-v1.2.6-web.zip`, `MawangCastle-v1.2.6-Windows.zip`

정확한 출시 스냅샷은 `main` 병합 뒤 이동하지 않는 주석 태그로 고정한다. 이미 존재하는 이름의 태그를 새 커밋으로 재지정하지 않는다.

## 1.2.7 출시 후보 — 2026-09-14 사용자 확정

- 사용자가 이번 UIUX 개선판의 정식 출시 번호를1.2.7로 확정했다. 화면 표시1.2, 프로젝트·Windows 파일·manifest·태그1.2.7을 사용한다.
- 검증된 codex/v126-uiux-u0-u3 내용을 최신main에서 시작한 codex/v127-uiux-release에 통합한다. 과거v20실험 브랜치는 병합하지 않는다.
- 현재 캐릭터 그림 유지, 방향별 미술은 사용자 승인 후속. 기존v1.2.6과 이전 출시 태그는 이동하거나 덮어쓰지 않는다.
- 준비된 미궁·건물 배치·UI 조작 개선을 포함하며 비용·보상·스토리·기존 저장 호환을 보존한다. Steam 업로드는 사용자가 수행한다.

## 1.2.8 한국어·영어 지원 — 2026-09-21 사용자 확정

- 사용자가 전체 영어화 Steam 배포본의 버전을 1.2.8로 확정했다.
- DAY 1~30 전체 대사, UI 및 영어 상점 자산을 포함한다. 게임 내 설정에서 한국어와 영어를 선택한다.
- 화면 표시 1.2, 프로젝트·Windows·manifest·불변 태그는 1.2.8이다.
- 기존 저장 형식과 경로 및 모든 기존 출시 태그·Release는 보존한다.

## 1.2.9 Steam 심사 입력 수정 — 2026-09-22

- Build 25423797의 시설 드래그·몬스터 배치·방어 진행 차단을 수정하는 1.2.8 유지보수판이다.
- 프로젝트·Windows·manifest·불변 태그는 1.2.9로 구분하고 기존 v1.2.8과 배포 파일은 보존한다.

## 1.2.10 간체 Steam 업데이트 — 2026-10-07

- 사용자가 새 SemVer `1.2.10`을 확정했다. `1.2` 표시 체계와 저장 경로는 유지한다.
- project·Windows export·manifest·새 불변 태그를 1.2.10으로 일치시킨다. 기존 v1.2.9@4076e099202f440c85a30699268d1c887c26c903 및 출시 파일은 보존한다.
- 기존 main@b06be967aa763199ac631729eb65cacbe9489c26의 간체 추가와 관련 표적 검증을 기반으로 한다. 새 전체 30일·원어민 교정·Steam 설치·2PC Cloud 완료를 주장하지 않는다.

## 1.2.11 continuity maintenance patch — 2026-10-11 user decision

- The user selected 1.2.11 for caption continuity, checkpoint/menu safety, read-only backlog, offline update notes, promotion feedback and remembered-speed improvements. This is a compatible patch, not an expansion or save-format change.
- Parent live Steamworks read: public Build25808943, description v1.2.10 same-version hotfix, source515ed745d4ce731f7bafb31ee1f9381470794d72. This commit is an ancestor of the review branch. Public deployment timestamps were displayed as October8 9:24am/9:42am; timezone unverified. The local agent did not independently read that web page.
- Project and installed-version labels use 1.2.11; Windows file/product versions use 1.2.11.0. New exports and review manifests identify 1.2.11. Prior 1.2.10 history, tags and binaries remain unchanged. The latest user request takes precedence over the older two-component display convention.
- App5267750 and the existing custom user-data path, five campaign format versions and custom-layout filename stay unchanged. No new Cloud button/SDK or account-isolated save migration.
- No public game deployment, push, merge, release tag or GitHub Release is performed by this local version-update task. Real two-PC Auto-Cloud and full human campaign tests remain separate verification gates.

## 1.2.12 skill, growth and save maintenance patch — 2026-10-13

- User authorized publishing the completed maintenance changes and a higher patch version after directly verifying the currently public build.
- Fresh official SteamCMD anonymous app-info read: public Build25870353, Depot5267751 manifest5824439082666467035. Both identifiers exactly match the recorded immutable 1.2.11 public deployment; 1.2.12 is the next maintenance patch.
- Product behavior is based on reviewed 2dfbaeea2e28b4d8d04631689eee24c9ef7b0800. This release preparation changes version metadata and KO/EN/ZH offline patch notes only; existing passing skill/growth/save evidence is retained by impact scope.
- Project/update identifiers use 1.2.12; Windows file/product metadata use 1.2.12.0. The next source commit is frozen before export.
- No change to App5267750, Depot5267751, user-data directory, save-format filenames or Cloud configuration.
- No immutable Git tag is claimed created. A build manifest's v1.2.12 field records the intended release label, with explicit tag_state=not_created. Upload/default/announcement status is recorded separately in the handoff. Remote Git integration and two-PC Steam Cloud validation are not part of this local upload preparation.
