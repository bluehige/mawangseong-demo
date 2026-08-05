# v1.2.2 V2-P4B `stone_sentinel` 자산 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음
- 작업 패킷: `V2-P4B-ASSET-STONE`

## 2. 이번 세션 목표

- 요청 사항: 문서의 다음 패킷 하나만 처리하고 돌콩 기본 계약 전투 자산 1개를 만든다.
- 완료 조건: GPT 내부 이미지 생성 원본, `SOURCE.md`, 192×192 셀 16프레임 런타임 시트, 직접 검수를 남긴다.
- 범위에서 제외한 사항: 제품 데이터·코드·씬 연결, 초상화·VFX·오디오, UI·실플레이, 다음 CONNECT 패킷, 공통 V3 정규화.

## 3. 완료한 작업

- 구현: 돌콩 기본 전투 4×4 원본과 투명 런타임 시트를 생성·후처리했다.
- 스토리 및 데이터: 변경 없음. `stone_sentinel`의 제품 sprite/profile 연결은 다음 패킷으로 분리했다.
- 밸런스: 변경 없음.
- UI/UX: 변경 없음.
- 그래픽: 숯빛 회색 현무암 몸체, 짧은 뿔, 접힌 돌날개, 가슴 성문 문양, 호박색 눈을 가진 작은 석상 파수꾼 16프레임을 만들었다.
- 행 계약: `idle_down 2 + down 2 / move_down 4 / attack_down 4 / skill_down 4`를 4×4 시트에 배치했다.
- 후처리: 녹색 크로마와 가장자리 녹색 번짐을 제거하고, 투명 192×192 셀 16개를 768×768 RGBA 시트로 조립했다.
- 다음 제안: `V2-P4B-CONNECT-STONE` 하나. 이번 핸드오프에서는 실행하지 않는다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/update4_contract_monsters/dolkong/dolkong_combat_sheet_chroma_2026-08-04.png` | GPT 내부 이미지 생성 원본 | 완료 |
| `assets/source/imagegen/update4_contract_monsters/dolkong/SOURCE.md` | 생성 모델·날짜·대상 버전·후처리 출처 | 완료 |
| `assets/sprites/monsters/update4/monster_dolkong_sheet.png` | 192×192 셀 16프레임 투명 런타임 시트 | 완료 |
| `docs/qa/V122_V2_P4B_STONE_ASSET_2026-08-04.md` | 자산 직접 검수와 다음 패킷 제안 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_V2_P4B_STONE_ASSET_2026-08-04.md` | 패킷 종료 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 완료 패킷과 CONNECT 제안 잠금 | 검수 필요 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예.
- 생성 모델: `GPT internal image generation`
- 생성 원본 경로: `assets/source/imagegen/update4_contract_monsters/dolkong/dolkong_combat_sheet_chroma_2026-08-04.png`
- `SOURCE.md` 경로: `assets/source/imagegen/update4_contract_monsters/dolkong/SOURCE.md`
- 런타임 최종 자산 경로: `assets/sprites/monsters/update4/monster_dolkong_sheet.png`
- 프롬프트/후처리/크롭/알파 처리 요약: 작은 회색 석상 파수꾼과 4×4 동작 행 계약을 명시해 생성했다. 1254×1254 RGB 원본을 4×4 셀 경계로 분리하고 녹색 크로마·가장자리 번짐 제거, 투명 192×192 셀 맞춤 후 768×768 RGBA 시트로 조립했다.
- 게임 연결 및 실제 렌더 확인 결과: 연결하지 않음. 다음 `V2-P4B-CONNECT-STONE` 범위다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 원본·런타임 이미지 크기/형식·SHA-256 확인 | PASS | `docs/qa/V122_V2_P4B_STONE_ASSET_2026-08-04.md` |
| 2 | 4×4 16셀 존재·행 계약·각 셀 visible pixel·중복 해시 확인 | PASS | 같은 QA 보고서 |
| 3 | 네 모서리 투명·순수 크로마 잔류 0·녹색 우세 잔류 0 확인 | PASS | 같은 QA 보고서 |
| 4 | 전체 회귀 테스트 | NOT_REQUESTED | 자산 단일 패킷 |
| 5 | 시각/실플레이 검수 | NOT_REQUESTED | 런타임 연결 전 |

### 검수 에이전트 반복 기록

- 검수 에이전트는 요청되지 않았고 실행하지 않았다.
- 남은 P1/P2 지적: 제품 profile·data가 아직 기존 슬라임 경로를 가리키므로 다음 CONNECT 패킷에서 연결해야 한다.
- 실행하지 못한 필수 검수와 이유: `1280×720` 대표 화면과 접지·배율 확인은 CONNECT 패킷 범위다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A — 자산 단일 패킷의 정책 필드
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 새 돌콩 시트는 아직 제품 데이터에 연결하지 않았으므로 현재 게임의 `stone_sentinel` 표시에는 영향을 주지 않는다.
- 밸런스 관찰 항목: 해당 없음.
- 임시 구현 또는 대체 자산: 기존 `monster_slime_idle_down_00.png` 공유 경로는 CONNECT 전까지 유지된다.
- 외부 환경/도구 제약: 실제 게임 화면의 접지·크기·가림 검수는 CONNECT 패킷에서 실행해야 한다.

## 8. 다음 작업 순서

1. 다음 별도 turn에 `V2-P4B-CONNECT-STONE` 카드 하나만 연다.
2. `data/monsters.json`과 `data/v122/combat_visual_profiles.json`에 돌콩 런타임 시트 1개만 연결한다.
3. 직접 계약 검사와 `1280×720` 대표 화면 확인 후 다음 패킷을 제안한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`이 원격보다 2커밋 앞서며 기존 Luna 구현과 여러 감사 문서가 함께 미커밋된 혼합 상태다.
- 미커밋 파일: 이번 패킷의 원본·`SOURCE.md`·런타임 시트·QA·핸드오프·CURRENT와 기존 변경 다수.
- 의도하지 않은 기존 변경: 보존했으며 되돌리거나 스테이징하지 않았다.
- 스태시 또는 별도 작업공간: 만들지 않음.
- 빌드/캡처 산출물 위치: 이번 패킷에서는 제품 빌드·캡처를 생성하지 않음.

## 10. 종료 체크리스트

- [x] 패킷 목표와 범위 대조 완료
- [x] 생성 원본·출처·런타임 시트 기록 완료
- [x] 4×4/16셀/투명도/크로마 직접 검사 통과
- [x] 제품 데이터·코드·씬 연결은 실행하지 않음
- [x] 전체 회귀·실플레이·검수 에이전트는 요청되지 않아 실행하지 않음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록

Related tests: 4×4/16셀/행 계약, RGBA 투명도, 순수 크로마 0, 녹색 우세 0, 중복 해시 0, SHA-256 검사 PASS
UI check: 런타임 연결 전이라 실행하지 않음
Unresolved issues: 제품 profile/data가 아직 기존 슬라임 경로를 참조하며 다음 패킷은 `V2-P4B-CONNECT-STONE` 하나로 잠김
