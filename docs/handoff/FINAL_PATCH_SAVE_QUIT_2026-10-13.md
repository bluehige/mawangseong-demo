# 승인 패치 최종 정리 · DAY30 코코 저장/안전 종료

## 1. 메타데이터

- 작성일: 2026-10-13 UTC.
- 목표 버전: 승인된 1.2.11 검토 후보. 새 SemVer/태그 발급 없음.
- WORKSTREAM_ID: FINAL_PATCH_SAVE_QUIT_20261013.
- 작업 브랜치: `codex/fresh-v5-result-save-fix`.
- 기준 SHA: `05a126169096ae35c7579e876a1a891f97e1a40f` (제품 `b1a9e502cafc8a18d6161c4757fec9bdc1ebf96f`).
- 최종 제품/Reviewed SHA: `2dfbaeea2e28b4d8d04631689eee24c9ef7b0800`.
- 게임 로직·배치·결산 변경 고정 SHA: `9138368aa837c585143fd5e8b4edf5a923fef339`; 이후 종료문구 카탈로그 2경로와 검수 도구만 변경. 이전 통과를 전체 SHA PASS로 승격하지 않고 해당 파일·행 영향범위로 재사용했다.
- 마지막 제품 커밋: `2dfbaee`; 이후 `docs/handoff/`만 변경한다. 종료 문서 체크포인트 SHA는 최종 대화에 보고한다.
- 원격 push/merge/PR/태그/Steam/Cloud 설정 변경: 0.
- 로컬 `main` 부재. `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, v1.2.5=`f757ffa9f9e962158f2123856c8568a3163ecb6c`. 마지막 알려진 origin 문서 쌍을 읽었으나 원격 최신성/현재 권위는 확정하지 않았다. 선택한 단일 worktree를 유지했다.

## 2. 이번 세션 목표

잔여 전열/후열 안내, 기존 시설 기여 표시, 검토 패키지를 마무리한다. 중간에 사용자가 제출한 DAY30 오류를 우선 복구했다. 기존 첫 승리 저장·곱 자동 경계·성장·7스킬 통과검사는 반복하지 않는다. 최종 종합 실행은 새 영향범위만 묶고, 실패한 하네스 경계만 보정했다.

## 3. 완료한 작업

- **별도 DAY30 P1:** `CampaignSaveMigratorV1ToV2.SPECIES_TO_INSTANCE`의 정상 등록 5종 누락을 보완했다: graveyard_hound→monster_koko, ghost_housemaid→monster_bebe, armored_beetle→monster_toktok, spider_tailor→MON_SILKY, bat_courier→MON_POPO. 공통 매핑을 사용하므로 로스터·선택·원정·성장 참조도 같이 변환한다. 새 몬스터/ID 생성, 로스터 삭제/스킵, unknown species 허용 없음.
- 기존 현재 저장도 v1 기록 뒤 v2 변환을 거친다. 이 오류는 이전 LEGACY 회차 Council metric 삽입 P1과 다른 원인이다. 이전 7줄 수정은 본 매핑 누락을 포함하지 않았다.
- 저장 실패한 Quit 요청은 오류·최근 체크포인트·진행 손실 안내를 유지한 채 취소/다시 저장하고 종료/저장 없이 종료를 표시한다. 마지막 선택만 기존 명시적 `leave(false)` 경로로 연결된다. 실패 뒤 자동 무저장 종료 없음. 정상 Save/Quit와 타이틀/로드 보호 유지.
- DAY1 곱 표식/현재 카드: `전열 · 푸딩 합류`, `후열 · 핀 합류`. 같은 방/다른 방 선택을 동일한 선택 완료 문구로 표시하며, 기존 시작 위치와 실제 zone 매핑은 바꾸지 않았다. 튜토리얼/EN/ZH 동기화.
- 결산에 기존 `facility_effects`의 감시초소 추가 피해/둔화 적용 횟수, 병영 추가 피해/피해 감소, 회복실 실제 회복 HP를 최대 3줄로 표시한다. 탈취/무력화 알림도 함께 보인다. 키가 없으면 값을 만들지 않는다. 기록된 0은 0이다. 함정 누적 피해 계측이나 새 전술 일시정지 없음.
- 시설 추가 피해/피해 감소는 기존 계산 카운터이며 실제 HP 총피해나 승리 인과로 승격하지 않는다. 둔화는 적용 횟수이며 고유 적 수/지연 시간이 아니다.
- 오류 창의 기존 저장 묶음 복구/복구 실패 안내 두 줄도 EN/ZH로 보완했다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/core/CampaignSaveMigratorV1ToV2.gd | 정상 5종 canonical 매핑 |
| scripts/ui/PlayerContinuityUI.gd | 저장 실패 Quit 확인 유지·명시적 선택 |
| scripts/game/GameRoot.gd | DAY1 선택/현재 카드 문구 |
| scripts/v122/ui/V122CombatResultViewModel.gd | 기존 시설 측정값 표시 |
| scripts/ui/ResultWorkspaceUI.gd | 시설/알림 동시 표시 공간 |
| data/localization/ui_en.json, ui_zh_cn.json | 새 문구와 오류 안내 번역 |
| data/localization/v122_stage10_ui.json | 실제 튜토리얼 KO/EN/ZH |
| tools/tests/FinalPatchBoundaryTest.gd | 새 저장·종료·변경 화면 경계만 |
| docs/handoff/CURRENT.md, 본 문서 | 종료 인계 |

## 5. 그래픽 및 오디오 자산

생성/교체/후처리 없음. 능력치·효과·AI·보상·해금·저장 경로·스키마·Cloud 설정 변경 없음. Godot export가 만든 .import 1423개 및 테스트 UID는 clean 기준 HEAD 내용으로 복원했다. 기존 자산/패키지/프로세스를 교체하지 않았다.

## 6. 테스트 및 검수

근거 루트: `C:\Users\blueh\Documents\Codex\2026-10-13\task\final-review`. Godot `4.6.3.stable.official.7d41c59c4`, OpenGL3.3/RTX3060Ti. 캡처는 1920×1080 렌더의 자동화 fixture이며 사람 재미/자연 플레이 증거가 아니다.

| 경계 | 결과·한계 |
|---|---|
| 최종 export/통합 PCK 리소스 | export exit0; 검증된 803 base+16리소스 통합 패치와 최종 full export의 3421리소스 size/MD5/flags 모두 일치, 미포함0 |
| 정상 New Game의 곱 전열/후열 실제 카드/지도 입력 | 양쪽 실제 room/zone·즉시 완료 피드백·현재 카드 일치. 전투/첫 승리 검사는 실행하지 않음 |
| 기존 기록 시설 값·0/누락·알림 동시 표시 | 실제 저장된 병영17/회복0 입력을 표시. watch0/탈취11은 표시 스트레스용 합성 fixture라고 구분. KO/EN/ZH 캡처, 최종 번역 경로 확인 |
| DAY30 통제 v1~v5 기록·Continue | 실제 로컬 DAY2 백업 복사본을 기준으로 15/20/27 실제 진화 전제·최종 준비·정상 14종을 구성. 기록/Continue, 코코 Lv5/EXP13/bond44/nested mastery2·자원 보존 확인. 사용자 실제 DAY30 복구 증거 아님 |
| 이미 기록한 v1 input→v5 14종 모든 필드 의미 비교 | `recorded-day30-field-comparison.json`: 14종·모든 key·누락/불일치0. 원시 int/JSON float 표현만 달랐던 하네스 비교를 바로잡았다. 저장 테스트를 다시 쓰지 않았다 |
| 미등록 sentinel 거부·5개 primary checkpoint bytes 복구 | 실제 경계에서 unknown_review_species 거부, 로스터 유지, 바이트 동일. sidecar 전체 보호로 확대 주장하지 않음 |
| 마지막 명시 Quit 경계 | `quit-boundary-console.log` **PASS13/0**, JSON failures=[], 프로세스 exit0. 오류/손실/취소/재저장/무저장 종료 3언어 표시. 마지막 Quit는 실제 버튼의 production pressed callback이며 OS 마우스 클릭으로 주장하지 않는다. 정상 체크포인트5개 변경0 |
| 마지막 notice 카탈로그만 | `final-notice-locale-results.json`: 최종 패치에서 두 안내 줄×EN/ZH **PASS4**. 저장/종료/배치 통과검사 재실행0 |
| 개인 저장 보존 | 698→698, hash mismatch0. 개인 원본은 read/hash만, 체크포인트5개는 먼저 byte-copy 백업 후 복사본만 inspect/restore |
| 독립 소스 읽기 | `/root/final_review_plan`이 9138368 새 생산 diff를 1회 읽음, source 범위 P1/P2=0/0. 실행 테스트/whole QA 아님. 이후 catalog2 줄은 별도 최종 번역 경계로 확인 |
| 기존 첫 승리 저장·곱 경계·성장/스킬 | b1a9e50의15/7/12+부모 Cloud CUA, 8033502의24/0, d7f662b 성장 및 이전 각 스킬 SHA/파일 영향범위를 재사용. 해당 통과검사 재실행0, assertion 수 합산/whole PASS 주장0 |

**종합 실행의 실패 이력은 보존한다.** 요청대로 한 번 모아 시작했으나 하네스 준비 오류 때문에 문자 그대로 한 프로세스로 끝나지 않았다. `final-boundary-console.log`는 tutorial 준비/typed Array/Label raw source 판정 오류로 INVALID, 격리 테스트 pair만 종료했다. `boundary-repair-console.log`는 DAY30 진화 전제 미구성 및 timeout FAIL10/6. `remaining-boundary-console.log`는 FAIL44/20이며 14 numeric representation 비교와 6 Label 이름 조회 오류였다. 데이터/픽셀/target registry로 이 오류를 확인했고 이미 통과한 부팅·시설·배치·정상14종 왕복을 반복하지 않고 **마지막 Quit 경계만13/0**으로 마쳤다. 실패 로그를 숨기거나 전체 PASS로 세지 않는다. 최종 결과는 새 승인 범위의 TARGETED_PASS다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 2dfbaeea2e28b4d8d04631689eee24c9ef7b0800
- Review range: 05a126169096ae35c7579e876a1a891f97e1a40f..2dfbaeea2e28b4d8d04631689eee24c9ef7b0800
- Remaining P1/P2: N/A (whole product); 이번 생산 소스 범위0/0
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 사용자 첨부 `libfile_af1001a4ce8c81919e48273f056b15b3`의 Library OCR은 DAY30 성관리 메뉴·graveyard_hound 변환 누락 오류와 일치한다. 현재 공식 materialization은 Windows `os.setxattr` 미지원으로 설치 실패. 우회/원본 수정/재다운로드 없음. **이미지 원본 픽셀은 직접 확인하지 못했다.** OCR/부모 관찰과 소스/실행 증거를 구분한다.
- 실제 사용자 DAY30 저장/실행 SHA는 미수신. 로컬5개 저장은 August5/DAY2·핵심3종이며 screenshot의 live profile로 간주하지 않는다. 현재 Godot/MawangCastle 사용자 게임 프로세스도 시작 전 발견하지 못했다. 종료 불가 사용자 프로세스는 강제 종료하지 않았다.
- 자동 검사·통제 UI와 부모의 실제 자연 첫 승리/DAY2 관찰을 구분한다. 새 전체DAY1~30 플레이/사람 재미/두 번째 자연전투/실제 Steam 설치/2PC Cloud는 NOT_RUN. 공개 출시 승인이 아니다.
- subprocess 조사 두 worker는 gpt-6.1-sol/ultra로 명시했다. Fast 별도 변경 인자는 실행 도구에 노출되지 않아 그 UI 설정을 바꿨다고 주장하지 않는다.

## 8. 다음 작업 순서

1. 부모가 기존 8033502 base에 **새 통합 패치 하나만** mount하여 검토한다. 이전 FreshVictorySavePatch를 위에 다시 얹지 않는다. 기존 검토 프로필도 먼저 복사하고 명시적으로 복사본 경로를 선택한다.
2. 사용자 실제 DAY30 세이브와 실제 실행 후보를 확보하면 byte-copy/해시 후 그 복사본의 이번 변환·Save/Quit 경계만 확인한다. 이미 통과한 전체 검사를 다시 돌리지 않는다.
3. 사람이 판단할 실제 2번째 전투/성장 피해·재미·Steam2PC Cloud는 각 미검증 범위로 유지한다. 공개 배포/Cloud 설정/push/merge는 별도 지시가 있어야 한다.

## 9. 작업 트리 상태

제품 커밋 뒤 clean. 종료 문서2경로만 추가/갱신하여 로컬 문서 체크포인트를 남긴다. 모든 PCK/ZIP/캡처/개인 백업은 task workspace `final-review/`에만 존재하며 소스 Git에 추가하지 않는다. origin fetch/push 없음.

## 10. 종료 체크리스트

- [x] 승인 범위 구현·문구·패키징 완료
- [x] 관련 경계 통과/초기 하네스 실패 보존
- [x] 최종 제품 SHA·정확한 통합 패치·재사용 영향범위 기록
- [x] 실제 플레이/자동 fixture/Steam2PC Cloud 구분
- [x] 개인698 파일 보존·원본 변경0
- [x] CURRENT 갱신 및 의도한 파일만 로컬 커밋
- [x] 공개/원격 변경0
- [ ] 사용자 실제 DAY30 원본 복사본 복구 확인 (미수신)

## 11. 고정 검토 패키지

- 개인 Library: `libfile_0d8ab26307308191ba8917bc99b797b9`, `Mawang-FinalReview-SaveQuit-2dfbaee.zip`. 저장 succeeded, 공유/공개 호출0. 동일 Library identity로 최종 증거를 보완한다. Windows 로컬 xattr 적용은 현재 공식 helper의 os.setxattr 부재로 실패했으며 반환 identity/version/xattrs는 `library-delivery-final.json`에 보존한다. Library 저장 실패로 해석하지 않는다.
- 필수 base803: 584531800 bytes, SHA256 `bdaaf764c8f413275b7bb5577a3a09bdcc42d7c98bac22acc753ab716e8e8b00`. 부모가 이미 받은 Part1/Part2 PCK를 재사용한다.
- 최종 full export: 584536072 bytes, SHA256 `3a1f7e990174adc5acd3dc6b8d773c2cc0ba3057490b2936ef70349ee479781d`. 로컬 검토 산출물, 공개 업로드 없음.
- 전달 통합 patch: 1962184 bytes, SHA256 `9ac4e535d7c262cb3a884276a436dffe23f26817cf73a4b74847b4310fc67c61`, 16리소스. base+patch는 full export의3421리소스와 모두 일치한다.
- Quit13/0을 실행한 초기 통합 patch SHA256 `5c876d7f0c05efa6308fd721bcf5e6e387afc1bde843ce89566b58210c18d13d`. 최종 patch와 다른 리소스는 `ui_en.json`, `ui_zh_cn.json`, `.godot/uid_cache.bin`뿐이며 **게임/저장/종료 코드12리소스는 동일**하다. 마지막 번역 변경은 최종patch의 notice4 경계로 확인했다. `final-runtime-impact.json`과 두 inventory로 증명하며 정확한 SHA의 통과 범위를 합쳐 기록한다.
- ZIP에는 patch/Bootstrap/Linux·Windows 격리 launcher/source.diff/manifest/본 보고/성공·초기실패 로그/대표9PNG만 포함한다. base PCK/EXE/개인 저장/698파일 목록/SDK/계정·비밀은 제외한다.


## 12. 독립 Windows 검토 빌드 추가 · 2026-10-13

기존 section11 ZIP은 base803을 요구하는 델타 산출물이며 보존한다. 후속 독립 실행 요구는 새 **Windows x64 완성 ZIP**으로 충족했다. 제품 `2dfbaeea2e28b4d8d04631689eee24c9ef7b0800`, 문서 기준 `c2f0792ed11048f61e331215cd6b2b211e647985` 유지; 코드/데이터/자산/밸런스/저장경로/Cloud 설정 추가 변경0. 기존 전열·후열/시설 표시를 중복 구현하지 않았다.

- 로컬 완성본: `C:\Users\blueh\Documents\Codex\2026-10-13\task\standalone-review\Mawang-Standalone-Windows-Review-2dfbaee.zip`
- ZIP: 615708233 bytes, SHA256 `952bc549f44dc68797c2623eb7abe94241f08f0395e03166887cb5181a4df0b8`,30 entries. manifest `version=1.2.11`, `build_kind=private review`.
- `Game/MawangCastle.exe`:104699392B, SHA256 `b4eb57c313774883e4c80dc28f3892c6acd67eb37e5dbcca3c4684ac471c42f4`. 설치된 공식4.6.3 release template 기반 WindowsSteam export exit0. 최초 export는 격리APPDATA 템플릿 부재로 실패; release template 복사 후 패키징만 재개했다. debug template는 설치되어 있지 않으며 사용하지 않았다.
- `Game/MawangCastle.pck`:584536072B, SHA256 `3a1f7e990174adc5acd3dc6b8d773c2cc0ba3057490b2936ef70349ee479781d`. 새 export와 기존 fullPCK가 **바이트 동일**,3421리소스 size/MD5/flags 차이0. 기존PCK를 동봉; 옛base·overlay·Godot설치 필요0. Linux 실행파일은 포함하지 않는다.
- `Play.cmd`: setlocal+Game cwd, package/review_userdata로 APPDATA 격리한 새EXE 실행. 기본 격리는 launcher 계약이며 EXE 직접 실행은 기본 개인APPDATA를 사용할 수 있다. 원본 개인저장/검토profile/SDK/계정·비밀 미포함.
- 기존 GodotMIT/폰트 고지와 공식4.6.3 `COPYRIGHT.txt`(99790B, SHA256 `b3330849267d56ddd3d62a513817506606c2195034411fe05859f0140bff9d8a`) 동봉. 출처 [공식 고지](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/COPYRIGHT.txt), [Godot 배포 지침](https://docs.godotengine.org/en/4.6/about/complying_with_licenses.html#third-party-licenses). 프로젝트 전용DLL/GDExtension 미발견.

**추가 실행 범위는 새EXE 부팅 경계뿐이다.** 수정 없는 Main을 새EXE+옆의 fullPCK로 격리APPDATA에서 실행해 Godot movie/quit-after2로1920×1080 캡처·정상exit0을 얻었다. 대표PNG를 직접 읽어 타이틀 위 정상 첫실행 업데이트1.2.11 안내를 확인했다. resource/script ERROR0. 사용자 입력/자연플레이/저장/게임메뉴Quit 검증으로 확대하지 않는다. 첫 외부 --script 진단은 표준release의 path override 미지원 때문에 무시되었고 runner55초timeout으로 자기 프로세스만 종료한 INVALID. 실패 시도·stdout·원인은 모두 남겨 literal single-process PASS라고 주장하지 않는다.

- 새 경계: `standalone-boot.json`, `standalone-exit.json`, `regular-title00000001.png`, `standalone-regular-boot-console.log`, `standalone-pack-provenance.json`. 초기 INVALID는 `standalone-invalid-attempt.json`과 첫console 보존.
- 기존 13/0·notice4·14종필드비교·전열/후열·시설/첫승리/곱/성장/스킬은 section6/11의 SHA·영향범위를 재사용. 통과 게임플레이/저장 검사 반복0.
- 완성ZIP CRC 검증PASS. manifest SemVer를 마지막에 교정한 뒤 ZIP에서 달라진 entry는 manifest.json 하나뿐; 나머지29개 size/CRC 동일, 새JSON 유효. 추가 엔진 실행0.
- export 생성 .import1423/테스트UID3만 clean HEAD로 복원, 제품 변경0. 마지막 개인원본 read/hash698→698 mismatch0. SaveStore.inspect 원본 호출0.

**Library 전달은 미완료다.** 현재 공식 Library3-script prepared helper를 한 번 실행했으나 `Library prepare_uploads is not available`로 tool-discovery 단계에서 실패했다(exit1/stdout0). 준비/전송/최종 저장 호출 전의 확인된 실패이며 새Library파일ID 없음. Assistant tool 목록에는 prepared actions가 있지만 이 호스트의 helper inventory에는 연결되지 않은 환경 차이로 보인다. helper를 수정하거나 rawURL/직접업로드/분할/중복 생성으로 우회하지 않았다. 공식 [prepared-upload 지침](skill://plugin_connector_1p_1b8ff8edfc1481918b252c8277e23125/library/references/prepared-uploads.md)의 “Never switch a started helper write to a direct action”을 따른다. 이전 델타Library를 독립완성본이라고 제시하지 않는다. 전달진단 `library-delivery-summary.json` 및 로컬 완성ZIP을 부모에게 넘긴다.

정확한 제품SHA의 TARGETED_PASS와 검수 한계는 그대로다. 사용자 실제DAY30 save/executable 미수신, 전체캠페인/사람재미/자연두번째전투/실제Steam설치/2PCCloud NOT_RUN. 공개Steam/Cloud설정/원격pushmerge/태그Release0. 모든 빌드·캡처는 workspace에만 보관. 병합후권위CURRENT가 아니라 branch-local 인계이며 로컬main부재/원격최신성미확정 유지. 다음은 독립Windows완성본의 사람검토, Library helper환경이 정상인 호스트로 전달, 실제DAY30 자료가 도착하면 복사본의 미검증 좁은 경계만 확인하는 것이다.
