# V130R Step13 Steam 도전과제 100개 — 사용자 확인 대기

## 1. 메타데이터

- 작성일: 2026-10-18 KST. 요청한 파일명 2026-10-17 유지.
- 목표 버전: 1.3.0. WORKSTREAM_ID: V130R_STEP13_ACHIEVEMENTS.
- 작업 브랜치: codex/v130r-defense-layout.
- 기준 SHA: 82fec09596abd45bf2c0b723d6a0ab9f96d7720b (0114 위).
- 마지막 제품·검증 커밋 SHA: 8ac1fce9cbd249eabfa94eb0943bbf2c31cddaf7. 구현 커밋 58f6f68dd69f42955278ca4e3fde3048c749d707, 이후 LF 보존 설정만 추가. 후속 커밋은 핸드오프 문서만 변경한다.
- 원격 푸시 여부: 없음. push·PR·태그·Steam 업로드·main 변경 없음.
- 권위 제한: 로컬 main 참조 없음. origin/main 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b, v1.2.5 f757ffa9f9e962158f2123856c8568a3163ecb6c. fetch/원격 조회를 수행하지 않아 최신 main 권위를 확정하지 않았다. 사용자 지정 브랜치와 최신 제공 지침으로 진행했다.

## 2. 이번 세션 목표

지정 기획의 100개·8세트·숨김 8개를 게임 이벤트, 자체 영속 기록, Steam 호출, 3언어 화면과 연결한다. 영어 로컬 커밋만 만들고, 실제 사용자 저장은 열거나 수정하지 않는다. 필요한 Godot 검사는 격리 APPDATA/LOCALAPPDATA에서 한 프로세스씩 실행한다. 공개 배포·Steamworks 정의 게시·실제 계정 해제는 이번 실행 범위 밖이며 사용자 PC 절차를 아래에 제공한다.

## 3. 완료한 작업

