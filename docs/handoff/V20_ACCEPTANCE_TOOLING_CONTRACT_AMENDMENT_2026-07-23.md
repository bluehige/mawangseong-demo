# DAY 1~5 수용 테스트 키트 계약 보완

- 작성일: 2026-07-23
- 대상 브랜치: `release/v2.0`
- 작업 브랜치: `codex/v20-validation-acceptance-tooling-contract-amendment`
- base SHA: `28c6740f635e0cfffd57405879d4cdbb495d0c6b`
- 변경 종류: docs 전용
- 제품 코드·data·scene·asset 변경: 0개

## 보완 이유

기존 PR 5 allowlist에는 물리 trial·summary와 수동 기록 템플릿만 있었다. 다음 항목은 계약에 요구됐지만 실제 파일 경로와 전달·회수 규칙이 없었다.

1. 참가자마다 `user://v20/`을 분리하는 실행기
2. title 노출부터 첫 배치·상태 체류·invalid 시도·20초 입력 공백을 저장하는 기록기
3. 전투마다 기존 raw `v20_evidence`를 보존하는 checkpoint
4. 고정 다섯 질문과 관찰자 개입을 받는 회수 절차
5. crash와 30분 종료에서도 부분 원본을 남기는 결과 ZIP
6. 합성 persona와 실제 FU01~FU10을 분리하는 evidence kind
7. 후보 20전과 공식 물리 70전의 process·분모 분리

이 경로들이 allowlist 밖인 상태에서 코드부터 추가하면 상위 계약 14절을 위반한다. 그래서 PR 5 코드보다 이 docs 변경을 먼저 병합한다.

## 고정한 플레이어·관찰자 행동

- 관찰자는 고정 SHA kit의 `Start-Test.cmd`를 실행하고 `FU01`~`FU10`만 입력한다.
- launcher는 기존 session을 삭제하거나 덮어쓰지 않고 참가자별 새 `APPDATA`·`LOCALAPPDATA`에서 게임을 시작한다.
- 참가자는 title 화면부터 최대 30분 동안 설명 없이 플레이한다.
- 게임 종료 뒤 launcher가 계약의 다섯 질문을 그대로 받고 `<FU ID>_result.zip`을 만든다.
- crash, hard lock, save 오류와 결과 미도달도 부분 ZIP과 runtime log로 제품 실패에 남긴다.
- `AGENT-*` persona는 같은 UI와 패키징 경로를 사전 점검하지만 `synthetic_preflight`로 고정하며 사람 PASS에 넣지 않는다.

## 고정한 시스템 규칙

- 참가자 기록기는 debug acceptance mode와 명시적 participant ID가 함께 있을 때만 켜진다.
- 기록기는 `RAW_ONLY`, `PENDING_HUMAN_REVIEW`만 쓰며 재미·진행 단순성·밸런스 판정을 만들지 않는다.
- 공식 물리 runner는 한 process에서 한 전투만 실행한다. orchestrator가 primary 60전과 replay 10전을 정확히 생성한다.
- Windows와 Web는 같은 clean source SHA의 `--export-debug`만 허용한다.
- `v1.2.1` tag·Release·저장·PC/모바일 공개본은 변경하지 않는다.

## 수정 파일

- `docs/design/V20_DAY1_5_IMPLEMENTATION_PR_PLAN.md`
- `docs/playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md`
- `docs/handoff/V20_ACCEPTANCE_TOOLING_CONTRACT_AMENDMENT_2026-07-23.md`
- `docs/handoff/CURRENT.md`

## 판정

- 세 제품 가설: `PENDING`
- PR 5 구현 진입: 이 docs PR이 `release/v2.0`에 merge된 뒤 `GO`
- 자동 출력·합성 persona로 사람 PASS 처리: 금지
- `release/v2.0` 전체 병합·v1.2.1 변경: 금지

## 다음 작업

1. 이 docs 전용 PR을 repository-policy 통과 뒤 merge commit으로 `release/v2.0`에 병합한다.
2. merge SHA에서 PR 5 구현 브랜치를 갱신한다.
3. 기록기·한 process 한 전투 runner·격리 launcher·결과 ZIP을 구현하고 self-test한다.
4. 기능 SHA를 고정한 뒤 Full 자동 계약, 물리 70전, Windows·Web debug build, 합성 persona UI preflight를 실행한다.
5. 숙련 QA 24전과 실제 FU01~FU10 10명은 같은 고정 build로만 실행한다. 실제 사람이 없으면 상태를 `PENDING`으로 유지한다.

## 검토 예약 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: `5938eb7b0e5aa46f78a10958dfb6adeab644ace7`
- Review range: `28c6740f635e0cfffd57405879d4cdbb495d0c6b..5938eb7b0e5aa46f78a10958dfb6adeab644ace7`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
