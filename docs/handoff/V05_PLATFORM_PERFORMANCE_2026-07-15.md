# v0.5 PC·모바일 플랫폼 성능 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5
- 작업 브랜치: `codex/v05-platform-performance`
- 기준 브랜치 및 SHA: `origin/main` / `42bf1f4a5acd5ffa7bacc949f63f9444e0f264aa`
- 마지막 구현 커밋 SHA: `113e85d0b2a045bc7c7cff81e1fbc07b529b90b2`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: GitHub 테스트판의 느린 원인이 모바일 전용인지 PC 공통인지 확인하고, 모바일과 PC에 맞는 방식으로 전체 성능을 수정한다.
- 완료 조건: 공개 PC Web과 모바일 Web의 병목을 재현하고 원인을 특정하며, PC Web·모바일 Web·Windows native에 서로 다른 품질 프로필을 적용한 뒤 관련 자동 테스트와 실제 브라우저 계측을 통과한다.
- 범위에서 제외한 사항: 공개 Pages 교체, 전체 회귀·전체 플레이 검수, 별도 검수 에이전트, 외부 기기 팜 실측은 요청되지 않아 수행하지 않았다.

## 3. 원인과 완료한 작업

### 확인한 원인

- 모바일만의 문제가 아니었다. 공개 PC Web 1920×1080 타이틀도 약 35.54fps였고, 화면당 약 5,631회의 WebGL draw 호출이 발생했다.
- `GameRoot._draw()`가 타이틀·대화·전면 UI 화면에서도 보이지 않는 전체 던전을 계속 제출했다.
- quarter renderer가 728개 활성 셀과 방 벽의 미세 돌·잔해·격자 장식을 플랫폼 구분 없이 매번 그렸다.
- 전투 컨트롤러의 5개 업데이트 경로가 시각 효과 유무와 무관하게 매 physics tick마다 전체 맵 redraw를 요청했다.
- Web의 긴 BGM이 sample 방식으로 디코딩되어 첫 관리곡 진입 때 backing storage가 최대 약 126.55MiB 증가했다.
- 모바일은 DPR 3 기기에서 844×390 CSS 화면을 2532×1170 백버퍼로 렌더링했고, 149MB PCK를 시작할 때 복사·로딩하는 부담도 컸다.

### 플랫폼별 수정

- 공통: 던전이 필요한 `management`, `monster`, `combat`, `result` 화면에서만 던전과 unit/effect layer를 렌더링한다.
- Windows native: `full` 프로필을 유지하여 기존 미세 돌벽·잔해·격자 품질을 보존한다.
- PC Web: `web` 프로필로 큰 형태, 방 격자, 암반·edge skirt는 유지하고 작은 벽 돌·잔해·거친 외곽선만 줄인다.
- 모바일 Web: `mobile` 프로필로 작은 벽 장식뿐 아니라 암반·edge skirt·셀별 격자선을 추가 생략한다. 기존 터치 전용 UI는 유지한다.
- 모바일 Web: HiDPI 백버퍼를 CSS 픽셀 크기로 제한한다. DPR 3 실측에서 844×390 백버퍼를 확인했다.
- Web 공통: 긴 BGM만 stream playback으로 전환한다. native BGM 및 짧은 SFX 재생 방식은 바꾸지 않았다.
- 전투: 동적 오버레이가 없으면 전체 맵 redraw를 0회로 만들고, 필요한 오버레이가 있을 때만 즉시 1회 후 최대 10fps로 갱신한다.
- 모바일 빌드: 일러스트 134개의 품질 0.90 정책에 1280px size limit을 추가했다. 전투 스프라이트·폰트·PC Web 원본 품질은 건드리지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `project.godot` | 모바일 Web HiDPI 백버퍼 제한 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | native/PC Web/mobile 렌더 프로필과 world layer 가시성 제어 | 완료 |
| `scripts/game/GameRoot.gd` | 비월드 화면 던전 렌더 차단, Web BGM streaming | 완료 |
| `scripts/game/CombatSceneController.gd` | 무조건 redraw 제거 및 동적 오버레이 10fps 제한 | 완료 |
| `tools/mobile_web_export.py` | 모바일 일러스트 1280px export 제한 | 완료 |
| `tools/ci/test_mobile_web_export.py` | 모바일 import override 계약 검증 | 완료 |
| `tools/EngineerPerformanceSmokeTest.gd` | 렌더 가드·native full 품질·idle combat redraw 회귀 검증 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 신규 자산 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 자산 파일은 수정하지 않았고 모바일 export 시 일러스트 import 크기만 제한한다.
- 게임 연결 및 실제 렌더 확인 결과: PC Web 1920×1080과 모바일 Web 844×390/DPR 3에서 타이틀·관리 화면을 실제 렌더해 UI와 던전 표시를 확인했다.

## 6. 성능 계측

