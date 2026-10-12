# 왕관 젤 계승·실제 방 긴급전령 검증

제품 `a83460df54c7b2fddf66c68616abc2c72ee496d1`, `codex/crown-mobility-inheritance`, Godot4.6.3. 개인 세이브698파일·이전 네 구현 패키지의 EXE/PCK/launcher12해시를 보존했다. Steam/publicGit/계정보안/유료서비스 변경0. 버전1.2.11은 변경하지 않았다. 로컬 main은 없고 origin/main0ac9fdc7의 원격 최신성은 재확인하지 않았으며 아래 구현은 별도 검토본이다.

## 구현

[구현 전에 고정한 계약](CROWN_MOBILITY_SPEC_2026-10-12.md). 사용자 답 ‘긴급전령의 상층 구현을 다른 밸런스로 수정해봐’를 반영해 다른 **실제 위험 방** 지원으로 재설계했다. 상층 전투를 구현했다고 주장하지 않는다.

- 푸딩 왕관: 저장한 승급 원본을 사용한다. 성문방벽은 현재 방 중심까지 실제로 걸어간 뒤 남은6초 방호창 동안 추가DEF3/고정·평타. 구조연금젤은 같은 물리방 최저HP비율 다른아군을 실제 뒤 안전점44로 옮긴다. 경로/벽/적점유/이동잠금/고정 때문에 이동이 불가하면 기존 방호는 유지하며 성공으로 표시하지 않는다. 마나0/전투1회/기존30%방호·35%대납은 유지한다.
- 포포 왕관: 다른 적점유 방 아군을 HP비율→적수→거리로 선정한다. 실제 안전 경로를 따라 .20초 simulation 이동하고 **도착 후** 아군 한명에게6초 이동×1.20·공격간격×.85·새 적대 상태시간×.80을 적용한다. 마나0/전투2회. 기존 보행중계 버프와 독립된 source/recipient key와 도착deadline을 사용한다. 포포 자체의 저항/봉인약점은 별도다.
- 첫 실제 다른 방 진입1회에 첫기본스킬의 남은CD30%만 회복하고 실제 회복 초를 기여에 기록한다. 평범한 방 이동 전체를 .20초로 바꾸지 않는다. 수동 명령은 다음 이동tick 전에 즉시 취소하고 이미 확정한 횟수만 남긴다. 메뉴 중 정지, 대상down/queued/방이탈·시전자봉인/억제·경로불가에 지원0, production battle-abandon에서 임시소유권을 제거한다.
- 현재 native왕관 프레임/아군 프레임 컷씬, 준비효과0·접촉1, 실제 결과 문구/전령이동 시작 안내, 현재 HUD역할·계승·고정·이동·지원·사용횟수를 연결했다. 메아리 경보 등 잔여 미구현은 계속 미지원으로 표시한다.

NEW_DESIGN: DEF3은 기존hold_corridor, 구조44는 기존ghostduo에서 차용한 새 계승 연결 선택이다. 전령의 층→방 재설계와 첫 실제진입 패시브, 저항+.20을duration×.80으로 해석한 선택도 명시했다. 수치는 사람의 재미·밸런스 검증 결과가 아니다.

변경13파일: 새 `scripts/combat/CrownMobilityRuntime.gd/.uid`, `scripts/game/CombatSceneController.gd`, `scripts/units/Unit.gd`, `scripts/ui/HUDController.gd`, `scripts/systems/crown/CrownEvolutionService.gd`, update4 `skills.json/crown_evolutions.json`, 새 `CrownMobilityRecoveryTest.gd/.uid/.tscn`, 기존 `CrownContractMonstersPhase28Test.gd`, 사전계약 문서. 외부 packed검증/패키지증거는 task evidence에 별도로 저장했다.

## 실행 증거

