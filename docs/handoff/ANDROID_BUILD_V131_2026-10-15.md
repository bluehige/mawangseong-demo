# Android 첫 테스트 빌드 인계 (0065)

## 1. 메타데이터

- 작성일: 2026-10-15 (KST).
- 목표 버전: **1.3.0 내용 기준**. V131은 작업 식별자이며 제품을 1.3.1로 올리지 않았다.
- WORKSTREAM_ID: `V131_ANDROID_FIRST_BUILD_0065`.
- 브랜치: `codex/v131-android` (기존 브랜치 계속 사용).
- 사용자 지정 최초 기준: `9befdd2afc32bbf1f0a231bae5bd840b09d33cfe`.
- 이번 시작 SHA: `2f2439bb86237cc0e4daf3c4b09e27ce901a989d`.
- 시작 조건: HEAD에 `V131_OGG_AUDIO_2026-10-15.md` 커밋 존재 및 `assets/audio` OGG 131개 확인. OGG 구현은 `4e93eb7ee38f3b86ca978e96ee0657c5d708b9a8`.
- 마지막 구현·검증 SHA: **`1113dcc53db067951406ec11cb030e7db0ae9b57`**. 이후에는 이 문서와 CURRENT만 커밋한다. 마지막 문서 커밋은 `git log -1 --format=%H`와 최종 보고에서 확인한다.
- 로컬 영어 커밋만 수행. push·merge·PR·태그·Release·Play 콘솔·Steam 조치 없음.
- 로컬 `main` 부재. origin/main 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, 불변 v1.2.5 `f757ffa9f9e962158f2123856c8568a3163ecb6c`. `main:AGENTS.md`/CURRENT 조회는 실패했고 origin/main 문서와 사용자 제공 최신 정책을 읽었다. 원격 조회·fetch 없이 최신 main 권위를 확정하지 않았다. 사용자가 지정한 기존 브랜치에서 계속 진행했다.

## 2. 목표와 완료 조건

갤럭시 S23에 직접 설치할 debug APK와 같은 게임·자산 설정의 무서명 AAB를 만든다. Android 도구 등록, 최소 생명주기 대응, 기존 표적 테스트 및 Windows 비교 빌드 부팅을 확인한다. Android 실기/원격 디버그가 불가능하면 사유를 기록한다.

가격 **5,000원은 출시 때 반영할 사용자 결정**이며 이번에는 빌드만 했다. 버튼 크기·핀치·길게 누르는 툴팁·좌우 여백 처리, 신규 그래픽, 릴리스 서명 키, Play 업로드는 제외했다.

## 3. 완료한 작업

### 설치·에디터 설정

| 항목 | 실제 구성 |
|---|---|
| Godot | 기존 공식 `4.6.3.stable.official.7d41c59c4`, 설치 shim에서 실제 GUI EXE 경로를 확인하여 직접 호출 |
| Android export templates | 공식 godot-builds 4.6.3 archive의 SHA-512를 공식 SHA512-SUMS와 대조. `android_debug.apk`, `android_release.apk`, `android_source.zip`을 `%APPDATA%/Godot/export_templates/4.6.3.stable/`에 설치 |
| OpenJDK 17 | 공식 Adoptium Temurin **17.0.20.1+1**, ZIP SHA-256을 공식 API 메타데이터와 대조. `C:/Users/blueh/AppData/Local/Programs/Temurin17/jdk-17.0.20.1+1` |
| 설치 경로 선택 | winget Temurin MSI 설치가 진행되지 않아 취소하고 공식 ZIP으로 설치했다. 기존 Android Studio의 Java 21은 삭제·교체하지 않았다 |
| SDK | 기존 `C:/Users/blueh/AppData/Local/Android/Sdk` 재사용. platform-tools 37.0.0, 공식 command-line tools 22.0(`latest`) 추가. 기존 pinned tools 23.0도 유지 |
| Platforms / build-tools | 기존 안정 platform **37.2** 확인(package metadata: codename 없음, obsolete=false), 36/36.1 등 보존. 공식 문서 호환용 platform 35·build-tools 35.0.1도 설치. **실제 4.6.3 템플릿은 compile/target 36·min 24**이고 APK 도구는 36.0.0, Gradle 설정은 build-tools 36.1.0을 사용한다 |
| Debug keystore | 기존 `%APPDATA%/Godot/keystores/debug.keystore` 재사용, `androiddebugkey` alias 확인. APK 인증서 SHA-256 `f774ce90b95dc458b61e22ca68fb4ae1955a8f0a817565195f3c441093de9e80`. 새 릴리스 키 생성 없음 |
| Godot EditorSettings | `%APPDATA%/Godot/editor_settings-4.6.tres`의 `export/android/java_sdk_path`, `android_sdk_path`, debug keystore 경로 등록. 변경 전 사본은 `tmp/android_build/editor_settings_before.tres` |

