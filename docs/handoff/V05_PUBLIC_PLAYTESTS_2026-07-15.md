# v0.5 공개 Web·모바일 플레이테스트 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5 Lyria 오디오 반영 공개 테스트
- 작업 브랜치: `codex/v05-public-playtests` (원본 저장소 문서 전용)
- 기준 브랜치와 SHA: `main` / `80547dcda4916f270b8d5dd3fb4ffb1a54ce83c7`
- 빌드 기준 소스 SHA: `6c955974f723a7ea39ea0d0fbae18e909c05d095`
- 관련 PR: Web playtest #1, Mobile playtest #1
- 신규 SemVer 태그: 없음

## 2. 이번 세션 목표

- 기존 안정판 Pages를 덮어쓰지 않고 최신 Lyria 빌드를 Web과 모바일 브라우저에서 각각 공개 테스트할 수 있게 한다.
- 공개 저장소와 Pages URL을 분리하고 실제 Godot 캔버스 로딩까지 확인한다.
- 네이티브 Android/iOS 패키지 생성은 현재 범위에 포함하지 않는다.

## 3. 공개 저장소와 플레이 URL

| 대상 | 공개 저장소 | 플레이 URL | 배포 commit |
|---|---|---|---|
| 데스크톱 Web | `bluehige/mawangseong-web-playtest` | https://bluehige.github.io/mawangseong-web-playtest/ | `03638765e3d7ef77031d2c4849f8c84a965eb8a7` |
| 모바일 브라우저 | `bluehige/mawangseong-mobile-playtest` | https://bluehige.github.io/mawangseong-mobile-playtest/ | `27341c4a914007e723eaa58c270ab20229590d7a` |

- Web 빌드 PR #1 merge commit: `ed4c9b3103063dd6e47dc3b937d28fcd45167506`
- Mobile 빌드 PR #1 merge commit: `150332f527a79538fb308eae92c29f388a162a98`
- 두 저장소 모두 공개(`PUBLIC`)이며 빌드 PCK/WASM은 Git LFS로 추적한다.

## 4. 구현 내용

- 최신 `test/web-v0.5-audio` export를 두 공개 저장소에 독립적으로 게시했다.
- Web 저장소는 데스크톱 브라우저 테스트용 원본 export를 유지한다.
- 모바일 저장소는 같은 게임 PCK를 사용하되 `viewport-fit=cover`, 전체 화면 버튼, 가로 화면 권장과 세로 회전 안내를 추가했다.
- Pages Actions가 `lfs: true` checkout을 사용하고 PCK/WASM 실제 크기 및 대표 Lyria 오디오 경로를 검증한 뒤 배포하도록 구성했다.
- 기존 `bluehige/mawangseong-demo` 안정판 Pages와 출시 증빙은 변경하지 않았다.

## 5. 빌드와 자산

- `index.pck`: 231,371,076 bytes
- `index.wasm`: 38,047,590 bytes
- 대표 포함 확인: `management_castle_bustle.wav`, `combat_boss_council.wav`, `fireball.wav`
- 공개 저장소에는 컴파일된 테스트 빌드만 있으며 Gemini API 키나 생성 비밀값은 포함하지 않았다.

## 6. 테스트 및 검수

| 순서 | 검증 | 결과 | 근거 |
|---:|---|---|---|
| 1 | Web Pages Actions | PASS | run `29384105281` |
| 2 | Mobile Pages Actions | PASS | run `29384106568` |
| 3 | Web HTML/PCK HTTP 응답 | PASS | HTML 200, PCK 200 및 231,371,076 bytes |
| 4 | Web 실제 브라우저 로드 | PASS | 1920x1080 Godot canvas, status 제거, console error 0 |
| 5 | Mobile 844x390 가로 화면 로드 | PASS | 1920x1080 Godot canvas, status 제거, console error 0 |
| 6 | Mobile 390x844 세로 화면 안내 | PASS | 회전 안내 `display:flex` 및 안내 문구 확인 |
| 7 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 공개 배포 핵심 경로만 최소 확인 |

- 모바일 첫 CDN 캐시에서는 231MB PCK 로드 완료까지 약 45초가 걸렸다. 연결 속도와 캐시 상태에 따라 초기 로딩 시간이 길 수 있다.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: `80547dcda4916f270b8d5dd3fb4ffb1a54ce83c7`
- Review range: `6c955974f723a7ea39ea0d0fbae18e909c05d095..80547dcda4916f270b8d5dd3fb4ffb1a54ce83c7`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 다음 작업

- 모바일 빌드는 네이티브 APK/AAB가 아니라 모바일 브라우저 빌드다.
- 초기 모바일 다운로드가 크므로 후속 작업에서 오디오 압축 또는 export 크기 최적화를 검토할 수 있다.
- 실제 Android/iOS 출시가 필요하면 export preset, SDK와 서명 정보를 별도 작업으로 추가한다.
- 정식 출시 태그와 Steamworks 외부 게이트는 이번 공개 플레이테스트와 별개다.

## 8. 작업 트리 상태

- 원본 저장소 기능·자산 변경: 없음
- 원본 저장소 변경: 이 핸드오프와 `docs/handoff/CURRENT.md`만 변경
- 외부 공개 저장소: Web/Mobile 모두 `main` 배포 완료
- 로컬 테스트 저장소: `mawangseong-web-playtest`, `mawangseong-mobile-playtest`