| 대상 | 변경 전 | 변경 후 | 결과 |
|---|---:|---:|---|
| PC Web 타이틀 FPS | 35.54 | 60.02 | 60fps 회복 |
| PC Web 타이틀 draw 호출/프레임 | 약 5,631 | 20 | 99.6% 감소 |
| PC Web 관리 FPS | 기준 화면도 35fps대 | 60.18 | 60fps 유지 |
| PC Web 관리 draw 호출/프레임 | 약 5,631 | 약 2,243 | 60.2% 감소 |
| 모바일 Web DPR 3 타이틀 FPS | 24.3 | 60.03 | 60fps 회복 |
| 모바일 Web 관리 FPS | DPR 1 튜토리얼 약 31 | DPR 3에서 60.14 | 고DPI에서도 60fps |
| 모바일 Web 관리 draw 호출/프레임 | 약 5,626 | 약 1,304 | 76.8% 감소 |
| 모바일 Web 백버퍼 | 2532×1170 | 844×390 | 픽셀 수 88.9% 감소 |
| 첫 관리 BGM backing storage 증가 | 최대 약 126.55MiB | PC 약 0.12MiB, 모바일 약 0.22MiB | 대용량 선디코딩 제거 |
| 모바일 PCK | 149,196,724 bytes | 146,803,604 bytes | 추가 2,393,120 bytes 감소 |

- PC Web 관리 화면의 5초 `TaskDuration`은 3.601초, 모바일 DPR 3 관리는 2.584초였고 두 환경 모두 60fps를 유지했다.
- PC Web 결과물은 231,378,276-byte PCK, 모바일 결과물은 146,803,604-byte PCK이다.
- 브라우저 근거 캡처: `output/playwright/platform-after/pc-management.png`, `mobile-title-dpr3.png`, `mobile-management-dpr3.png`
- 빌드 근거: `tmp/perf_web/`, `tmp/perf_mobile/`이며 Git 비추적 산출물이다.

## 7. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `Godot --headless --path . tools/EngineerPerformanceSmokeTest.tscn` | PASS, 15 assertions | native full 프로필, 비월드 렌더 차단, idle combat 0회/0.5초, 동적 시설 4회/0.5초 |
| 2 | `Godot --headless --path . tools/QuarterModuleSmokeTest.tscn` | PASS | quarter layout·렌더·시설 계약 |
| 3 | `Godot --headless --path . res://tools/MobileTouchUISmokeTest.tscn -- --mobile-touch-ui` | PASS, 23 assertions | 모바일 터치 UI·튜토리얼·전투 입력 |
| 4 | `Godot --headless --path . tools/tests/MusicStateAudioTest.tscn` | PASS, 12 assertions | 관리/일반/보스 음악 상태 |
| 5 | `python -m unittest tools.ci.test_mobile_web_export -v` | PASS, 3 tests | 모바일 일러스트 override 범위와 1280px 계약 |
| 6 | Playwright Chromium, PC Web 1920×1080 타이틀·관리 | PASS | 60fps, 캡처와 CDP/WebGL 계측 |
| 7 | Playwright Chromium, mobile Web 844×390, DPR 3, touch | PASS | 60fps, 844×390 백버퍼, 터치 진입 |
| 8 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 사용자 요청 없음 |

- 추가로 실행한 `DemoSmokeTest.tscn`은 기능 진행 assertions를 통과했으나, 기존 테스트의 `전투 이탈 후 음악 페이드아웃 정지` 한 항목이 현재 `main`의 의도된 관리 BGM 재생 동작과 불일치했다. 이번 Web streaming 변경은 native에서 활성화되지 않으므로 성능 수정 회귀가 아니며, 집중 음악 상태 테스트 12개는 모두 PASS다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 113e85d0b2a045bc7c7cff81e1fbc07b529b90b2
- Review range: 42bf1f4a5acd5ffa7bacc949f63f9444e0f264aa..113e85d0b2a045bc7c7cff81e1fbc07b529b90b2
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 8. 미해결 항목과 위험

- 공개 GitHub PC Web·모바일 Pages는 아직 이 커밋으로 재빌드·교체하지 않았다.
- 측정은 Chromium 데스크톱 에뮬레이션과 Windows native headless에서 수행했다. 실제 저사양 Android/iOS 기기의 발열·메모리·장시간 전투는 공개 전 별도 확인이 권장된다.
- PC Web 관리 화면은 60fps지만 main-thread 여유가 모바일보다 작다. 이후 던전 규모가 커지면 정적 dungeon layer 캐싱 또는 MultiMesh 전환을 검토한다.
- `DemoSmokeTest`의 위 음악 종료 기대값은 현재 음악 상태 계약에 맞춰 별도 정리할 수 있다.

## 9. 다음 작업 순서

1. `codex/v05-platform-performance`를 검토해 소스 PR로 병합한다.
2. 병합된 태그 또는 승인 SHA에서 PC Web과 모바일 Web 테스트 브랜치를 각각 재빌드한다.
3. 실제 Android/iOS 1대 이상과 PC 저사양 브라우저에서 타이틀·관리·전투 10분 발열/메모리 확인 후 공개 테스트 링크를 교체한다.

## 10. 작업 트리 상태

- 구현 커밋 직후: `codex/v05-platform-performance...origin/main [ahead 1]`
- 구현 커밋: `113e85d0b2a045bc7c7cff81e1fbc07b529b90b2`
- 미커밋 파일: 이 핸드오프와 `docs/handoff/CURRENT.md` 문서 갱신분
- 의도하지 않은 기존 변경: 없음. 원래 작업 트리는 건드리지 않고 별도 worktree에서 작업했다.
- 스태시 또는 별도 작업공간: `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성_perf_v05`
- 빌드/캡처 산출물 위치: Git 비추적 `tmp/perf_web/`, `tmp/perf_mobile/`, `output/playwright/platform-after/`

## 11. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 PC Web·모바일 Web 실측 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 그래픽·오디오 자산 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 구현 파일만 커밋
- [ ] 원격 푸시 및 PR/공개 테스트판 교체
