# 1.3.0 업적 등록 — 사용자 직접 작업

App **5267750**. 이 패키지는 업적100·스탯20·추가 세트7개(기본 세트 포함8개)입니다. **빌드를 default로 지정하기 전에 업적을 저장·게시하세요.** 이미 같은 API가 있으면 수정 내용을 검토하고 중복 생성하지 마세요.

1. Steamworks 앱 관리 → `Edit Steamworks Settings` → `Stats & Achievements` → `Stats`. `STATS_20_INPUT_ORDER.md`의 20행을 순서대로 등록합니다. API 이름은 그대로, INT/Client, 기본0·최소0·증가 전용 켜기, 최대는 각 행 값입니다. Max Change는 미설정, Aggregated는 끄기입니다. 저장합니다. **스탯 화면의 실제 필드 배치·저장 버튼 이름은 확인 필요**: 로그인한 편집기는 이번에 열지 않았습니다.
2. `Stats & Achievements` → `Achievements` → 상단 새 편집기 배너 → `Manage Achievements`. `SETS_7_NAMES.md`의 추가 세트7개를 만듭니다. 기본 게임 세트는 새로 만들지 않습니다. 실제 세트 ID7개를 확인합니다. 화면에 ID가 없으면 `Bulk Import/Export`에서 세트 현지화를 내보내 ID를 확인합니다. 세트 생성 버튼의 현재 이름은 **확인 필요**입니다.
3. 이 폴더의 `Make_Achievement_CSV.cmd`를 더블클릭합니다. 안내된 영어 세트명에 해당하는 **실제 ID7개만** 입력합니다. `Generated`에 아래 파일3개가 나오고 결과 코드0/PASS여야 합니다. `data`의 template CSV를 가져오면 안 됩니다. 시험용 ID로 만든 CSV도 사용하지 마세요.

   - `5267750-achievements-definitions.csv`: 업적100개 정의
   - `5267750-achievements-localization.csv`: 업적 이름·설명 3언어
   - `5267750-achievement-sets-localization.csv`: 세트 이름 3언어

4. `Bulk Import/Export` → `Configure Languages`에서 English/Korean/Simplified Chinese를 맞춥니다. 생성한 정의·현지화·세트 현지화 CSV를 가져옵니다. `Icons`의 PNG100개도 선택하고 `Automatically generate unachieved icons`를 켭니다. 여러 파일 선택은 폴더 안에서 Ctrl+A로 할 수 있습니다. `Icons_100_ACHIEVED.zip`은 묶음 보관본이며, **ZIP 자체의 직접 가져오기 지원은 확인 필요**입니다. PNG를 선택하는 방식을 권장합니다.
5. 가져오기 검토에서 100개, 숨김8개, 3언어, 기본+추가7세트, 진행도 스탯을 확인합니다. `Save imported data`로 저장합니다. 오류가 있으면 그대로 게시하지 말고 해당 이름·세트ID·스탯 범위를 확인합니다.
6. Steamworks의 변경 검토 후 **게시(Publish)** 합니다. 게시 화면의 정확한 버튼·권한·추가 확인 절차는 **확인 필요**입니다. 게시 완료를 확인한 뒤 빌드를 업로드/default 지정합니다. 실제 클라이언트에서 첫 업적이 해제되는지도 출시 전에 확인하세요.

아이콘 규칙은 `<API_NAME>_ACHIEVED.png`, 256×256 PNG입니다(JPG 허용). 잠김 아이콘은 Steam에서 자동 생성합니다. 세트ID는 AppID/DepotID와 다릅니다. 생성기는 서버 존재 여부를 확인하지 않으므로 반드시 실제 ID를 입력하세요.

공식 문서 확인: 2026-10-19. [업적 편집기·CSV·아이콘·세트](https://partner.steamgames.com/doc/features/achievements/ach_guide?l=english), [통계 필드](https://partner.steamgames.com/doc/features/achievements?l=english). 로그인·가져오기·저장·게시·실계정 해제는 실행하지 않았습니다. 세트 기능은 공식 문서상 beta이며 로그인한 화면과 차이가 있으면 확인이 필요합니다.
