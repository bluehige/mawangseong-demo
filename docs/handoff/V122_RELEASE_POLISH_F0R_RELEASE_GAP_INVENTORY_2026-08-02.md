# V1.2.2 릴리스 폴리시 F0-R 출시 공백 인벤토리 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: V1.2.2 release polish
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `origin/main` merge-base `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 기준 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- PR/태그: 없음 (사용자 요청 전 커밋·푸시하지 않음)

## 2. 이번 세션 목표

- 요청 사항: Luna 순차 실행 계획의 F0-R을 읽기 전용으로 완료한다.
- 완료 조건: 저장·복구, 입력·IME, UI·현지화, 성능, 권리·출처 다섯 영역의 권위 문서, 현재 증거, 미검수 공백, Q1 재현 입구와 소유 페이즈를 고정한다.
- 제외 범위: Q1 상세 감사, 런타임·데이터·자산 수정, 전체 회귀·전체 플레이, 후보 빌드, 커밋·푸시.

## 3. 완료 내용

- `tmp/v122_release_polish/f0_r/f0_r_inventory.json/tsv`에 Q1-S/I/L/P/R 다섯 행을 기록했다.
- P8·P17·P1·Stage 10/12·전투 오버레이 성능 문서를 다시 읽고, targeted PASS와 실제 OWNER/Windows 검수 대기를 구분했다.
- Q1-S/I/L/P를 `OWNER_QA_PENDING`, Q1-R을 `SOURCE_AUDIT_PARTIAL`로 고정했다. 이는 자동 검사가 실패했다는 뜻이 아니라 출시 후보에서 아직 닫지 않은 검수 입구라는 뜻이다.
- S09에서 알려진 `trap` 내부 ID P3, 실제 Windows GPU 장시간 성능 미검수, 1.2.1 저장 hash/mtime 미검수, F0-A의 BGM SOURCE 충돌을 다음 패킷 입력으로 남겼다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_F0R_RELEASE_GAP_INVENTORY_2026-08-02.md` | 다섯 Q1 영역의 공백·증거·재현 입구 요약 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_F0R_RELEASE_GAP_INVENTORY_2026-08-02.md` | F0-R 세션 인계 | 완료 |
| `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md` | F0-R 완료 및 Q1-S 대기 상태 반영 | 완료 |
| `docs/handoff/CURRENT.md` | F0-R 핸드오프 링크와 다음 작업 갱신 | 완료 |

임시 기계 산출물은 `tmp/v122_release_polish/f0_r/`에만 두었다.

## 5. 그래픽·오디오 자산과 실제 렌더 확인

- 신규 그래픽·오디오 생성 및 자산 교체: 없음.
- 화면 캡처·실제 플레이: 없음. F0-R은 기존 기록과 재현 입구만 정리했다.
- 후보 export·빌드·태그·Release: 없음.

## 6. 테스트 및 검증

| 순서 | 검증 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | F0-R JSON/TSV 5개 영역·상태·소유 페이즈 assertion | PASS | `tmp/v122_release_polish/f0_r/f0_r_inventory.json` |
| 2 | 참조 권위 문서 존재·핵심 상태 대조 | PASS | P1/P8/P17/Stage 10/12/성능/F0-V/F0-A 문서 |
| 3 | 전체 회귀/전체 플레이/후보 빌드 | NOT_REQUESTED | 이번 요청은 읽기 전용 출시 공백 목록화 |

### 정책 CI용 고정 필드

- Related tests: F0-R JSON/TSV 구조 assertion — PASS
- UI check: 해당 없음 — 화면·런타임 변경 없음
- Unresolved issues: Q1-S/I/L/P 사용자·Windows 검수 대기, Q1-R 전체 권리표 미완료, F0-A BGM SOURCE 충돌, S09 `trap` 내부 ID P3

## 7. 미해결 문제와 위험

- `READY_FOR_OWNER_FINAL_QA`는 정식 출시 완료가 아니다. OWNER 체크리스트가 통과되기 전에는 R1을 시작하지 않는다.
- F0-R의 상태는 Q1 상세 감사 전의 입구 상태다. 각 Q1에서 결함을 발견하면 한 결함당 별도 Luna 패킷으로 쪼갠다.
- 기존 dirty 13개와 F0-V/F0-A 문서 변경은 섞지 않고 보존한다.

## 8. 다음 작업 순서

1. `Q1-S 저장·복구`
2. `Q1-I 입력·IME`
3. `Q1-L UI·현지화`
4. `Q1-P 성능`
5. `Q1-R 권리·출처`

사용자가 별도로 전체 검수나 실제 후보 빌드를 요청하기 전에는 Quick/Full 전체 검증, export, 커밋·푸시를 하지 않는다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification` (origin보다 2커밋 앞섬)
- F0-R에서 새로 만든 문서: QA 보고서와 본 핸드오프
- 임시 산출물: `tmp/v122_release_polish/f0_r/` (커밋 대상 아님)
- 기존 사용자 변경: 6개 `.png.import` 수정, 7개 `.uid` 미추적, 기존 Luna 계획·F0-V·F0-A 문서와 CURRENT 변경을 보존
- 커밋/푸시: 수행하지 않음

## 10. 종료 체크리스트

- [x] 다섯 Q1 영역과 소유 페이즈 고정
- [x] 권위 문서·현재 증거·미검수 공백 기록
- [x] 재현 입구와 다음 순서 기록
- [x] JSON/TSV 기계 인벤토리 생성
- [x] QA 문서와 CURRENT/계획 갱신
- [ ] Q1 상세 감사
- [ ] 사용자 OWNER 최종검수
- [ ] 커밋·푸시
