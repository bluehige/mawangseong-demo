# Steamworks 포털 입력값

App ID와 Depot ID를 받은 뒤 0을 실제 값으로 교체하고 이 표대로 설정한다.

## 기본 앱

| 항목 | 값 |
|---|---|
| App type | Game |
| Release model | Full Release |
| Korean name | 마왕님, 마왕성은 누가 지켜요? |
| English name | Who Guards the Demon Castle? (상표·현지화 확정 전 초안) |
| Supported OS | Windows only |
| Architecture | 64-bit x86_64 |
| Executable | `MawangCastle.exe` |
| Launch type | Launch (default) |
| Launch arguments | 비움 |
| Working directory | 비움 |
| Languages | Korean interface + subtitles, no full audio |
| Controller | 현재 미지원 |
| Steamworks runtime API | 미사용 |

Steamworks SDK는 SteamPipe 업로드 도구로만 사용한다. Steam 런타임 API는 판매의
필수 조건이 아니므로 현재 빌드에는 GodotSteam이나 `steam_api64.dll`을 추가하지
않는다. 도전 과제·오버레이 직접 연동을 약속하지 않는다.

## Depot

- Depot 이름: `Windows Base Content`
- Language: `All languages`
- OS: 포털 기본 Depot이 단일 PC Depot이면 `All OSes` 유지 가능. 여러 OS Depot을
  만들 때만 Windows로 제한한다.
- Content root: `builds/steam/windows/v<version>/`
- Mapping: 모든 파일을 Depot 루트로 재귀 매핑
- 제외: `steam_appid.txt`, PDB, 소스, 문서 작업 파일
- 기본 브랜치 자동 활성화: 사용하지 않음
- 비공개 테스트 브랜치 예: `internal`

## Steam Auto-Cloud

- Byte quota per user: `10485760` (10 MiB)
- Number of files per user: `50`
- Root: `WinAppDataRoaming`
- Subdirectory: `Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo`
- OS: Windows
- Recursive: No

공개 게임명과 다른 예전 `Demo` 경로는 오기가 아니다. `project.godot`의 정식
게임명 변경 뒤에도 기존 테스트/데모 저장을 유지하도록 Godot 사용자 데이터
디렉터리를 이 값으로 명시 고정했다. 출시 후에는 이 경로를 임의로 바꾸지 않는다.

다음 Pattern을 각각 별도 행으로 추가한다.

- `campaign_save_v1.json`
- `campaign_save_v2.json`
- `campaign_save_v3.json`
- `campaign_save_v4.json`
- `campaign_save_v5.json`
- `quarter_custom_layouts.json`

`settings.cfg`, `first_play_observation/`, `.tmp`, `.bak`, `.corrupt`, `.invalid`
파일은 동기화하지 않는다. 저장 후 반드시 Publish하고 Steam 콘솔의
`testappcloudpaths <AppId>`로 두 대의 Windows PC에서 업로드·다운로드를 확인한다.

## 스토어 기능 체크

- Single-player: 체크
- Steam Cloud: 2대 PC 검증 완료 뒤 체크
- Family Sharing: Steam 기본 정책에 따름
- Achievements, Trading Cards, Workshop, Leaderboards: 체크하지 않음
- Online Co-op/PvP, In-App Purchases: 체크하지 않음
- Captions/Subtitles: 음성 대사가 없으므로 언어 표에서 Full Audio는 체크하지 않음

## Demo 전략

현재 데모를 배포하려면 기본 게임 App ID의 Associated packages 페이지에서 별도
Demo App ID를 만든다. Demo에도 Depot, 빌드와 출시 체크리스트가 필요하다. 기본
게임의 공개 예정 페이지에서 데모를 노출하고, 전체 게임 출시 전 위시리스트와
피드백을 모으는 용도로 사용한다. Steam Playtest는 제한된 비공개 검수에만
사용하고 유료 접근으로 판매하지 않는다.

## 가격·출시일

가격은 경쟁작 조사와 플레이타임 측정 전에는 입력하지 않는다. Steam의 지역별
권장 변환표를 시작점으로 모든 판매 통화에 가격을 넣는다. 출시 할인은 선택이며,
설정할 경우 현재 Steamworks 제한을 포털에서 다시 확인한다.

출시일은 실제 일정이 정해지기 전 `Coming Soon`으로 표시하되 내부 목표일은
정확히 입력한다. 출시 14일 이내에는 날짜 변경이 제한될 수 있으므로 여유를 둔다.
