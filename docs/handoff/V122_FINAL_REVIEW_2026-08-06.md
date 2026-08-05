# v1.2.2 최종 SHA 검수·Windows 후보 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/main` / `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 검수·빌드 기능 SHA: `74bac37d6928e0540a489b92b389021e349d80c3`
- 원격 푸시 여부: 이 문서 작성 시점에는 미푸시. 원격 작업 브랜치보다 5커밋 앞선다.
- 관련 PR 또는 태그: 기존 Draft PR `#80`; `v1.2.2` 태그와 GitHub Release는 아직 생성하지 않았다.

## 2. 이번 세션 목표

- 요청 사항: 사용자 화면 검수에서 발견된 구조벽·전투 깊이·방 지침 가독성 결함을 반영한 뒤 최종 검수를 수행한다.
- 완료 조건: 수정 내용을 커밋 SHA로 고정하고, 독립 코드 리뷰에서 P1/P2/P3 0건, 같은 깨끗한 SHA에서 Full 156/156 PASS, 새 Windows release export·실제 부팅·ZIP 해시 검증을 모두 통과한다.
- 범위에서 제외한 사항: 코드 서명 인증서 구매·적용. 기능 SHA 이후에는 저장소 정책에 따라 `docs/handoff/`만 수정한다.

## 3. 완료한 작업

