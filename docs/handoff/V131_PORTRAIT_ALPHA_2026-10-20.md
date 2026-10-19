# V131 대화 초상 네이티브 투명 교체 — TARGETED_PASS

## 1. 메타데이터

- 작성일: 2026-10-20
- 목표 버전/작업: v1.3.1-2 / 0132, `V131-PORTRAIT-ALPHA`
- 작업 브랜치: `codex/v131-patch`
- 선택 작업트리: `C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-v131-patch`
- 시작 SHA: `c23a64c064e1395520ce0a8ad15ce0a985cb0003` (0130 핫픽스와 0131 UI 포함)
- 마지막 제품/검증 SHA: `7d1020275938793592d8b1093f4755490db5999c`. 이후에는 이 인계·CURRENT·검사 CSV·파일 목록만 커밋한다.
- 로컬 영어 제품 커밋: `Replace dialogue portraits with native transparent assets`.
- 원격 푸시/PR/태그/main 변경: 없음.
- 로컬 main 참조가 없어 main 정책/CURRENT를 직접 읽을 수 없었다. 캐시 `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, `v1.2.5=f757ffa9f9e962158f2123856c8568a3163ecb6c`를 확인하고 캐시 정책/CURRENT를 읽었다. 원격 최신성 미확정, fetch/원격 조회 없음. 최신 사용자 지시로 작업 범위를 정했다.

## 2. 목표와 완료 범위

도둑 니아의 “마왕. 개업 축하해. 첫 도난은 내가 맡으려고 왔어.” 초상에 돌벽 사각 배경이 남는 문제와 0125 CSV의 개별 이미지21개·합본5개를 모두 처리했다. 골딘과 같은 GPT 내부 네이티브 투명 출력 방식이며, 외형·복장·표정·소품을 참조해 재생성했다.

대화 등장 초상 전체의 데이터 선언 경로를 자동 검사하고 실제 Windows EXE에서 니아 포함3개 대화 화면을 확인했다. Steam 배포, 밸런스, 대화 성능, 전체 회귀·전체 플레이는 범위 밖이다.

## 3. 완료한 작업

- 개별21개: 온보딩12개, 캠페인2개, 방패병1개, update3 적6개. 각 원본은 그대로 두고 `_alpha_v131.png` 교체본을 연결했다.
- 합본5개: 진화 기본/승리/부상3개, 왕관 core/support2개. 기존1536×1024·3열×2행·512px 셀을 유지했다. 30개 초상 영역을 각각 검사했다.
- update3 적6개는 과거 4×4 전투 시트의 첫 프레임이 대화 초상 `.tres`에 연결돼 있었다. 해당 인물의 독립 투명 초상을 생성하고 `.tres`의 원본·전체 이미지 영역을 갱신했다. 기존 전투 시트 픽셀/전투 연결은 유지했다.
- 캐릭터·적·화자 레지스트리의 초상 경로를 일치시켰다. 레지스트리에 남은 골딘 구 경로2개도 기존0125 네이티브 투명 교체본으로 연결했다.
- 스토리 대사 원문, 밸런스 수치, DAY29 무전투 데이터, NEXON MapleStory 글꼴, 저장 형식, 대화 배치 계산 코드는 변경하지 않았다. 공개 프로젝트 버전 메타데이터는 선행0131과 같은1.3.0을 유지했다.

## 4. 변경 파일

제품183경로와 인계4경로의 전체 목록: [파일 목록](V131_PORTRAIT_ALPHA_FILES_2026-10-20.txt).

| 경로 | 변경 목적 |
|---|---|
| `assets/source/imagegen/v131_portrait_alpha_20261020/` | 생성26·원본26·참조판5·정확한 프롬프트26·SOURCE.md·작업 manifest |
| `assets/sprites/portraits/{onboarding,campaign,enemies,update3,uiux_evolution,uiux_crowns}/` | 런타임 PNG26 및 import26, AtlasTexture36개 연결 |
| `data/characters.json`, `data/enemies.json`, `data/v130r/story/speaker_registry.json` | 초상 연결만 변경 |
| `tools/audit_portrait_alpha.py` | PNG/AtlasTexture 실제 영역의 전체 알파 검사 |
| `tools/run_v131_portrait_alpha.py` | 단일 엔진·격리 프로필·표적 검사·검사용 EXE |
| `tools/tests/V131PortraitAlphaTest.{gd,gd.uid,tscn}` | 두 해상도 크기·하단 기준선 검증 |
| `tools/tests/V131PortraitExeProbe.{gd,gd.uid}` | EXE에서 직접 입력하는 F7/F10 보조 도구, 제품 프로젝트에는 미등록 |
| 이 인계·`CURRENT.md`·알파 CSV·파일 목록 | 결과 및 남은 제한 |

## 5. 그래픽 출처와 알파

- Generation model: GPT internal image generation
- Generated date: 2026-10-20
- Target version: v1.3.1
- [출처·모든 원본/런타임 경로·정확한 프롬프트](../../assets/source/imagegen/v131_portrait_alpha_20261020/SOURCE.md).
- 26호출 모두 `transparent_background=true`. 생성 원본을 그대로 런타임에 복사했다. 26개 바이트 동일성/SHA256과83개 고유 이미지 출처 매핑을 검증했다.
- 로컬 배경 제거·색상 키·마스킹·알파 필터·재채색·런타임 리샘플링 없음. 참조/검토용 비교판 조립과 캡처 축소만 수행했다.
- 검사: `data/**/*.json`의 모든 portrait 필드·변형·화자 슬롯에서 PNG/`.tres`를 찾고, `.tres`는 실제 영역으로 펼쳐 검사한다. 전체 원본의 바깥 테두리만 검사하는 방식이 아니다.
- 가장자리 띠 폭은 짧은 변의1%(최소1px), α>248의 불투명 비율을 기록한다. α최소값이0이 아니거나 가장자리 비율>0.50 또는 모서리 비율>0.50이면 배경 잔여로 실패한다. 하단의 망토/갑옷 접촉은 비율로 보존하며 원본 알파를 바꾸지 않는다. 비교판에서도26개 결과를 직접 확인했다.
- 시작 검사156경로/배경53개 → 최종154경로/배경0개. 골딘 구2경로가 기존 교체 경로로 합쳐져 고유 경로가2개 줄었다. [최종 전수 CSV](V131_PORTRAIT_ALPHA_2026-10-20.csv). 과거 Evelyn은 가장자리0.402559/모서리0.25, 실제 알파0..255로 사각 배경 판정이 아니며 원본 유지다.

## 6. 검증과 실제 EXE

| 명령/확인 | 결과 |
|---|---|
| `python -m py_compile tools/audit_portrait_alpha.py tools/run_v131_portrait_alpha.py` | PASS |
| `python -X utf8 tools/audit_portrait_alpha.py` | 고유154개 경로, 사각 배경 잔여0 |
| `python -X utf8 tools/run_v131_portrait_alpha.py test` | 1280×720·1920×1080, 60개 텍스처/120샘플, 크기·하단 기준선·RGBA360검사 실패0, 종료0·진단0 |
| `python -X utf8 tools/run_v131_portrait_alpha.py export` | 최종 Windows release 내보내기 성공, 종료0·진단0 |
| `python -X utf8 tools/run_v131_portrait_alpha.py launch --portrait nia/milo/leon` + Computer Use | 세 번 독립 기동, F7로 실제 대화 열기·화면 확인·F10 종료, 세 번 모두 종료0·진단0 |
| `git diff --cached --check`, 이미지 출처/바이트 검증 | PASS |
| 전체 회귀·전체 플레이·별도 전체 검수 에이전트 | NOT_REQUESTED / 미실행 |

실제 EXE는 Vulkan/Forward+·RTX3060Ti에서920×518 창으로 조작했다. [니아](../../tmp/portrait_alpha_20261020/exe_nia.png), [밀로](../../tmp/portrait_alpha_20261020/exe_milo.png), [레온](../../tmp/portrait_alpha_20261020/exe_leon.png)의 정확한 초상 경로와 격리 user 경로는 대응 JSON 및 [EXE 요약](../../tmp/portrait_alpha_20261020/exe_summary.json)에 기록했다. 니아의 문제 대사를 동일하게 표시했고 머리·어깨 바깥으로 왕좌 장면이 이어짐을 확인했다. 검사용 대사 큐는 보조 도구에만 있으며 제품 스토리를 바꾸지 않았다. 기존0125c `StoryDialoguePresenter.gd` 바이트/크기 계산을 유지한다.

직접 이미지 열람은 참조판5+생성 비교판5+Computer Use 대화3=**13장**, 모두960px 이하다. 저장한 EXE 캡처는920×518, Computer Use의 창 테두리 포함 캡처도922×550이다. 추가 열람 없음.

첫 export의 QA 보조 스크립트 변수 형식 추론 오류는 `Node` 명시로 수정하고 다시 export해 오류0을 확인했다. [최초 실패 기록](../../tmp/portrait_alpha_20261020/export_first_failed.json)을 보존했다.

### 기존 0125 검사에서 확인한 범위 밖 불일치

`python -X utf8 tools/run_playtest_ui.py headless`는128개 중124개 통과,4개 실패다. 실패는 전부 `tooltip text clears frame ornaments`이며 초상 크기/기준선 검사는 통과했다. 구 검사에는 안쪽 여백≥40px가 고정돼 있지만 선행0131 UI는14px를 사용한다. `DialogueToolbarButton.gd`와 `StoryDialoguePresenter.gd`가 시작SHA와 동일함을 바이트 비교했다. 이번 변경이 만든 초상 결함으로 분류하지 않고 기존 검사 기대값 불일치로 남긴다. 해당 툴팁이나 구 검사 파일을 수정하지 않았다. 이 명령 전체를 PASS로 보고하지 않는다.

### 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7d1020275938793592d8b1093f4755490db5999c
- Review range: c23a64c064e1395520ce0a8ad15ce0a985cb0003..7d1020275938793592d8b1093f4755490db5999c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

판정은 초상 투명 교체·알파 전수·크기 유지·명시한 실제 EXE3화면에 한정된다. 전체 출시 PASS가 아니다.

## 7. 남은 제한

- 구0125 툴팁 여백 단언4개는 선행0131의 내용 높이 툴팁 구조에 맞춘 별도 유지보수가 필요하다.
- 이전 F7 진단 연속 전환 충돌 원인 해결을 주장하지 않는다. 이번에는 세 인물을 독립 프로세스로 확인해 충돌0이었다.
- 새 그림의 주관적 최종 선호 판단은 사용자 확인 대기다. 기존 난도·대화 성능·Steam 출시 게이트는 이번 결과로 해소되지 않는다.

## 8. 다음 작업

1. **사용자 확인 대기.** 니아 포함 교체 초상의 외형/표정을 확인한다.
2. 수정 요청이 있으면 같은 브랜치에서 해당 초상만 재생성하고 알파/필요한 화면을 다시 검사한다.
3. 0133 이후 계획이나 Steam 배포로 자동 진입하지 않는다.

## 9. 작업트리와 보존

시작 작업트리는 clean이었다. 원래 `mawangseong-action`의 혼합 작업은 건드리지 않았다. Godot이 생성한 무관한 미추적 UID118개를 제거하고 기존 import 내용은 보존/복구했다. 의도한 파일만 명시적으로 스테이징했다. EXE/PCK/캡처/로그/프로필/tmp는 커밋하지 않는다. 제품 커밋 이후 인계 문서만 변경했다.

`Steam-1.3.0-Ready` 접근/수정, push/fetch/PR/태그/main 변경, Steam 로그인·업로드·Steamworks 조작0. 사용자 세이브 원본 접근/수정0, 테스트용 새 프로필만 사용했다. Godot/게임은 직렬1개 이하, 최종0개다.

## 10. 종료

- 요청된26개 교체·연결 및 출처 보존 완료.
- 전수 알파 잔여0, 크기360항목 통과, 실제 EXE3개 화면 확인 완료.
- 구 툴팁 단언4개 실패와 미실행 전체 검수는 위에 명시했다.
- `CURRENT.md` 갱신·로컬 영어 커밋만 진행했다.
- **사용자 확인 대기.**
