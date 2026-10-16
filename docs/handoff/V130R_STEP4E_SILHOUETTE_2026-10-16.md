# V130R Step4E 가림 윤곽·수비 분산 — 사용자 확인 대기

## 1. 메타데이터

- 작성: 2026-10-17 KST(자정 경과). 요청한 2026-10-16 파일명 유지.
- WORKSTREAM_ID: V130R_STEP4E_SILHOUETTE / 목표 버전: 1.3.0.
- 브랜치: `codex/v130r-defense-layout`.
- 기준 SHA: `29dd21ce3b30c3bbe14eedc36f39c8e6ec9b607c`. 사용자 지정 0099의 구현 `545b8d84`와 문서 `29dd21ce` 위에서 작업.
- 마지막 구현·검증 커밋: `ee108a99e06cf82c809b53b7edec7f35d2fdf251` / `Draw occluded outlines and spread resting defenders`.
- 이후 변경은 인계/CURRENT 문서뿐이다. 최종 문서 SHA는 `git log -1`로 확인.
- push·merge·태그·Steam·원격 조회·fetch·PR 없음. 영어 로컬 커밋만 수행.
- 권위 제한: 로컬 `main` 없음. 저장된 `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 AGENTS/CURRENT를 읽었으나 원격 최신성 미확인. 현재 사용자 지시와 지정 기준을 사용.
- `v1.2.5=f757ffa9f9e962158f2123856c8568a3163ecb6c` 보존.

## 2. 목표와 완료 조건

- 가려진 몸에만 채움 없는 2 화면px 윤곽, 아군 하늘색·적 붉은색, 불투명도40%.
- 본체와 같은 프레임·변환·반전·중심·오프셋을 사용하고 Atlas 이웃 그림이 섞이지 않게 한다.
- 같은 건물 수비 칸마다 작은 고정 오프셋. 병영 네 명의 등각 격자 2×2 배치를 바깥으로 벌린다. 교전 이동은 기존 코드 유지.
- 지정3장·축소본 개별 확인·관련 검증·인계·로컬 영어 커밋.
- 제외: 사용자 세이브, 그림 원본·경제·전투 수치·스토리·AI 변경, 전체 회귀/전체 플레이/별도 검수 에이전트/성능/export/배포.

## 3. 완료 내용

- 기존 실루엣 셰이더의 내부 채움을 제거했다. 실제 몸 알파의 안쪽2px만 남기며 최대 알파0.4다. `dFdx/dFdy`(화면 픽셀에 대한 UV 변화)로 줌·자세에 관계없이 화면 기준 폭을 계산한다.
- 알파 윤곽 샘플에 현재 Atlas 영역 제한과 기존 색상 키 제거를 적용했다. 별도 actor_texture를 바인딩해 Godot headless/dummy 셰이더 컴파일러의 기본 TEXTURE 함수 인자 오류도 해결했다. 최종 headless/GPU 로그 오류0.
- 실제 건물 깊이 마스크는 유지한다. 몸보다 앞인 구조물과 겹치는 윤곽만 표시한다. 가려지지 않은 몸은 기존 그대로다.
- 실루엣 변환은 visual_body의 전체 변환과 sprite 변환을 사용한다. 프레임·반전·centered·offset도 본체와 일치시켰다.
- 병영 슬롯0~3 오프셋: `(-24,0), (0,-12), (0,12), (24,0)` 월드px. 각 칸 안에 머물며 기존 발 중심 마름모를 바깥으로 확장한다. 화면 수평 직사각형 강제 배치가 아니라 **등각 격자 2×2**다.
- 병영의 최근접 발 간격 **64→88 월드px**(기본0.75줌에서48→66화면px), 이웃 대각 간격71.55→98.39월드px. 푸딩·곱·로로·돌콩은 같은 기존 수비 칸을 유지한다.
- 강화 후 최대8칸까지 오프셋을 서로 다르게 준비했다. 4~7번은 `(-12,-6), (12,-6), (-12,6), (12,6)`. 이번 실제 화면은 기본 병영4칸이다.
- 초기 위치와 복귀 home만 오프셋으로 설정한다. 교전 경로/공격/추적/전술 코드는 바꾸지 않았다. 실제 복귀 경로 끝점과 기존 이동으로 도착하는 것을 검사했다.
- 데이터·밸런스·스토리·세이브 스키마 변경 없음.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `scripts/game/ApprovedBattleController.gd` | 고정 수비 home 오프셋 |
| `scripts/map_builder/ApprovedBattleOcclusion.gd` | 하늘색/붉은색·40% |
| `scripts/units/ApprovedBattleUnit.gd` | 실제 프레임·Atlas 경계·자세 변환 일치 |
| `scripts/units/approved_battle_silhouette.gdshader` | 채움 없는 화면2px 안쪽 윤곽 |
| `tools/tests/V130RStep4DLabelsTest.gd` | 재사용 검증의 출력 경로를 세션별로 분리 가능하게 변경 |
| `tools/tests/V130RStep4ESilhouetteTest.gd` | 수비 위치·실제 E DAY7·병영·가림·줌/적 색상 검사 |
| `tools/tests/V130RStep4ESilhouetteTest.tscn` | 격리 검증 씬 |
| `tools/run_v130r_step4e.ps1` | Godot최대1·APPDATA 격리·소유PID 오류/시간초과 종료 |
| `tools/tests/v130r_step4e_capture_audit.py` | 픽셀 감사·UTF-8 경로 게시·기존 파일 해시 확인 |
| `docs/handoff/V130R_STEP4E_SILHOUETTE_2026-10-16.md` | 세션 인계 |
| `docs/handoff/CURRENT.md` | 현재 브랜치 진입 링크 |

## 5. 자산·검수 이미지

- 새 그림/음원 생성·원본 수정·배경 제거 없음. 기존 자산 재사용, SOURCE.md 추가 대상 없음.
- 결과: `C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step4e_silhouette/`.
- `battle_e_day7.png`: 실제1920×1080 E DAY7 원본 웨이브 첫 접촉.14명 시험 해금·자동배치, 전체 웨이브 완주 아님.
- `occlusion_check.png`: 실제1920×1080, 길 칸(19,6)에 푸딩을 놓은 일시정지 검수. 앞 구조물 뒤에 가려진 윤곽만 표시.
- `barracks_front.png`: 실제 viewport에서 병영4명을 생산 home에 복귀시켜 일시정지한 확대 영역. 본체/라벨을 포함한 무배율 크롭이며 합성/재배치 그림이 아니다.
- `previews/` 최대1000×600 축소본3장. 최종본을 각각 한 장씩 열어 확인했다.
- 보조: `label_manifest.json`, `capture_audit.json`, direct/capture 결과, wall_depth, backwall_control. 원본 알파/실루엣 마스크는 ignored `tmp/v130r_step4e/alpha`, `silhouette`.

## 6. 검증

| 명령/검증 | 결과 |
|---|---|
| `tools/run_v130r_step4e.ps1 -Mode direct` | 1106 checks / 실패0 / stderr0 |
| 같은 실행기 `-Mode capture` | 322 checks / 실패0 / stderr0 |
| `python tools/tests/v130r_step4e_capture_audit.py` | TARGETED_PASS /25개 렌더 /기존1394파일 SHA256 불변 |
| `tools/run_v130r_step4.ps1 -Mode direct` | 기존 전투385 checks /실패0 /stderr0 |
| Python AST·PowerShell parser·scoped/cached `git diff --check` | PASS |
| 요청3장 최종 축소본 개별 시각 확인 | 3/3 |
| 전체 회귀·전체 플레이·별도 검수 에이전트·장시간 성능·export | NOT_REQUESTED /미실행 |

- 윤곽 픽셀은 실제 몸 알파 안에만 존재하고 깊은 내부에는0이다. 최대 알파102/255(40%).
- 줌0.5/0.75/1.0에서 앞턱 뒤 실루엣이 존재하며 적 붉은색도 GPU로 확인. 뒷벽 앞 대조는0픽셀.
- 깊이 검사는 동일 GPU 깊이 텍스처를 CPU 역변환해 비교했다. 정확한 경계의 행렬 반올림 차이에 한해 이웃 깊이 텍셀1개 허용. 몸 위치 검사는 허용 이동 없이 알파 영역 포함을 확인.
- 실제 가림 화면 켬/끔 차이도 윤곽 영역에만 있다. 현재 자세/줌/이동·이름표6px·복귀·기존 전투 직접 검사를 포함한다.
- 초기 셰이더 helper TEXTURE 접근, dummy sampler 전달 오류, 병영 슬롯1/2 방향과 간격 게이트 오류는 수정 후 재실행했다. 최종 결과/로그에는 실패가 없다.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: ee108a99e06cf82c809b53b7edec7f35d2fdf251
- Review range: 29dd21ce3b30c3bbe14eedc36f39c8e6ec9b607c..ee108a99e06cf82c809b53b7edec7f35d2fdf251
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 제한·미해결

- **사용자 확인 대기.** 병영 로로는 실제 앞 구조물 뒤라 일부가 윤곽으로 보이며, 기존 이름표 충돌 회피의 위/아래 비킴은 유지된다. 네 유닛 몸 전체의 무가림을 보장하는 지형 변경은 아니다.
- 해당 E DAY7 첫 접촉과 일시정지 가림/병영·줌 대조 검수다. F·강화8명·모든 자세/해상도·개인 캠페인 완주 검수는 하지 않았다.
- 사용자 세이브 읽기/수정 없음. APPDATA/LOCALAPPDATA는 ignored tmp 격리. 앞 단계 시험 JSON 바이트도 검사 전후 불변.
- 원격 최신 권위는 미확정이며 조회하지 않았다.

## 8. 다음 순서

1. 사용자: 요청3장 확인. **사용자 확인 대기.**
2. 추가 시각 지시가 오면 해당 표시/오프셋과 표적 검사만 조정.
3. push·merge·태그·Steam은 금지 유지.

## 9. 작업 트리

- 기존 혼합 변경1394파일 SHA256 불변. .import/.uid·docs/design/v131_layout 등은 그대로 보존하고 커밋에서 제외.
- 구현/도구9경로와 문서2경로만 명시적으로 stage. `git add -A`·stash·브랜치 전환·기존 변경 되돌리기 없음.
- 캡처·빌드·로그·임시 스크립트는 ignored tmp와 외부 _mockup에만 둔다. 소스 커밋에 이미지 없음.
- Godot 시작0·동시최대1·최종0. 기존 프로세스 감지 시 실행 거절; 실행은 한 번에 하나씩 수행.
- 로컬 영어 구현/문서 커밋, 원격 푸시 없음.

## 10. 종료 체크

- [x] 요청 범위 구현·직접/GPU/기존 전투 검사 통과
- [x] 이미지3장·축소본 한 장씩 확인
- [x] 세이브/기존 변경 보존·Godot종료0
- [x] 검수SHA·제한·미실행 범위 기록
- [x] CURRENT 갱신·영어 로컬 커밋·사용자 확인 대기
