# V130R Step3 — 개체별 몬스터 배치, 사용자 확인 대기

## 1. 메타데이터

- 작성일: 2026-10-16 KST
- WORKSTREAM_ID: V130R_STEP3_PLACEMENT
- 목표 버전: 1.3.0 별도 안전 미리보기
- 작업 브랜치: `codex/v130r-defense-layout`
- 기준 SHA: `b1297e02e431d3b8e9c4209bbd88ef28b605670e` (0088 문서; 구현 `7edacee99619bb0e757f174da4fd1f2893c9d88c`)
- 마지막 구현·검증 SHA: `6ca4c895b121a50b58ae15c1c729c9aeccda6fd4`
- 영어 로컬 커밋: `Add individual monster defense placement preview and isolated saves`
- 이 인계/CURRENT만 후속 영어 로컬 문서 커밋. 최종 문서 SHA는 `git log -1`로 확인한다.
- 원격 조회/fetch·push·merge·PR·태그·Steam 미실행.
- 권위 제한: 로컬 `main` 없음. 캐시 `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, `v1.2.5=f757ffa9f9e962158f2123856c8568a3163ecb6c`. 캐시 AGENTS/CURRENT를 읽었으나 원격 최신 권위 미확정. 사용자 지정 브랜치·기준을 따른다.
- 기준 자료: 외부 `_mockup/ui_icons_v1/ui_preview_place.png`, `_mockup/plan/ui2_2_place.png`, `_design/monsters_v130r/MONSTER_DESIGN_v130r_v1.md`와 기존 데이터. 지정 `_design`에는 몬스터 MD/JSON만 있어 설계서3-3 원문은 찾지 못했다.

## 2. 이번 세션 목표

- 건설↔몬스터 배치 전환, 기존 14개체 카드·잠금, 수비 칸 드래그·교체·해제, 인접 정보창, 자동/전부 해제, 유지비·경고, 격리 시험 저장과 재열기.
- 요청1920×1080 실제 게임 캡처6장·비교 이미지·다른 점 표, 정원/교체/해제/저장 자동 검사.
- 제외: 사용자 세이브 변경, 본편 합류·전투·정산 연결, 전체 회귀·전체 플레이·별도 검수 에이전트, export·배포·원격 변경.

## 3. 구현 사항 — 사용자 확인 대기

- 상단 건설/배치 탭은 실제 클릭 전환. 전투 탭 비활성. 배치 중 건물 클릭이 건설 원형 메뉴를 열지 않으며, 건설 복귀 뒤 기존5개 메뉴 유지.
- 하단 건설 바 대신14개체 명단. GPT 초상화·역할 그림·식량 그림/숫자·실제 데이터 초기 Lv1, 개체 ID당 최대1배치. 기본4명 해금, 나머지 잠금. `--unlock-all` 시험 플래그로 전체 해금하며 계약자를 날짜로 자동 합류시키지 않는다.
- 기존 시각 샘플 슬라임/고블린을 제거하고 실제 배치 개체만 표시. `UIUXActorArt.frame`의16프레임 atlas 영역/여백과 대기0프레임을 사용, 최대76×88 월드픽셀로 한 칸에 배치. 좌우 반전으로 입구를 향한다.
- 카드/서 있는 개체를 끄는 동안 빈 수비 칸은0084 GPT 하이라이트 청록, 인접 정원 밖 후보 칸은 붉게. 붉은 칸은 거절하고 원위치 유지. 배치된 개체 위에 놓으면 교체, 명단에서 교체하면 밀린 개체는 대기, 일반 지도 밖/명단 쪽으로 끌면 해제. 실제 정원 밖 인덱스는 모델에서 거절한다.
- 개체 클릭 시 바로 옆 GPT 패널. 이름·역할·체력/공격/방어·실제 기술2~3개·한 줄 설명(긴 설명 말줄임/툴팁)·유지비·해제/닫기 그림.3기술은 패널 높이 확장, 하단 명단을 피하며 카메라 이동 때 개체 위치를 따라간다.
- 자동 배치는 탱커/원거리/회복/미끼 대표를 먼저 확보하고 나머지는 기존 명단 순서. 탱커 병영 앞줄, 원거리 감시탑/후열, 회복 둥지 지원형, 미끼 보물실 유인형 우선. 정원/일일 수입 안에서만 선택한다. 전원 해금 기준11명·22/일.
- 유지비는 푸딩/곱/핀/로로1, 모리/두둠/베베/포포/실키2, 돌콩/미미/루미/코코/톡톡3. 현재 식량18과 `−합계/일` 표시. E등급 기획 수입23/일 초과도 수동 배치 허용, GPT 경고+굶주림 위험.14명29/일 경고 캡처. 식량 실제 차감·굶주림 효과는0095에서 연결한다.
- `tmp/v130r_step3/copies/placement_test.json`에 건물 상태+개체별 건물ID/슬롯 저장, 다음 실행 때 복원. 기존 step2 시험 파일은 읽기만 하며 모든 변경은 새 step3 복사본에 쓴다. JSON 숫자형은 복원 시 정수 정규화.
- 스토리·캠페인 데이터·개체 기본 능력치·본편 저장 형식 변경 없음. 로로 배치 가능은 새 기획에 따른 미리보기 적용이며 본편 원정 전용 속성은 그대로다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `scripts/map_builder/ApprovedMonsterPlacement.gd` | 개체/유지비·정원·교체·추천·시험 저장 모델 |
| `scripts/map_builder/ApprovedMonsterPlacement.gd.uid` | Godot 리소스 ID |
| `scripts/map_builder/ApprovedMonsterPlacementUI.gd` | 명단·드래그·정보·식량 UI |
| `scripts/map_builder/ApprovedMonsterPlacementUI.gd.uid` | Godot 리소스 ID |
| `scripts/map_builder/ApprovedPlacementView.gd` | 기존 지도/탭/입력/저장 연결 |
| `scripts/map_builder/ApprovedTileAssembler.gd` | 고정 샘플 제거·빈 수비 칸 |
| `assets/maps/v130r_step3/monster_info_panel.png` | 실제 UI용 GPT 패널 |
| `assets/maps/v130r_step3/monster_info_panel.png.import` | 런타임 import |
| `assets/source/imagegen/v130r_step3/monster_info_panel_source.png` | 네이티브 투명 생성 원본 |
| `assets/source/imagegen/v130r_step3/SOURCE.md` | 출처·실제 알파·후처리·기존 GPT 재사용 |
| `assets/source/imagegen/v130r_step3/PROMPT.txt` | 실제 생성 프롬프트 |
| `tools/assets/import_v130r_step3.py` | 자산 복사·알파 확인·크롭/축소 |
| `tools/run_v130r_step3.ps1` | 공식 실행기 탐색·단일 Godot·APPDATA 격리 |
| `tools/tests/V130RStep3PlacementTest.gd` | 모델/재열기/실제 입력/캡처 검사 |
| `tools/tests/V130RStep3PlacementTest.gd.uid` | Godot 리소스 ID |
| `tools/tests/V130RStep3PlacementTest.tscn` | 검사 진입 씬 |
| `tools/tests/v130r_step3_capture_audit.py` | UTF-8 한글 경로 저장·축소본/비교·보존 감사 |
| `docs/handoff/V130R_STEP3_PLACEMENT_2026-10-16.md` | 본 인계 |
| `docs/handoff/CURRENT.md` | 브랜치 후속 진입 기록 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 `image_gen` 신규1회, `transparent_background=true`. 생성 원본 알파0..255 직접 검사. 외부 생성기/유료API/배경제거/코드 그림 없음.
- 원본·실제 프롬프트·정책 필드·정확한 경로는 `assets/source/imagegen/v130r_step3/SOURCE.md`와 `PROMPT.txt`.
- 후처리는 투명 여백 크롭·800px 축소·뿔 돌출부를 제외한 직사각 본체 크롭(0,78,800,548). 원본 보존. 런타임800×470, 실제 게임에서 글이 패널 안에 있는지 확인.
- 기존 GPT 지도·초상화·캐릭터 시트·역할/식량/잠금/경고·자동/해제·하이라이트 재사용. 폰트 NEXON_Maplestory Bold/Light. 글씨만으로 만든 버튼/코드 도형 UI 추가 없음.
- 오디오 변경0.

## 6. 테스트 및 검수

| 명령/방법 | 결과 | 근거 |
|---|---|---|
| `powershell -ExecutionPolicy Bypass -File tools/run_v130r_step3.ps1 -Mode import` | PASS | `tmp/v130r_step3/import*.log` |
| 같은 실행기 `-Mode direct` | 172 checks / 실패0 | `direct_result.json` |
| 같은 실행기 `-Mode capture` | 56 checks / 실패0 | `capture_result.json`, 실제1920×1080 |
| `python tools/tests/v130r_step3_capture_audit.py` | 요청6장·기존1,383파일 해시변경0 | 외부 `capture_audit.json` |
| Python AST·PowerShell 파서·`git diff --cached --check` | PASS | 실행 결과 |
| 요청 캡처6장+비교1장 | 축소본 한 장씩 시각 확인 | 외부 `previews/` |
| 전체 회귀/전체 플레이/별도 검수 에이전트/export | NOT_REQUESTED / 미실행 | 요청 범위 유지 |

직접 검사:14개체/유지비/그림/스킬, 계약 잠금 거절, 정원 초과/없는 시설 거절, 배치 교체/대기 교체/해제, 예산0/1/15/23/30별 자동배치·모든 시설 정원·셀 중복 없음·역할 추천, 실제 파일 저장 왕복·씬 종료/새로 열기, 전부 해제 유지비0. 화면 검사: 실제 탭/드래그/정보/자동/교체/외부해제/전부해제/건설복귀/비활성 전투,14개체 정보 내용과 명단 비겹침, 기존 건물5메뉴. 최종 direct/capture stderr 빈 파일. 이전 step2 시험 배치 바이트 불변.

초기 개발 중 타입 추론 오류·update3 종 데이터 누락·JSON 숫자형 일치 문제를 발견해 수정했다. 최종 위 검사에서 실패/스크립트 오류0. import 중 기존 누락 UID 재생성 경고는 제품 오류와 구분한다. 자료 조사 에이전트1명은 읽기 전용/쓰기0/Godot0으로 데이터와 GPT 출처만 조사했으며 별도 검수 에이전트는 실행하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 6ca4c895b121a50b58ae15c1c729c9aeccda6fd4
- Review range: b1297e02e431d3b8e9c4209bbd88ef28b605670e..6ca4c895b121a50b58ae15c1c729c9aeccda6fd4
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

이 SHA 이후에는 docs/handoff 문서만 변경한다. 표적 검사 결과이며 사용자 화면 승인과 구분한다.

## 7. 다른 점과 제한

| 기준 | 이번 미리보기 |
|---|---|
| 목업 평면 격자·원형 기호·예시7장 | 기존0088 GPT 지도·실제14개체 초상화/캐릭터, 건설 바 자리를 명단으로 교체 |
| 목업 통합 한 줄 HUD·배치 예시12/18 | 기존 좌측 HUD 구조 유지, 실제 배치수/수비18칸/유지비 표시 |
| 목업 시설 설명창 | 이번 요청에 맞춰 개체 옆 실제 능력/기술 패널 |
| 기획 입구 방향 | 기본14종에 방향별 사선 그림이 없어 정면 대기 그림 좌우 반전. 새 사선 그림은 만들지 않음 |
| 기존 합류/캠페인 레벨 | 시험 초기 데이터 Lv1·기본4명, 나머지 잠금/전원해금 플래그. 개인 저장은 읽지 않음 |
| 기획 E등급 식량23/일 | 본편 기본 수입6이나 이 시험은23. 기존 지도 내부 legacy stage=3과 구분 |
| 로로 기존 원정 전용 | 새 기획에 따라 이 화면에서만 배치 가능 |
| 기존 기술의 방/가시 복도 표현 | 방 단위만 영향범위로 정리, 전투/지형효과는 후속0090 연결 대상 |
| 설계서3-3 | 원문 미확인, 지정 목업2개와 선행 인계로 확인 |
| 사용자 저장 | 격리 시험 JSON으로만 저장·재열기. 본편 저장 통합 아님 |

위 항목과 그래픽·자동 선택 취향은 **사용자 확인 대기**. 치환되지 않은 기존 기술 문구는 데이터 그대로이며, 실제 정산·배치 전투 효과를 구현했다고 주장하지 않는다.

## 8. 다음 작업 순서

1. 외부 `C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step3_place/previews/` 사용자 확인 대기.
2. 같은 폴더 `differences.md`와 `compare_place_vs_mockup.png`로 차이 확인. 실제1920×1080 원본은 `place_01_roster.png`, `place_02_drag.png`, `place_03_placed.png`, `place_04_info.png`, `place_05_auto.png`, `place_06_food_warn.png`.
3. 사용자 후속 지시 범위에서만 보정.0090 전투/0095 정산·캠페인 합류·새 방향 그림·push/merge/태그/Steam 자동 진행 금지.

수동 재현: `powershell -ExecutionPolicy Bypass -File tools/run_v130r_step3.ps1 -UnlockAll`. 건설 탭으로 시작하며 배치 탭 클릭. 기본 잠금 확인은 `-UnlockAll` 생략. 개인 APPDATA/LOCALAPPDATA는 ignored tmp로 격리하며 기존 Godot이 있으면 실행을 거절한다.

## 9. 작업 트리 상태

- 기존 혼합 import/UID 파일1,383개 SHA-256 보존. 기존 미추적 설계 폴더 등 수정 없음. 이번17개 구현/자산/검사 경로만 명시 스테이징·로컬 커밋했다.
- 개인 사용자 세이브 경로 미접근·미수정. 기존 step2 시험 파일도 바이트 보존. 새 step3 시험 복사본/로그는 ignored tmp, 캡처는 외부 mockup.
- Godot 시작0·모든 실행 직렬·동시최대1·종료0. 초기 파싱 실패로 남은 본 세션 소유 프로세스1개를 종료했고 이후 시험은 정상 종료했다.
- 브랜치 전환·stash·별도 worktree 없음. 원격 최신성 조회/fetch·push·merge·태그·Steam0.

## 10. 종료 체크리스트

- [x] 요청 범위 구현·정원/교체/해제/저장 재열기 검사
- [x] 실제1920×1080 요청6장·비교/차이 표·축소본 개별 확인
- [x] GPT 출처/알파/폰트·기존 변경/사용자 세이브 보존
- [x] 영어 로컬 구현 커밋·인계/CURRENT 문서 커밋
- [x] 전체 검수 미요청·원격/배포 미실행·Godot 종료0
- [ ] 사용자 화면 확인

**사용자 확인 대기.**
