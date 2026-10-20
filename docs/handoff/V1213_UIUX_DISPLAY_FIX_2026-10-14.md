# V1213 병합 확인 및 D01~D09 표시 결함 수정

## 1. 메타데이터

- 작성일: 2026-10-14
- WORKSTREAM_ID: V1213-UIUX-D-FIX
- 목표 버전: 기존 제품 1.2.12 유지. v1213은 작업 이름이며 SemVer 변경 없음.
- 작업 브랜치: `codex/v1213-fix-plan` 유지
- 최초 기준 SHA: `c57400c104a995425138b39e8d2031e3ebf3109f`
- 구현 직전 HEAD: `f258253763845952fa80707442d63240087f987a`. 작업 중 다른 세션이 디자인 문서 2개만 추가했으며 제품 기준은 동일하다. 보존하고 변경하지 않았다.
- 마지막 구현·검증 커밋 SHA: `dcd5743efb1d25a25b5f7ce2bc02bd97996affef`
- 이후 커밋: 이 인계와 CURRENT만 기록하는 문서 커밋. 정확한 최종 HEAD는 Git 로그를 따른다.
- 원격 푸시/PR/태그/배포: 없음
- 권위 확인: 로컬 `main` 없음. 캐시 `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, `v1.2.5=f757ffa9f9e962158f2123856c8568a3163ecb6c`. `main:` 조회 실패를 보존하고 `origin/main:`의 AGENTS/CURRENT를 참고했다. 원격 최신성은 확정하지 않았고 fetch·브랜치 전환 없음. 현재 명시 사용자 지시를 실행 기준으로 사용했다.

## 2. 이번 세션 목표

- 병합 HEAD에서 기존 S1/S1 후속/S2 표적 검사 재실행.
- 감사 45eb925 이후 S2가 이미 해소한 표시 결함을 구분하고 D01~D09 잔여만 수정.
- 공통 글자 높이/행 공간, 터치 영역 충돌, 컷신 HUD 표시, 마스크, 지역 카드 경계 검증.
- 기존 감사 도구 재사용으로 29화면과 터치 대표 변형의 0줄 라벨/의도치 않은 형제 겹침을 자동 검사.
- 제외: 화면/정보 구조 개편·새 디자인, 게임 로직·밸런스, 전체 회귀·전체 플레이·검수 에이전트, 개인 세이브, push/공개 조치.

## 3. 완료한 작업

### 병합 확인

`c57400c`에서 `V1213StageOneTest` 41, `V1213S1FollowupTest` 131, `V1213StageTwoTest` 907개 모두 PASS. 자동 병합된 GameRoot/BuildingPlacementController의 실패 없음. 변경 뒤 동일 표적 검사도 모두 PASS.

### 감사 재측정과 조치

| ID | 병합 기준 재측정 | 조치 및 최종 결과 |
|---|---|---|
| D01 | 데스크톱 건설 팔레트의 시설 이름 0줄 미재현. S2에서 이미 라벨 높이 보완. | 기존 보완 유지. 공통 행 공간/최소 높이 검사에서 0줄 없음. |
| D02 | 데스크톱 동료 이름 및 훈련 제목 소실 미재현. | 성장 화면 개별 코드 변경0. 공통 규칙을 적용해 이름/제목 유지. |
| D03 | 터치 성장 `보유 기술`: font38, 높이52, 폰트 높이56, visible_lines0. 상단·스크롤 캡처에서 동일. 터치 raid의 DAY 적용/브리핑 제목도 각각 0줄. 이전 감사의 18개 전부가 남은 것은 아니다. | Container가 size를 다시 설정해도 custom_minimum_size로 1줄 높이 보장. 한국어 keep-font 우회 제거. 선호 크기를 행 공간 안에서 조정하되 하한18px 유지. 직접 생성 화면도 공통 규칙 연결. 최종 0줄0. |
| D04 | 터치 수비대 도크 y586~862와 탭 y730~810의 교차80px. 터치 건설 팔레트도 탭 끝과 18px 겹침. | 도크/팔레트는 탭 아래 y816~972 공간 사용. 콘텐츠 목록은 기존 스크롤 유지. 겹침0. |
| D05 | 터치 상세창이 배속/명령과 교차. 실제 유닛 상세·수동 기술 변형에서 관찰. | 헤더/닫기는 고정, 기존 본문과 수동 기술은 상세 내부 스크롤. 상세 끝 y648, 배속 시작654·명령 시작830. 실제 스크롤 하단 캡처 포함 교차0. |
| D06 | 기존 감사의 첫 보호 알림 `(56,176,790,136)`과 컷신 제목 `(205,190,1350,65)`가 교차하는 배치는 병합 코드에서도 동일. 초기 baseline 스윕에는 첫 보호 이벤트를 별도로 발동하지 않았으므로 이 전 측정은 소스 좌표 대조다. | 생산 `record_pudding_support()`로 알림 생성 후 컷신에서 숨김, 종료 때 원래 가시성 복구를 직접 검사. 효과 commit에서 새로 생긴 알림도 같은 tick 안에 숨김. 컷신/알림 교차0. |
| D07 | 데스크톱/터치 컷신에서 배속 패널이 남는 것을 baseline에서 확인. | 배속은 컷신 중 숨김·종료/중단 때 복구. 기존 메뉴/스킵 연결 유지. 교차0. |
| D08 | 마스크4개가 Obsidian 스타일로 패널 테두리/질감을 받음. | 공통 표면 생성기에서 비버튼 width0은 무테 StyleBoxFlat. 어두운 띠/투명 holder/그림자는 지정 색만 사용. 마스크 테두리0. 강조 링은 유지. |
| D09 | 첫 지역 인장 라벨 높이63/가시48(데스크톱), 터치 높이83/가시48. Label 자체 2줄 판정은 정상이어도 부모 카드에서 잘림. | 실제 라벨 끝+여백으로 카드 높이 계산, 다음 행 위치 조정. 터치는 이미 있던 긴 내용 스크롤 경로 재사용. 카드 경계 넘침0. 자연 해금은 검사 범위 밖. |

스캐너가 같은 범위에서 찾은 추가 행 충돌도 공통 맞춤으로 해소했다. 공지/예상 경로 패널은 실제 공지 끝 아래에 배치하고, 튜토리얼 배지는 설명창 위의 빈 공간을 우선해 설명을 덮지 않게 했다. 새로운 화면이나 정보 구조는 만들지 않았다.

- 데이터/스토리/밸런스/자산: 변경 없음.
- 저장/호환성: 개인 세이브 접근 없음. 모든 실행 전에 격리 APPDATA 사용. fixture만 프로세스 메모리 상태/감사 세이브 경로를 사용.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `scripts/ui/UIStandard.gd` | 공통 행 공간 및 직접 생성 라벨 맞춤 |
| `scripts/ui/HUDController.gd` | Container 최소 높이·터치 실제 버튼 영역·상세 스크롤 |
| `scripts/ui/ManagementWorkspaceUI.gd` | keep-font 우회 제거, 팔레트·예상 경로 간격 |
| `scripts/ui/UIUXTheme.gd` | 무테 표면, 로컬 탭 재구성의 공통 글자 맞춤 |
| `scripts/game/GameRoot.gd` | 공통 화면 글자 적용, 배지 빈 공간 후보·그림자 이름 |
| `scripts/game/ManagementSceneController.gd` | 터치 수비대 도크 공간 계약 |
| `scripts/ui/SkillActionPresentation.gd` | 컷신 HUD 숨김/원래 가시성 복구 |
| `scenes/ui/screens/RegionSelectionScreen.gd` | 카드 콘텐츠 높이와 기존 터치 스크롤 |
| `tools/ux_audit/Audit.gd` | 출력 경로 격리·글자 영역/부모/스타일 측정 확장 |
| `tools/ux_audit/Sweep.gd` | 29화면+변형 표시 fixture |
| `tools/ux_audit/Sweep.tscn` | 실행 진입점 |
| `tools/ux_audit/scan.py` | 형제/교차 레이어/0줄/카드/마스크 스캐너 |
| `tools/ux_audit/README.md` | 재실행 명령과 판정 경계 |
| `docs/plans/V1213_FIX_CHECKLIST_2026-10-14.md` | 진행 기록 |
| `docs/handoff/V1213_UIUX_DISPLAY_FIX_2026-10-14.md` | 본 인계 |
| `docs/handoff/CURRENT.md` | 짧은 세션 진입점 |

## 5. 그래픽 및 오디오 자산

새 생성/편집/자산 파일 변경 없음. 기존 실제 폰트·게임 화면으로 렌더했다. 캡처는 실제 viewport texture이며 OS 화면/물리 터치 기기 검증은 아니다.

## 6. 테스트 및 검수

Godot 4.6.3. 설치된 godot.cmd의 실제 경로 사용. APPDATA는 기존 검사 guard가 요구하는 `tmp/v1213_s1/`, `tmp/v1213_s1fu/`, `tmp/v1213_s2/` 또는 스윕 출력 폴더 안으로 격리했다.

| 검사 | 결과 | `tmp/v1213_uiux_fix/` 근거 |
|---|---|---|
| 병합 S1/S1 후속/S2 headless | PASS41/131/907 | `merge_s1.log`, `merge_s1fu.log`, `merge_s2.log` |
| 최종 S1/S1 후속/S2 headless | PASS41/131/907 | `verified_s1.log`, `verified_s1fu.log`, `verified_s2.log` |
| GUI `Sweep.tscn`, 1920×1080 | 29화면·변형49, fixture 실패0 | `verified_desktop_final.log`, `verified_desktop_final/` |
| 동일 `--mobile-touch-ui` | 29화면·변형50, fixture 실패0 | `verified_touch.log`, `verified_touch/` |
| `python tools/ux_audit/scan.py tmp/v1213_uiux_fix/verified_desktop_final tmp/v1213_uiux_fix/verified_touch` | exit0. 양쪽 0줄/의도치 않은 겹침/지역 넘침/마스크 테두리 모두0 | 각 `scan.json` |
| 보호 알림·배속 종료 후 복구 | 양쪽 fixture PASS | 각 `sweep_result.json`, `skill_action_with_support.png/json` |
| Pillow PNG 크기 검사 | 최종99개 모두1920×1080 | 각 `captures.json`의 PNG |
| 대표 직접 화면 확인 | 성장 전, 지역 후, 터치 상세 스크롤/컷신/튜토리얼 후 확인 | 위 PNG |
| `python -m py_compile tools/ux_audit/scan.py`, `git diff --check`, staged diff 검사 | PASS | 로컬 실행 |
| 전체 회귀/전체 플레이/별도 검수/새 export | NOT_REQUESTED/NOT_RUN | 요청 범위 유지 |

초기 하네스의 잘못된 설정 속성/Variant 타입 추론 오류, 미완성 행 충돌 후보는 수정하고 최종 완료 스윕으로 대체했다. 실패 로그를 삭제하지 않았다. 최종 두 GUI 스윕과 S1/S2에는 SCRIPT ERROR/ERROR 없음. S1 후속 headless 터치 에뮬레이션에는 `can_process: !is_inside_tree()` 로그7회가 baseline과 최종에 동일하게 있으며 검사 자체는131/0이다. 새 회귀로 분류하거나 오류0이라고 주장하지 않는다.

### 스캐너 판정 범위

모든 관찰 가능한 형제 Control 후보를 보존하고 실제 폰트 측정 영역으로 교차를 검사한다. 의도된 배경·완전 포함 시각 패널·투명 holder·빈 텍스트·스크롤바·임시 관리 상세 드로어·튜토리얼 강조/그림자·대화 프레임 접합은 이유와 함께 제외한다. 상세/배속/명령/컷신/보호 알림은 부모가 달라도 별도 계약으로 검사한다. 인장 조건은 보이는 줄뿐 아니라 부모 카드 경계도 검사한다. 전면 모달 뒤의 배경과 화면/스크롤 밖 텍스트는 표시 결함 집계에서 제외한다.

‘모든 화면 상태’는 이번 감사의29종 및 명시 변형99개 상태다. 모든 날짜/언어/영입 조합·자연 캠페인의 전수 검증이나 픽셀 OCR 증명은 아니다. S2 표적 검사의 기존 ko/en/zh_CN 검증은 별도로 유지했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: dcd5743efb1d25a25b5f7ce2bc02bd97996affef
- Review range: f258253763845952fa80707442d63240087f987a..dcd5743efb1d25a25b5f7ce2bc02bd97996affef
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

Reviewed SHA 이후에는 docs/handoff 문서만 변경했다. 별도 검수 에이전트 없음.

## 7. 미해결 항목과 위험

- 요청한 표시 fixture의 잔여 결함0. 기존 S1 후속 headless 입력 로그7회는 그대로 기록.
- 화면 개편·자연 후기 해금·물리 터치·전체 캠페인/재미·21:9·새 export·공개 배포는 수행하지 않았다.
- 이번 스캐너는 기하/Control 측정이며 임의 UI 조합의 디자인 품질을 판정하지 않는다.
- 로컬 main 부재/원격 최신성 미확정은 유지한다.

## 8. 다음 작업 순서

1. 헤드는 `dcd5743`의 표시 수정과 인계를 사용한다. 새로운 UI/UX 개편은 이미 추가된 별도 디자인 문서와 별도 승인 범위로 진행한다.
2. 이후 UI 변경 시 동일 스캐너와 관련 표적 검사를 재사용하고, 무테 마스크·최소 글자 높이·행 공간·컷신 HUD 복구 계약을 유지한다.
3. push/병합/태그/배포·전체 회귀는 새 지시 전 실행하지 않는다.

## 9. 작업 트리 상태

- 브랜치 전환·stash·다른 작업트리 수정 없음. 구현 writer 한 명, 하위 구현 에이전트 없음.
- 구현 커밋 뒤 잔여 기존 미추적: `docs/design/v1213_screens/`, `docs/design/v1213_uiux/kit/`, `docs/design/v20_map_builder/`. stage/수정하지 않았다.
- 작업 중 외부 문서 전용 f258253 보존.
- 캡처/격리 세이브/실패·최종 로그는 `tmp/v1213_uiux_fix/` 및 기존 검사별 tmp 폴더에만 보관, 커밋 제외.
- 관련 파일만 명시적 git add, 영어 로컬 커밋. push 없음.

## 10. 종료 체크리스트

- [x] 병합 확인 및 D01~D09 대조
- [x] 공통 계층 중심 구현과 범위 밖 변경 배제
- [x] 관련 검사41/131/907 PASS
- [x] 실제1920×1080 전후 캡처/격리 APPDATA
- [x] 29화면×2 및 변형99개, 스캐너0/0
- [x] 기존 로그와 하네스 제한 구분
- [x] 체크리스트 진행 기록 및 CURRENT 갱신
- [x] 검증 구현 SHA 기록, 이후 인계 문서만 변경
- [x] 관련 파일만 로컬 커밋, 기존 미추적 보존, push 없음
