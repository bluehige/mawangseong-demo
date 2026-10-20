# Steam 1.3.0 출시 준비 패키지

**사용자 확인 대기.** App5267750 / Depot5267751. 준비 담당자는 Steam 로그인·업로드·Steamworks 편집·게시를 실행하지 않았습니다.

집에서 할 일은 아래 3단계입니다. Python3와 기존 SteamCMD를 사용합니다. 이 PC에서 Python3.11과 공식 SteamCMD 경로를 확인했으며 새로 설치하지 않았습니다.

1. **업적 등록·게시 (약 30~60분)** — `Achievements/STEAMWORKS_ACHIEVEMENTS_KO.md` 순서대로 스탯20개 등록 → 세트7개 생성 → ID7개 입력 → CSV·아이콘 가져오기 → 저장·게시합니다. **업적을 먼저 게시하고 빌드를 default로 지정하세요.**
2. **빌드 업로드 (약 5~30분, 회선에 따라 다름)** — `OpenSteamworksBuilds.cmd`로 같은 Desc의 빌드가 없는지 확인한 뒤 `Upload_1.3.0.cmd`를 더블클릭합니다. 내용 검증 후 `UPLOAD`를 입력하면 저장 로그인으로 한 번 시도합니다. 없으면 `CONSOLE`로 전환하여 SteamCMD에서 로그인·업로드 명령을 직접 입력합니다. 비밀번호/Guard는 공식 콘솔에만 입력하세요. 막히면 `HTTP_UPLOAD_1.3.0_KO.md`와 동봉 ZIP을 사용합니다. 두 경로를 동시에 실행하지 마세요. 결과는 `Evidence/upload-result.txt`에 기록됩니다. 이 스크립트는 default를 변경하지 않습니다.
3. **원할 때 공개 적용·공지 (약 5~15분)** — Steamworks Builds에서 기록된 BuildID/Desc를 확인하고 대상 빌드를 default로 지정합니다. 요청되면 Steam Mobile 확인을 직접 처리합니다. 이후 `PATCH_NOTES_KO.txt`, `PATCH_NOTES_EN.txt`, `PATCH_NOTES_ZH_CN.txt`를 공지에 사용합니다. 업적 게시 완료와 BuildID를 확인하기 전에는 default로 바꾸지 마세요.

`Content`에는 Steam에 올릴 파일만 있습니다. 실행 확인은 Steam 미실행·격리 APPDATA에서 수행하며 사용자 세이브는 수정하지 않습니다. 테스트 프로필·로그·캡처는 `Evidence`에 있습니다. 수동으로 EXE를 실행하면 일반 세이브 경로를 사용할 수 있으므로 추가 확인에는 `Evidence`의 실행 환경 기록을 참고하세요.

업로드 성공 여부는 새 BuildID로 확인합니다. 종료 코드0이나 ZIP 선택만으로 업로드 성공이라고 판단하지 마세요. 완료/성공 여부가 불명확하면 재업로드 전에 Builds 목록부터 확인하세요.
