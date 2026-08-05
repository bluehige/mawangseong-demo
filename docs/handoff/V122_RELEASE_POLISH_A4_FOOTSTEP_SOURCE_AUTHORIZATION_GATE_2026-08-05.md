# v1.2.2 A4 발소리 출처·생성 범위 승인 gate 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 실행하지 않음 (`HEAD`가 upstream보다 2커밋 앞섬)
- 관련 PR 또는 태그: 없음
- 패킷: `A4-FOOTSTEP-SOURCE-AUTHORIZATION-GATE`
- 결과: `A4_FOOTSTEP_SOURCE_AUTHORIZATION_GATE_PASS_PENDING_MANIFEST_APPROVAL`

## 2. 이번 세션 목표

- 요청 사항: 현재 잠긴 발소리 승인 gate를 수행하고, Sol을 최대치로 투입하는 기준에서 v1.2.2 마무리 잔여 작업을 브리핑한다.
- 완료 조건: 발소리 공백·최대 품질 범위·첫 후보·예상 비용·다음 승인 경계를 문서로 고정한다.
- 범위에서 제외한 사항: Lyria API 호출, manifest·catalog·코드·자산·source/runtime 변경, scheduler 구현, 전체 회귀, 빌드, 커밋, 푸시.

## 3. 완료한 작업

- 구현: 없음. 읽기 전용 감사만 수행했다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX: 변경 없음.
- 저장 및 호환성: 변경 없음.
- 오디오 감사: v1.2.2 manifest 80개와 catalog 80 assets/72 events에 발소리 항목이 0개임을 확인했다.
- 자산 감사: runtime·source 전용 발소리가 각각 0개임을 확인했다.
- 품질 계약: surface 3종 × 변형 3개 = 9 cue, normal/heavy 2개 runtime 프로필로 고정했다.
- 첫 후보: `footstep_cave_rough_01`, `lyria-3-clip-preview`, 요청당 예상 `$0.04`로 제안했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_A4_FOOTSTEP_SOURCE_AUTHORIZATION_GATE_2026-08-05.md` | 발소리 공백·범위·첫 후보·비용 감사 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_FOOTSTEP_SOURCE_AUTHORIZATION_GATE_2026-08-05.md` | 세션 결과와 마무리 잔여 작업 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 완료 패킷과 다음 단일 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: 없음
- 생성 원본 경로: 없음
- `SOURCE.md` 경로: 없음
- 런타임 최종 자산 경로: 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 없음
- 게임 연결 및 실제 렌더 확인 결과: 이번 패킷은 읽기 전용 승인 gate로 생성·연결·청취하지 않음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | manifest JSON에서 전용 발소리 ID·path·kind 검색 | PASS — 0개 확인 | `tools/audio/lyria_v122_manifest.json` |
| 2 | catalog JSON에서 전용 발소리 asset·event 검색 | PASS — 0개 확인 | `data/audio/audio_event_catalog.json` |
| 3 | runtime·source 파일 검색 | PASS — 전용 발소리 0개 확인 | `assets/audio`, `assets/source/audio` |
| 4 | A4 계획의 surface·weight·voice 계약 확인 | PASS | `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md` |
| 5 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 밖 |

API 호출·유료 요청·신규 음원 생성은 0회다.

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 읽기 전용 감사와 문서 갱신, 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 발소리 9 cue, normal/heavy 프로필, 발 접촉 scheduler, x3 밀도 감소, 동시 voice 3개 제한이 아직 구현되지 않았다.
- catalog 80개 전부 `review_status=pending`이며, actual runtime 70개 중 source record가 missing인 자산이 17개다.
- catalog의 unconnected 자산 10개(`heart_ready`, `monster_signature_01`~`09`)는 출시 전 연결·퇴역 판정이 필요하다.
- 캐릭터 프로필 연결은 완료됐지만 V3 원본 상태 승격과 대표 동작 검수가 남아 있다.
- Q1-S Stage 04 `service_entrance` 투영 계약, Q1-L 사용자 용어 3건, Windows IME·모바일·성능 실기 gate가 남아 있다.
- 작업 트리는 다수의 기존 변경과 신규 파일이 섞인 미커밋 상태다. 출시 전 기능 SHA를 정리하고 선별 커밋·통합해야 한다.

## 8. 다음 작업 순서

1. `A4-FOOTSTEP-CAVE-ROUGH-01-MANIFEST-CONTRACT`: 첫 cue 한 개를 `planned`로 등록하고 파이프라인 테스트·무료 dry-run을 통과한다. API 호출은 금지한다.
2. 사용자 별도 승인 뒤 `A4-FOOTSTEP-CAVE-ROUGH-01-GENERATION-TAKE01`: Lyria clip 요청 1회(예상 `$0.04`)만 실행한다.
3. 후보 청취 승인 → source/runtime 승격 → catalog 등록 → scheduler 연결 → 대표 전투 청취를 각각 별도 패킷으로 수행한다.
4. surface 3종의 총 9 cue와 normal/heavy 프로필을 같은 규칙으로 완료한다.
5. 오디오 catalog 청취·권리·출처·연결 gate와 A1-C loop seam, A1-B clipping, A5 최종 믹스를 닫는다.
6. V3 원본 승격·대표 동작, Q1 제품 결정·실기, DAY 1~30 사용자 검수와 출시 후보 절차를 진행한다.

## 9. Sol 최대 투입 기준 마무리 브리핑

Sol이 코드·문서·자동 검증을 최대치로 처리해도 아래 사용자·외부 gate는 대신 완료할 수 없다.

- 실제 청취 승인: 발소리·BGM·스킬음·최종 믹스
- 실제 Windows 조작: 한국어 IME, 후보 빌드, 장시간 성능·발열·메모리
- 실제 플레이: DAY 3 핵심 체감, DAY 6~30 대사·분기·엔딩
- 제품 결정: Stage 04 `service_entrance` 투영 포함 여부, 공개 게임명·가격·출시일
- 권리·사업: 오디오/그래픽 권리 승인, Steamworks 계약·등록비·세금/은행·App/Depot ID·스토어 심사

Sol이 직접 마무리할 수 있는 저장소 작업은 발소리·오디오 계약 구현, visual source 승격, P2 결함 보정, 대상 테스트, 문서 정리, 선별 커밋·PR, 요청 시 Full 검증과 후보 export다.

## 10. 작업 트리 상태

- `git status --short --branch`: `codex/v122-ui-simplification`, upstream보다 2커밋 앞섬, 기존 수정·신규 파일 다수
- 미커밋 파일: 기존 사용자·Luna 작업이 대량으로 섞여 있음
- 의도하지 않은 기존 변경: 보존했으며 수정·되돌림하지 않음
- 스태시 또는 별도 작업공간: 사용하지 않음
- 빌드/캡처 산출물 위치: 이번 패킷에서 생성하지 않음
- 커밋·푸시: 실행하지 않음

## 11. 종료 체크리스트

- [x] 요구사항과 현재 NEXT 패킷 대조
- [x] manifest·catalog·runtime·source 읽기 감사
- [x] 최대 품질 발소리 범위와 첫 후보 고정
- [x] 유료 호출 0회 확인
- [x] 전체 검수 미요청 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 다음 패킷 자동 실행 금지
- [ ] 사용자 승인 후 첫 manifest 패킷 실행
- [ ] 커밋·푸시
