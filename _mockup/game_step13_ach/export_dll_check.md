# Windows DLL/export — TARGETED_PASS · 사용자 확인 대기

공식 GodotSteam 4.23.1, Steamworks SDK 1.65, Godot 4.4+ GDExtension. Godot 4.6.3 공식 엔진·기본 export template로 Windows Desktop release export 성공, 오류 0. 커스텀 모듈/커스텀 엔진은 사용하지 않았다.

공식 배포: https://codeberg.org/godotsteam/godotsteam/releases/download/v4.23.1/godotsteam-4.23.1-gdextension-plugin-4.4.zip.tar.xz

Archive SHA-256: `37d53ede5eda11d2247d70c1af91f95a4777ad2a419fc8a24de1cc816d21cc0a`. 라이선스/descriptor의 원본·설치 해시는 addons/godotsteam/PROVENANCE.json에 있다. DLL 3개는 공식 배포 바이트와 같다. descriptor만 Windows x64 항목으로 제한했다.

| DLL | 바이트 | SHA-256 |
|---|---:|---|
| `libgodotsteam.windows.template_debug.x86_64.dll` | 4325888 | `2f94c4ef1142534f332d0cbb41ee597f67af6fb6498a110c3644984488ed28ce` |
| `libgodotsteam.windows.template_release.x86_64.dll` | 3982336 | `799e1917061854661ab53c8ef6d297366193ed495088b34f5e32a280fa4ef744` |
| `steam_api64.dll` | 319128 | `8de54d32508e216c9135b8bf025749243d44e404c1c22a8e5fe35acecabe7a9c` |

실제 tmp/v130r_step13/export/에는 MawangCastle.exe/PCK와 release 확장 DLL·steam_api64.dll이 있다. 두 DLL의 해시가 소스 공식 배포본과 일치한다. debug DLL은 개발 실행용이며 release 출력에 추가하지 않았다.

실제 PCK v3 색인 5024항목을 읽어 steam_appid.txt가 없고 원본 이미지/검수/도구/tmp 자료도 없는 것을 확인했다. 파일 시스템 출력에도 App ID 파일이 없다. 100개 런타임 아이콘과 조건/카탈로그 JSON, GDExtension descriptor가 들어 있다. App ID 5267750은 개발 파일 및 steamInitEx 인자로만 설정한다.

`tools/run_v130r_step13.ps1 -Mode export_smoke`로 Steam 없는 환경의 실제 release EXE를 격리 저장·headless 60프레임 실행하고 정상 종료했다. stderr 비어 있음. 산출물 검사 631개 실패 0. 실제 Steam 오버레이·계정 해제는 사용자 확인 대기이며 인계서 8절을 따른다. DLL/EXE/PCK 빌드는 Steam에 업로드하지 않았다.
