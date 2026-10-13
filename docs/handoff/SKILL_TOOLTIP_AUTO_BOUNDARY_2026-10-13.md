# 지원 툴팁·곱 자동 경계와 개인 Library 검토 패키지

## 메타데이터와 승인 범위

작성일 2026-10-13 UTC. 제품 Who Guards the Demon Castle / bluehige/mawangseong-demo / Steam5267750. 버전1.2.11·Godot4.6.3 유지. 브랜치 `codex/skill-tooltip-auto-boundary`, 기준 `721fe9aa275ad1ff091288028967726627060fb5`, Product/Reviewed SHA `80335024f813bf0b5052251714185d000fa76932`. 이후 변경은 이 핸드오프와 CURRENT 문서만이다. 로컬 main이 없고 origin/main `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 원격 최신성은 미검증; fetch/push/merge 없음.

부모의 승인: 기존 night_relay·royal_emergency_plating 문구를 실제1F 범위로 정정하고, 곱 왕관 자동 효과 동등성 한 경계만 추가 검증. 다른7스킬 전체 검사는 반복하지 않는다. 개인 진행 없이 최신 PCK·필수 데이터·정상 새 게임 안내를 개인 Library로 전달해 부모의 실제10–20분 검토를 가능하게 한다. 실제2F·새 밸런스·Steam 공개 작업은 범위 밖이다.

## 변경 파일과 결과

| 파일 | 변경 |
|---|---|
| data/regular_version/update4/skills.json | night_relay: 1층 다른 위험 방까지 보행한 뒤 양쪽5초 효과. royal_emergency_plating: 1층 같은 방/가까운 도달 가능 손상 시설 중 HP비율 최저, 최대HP30% 수리·8초 피해30% 감소 |
| data/localization/ui_en.json, ui_zh_cn.json | 해당 Korean-keyed 툴팁 두 개를 동일한 실행 의미로 번역. 기존 다른층/왕관실·인장금고 문구 교체 |
| tools/tests/CrownGobAutomaticBoundaryTest.gd/.tscn | 기존 Gob fixture를 상속하지만 run을 새 경계 하나로 대체. 실제 수동 request_selected_skill과 자동 try_auto_monster_skill 비교; 툴팁6개 실제 TranslationServer 조회 |

생산 전투 코드·능력치·마나·해금일·적수·보상·그래픽·오디오·저장 경로 변경0. 기존8스킬 구현/왕관·성장 피드백을 최신 PCK에 포함한다. 로컬 편집기 재임포트가 생성한1423개의 추적 .import 메타데이터는 작업 시작 시 clean이었던 원본 HEAD로 해당 경로만 복원했다. 생성된 비추적 테스트 UID는 제거했으며 제품 코드 변경으로 포함하지 않았다.

## 새 검증 — 다른7스킬 전체 회귀 재실행 없음

| 검사 | 결과와 범위 |
|---|---|
| CrownGobAutomaticBoundaryTest 실제 OpenGL GUI | **PASS24/0**, 오류0. 한국어/영어/중국어 툴팁6개+실제 수동/자동 연쇄 한 경계 |
| 실제 수동/자동 결과 | 둘 다 주/보조 HP손실19/19·contacts2·사용1·부채1·마나500 그대로·실제 원위치 복귀·종료 DEF0.85. 정상 AI dispatcher를 호출하되 다른 기본 기술은 fixture에서 CD를 걸어 왕관 기술을 고립시킴 |
| 실제 컷신 | 수동·자동2PNG 직접 확인. 현재 crown_gob 프레임과 준비 단계 ‘연쇄 접근 시작 · 실제 타격 후 사용’. 자연 왕관 획득/새 그림 검증 아님 |
| 최초 sandbox PCK export | exit0이지만 project.binary 임시 안전 저장 ERROR. **실패 중간 기록**, 통과로 합산하지 않음 |
| 최종 PCK export | 작업 로컬 TEMP/TMP와 필요한 파일 권한 범위로 재시도, exit0·ERROR/SCRIPT ERROR0 |
| 새 PCK 내용 | 툴팁6개 존재·리소스3421개·개인 campaign/customlayout/test폴더/native extension 파일0 |
| 새 PCK 실제 main 부팅 | OpenGL180frames exit0·오류0. 타이틀/첫실행 업데이트 창 PNG 직접 확인. 신규 스킬 전체 재실행 아님 |
| 보존 | 개인698개와 기존 백업, mismatch0 |
| 다른7스킬 전체 검사·전체회귀·자연10–20분·자연전체해금·사람 재미/밸런스 | **NOT_RUN**, 부모의 다음 실제 플레이 검토로 연결 |
| Linux 실제 실행·두PCCloud·Steamworks 현재 읽기 | **NOT_RUN 로컬**, Linux는 부모에 준비된 환경에서 확인. Steamworks 기존 환경 차단 상태 별도 |

Review task ID: NOT_REQUESTED. Remaining P1/P2: N/A (전체제품). Final review result: TARGETED_PASS (이 경계/문구/패키지 범위). 자동 assertion 수를 재미나 자연 플레이 증명으로 해석하지 않는다.

## 패키지와 Linux 경로

작업 루트 `evidence/skill-boundary-private-cloud/`에 PCK·README·launch-linux.sh·manifest·로그·개인보존 결과·Library 인계를 보존했다. PCK584531800 bytes, SHA256 **BDAAF764C8F413275B7BB5577A3A09BDCC42D7C98BAC22ACC753AB716E8E8B00**.

정적 조사와 PCK 내용상 GDExtension/DLL/SO/C#/Windows 전용 런타임 분기 없음. Windows Steam 프리셋은 배포용 제외 필터이며 Steam SDK 연동이 아니다. 무암호 PCK 안에 project.binary·compiled GDScript·런타임 JSON·세 언어 카탈로그·폰트·텍스처·오디오가 들어 있다. Linux에는 기존 **Godot4.6.3 Linux x86_64와 OpenGL3.3 표시 환경**이 필요하고, Windows EXE/Steam 로그인/추가 에셋/.NET/내보내기 템플릿은 필요하지 않다. 플랫폼 중립 구조 확인이며 Linux 부팅 PASS 주장은 아니다.

Library는 한 PCK의 연속 바이트를 두 ZIP으로 전달했다. 둘 다 같은 폴더에 unzip하고 `GODOT_BIN=/absolute/path/to/godot bash ./launch-linux.sh`로 실행한다. 스크립트가 part1→part2를 결합하고 위 SHA256을 확인한 뒤 XDG_DATA_HOME/CONFIG_HOME/CACHE_HOME을 패키지 내부 `.private-review-profile`로 고정한다. 기존 사용자 기본 경로 계약은 변경하지 않는다. 다른 새 게임 비교에는 REVIEW_PROFILE로 새로운 폴더를 지정하며 개인 진행파일을 복사하지 않는다.

README에 정상 New Game→이름→도입대화→고블린 카드/허용 방→Start Defense 경로, 시설/배치·Focus(CP1)/Emergency Fallback(CP2)의 노란 대상 클릭, Space/Enter·Tab·ESC·배속·zoom을 기재했다. 튜토리얼의 시설 선택 제한을 우회하지 않고 실제 이용 가능 시점을 기록하게 했다. 과거6618c09의 DAY2 TUT110 scripted 입력 정지는 현 빌드의 재현 증거가 아니며, 재발하면 화면/입력/단계를 기록하고 검사 편의를 위해 스킵하지 않는다.

## 개인 Library 전달 확인

| 파일 / authoritative identity | bytes | SHA256 |
|---|---:|---|
| MawangCastle-PrivateReview-8033502-Part1.zip · libfile_e6879d2aba1c8191aca8058a669c11ca · file_00000000e5a082098377345b9464d6f7 · version0 |293929521|81C6D032EFD7265B90B3FD0D1654B0B2DC90AEBBF148566BC93FCD9B49A27126|
| MawangCastle-PrivateReview-8033502-Part2.zip · libfile_5a7f66d397248191b8edb41982f4bb4d · file_00000000899c820981b4e8d7f37e0405 · version0 |292266042|28F2D2CE1A55328CC0814B1B91FFC87D466E92ED872A210B789A0DAC9CE9EC1C|

둘 다 create_library_file **status succeeded**, 개인 기본 Library 폴더에 저장; share/public access 호출 없음. 현재 Library 스킬 helper의 첫 조회는 sandbox DNS로 실패, 네트워크 재시도에서 prepare_uploads 미제공을 확인했으며 저장/전송은 시작되지 않았다. 스킬의 미제공 대체 경로로 500MB 미만 파일을 각각 순서대로 등록했다. Windows Python의 os.setxattr 미지원으로 로컬 xattr helper는 실패했지만 Library 저장은 성공했다. 반환된 ID/버전/xattrs를 `library-delivery.json`에 별도 보존했으며 xattrs가 설정됐다고 주장하지 않는다.

패키지에는 allowlist의 PCK 두 조각·README·launch·manifest·보존 숫자·이번 검증 로그/3PNG만 포함하며 개인 세이브·계정/보안 자료가 없다. 개인 백업 manifest/캠페인 데이터·엔진 임시 폴더·Git은 전송하지 않았다.

## 다음과 복구 지점

부모가 Library 두 파일의 반환 identity로 materialize→같은 디렉터리에 unzip→실제 Linux 부팅 확인→격리 새 게임의 첫10–20분 선택/결과 가독성/재도전 이유 검토를 진행한다. 개인 진행·튜토리얼 우회·사람 재미 자동PASS 주장 금지. 이 브랜치의 product8033502와 해당 evidence 폴더가 복구 지점이며 첫 export 실패/Library 사전실패도 삭제하거나 성공으로 승격하지 않았다. Steam공개 배포/설정/개발자전용 해제·원격push/merge·SDK계약/보안 변경0.