SDK 설치는 새 Android CLI의 `android --sdk <SDK> sdk install platforms/android-35`, `... build-tools/35.0.1`을 사용했다. 기존 pinned sdkmanager는 사용 중단 안내를 반환했다. 설치 뒤 실제 파일·버전·실제 export 성공으로 확인했다.

공식 근거: [Godot 4.6 Android 설정](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html), [Android export 속성](https://docs.godotengine.org/en/4.6/classes/class_editorexportplatformandroid.html), [Godot 공식 템플릿](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable), [Android 공식 command-line tools](https://developer.android.com/studio#command-tools), [Adoptium 공식 API](https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse). 문서의 권장 SDK 번호와 실제 템플릿의 번호는 구분했다.

### Export·런타임

- `Android` 프리셋 추가: arm64-v8a만 포함, `mobile_touch_ui`, 패키지 **`com.dklee.mawangcastle`(가정)**, name 1.3.0/code 10300. 기존 Web·Windows·Windows Steam·QA 프리셋 내용은 그대로다.
- Android FPS 최대 60, PC 기본 최대 120 유지. GLES Compatibility를 모바일 기능 오버라이드로 지정하고 APK/AAB manifest에서도 `gl_compatibility`를 확인했다. 던전은 기존 `mobile` 렌더 프로필을 네이티브 Android에도 재사용한다.
- 가로 자동 회전: Godot `SCREEN_SENSOR_LANDSCAPE=4`. 실제 Android manifest에는 Godot 변환 결과인 **`userLandscape`(11)**가 들어간다. 세로 회전 허용 설정은 아니다.
- Android에서만 `AndroidLifecycle` 노드를 생성한다. APPLICATION_PAUSED/RESUMED와 WM_GO_BACK_REQUEST를 처리하며 전체 SceneTree(노드·타이머 처리)를 정지·복원한다. 기존 일시정지 메뉴는 복귀 후 유지하고 명시적으로 재개한다. 기존에 정지된 전투 상태도 보존한다.
- 배경 전환 시 안전한 화면의 커밋된 상태를 **동기 저장**하고 설정도 저장한다. 배치 미리보기는 기존 메뉴 경로로 취소한다. 저장 실패는 기존 오류 표시·원본 보존 절차를 사용한다.
- **전투 도중 저장 형식은 추가하지 않았다.** 전투 중 앱이 살아 있으면 같은 전투에서 메뉴를 닫아 재개하며, OS가 앱을 종료했다면 마지막 안전 체크포인트(일반적으로 전투 직전)부터 이어진다. 방어 시작 카운트다운·맵 편집·복원 중 등 기존 저장 금지 조건도 유지한다. 임의의 중간 전투 저장으로 기존 저장을 덮어쓰지 않는다.
- 뒤로가기는 자동 종료를 끄고 기존 ESC 입력 경로로 전달한다. 열린 메뉴·설정·확인창·배치 등의 기존 취소 정책을 재사용한다. 제목에서 즉시 종료하지 않는다.
- 전투 화면에 있는 동안 화면 꺼짐 방지 요청. 배경 전환·전투 화면 이탈·노드 종료 때 해제한다. `user://` 저장 경로 및 기존 v1~v6 스키마를 유지한다.
- 스토리·밸런스·수치·그래픽/오디오 원본·화면 배치 변경 없음. 이미지 생성·Sweep·갤러리 실행 없음.

### 모바일 자산·빌드 도구

`tools/android_export.py`가 `tmp/android_stage` 격리 복사본을 만들고 `tools/mobile_web_export.py`의 같은 일러스트 정책을 적용한다. 원본 PNG/import를 줄이거나 변경하지 않는다. portraits 131 + endings 26 + regions 10 + onboarding 2 + backgrounds 4 = **173개**, quality 0.90 / 최대 1280px. 이전 도구의 고정 기대 개수 134를 현행 전체 자산 수 173으로 올렸으며 개수 검사·금지 범위 검사는 유지했다.

Android export가 요구하는 ETC2/ASTC import 플래그는 **격리 복사본에만** 켠다. Steam·에디터 플러그인·원본·문서·도구·외부 빌드 파일은 제외한다. Gradle 소스도 격리 복사본에만 풀고 `android/.gdignore`로 재가져오기를 막는다. AAB만 Gradle/release variant/서명 꺼짐이며 게임 설정·자산·ABI·패키지·버전은 APK와 같다. Gradle은 heap 1536MiB·worker 2·상주 daemon 비활성으로 설정했다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `export_presets.cfg` | Android 프리셋 추가 |
| `project.godot` | Android 60fps·가로·초기 화면 꺼짐 정책, 모바일 GLES |
| `scripts/core/AndroidLifecycle.gd`, `.gd.uid` | Android 전용 중단·복귀·저장·뒤로가기·화면 켜짐 |
| `scripts/game/GameRoot.gd` | Android에서만 생명주기 노드 생성 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | Android 기존 mobile 프로필 선택 |
| `tools/android_export.py` | 격리 APK·AAB 빌드·설치 안내·프로세스 제한 |
| `tools/mobile_web_export.py` | 현행 일러스트 고정 개수 173으로 갱신 |
| `tools/tests/AndroidLifecycleTest.gd`, `.gd.uid`, `.tscn` | 새 기능 동작·기존 PC 분리·안전저장 직접 검사 |
| `tools/tests/RunAndroidBuildChecks.ps1` | 독립 사용자 경로·Godot 1개·현재 표적 검사 실행 |
| `docs/handoff/ANDROID_BUILD_V131_2026-10-15.md` | 이번 세션 인계 |
| `docs/handoff/CURRENT.md` | 진입 링크·다음 작업 |

## 5. 산출물·자산

최종 사용자 폴더: `C:/Users/blueh/Desktop/진행중인프로젝트/_android/`.

| 파일 | 크기 | SHA-256 |
|---|---:|---|
| `mawangcastle-1.3.0-test.apk` | **511,279,349 bytes (487.59 MiB)** | `a6eae22b47ea7975698d8e9104ea2354c6d4d28b6213eeebe87c3957d9f6f87c` |
| `mawangcastle-1.3.0-test.aab` | **508,466,477 bytes (484.91 MiB)** | `9159c05fbdaf0596a087c751ea7aee95cc31e57c16e0c25578cb85afc99e65e5` |
| `README_설치방법.txt` | UTF-8 BOM 한국어 | 알 수 없는 앱 설치·USB/카톡/드라이브·설치·정지/저장 제한·다음 UI 범위 안내 |

폰에 설치할 것은 APK다. AAB는 직접 설치 파일이 아니다. 큰 파일이므로 카카오톡 전송이 막히면 USB 또는 드라이브를 사용하도록 안내했다. APK와 무서명 AAB는 소스 Git에 커밋하지 않았다. 불필요한 APK `.idsig` 보조 파일은 제거했다.

신규 그래픽/오디오 생성·원본 가공 없음. OGG 131개를 그대로 사용했다. 기존 Steam 1.3.0 출시 파일과 `C:/Users/blueh/Documents/Codex/2026-10-13/task/Steam-1.3.0-Ready`는 수정하지 않았다.

## 6. 테스트 및 검수

| 검사 | 결과·실제 범위 | 근거 (`tmp/android_build/`) |
|---|---|---|
| AndroidLifecycleTest | **41 checks / 0 failures**. PC 120fps·Android 노드 미생성, 중단/복귀·중복 중단, v6 동기 저장과 복원, 전투 체크포인트 보존, ESC 메뉴·설정 취소, 화면 켜짐 요청, 원래 사용자 pause 및 스킬 연출 정지 보존 | `AndroidLifecycleTest.log`, `lifecycle_result.json` |
| 기존 V130SavePlotTest | **212 checks / 0 failures**. v1~v5 복사본→v6·이어하기·복구 | `V130SavePlotTest.log`, 기존 `tmp/v130_m6/result.json` |
| 기존 V1213StageOneTest | **41 checks PASS** | `V1213StageOneTest.log` |
| 기존 mobile Web 정책 검사 | unittest **3 PASS**. 전체 개수·선택 범위·1280/0.90·외부 경로 거부 | `python -m unittest discover -s tools/ci -p test_mobile_web_export.py` |
| 실제 가져온 일러스트 | **173/173**, 전부 긴 변 1280px 이하. 파일별 실제 Texture 크기 저장 | `illustration_dimensions.json`, `illustration_check.log` |
| 최종 APK | debug export exit 0, apksigner verify exit 0. arm64 단일 ABI, name/code/package·min24/target36·가로·GLES·터치 기능·60fps binary 확인, ZIP CRC PASS, 제외 경로 0 | `apk_final.log`, `apk_signature.log`, `apk_manifest_final.txt`, `artifact_verification.json` |
| 최종 AAB | unsigned release Gradle export exit 0. 공식 **bundletool 1.18.3 validate exit 0**, 같은 package/ABI/features/fps/render setting. ZIP CRC PASS, 서명 엔트리 0·jarsigner unsigned 확인 | `aab.log`, `bundle_validate.log`, `aab_manifest.xml`, `aab_signature.log`, `artifact_verification.json` |
| Android 첫 화면 | **에뮬레이터 PASS**. 기존 이미지의 실제 ABI 목록이 `x86_64,arm64-v8a`인 것을 추가 확인했다. 기존 사용자 AVD를 수정하지 않고 `tmp/android_build/avd_home`에 임시 API36 가상 기기 생성. 최종 arm64 APK install Success·COLD 시작 Status ok, 실제 2340×1080 한국어 타이틀·설정 확인. 실제 S23는 미실행 | `android_install.log`, `android_host_launch.log`, `android_title.png`, `android_settings.png`, `android_runtime_result.json` |
| Android 복귀·저장·뒤로가기 | 설정에서 HOME→같은 PID 2994로 HOT 복귀→시스템 BACK→타이틀 시각 확인. 앱 내부 `files/settings.cfg` 실제 생성·한국어와 UI 설정 저장 확인. 첫 타이틀 로딩 오류 0, 화면 전환 후 기존 유형의 can_process 진단 2건은 별도 기록 | `android_resume.log`, `android_user_files.txt`, `android_saved_settings.cfg`, `android_runtime_final.log` |
| Windows 비교 | 별도 `tmp/android_build/windows/MawangCastle.exe` export **exit 0**, 실제 타이틀·v1.3.0 직접 확인, 창 닫기 후 종료·stderr **0 bytes**. 실제 창 1280×720(테두리 포함 캡처 1296×759). 전체 플레이 검수는 아님 | `windows_export.log`, `windows_boot.log`, `windows_boot.stderr.log`, `windows_title.png` |
| PC 분기·보존 | 기존 export 프리셋 모든 section 동일, PC 120fps 유지. 기존 혼합 import/UID **1382개 SHA-256 일치**. Steam 준비 **35파일 크기/시각 일치** | `preservation_before.json`, `preservation_after.json` |
| 형식 | Python py_compile, 의도한 diff 및 staged `git diff --check` PASS | 커밋 `1113dcc` |

각 자동 실행은 Godot 직접 GUI EXE를 headless로 실행해 콘솔 wrapper의 보조 엔진을 피했다. 기록된 빌드·표적 검사 모두 전0·최대1·후0. Windows EXE도 다른 엔진 종료 뒤 단독 실행했다. Android는 호스트 Godot가 없는 상태에서 게스트 앱 1개만 실행하고 force-stop 뒤 가상 기기도 종료했다. 최종 Godot/테스트 EXE/Java/emulator/qemu 프로세스 0개, adb 연결 기기 0개 확인. GUI 캡처 **누적5/20장**, 최초 Android 전체화면 안내/영문 제목 캡처는 최종 한국어 타이틀로 교체했고 **대표3장**(Windows 타이틀·Android 타이틀/설정)만 보관한다. 전체 회귀·전체 플레이·별도 검수 에이전트는 NOT_REQUESTED이며 실행하지 않았다. 병렬 에이전트는 읽기 전용 코드 조사만 했다.

### 추가 실행한 구형 검사: 기존 실패를 PASS로 바꾸지 않음

- `PlayerContinuityTest`: **89 checks / 6 failures**. 이번 시작 SHA `2f2439b`의 GameRoot를 임시 복사본에 연결하여 **동일한 6개 실패 문구**가 재현됐다. 초기 업데이트 자동 팝업 기대 3건, 방어 카운트다운 ESC/재개 2건, 확인 취소 후 pause 기대 1건이다. Android 변경으로 추가된 실패 0이지만 이 검사를 PASS라고 기록하지 않는다. 제품 메뉴를 바꾸거나 테스트 기대값을 낮추지 않았다.
- `tools/CampaignSaveLoadSmokeTest.gd`: 현재 삭제된 `Constants.SCREEN_UPPER_FLOOR`를 참조해 parse error. 기준 SHA의 검사에도 같은 참조가 있고 기준 Constants에도 해당 상수가 없다. 1층 개편 이전의 검사 이관이 별도 필요하다. 엔진이 parse error 후 대기하므로 이 세션 소유 프로세스를 종료했다.
- 위 둘은 현행 Android 표적 runner의 기본 세트에 넣지 않았다. 현재 기본 세트는 AndroidLifecycleTest/V130SavePlotTest/V1213StageOneTest이며, 유효한 기존 테스트의 기대값은 변경하지 않았다.
- 근거: `baseline_comparison.json`, `baseline_continuity.log`, `PlayerContinuityTest.log/.stderr.log`, `CampaignSaveLoadSmokeTest.stderr.log`. 이 기존 실패 때문에 **저장소 전체 또는 모든 메뉴 검사가 PASS라는 주장은 하지 않는다**.

### 실행 중 실패와 수정

1. 일러스트 고정 개수 134와 실제 173의 불일치 → 정책 범위 5종은 그대로, 정확한 개수로 올리고 기존 3검사 PASS.
2. legacy APK exporter는 min/target SDK 명시 override를 허용하지 않음 → 빈 값(공식 템플릿 기본값) 사용. Android exporter의 ETC2/ASTC 사전 조건은 격리 복사본에서만 충족.
3. Godot의 Android manifest 생성은 모바일 renderer 설정을 사용 → `.mobile=gl_compatibility`로 지정한 뒤 APK/AAB manifest·binary 재확인.
4. 최초 Gradle 템플릿을 엔진이 재가져와 생성한 icon `.import` 및 asset pack 재탐색 때문에 재빌드 실패 → `android/.gdignore`를 도구에 추가. 이미 생성된 격리 `android/build/res`의 sidecar 12개만 검증된 경로 안에서 제거. 최종 export 오류 0·bundletool PASS. 실패 로그 `apk.log`, `apk_retry*.log`, `aab_generated_cache_failure.log`, `aab_icon_import_failure.log` 보관.
5. 새 테스트 초기 fixture의 이름 미설정으로 저장 요약 불일치 → 실제 이름을 설정해 수정. 스킬 연출 hold를 사용자 pause와 구분해 각각 보존하는 검증으로 명확히 했다. 기존 테스트 수정 없음. profile 계약은 검사별 독립 경로로 맞췄다.
6. 처음에는 AVD의 x86_64 표시만 보고 arm64 실행 불가라고 판단했으나 **이미지의 ABI 목록과 WHPX 가속을 추가 확인하여 정정**했다. 임시 가상 기기에서 ARM64 변환 실행을 사용했다. 최초 SwiftShader는 GLES shader uniform 한계 오류가 있어 앱을 종료하고 같은 임시 기기를 `-gpu host`로 재시작했다. 최종 NVIDIA GLES 3.1 실행의 첫 화면 로딩 오류/Script Error/FATAL은 0이다. 화면 전환 후 `Condition !is_inside_tree() / can_process` 진단 2건이 보였으나 UI·HOT 복귀·뒤로가기는 정상이다. 앞선 제품 인계에도 존재하는 진단 유형이며 이번에 엔진/공통 PC UI를 수정하지 않았다. SwiftShader 로그도 `android_swiftshader.log`에 보관했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 1113dcc53db067951406ec11cb030e7db0ae9b57
- Review range: 2f2439bb86237cc0e4daf3c4b09e27ce901a989d..1113dcc53db067951406ec11cb030e7db0ae9b57
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

위 판정은 표에 명시한 현행 Android 직접 검사·API36 에뮬레이터 대표 부팅/복귀·기존 v6/StageOne·Windows 대표 부팅 범위다. S23 실기 부팅, 구형 검사 2종, 전체 회귀 또는 출시 승인으로 확대하지 않는다. 원격 repository-policy는 실행하지 않았다.

## 7. 가정과 남은 제한

- 패키지명 `com.dklee.mawangcastle`은 사용자 제시 후보를 테스트에 사용한 **가정**이며 Play 소유권/가용성/최종 ID 확인은 하지 않았다.
- 사용자 기기 정보: Galaxy S23, 6.1인치, 2340×1080, 약425ppi, 기본 밀도 약2.625. 가로 16:9 게임 영역 1920×1080이면 픽셀 1:1, 좌우 `(2340-1920)/2=210px`씩. **48dp×2.625=126px**, 기존 측정 기준 128px과 대응한다. 이는 사용자가 준 계산 조건이며 시스템 바/카메라 영역을 포함한 실측은 아니다. 좌우 여백·안전 영역 처리는 이번에 기록만 했다.
- 버튼·드래그·줌·툴팁의 모바일 사용성은 앞선 [터치 측정](ANDROID_TOUCH_AUDIT_2026-10-15.md)의 미달이 남아 있다. 이번 APK가 터치 UI 완성이나 스토어 출시 후보를 뜻하지 않는다.
- 전투 중 강제 종료 시 마지막 안전저장부터 복원하는 기존 제한, **S23 실기 부팅 미확인**, 위 구형 검사 실패·화면 전환 can_process 진단을 유지한다. 에뮬레이터는 S23와 픽셀 크기/논리 밀도(420dpi=2.625)를 맞춘 가상 환경이며 실제 Snapdragon/Adreno 검증은 아니다.

## 8. 다음 작업과 재실행

1. 폰으로 APK와 설치 안내를 복사하여 S23에서 첫 화면·소리·터치·홈 전환/복귀·뒤로가기·저장 이어하기를 확인한다. 설치 전 기존 동일 패키지의 다른 서명 앱이 있으면 데이터 보존 여부부터 판단한다.
2. 별도 작업에서 터치 크기 128px·간격20px·글자36/30 기준, 핀치·길게 누르기·좌우 여백 우선순위를 정한다.
3. 구형 메뉴/상층 저장 검사 2종을 현재 제품 계약으로 이관할지 헤드가 별도 범위를 정한다. 릴리스 키 생성·최종 패키지명·Play 설정은 사용자 확인 뒤 별도 작업이다.

PowerShell 재빌드 (Godot 전0개 확인, 원본/Steam 폴더는 사용하지 않음):

```powershell
$env:JAVA_HOME = 'C:/Users/blueh/AppData/Local/Programs/Temurin17/jdk-17.0.20.1+1'
$env:ANDROID_HOME = 'C:/Users/blueh/AppData/Local/Android/Sdk'
& C:/Users/blueh/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe tools/android_export.py --godot D:/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64.exe --output 'C:/Users/blueh/Desktop/진행중인프로젝트/_android'
& tools/tests/RunAndroidBuildChecks.ps1
```

실제 Godot 경로는 재개 시 `godot-gui.cmd`에서 다시 확인한다. `--bundle-only`는 같은 실행에서 준비한 격리 복사본으로 실패한 AAB만 재개할 때 사용하며, 소스 변경 후에는 전체 빌드 명령을 사용한다. 템플릿 원본·ZIP/JDK·검사 로그는 `tmp/android_build/`, 격리 자산은 `tmp/android_stage/`에 남아 있다.

## 9. 작업 트리 상태

- 이번 구현 커밋은 12개 명시 경로뿐이다. 신규 UID도 이번 새 스크립트 2개만 포함했다. 기존 1382개 혼합 import/UID는 보존하고 제외했다.
- 최종 문서 커밋은 이 문서와 CURRENT만 포함한다. 기존 변경을 되돌리거나 `git add -A`, branch 전환, stash, push를 사용하지 않았다.
- 산출물·스크린샷·다운로드·임시 baseline·Windows 비교 빌드는 모두 Git 미포함이다. 추가 전체 검수·공개 배포도 없다.

## 10. 종료 확인

- [x] APK·무서명 AAB·한국어 설치 안내 생성
- [x] 현행 직접 검사·관련 v6/StageOne·모바일 정책 검사 통과
- [x] 실제 173개 크기 및 최종 패키지 내용·서명 검사
- [x] Windows 비교 빌드·대표 타이틀 확인
- [x] 기존 혼합 파일·Steam 준비 폴더 보존 확인
- [x] Android 에뮬레이터 부팅·홈 복귀·뒤로가기·앱 내부 설정 저장 확인
- [x] S23 실기 미실행·구형 검사 실패·진단·S23 조건 기록
- [x] 구현 SHA·명시적 스테이징·로컬 커밋, CURRENT 연결
- [ ] Android 실기 첫 화면/실사용 확인 (후속 사용자 설치 테스트)