| 검사 | 결과 | 실제 범위 |
|---|---|---|
| CrownMobilityRecoveryTest 최종GUI | PASS202/0 | x1/x3 실제controller→recipientphysics 수명, 수동·실제auto·off/once첫/seen/always, 실제보행/중앙도착/구조, unsafe·잠금·봉인·사망·queued·방변경·메뉴, saved/legacy계승, 2수신자독립지원/2회제한, 실제CD회복, 준비억제 |
| BasicSupportRecoveryTest | PASS253/0 | 기존기본실밥/중계·왕관젤·합동 연결 회귀 |
| CrownContractMonstersPhase28Test | PASS29 | 순수서비스 계약. 기존synthetic AB숫자는 실제플레이/밸런스 증거가 아님 |
| PlayerContinuityTest | PASS89/0 | 기존메뉴/저장실패/체크포인트/백로그 경로. 의도된synthetic저장실패경고를 개인파일실패로 오해하지 않는다 |
| Godot편집기 재검증/export | exit0/error0 | 첫편집기 safe-save ERROR는 보존하고 PASS에서 제외. 보안설정 변경 없이 재실행 |
| 실제 신규PCK | PASS18/0 | 제품dispatch·실제중앙/구조44/방간이동/도착후6초/consumer·CD·suppression·production abandon |
| WindowsEXE 격리180frame | exit0/error0 | 시작검증. 사람의nativeOS클릭/전체플레이는 미실행 |
| 독립검수 | TARGETED_PASS | 제품SHA확인·별도격리PCK18/0·직접PNG3확인. 확정 열린P1/P2/P3 0; 전체검수로 확대하지 않음 |
| 저장/이전패키지 보존 | PASS | 개인698 mismatches0, 이전4×3hash변경0; 원본17capture·기존5artifact보존 |

최종GUI/편집기/export/PCK/EXE 로그의 runtime SCRIPT ERROR/ERROR/Parse Error0. 첫실행 FAIL143/15는 fixture API/ledger/문구와 실제경로끝점 문제를 구분해 보존했다. 두번째headless188/0, 중간GUI202/0은 최종현재UI반영 검증으로 대체했다. 독립읽기에서 발견한 manual-cancel순서/도착frame이중차감/가중점수역전/즉시중앙caption 덮어쓰기4건을 수정했다.

## 별도 개발 패키지

`../evidence/royal-support-recovery/mobility-development-build`의 `LaunchPrototype.ps1`은 패키지 내부userdata를 쓴다. 새 바로가기/Steam 설치/배포는 하지 않았다. `ReviewEvidence`에 최종3PNG·결과JSON·로그·중간실패 기록이 있다. 현재왕관native프레임과 실제결과 caption을 세PNG에서 직접 확인했다.

| 파일 | 크기 / SHA256 |
|---|---|
| MawangCastle.exe |104699392 / DD562A07855D0CCED116F58E1E727250F45A0D3BF0822B96A17635240DB09845|
| MawangCastle.pck |584469320 / 10171C669878BDC234E75CC615AC7243B91B3AA8EC5781515453E26B858B2B51|
| LaunchPrototype.ps1 |647 / D31BB2686C72DC74DD1B0F6EBA5B8B36E485DFC3EE4A57344F911B64118F24A5|

## 잔여/복구

NOT_RUN: 자연획득 영입·mastery·왕관해금, 실제상층/인장·boss channel, 사람 재미·정상진행밸런스·전체캠페인/nativeOS/저사양/두PCCloud. 최신Steamworks는 브라우저runtime장애로 읽기NOT_RUN, 설정write0. 과거게시·developer-only기록과 구분한다.

핀 ‘마나 효율로 변경하고 비용도 재설계’ 답은 승인된 다음 단계이며 이 제품에는 아직 구현하지 않았다. 다음은 핀의 실제manaquote·삼색모드/이력, 곱의 실제연쇄명령, 메아리의 실제공개/채널지연, 정상영입/mastery, 승인된성장순서다. 전체기능 완료 아님. 추가필수설계결정은 부모에게 질문/권장안/영향을 먼저 전달한다. 같은 두결정 재질문 없음.

복구점: 제품a83460d·별도패키지·최종로그와3PNG. 이후코드는 다른작업브랜치에서 진행하고 이 패키지는 덮어쓰지 않는다. Review task ID: scoped independent `/root/skill_action_review`; Reviewed SHA:a83460df54c7b2fddf66c68616abc2c72ee496d1; Remaining confirmed P1/P2:0; Final review result:TARGETED_PASS; 전체 QA NOT_REQUESTED. 독립보고서 `evidence/basic-support-recovery/crown-mobility-independent-review.md` 및 별도로그 `mobility-independent-packed.log`.