- 구조벽·깊이: 바닥 `z=0`, 전투 유닛 `z=1..44`, 전면 오브젝트 `z=30`, 전면 구조벽 `z=50`의 실제 Canvas 계층을 구성했다. 따라서 유닛은 바닥보다 앞에 있고, 맵 아래쪽 유닛은 전면 가구보다 앞에, 위쪽 유닛은 전면 가구보다 뒤에 보인다.
- 구조벽 가림: 카메라 뒤쪽 N/W 구조벽은 불투명도 `0.94`, 앞쪽 E/S 구조벽은 `0.46` 반투명으로 유지해 통로 경계와 가려진 캐릭터를 함께 읽을 수 있게 했다. 모바일 프로필의 N/W 벽 누락도 원래 계약대로 복구했다.
- 실화면 검증 강화: topology 사각형이 아니라 실제 구조벽 PNG draw rect와 불투명 픽셀을 찾고, 실제 캐릭터의 불투명 픽셀을 같은 화면 좌표에 강제로 겹쳐 전면 벽 반투명과 깊이를 검증하도록 캡처를 보강했다.
- 전면 장식 깊이: 기존에 선언만 돼 있던 `ObjectFrontLayer(z=30)`에 실제 Canvas를 연결하고 전면 장식·시설을 해당 계층에서 그리도록 수정했다.
- 방 지침 가독성: 1280×720에서 축소돼 약 9px로 보이던 선택 글자를 20px, 버튼 높이를 46px로 키웠다. 펼침 목록·튜토리얼 강조 링·설명·아래 시설 패널이 겹치지 않는 것을 실제 Vulkan 캡처로 확인했다.
- 검수 중 발견·수정: 독립 1차 리뷰가 전면 장식 계층 미연결, 실제 PNG 겹침을 증명하지 못한 캡처, 모바일 후면 벽 누락, 오래된 VFX 상태 문자열을 지적했다. 모두 수정하고 관련 계약 테스트를 강화한 뒤 재검수했다.
- 사용자 gate: 사용자는 실제 Windows 후보에서 한국어 IME가 정상이라고 확인했으며 커밋·푸시·PR·태그·Release 진행을 승인했다.
- 스토리·밸런스·저장 형식·그래픽·오디오: 이번 최종 보정으로 내용 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/asset_manifest.json` | 공통 구조벽 전면 반투명 계약 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 바닥·유닛·전면 장식·구조벽 실제 계층과 디버그 표본 API | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd` | 전면 장식 전용 Canvas draw scope | 완료 |
| `scripts/game/CombatSceneController.gd` | 전투 깊이 fallback 정렬 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 방 지침 글자·버튼·패널 간격 확대 | 완료 |
| `scripts/units/Unit.gd` | 유닛 최솟값을 바닥 위로 고정 | 완료 |
| `tools/RoleCombatLayoutCapture.gd` | 실제 불투명 벽·캐릭터 픽셀 강제 겹침 캡처 | 완료 |
| `tools/TutorialUxCapture.gd` | 1280×720 펼침 목록 가독성 검증 | 완료 |
| `tools/tests/V122CombatVfxDepthLiveContractTest.gd` | 실 Canvas·전면 장식·유닛 깊이 계약 | 완료 |
| `tools/tests/V122FrontWallActorVisibilityTest.gd` | 전면 벽 실제 draw rect·alpha 표본 계약 | 완료 |
| `tools/tests/V122V4ADepthSlotContractTest.gd` | V4-A 깊이 슬롯·live 상태 계약 | 완료 |
| `docs/handoff/V122_*WALL*`, `V122_UNIT_ABOVE*`, `V122_ROOM_DIRECTIVE*` | 사용자 검수별 수정·폐기·대체 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 최종 보정에서는 사용하지 않음.
- 생성 모델: 해당 없음.
- 생성 원본 경로: 변경 없음.
- `SOURCE.md` 경로: 변경 없음.
- 런타임 최종 자산 경로: PNG·WAV 파일 변경 없음.
- 프롬프트/후처리/크롭/알파 처리 요약: 신규 자산 후처리 없음. 기존 구조벽의 런타임 draw alpha와 계층만 수정했다.
- 게임 연결 및 실제 렌더 확인 결과: `tmp/role_combat_verification/06_combat_front_wall_transparency.png`, `07_combat_top_floor_depth.png`, `08_combat_bottom_floor_depth.png`에서 전면 벽 반투명과 위치별 Y-depth를 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 전면 벽·유닛 실픽셀 계약 | PASS, 33 assertions | `tools/tests/V122FrontWallActorVisibilityTest.tscn` |
| 2 | 전투 VFX·전면 장식 live 깊이 계약 | PASS, 29 assertions | `tools/tests/V122CombatVfxDepthLiveContractTest.tscn` |
| 3 | V4-A 깊이 슬롯 계약 | PASS | `tools/tests/V122V4ADepthSlotContractTest.tscn` |
| 4 | 실제 Vulkan 역할·전투 레이아웃 캡처 | PASS | `tmp/role_combat_verification/` |
| 5 | 직접 관련 회귀 8종 | PASS | Quarter module, topology, combat hierarchy, heart chamber, engineer performance 관련 테스트 |
| 6 | 기능 커밋 전 작업 트리 Full | PASS, 156/156 | `tmp/core_verification/runs/20260806_022955/report.json` |
| 7 | 기능 SHA 고정 Full | PASS, 156/156, 실패 0, 1167.14초 | `tmp/core_verification/runs/20260806_025734/report.json` |
| 8 | 독립 코드 리뷰 | PASS, P1/P2/P3 0건 | 검수 에이전트 `019fd2d3-6398-7d50-a0c2-1ce3068de487` |
| 9 | Windows Desktop release export | PASS, stderr 0 | `tmp/v122_final_review_candidate/74bac37/export.stdout.log` |
| 10 | Windows 1280×720 실제 부팅 10초 | PASS, 조기 종료·오류 0 | `tmp/v122_final_review_candidate/74bac37/windows_boot_1280x720.log` |
| 11 | ZIP 2개 엔트리 내부 SHA-256 재검산 | PASS, EXE/PCK 모두 원본과 일치 | `tmp/v122_final_review_candidate/74bac37/SHA256SUMS.txt` |
| 12 | `git diff --check` 및 Google API 키 형태 검색 | PASS, 형식 오류 0·키 패턴 0 | 최종 로컬 명령 결과 |

