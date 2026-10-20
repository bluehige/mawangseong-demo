# Steam 도전과제 100개 — Step13 연결

**사용자 확인 대기. 게임 이벤트·저장 큐·3언어 화면과 GodotSteam 호출을 연결했다. 실제 Steamworks 정의 등록·게시 및 사용자 클라이언트 해제 확인은 미실행이다.**

구현은 `scripts/achievements/`, 명시적 100개 조건은 `runtime_rules.json`이다. `tools/run_v130r_step13.ps1`에서 격리 저장으로 직접/오프라인/화면/export 검사를 실행한다. 공식 GDExtension 버전·해시는 `addons/godotsteam/PROVENANCE.json`, 절차·한계는 `docs/handoff/V130R_STEP13_ACHIEVEMENTS_2026-10-17.md`에 기록한다. 아래 원본 제작·CSV 안내는 0113a/0113a2에서 가져온 자료다.

2026-10-17 23:16 저장된 지정 기획 `ACHIEVEMENTS_v130.md`의 “추가 14개” 표와 `achievements_v130.json`을 대조하여 **100개·8세트·숨김 8개**를 완성했다. 기존 86개에 `ACH_MILO`부터 `ACH_100`까지 14개를 보충했다. 원문 사본은 `assets/source/imagegen/achievements_v130/design/`에 보존했다. 이전 86개 기획 차이는 해소됐다.

| 파일 | 용도 |
|---|---|
| `achievements.json` | 원문 조건·API 이름·세트·숨김을 보존한 3언어 카탈로그와 PNG/JPG 경로, 진행도 범위 |
| `steamworks_import.csv` | 사용자 지정 열의 검토·매핑용 통합 CSV. Steam 편집기에 직접 넣는 형식이 아님 |
| `stats.csv` | 진행도 stat 20종의 정의표. Steam Stats 화면 등록용 참고 자료이며 자동 가져오기를 확인한 형식이 아님 |
| `5267750-achievements-localization.csv` | 공식 현지화 형식: API별 name/description 두 행, koreana/english/schinese 열 |
| `5267750-achievements-definitions.template.csv` | 공식 정의 열의 템플릿. **실제 세트 ID 미확인으로 직접 업로드 불가** |
| `set_ids.template.json` | 실제 Steam 세트 ID를 넣기 위한 빈 대응표. 문자열 세트 키는 프로젝트 내부 식별자 |

CSV는 UTF-8 BOM과 표준 CSV 인용 규칙을 사용한다. `zh` 열은 통합 CSV의 짧은 열 이름이며 실제 언어는 간체 `zh_cn`/Steam `schinese`다. 숨김은 `hidden=true` 또는 공식 정의의 `spoiler=true`로 유지한다. 숨김 API 목록은 JSON의 `hidden_achievements`에 명시했다.

아이콘은 `assets/achievements/v130/icons/<API>_ACHIEVED.png`의 256×256 PNG이고, 업로드용 JPG 변환본은 `icons_jpg/`에 있다. 모든 그림의 원본·프롬프트·출처는 `assets/source/imagegen/achievements_v130/`에 보존했다. `_mockup/achievements_v130/icons_sheet.png`는 세트별 한 줄 검수판이다. `locked_preview*.png`는 PIL 흑백 확인용일 뿐 업로드하지 않는다. Steam 편집기의 자동 잠김 아이콘 생성 옵션을 사용한다.

roster·기억·합동기·전문화는 고유 ID를 세고, 함정·개성·이동은 성공한 효과 이벤트만 누적한다. `STAT_BUILDING_MOVES`는 완료한 이동 20회, `STAT_BARK_SPECIES`는 실제 표시한 전투 대사의 고유 24종이다. `STAT_BATI_LINES`는 표시된 바티 대사를 넘긴 횟수 100회이며 같은 문장을 다시 읽는 것도 새 표시 이벤트다. 화면 재그리기와 스킵은 더하지 않는다. `STAT_MEMORIES` 목표는 두 승인 기억 카탈로그의 고유 **74개**이며 범위 밖 ID를 세지 않는다. 원문 trigger는 보존하고 실행에는 별도 명시적 조건 데이터를 사용한다.

한국어 이름·설명은 변경하지 않았다. 몬스터 이름은 0089a 대응을 사용하는 `data/v130r/story/speaker_registry.json` 및 기존 현지화 사전과 맞췄다. 특히 Pynn/皮恩, Pongdang/噗咚, Neurit/慢栗, Nubi/缝妮를 유지한다. 추가 엔딩의 축약 기획명은 설명에서도 같은 축약 이름으로 번역했다. 기존 게임 카탈로그의 긴 엔딩 제목과는 문구가 다를 수 있지만 API/trigger ID는 바꾸지 않았다. 원문의 ‘두 층 하나의 옥좌’는 요청대로 보존했다.

## 실제 등록을 준비할 때

1. 100개 아이콘·3언어 시트를 확인한다. `ACH_100`은 모든 세트 색을 합친 특별 왕관 테두리다.
2. Steam 편집기에서 실제 세트를 만들거나 기존 세트 ID를 확인하고, `set_ids.template.json`의 복사본에 입력한다. 기본 캠페인은 빈 값, 나머지 7개는 실제 양의 정수 ID가 필요하다. 이 작업은 이번에 수행하지 않았다.
3. 다음 명령은 로컬 파일만 만든다. 실제 ID가 모두 있어야 직접 가져오기 가능한 정의 CSV 및 세트 현지화 CSV가 나온다.

```powershell
python tools/achievements/prepare_steam_import.py --set-ids path/to/actual_set_ids.json
```

4. Stats 화면에서 정의를 먼저 등록한다. 이후 정의·현지화 CSV와 `_ACHIEVED.png`를 함께 가져오고 자동 잠김 생성을 선택한다. 템플릿의 `REPLACE_WITH_...`를 실제 ID 없이 올리지 않는다. 실제 업로드·저장·게시는 사용자 후속 작업이며 이번에 실행하지 않았다.

공식 근거: [Steamworks Step by Step: Achievements](https://partner.steamgames.com/doc/features/achievements/ach_guide?l=english), [Stats and Achievements](https://partner.steamgames.com/doc/features/achievements?l=english). 확인일: 2026-10-17. 정의 CSV의 세트 ID, 현지화의 언어 열, 아이콘 파일명과 자동 잠김 생성 규칙을 확인했다. 로그인한 편집기에 대한 실제 import 시험은 하지 않았다.