- `codex/v130r-monsters`에서 요청한 아이콘·텍스트 100개를 가져왔다. 추적 가능한 출처를 위해 같은 브랜치의 원본·생성 영수증·프롬프트·기획 사본도 그대로 가져왔다. 지정 Desktop JSON과 기획 사본의 내용 일치를 검사했다.
- `AchievementService` 자동 로드와 명시적인 `runtime_rules.json` 100개 조건. 원문 trigger를 보존하고, 불완전한 trigger 문자열을 코드로 평가하지 않는다. 엔딩 23개·왕관 6개·인장 6개·전선 3개 등을 실제 ID로 매핑한다.
- 함정 설치/처치, 완료한 건물 이동, 실제 개성 효과 11개 누계와 3개 순간 조건, 소비한 바티 대사, 실제 표시한 전투 대사 종을 연결했다. 시전 대기·화면 재그리기만으로 성공 누계를 올리지 않는다. 개성 14개 중 Steam 진행도 stat가 없는 갑옷·인형·푸딩은 기획대로 순간 조건이다.
- 최초 엔딩·왕관·인장·보유·기억·합동기·전문화를 기존 기록으로 소급한다. 기억은 승인 카탈로그 고유 74개만 센다. 서로 다른 회차의 고유 기억/종/합동기 기록은 합치고 중복 해제를 막는다. 실제 DAY2 v1/v5 테스트 사본과 별도의 완료 기록 모의 입력을 검사했다.
- `user://achievements_v130.json`에 해제·stat·고유 ID·미전송 큐를 원자적 교체/백업으로 저장한다. 캠페인 저장의 `payload.achievements`에도 프로필/회차 정보를 넣으며 v6에서는 `active_run.legacy_payload.achievements`로 보존된다. Steam 확인 콜백 성공 전에는 전송 항목을 지우지 않는다. 실패/수락 거절/확인 누락 시 다음 실행에도 큐가 남는다.
- 같은 캠페인의 패배·굶주림 이력을 별도 ID로 기억해 이전 저장/재시도가 무패·무굶주림 기록을 되돌리지 않게 했다. 옛 저장에 해당 이력이 없으면 완벽 기록을 추정하지 않는다. 식량 정산 직후의 굶주림과 부족량을 쓰며, 옥좌 무피해는 최종 체력 차이가 아닌 실제 받은 피해 누계로 판정한다.
- Steam 없이 초기화 실패해도 타이틀을 정상 구성한다. 강제 Steam 실행/재시작/네트워크 대기는 없다. `steamInitEx(5267750,false)`와 수동 콜백, 앱/사용자 일치 검사를 사용한다. SDK 1.65에서 제거된 `requestCurrentStats` 대신 `requestUserStats(getSteamID())`를 쓴다. `setAchievement`/`setStatInt`/`storeStats`, `indicateAchievementProgress`를 실제 공식 확장 API에 연결했다.
- 진행도 팝업도 `user_stats_stored`를 발생시키므로 실제 저장 배치와 팝업 콜백을 분리한다. Steam stat는 원격 최고치보다 낮추지 않는다. 일반 stat 전송은 60초/정산 경계, 신규 해제는 즉시 예약한다.
- 0114 메뉴의 도전과제 버튼을 활성화했다. 8세트 목록, 고유 진행도, 잠김 이미지, 숨김 제목/설명 보호, 한국어/영어/간체를 제공한다. 게임 화면의 `zh_CN`을 카탈로그의 `zh_cn`에 매핑한다. 해제 토스트는 입력을 가로채지 않고 순서대로 표시한다.
- 개발 명령 `--ach-reset-local`, `--ach-reset-steam`을 debug 빌드에서만 처리한다. Steam 초기화 후 리셋이 기존 큐 업로드보다 먼저 실행된다. release 빌드에서는 무시한다. 이번 세션은 실제 Steam 리셋을 실행하지 않았다.
- 전투 수치/웨이브/버전 변경 없음. 공병 시설 무력화는 `action_interrupt_timer`가 끝나야 실행되도록 하여 기존 방해 효과가 실제 시설 행동에도 적용되게 했다. 별도 전체 밸런스 검수는 수행하지 않았다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/achievements/ | 서비스·판정·소급·Steam 어댑터·이벤트·목록·토스트 |
| scripts/game/, core/GameState.gd | 승패/피해/보스/원정/정산/저장 연결 |
| scripts/combat/V130RMonsterSkills.gd, units/Unit.gd | 개성 효과·실제 보호/대신 받은 피해 |
| scripts/map_builder/ApprovedPlacementView.gd, ApprovedRecruitment.gd | 성공한 건설/이동/합류 |
| scripts/story/StoryDirector.gd, V130RStoryRuntime.gd | 읽은 대사·완료 장면·표시한 bark |
| scripts/ui/StartFlow.gd, TitleWorkspaceUI.gd | 메뉴·새 캠페인·바티 질문 |
| addons/godotsteam/, steam_release_export_filter/steam_release_export_filter.gd | 공식 확장·DLL·출처·내보내기 필터 |
| project.godot, export_presets.cfg, steam_appid.txt | 자동 로드·개발 App ID·내보내기 제외 |
| .gitattributes | 공식 descriptor/라이선스의 LF 줄바꿈·해시 재현성 |
| assets/achievements/v130/, assets/source/imagegen/achievements_v130/ | 기존 GPT 100개 아이콘·출처 |
| assets/source/imagegen/v130r_achievement_toast/ | 신규 프레임 원본·정확한 프롬프트·알파 출처 |
| data/v130r/achievements/ | 3언어 카탈로그·100개 명시 조건·Steam 등록 참고 CSV |
| tools/achievements/, tools/run_v130r_step13.ps1, tools/tests/V130RStep13AchievementTest*, v130r_achievement_cases.json, v130r_step13_report.py | 재현·100개 시험·단일 프로세스 실행·산출물 검사 |
| _mockup/game_step13_ach/*.md | 요청한 오프라인/소급/100개 판정/DLL 검수표 |

정확한 제품 커밋 경로 목록은 종료 시 아래에 추가한다. PNG 캡처·원시 실행 JSON·로그·PCK/EXE·시험 세이브는 로컬 산출물이며 커밋하지 않는다.

## 5. 그래픽 및 공식 확장 출처

신규 그림 생성은 GPT 내부 `image_gen` 1회(토스트 프레임)다. 원본 RGBA의 실제 alpha 0~255를 확인한 뒤 투명 여백 자르기·비율 축소·PNG 최적화만 했다. 로컬 배경 제거/외부 생성기/유료 API는 사용하지 않았다. 기존 아이콘 100개는 재생성하지 않았다. 게임 안 일반 잠김 상태는 기존 GPT 아이콘의 표시용 흑백 shader, 숨김은 기존 GPT 자물쇠를 재사용한다. Steam 잠김 이미지는 사용자 등록 시 자동 생성 옵션을 사용한다. 새 오디오 없음.

공식 배포는 [Godot Asset Library 2445](https://godotengine.org/asset-library/asset/2445)가 안내한 GodotSteam **4.23.1 / Steamworks SDK 1.65 / Godot 4.4+**이다. 현재 Godot **4.6.3.stable.official.7d41c59c4**에서 GDExtension 로드·API 제공 목록·Windows release export를 확인했다. MIT 라이선스와 공식 DLL 바이트를 보존하고 descriptor의 Windows x64 항목만 남겼다. 커스텀 엔진/커스텀 export template를 사용하지 않는다.

- 공식 archive: https://codeberg.org/godotsteam/godotsteam/releases/download/v4.23.1/godotsteam-4.23.1-gdextension-plugin-4.4.zip.tar.xz
- archive SHA-256: `37d53ede5eda11d2247d70c1af91f95a4777ad2a419fc8a24de1cc816d21cc0a`
- DLL별 버전·원본/설치 해시·크기: [PROVENANCE.json](../../addons/godotsteam/PROVENANCE.json), [export_dll_check.md](../../_mockup/game_step13_ach/export_dll_check.md).
- 재현: `python tools/achievements/vendor_godotsteam.py`. 고정 해시가 다르면 설치를 거부한다.
- Steam API 근거: [ISteamUserStats](https://partner.steamgames.com/doc/api/ISteamUserStats), 특히 RequestCurrentStats 폐기·RequestUserStats·StoreStats·IndicateAchievementProgress 항목. 조회일 2026-10-18.

## 6. 테스트 및 검수

최종 명령별 수치·실제 DLL 해시·로컬 근거는 아래 검수표에 기록한다.

- [unit_tests.md](../../_mockup/game_step13_ach/unit_tests.md): 독립 기획 입력 100개, 양성·잘못된 이벤트·누락/반대 조건·경계·중복·메타.
- [offline_test.md](../../_mockup/game_step13_ach/offline_test.md): Steam 없는 실제 초기화/타이틀, 실패→재전송/확인 콜백, 다음 프로필 로드.
- [retro_unlock_test.md](../../_mockup/game_step13_ach/retro_unlock_test.md): v1/v5 대표 테스트 복사본·합성 완료 기록·원본 불변.
- [export_dll_check.md](../../_mockup/game_step13_ach/export_dll_check.md): 실제 Windows release export, 두 DLL, PCK 색인, App ID/원본/검수 자료 제외, release 부팅.

요청한 실제 렌더 4장: [한국어](../../_mockup/game_step13_ach/ach_menu_ko.png), [영어](../../_mockup/game_step13_ach/ach_menu_en.png), [토스트](../../_mockup/game_step13_ach/ach_toast.png), [진행도](../../_mockup/game_step13_ach/ach_progress.png). 각각 1280×720 축소본 한 장이며 합성 검수판이 아니다. 간체도 실제 목록/문구 구성 검사를 수행했다. 진행도 27/50과 첫날 토스트는 별도 시험 입력이다. 실제 DAY1 자연 승리는 별도의 live_battle.json에 구분해서 기록한다.

초기 화면 시험의 난수 미고정 DAY1 자동 배치에서 1패가 나와 성공 검사가 실패했다. 밸런스나 승패를 바꾸지 않고 해당 시험의 시드를 `130013`으로 고정한 뒤 자연 승리·서비스 해제를 재검증했다. 이는 도전과제 연결의 재현 가능한 한 사례이며, 모든 DAY1 시드의 승리나 게임 밸런스 통과를 뜻하지 않는다.

전체 회귀·전체 캠페인·장시간 성능·다중 해상도·별도 검수 에이전트는 NOT_REQUESTED/미실행이다. 읽기 전용 코드 연결점 조사만 병행했으며 구현 writer와 Godot 실행자는 하나였다. 테스트는 격리 APPDATA/LOCALAPPDATA, 기존 `tmp/v130_m6/original_copies/`에서 만든 새 시험 복사본만 사용했다. 실제 사용자 저장 디렉터리는 열거나 수정하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 8ac1fce9cbd249eabfa94eb0943bbf2c31cddaf7
- Review range: 82fec09596abd45bf2c0b723d6a0ab9f96d7720b..8ac1fce9cbd249eabfa94eb0943bbf2c31cddaf7
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 가정

- **사용자 확인 대기:** 목록/토스트의 취향과 실제 Steam 클라이언트 해제. 이 세션은 Steam 클라이언트가 없는 환경에서 검사했으며 실제 계정 해제 성공이라고 주장하지 않는다.
- Steamworks의 실제 7개 추가 세트 ID가 아직 없다. `set_ids.template.json`은 빈 템플릿이다. 모의 ID로 시험한 CSV는 `tmp/` 전용이며 업로드하면 안 된다. 실제 ID 누락 시 생성기가 거부한다.
- 오래된 저장에 없는 함정·이동·개성·청취 누계는 0부터 시작한다. 전투 결과만으로 과거 boss 막타/직접 조종/무피해/속도 조건을 추정하지 않는다. 소급 엔딩·왕관·인장·보유·기억·합동기·전문화는 기록된 ID만 쓴다. 구 seen_scene_ids에는 스킵도 들어 있어 비밀 대사의 완독 증거로 추정하지 않는다.
- ‘관문다리’는 정답 JSON의 `victory && grade==C`를 그대로 따른다. 두 최종 방어선 유지 조건은 C 지도 옥좌 두 문에 적이 도달하지 않고 승리한 경우로 구체화했다. 갑옷은 레온 전투 종료 시 실제 재조립 회복을 마치고 살아 있으면 승패와 무관하게 판정한다. 바티는 서로 다른 문장 100개가 아니라 실제 읽고 넘긴 100회다.
- Windows x64만 이번 공식 바이너리/내보내기 검증 대상이다. macOS/Linux/웹의 Steam 지원이나 실제 Steamworks CSV import 성공은 검증하지 않았다.
- 개발 리셋은 업적 프로필/stat만 지운다. 캠페인 저장의 엔딩/기억 등은 보존되므로 이어하기 시 다시 소급되는 것이 정상이다. 완전 초기 상태 시험은 격리 폴더의 새 캠페인으로 한다.

## 8. 사용자 PC의 실제 Steam 해제 확인 절차

1. Steamworks 앱 **5267750**에서 stat 20개를 `stats.csv`와 같은 API 이름/INT/Client/증가 전용 조건으로 등록한다. 실제 7개 추가 세트를 만들거나 기존 ID를 확인하고 `set_ids.template.json`의 **복사본**에 채운다. 기본 캠페인은 기본 세트를 쓴다. 이 단계는 사용자가 수행하며 이번 세션에서는 하지 않았다.
2. `python tools/achievements/prepare_steam_import.py --set-ids <실제ID복사본.json> --output <검토폴더>/5267750-achievements-definitions.csv`로 로컬 정의 100행을 만든다. 같은 폴더의 현지화 CSV, 아이콘 100개와 함께 검토한다. 템플릿의 미확인 ID를 그대로 업로드하지 않는다. Steamworks에서 숨김 8개/이름/언어/stat를 확인하고 **사용자가** 저장·게시한다. 자동 잠김 이미지 옵션을 선택한다.
3. 개발 권한/라이선스가 있는 Steam 계정으로 클라이언트를 온라인 실행한다. 이 저장소의 개발 실행에는 루트 `steam_appid.txt=5267750`이 있지만 export에는 포함되지 않는다. 실제 배포본은 Steam 라이브러리에서 실행한다.
4. 사용자 원본 저장을 보존하기 위해 테스트는 별도 폴더를 사용한다. PowerShell에서 프로젝트 안 `tmp/steam_ach_user_test/` 아래를 APPDATA/LOCALAPPDATA로 지정한 뒤 개발 Godot를 한 개만 실행한다. 원래 환경 변수는 종료 후 복원한다. 시험할 기존 세이브가 필요하면 해당 격리 폴더에 **복사본만** 넣는다. 첫 해제 확인에는 새 캠페인을 권장한다.
5. 개발 빌드의 로컬 업적만 초기화하려면 Godot 사용자 인수 `--ach-reset-local`을 사용한다. 실제 테스트 계정의 Steam stat/업적까지 초기화할 때만 `--ach-reset-steam`을 선택한다. 이 명령은 디버그에서만 동작하며 이번 세션에서 실제 계정 대상으로 실행하지 않았다. 재사용 캠페인은 소급되므로 새 캠페인으로 시험한다.
6. Godot 편집기의 Remote 트리에서 AchievementService의 `bridge.initialized=true`, `bridge.stats_available=true`를 확인한다. false면 App ID/Steam 로그인/라이선스/게시된 API 이름과 Steam의 `logs/stats_log.txt`를 확인한다. 게임 타이틀은 실패 상태에서도 계속 동작해야 한다.
7. 새 캠페인 DAY1을 자연 승리한다. 게임 토스트와 Steam 오버레이에서 **ACH_FIRST_NIGHT** 하나가 해제됐는지 확인한다. 격리 폴더의 achievements_v130.json에서 같은 ID가 unlocked에 있고, 저장 확인 콜백 이후 pending에서 사라지는지도 확인한다. 다시 실행해 같은 토스트/해제가 반복되지 않는지 본다.
8. 진행도 시험은 같은 격리 캠페인에서 함정을 설치하고 Steam stat `STAT_TRAPS_PLACED`와 게임의 진행도를 비교한다. 50 미만은 진행도 표시, 50은 해제다. 중간 알림 자체가 해제를 뜻하지 않는다.
9. 재전송 시험은 아직 달성하지 않은 **DAY3**을 대상으로 한다. Steam을 닫거나 오프라인으로 전환하고 DAY3을 이긴 뒤 종료한다. 로컬 ACH_HERO_TRAINEE 기록을 확인하고 Steam을 온라인으로 연 다음 게임을 다시 실행해 전송/클라이언트 해제를 확인한다. 오프라인 Steam SDK가 자체 캐시에 성공 저장했다고 응답하면 Steam 클라이언트가 온라인 때 동기화할 수도 있다.
10. Steam 해제 화면과 타이틀/토스트 결과를 사용자 판단으로 확인한 뒤 게임을 종료한다. Godot가 0개인지 확인한다. 성공/실패를 이 인계서의 후속 기록에 남기며, 에이전트가 업로드나 공개 게시를 대신 완료한 것으로 취급하지 않는다.

## 9. 작업 트리 상태

기존 대량 .import 변경과 다른 단계의 로컬 산출물을 되돌리거나 함께 커밋하지 않는다. 이번 소스/공식 addon/자산/검수 MD만 명시적으로 스테이징한다. 로컬 빌드는 `tmp/v130r_step13/export/`, 실행 로그/격리 저장은 `tmp/v130r_step13/`, 축소 캡처와 원시 JSON은 `_mockup/game_step13_ach/`에 있다. 정확한 최종 커밋/정책 검사/종료 프로세스 결과는 종료 기록으로 덧붙인다.

## 10. 종료 체크리스트

- 로컬 커밋만, 영어 메시지. push/태그/Steam 업로드/main 변경 0.
- 실제 사용자 세이브 접근/수정 0. 시험 복사본 해시 불변 검사.
- Godot 동시 최대 1. 종료 시 0 확인.
- 100개 직접 조건과 요청 화면/오프라인/소급/Windows export 검사를 완료한 뒤에만 종료 수치를 기록.
- 사용자 확인 대기.

## 최종 실행 기록

- 직접 636 / 실제 Steam 없는 실행 640 / 화면·실전 649 / 산출물 631 검사 모두 실패 0. 모든 모드에서 100개 판정 전수 실행. 최종 stderr 비어 있음.
- Windows Desktop release export와 실제 release EXE headless 60프레임 부팅 종료 0. PCK 색인 5024항목, DLL 2개 해시 일치, App ID 파일/원본/검수 자료 없음.
- 공식 vendor manifest 해시 및 LF checkout 속성 재검사 통과. 신규 프레임은 native alpha 0~255 확인.
- 실제 마지막 자연 DAY1: 시드 130013, 84.32전투초, 침입자5/함정적중3/스킬11/금고손실0/승리. 승패 주입 없음. 초기 미고정 1패는 위 재현성 한계에 기록했다.
- 기존 추적 .import 미커밋 1307개를 남겼고 이번 구현의 미커밋 추적 파일은 없다. 캡처/JSON/로그/시험 저장/빌드는 로컬에 보존한다.
- Godot/MawangCastle 프로세스 종료 0개, 동시 최대 1. 사용자 원본 저장 미접근/미수정. push/PR/태그/Steam 업로드/main 변경 0.
- repository-policy: PASS. `ValidateRepositoryPolicy.ps1 -BaseRef 82fec09596abd45bf2c0b723d6a0ab9f96d7720b -HeadRef codex/v130r-defense-layout`를 문서 커밋 cbcdcebb에서 실행해 최종 677경로/3커밋을 검사했다. 이후에는 이 정책 결과를 기록하는 docs/handoff/ 문서만 변경한다. Reviewed SHA의 제품 내용은 그대로다.
- **사용자 확인 대기.**

<details>
<summary>정확한 제품 변경 파일 675개</summary>

```text
.gitattributes
_mockup/game_step13_ach/export_dll_check.md
_mockup/game_step13_ach/offline_test.md
_mockup/game_step13_ach/retro_unlock_test.md
_mockup/game_step13_ach/unit_tests.md
addons/godotsteam/PROVENANCE.json
addons/godotsteam/README.md
addons/godotsteam/godotsteam.gdextension
addons/godotsteam/godotsteam.gdextension.uid
addons/godotsteam/license.md
addons/godotsteam/win64/libgodotsteam.windows.template_debug.x86_64.dll
addons/godotsteam/win64/libgodotsteam.windows.template_release.x86_64.dll
addons/godotsteam/win64/steam_api64.dll
addons/steam_release_export_filter/steam_release_export_filter.gd
assets/achievements/v130/icons/ACH_100_ACHIEVED.png
assets/achievements/v130/icons/ACH_100_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_ALL_BARKS_ACHIEVED.png
assets/achievements/v130/icons/ACH_ALL_BARKS_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_ALL_DUOS_ACHIEVED.png
assets/achievements/v130/icons/ACH_ALL_DUOS_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_ALL_FACILITIES_ALIVE_ACHIEVED.png
assets/achievements/v130/icons/ACH_ALL_FACILITIES_ALIVE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_ALL_MEMORIES_ACHIEVED.png
assets/achievements/v130/icons/ACH_ALL_MEMORIES_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_BUILD_ALL5_ACHIEVED.png
assets/achievements/v130/icons/ACH_BUILD_ALL5_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_BUILD_FIRST_ACHIEVED.png
assets/achievements/v130/icons/ACH_BUILD_FIRST_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_BUILD_MAX_ACHIEVED.png
assets/achievements/v130/icons/ACH_BUILD_MAX_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_CROWN_CROWN_GOB_MIDNIGHT_MARSHAL_ACHIEVED.png
assets/achievements/v130/icons/ACH_CROWN_CROWN_GOB_MIDNIGHT_MARSHAL_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_CROWN_CROWN_MORI_GRAND_MYCELIAL_PRIEST_ACHIEVED.png
assets/achievements/v130/icons/ACH_CROWN_CROWN_MORI_GRAND_MYCELIAL_PRIEST_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_CROWN_CROWN_POPO_GRAND_NIGHT_COURIER_ACHIEVED.png
assets/achievements/v130/icons/ACH_CROWN_CROWN_POPO_GRAND_NIGHT_COURIER_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION_ACHIEVED.png
assets/achievements/v130/icons/ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_CROWN_CROWN_PYNN_CASTLE_FLAME_SAGE_ACHIEVED.png
assets/achievements/v130/icons/ACH_CROWN_CROWN_PYNN_CASTLE_FLAME_SAGE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_CROWN_CROWN_TOKTOK_ROYAL_ARMORER_ACHIEVED.png
assets/achievements/v130/icons/ACH_CROWN_CROWN_TOKTOK_ROYAL_ARMORER_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_DAY29_ACHIEVED.png
assets/achievements/v130/icons/ACH_DAY29_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END3_ENDING_HOLY_OPEN_GATE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END3_ENDING_HOLY_OPEN_GATE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END3_ENDING_LINKED_CORRIDORS_ACHIEVED.png
assets/achievements/v130/icons/ACH_END3_ENDING_LINKED_CORRIDORS_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END3_ENDING_LIVING_CASTLE_VOICE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END3_ENDING_LIVING_CASTLE_VOICE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END3_ENDING_OFF_LEDGER_INDEPENDENCE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END3_ENDING_OFF_LEDGER_INDEPENDENCE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END3_ENDING_THREE_FRONT_ARMISTICE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END3_ENDING_THREE_FRONT_ARMISTICE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END4_ENDING_COUNCIL_DISSOLVED_ACHIEVED.png
assets/achievements/v130/icons/ACH_END4_ENDING_COUNCIL_DISSOLVED_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END4_ENDING_COUNCIL_SEAT_ACHIEVED.png
assets/achievements/v130/icons/ACH_END4_ENDING_COUNCIL_SEAT_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END4_ENDING_MINION_WEARS_THE_CROWN_ACHIEVED.png
assets/achievements/v130/icons/ACH_END4_ENDING_MINION_WEARS_THE_CROWN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END4_ENDING_OUTPOST_BECOMES_HOME_ACHIEVED.png
assets/achievements/v130/icons/ACH_END4_ENDING_OUTPOST_BECOMES_HOME_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END4_ENDING_THREE_RIVALS_COSIGN_ACHIEVED.png
assets/achievements/v130/icons/ACH_END4_ENDING_THREE_RIVALS_COSIGN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END4_ENDING_TWO_FLOORS_ONE_THRONE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END4_ENDING_TWO_FLOORS_ONE_THRONE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_ADAPTIVE_RIVAL_MASTERY_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_ADAPTIVE_RIVAL_MASTERY_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_CASTLE_WITHOUT_RESERVES_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_CASTLE_WITHOUT_RESERVES_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_CHALLENGE_SEAL_LEGEND_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_CHALLENGE_SEAL_LEGEND_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_CONTRACT_MONSTER_ALLIANCE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_CONTRACT_MONSTER_ALLIANCE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_DEMON_HERO_RIVAL_PACT_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_DEMON_HERO_RIVAL_PACT_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_DREAD_OVERLORD_RISES_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_DREAD_OVERLORD_RISES_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_EVELYNS_COUNTERLEDGER_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_EVELYNS_COUNTERLEDGER_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_IMPREGNABLE_DEMON_CITADEL_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_IMPREGNABLE_DEMON_CITADEL_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_MONSTER_FAMILY_CASTLE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_MONSTER_FAMILY_CASTLE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_ROYAL_DOCTRINE_BROKEN_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_ROYAL_DOCTRINE_BROKEN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_TRUE_DEMON_CASTLE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_TRUE_DEMON_CASTLE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_END_TWELVE_ENDINGS_CHRONICLE_ACHIEVED.png
assets/achievements/v130/icons/ACH_END_TWELVE_ENDINGS_CHRONICLE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_ENGINEERS_ACHIEVED.png
assets/achievements/v130/icons/ACH_ENGINEERS_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FAMILY_10_ACHIEVED.png
assets/achievements/v130/icons/ACH_FAMILY_10_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FAMILY_24_ACHIEVED.png
assets/achievements/v130/icons/ACH_FAMILY_24_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FIRST_DUO_ACHIEVED.png
assets/achievements/v130/icons/ACH_FIRST_DUO_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FIRST_JOIN_SCENE_ACHIEVED.png
assets/achievements/v130/icons/ACH_FIRST_JOIN_SCENE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FIRST_MEMORY_ACHIEVED.png
assets/achievements/v130/icons/ACH_FIRST_MEMORY_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FIRST_NIGHT_ACHIEVED.png
assets/achievements/v130/icons/ACH_FIRST_NIGHT_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FIRST_SPEC_ACHIEVED.png
assets/achievements/v130/icons/ACH_FIRST_SPEC_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FRONT_FRONT_GUILD_REPOSSESSION_ACHIEVED.png
assets/achievements/v130/icons/ACH_FRONT_FRONT_GUILD_REPOSSESSION_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FRONT_FRONT_HERO_OATH_ACHIEVED.png
assets/achievements/v130/icons/ACH_FRONT_FRONT_HERO_OATH_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FRONT_FRONT_HOLY_PURIFICATION_ACHIEVED.png
assets/achievements/v130/icons/ACH_FRONT_FRONT_HOLY_PURIFICATION_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_FULL_HOUSE_ACHIEVED.png
assets/achievements/v130/icons/ACH_FULL_HOUSE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_GATE_BRIDGE_ACHIEVED.png
assets/achievements/v130/icons/ACH_GATE_BRIDGE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_GRADE_C_ACHIEVED.png
assets/achievements/v130/icons/ACH_GRADE_C_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_GRADE_D_ACHIEVED.png
assets/achievements/v130/icons/ACH_GRADE_D_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_GRADE_E_ACHIEVED.png
assets/achievements/v130/icons/ACH_GRADE_E_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_HERO_TRAINEE_ACHIEVED.png
assets/achievements/v130/icons/ACH_HERO_TRAINEE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_LEON_ACHIEVED.png
assets/achievements/v130/icons/ACH_LEON_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_LEVEL_10_ACHIEVED.png
assets/achievements/v130/icons/ACH_LEVEL_10_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_MILO_ACHIEVED.png
assets/achievements/v130/icons/ACH_MILO_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_MOVE_BUILDING_ACHIEVED.png
assets/achievements/v130/icons/ACH_MOVE_BUILDING_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_ARMOR_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_ARMOR_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_DOLL_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_DOLL_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_FROG_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_FROG_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_GOB_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_GOB_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_MAP_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_MAP_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_MOLE_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_MOLE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_PUDDING_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_PUDDING_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_PYNN_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_PYNN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_RATS_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_RATS_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_ROLO_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_ROLO_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_SHADOW_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_SHADOW_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_SNAIL_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_SNAIL_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_TROLL_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_TROLL_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_M_WISP_ACHIEVED.png
assets/achievements/v130/icons/ACH_M_WISP_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_NIA_ACHIEVED.png
assets/achievements/v130/icons/ACH_NIA_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_NO_HUNGER_ACHIEVED.png
assets/achievements/v130/icons/ACH_NO_HUNGER_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_NO_THRONE_DMG_ACHIEVED.png
assets/achievements/v130/icons/ACH_NO_THRONE_DMG_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_PERFECT_CAMPAIGN_ACHIEVED.png
assets/achievements/v130/icons/ACH_PERFECT_CAMPAIGN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_ROMAN_ACHIEVED.png
assets/achievements/v130/icons/ACH_ROMAN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SEAL_ADAPTIVE_ACHIEVED.png
assets/achievements/v130/icons/ACH_SEAL_ADAPTIVE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SEAL_CONTRACT_VANGUARD_ACHIEVED.png
assets/achievements/v130/icons/ACH_SEAL_CONTRACT_VANGUARD_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SEAL_LOW_MANA_ACHIEVED.png
assets/achievements/v130/icons/ACH_SEAL_LOW_MANA_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SEAL_NO_DISABLE_ACHIEVED.png
assets/achievements/v130/icons/ACH_SEAL_NO_DISABLE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SEAL_NO_DOWN_ACHIEVED.png
assets/achievements/v130/icons/ACH_SEAL_NO_DOWN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SEAL_NO_THRONE_ACHIEVED.png
assets/achievements/v130/icons/ACH_SEAL_NO_THRONE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SECRET_37_ACHIEVED.png
assets/achievements/v130/icons/ACH_SECRET_37_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SECRET_ALL_IN_ONE_ACHIEVED.png
assets/achievements/v130/icons/ACH_SECRET_ALL_IN_ONE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SECRET_BATI_ACHIEVED.png
assets/achievements/v130/icons/ACH_SECRET_BATI_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SECRET_BUCKET_ACHIEVED.png
assets/achievements/v130/icons/ACH_SECRET_BUCKET_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SECRET_DIRECT_LEON_ACHIEVED.png
assets/achievements/v130/icons/ACH_SECRET_DIRECT_LEON_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SECRET_HUNGRY_WIN_ACHIEVED.png
assets/achievements/v130/icons/ACH_SECRET_HUNGRY_WIN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SECRET_ZERO_FOOD_ACHIEVED.png
assets/achievements/v130/icons/ACH_SECRET_ZERO_FOOD_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SELEN_ACHIEVED.png
assets/achievements/v130/icons/ACH_SELEN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SPEC_24_ACHIEVED.png
assets/achievements/v130/icons/ACH_SPEC_24_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SPEED_X3_WIN_ACHIEVED.png
assets/achievements/v130/icons/ACH_SPEED_X3_WIN_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_SPLIT_DEFENSE_ACHIEVED.png
assets/achievements/v130/icons/ACH_SPLIT_DEFENSE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_STONE_BRIDGE_ACHIEVED.png
assets/achievements/v130/icons/ACH_STONE_BRIDGE_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_THIEF_DENIED_ACHIEVED.png
assets/achievements/v130/icons/ACH_THIEF_DENIED_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_TRAPS_50_ACHIEVED.png
assets/achievements/v130/icons/ACH_TRAPS_50_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_TRAP_KILLS_100_ACHIEVED.png
assets/achievements/v130/icons/ACH_TRAP_KILLS_100_ACHIEVED.png.import
assets/achievements/v130/icons/ACH_VAULT_1000_ACHIEVED.png
assets/achievements/v130/icons/ACH_VAULT_1000_ACHIEVED.png.import
assets/achievements/v130/icons_jpg/ACH_100_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_100_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_ALL_BARKS_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_ALL_BARKS_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_ALL_DUOS_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_ALL_DUOS_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_ALL_FACILITIES_ALIVE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_ALL_FACILITIES_ALIVE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_ALL_MEMORIES_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_ALL_MEMORIES_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_BUILD_ALL5_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_BUILD_ALL5_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_BUILD_FIRST_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_BUILD_FIRST_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_BUILD_MAX_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_BUILD_MAX_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_GOB_MIDNIGHT_MARSHAL_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_GOB_MIDNIGHT_MARSHAL_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_MORI_GRAND_MYCELIAL_PRIEST_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_MORI_GRAND_MYCELIAL_PRIEST_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_POPO_GRAND_NIGHT_COURIER_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_POPO_GRAND_NIGHT_COURIER_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_PYNN_CASTLE_FLAME_SAGE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_PYNN_CASTLE_FLAME_SAGE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_TOKTOK_ROYAL_ARMORER_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_CROWN_CROWN_TOKTOK_ROYAL_ARMORER_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_DAY29_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_DAY29_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_HOLY_OPEN_GATE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_HOLY_OPEN_GATE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_LINKED_CORRIDORS_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_LINKED_CORRIDORS_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_LIVING_CASTLE_VOICE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_LIVING_CASTLE_VOICE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_OFF_LEDGER_INDEPENDENCE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_OFF_LEDGER_INDEPENDENCE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_THREE_FRONT_ARMISTICE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END3_ENDING_THREE_FRONT_ARMISTICE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_COUNCIL_DISSOLVED_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_COUNCIL_DISSOLVED_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_COUNCIL_SEAT_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_COUNCIL_SEAT_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_MINION_WEARS_THE_CROWN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_MINION_WEARS_THE_CROWN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_OUTPOST_BECOMES_HOME_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_OUTPOST_BECOMES_HOME_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_THREE_RIVALS_COSIGN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_THREE_RIVALS_COSIGN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_TWO_FLOORS_ONE_THRONE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END4_ENDING_TWO_FLOORS_ONE_THRONE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_ADAPTIVE_RIVAL_MASTERY_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_ADAPTIVE_RIVAL_MASTERY_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_CASTLE_WITHOUT_RESERVES_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_CASTLE_WITHOUT_RESERVES_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_CHALLENGE_SEAL_LEGEND_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_CHALLENGE_SEAL_LEGEND_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_CONTRACT_MONSTER_ALLIANCE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_CONTRACT_MONSTER_ALLIANCE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_DEMON_HERO_RIVAL_PACT_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_DEMON_HERO_RIVAL_PACT_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_DREAD_OVERLORD_RISES_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_DREAD_OVERLORD_RISES_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_EVELYNS_COUNTERLEDGER_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_EVELYNS_COUNTERLEDGER_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_IMPREGNABLE_DEMON_CITADEL_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_IMPREGNABLE_DEMON_CITADEL_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_MONSTER_FAMILY_CASTLE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_MONSTER_FAMILY_CASTLE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_ROYAL_DOCTRINE_BROKEN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_ROYAL_DOCTRINE_BROKEN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_TRUE_DEMON_CASTLE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_TRUE_DEMON_CASTLE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_END_TWELVE_ENDINGS_CHRONICLE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_END_TWELVE_ENDINGS_CHRONICLE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_ENGINEERS_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_ENGINEERS_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FAMILY_10_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FAMILY_10_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FAMILY_24_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FAMILY_24_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FIRST_DUO_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FIRST_DUO_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FIRST_JOIN_SCENE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FIRST_JOIN_SCENE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FIRST_MEMORY_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FIRST_MEMORY_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FIRST_NIGHT_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FIRST_NIGHT_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FIRST_SPEC_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FIRST_SPEC_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FRONT_FRONT_GUILD_REPOSSESSION_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FRONT_FRONT_GUILD_REPOSSESSION_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FRONT_FRONT_HERO_OATH_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FRONT_FRONT_HERO_OATH_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FRONT_FRONT_HOLY_PURIFICATION_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FRONT_FRONT_HOLY_PURIFICATION_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_FULL_HOUSE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_FULL_HOUSE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_GATE_BRIDGE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_GATE_BRIDGE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_GRADE_C_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_GRADE_C_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_GRADE_D_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_GRADE_D_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_GRADE_E_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_GRADE_E_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_HERO_TRAINEE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_HERO_TRAINEE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_LEON_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_LEON_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_LEVEL_10_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_LEVEL_10_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_MILO_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_MILO_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_MOVE_BUILDING_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_MOVE_BUILDING_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_ARMOR_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_ARMOR_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_DOLL_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_DOLL_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_FROG_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_FROG_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_GOB_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_GOB_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_MAP_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_MAP_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_MOLE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_MOLE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_PUDDING_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_PUDDING_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_PYNN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_PYNN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_RATS_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_RATS_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_ROLO_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_ROLO_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_SHADOW_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_SHADOW_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_SNAIL_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_SNAIL_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_TROLL_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_TROLL_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_M_WISP_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_M_WISP_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_NIA_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_NIA_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_NO_HUNGER_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_NO_HUNGER_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_NO_THRONE_DMG_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_NO_THRONE_DMG_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_PERFECT_CAMPAIGN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_PERFECT_CAMPAIGN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_ROMAN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_ROMAN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SEAL_ADAPTIVE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SEAL_ADAPTIVE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SEAL_CONTRACT_VANGUARD_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SEAL_CONTRACT_VANGUARD_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SEAL_LOW_MANA_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SEAL_LOW_MANA_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SEAL_NO_DISABLE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SEAL_NO_DISABLE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SEAL_NO_DOWN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SEAL_NO_DOWN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SEAL_NO_THRONE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SEAL_NO_THRONE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SECRET_37_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SECRET_37_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SECRET_ALL_IN_ONE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SECRET_ALL_IN_ONE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SECRET_BATI_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SECRET_BATI_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SECRET_BUCKET_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SECRET_BUCKET_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SECRET_DIRECT_LEON_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SECRET_DIRECT_LEON_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SECRET_HUNGRY_WIN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SECRET_HUNGRY_WIN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SECRET_ZERO_FOOD_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SECRET_ZERO_FOOD_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SELEN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SELEN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SPEC_24_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SPEC_24_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SPEED_X3_WIN_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SPEED_X3_WIN_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_SPLIT_DEFENSE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_SPLIT_DEFENSE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_STONE_BRIDGE_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_STONE_BRIDGE_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_THIEF_DENIED_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_THIEF_DENIED_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_TRAPS_50_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_TRAPS_50_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_TRAP_KILLS_100_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_TRAP_KILLS_100_ACHIEVED.jpg.import
assets/achievements/v130/icons_jpg/ACH_VAULT_1000_ACHIEVED.jpg
assets/achievements/v130/icons_jpg/ACH_VAULT_1000_ACHIEVED.jpg.import
assets/achievements/v130/toast_frame.png
assets/achievements/v130/toast_frame.png.import
assets/source/imagegen/achievements_v130/SOURCE.md
assets/source/imagegen/achievements_v130/design/ACHIEVEMENTS_v130.md
assets/source/imagegen/achievements_v130/design/achievements_v130.json
assets/source/imagegen/achievements_v130/first_prompt.txt
assets/source/imagegen/achievements_v130/jobs.json
assets/source/imagegen/achievements_v130/localization.tsv
assets/source/imagegen/achievements_v130/originals/ACH_100.png
assets/source/imagegen/achievements_v130/originals/ACH_ALL_BARKS.png
assets/source/imagegen/achievements_v130/originals/ACH_ALL_DUOS.png
assets/source/imagegen/achievements_v130/originals/ACH_ALL_FACILITIES_ALIVE.png
assets/source/imagegen/achievements_v130/originals/ACH_ALL_MEMORIES.png
assets/source/imagegen/achievements_v130/originals/ACH_BUILD_ALL5.png
assets/source/imagegen/achievements_v130/originals/ACH_BUILD_FIRST.png
assets/source/imagegen/achievements_v130/originals/ACH_BUILD_MAX.png
assets/source/imagegen/achievements_v130/originals/ACH_CROWN_CROWN_GOB_MIDNIGHT_MARSHAL.png
assets/source/imagegen/achievements_v130/originals/ACH_CROWN_CROWN_MORI_GRAND_MYCELIAL_PRIEST.png
assets/source/imagegen/achievements_v130/originals/ACH_CROWN_CROWN_POPO_GRAND_NIGHT_COURIER.png
assets/source/imagegen/achievements_v130/originals/ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION.png
assets/source/imagegen/achievements_v130/originals/ACH_CROWN_CROWN_PYNN_CASTLE_FLAME_SAGE.png
assets/source/imagegen/achievements_v130/originals/ACH_CROWN_CROWN_TOKTOK_ROYAL_ARMORER.png
assets/source/imagegen/achievements_v130/originals/ACH_DAY29.png
assets/source/imagegen/achievements_v130/originals/ACH_END3_ENDING_HOLY_OPEN_GATE.png
assets/source/imagegen/achievements_v130/originals/ACH_END3_ENDING_LINKED_CORRIDORS.png
assets/source/imagegen/achievements_v130/originals/ACH_END3_ENDING_LIVING_CASTLE_VOICE.png
assets/source/imagegen/achievements_v130/originals/ACH_END3_ENDING_OFF_LEDGER_INDEPENDENCE.png
assets/source/imagegen/achievements_v130/originals/ACH_END3_ENDING_THREE_FRONT_ARMISTICE.png
assets/source/imagegen/achievements_v130/originals/ACH_END4_ENDING_COUNCIL_DISSOLVED.png
assets/source/imagegen/achievements_v130/originals/ACH_END4_ENDING_COUNCIL_SEAT.png
assets/source/imagegen/achievements_v130/originals/ACH_END4_ENDING_MINION_WEARS_THE_CROWN.png
assets/source/imagegen/achievements_v130/originals/ACH_END4_ENDING_OUTPOST_BECOMES_HOME.png
assets/source/imagegen/achievements_v130/originals/ACH_END4_ENDING_THREE_RIVALS_COSIGN.png
assets/source/imagegen/achievements_v130/originals/ACH_END4_ENDING_TWO_FLOORS_ONE_THRONE.png
assets/source/imagegen/achievements_v130/originals/ACH_END_ADAPTIVE_RIVAL_MASTERY.png
assets/source/imagegen/achievements_v130/originals/ACH_END_CASTLE_WITHOUT_RESERVES.png
assets/source/imagegen/achievements_v130/originals/ACH_END_CHALLENGE_SEAL_LEGEND.png
assets/source/imagegen/achievements_v130/originals/ACH_END_CONTRACT_MONSTER_ALLIANCE.png
assets/source/imagegen/achievements_v130/originals/ACH_END_DEMON_HERO_RIVAL_PACT.png
assets/source/imagegen/achievements_v130/originals/ACH_END_DREAD_OVERLORD_RISES.png
assets/source/imagegen/achievements_v130/originals/ACH_END_EVELYNS_COUNTERLEDGER.png
assets/source/imagegen/achievements_v130/originals/ACH_END_IMPREGNABLE_DEMON_CITADEL.png
assets/source/imagegen/achievements_v130/originals/ACH_END_MONSTER_FAMILY_CASTLE.png
assets/source/imagegen/achievements_v130/originals/ACH_END_ROYAL_DOCTRINE_BROKEN.png
assets/source/imagegen/achievements_v130/originals/ACH_END_TRUE_DEMON_CASTLE.png
assets/source/imagegen/achievements_v130/originals/ACH_END_TWELVE_ENDINGS_CHRONICLE.png
assets/source/imagegen/achievements_v130/originals/ACH_ENGINEERS.png
assets/source/imagegen/achievements_v130/originals/ACH_FAMILY_10.png
assets/source/imagegen/achievements_v130/originals/ACH_FAMILY_24.png
assets/source/imagegen/achievements_v130/originals/ACH_FIRST_DUO.png
assets/source/imagegen/achievements_v130/originals/ACH_FIRST_JOIN_SCENE.png
assets/source/imagegen/achievements_v130/originals/ACH_FIRST_MEMORY.png
assets/source/imagegen/achievements_v130/originals/ACH_FIRST_NIGHT.png
assets/source/imagegen/achievements_v130/originals/ACH_FIRST_SPEC.png
assets/source/imagegen/achievements_v130/originals/ACH_FRONT_FRONT_GUILD_REPOSSESSION.png
assets/source/imagegen/achievements_v130/originals/ACH_FRONT_FRONT_HERO_OATH.png
assets/source/imagegen/achievements_v130/originals/ACH_FRONT_FRONT_HOLY_PURIFICATION.png
assets/source/imagegen/achievements_v130/originals/ACH_FULL_HOUSE.png
assets/source/imagegen/achievements_v130/originals/ACH_GATE_BRIDGE.png
assets/source/imagegen/achievements_v130/originals/ACH_GRADE_C.png
assets/source/imagegen/achievements_v130/originals/ACH_GRADE_D.png
assets/source/imagegen/achievements_v130/originals/ACH_GRADE_E.png
assets/source/imagegen/achievements_v130/originals/ACH_HERO_TRAINEE.png
assets/source/imagegen/achievements_v130/originals/ACH_LEON.png
assets/source/imagegen/achievements_v130/originals/ACH_LEVEL_10.png
assets/source/imagegen/achievements_v130/originals/ACH_MILO.png
assets/source/imagegen/achievements_v130/originals/ACH_MOVE_BUILDING.png
assets/source/imagegen/achievements_v130/originals/ACH_M_ARMOR.png
assets/source/imagegen/achievements_v130/originals/ACH_M_DOLL.png
assets/source/imagegen/achievements_v130/originals/ACH_M_FROG.png
assets/source/imagegen/achievements_v130/originals/ACH_M_GOB.png
assets/source/imagegen/achievements_v130/originals/ACH_M_MAP.png
assets/source/imagegen/achievements_v130/originals/ACH_M_MOLE.png
assets/source/imagegen/achievements_v130/originals/ACH_M_PUDDING.png
assets/source/imagegen/achievements_v130/originals/ACH_M_PYNN.png
assets/source/imagegen/achievements_v130/originals/ACH_M_RATS.png
assets/source/imagegen/achievements_v130/originals/ACH_M_ROLO.png
assets/source/imagegen/achievements_v130/originals/ACH_M_SHADOW.png
assets/source/imagegen/achievements_v130/originals/ACH_M_SNAIL.png
assets/source/imagegen/achievements_v130/originals/ACH_M_TROLL.png
assets/source/imagegen/achievements_v130/originals/ACH_M_WISP.png
assets/source/imagegen/achievements_v130/originals/ACH_NIA.png
assets/source/imagegen/achievements_v130/originals/ACH_NO_HUNGER.png
assets/source/imagegen/achievements_v130/originals/ACH_NO_THRONE_DMG.png
assets/source/imagegen/achievements_v130/originals/ACH_PERFECT_CAMPAIGN.png
assets/source/imagegen/achievements_v130/originals/ACH_ROMAN.png
assets/source/imagegen/achievements_v130/originals/ACH_SEAL_ADAPTIVE.png
assets/source/imagegen/achievements_v130/originals/ACH_SEAL_CONTRACT_VANGUARD.png
assets/source/imagegen/achievements_v130/originals/ACH_SEAL_LOW_MANA.png
assets/source/imagegen/achievements_v130/originals/ACH_SEAL_NO_DISABLE.png
assets/source/imagegen/achievements_v130/originals/ACH_SEAL_NO_DOWN.png
assets/source/imagegen/achievements_v130/originals/ACH_SEAL_NO_THRONE.png
assets/source/imagegen/achievements_v130/originals/ACH_SECRET_37.png
assets/source/imagegen/achievements_v130/originals/ACH_SECRET_ALL_IN_ONE.png
assets/source/imagegen/achievements_v130/originals/ACH_SECRET_BATI.png
assets/source/imagegen/achievements_v130/originals/ACH_SECRET_BUCKET.png
assets/source/imagegen/achievements_v130/originals/ACH_SECRET_DIRECT_LEON.png
assets/source/imagegen/achievements_v130/originals/ACH_SECRET_HUNGRY_WIN.png
assets/source/imagegen/achievements_v130/originals/ACH_SECRET_ZERO_FOOD.png
assets/source/imagegen/achievements_v130/originals/ACH_SELEN.png
assets/source/imagegen/achievements_v130/originals/ACH_SPEC_24.png
assets/source/imagegen/achievements_v130/originals/ACH_SPEED_X3_WIN.png
assets/source/imagegen/achievements_v130/originals/ACH_SPLIT_DEFENSE.png
assets/source/imagegen/achievements_v130/originals/ACH_STONE_BRIDGE.png
assets/source/imagegen/achievements_v130/originals/ACH_THIEF_DENIED.png
assets/source/imagegen/achievements_v130/originals/ACH_TRAPS_50.png
assets/source/imagegen/achievements_v130/originals/ACH_TRAP_KILLS_100.png
assets/source/imagegen/achievements_v130/originals/ACH_VAULT_1000.png
assets/source/imagegen/achievements_v130/receipts/ACH_100.json
assets/source/imagegen/achievements_v130/receipts/ACH_ALL_BARKS.json
assets/source/imagegen/achievements_v130/receipts/ACH_ALL_DUOS.json
assets/source/imagegen/achievements_v130/receipts/ACH_ALL_FACILITIES_ALIVE.json
assets/source/imagegen/achievements_v130/receipts/ACH_ALL_MEMORIES.json
assets/source/imagegen/achievements_v130/receipts/ACH_BUILD_ALL5.json
assets/source/imagegen/achievements_v130/receipts/ACH_BUILD_FIRST.json
assets/source/imagegen/achievements_v130/receipts/ACH_BUILD_MAX.json
assets/source/imagegen/achievements_v130/receipts/ACH_CROWN_CROWN_GOB_MIDNIGHT_MARSHAL.json
assets/source/imagegen/achievements_v130/receipts/ACH_CROWN_CROWN_MORI_GRAND_MYCELIAL_PRIEST.json
assets/source/imagegen/achievements_v130/receipts/ACH_CROWN_CROWN_POPO_GRAND_NIGHT_COURIER.json
assets/source/imagegen/achievements_v130/receipts/ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION.json
assets/source/imagegen/achievements_v130/receipts/ACH_CROWN_CROWN_PYNN_CASTLE_FLAME_SAGE.json
assets/source/imagegen/achievements_v130/receipts/ACH_CROWN_CROWN_TOKTOK_ROYAL_ARMORER.json
assets/source/imagegen/achievements_v130/receipts/ACH_DAY29.json
assets/source/imagegen/achievements_v130/receipts/ACH_END3_ENDING_HOLY_OPEN_GATE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END3_ENDING_LINKED_CORRIDORS.json
assets/source/imagegen/achievements_v130/receipts/ACH_END3_ENDING_LIVING_CASTLE_VOICE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END3_ENDING_OFF_LEDGER_INDEPENDENCE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END3_ENDING_THREE_FRONT_ARMISTICE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END4_ENDING_COUNCIL_DISSOLVED.json
assets/source/imagegen/achievements_v130/receipts/ACH_END4_ENDING_COUNCIL_SEAT.json
assets/source/imagegen/achievements_v130/receipts/ACH_END4_ENDING_MINION_WEARS_THE_CROWN.json
assets/source/imagegen/achievements_v130/receipts/ACH_END4_ENDING_OUTPOST_BECOMES_HOME.json
assets/source/imagegen/achievements_v130/receipts/ACH_END4_ENDING_THREE_RIVALS_COSIGN.json
assets/source/imagegen/achievements_v130/receipts/ACH_END4_ENDING_TWO_FLOORS_ONE_THRONE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_ADAPTIVE_RIVAL_MASTERY.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_CASTLE_WITHOUT_RESERVES.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_CHALLENGE_SEAL_LEGEND.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_CONTRACT_MONSTER_ALLIANCE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_DEMON_HERO_RIVAL_PACT.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_DREAD_OVERLORD_RISES.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_EVELYNS_COUNTERLEDGER.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_IMPREGNABLE_DEMON_CITADEL.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_MONSTER_FAMILY_CASTLE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_ROYAL_DOCTRINE_BROKEN.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_TRUE_DEMON_CASTLE.json
assets/source/imagegen/achievements_v130/receipts/ACH_END_TWELVE_ENDINGS_CHRONICLE.json
assets/source/imagegen/achievements_v130/receipts/ACH_ENGINEERS.json
assets/source/imagegen/achievements_v130/receipts/ACH_FAMILY_10.json
assets/source/imagegen/achievements_v130/receipts/ACH_FAMILY_24.json
assets/source/imagegen/achievements_v130/receipts/ACH_FIRST_DUO.json
assets/source/imagegen/achievements_v130/receipts/ACH_FIRST_JOIN_SCENE.json
assets/source/imagegen/achievements_v130/receipts/ACH_FIRST_MEMORY.json
assets/source/imagegen/achievements_v130/receipts/ACH_FIRST_NIGHT.json
assets/source/imagegen/achievements_v130/receipts/ACH_FIRST_SPEC.json
assets/source/imagegen/achievements_v130/receipts/ACH_FRONT_FRONT_GUILD_REPOSSESSION.json
assets/source/imagegen/achievements_v130/receipts/ACH_FRONT_FRONT_HERO_OATH.json
assets/source/imagegen/achievements_v130/receipts/ACH_FRONT_FRONT_HOLY_PURIFICATION.json
assets/source/imagegen/achievements_v130/receipts/ACH_FULL_HOUSE.json
assets/source/imagegen/achievements_v130/receipts/ACH_GATE_BRIDGE.json
assets/source/imagegen/achievements_v130/receipts/ACH_GRADE_C.json
assets/source/imagegen/achievements_v130/receipts/ACH_GRADE_D.json
assets/source/imagegen/achievements_v130/receipts/ACH_GRADE_E.json
assets/source/imagegen/achievements_v130/receipts/ACH_HERO_TRAINEE.json
assets/source/imagegen/achievements_v130/receipts/ACH_LEON.json
assets/source/imagegen/achievements_v130/receipts/ACH_LEVEL_10.json
assets/source/imagegen/achievements_v130/receipts/ACH_MILO.json
assets/source/imagegen/achievements_v130/receipts/ACH_MOVE_BUILDING.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_ARMOR.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_DOLL.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_FROG.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_GOB.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_MAP.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_MOLE.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_PUDDING.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_PYNN.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_RATS.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_ROLO.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_SHADOW.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_SNAIL.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_TROLL.json
assets/source/imagegen/achievements_v130/receipts/ACH_M_WISP.json
assets/source/imagegen/achievements_v130/receipts/ACH_NIA.json
assets/source/imagegen/achievements_v130/receipts/ACH_NO_HUNGER.json
assets/source/imagegen/achievements_v130/receipts/ACH_NO_THRONE_DMG.json
assets/source/imagegen/achievements_v130/receipts/ACH_PERFECT_CAMPAIGN.json
assets/source/imagegen/achievements_v130/receipts/ACH_ROMAN.json
assets/source/imagegen/achievements_v130/receipts/ACH_SEAL_ADAPTIVE.json
assets/source/imagegen/achievements_v130/receipts/ACH_SEAL_CONTRACT_VANGUARD.json
assets/source/imagegen/achievements_v130/receipts/ACH_SEAL_LOW_MANA.json
assets/source/imagegen/achievements_v130/receipts/ACH_SEAL_NO_DISABLE.json
assets/source/imagegen/achievements_v130/receipts/ACH_SEAL_NO_DOWN.json
assets/source/imagegen/achievements_v130/receipts/ACH_SEAL_NO_THRONE.json
assets/source/imagegen/achievements_v130/receipts/ACH_SECRET_37.json
assets/source/imagegen/achievements_v130/receipts/ACH_SECRET_ALL_IN_ONE.json
assets/source/imagegen/achievements_v130/receipts/ACH_SECRET_BATI.json
assets/source/imagegen/achievements_v130/receipts/ACH_SECRET_BUCKET.json
assets/source/imagegen/achievements_v130/receipts/ACH_SECRET_DIRECT_LEON.json
assets/source/imagegen/achievements_v130/receipts/ACH_SECRET_HUNGRY_WIN.json
assets/source/imagegen/achievements_v130/receipts/ACH_SECRET_ZERO_FOOD.json
assets/source/imagegen/achievements_v130/receipts/ACH_SELEN.json
assets/source/imagegen/achievements_v130/receipts/ACH_SPEC_24.json
assets/source/imagegen/achievements_v130/receipts/ACH_SPEED_X3_WIN.json
assets/source/imagegen/achievements_v130/receipts/ACH_SPLIT_DEFENSE.json
assets/source/imagegen/achievements_v130/receipts/ACH_STONE_BRIDGE.json
assets/source/imagegen/achievements_v130/receipts/ACH_THIEF_DENIED.json
assets/source/imagegen/achievements_v130/receipts/ACH_TRAPS_50.json
assets/source/imagegen/achievements_v130/receipts/ACH_TRAP_KILLS_100.json
assets/source/imagegen/achievements_v130/receipts/ACH_VAULT_1000.json
assets/source/imagegen/v130r_achievement_toast/SOURCE.md
assets/source/imagegen/v130r_achievement_toast/toast_original.png
data/v130r/achievements/5267750-achievements-definitions.template.csv
data/v130r/achievements/5267750-achievements-definitions.template.csv.import
data/v130r/achievements/5267750-achievements-localization.csv
data/v130r/achievements/5267750-achievements-localization.csv.import
data/v130r/achievements/README.md
data/v130r/achievements/achievements.json
data/v130r/achievements/runtime_rules.json
data/v130r/achievements/set_ids.template.json
data/v130r/achievements/stats.csv
data/v130r/achievements/stats.csv.import
data/v130r/achievements/steamworks_import.csv
data/v130r/achievements/steamworks_import.csv.import
export_presets.cfg
project.godot
scripts/achievements/AchievementGameplay.gd
scripts/achievements/AchievementGameplay.gd.uid
scripts/achievements/AchievementRetro.gd
scripts/achievements/AchievementRetro.gd.uid
scripts/achievements/AchievementRules.gd
scripts/achievements/AchievementRules.gd.uid
scripts/achievements/AchievementScreen.gd
scripts/achievements/AchievementScreen.gd.uid
scripts/achievements/AchievementService.gd
scripts/achievements/AchievementService.gd.uid
scripts/achievements/AchievementToast.gd
scripts/achievements/AchievementToast.gd.uid
scripts/achievements/SteamAchievementBridge.gd
scripts/achievements/SteamAchievementBridge.gd.uid
scripts/combat/V130RMonsterSkills.gd
scripts/core/GameState.gd
scripts/game/ApprovedBattleController.gd
scripts/game/CombatSceneController.gd
scripts/game/GameRoot.gd
scripts/map_builder/ApprovedPlacementView.gd
scripts/map_builder/ApprovedRecruitment.gd
scripts/story/StoryDirector.gd
scripts/story/V130RStoryRuntime.gd
scripts/ui/StartFlow.gd
scripts/ui/TitleWorkspaceUI.gd
scripts/units/Unit.gd
steam_appid.txt
tools/achievements/build_runtime_rules.py
tools/achievements/build_test_fixtures.py
tools/achievements/prepare_steam_import.py
tools/achievements/vendor_godotsteam.py
tools/run_v130r_step13.ps1
tools/tests/V130RStep13AchievementTest.gd
tools/tests/V130RStep13AchievementTest.gd.uid
tools/tests/V130RStep13AchievementTest.tscn
tools/tests/v130r_achievement_cases.json
tools/tests/v130r_step13_report.py
```

문서 변경: docs/handoff/V130R_STEP13_ACHIEVEMENTS_2026-10-17.md, docs/handoff/CURRENT.md.
</details>
