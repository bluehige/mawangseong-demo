# 기본 지원 실제 효과 복구 — 묶음1

Product/Reviewed SHA: 5f8554f3df4e63dc413f2f24de311041d4aa2102. Branch: codex/basic-support-skill-recovery. Godot4.6.3, 제품 표시1.2.11 유지. Review task ID: NOT_REQUESTED (전체 제품 검수); 독립 집중읽기 `/root/skill_action_review`. Remaining P1/P2: 집중범위0, 전체 N/A. Final review result: TARGETED_PASS.

최신 사용자 ‘이름에 맞게 스킬구현하고 컷신도 만들자’ 승인에 따라 앞선 보류/DLC 판단을 현재 중단 근거로 사용하지 않는다. [실행 명세](SKILL_COMPLETION_SPEC_2026-10-12.md)의 후속 묶음은 계속 진행 중이다. 이번 제품은 모든 기술 완성 빌드가 아니다.

## 실제 변경

- SingleFloorSupportRuntime: 실제 열린 방 socket edge 거미실1개, 첫고유4명 실제교차 둔화, 화염구 고정 발사사선/화염지대 영역별 사건 제거. 파수/수선 특화 수치 반영.
- 밤길 중계는 다른 실제 위험방까지 기존 내비게이션으로 보행한 뒤 양쪽5초 강화. 전달 동안 일반공격AI가 길을 끊지 않음. 대상사망/경로실패/수동명령 취소, source별 독립버프 수명, 체크포인트/타이틀 정리.
- 모리 기존왕관 치유1.08을 실제46→50/24→26에 연결, 현재 억제 상태 재검증. INT/공용마나 규칙 변경 없음.
- 푸딩 성벽의 품은 같은방 각아군 최초40%HP에서15%방호, 실제 hp_changed 즉시발동. 한프레임 연속 타격 전에 적용하고 재진입으로 반복하지 않음.
- Unit/HUD/Controller에 실제 효과·잔여상태 연결, 현재외형 공통 준비→접촉 컷신. 새 그래픽 생성 없음. 없는VFX 프레임 fallback 때 unparented sprite.free로 종료누수 제거.

## 실행 결과

| 검사 | 결과·범위 |
|---|---|
| BasicSupportRecoveryTest actual GPU | PASS253/0, 움직이는투사체대상의고정사선/특화/보행/도착/비용1회/수명/메뉴x3/왕관억제/동일frame14→60피해후HP17 포함 |
| SkillRuntimeConnectionTest actual GPU | PASS126/0, 기존응급실밥/왕관젤 실제비용·효과·취소·메뉴/체크포인트·현재왕관외형 |
| PlayerContinuityTest headless | PASS89/0, 의도한쓰기실패경고 포함. 저장실패를성공으로표시안함 |
| Day2RoomSelectionTest headless | PASS61/0, 기존자연DAY2격리checkpoint·occupiedroom/zoom/menu/복원. 실제GUI는기존979검증과분리 |
| editor/import | exit0, 초기editor의Unicode3경고 원본보존. 최종source런타임에SCRIPT ERROR/리소스누수 없음 |
| Windows release-template export | exit0, 별도 private 개발검토패키지. debug템플릿미설치 첫export FAIL 보존 |
| 새 PCK PackedSupportRecoverySmoke | PASS12/0, 거미줄/기존응급실밥/실제중계보행/양쪽효과·종료·정리 |
| 새 EXE 격리실행 | PASS180frames exit0, package/prototype_userdata |
| 보존 | 개인698files mismatch0·backup698/기존5artifacts/원래17captures 유지 |

집중독립읽기결과 TARGETED_PASS, 발견3P2(억제치유배율/프레임방호/실제발사사선) 수정 후 소스·최종증거재확인. 독립agent의실행은NOT_RUN이며writer직접실행과구분.

실패 원본: 초기205fixture2FAIL(accepted-interrupt 정책 오해·40%round경계), 확대248중1FAIL(화염영역밖문턱fixture), 상대로그경로 엔진시작crash, 프레임캡처headless대기 중단, debug-template export미설치. 고친fixture·실행옵션의최종검증을실패원본과함께보존.

## 빌드·캡처·남은 위험

`task-2/evidence/basic-support-recovery/development-build`의MawangCastle.exe/pck와LaunchPrototype.ps1, development-manifest.json. EXE단독대신격리launcher 사용. 이전aab19e4/979adcd패키지·바탕화면바로가기 그대로. ReviewEvidence는이번실제GPU16PNG+results.json과이번log/독립읽기이며기존aab갤러리를새결과로세지않는다.

개별 실행캡처에서현재실키시전/포포도착을육안확인. 모든PNG개별육안/모든승급외형matrix/자연movingreceiver/실제동시AI의x3장거리/커스텀모든socket/freed투사체target/모리합동배율/자연영입·mastery·왕관해금/사람재미는NOT_RUN. 현재 fixture는actor생성/왕관강제설정을포함하며정상획득을증명하지않는다.

남은6액티브 echo_alarm, royal_no_second_cut, tricolor_demonfire, royal_shared_umbrella, royal_emergency_plating, royal_urgent_courier와젤분기계승/passive잔여/정상해금은미완료. 실제상층범위질문대기. native은신·seal channel 기존미연결을이름만표시로완료처리안함. 성장개선은스킬묶음뒤. Steam실제설치노출/두PC Cloud/전체캠페인NOT_RUN, 공개배포·원격Git·홍보 없음.

복구점: 5f8554f 제품으로이묶음재현가능. 새로운코드묶음은후속검증대상이며이SHA의TARGETED_PASS를자동승계하지않는다.
