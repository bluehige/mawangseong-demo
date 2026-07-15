# v0.5 Lyria 오디오 빌드 적용 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5 개발선 오디오 반영 / 현재 애플리케이션 버전 표기는 0.3.0 유지
- 작업 브랜치: `test/web-v0.5-audio`
- 기준 브랜치와 SHA: `main` / `6c955974f723a7ea39ea0d0fbae18e909c05d095`
- 마지막 기능·빌드 커밋 SHA: `a60c1504c97af3b7940d87676ce5a8c7dfcd8fc2`
- 원격 푸시 여부: `origin/test/web-v0.5-audio` 푸시 완료
- 관련 PR 또는 태그: 기능 통합 PR #24, merge commit `6c955974f723a7ea39ea0d0fbae18e909c05d095`; 신규 SemVer 태그 없음

## 2. 이번 세션 목표

- 요청 사항: Lyria BGM·타격음·스킬별 효과음을 정식 `main`에 통합하고 Web, 모바일 대상, 정식 출시용 빌드에 적용한다.
- 완료 조건: `main` merge, Windows Steam 패키지 생성, Web/모바일 브라우저 패키지 생성, 최신 Web 데모 커밋, 핵심 자산 포함과 최소 기동 확인.
- 범위에서 제외한 사항: 전체 회귀·전체 플레이·별도 검수 에이전트, Steamworks 업로드, 신규 SemVer 태그, 저장소에 없는 Android/iOS 네이티브 빌드.

## 3. 완료한 작업

- PR #24를 merge commit 방식으로 `main`에 통합했다.
- 확정 `main` SHA에서 `Windows Steam` export를 만들고 배포 스크립트 검증을 통과했다.
- 같은 SHA에서 Web export를 만들었다. 이 산출물은 현재 저장소가 지원하는 데스크톱 Web과 모바일 브라우저 공용 빌드다.
- `test/web-v0.5-audio`에서 `web_Demo/`를 최신 Web export로 교체했다.
- `web_Demo/index.pck`, `web_Demo/index.wasm`을 Git LFS로 추적하도록 설정했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.gitattributes` | Web PCK/WASM Git LFS 추적 | 완료 |
| `web_Demo/index.html` 및 Web 런타임 파일 | 최신 Godot 4.5.2 Web export 적용 | 완료 |
| `web_Demo/index.pck` | Lyria 오디오가 포함된 게임 패키지 적용 | 완료 |
| `docs/handoff/V05_LYRIA_AUDIO_BUILD_APPLICATION_2026-07-15.md` | 빌드 적용과 최소 검수 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- 신규 생성 자산: 없음. 기존 Lyria 오디오와 출처 기록을 패키징했다.
- Windows Steam PCK와 Web PCK에서 다음 대표 경로를 확인했다: 관리 BGM, 보스 BGM, `fireball`, `quick_slash`, `slime_shield`, `moon_mark`.
- 패키지에 포함된 전체 오디오 원본과 출처는 기존 `assets/source/audio/lyria/v0.5/` 기록을 따른다.

## 6. 테스트 및 검수

| 순서 | 검증 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `PrepareSteamBuild.ps1 -Version 0.3.0` | PASS | `STEAM_BUILD: PASS`, manifest source commit `6c955974...` |
| 2 | Godot `Web` release export | PASS | 확정 SHA 로컬 산출물 및 `test/web-v0.5-audio/web_Demo/` |
| 3 | Steam/Web PCK 대표 오디오 경로 검색 | PASS | 양쪽 PCK에서 대표 BGM 2종과 스킬음 4종 확인 |
| 4 | `MawangCastle.exe --headless --quit-after 60` | PASS | exit code 0, 오류 출력 없음 |
| 5 | Git LFS stage 검사 | PASS | PCK 231,371,076 bytes, WASM 38,047,590 bytes가 LFS 포인터로 stage됨 |
| 6 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청에 따라 최소 검수만 수행 |

- Web 전용 worktree의 첫 export는 초기 전체 임포트 뒤 Godot signal 11로 종료됐지만 패킹 캐시를 유지한 재시도는 exit code 0으로 완료했다. 성공한 두 번째 산출물만 커밋했다.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: `a60c1504c97af3b7940d87676ce5a8c7dfcd8fc2`
- Review range: `6c955974f723a7ea39ea0d0fbae18e909c05d095..a60c1504c97af3b7940d87676ce5a8c7dfcd8fc2`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- Android/iOS export preset과 SDK가 저장소와 로컬 환경에 없으므로 네이티브 APK/AAB/IPA는 만들지 않았다. 현재 모바일 대상은 모바일 브라우저 Web build다.
- Steam App/Depot ID, 공개 지원 연락처, Valve 심사 등 외부 출시 게이트 17개가 남아 있어 Steamworks 업로드는 아직 불가능하다.
- 정식 SemVer 태그와 GitHub Release는 만들지 않았다. 현재 프로젝트와 배포 manifest의 애플리케이션 버전 표기는 `0.3.0`이다.
- 최신 Web 데모 브랜치는 소스 반영용이며 기존 Pages 배포 정책상 자동 공개 배포 대상은 아니다.

## 8. 다음 작업 순서

1. 네이티브 모바일 출시가 필요하면 Android 또는 iOS export preset, SDK, 서명 정보를 별도 작업으로 추가한다.
2. Steamworks 외부 게이트 17개를 완료한 뒤 이 SHA 계열에서 SteamPipe 업로드와 설치·실행 검사를 진행한다.
3. 실제 공개 버전을 정할 때 프로젝트 버전, SemVer 태그와 GitHub Release를 함께 정렬한다.

## 9. 작업 트리 상태

- 기능·빌드 커밋: `a60c1504c97af3b7940d87676ce5a8c7dfcd8fc2`
- Web 데모 원격 브랜치: `origin/test/web-v0.5-audio`
- 로컬 배포 산출물: `builds/distribution/main-6c95597/windows-steam/`, `builds/distribution/main-6c95597/web-mobile/` (Git 비추적)
- Web 데모 산출물: `test/web-v0.5-audio`의 `web_Demo/` (PCK/WASM Git LFS)