실행환경 참고: SHA 고정 Full을 시작할 때 Windows 자동화 셸의 `Path`/`PATH` 중복과 외부 Godot 접근 제한으로 두 차례 0초 실행기 실패가 있었다. 제품 테스트가 시작되지 않은 인프라 실패였으며, 중복 키를 현재 프로세스에서만 정규화하고 승인된 Godot 경로를 사용한 `20260806_025734` 실행이 공식 결과다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `019fd2d3-6398-7d50-a0c2-1ce3068de487` | `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..74bac37d6928e0540a489b92b389021e349d80c3` | `74bac37d6928e0540a489b92b389021e349d80c3` | 사전 작업 트리에서 P2 2건·P3 2건 발견 | 실제 ObjectFront Canvas, 실픽셀 캡처, 모바일 후면 벽, live 상태 계약 보정 | 위 코드·테스트 및 `tmp/role_combat_verification/` | 최종 SHA P1 0 / P2 0 / P3 0, PASS |

- 남은 P1/P2 지적: 0건.
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: 019fd2d3-6398-7d50-a0c2-1ce3068de487
- Reviewed SHA: 74bac37d6928e0540a489b92b389021e349d80c3
- Review range: 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..74bac37d6928e0540a489b92b389021e349d80c3
- Remaining P1/P2: 0
- Final review result: PASS

## 7. Windows 최종검수 후보와 해시

- 후보 폴더: `tmp/v122_final_review_candidate/74bac37/`
- ZIP: `MawangCastle-v1.2.2-Windows.zip`, 311,464,371 bytes
- EXE: `MawangCastle_v1.2.2.exe`, 96,523,776 bytes
- PCK: `MawangCastle_v1.2.2.pck`, 281,961,144 bytes
- EXE SHA-256: `BA355653BCD0D5A43DEFD7E4CC3FDF837ECB61D96B4047B4162364E9582C9413`
- PCK SHA-256: `DEDB31B268AEDAE967B8A48BF6D9FD3B39826901C9FB5636DA5F9B3531483ECE`
- ZIP SHA-256: `21D6E2B3924A8328F323742A25382BCB58F969699C64AB85E4EE11AD3D252EFC`
- Windows File/Product version: `1.2.2.0`
- 코드 서명: `NotSigned`. 기능·부팅 결함은 아니지만 외부 배포에서 SmartScreen 경고가 표시될 수 있다.

## 8. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동·독립 검수 범위의 출시 차단 문제는 없다.
- 밸런스 관찰 항목: 자동 장기 시뮬레이션은 전부 통과했다. 실제 사용자의 재미·체감 난이도는 자동 검사가 대신 판단하지 않는다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 코드 서명 인증서가 없어 EXE는 `NotSigned`다.
- 출시 절차: 작업 브랜치 푸시, PR merge commit, 병합 SHA 재빌드, `v1.2.2` 태그와 GitHub Release 게시가 남았다.

## 9. 다음 작업 순서

1. 이 문서와 `docs/handoff/CURRENT.md`만 문서 전용 커밋으로 고정한다.
2. `codex/v122-ui-simplification`을 푸시하고 기존 Draft PR `#80`을 최신화한 뒤 `release/v1.2.2`에 merge commit으로 병합한다.
3. 병합 SHA에서 Windows 후보를 다시 export·부팅·해시 검증하고, 이동하지 않는 `v1.2.2` 태그와 GitHub Release에 ZIP 및 해시 목록을 게시한다.

## 10. 작업 트리 상태

- 기능 검수 시 `git status --short --branch`: 깨끗함, `codex/v122-ui-simplification`이 원격보다 5커밋 앞섬.
- 미커밋 파일: 기능 SHA 이후 이 최종 핸드오프와 `docs/handoff/CURRENT.md`만 추가·수정 예정.
- 의도하지 않은 기존 변경: 없음.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v122_final_review_candidate/74bac37/`, `tmp/role_combat_verification/`, `tmp/core_verification/runs/20260806_025734/`.

## 11. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 전체 Full 156/156 통과
- [x] 독립 검수 에이전트 P1/P2/P3 0건
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] Windows export·부팅·ZIP·SHA-256 검증
- [x] 사용자 한국어 IME 확인
- [x] 그래픽·오디오 출처 변경 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 문서 전용 커밋
- [ ] 원격 푸시·PR 병합·`v1.2.2` 태그·Release
