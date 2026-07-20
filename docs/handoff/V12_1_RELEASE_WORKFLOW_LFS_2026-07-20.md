# 제품 1.2.1 태그 Windows LFS 빌드 방어 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-20
- 목표 버전: 제품 표시 1.2 / 기술 SemVer 1.2.1
- 작업 브랜치: `codex/v121-release-workflow-lfs`
- 기준 브랜치 및 SHA: `origin/main` / `c483d135b13cf9771ee43b045ba2c3dde51573ee`
- 마지막 기능·검증 도구 커밋 SHA: `655bef1bdf27b62907eec61c6a305ae28f732b0b`
- 원격 푸시 여부: 미푸시
- 관련 태그: `v1.2.1`은 계속 `c483d135b13cf9771ee43b045ba2c3dde51573ee`를 가리키며 이동하지 않음
- 원인 확인 대상: [태그 Actions run 29729582970](https://github.com/bluehige/mawangseong-demo/actions/runs/29729582970)

## 2. 이번 세션 목표

- 태그 Windows workflow가 Git LFS pointer를 실제 WAV로 오인한 채 성공하는 거짓 양성을 막는다.
- 내보낸 PCK에 필수 BGM 3개의 실제 Godot sample이 없으면 release validator가 실패하게 한다.
- artifact 업로드 전에 내보낸 Windows 실행 파일이 headless로 부팅되고 Godot runtime error를 내지 않는지 확인한다.
- 기존 `v1.2.1` 태그는 이동하지 않고, 이 변경은 별도 브랜치와 후속 PR 후보로만 남긴다.

## 3. 완료한 작업

- `actions/checkout@v5`에 `lfs: true`를 설정했다.
- 빌드보다 먼저 `git lfs fsck`를 실행하고 다음 세 WAV의 `RIFF`/`WAVE` 헤더를 직접 검사한다.
  - `assets/audio/bgm/combat_boss_council.wav`
  - `assets/audio/bgm/combat_dungeon_pressure.wav`
  - `assets/audio/bgm/management_castle_bustle.wav`
- Steam PCK validator가 위 세 WAV에 대응하는 `.godot/imported/<name>-*.sample`을 모두 요구하게 했다.
- 내보낸 `MawangCastle.exe --headless --quit-after 1`의 종료 코드와 `SCRIPT ERROR:`/`ERROR:` 출력을 artifact 업로드 전에 검사하게 했다.
- 누락된 필수 sample을 거부하는 회귀 테스트를 추가했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.github/workflows/build-windows-steam.yml` | LFS 실파일 checkout, 조기 WAV 검사, export 부팅 smoke | 완료 |
| `tools/release/validate_steam_release.py` | PCK 필수 runtime BGM sample 검사 | 완료 |
| `tools/ci/test_validate_steam_release.py` | 정상 PCK fixture 보강 및 필수 sample 누락 회귀 테스트 | 완료 |
| `docs/handoff/V12_1_RELEASE_WORKFLOW_LFS_2026-07-20.md` | 원인, 변경, 검증, 위험 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 및 release artifact 주의 갱신 | 완료 |

## 5. 원인과 기존 artifact 판정

- 기존 tag workflow checkout에는 `lfs: true`가 없었다.
- 해당 run에서 runtime WAV 3개는 각각 133바이트 Git LFS pointer였고 Godot 로그에는 `Not a WAV file`, 누락 sample, `GameRoot` preload parse error가 남았다.
- Godot import/export가 그 오류 뒤에도 종료 코드 0을 반환했고 기존 validator는 PCK 안의 필수 오디오를 요구하지 않아 run과 artifact upload가 성공으로 표시됐다.
- 따라서 run 29729582970의 artifact ID `8455749963`은 release에 사용하면 안 된다.
- 기준 태그 SHA를 로컬에서 다시 빌드한 `v1.2.1-workflow-baseline`은 manifest source commit이 `c483d135b13cf9771ee43b045ba2c3dde51573ee`이고, `MawangCastle.pck` SHA-256은 `ff212a7aa271f8963867ebc7346ba10e67c9aba9b3181c31b99634f89aac30d4`다. 이 로컬 경로는 검증 산출물이며 커밋하지 않았다.

## 6. 테스트 및 검증

| 순서 | 검증 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `python tools/ci/test_validate_steam_release.py` | PASS, 7/7 | 콘솔 기록 |
| 2 | `python tools/ci/test_validate_build_manifest.py` | PASS, 13/13 | 콘솔 기록 |
| 3 | `tools/ci/TestRepositoryPolicy.ps1` | PASS, 9/9 | 콘솔 기록 |
| 4 | PyYAML로 `.github/workflows/build-windows-steam.yml` parse | PASS | PyYAML 6.0.3, `YAML_PARSE_PASS` |
| 5 | `git lfs fsck` 및 runtime WAV 3개 `RIFF`/`WAVE` 검사 | PASS | `Git LFS fsck OK`, 3개 모두 `LFS_RUNTIME_WAV_PASS` |
| 6 | 강화 validator로 기준 태그 SHA 로컬 패키지 검사 | PASS, `STEAM_RELEASE: SETUP_PASS` | 외부 Steam 설정 17건만 기존대로 pending |
| 7 | 기능 SHA에서 `PrepareSteamBuild.ps1 -Version 1.2.1` | PASS, `STEAM_BUILD: PASS` | `builds/steam/windows/v1.2.1-workflow-hardened-warm-cache/` |
| 8 | 기능 SHA 새 패키지 `MawangCastle.exe --headless --quit-after 1` | PASS, exit 0 / runtime ERROR 0 | manifest source commit `655bef1bdf27b62907eec61c6a305ae28f732b0b` |
| 9 | `tools/ci/ValidateRepositoryPolicy.ps1 -BaseRef origin/main -HeadRef codex/v121-release-workflow-lfs` | PASS | docs commit 뒤 콘솔 기록 |

- Godot 4.5.2 fresh import는 전체 1,147개 asset import 종료 시 `signal 11` / `0xC0000005`로 두 번 종료됐다. 캐시를 보존해 import를 다시 실행하자 성공했고 이후 동일 기능 SHA의 package build와 smoke가 통과했다.
- Godot가 만든 `.import` 1,147개는 `git diff --quiet` 기준 내용 차이가 0인 줄바꿈·인덱스 갱신뿐이었고 모두 기능 diff에서 제외했다.
- 자동 생성 UID 5개도 격리 worktree에서 제거했다. 사용자 주 worktree의 기존 UID 5개는 건드리지 않았다.
- 전체 회귀, 전체 플레이 검수, Computer Use 검수는 이 최소 workflow 수정에서 요청되지 않아 실행하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 655bef1bdf27b62907eec61c6a305ae28f732b0b
- Review range: c483d135b13cf9771ee43b045ba2c3dde51573ee..655bef1bdf27b62907eec61c6a305ae28f732b0b
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 기존 `v1.2.1` 태그 run은 새 workflow를 소급 적용할 수 없다. 태그를 이동하지 말고, 현재 release에는 정확한 태그 SHA에서 별도로 재빌드·검증한 패키지만 사용해야 한다.
- fresh Godot import의 `0xC0000005`는 기존 핸드오프에도 기록된 비결정적 Windows importer 문제다. 이번 기능 SHA에서는 cache warm-up 뒤 package build가 성공했지만, 다음 깨끗한 runner 실행에서도 재발할 수 있다.
- 이 변경은 누락 오디오와 부팅 오류의 거짓 성공을 차단한다. importer 자체의 재시도·안정화는 이번 최소 변경 범위에 포함하지 않았다.
- Steam 외부 설정 17건은 기존과 같이 pending이며 이 workflow 변경이 해결하지 않는다.

## 8. 다음 작업 순서

1. 이 브랜치를 push하고 PR에서 `repository-policy`를 통과시킨 뒤 merge commit으로 `main`에 병합한다.
2. `v1.2.1` 태그는 이동·재지정하지 않는다.
3. 현재 1.2.1 GitHub Release에는 run 29729582970 artifact를 쓰지 말고, 정확한 태그 SHA `c483d135...`에서 LFS 실파일·PCK 필수 오디오·headless smoke까지 통과한 별도 패키지만 첨부한다.
4. 다음 새 불변 태그에서는 강화된 workflow run이 LFS, PCK audio, package boot를 모두 통과했는지 확인한다.

## 9. 작업 트리 상태

- 기능 커밋: `655bef1bdf27b62907eec61c6a305ae28f732b0b`
- 문서 커밋: 이 문서를 포함하는 후속 docs-only 커밋
- 원격 푸시 및 PR: 하지 않음
- 빌드 산출물: 격리 worktree의 ignored `builds/` 및 `tmp/`에만 존재하며 커밋하지 않음
- 의도 밖 tracked 변경 및 untracked UID: 없음
