# v1.2.2 정식 출시 마무리 — Luna 순차 실행 계획

작성일: 2026-08-02

상태: **AUDIT_CORRECTION_IN_PROGRESS.** V1/V2 결과는 현재 미커밋 작업 트리의 구현·대상 테스트 결과이며 최종 승인본이 아니다. V2-P4는 `SCOPE_BLOCKED`, V3/V4는 미완료다. A0/A1/C1/V5는 순서 밖 선행 구현으로 보존하되 재검증 전에는 완료로 세지 않는다. 이번 감사의 현재 판정은 `docs/handoff/V122_RELEASE_POLISH_LUNA_AUDIT_CORRECTION_2026-08-02.md`가 대체한다.

감사 보정 규칙: 같은 기능·데이터·자산 파일이 뒤 단계에서 다시 바뀌면 앞선 dirty-worktree PASS는 현재 승인 근거가 아니다. 최종 기능 SHA를 고정한 뒤 관련 테스트와 필수 실제 화면 gate를 다시 통과해야 해당 페이즈를 완료로 바꿀 수 있다.

대상 버전: 제품 `1.2.2`

계획 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

주 출시 플랫폼: Windows

## 1. 목적

이 계획은 정식 출시 전에 남은 사운드, 캐릭터 접지, 전투 타격감, 그래픽 통일, 실제 플레이 검수 공백을 닫기 위한 순차 실행 문서다.

여기서 **작업 패킷**은 Luna가 새 대화 또는 한 번의 작업 세션에서 처음부터 끝까지 처리하는 가장 작은 단위를 뜻한다. Luna의 이전 대화 기억에 의존하지 않고, 각 패킷은 입력 파일·허용 범위·완료 조건·검사·인계 문서를 자체적으로 갖는다.

이 문서에서 **Luna는 구현을 수행하는 작업 모델**, **Lyria는 최종 사운드 후보를 만드는 오디오 생성 파이프라인**을 뜻한다. 두 이름과 역할을 혼동하지 않는다.

- 여러 결함을 한 번에 고치지 않는다.
- 공통 계약을 먼저 만들고 자산은 작은 묶음으로 적용한다.
- 실제 화면이나 소리를 사용자에게 보여 주지 않은 상태로 승인 완료를 선언하지 않는다.
- 자동 검사는 파일 연결과 수치 계약을 확인하고, 실제 화면·청취 검수는 체감 품질을 확인한다.
- 출시 후 확장 기능을 출시 전 필수 범위와 섞지 않는다.

## 2. 사용자와 확정한 최종 방향

1. 전체 분위기는 `묵직한 회흑색 던전 70% + 캐릭터 개성·코미디 30%`다.
2. BGM 상태는 `타이틀 / 관리 / 일반 전투 / 후반 전투 / 보스 전투 / 최종전·엔딩` 6개다.
3. 기본 공격은 실제 무기와 피격 재질의 무게감을 사용하고, 고유 스킬은 판타지 효과를 강조한다.
4. 지상 캐릭터는 캐릭터별 발 위치와 작은 회흑색 접지 그림자를 사용한다.
5. 명시적 점프·비행 동작을 제외한 지상 idle·move·attack·skill 프레임의 발 위치 흔들림은 실제 `1280×720` 화면에서 2픽셀 이내로 제한하고, down은 별도 바닥 앵커를 유지한다.
6. 비행형만 별도 공중 규칙을 사용하고, 점프·돌진 외 지상 캐릭터는 바닥에서 이탈하지 않는다.
7. 맵별 환경음과 바닥 재질별 절제된 발소리를 출시 범위에 포함한다.
8. 기존 보조 합성음 48개는 전면 교체하지 않고, 실제 노출도와 품질을 기준으로 선별 교체한다.
9. 캐릭터는 맵 한 칸과의 비율로 정규화한 뒤 일반 체격을 현재 기준보다 약 15% 키운다.
10. 전투 이펙트는 평소 절제하고 치명타·보스·마지막 일격만 강하게 표현한다.
11. 기존 캐릭터 자산을 먼저 정규화하고, 원근·실루엣·그림체가 여전히 맞지 않는 자산만 선별 재제작한다.
12. 새 사운드는 생성 출처와 후처리를 기록하고 실제 게임 비교 청취를 통과한 것만 승격한다.
13. 출시 필수와 출시 완성도 항목은 출시 전에 끝내고, 비용이 큰 고급 확장 기능만 출시 후로 미룬다.

## 3. 코드·자산 감사에서 확인된 현재 공백

### 3.1 오디오

- WAV는 76개이며 약 54개만 실제 재생 경로에 연결돼 있고 22개는 파일만 존재한다.
- 현재 BGM은 관리·일반전·보스전 3개다. 일반전 외 일부 곡은 반복 설정이 빠져 곡 길이가 끝난 뒤 무음이 될 수 있다.
- 타이틀 BGM, 후반 전투 BGM, 최종전·엔딩 BGM이 없다.
- 일반 공격은 베기·방패·화염·피격·다운의 소수 공통음에 크게 의존한다.
- 고유 스킬 24개는 개별 소리가 있지만 Update 3·4의 여러 보조음과 모티프는 데이터에만 있고 실제 이벤트와 연결되지 않았다.
- UI 전용음, 맵 환경음, 발소리가 없다.
- `Master / Music / SFX`만 있고 Master limiter, 전체 효과음 동시 재생 상한, UI·환경음 분리, 중요 경보 시 음악 낮춤이 없다.
- 설정 화면은 실시간 미리듣기를 안내하지만 타이틀이 무음이라 슬라이더 변화가 체감되지 않는다.
- 의미가 다른데 실제 파일 해시가 같은 중복 음원 두 쌍이 있다.
- 기존 Lyria 파이프라인으로 승격하고 출처를 기록한 자산 28개와 단순 합성 보조 자산 48개가 섞여 있다. 28개도 사람의 최종 믹스·반복 피로 청취를 아직 통과하지 않았으므로 출처 기록만으로 청취 승인으로 간주하지 않는다.

### 3.2 캐릭터 접지와 전투 화면

- 모든 지상 캐릭터에 동일한 `scale=0.42`, `sprite_y=-37`을 적용하며 캐릭터·프레임별 발 기준점이 없다.
- 이동 중 캐릭터 몸 전체를 최대 3.2픽셀, 슬라임은 4픽셀 위로 올리지만 그림자는 고정돼 떠 보인다.
- 일부 도둑·슬라임 공격 프레임은 기준 발 위치에서 10픽셀 이상 벌어진다.
- Update 4의 큰 원본 시트도 같은 배율을 사용해 기존 캐릭터보다 약 1.4~1.6배 커질 수 있다.
- 비행 판정이 일부 하드코딩에 의존해 데이터의 `flying` 역할 태그와 일관되지 않다.
- 유닛 `z_index`가 월드 Y좌표를 그대로 사용해 전면 벽보다 앞으로 튀어나올 수 있다.
- 피해 판정과 HP는 먼저 바뀌고 피격 반응·숫자·소리는 약 0.18초 뒤에 나와 접촉감이 약하다.
- Update 4의 일부 VFX ID는 자산 존재 검사만 있고 실제 전투 이벤트에 연결되지 않았다.
- 기존 시각 테스트는 코드 문자열과 고정 좌표 위주여서 실제 렌더의 발 위치·벽 가림을 충분히 검증하지 못한다.

### 3.3 출시 전 남은 일반 검수

- DAY 3 집중 명령·도둑 사냥꾼 특성은 자동 테스트를 통과했지만 사용자의 실제 체감 확인이 남아 있다.
- DAY 6~30 대사·분기·승급 초상화·DAY 29 선언·DAY 30 기본 엔딩의 사용자 실기 확인이 남아 있다.
- `1.2.1` 저장 이어하기, Update 2~4, 설정·일시정지, Windows 물리 한/영 키 조합 상태가 최종 사용자 체크리스트에 남아 있다.
- Full 검증, Windows 출시 후보 export, 실행 확인, SHA-256, `v1.2.2` 태그와 Release는 아직 수행하지 않는다.

## 4. 우선순위와 출시 경계

| 등급 | 출시 전 처리 항목 | 완료 원칙 |
|---|---|---|
| P0 출시 차단 | BGM 무음·반복, 오디오 음량 우회, 캐릭터 발·크기, 전면 벽 가림, 피해·소리·반응 시점 불일치 | 자동 계약과 대표 실제 화면·청취가 모두 통과해야 함 |
| P1 출시 완성도 | 6개 BGM 상태, 무기·피격 재질음, 핵심 UI음, Stage별 환경음, 발소리, VFX 통일, 실패 그래픽 선별 교체 | 사용자에게 비교 자료를 제시하고 승인받아야 함 |
| POST_RELEASE 범위 밖 | 적응형 다중 악기층, 방 단위 위치 음향, 모든 캐릭터 전용 시그니처, 전체 음성, 모바일 전용 재믹스 | 결함 등급 P2와 구분해 이번 출시 후보에 포함하지 않음 |

## 5. Luna 작업 패킷 규칙

이 절은 저장소의 `AGENTS.md > Luna 소형 패킷 강제 규칙`을 구체화한다. 아래 상한은 이 문서에 과거에 적힌 더 큰 묶음보다 우선한다. Luna에게는 전체 계획을 실행하라고 주지 않고, 매번 `CURRENT.md`의 `NEXT_PACKET_ID` 한 개와 패킷 카드만 전달한다.

### 5.0 한 turn 한 패킷

- 한 turn에는 `PACKET_ID` 하나만 구현한다. 완료 뒤 시간이 남아도 다음 번호를 시작하지 않는다.
- 시작 전에 `GOAL / ALLOWED_WRITE_PATHS / FORBIDDEN / DIRECT_TEST / UI_OR_AUDIO_CHECK / STOP_AFTER`를 먼저 출력한다.
- 허용 경로 밖 수정이 필요해지는 순간 현재 구현을 멈추고 `SCOPE_CHANGE_REQUIRED`로 보고한다. 같은 turn에서 허용 목록을 스스로 넓히지 않는다.
- 공통 코드, 개별 자산, 런타임 연결, 실제 검수는 서로 다른 패킷이다.
- 관리 에이전트는 Luna에게 장기 backlog나 다음 패킷의 구현 지시를 함께 주지 않는다. 다음 단계 이름은 종료 보고의 제안으로만 남긴다.

### 5.1 한 패킷의 크기

| 패킷 종류 | 허용 작업량 |
|---|---|
| 코드·데이터 | 사용자 체감 결함 정확히 1개, 제품 코드·데이터 최대 2경로, 직접 테스트 최대 2경로 |
| 캐릭터 정규화 | 프로필 최대 2개. 서로 다른 원본 정체성을 다루면 1개만 허용. 공통 코드 변경 금지 |
| 이미지 자산 | 캐릭터 또는 효과 정확히 1개. 생성/선택과 런타임 연결은 별도 패킷 |
| 짧은 오디오 | cue 정확히 1개. 생성·청취·승격 뒤 중단 |
| 긴 BGM·환경 loop | 한 패킷에 한 곡 또는 한 loop만 생성·후처리·청취 |
| 연결·통합 | 이미 승인된 자산 또는 event 정확히 1개만 런타임에 연결 |
| 검수 | 제품 코드 변경 없이 지정된 화면 또는 청취 시나리오 하나만 판정 |

기본 패킷은 테스트와 핸드오프를 포함해 총 6경로, 자산 패킷은 총 7경로를 넘지 않는다. 넘으면 완료로 밀어붙이지 말고 다음 패킷으로 분리한다. `.gd`와 `.tscn`, 생성 원본과 runtime PNG는 각각 별도 경로로 계산한다.

패킷 종료 시 Luna는 다음 패킷을 실행하지 않고 아래 네 줄만 보고한다.

```text
CHANGED: 실제 변경 경로
TESTED: 직접 테스트와 결과
OPEN: 미해결 또는 없음
NEXT_PACKET_ID_PROPOSAL: 다음 한 개, 실행하지 않음
```

### 5.2 매 패킷 시작 시 읽을 자료

1. `AGENTS.md` 전체
2. `docs/handoff/CURRENT.md` 전체
3. 이 계획의 해당 페이즈 부분
4. 직전 패킷 핸드오프 또는 직접 관련된 최신 계약 문서 1개

이 네 문서로 수정 범위를 정할 수 없으면 구현을 시작하지 않고 별도 발견 패킷을 만든다.

### 5.3 Git과 산출물 규칙

- 구현 시작 기준 SHA가 직전 승인 패킷 SHA와 같은지 확인한다.
- 실제 구현 브랜치는 승인된 `release/v1.2.2` 통합 SHA에서 `codex/v122-release-polish-<packet>` 형식으로 시작한다.
- 그 승인 기준에는 이 계획의 시각 기준점인 `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`의 도로·통로·구조 벽 변경이 정식 통합 절차로 포함돼 있어야 한다. 포함되지 않았다면 파일을 수동 복사하지 말고 기준 브랜치 통합 여부부터 확정한다.
- 현재 작업 트리에 남아 있는 아래 13개 사용자 변경은 별도 지시 없이는 절대 스테이징하지 않는다.
  - `assets/sprites/enemies/update4/region/*.png.import` 6개
  - `FinaleEveHardeningTest`, `Update3BaselineContractTest`, `V122StoryDay06To30Test`, `V122StoryProductFlowTest`의 `.gd.uid`
  - `Update3BaselineSpec`, `Update3BaselineSummary`, `Update3BaselineTrial`의 `.gd.uid`
- `git add -A`를 사용하지 않고 페이즈 허용 목록만 명시적으로 스테이징한다.
- 패킷 하나의 제품 코드·데이터·자산·직접 테스트는 다른 작업과 섞이지 않는 기능 커밋 1개로 묶을 수 있어야 한다.
- 커밋 권한이 있는 패킷은 `기능·테스트 커밋 1개 → 그 SHA를 기록하는 handoff/CURRENT 전용 종료 커밋 1개`까지 최대 2커밋으로 닫는다. 두 번째 커밋에는 `docs/handoff/` 밖의 변경을 넣지 않는다.
- 커밋 권한이 없으면 커밋하지 않고 기능 파일과 종료 문서의 명시적 스테이징 후보 목록, 테스트 결과, 아직 고정되지 않은 SHA를 보고한다.
- 다음 패킷은 직전 패킷의 기능 SHA와 종료 문서가 커밋됐거나, 사용자가 정확한 diff와 기준 SHA를 승인한 뒤에만 시작한다.
- 완료한 구현 패킷은 개별 `codex/v122-*` 브랜치에서 `release/v1.2.2`로 PR merge commit 통합한다. 구현 브랜치나 과거 `release/v1.2`에서 `main`으로 바로 병합하지 않는다.
- 푸시·PR·전체 검수·빌드·태그·배포는 각각 사용자의 별도 지시가 있을 때만 수행한다.
- 캡처·청취 후보·생성 중간물은 `tmp/v122_release_polish/` 아래에만 둔다.
- 이미지 생성은 저장소 규칙대로 GPT 내부 이미지 생성 모델을 사용한다.
- 정식 오디오는 A0에서 `v1.2.2`용으로 버전 분리한 Lyria 파이프라인만 사용한다. `plan` 출력과 예상 비용을 보여 준 뒤 승인받은 경우에만 유료 `generate --execute`를 실행하며 API 키는 가려진 입력만 사용한다.

### 5.4 패킷 종료 조건

- 변경 허용 목록 밖 파일이 0개다.
- 가장 작은 직접 자동 테스트 한 묶음이 PASS다.
- UI·캐릭터 변경은 `1280×720` 대표 화면 한 장을 실제 실행해 확인한다.
- 오디오는 지정된 짧은 청취 시나리오와 버스·loop 자동 계약을 확인한다.
- `docs/handoff/HANDOFF_TEMPLATE.md` 형식의 날짜별 핸드오프와 `CURRENT.md`를 갱신한다.
- 미해결 문제가 있으면 다음 페이즈로 넘어가지 않는다.

## 6. 전체 실행 순서

| 순서 | 페이즈 | Luna 패킷 수 | 목표 | 완료 게이트 |
|---:|---|---:|---|---|
| 0 | F0 기준선·인벤토리 | `F0-V 시각 + F0-A 오디오 + F0-R 출시 공백` 3회 | 활성 캐릭터·오디오·출시 공백을 서로 독립된 기계 판독 목록으로 고정 | 각 패킷 런타임 변경 0, 해당 영역 누락·중복·대표 근거 확정 |
| 1 | V1 맵 비례 스케일 계약 | `V1-A 계약·registry + V1-B capture·감사 + V1-C/D 시트 3개씩` 4회 | 128×64 투영 타일 기준 크기 등급과 감사 도구 정의 | 프로필 schema·전처리 재현성·검증 테스트 PASS |
| 2 | V2 전체 캐릭터 크기 정규화 | `프로필 최대 2개 단위 N회, 정체성 자산은 1개 단위` | 일반 체격 +15%, 소형·대형·보스·비행 예외 적용 | 활성 roster 누락 0, Update 4 과대 표시 0 |
| 3 | V3 접지 렌더 구조·발 앵커 | `공통 구조 1회 + 프로필 2개 단위 N회` | 최종 크기에서 바닥 root와 움직이는 body를 분리 | 전체 지상 roster 발 흔들림 2픽셀 이하 |
| 4 | V4 가림·UI 앵커 | `V4-A 전면 벽 + V4-B UI 앵커` 2회 | 전면 벽 가림과 이름·HP·피해 숫자 위치를 서로 분리해 정리 | 유닛의 앞벽 돌출·표시 겹침 0 |
| 5 | A0 v1.2.2 오디오 생성·승격 계약 | 1 | v0.5 고정 수량·경로를 제거하고 새 버전 manifest와 검사를 분리 | 기존 v0.5 불변, 새 수량·출처 경로를 manifest로 판정 |
| 6 | A1 오디오 기반 | `A1-A/B/C + A1-D1/D2/D3 + A1-E suite 등록` 7회 | asset/event catalog, bus, stream loop, voice cap, crossfade | 76개 asset 전수 분류, 무음·음량 우회 0 |
| 7 | C1 접촉 시점·VFX 동기화 | 1 | 피해·소리·VFX·피격 동작을 같은 접촉 사건으로 묶음 | x1~x3 결과 동일, 접촉 오차 한 simulation frame 이내 |
| 8 | V5 VFX catalog·런타임 연결 | 1 | Update 4를 포함한 활성 VFX ID, 앵커, 가림, 강도 등급 연결 | 미해결 활성 VFX ID 0, 접근성 옵션 동작 |
| 9 | V6 실패 그래픽 선별 교체 | `시트 1개 또는 캐릭터 1개·동작 1개 단위` | 정규화로 해결되지 않는 자산만 재제작 | 전체 동작 통합 비교 보드와 실제 화면 사용자 승인 |
| 10 | A2 기본 타격·UI음 | `cue 1개 단위 N회` | 무기·피격 재질·핵심 UI cue 완성 | 같은 베기음 의존 제거, 설정 미리듣기 PASS |
| 11 | A3 BGM 6상태 | `연결 1회 + 곡 3회` | 기존 3곡 유지 검수, 새 3곡 생성·연결 | 6상태 고유 경로, stream loop seam·전환 승인 |
| 12 | A4 Stage 환경음·발소리 | `loop 1개 단위 + 발소리 1개 단위 + 연결 1개 단위` | Stage 01~04 ambience와 재질별 발소리 | x3에서도 타격을 덮지 않고 발 접촉과 일치 |
| 13 | A5 선별 교체·최종 믹스 | `cue 1개 단위 최대 12회 + 믹스 1회` | 최대 12개 합성음 선별 교체와 전체 음량 계층 확정 | 미분류·중복·클리핑·무음 폴백 0 |
| 14 | Q1 비시각 출시 공백 | `Q1-S 저장 + Q1-I 입력 + Q1-L UI·현지화 + Q1-P 성능 + Q1-R 권리` 5회 뒤 결함별 N회 | 각 영역을 읽기 전용으로 감사한 뒤 결함을 하나씩 수정 | P0/P1/P2 미해결 0, 비차단 항목은 P3 또는 OUT_OF_SCOPE로만 명시 |
| 15 | I1 통합 대표 검수 | `시나리오별 6회` | 설정·관리·DAY 3·후반·보스·Stage 전환을 한 패킷에 하나씩 확인 | 각 시나리오 자동 계약과 대표 화면 또는 청취 기록 PASS |
| 16 | I2 사용자 비교 승인 | `지적 1건당 1회` | 화면·음원 비교 자료를 사용자에게 제시 | 사용자 승인, 지적은 새 소패킷으로만 수정 |
| 17 | R1 정식 출시 검수·후보 | 하위 게이트마다 별도 명시 승인 후 | 출시 문서, OWNER 전체 QA, Full, Windows·Web 후보, main 통합, 태그·Release | 검수 release SHA와 handoff를 제외한 제품 tree 동일성 및 각 게이트 충족 |

## 7. 페이즈별 상세 지시

### F0. 기준선과 인벤토리

목표는 수정이 아니라 이후 Luna가 전체 저장소를 반복 탐색하지 않게 기준표를 만드는 것이다. 한 패킷에 모두 조사하지 않고 아래 세 패킷을 순서대로 수행한다.

#### F0-V 시각 인벤토리

- 활성 캐릭터 ID, 원본 프레임 크기, 투명 영역, 발 추정점, 현재 맵 대비 높이, 비행 여부를 담은 감사표
- 활성 roster 전체 비교 contact sheet와 대표 DAY 3 `1280×720` 캡처
- 이 단계의 시각 상태 값은 `PASS / NEEDS_NORMALIZATION / DISCONNECTED`로 제한하고 재생성 판정은 내리지 않는다.

#### F0-A 오디오 인벤토리

- 오디오 76개의 경로, 실제 호출 이벤트, 버스, stream loop, 출처, 해시를 담은 감사표
- 출처 `lyria / procedural`와 사람 청취 상태 `pending / approved / replace / retire`를 별도 열로 기록
- 런타임 연결 상태는 `사용 중 / 연결 필요 / 퇴역 후보`로 별도 기록
- `assets/audio/bgm/SOURCE.md`가 실제 115초 Lyria 곡을 procedural 30초로 적은 기존 충돌을 근거 파일과 함께 표시하고 A0의 정정 대상으로 넘긴다.
- F0-A 결과: 실제 런타임 54개, 데이터-only 12개, 호출 미확인 10개; Lyria 28개, 로컬 결정적 합성 48개; 청취 상태는 76개 모두 `pending`이다.
- 관리·보스 BGM은 `.import` 루프와 종료 후 재시작 경로가 없어 A1에서 루프 정책을 먼저 결정한다. Update 4 오디오 13개는 22.05kHz라 44.1kHz 자산과의 믹스도 A1에서 확인한다.

#### F0-R 일반 출시 공백

- 수정 없이 `저장·복구 / 입력·IME / 현지화·placeholder / 성능 / 권리·출처`의 기존 권위 문서와 미검수 항목만 목록화
- 실제 상세 감사는 Q1의 다섯 패킷으로 미루고 여기서는 소유 페이즈와 재현 입구만 지정
- F0-R 결과: Q1-S·Q1-I·Q1-L·Q1-P는 `OWNER_QA_PENDING`, Q1-R은 `SOURCE_AUDIT_PARTIAL`로 고정했다. P8 자동 검사는 통과했지만 저장 원본·물리 IME·전체 UI·Windows GPU 장시간 전투·전체 활성 자산 권리 표는 아직 사용자 또는 상세 감사가 필요하다.
- 근거와 기계 판독 결과는 `docs/qa/V122_F0R_RELEASE_GAP_INVENTORY_2026-08-02.md`와 `tmp/v122_release_polish/f0_r/f0_r_inventory.{json,tsv}`에 기록했다. 코드·데이터·자산·빌드·전체 회귀는 이 패킷에서 건드리지 않았다.
- 다음 순서는 `Q1-S 저장·복구 → Q1-I 입력·IME → Q1-L UI·현지화 → Q1-P 성능 → Q1-R 권리·출처`이며, 각 패킷은 하나의 결함 범위만 상세 감사하고 대상 테스트만 실행한다.

금지:

- 런타임 코드·밸런스·자산 수정
- 인벤토리를 만들면서 임의로 파일 삭제
- 전체 회귀와 출시 빌드

### V1. 맵 비례 스케일 프로필과 감사 도구

경로 상한을 지키기 위해 아래 네 패킷으로 분리한다.

#### V1-A 계약·registry

- `data/v122/combat_visual_profiles.json`
- 시각 프로필을 읽는 최소 loader와 `scripts/core/DataRegistry.gd` 연결
- 프로필 누락·schema·맵 비례 수치를 검사하는 전용 계약 테스트

#### V1-B capture·감사

- `tools/V122CombatPolishCapture.gd`와 전용 장면 파일
- `docs/qa/V122_COMBAT_VISUAL_NORMALIZATION_AUDIT.md`
- 런타임 변경 없이 같은 ID·카메라·`1280×720` 조건으로 비교판을 재현하는 검사
- 완료 기록: 비헤드리스 OpenGL 캡처에서 44개 roster·`1280×720` 비교판과 manifest를 생성했다. 헤드리스는 dummy viewport가 비어 `CAPTURE_BLOCKED`로 남긴다.

#### V1-C·V1-D Update 4 전처리

- `tools/prepare_v122_combat_runtime_sprites.py`와 결정론 검사
- 아래 3개 묶음은 2026-08-02에 이미 끝난 역사적 실행 기록이다. 앞으로의 보정 패킷 크기로 재사용하지 않으며, 현재 규칙에 따른 후속 자산 보정은 시트 1개씩만 처리한다.
- V1-C에서 공통 변환 로직을 만들고 V1-D는 변환 로직을 바꾸지 않은 채 나머지 세 시트만 처리한다. 묶음 manifest를 분리하기 위한 packet 선택만 추가하며, 공통 변환 결함이면 V1-D를 계속하지 않고 V1-C 보정 패킷으로 돌아간다.
- V1-C 완료: `coal_spark`, `dusk_courier`, `bronze_automaton` 3개를 768×768 RGBA/192×192 정수 셀로 변환하고 `--check --packet v1-c` 결정론 검사를 통과했다.
- V1-D 완료: 같은 변환 로직으로 `shadow_duelist`, `spore_doll`, `root_tender` 3개를 처리하고 `--check --packet v1-d`를 통과했다. 묶음별 manifest를 분리해 V1-C 결과를 보존했다. 다음은 V2 runtime 연결이다.

프로필 필드:

- `QuarterDungeonRenderer`의 128×64 투영 타일과 한 칸 사선 길이 `E`에 대한 몸 높이·폭 비율
- 체격 등급 `small / normal / large / boss`
- `grounded / flying` 이동 형태
- 런타임 자산 경로, 원본 프레임 크기, 투명 영역 크기
- 상태는 F0의 `PASS / NEEDS_NORMALIZATION / DISCONNECTED`를 입력으로 받고, 후속 정규화가 끝난 뒤 `NORMALIZED_PASS / FAIL_REGEN`으로만 전이한다.
- 상태 소유권은 분리한다. F0는 초기 감사 상태만 기록하고, V1·V2는 그 상태를 운반한다. 캐릭터의 최종 `NORMALIZED_PASS / FAIL_REGEN`은 V3가 확정하며, V6는 `FAIL_REGEN`만 소비해 재제작한다. VFX의 같은 전이는 V5가 소유한다.

완료 기준:

- 절대 화면 픽셀로 캐릭터 크기를 고정하지 않는다.
- 일반 체격 목표는 F0에서 측정한 기존 중앙값의 `1.15배`다.
- 누락 프로필은 조용히 공통값으로 처리하지 않고 검사에서 실패한다.
- 기존 192px 코어 PNG는 다시 저장하지 않고 런타임 배율로 처리한다.
- 1254px·마젠타 배경인 Update 4 시트는 정수 192px 셀의 투명 런타임 시트로 결정적으로 전처리하고 `--check`로 같은 결과가 재현되는지 확인한다.
- Update 4 지역 적 시트 6개는 과거 V1-C·V1-D에서 각각 3개씩 전처리했다. 이는 완료 이력일 뿐이며, 이후 패킷은 현재의 1자산 상한을 따른다.

### V2. 전체 roster 크기 정규화

각 패킷은 프로필 최대 2개만 수정한다. 서로 다른 원본 정체성을 판단하거나 자산을 바꾸는 패킷은 캐릭터 1개만 다룬다. 패킷 도중 공통 코드 결함을 발견하면 자산 수정을 계속하지 않고 V1 보정 패킷으로 되돌린다.

순서:

1. DAY 1~5 핵심 아군
2. DAY 1~5 일반 적과 도둑
3. DAY 6~30 반복 노출 아군·적
4. Update 3 캐릭터
5. Update 4 지역 적
6. 대형·보스
7. 비행형

완료 기준:

- 일반 체격은 맵 비례 정규화 후 기존 화면 중앙값보다 12~18%, 목표 15% 커진다.
- Update 4 원본 크기 때문에 생기는 우발적 1.4~1.6배 확대가 없다.
- 소형·대형·보스 차이는 의도한 등급으로만 발생한다.
- 마젠타 테두리, 잘림, 흐릿한 재확대가 없다.
- 모든 활성 캐릭터가 프로필과 비교표에 한 번씩 등장한다.
- 이 단계에서는 크기·알파·선명도 항목만 갱신하고 발·동작 실패를 단독으로 `FAIL_REGEN` 확정하지 않는다. 최종 캐릭터 상태 확정은 V3가 소유한다.

V2-P1 미승인 작업 트리 구현 기록 (2026-08-02): 실행 순서를 어기고 Update 4 지역 적 6개가 먼저 처리됐다. runtime path, grounded/flying profile, map-relative render scale은 연결됐지만 이는 `RUNTIME_PREP_PASS`까지만 뜻한다. 최종 `NORMALIZED_PASS`는 V3의 접지·동작 검증만 확정한다. 감사에서 셀 경계 절단·투명 시트 재크로마 처리·캡처 배율 오류를 수정하고 전용 `1280×720` 비교판을 다시 만들었으나, 최종 기능 SHA가 없어 아직 승인하지 않는다. 상세: `docs/qa/V122_V2_UPDATE4_RUNTIME_NORMALIZATION_2026-08-02.md`.

V2-P2 미승인 작업 트리 구현 기록 (2026-08-02): DAY1~5 핵심 아군과 DAY12 첫 승급 6개의 profile·맵 비례 scale을 연결했다. 그러나 V1 보정 패킷이 소유했어야 할 `DataRegistry`·`Unit` 공통 코드를 이 패킷에서 함께 고친 것은 범위 이탈이다. 감사에서 이 fallback이 2차 승급·왕관 7종을 기본 종족 그림으로 바꾸는 결함을 확인해 정확한 sprite path 보존 계약으로 수정했다. 관련 테스트는 dirty worktree 참고 결과이며 V3 전에는 최종 완료가 아니다. 상세: `docs/qa/V122_V2_P2_CORE_ALLY_NORMALIZATION_2026-08-02.md`.

V2-P3 미승인 작업 트리 구현 기록 (2026-08-02): DAY1~5 직접 등장 3종과 초기 일반 적 풀 3종의 profile·맵 비례 scale을 연결했다. 대상 테스트와 수정된 `1280×720` 비교판은 현재 작업 트리에서 확인했지만, V3 접지와 최종 SHA 재검증 전에는 완료로 세지 않는다. 상세: `docs/qa/V122_V2_P3_REGULAR_ENEMY_THIEF_NORMALIZATION_2026-08-02.md`.

V2-P4 부분 연결·범위 게이트 결과 (2026-08-02): 후보 자산 사전 검사에서 `kobold_scout` 원본이 `1254×1254` 전체 불투명 이미지이고, 스토리·데이터 계약상 원정·정찰 지원 전용이라는 충돌을 확인했다. 같은 원본을 공유하는 `moon_tracker`도 전투 profile에 연결하지 않았다. 대신 투명한 기존 전투 원본을 가진 `spore_healer·stone_sentinel·war_drummer·mimic_porter` 4개만 profile·맵 비례 배율에 연결하고, runtime 계약과 `1280×720` 비교판을 PASS했다. 공유 원본의 캐릭터 정체성은 승인하지 않았으며 P4 전체는 `SCOPE_BLOCKED`로 남긴다. 실제 전투 원본 결정 전에는 V2-P5나 V3로 이동하지 않는다. 상세: `docs/qa/V122_V2_P4_RECURRING_ASSET_SCOPE_GATE_2026-08-02.md`.

#### V2-P4 남은 작업의 Luna 소형 패킷 큐

관리 에이전트는 아래 큐 전체를 Luna에게 한 번에 지시하지 않는다. 매 turn에는 `CURRENT.md`가 가리키는 첫 번째 `NEXT` 행 하나만 패킷 카드로 전달한다. `DISCOVER` 결과 기존 승인 자산을 재사용할 수 있으면 같은 캐릭터의 `ASSET` 패킷은 건너뛸 수 있지만, 그 turn에서 `CONNECT`까지 실행하면 안 된다.

| 순서 | PACKET_ID | 목표 한 개 | 제품 쓰기 | 초기 상태 |
|---:|---|---|---:|---|
| 1 | `V2-P4A-DISCOVER-SPORE` | `spore_healer` 전용 원본 후보와 현재 공유 그림 충돌만 판정 | 0 | `NEXT` |
| 2 | `V2-P4A-ASSET-SPORE` | 승인된 방향으로 `spore_healer` 자산 1개만 생성·후처리 | 자산 1개 | `LOCKED` |
| 3 | `V2-P4A-CONNECT-SPORE` | 승인된 `spore_healer` 자산 1개만 profile/runtime에 연결·검사 | 데이터/연결 1개 | `LOCKED` |
| 4 | `V2-P4B-DISCOVER-STONE` | `stone_sentinel` 원본 후보만 판정 | 0 | `LOCKED` |
| 5 | `V2-P4B-ASSET-STONE` | `stone_sentinel` 자산 1개만 생성·후처리 | 자산 1개 | `LOCKED` |
| 6 | `V2-P4B-CONNECT-STONE` | `stone_sentinel` 자산 1개만 연결·검사 | 데이터/연결 1개 | `LOCKED` |
| 7 | `V2-P4C-DISCOVER-WAR` | `war_drummer` 원본 후보만 판정 | 0 | `LOCKED` |
| 8 | `V2-P4C-ASSET-WAR` | `war_drummer` 자산 1개만 생성·후처리 | 자산 1개 | `LOCKED` |
| 9 | `V2-P4C-CONNECT-WAR` | `war_drummer` 자산 1개만 연결·검사 | 데이터/연결 1개 | `LOCKED` |
| 10 | `V2-P4D-DISCOVER-MIMIC` | `mimic_porter` 원본 후보만 판정 | 0 | `LOCKED` |
| 11 | `V2-P4D-ASSET-MIMIC` | `mimic_porter` 자산 1개만 생성·후처리 | 자산 1개 | `LOCKED` |
| 12 | `V2-P4D-CONNECT-MIMIC` | `mimic_porter` 자산 1개만 연결·검사 | 데이터/연결 1개 | `LOCKED` |
| 13 | `V2-P4E-DISCOVER-MOON` | `moon_tracker` 전투 전용 원본 방향만 판정 | 0 | `LOCKED` |
| 14 | `V2-P4E-ASSET-MOON` | `moon_tracker` 자산 1개만 생성·후처리 | 자산 1개 | `LOCKED` |
| 15 | `V2-P4E-CONNECT-MOON` | `moon_tracker` 자산 1개만 연결하고 임시 출전 차단을 해제·검사 | 데이터/연결 2개 | `LOCKED` |
| 16 | `V2-P4F-VERIFY-IDENTITY` | 다섯 캐릭터의 정체성·크기 비교판 한 장만 검수 | 0 | `LOCKED` |

각 행은 별도 turn과 별도 종료 보고를 사용한다. 한 행이 `BLOCKED`면 아래 행은 모두 계속 `LOCKED`다.

### V3. 바닥 root와 움직이는 body·발 앵커

예상 경로:

- V2에서 최종 크기가 확정된 `data/v122/combat_visual_profiles.json`
- `scripts/units/Unit.gd`
- 필요한 경우 유닛 생성 경로 1개
- `V122CombatVisualHierarchyTest` 확장 또는 새 grounding 테스트

구현 계약:

- 유닛의 월드 위치는 발이 닿는 바닥 root다.
- 접지 그림자·선택 표시는 root에 남는다.
- 스프라이트 몸체만 공격·피격·점프 포즈를 수행한다.
- 지상 이동의 의미 없는 수직 bob을 제거하거나 발 접촉이 유지되는 범위로 제한한다.
- 비행형은 데이터 태그와 프로필을 함께 사용한다.
- 최종 크기에서 측정한 애니메이션·프레임별 발 보정, 그림자, 머리·UI·VFX 앵커를 프로필에 추가한다.

대표 확인:

- 공통 구조 패킷에서 슬라임, 도둑, 일반 탐험가의 idle·move·attack·skill·down
- 명시적인 점프·비행 프레임을 제외한 idle·move·attack·skill의 발 흔들림이 `1280×720`에서 2픽셀 이하
- down은 서 있는 발 앵커와 구분된 쓰러짐 바닥 앵커를 사용하고 그림자와 몸이 분리되지 않음
- 접지 그림자는 몸보다 작고 낮은 채도의 회흑색 타원이며 체격 프로필에 따라 폭·깊이만 달라짐
- 이후 패킷에서 프로필 최대 2개씩 전체 활성 roster의 발·그림자·UI/VFX 앵커를 채운다. 서로 다른 원본 정체성을 판단하면 1개만 다룬다.
- V2 크기 결과와 V3의 모든 동작·발 기준을 함께 통과하면 `NORMALIZED_PASS`, 계획에 고정된 재생성 사유가 남으면 `FAIL_REGEN`으로 확정한다. V6는 이 최종 상태만 입력받는다.

### V4. 전면 벽과 표시 앵커

#### V4-A 전면 벽 가림

이 패킷은 캐릭터와 VFX의 깊이만 다루고 이름·HP·피해 숫자의 위치는 바꾸지 않는다.

- `UnitYSortLayer` 내부 정렬과 전면 벽 Canvas 계층을 분리한다.
- Y 정렬은 Unit 레이어의 제한된 깊이 구간 안에서만 작동하고 유닛의 유효 깊이값은 `FrontWallLayer`를 절대 넘지 않는다.
- 월드 Y값을 무제한 `z_index`로 쓰거나 더 큰 고정 숫자로 문제를 가리지 않는다.
- 남·동쪽 구조 벽의 앞가림은 캐릭터 몸 일부만 자연스럽게 가린다.
- 북·서쪽 후면 벽에서는 캐릭터가 정상적으로 앞에 보인다.
- 후속 V5가 지면·몸·공중 VFX를 안전하게 연결할 수 있도록 제한된 depth slot과 가림 API만 정의한다. 이 패킷에서는 실제 VFX ID를 연결하거나 VFX 가림 완료를 판정하지 않는다.
- V4-A의 완료는 깊이 슬롯·가림 API 계약으로 한정한다. 실제 VFX catalog ID 연결과 지면·몸·공중 효과의 가림 판정은 V5에서만 수행한다.

#### V4-B 이름·HP·피해 숫자 앵커

이 패킷은 V4-A가 통과한 깊이 계약을 입력으로 사용하고 Canvas 계층을 다시 설계하지 않는다.

- 이름·HP·피해 숫자·경고는 프로필 앵커를 사용한다.
- 일반 이름은 필요할 때만 보여 주고 긴급 경고가 최상위다.

대표 확인:

- Stage 01 좁은 통로에서 아군·도둑·대형 적이 앞벽을 통과해 보이지 않는다.
- 북·남·동·서 벽 근처를 한 장면에서 비교해 방향별 가림이 뒤집히지 않는다.
- 캐릭터 크기가 달라도 HP와 피해 숫자가 머리·벽과 겹치지 않는다.

### A0. v1.2.2 오디오 생성·승격 계약

기존 `tools/audio/lyria_v05_manifest.json`과 `assets/source/audio/lyria/v0.5/`는 공개 감사 기록이므로 수정하거나 새 자산의 대상으로 재사용하지 않는다.

예상 산출물:

- `tools/audio/lyria_v122_manifest.json`
- v1.2.2 manifest를 선택할 수 있는 파이프라인 최소 변경
- WAV 76개, BGM 3개, source 28개를 코드에 고정한 테스트를 manifest 기반 수량·해시·경로 검사로 교체
- 신규 원본 경로 `assets/source/audio/lyria/v1.2.2/` 계약
- 실제 생성·승격 기록과 충돌하는 기존 `assets/audio/bgm/SOURCE.md`의 정정 또는 명시적 deprecated 처리

완료 기준:

- `plan`과 `generate` 검증은 manifest에 계획됐지만 아직 없는 runtime WAV를 허용한다.
- `promote --confirm` preflight는 이번에 선택한 asset 1개의 missing runtime만 허용한다. 복사와 출처 기록이 끝난 postflight부터 manifest·runtime exact coverage를 강제한다.
- `validate`와 `release`는 시작부터 승인된 runtime 존재와 exact coverage를 강제한다.
- placeholder·무음 WAV로 coverage 검사를 우회하지 않는다.
- `plan` 서브커맨드는 새 버전·새 원본·런타임 경로·예상 호출 수·예상 비용을 출력한다.
- 유료 생성은 사용자가 plan·비용을 승인한 뒤 `generate --execute`로만 실행하고, 청취 후보 승격은 별도 승인 뒤 `promote --confirm`으로만 실행한다.
- v0.5 manifest와 기존 28개 출처 기록의 해시가 바뀌지 않는다.
- 새 cue나 BGM을 추가해도 manifest의 선언 수량을 따르며 과거 `76 / 3 / 28` 고정값 때문에 실패하지 않는다.

#### A0 실행 결과 (계약 완료, 생성·승격 대기)

- `tools/audio/lyria_v122_manifest.json`을 추가해 대상 버전을 `v1.2.2`로 분리하고, 원본 경로를 `assets/source/audio/lyria/v1.2.2/`, 기본 작업 경로를 `tmp/lyria_audio_v122/`, 정책을 `plan-only-until-owner-approval`로 고정했다. 기존 v0.5 manifest는 수정하지 않았다.
- manifest는 76개 항목을 보존하며 `validate`는 `assets=76`, `coverage=all-current-wav`로 통과했고 `plan`은 예상 비용만 출력했다. JSON 문법 검사도 통과했으며 네트워크·`generate --execute`·`promote --confirm`은 실행하지 않았다.
- `assets/audio/bgm/SOURCE.md`의 `combat_dungeon_pressure` 설명을 실제 승격된 Lyria 원본 기록으로 정정했다. v0.5 계약의 120초와 현재 runtime WAV 116.909초 차이는 숨기지 않고 A1 loop 검증 항목으로 남겼다.
- 상세 결과는 `docs/qa/V122_A0_AUDIO_MANIFEST_CONTRACT_2026-08-02.md`, 핸드오프는 `docs/handoff/V122_RELEASE_POLISH_A0_AUDIO_MANIFEST_CONTRACT_2026-08-02.md`에 기록했다. 실제 음원 생성·승격과 A1 런타임 연결은 사용자 승인 뒤에만 진행한다.

### A1. 오디오 이벤트·믹서 기반

#### A1-A catalog·분류

- `data/audio/audio_event_catalog.json`은 모든 WAV를 담는 `assets`와 실제 호출만 담는 `events`를 분리한다.
- 최초 `assets`에는 76개 WAV를 한 번씩 기록한다. event 참조가 0개인 22개에 가짜 사건을 만들지 않고 `연결 필요` 또는 `retire` 후보로 명시한다.
- `events`에는 실제 게임 사건 ID와 참조 asset만 기록하며 한 사건의 소유 경로를 중복 정의하지 않는다.
- `provenance: lyria | procedural`과 `review_status: pending | approved | replace | retire`를 분리한다.
- 기존 Lyria 출처 28개는 `provenance=lyria`로 시작하되 사람 청취 전에는 `review_status=pending`이다.
- 누락 event ID를 조용히 무시하지 않고 개발 로그와 계약 테스트에서 실패시킨다.

##### A1-A 실행 결과 (완료)

- `data/audio/audio_event_catalog.json`에 manifest의 76개 WAV를 한 번씩 기록하고, 실제 런타임 재생 사건 54개만 `events`에 연결했다. 데이터에만 남은 12개와 코드·데이터 소비자를 찾지 못한 10개는 각각 `data_only`·`unconnected`로 분리했다.
- 자산별 `provenance`(Lyria 28개·procedural 48개), `review_status=pending`, 기본 버스(Music 6개·SFX 70개), 출처 기록 상태를 고정했다. 실제 호출이 없는 파일에 임의의 사건을 추가하지 않았다.
- `tools/audio/test_audio_event_catalog.py` 6개 계약 테스트와 JSON 문법 검사를 실행해 모두 PASS했다. 각 event의 소유 코드 파일과 함수 위치도 확인했다.
- 이번 패킷은 catalog·검증 코드만 추가했고 런타임 재생 코드, 오디오 파일, import 설정, 빌드는 변경하지 않았다. suite 등록은 A1-E에서 진행한다.
- 상세 결과: `docs/qa/V122_A1_A_AUDIO_EVENT_CATALOG_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_A1_A_AUDIO_EVENT_CATALOG_2026-08-02.md`.

#### A1-B bus·limiter·설정

- 버스 계층을 `Music → Master`, `SFX → Master`, `UI → SFX → Master`, `Ambience → SFX → Master`로 고정한다.
- Master limiter ceiling은 `-1 dBFS` 이하로 두고 대표 과밀 전투에서 클리핑 0을 확인한다.
- 사용자 SFX 0%에서는 SFX·UI·Ambience가 모두 무음이고 Music만 유지돼야 한다.
- 이 패킷은 공통 버스와 설정 전파만 만든다. 현재 Master로 새는 층 경보의 실제 이관과 SFX mute 회귀는 A1-D3가 소유한다.

##### A1-B 실행 결과 (미승인 선행 구현 — 과밀 전투 clipping 0 미검증)

- `scripts/core/AudioSettings.gd`에 `UI`와 `Ambience` 버스를 추가하고 `Music / SFX → Master`, `UI / Ambience → SFX` 전송 계층을 idempotent하게 보장한다.
- Master에 `AudioEffectLimiter`를 한 번만 연결하고 ceiling을 `-1.0 dBFS`로 고정했다. SFX 음량은 SFX·UI·Ambience에 함께 전파되며 SFX 0%에서도 Music은 유지된다.
- `tools/tests/AudioBusContractTest.gd/.tscn` 9 assertions와 `MusicStateAudioTest` 12 assertions의 당시 자동 계약 결과는 PASS였다. 실제 과밀 전투의 clipping 0 검증은 하지 않았으므로 A1-B 완료 gate는 열려 있다.
- 이번 패킷은 오디오 설정·버스 런타임과 직접 계약 테스트만 변경했고 새 음원·catalog event·환경음·빌드는 건드리지 않았다. 다음은 A1-C BGM transport다.
- 상세 결과: `docs/qa/V122_A1_B_AUDIO_BUS_CONTRACT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_A1_B_AUDIO_BUS_CONTRACT_2026-08-02.md`.

#### A1-C BGM transport

- 곡 자체 반복은 WAV import의 stream loop 계약으로 처리하고, `finished` 신호 재시작을 매끄러운 loop 대책으로 인정하지 않는다.
- 기존 관리·일반전·보스 3곡과 이후 모든 BGM·ambience의 loop mode를 검사한다.
- 관리·보스 곡은 각각 130초 재생해 무음 0을 확인하고, 오프라인 loop seam 청취에서 클릭·박자 단절이 없어야 한다.
- 두 플레이어 crossfade는 상태 전환에만 사용한다. 같은 상태 재요청과 빠른 연속 전환은 idempotent해야 하며 중복 재생·하드 컷이 없어야 한다.
- 기존 관리곡을 짧게 사용하는 `preview_music` catalog event를 만들고 설정 슬라이더 조작 때 재생·정지·연속 요청 중복 방지 계약을 연결한다.
- 이 패킷의 직접 테스트 경로는 `tools/tests/MusicStateAudioTest.gd`와 `tools/tests/MusicStateAudioTest.tscn` 두 개 안에서 끝낸다.

##### A1-C 실행 결과 (PARTIAL — 130초·loop seam·소유자 청취 미완료)

- `management_castle_bustle.wav.import`와 `combat_boss_council.wav.import`의 loop mode를 `LOOP_FORWARD`(`2`)로 고정해 관리·일반전·보스 3곡이 모두 WAV stream loop를 사용하도록 했다. `finished` 신호 재시작 코드는 추가하지 않았다.
- `scripts/game/GameRoot.gd`에 주·보조 BGM 플레이어를 두고 상태가 바뀔 때만 crossfade하도록 연결했다. 같은 상태 재요청은 현재 플레이어와 tween을 재사용하고, 빠른 상태 전환은 이전 보조 플레이어를 정리한 뒤 새 목표로 다시 교차 전환한다.
- 설정 음악 슬라이더에는 기존 관리곡을 3초만 재생하는 `music.preview.settings` catalog event를 연결했다. 미리듣기 중 연속 요청은 무시하고, 설정을 닫으면 즉시 정리한다.
- `MusicStateAudioTest`를 27 assertions로 확장해 3곡 loop 설정, 두 플레이어 전환·종료, 동일 상태 idempotent, 설정 preview 중복 방지를 자동 계약으로 확인했다. `AudioBusContractTest` 9/9와 catalog 테스트의 당시 결과도 PASS였다. 관리·보스곡 130초 재생, loop seam 청취와 소유자 청취는 하지 않았으므로 PARTIAL이다.
- 변경 파일은 BGM import 2개, `scripts/game/GameRoot.gd`, `data/audio/audio_event_catalog.json`, catalog 계약 테스트, `MusicStateAudioTest`와 A1-C 결과 문서다. 새 음원 생성·승격·빌드·푸시는 실행하지 않았다.
- 상세 결과: `docs/qa/V122_A1_C_BGM_TRANSPORT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_A1_C_BGM_TRANSPORT_2026-08-02.md`.

#### A1-D1 voice allocator·catalog API

- global one-shot SFX 최대 24, 같은 일반 event 최대 4, UI 최대 2, 발소리 최대 3을 초기 계약으로 고정한다.
- 상한 초과 시 `중요 경보·보스 모티프 > UI 확정 > 고유 스킬·피격 > 일반 타격 > 발소리` 순으로 보호하고 가장 오래된 낮은 우선순위 voice를 줄인다.
- catalog API는 미해결 event·asset을 조용히 넘기지 않고 진단 로그와 테스트 실패를 낸다.

##### A1-D1 실행 결과 (완료)

- `scripts/audio/AudioVoiceAllocator.gd`에 일회성 SFX 예산을 고정했다. 전체 24개, 동일 일반 event 4개, UI 2개, 발소리 3개를 넘으면 요청의 우선순위보다 낮은 voice 중 가장 오래된 것을 축출하며, 같은 우선순위는 보호한다.
- `scripts/audio/AudioCatalogApi.gd`는 `data/audio/audio_event_catalog.json`의 event·asset·runtime 파일·버스 연결을 함께 확인한다. 미등록 ID, data-only 자산, 파일 누락은 진단 로그를 남기고 빈 해석 결과로 차단한다.
- `tools/tests/AudioVoiceAllocatorTest.gd/.tscn` 55 assertions에서 global·event·UI·발소리 상한, 우선순위 보호·축출·release, 정상/미등록 catalog 해석을 직접 확인했다.
- 이번 패킷은 실제 재생 호출을 아직 allocator로 이관하지 않았다. GameRoot·Update 3/4 연결은 A1-D2, CombatSceneController·HUD 하드코딩 이관은 A1-D3가 소유한다.
- 상세 결과: `docs/qa/V122_A1_D1_AUDIO_VOICE_ALLOCATOR_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_A1_D1_AUDIO_VOICE_ALLOCATOR_2026-08-02.md`.

#### A1-D2 GameRoot·Update 3/4 routing

- `AudioDirector`를 통해 GameRoot와 Update 3·4 데이터 사건을 catalog에 연결한다.
- Update 4의 `sfx`와 `boss_motif`는 파일 존재가 아니라 실제 crown·rival·boss 대표 사건에서 정확히 1회 재생되는지 검사한다.
- 이 패킷은 `tools/tests/SkillAudioPaletteTest.gd`와 `tools/tests/SkillAudioPaletteTest.tscn` 두 경로 안에서 연결 회귀를 소유한다.

##### A1-D2 실행 결과 (완료)

- `scripts/audio/AudioDirector.gd`를 추가해 catalog event 해석, 일회성 voice allocator, 버스 선택, 중복 instance token, 종료·축출 정리를 하나의 런타임 경로로 묶었다.
- `scripts/game/GameRoot.gd`의 Update 3 효과음과 경보를 AudioDirector로 이관하고, Update 4의 계약 스킬 4개·왕관 SFX 6개·경쟁 보스 모티프 3개를 실제 데이터 사건 메서드에 연결했다. 왕관 확정 성공 시에만 SFX를 한 번 호출하며, 동일 instance token의 중복 재생은 거부한다.
- `data/audio/audio_event_catalog.json`은 76개 자산 중 66개를 실제 runtime event에 연결하고 data-only 0개, 코드·데이터 소비자 미확인 10개로 갱신했다. 기존 `sfx_popo_alarm`은 층 경보와 `echo_alarm` 두 사건이 공유한다.
- `tools/tests/SkillAudioPaletteTest.gd/.tscn`을 126 assertions로 확장해 24개 기존 스킬 cue, 13개 Update 4 catalog event의 파일·소유자 연결, GameRoot의 스킬·왕관·경쟁 보스·Update 3 경보 실제 voice 생성과 중복 억제를 확인했다. `AudioVoiceAllocatorTest` 55/55, `AudioBusContractTest` 9/9, `MusicStateAudioTest` 27/27, Python catalog 6/6도 재실행했다.
- 이번 패킷은 새 음원을 생성하거나 CombatSceneController·MultiFloorHUD의 직접 SFX를 이관하지 않았다. 그 하드코딩 경로는 A1-D3가 소유하며, 새 음원 승격·소유자 청취·빌드도 후속 게이트다.
- 상세 결과: `docs/qa/V122_A1_D2_AUDIO_DIRECTOR_ROUTING_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_A1_D2_AUDIO_DIRECTOR_ROUTING_2026-08-02.md`.

#### A1-D3 전투·HUD 하드코딩 이관

- `CombatSceneController`의 일반·스킬 SFX와 `MultiFloorHUD`의 층 경보를 공통 catalog·voice budget 경로로 옮긴다.
- D1~D3 각 패킷은 제품 코드·데이터 4경로 상한을 따르고 다른 하위 패킷 파일을 함께 고치지 않는다.
- D1과 D3는 각각 자기 결함만 확인하는 `.gd/.tscn` 테스트 한 쌍 이내로 제한한다.

##### A1-D3 실행 결과 (완료)

- `CombatSceneController._play_sfx`가 WAV를 직접 생성하지 않고 stream 경로를 catalog asset ID로 변환해 GameRoot의 `AudioDirector.play_asset`을 호출하도록 이관했다. 기존 min-interval cooldown과 공격·피격·스킬별 무작위 pitch는 유지하고, 공통 voice 예산·종료 정리를 사용한다.
- `MultiFloorHUD`의 `FloorAlertSound` 직접 플레이어를 제거하고 `setup`에서 전달받은 AudioDirector의 `update4.floor_intrusion.alarm` event를 사용하도록 변경했다. 반복 경보는 HUD 자신의 voice token만 교체하고 HUD가 사라질 때 다른 전투 voice는 건드리지 않는다.
- `GameRoot`가 상층 HUD를 만들 때 AudioDirector를 주입한다. catalog event의 소유 locator는 실제 `CombatSceneController._play_sfx`·`MultiFloorHUD.push_hidden_floor_alert`에 남아 있다.
- `tools/tests/CombatAudioDirectorRoutingTest.gd/.tscn` 9 assertions에서 일반 타격, 스킬, 층 경보의 공통 재생, cooldown·voice 수명·HUD 제거 정리를 직접 확인했다. A1-D2 `SkillAudioPaletteTest` 126/126, `AudioVoiceAllocatorTest` 55/55와 Python catalog 6/6을 재실행했다.
- 이번 패킷은 새 음원을 만들거나 버스 구조를 바꾸지 않았다. A1-E suite 등록, 새 음원 승격·소유자 청취·출시 검수·빌드는 후속 게이트다.
- 상세 결과: `docs/qa/V122_A1_D3_COMBAT_HUD_AUDIO_ROUTING_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_A1_D3_COMBAT_HUD_AUDIO_ROUTING_2026-08-02.md`.

#### A1-E 테스트 suite 등록

- A1-A~D3에서 이미 통과한 `MusicStateAudioTest`, `SkillAudioPaletteTest`, catalog·bus·voice budget·routing 테스트를 `tools/tests/core_verification_suite.json`에 등록한다.
- 이 패킷은 제품 런타임이나 테스트 구현을 고치지 않고 suite JSON과 종료 문서만 변경한다.
- 등록된 개별 테스트를 직접 한 번 확인하되 Quick/Full 전체는 실행하지 않는다.

##### A1-E 실행 결과 (완료)

- `tools/tests/core_verification_suite.json`에 `AudioBusContractTest`, `MusicStateAudioTest`, `AudioVoiceAllocatorTest`, `SkillAudioPaletteTest`, `CombatAudioDirectorRoutingTest` 5개 오디오 check를 `quick`·`full`에 등록했다.
- 등록 후 `V122ContentCompatibilityTest`를 실행해 suite coverage 85/85, 499 assertions PASS를 확인했다. Quick/Full 전체 검증은 실행하지 않았다.
- 등록된 오디오 입구는 각각 직접 실행해 AudioBus 9/9, BGM 27/27, voice/catalog 55/55, Update 3/4 routing 126/126, 전투·HUD routing 9/9를 확인했다. Python catalog 6/6와 JSON 문법도 PASS했다.
- 이번 패킷은 suite JSON과 결과 문서만 변경했고 제품 런타임·데이터·그래픽·음원은 추가로 변경하지 않았다. 다음은 C1 피해·소리·VFX 접촉 동기화다.
- 상세 결과: `docs/qa/V122_A1_E_AUDIO_SUITE_REGISTRATION_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_A1_E_AUDIO_SUITE_REGISTRATION_2026-08-02.md`.

### C1. 피해·소리·VFX·피격 반응 동기화

입력은 V3의 발·몸 분리와 A1의 AudioDirector다.

구현 계약:

- 공격 시작이 아니라 실제 접촉 사건에서 피해, 피격 동작, 타격음, VFX, 피해 숫자를 함께 발생시킨다.
- 전투 배속 x1~x3에서 같은 simulation 사건을 사용한다.
- 판정 지연 때문에 기존 승패가 바뀌지 않도록 고정 난수 대표 전투를 비교한다.
- 일반 공격, 투사체, 돌진, 광역 스킬의 접촉점을 각각 명시한다.

완료 기준:

- 다섯 피드백 요소의 시작 오차가 한 simulation frame 이내다.
- 고정 난수 입력에서 x1·x2·x3의 승패·피해 총량·사망 순서는 정확히 같고, 사건 시간값만 배속 비율에 맞춰 달라진다.
- 실제 `1280×720` 게임 프레임의 `예비동작 → 접촉 → 회복` 3칸 비교판 또는 짧은 녹화에서 접촉 전 조기 피해 표시가 없고 접촉 순간 다섯 피드백이 같은 대상에 모인다.

##### C1 실행 결과 (BLOCKED — V3 전제 및 실제 1280×720 증거 없음)

- `CombatSceneController`에 접촉 피드백 단일 입구와 중복 토큰·simulation frame 기록을 추가하고, 피해 적용 직후 피격 동작·피해 숫자·타격음·VFX를 한 사건으로 발생시켰다.
- 일반 공격, 투사체 도착, 영웅 돌진, 광역 스킬을 대표 접촉점으로 고정했다. 산성 장판 틱, 가시 복도 함정, 베베 빗자루, 돌콩 파동, 루미의 두 공격 스킬, 등껍질 돌진도 같은 경로로 이관했다.
- 공격 시작에 있던 일반 베기음·임프 화염구 충돌음을 제거하고 실제 접촉 시점으로 이동했다. 투사체 공통 표시 함수는 피해 투사체에서 도착 VFX를 중복 생성하지 않도록 선택 플래그를 사용한다.
- `ContactFeedbackSyncTest` 23/23의 당시 자동 계약에서는 접촉 종류별 단일 사건, 다섯 채널 순서, x1·x2·x3 동일 피해량·동일 simulation frame을 확인했다.
- suite에 `contact_feedback_sync`를 quick/full로 등록하고 `V122ContentCompatibilityTest` coverage 85/85·500 assertions와 기존 전투 AudioDirector 9/9를 재실행했다. Quick/Full 전체 검증과 Windows 캡처는 실행하지 않았다.
- V3의 발·몸 분리가 아직 없고 실제 `1280×720`의 예비동작·접촉·회복 비교 증거도 없으므로 C1 완료로 인정하지 않는다. 당시 기록: `docs/qa/V122_C1_CONTACT_FEEDBACK_SYNC_2026-08-02.md`, `docs/handoff/V122_RELEASE_POLISH_C1_CONTACT_FEEDBACK_SYNC_2026-08-02.md`.

### V5. VFX catalog와 런타임 연결

예상 산출물:

- `data/v122/combat_vfx_catalog.json`
- VFX ID를 실제 프레임으로 해석하는 데이터 기반 loader
- 활성 VFX 참조·앵커·강도 계약 테스트

catalog 필드:

- `vfx_id`와 실제 파일 또는 프레임 패턴
- `ground / body / aerial` 앵커
- Unit 레이어와 전면 벽을 따르는 깊이 규칙
- `normal / finisher / boss` 강도 등급
- 재생 속도, 반복 여부, 접근성 축소 동작

구현 계약:

- Update 4 하위 폴더까지 검색하고 `vfx_id`, `boss_vfx_id`를 실제 전투에 연결한다.
- 모든 활성 참조는 실제 프레임으로 해석되며 미해결 ID는 검사에서 실패한다.
- 지면 효과는 발 앵커, 몸 효과는 몸 중심, 공중 효과는 비행 앵커를 사용한다.
- 일반 VFX는 캐릭터 실루엣을 오래 가리지 않고 결정타·보스만 확대한다.
- 화면 흔들림, 이펙트 강도, 섬광 감소 옵션을 실제 연출에 연결한다.

완료 기준:

- 활성 참조의 미해결 VFX ID가 0개다.
- 일반 근접·방어·마법·결정타·Update 4 고유 효과를 실제 `1280×720` 전투에서 비교한다.
- 전면 벽 뒤의 캐릭터에 붙은 지면·몸 VFX도 같은 방식으로 가려진다.
- VFX 이미지가 정규화 후에도 계획의 재생성 사유를 남기면 이 페이즈가 해당 이미지를 `FAIL_REGEN`으로 확정하고, 그렇지 않으면 `NORMALIZED_PASS`로 닫는다.

##### V5 실행 결과 (CATALOG_PASS / DEPTH_OCCLUSION_PENDING)

- `data/v122/combat_vfx_catalog.json`에 활성 전투 VFX 34개와 실제 프레임 경로, 지면·몸·공중 앵커, `unit_fx`/`front_fx`/`aerial_fx` 깊이, `normal`/`finisher`/`boss` 강도, 재생·반복·섬광 감소 메타데이터를 고정했다.
- `V122CombatVfxCatalog` loader가 실제 파일·프레임 패턴과 메타데이터를 검증하고, 활성 참조의 미해결 ID가 0개인지 런타임 시작 시 확인한다.
- `GameRoot`에 Update 4 스킬·왕관·경쟁 보스 VFX helper와 접근성 강도/섬광 감소 API를 연결했다. `CombatSceneController`는 catalog 프로필의 앵커·깊이·효과 유지 시간을 읽는다. 다만 현재 Unit의 무제한 월드 Y `z_index`와 VFX의 `-30/3000` 고정 깊이는 실제 전면 벽 계약을 충족하지 않으므로 벽 가림 완료로 표현하지 않는다.
- `V122CombatVfxCatalogTest` 57/57 등 당시 자동 검사는 catalog·경로·고정 숫자를 확인했을 뿐 실제 Unit+전면 벽 계층을 검증하지 않았다. catalog/frame 연결 참고 결과만 PASS다.
- 상세 결과: `docs/qa/V122_V5_COMBAT_VFX_CATALOG_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_V5_COMBAT_VFX_CATALOG_2026-08-02.md`.
- V4-A가 미완료이고 실제 N/E/S/W 전면 벽 뒤의 Unit·ground/body/aerial VFX `1280×720` 비교도 없다. 따라서 V5는 `DEPTH_OCCLUSION_PENDING`이며 `I1-5-OWNER-01` 전에는 V6 재제작 패킷을 시작하지 않는다.

### V6. 정규화 실패 그래픽만 선별 재제작

먼저 전체 비교표에서 아래 항목을 평가한다.

- 2:1 쿼터뷰 투영
- 좌상단 광원과 우하단 그림자
- 회흑색 던전에서의 명도·채도
- 외곽선과 픽셀 밀도
- 발 기준점과 투명 여백
- 기존 캐릭터와의 실루엣 일관성

정규화로 통과한 자산은 유지한다. 아래 사유 중 하나가 V3 또는 V5 감사 문서에서 `FAIL_REGEN`으로 확정된 자산만 GPT 내부 이미지 생성 모델로 다시 만든다.

패킷 계산 규칙:

- 완성된 시트형 런타임 PNG 1개는 이미지 자산 1개로 계산하며 한 패킷에는 정확히 1시트만 다룬다.
- 프레임별 PNG 형식은 한 패킷에 캐릭터 1개·애니메이션 묶음 1개만 다루고 런타임 프레임은 최대 3개다. 프레임이 더 많으면 다음 패킷으로 나눈다.
- 한 캐릭터의 모든 동작 패킷이 끝난 뒤 새 자산 생성 없는 별도 통합 승인 패킷에서 전체 애니메이션을 비교한다.
- 생성 원본·`SOURCE.md`·런타임 자산·연결 데이터·도구/테스트·핸드오프를 포함한 총 7경로 상한을 지킨다. 7경로 안에 끝낼 수 없으면 연결이나 후처리를 다음 패킷으로 분리한다.
- V6는 V3/V5가 확정한 `FAIL_REGEN`만 입력으로 받으며 상태를 새로 판정하지 않는다. 시트형은 시트 1개를 자산 1개로, 개별 프레임형은 캐릭터 1개·애니메이션 묶음 1개로 계산한다.

- 정규화 후에도 발 오차가 2픽셀을 넘음
- 마젠타 제거가 의상·마법의 고유 색을 파괴함
- 목표 크기에서 심한 흐림·절단이 생김
- 맵과 투영 방향이 맞지 않음
- `1280×720`에서 실루엣을 알아보기 어려움

승격 순서:

1. 생성 원본과 `SOURCE.md`
2. 후처리·알파·프레임 분리
3. 기존/후보 contact sheet
4. 실제 게임 `1280×720` 나란히 비교
5. 사용자 승인
6. 런타임 교체

VFX 이미지 재제작이 필요한 경우 캐릭터와 같은 패킷에 섞지 않고 별도 `FAIL_REGEN` 자산군으로 처리한다.

### A2. 현실적 기본 타격과 핵심 UI음

짧은 음원은 한 패킷에 정확히 1개만 생성·후처리·기록·청취한다. 아래 목록은 백로그 순서이며 한 번호 전체를 한 패킷에 끝내라는 뜻이 아니다.

각 승격 패킷은 `v1.2.2 manifest + audio_event_catalog assets/events + source record + runtime WAV`를 같은 변경에서 함께 갱신한다. 네 기록 중 하나라도 빠지면 승격하지 않는다.

1. 날붙이 3변형 + 둔기·방패 3변형
2. 발톱·물기 3변형 + 화염·기본 마법 3변형
3. 천·가죽/신체, 금속 갑옷, 돌·시설 피격 재질
4. 다운·치명·보상
5. UI 클릭·선택·확정·취소·실패·위험 경보

변형은 무작위 난사가 아니라 결정적 순환을 사용해 반복 재현과 테스트가 가능해야 한다. 기존 고유 스킬 24개는 이 페이즈에서 재생성하지 않지만, 출처만으로 `approved` 처리하지 않고 A5·I2 청취 상태를 따른다.

완료 기준:

- 슬라임·임프·일반 근접 공격이 같은 베기음처럼 들리지 않는다.
- 같은 검도 천·갑옷·시설을 칠 때 피격층이 다르다.
- 타이틀 설정 화면에서 Master/Music/SFX 슬라이더의 실제 미리듣기가 된다. A3의 타이틀곡을 선행 조건으로 요구하지 않고, A1에서 연결한 기존 관리곡의 짧은 `preview_music` event를 사용한다.
- DAY 3 x1·x3 짧은 청취에서 클리핑과 반복 피로가 없다.

### A3. BGM 6상태

상태 우선순위:

1. DAY 30 최종전·엔딩
2. 보스 태그가 살아 있는 전투
3. 후반 고위험 일반 전투
4. 일반 전투
5. 관리
6. 타이틀

기존 관리·일반전·보스전 3곡은 먼저 유지 검수한다. 타이틀, 후반 전투, 최종전·엔딩 3곡은 각각 별도 Luna 패킷에서 후보 생성·후처리·loop 청취·출처 기록을 끝낸다.

새 곡 승격도 A2와 같은 manifest·catalog·source·runtime 원자적 기록 계약을 따른다.

상태 선택은 단순 `day == 30`으로 결정하지 않는다.

- 타이틀은 Title screen 진입 사건에서만 선택한다.
- 관리는 전투 밖 Management screen에서 선택한다.
- 후반 고위험 전투는 명시된 combat risk 또는 late-wave 태그로 선택한다.
- 보스는 살아 있는 boss encounter 태그가 후반 일반전보다 우선한다.
- 최종전은 DAY 30의 명시적 final battle encounter에서만 선택한다.
- 엔딩·결과는 final result screen 사건으로 전환하며 DAY 30의 관리·설정 화면을 덮지 않는다.

완료 기준:

- 여섯 상태가 서로 다른 최종 파일을 사용한다.
- 같은 게임의 악기·화성 언어를 유지하되 일반전과 후반전의 긴장도가 구분된다.
- 타이틀→관리→일반전→보스→결과 흐름에서 중복 재생과 하드 컷이 없다.
- 각 곡의 핵심 30초와 stream loop 경계를 사용자에게 들려주고 승인받는다.

### A4. Stage별 환경음과 발소리

환경 loop는 Stage마다 한 패킷으로 만든다.

- Stage 01: 바람, 먼 물방울, 석재 울림
- Stage 02: 낮은 실내 공기, 목재·금속 장치
- Stage 03: 무거운 석재, 먼 전투 진동
- Stage 04: 깊은 공명, 심장·기계성 저음

발소리는 `surface`와 `weight` 두 축으로 선택한다. surface마다 3변형을 목표로 하되 생성 패킷은 `2개 + 1개`로 분리한다.

- `surface`: 거친 동굴석 / 다듬은 성벽석 / 금속·기계 통로
- `weight`: normal / heavy

heavy는 별도 바닥 재질이 아니라 같은 surface의 저음·음량·간격 프로필이다. 따라서 대형·보스가 동굴석에 있으면 동굴석 재질을 유지한 채 heavy 프로필을 적용한다.

구현 계약:

- V2·V3에서 확정한 발 접촉 시점만 사용한다.
- 정지 캐릭터는 발소리를 내지 않는다.
- 화면에 보이는 주요 유닛만 재생하며 발소리 전체 동시 voice는 최대 3이다.
- x3에서는 발소리 밀도를 줄여 타격과 경고를 덮지 않는다.
- 방마다 3D 음원을 만드는 고급 위치 음향은 출시 후로 미룬다.
- 승인된 네 환경 loop를 버스·Stage 사건에 연결하는 패킷과 발 접촉 scheduler를 연결하는 패킷을 분리한다.
- 환경음·발소리 승격도 manifest·catalog·source·runtime 네 기록을 같은 변경에서 갱신한다.

### A5. 선별 합성음 교체와 최종 믹스

교체 순서:

1. 의미가 다른데 파일 해시가 같은 중복 두 쌍
2. 실제 노출되는 라이벌·최종 보스 모티프
3. 왕관 확정과 실키·포포 핵심 사건음
4. 반복 피로가 큰 심장 loop와 적 경고음
5. 나머지는 청취 결과에 따라 유지 또는 퇴역

한 패킷에서 정확히 1개만 교체하고 이번 출시의 생성 교체 상한은 총 12개다. 48개 전부를 재생성하지 않으며, 모든 48개는 출처 `lyria / procedural`과 별개로 최종 청취 상태 `approved / replace / retire` 중 하나를 가져야 한다. 12개를 다 쓴 뒤에도 런타임 연결 asset에 `replace`가 남으면 출시 완료로 처리하지 않고 추가 생성 범위·비용 승인을 기다린다.

최종 믹스 계약:

- BGM, 기본 타격, 판타지 스킬, UI 경보, 환경음, 발소리의 상대 음량표를 고정한다.
- 중요 경보와 보스 모티프 때 음악을 약 3~5dB 낮추되 사용자가 저장한 Music 버스 값을 직접 덮어쓰지 않는다. 별도 transient gain과 중첩 경보 reference count를 사용하고 마지막 경보 종료 때 원래 값으로 정확히 복원한다. 정확한 감소값은 실제 청취로 결정한다.
- limiter를 켠 상태에서 피크 클리핑이 없다.
- 필요할 때만 BGM 압축·스트리밍 형식을 바꾸며 파일 크기만 보고 품질을 낮추지 않는다.
- 전체 catalog asset의 `pending`이 0이고, 런타임 연결 asset의 `replace`가 0이며, `retire` asset의 runtime event 참조가 0이다.
- 모든 연결 asset에는 실제 게임 사건에서 들은 비교 청취 evidence가 하나 이상 있다. 기존 Lyria 28개·고유 스킬 24개·A2~A4 신규 자산도 예외가 아니다.

### Q1. 비시각 출시 공백

한 패킷에 여러 시스템을 감사하지 않는다. 아래 다섯 패킷은 모두 읽기 전용이며 발견 목록과 재현 입구만 만든다.

- `Q1-S 저장·복구`: `1.2.1` 이어하기, 실패 복구, `.tmp/.bak`, 원본 hash·수정 시각
- `Q1-I 입력·IME`: Windows 물리 한/영 조합, Backspace, 화면 전환, touch·landscape
- `Q1-L UI·현지화`: dead click, placeholder, 내부 ID, 한국어·영어 누락, 최장 문구 잘림, 설정 적용·취소·미리보기
- `Q1-P 성능`: 대표 저사양 Windows 전투의 프레임·메모리 급락
- `Q1-R 권리·출처`: 새 자산뿐 아니라 모든 활성 그래픽·오디오의 생성 원본, manifest, `SOURCE.md`, 사용 권리와 deprecated 기록

발견한 P0/P1/P2는 한 결함당 Luna 패킷 하나로만 수정한다. 출시를 막지 않는 항목은 근거와 함께 P3 또는 OUT_OF_SCOPE로 재분류하며, P1을 known issue 승인만으로 남겨 두지 않는다. 새로운 콘텐츠나 밸런스 확장은 만들지 않는다.

#### Q1-S 저장·복구 상세 감사 (완료)

- `V122SaveProgressionTest`, `SaveV4MigrationTest`(42 assertions), `SaveV5MigrationTest`(37 assertions)는 PASS했다. 버전 마이그레이션, `.tmp/.bak` 원자적 복구, 손상·미지원 저장 거부 계약을 확인했다.
- `CampaignSaveLoadSmokeTest`는 246 assertions 중 8건이 실패했다. Stage 04 쿼터뷰 투영 기대 4건과, 전투 overlay가 닫히지 않은 직접 호출 뒤 후일담 autosave·이어하기 연쇄 4건으로 분리했다. 저장 본문 손상으로 단정하지 않는다.
- 실제 1.2.1 원본 SHA-256·수정 시각·후보 Windows 빌드 이어하기는 소유자 검수로 남겼다. 이 패킷에서 런타임·데이터·자산·빌드는 수정하지 않았다.
- 상세 결과: `docs/qa/V122_Q1S_SAVE_RECOVERY_AUDIT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_Q1S_SAVE_RECOVERY_AUDIT_2026-08-02.md`.
- 첫 번째 P2 재현 완료: 실제 전투 종료·overlay 닫힘 뒤 후일담 autosave 흐름은 11 assertions PASS했고 기존 smoke 실패 4건은 `HARNESS_GAP_CONFIRMED_RUNTIME_FLOW_PASS`로 재분류했다.
- 두 번째 P2 재현 완료: Stage 04 `area_room_count=11`과 full-grid 시각 object 투영 수 `12`를 확인했다. `service_entrance`를 포함하는 현재 dual-front layout 때문에 숫자가 달라지며, 제품 계약 결정 전까지 런타임 수정은 보류한다.
- Q1-S 상태: 저장·복구 핵심 테스트 PASS, story autosave 실제 흐름 PASS, Stage 04 투영 계약 `P2_REVIEW_REQUIRED`, 실제 1.2.1 원본 hash/mtime·이어하기 `OWNER_QA_PENDING`. Q1-I 입력·IME로 이어서 진행했다.

#### Q1-I 입력·IME 상세 감사 (완료)

- `GameRoot.gd`의 포커스 소유권, 이름 `LineEdit`의 IME·Backspace·Enter 경로, `InputSettings`의 `physical_keycode` 매칭, touch portrait 차단과 landscape 해제 경로를 읽기 전용으로 확인했다.
- `V122Stage10LocalizationTest`, 관리·전투·결과 UI 방향 계약, `V122ReleaseReadinessTest`는 모두 PASS했다. `Q1IInputImeRepro`는 `--mobile-touch-ui`로 12 assertions PASS했고, 이름 입력 중 전역 키 격리·물리 H 바인딩·390×844 세로 차단·844×390 가로 해제·이름→관리 전환을 확인했다.
- 자동·합성 범위에서 P0/P1/P2 런타임 결함은 재현되지 않았다. 실제 Windows 한/영 IME·조합 중 Backspace·Enter 제출과 실제 Mobile Web/기기 회전·탭은 실행 환경 밖이므로 `OWNER_QA_PENDING` 출시 게이트로 남겼다.
- 상세 결과: `docs/qa/V122_Q1I_INPUT_IME_AUDIT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_Q1I_INPUT_IME_AUDIT_2026-08-02.md`, 기계 결과: `tmp/v122_release_polish/q1_i/q1_i_inventory.{json,tsv}`.
- Q1-I에서는 런타임·데이터·자산·빌드를 수정하지 않았다. 다음 순서는 Q1-L UI·현지화·placeholder 상세 감사다.

#### Q1-L UI·현지화·placeholder 상세 감사 (완료)

- `data/localization/v122_stage10_ui.json`의 `ko/en` 각 142개 키, 설정 61개·이름 20개·튜토리얼 61개를 대조해 누락·빈 값 0을 확인했다. `name.placeholder`는 의도적인 입력 안내이고 `open_placeholder`·`debug_placeholder`·legacy socket marker는 데이터·맵 구조로 분리했다.
- `V122Stage10LocalizationTest`, `V122StoryProductFlowTest`(33 assertions), `V122TutorialGuidanceLevelTest`, 관리·전투·결산 UI 계약은 모두 PASS했다. `Q1LUiLocalizationRepro`는 8 assertions PASS_WITH_FINDINGS로 왕관 후보 `MON_GOBLIN`, 전투 목표 `throne`, 활성 경로 `entrance → spike_corridor → throne` 노출을 재현했다.
- `Q1-L-P3-01`(의회 왕관 후보 instance ID), `Q1-L-P3-03`(전투 목표·경로 room ID), `Q1-L-P3-04`(미지 room ID 결산 fallback)를 출시 비차단 P3/별도 수정 패킷으로 분리했다. S09의 과거 `trap` 노출은 기준 SHA가 달라 `Q1-L-P3-02` 역사적 carry-forward로 두고 현재 후보 재확인을 요구한다.
- 전체 버튼·최대 글꼴·최장 문구·dead click·실제 Windows 후보 화면은 `Q1-L-OWNER-01` `OWNER_QA_PENDING` 출시 게이트다. 자동·합성 범위에는 P0/P1/P2 런타임 결함이 없었다.
- 상세 결과: `docs/qa/V122_Q1L_UI_LOCALIZATION_PLACEHOLDER_AUDIT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_Q1L_UI_LOCALIZATION_PLACEHOLDER_AUDIT_2026-08-02.md`, 기계 결과: `tmp/v122_release_polish/q1_l/q1_l_inventory.{json,tsv}`.
- Q1-L에서는 런타임·데이터·자산·빌드를 수정하지 않았다. 다음 순서는 Q1-P 성능 상세 감사다.

#### Q1-P 성능·메모리 상세 감사 (완료)

- `EngineerPerformanceSmokeTest`(20 assertions)와 `V122CombatVisualHierarchyTest`를 다시 실행해 Windows full 프로필의 화면 전환 draw guard, idle 전투, 공병 프레임 공유, 동적 overlay·함정·시설 분리를 PASS로 확인했다.
- `Q1PPerformanceRepro`는 idle, 동적 표식 20개, 타격 효과 24개, 함정, 시설 카운트다운, 복합 표식·타격·함정·시설을 시나리오당 120프레임 합성했다. 모든 시나리오의 정적 맵 전체 redraw는 0회였고 wall p95는 각각 16.468, 15.034, 15.955, 15.954, 15.926, 15.129ms였다.
- 복합 시나리오의 Godot `memory_static` peak는 326,248,559B로 idle peak 325,828,751B보다 약 419,808B 높았다. 이는 내부 정적 메모리와 테스트 생성 자원만 나타내며 Windows RSS·VRAM·장시간 누수 판정값이 아니다. headless 더미 렌더러의 GPU draw-call 값은 승인 근거로 사용하지 않았다.
- `Q1-P-PASS-01`은 출시 비차단 targeted PASS다. 실제 Windows GPU·저사양 메모리/RSS·최소 10분 혼잡 전투는 `Q1-P-OWNER-01` `OWNER_QA_PENDING` 출시 게이트로 남겼다. 직접 전투 합성의 autosave/ObjectDB/RID 종료 경고는 `Q1-P-HARNESS-01` harness noise다.
- 상세 결과: `docs/qa/V122_Q1P_PERFORMANCE_AUDIT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_Q1P_PERFORMANCE_AUDIT_2026-08-02.md`, 기계 결과: `tmp/v122_release_polish/q1_p/q1_p_inventory.{json,tsv}`.
- Q1-P에서는 런타임·데이터·자산·빌드를 수정하지 않았다. 다음 순서는 Q1-R 권리·출처·deprecated 상세 감사다.

#### Q1-R 권리·출처·deprecated 상세 감사 (완료)

- F0-V/F0-A 인벤토리와 Update4·던전·벽 manifest를 교차 대조해 활성 그래픽 37개 고유 스프라이트, Update4 런타임 경로 138개, 구조 벽 runtime 14개, 오디오 76개의 실제 파일 존재를 확인했다. 활성 연결 source record 46개(문서 45개)의 누락은 0개였다.
- 기존 `tools/audio/lyria_v05_manifest.json`은 활성 WAV 76/76을 연결하지만 target은 `v0.5`다. 계획상 필요한 `tools/audio/lyria_v122_manifest.json`과 `data/audio/audio_event_catalog.json`은 존재하지 않아 `Q1-R-P2-01` release gate로 남겼다.
- `combat_dungeon_pressure`는 활성 Lyria 원본과 약 116.9초 WAV를 사용하지만 공용 `assets/audio/bgm/SOURCE.md`는 절차적 합성·30초라고 설명한다. `Q1-R-P2-02`로 분리했으며 이번 패킷에서는 문서·오디오를 수정하지 않았다.
- 전체 SOURCE.md 72개 중 41개, 활성 연결 문서 45개 중 29개가 AGENTS 고정 출처 필드를 완전히 갖추지 않았다. 권리 위반을 판정한 것이 아니라 표준화·소유자 승인이 필요하다는 P3/OWNER 경계다.
- legacy wall quarantine 5그룹·12경로와 proof-only 정책은 유지되며 활성 런타임 적중은 각각 0개였다. 상세 결과: `docs/qa/V122_Q1R_SOURCE_RIGHTS_DEPRECATED_AUDIT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_Q1R_SOURCE_RIGHTS_DEPRECATED_AUDIT_2026-08-02.md`, 기계 결과: `tmp/v122_release_polish/q1_r/q1_r_inventory.{json,tsv}`.
- Q1-R에서는 런타임·데이터·자산·빌드를 수정하지 않았다. 다음 순서는 I1 통합 대표 검수지만, Q1-R의 P2 release gate와 OWNER 청취·권리·승격 검수는 먼저 해소해야 한다.

### I1. 통합 대표 검수

이 페이즈는 새 기능과 자산을 만들지 않는다.

각 번호를 별도 검수 패킷으로 수행한다.

1. 타이틀과 설정 미리듣기
2. 관리 화면 BGM·UI음
3. DAY 3 도둑 침입, 집중 명령, 도둑 사냥꾼 특성, 혼잡 타격
4. 후반 일반 전투
5. 보스 및 최종전 음악·VFX
6. Stage 01~04 환경음·발소리 전환

각 패킷은 `1280×720` 대표 화면 또는 해당 청취 시나리오 하나만 판정한다. 여섯 패킷의 합산 청취 시간을 최소 20분으로 기록하고, 최종 합산 결과는 헤드폰과 일반 스피커에서 각각 확인한다. 이것은 DAY 1~30 전체 플레이나 Full 검증을 대신하지 않는다.

#### I1-1 타이틀·설정 대표 검수 (완료)

- 실제 Godot 렌더링 환경에서 `1280×720` 타이틀, 화면 설정, 오디오 설정을 각각 캡처했다. 타이틀→설정 이동과 display/audio 카테고리 전환은 4 assertions PASS다.
- `V122Stage10LocalizationTest` 42 assertions와 `V122ManagementUIContractTest`도 PASS했다. 캡처와 기계 결과는 `tmp/v122_release_polish/i1_1_title_settings/`에 남겼다.
- 이번 패킷은 화면 구조·설정 진입 계약만 판정했다. 헤드폰·일반 스피커 실제 청취와 실제 Windows 후보의 버튼·최장 문구·음량 체감은 `I1-1-OWNER-01`로 남겼다.
- 상세 결과: `docs/qa/V122_I1_1_TITLE_SETTINGS_REPRESENTATIVE_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_I1_1_TITLE_SETTINGS_REPRESENTATIVE_2026-08-02.md`.
- I1-1에서는 런타임·데이터·자산·빌드를 수정하지 않았다. 다음 순서는 I1-2 관리 화면 BGM·UI음 대표 검수다.

#### I1-2 관리 화면 BGM·UI음 대표 검수 (완료)

- 실제 `1280×720` 관리 화면을 캡처하고 `management_castle_bustle.wav`가 관리 화면의 음악 stream으로 선택·재생되는지 4 assertions PASS로 확인했다.
- `HUDController.gd`에는 전용 관리 UI 클릭·탭 효과음 hook이 없고, `GameRoot.gd`의 기존 `AudioStreamPlayer`는 BGM·Update3·전투 효과용이다. UI음은 새로 만들거나 연결하지 않고 `I1-2-UI-SFX-GAP`으로 별도 A1 패킷에 남겼다.
- 검수용 저장을 비활성화해 자동 저장 경고가 대표 캡처를 가리지 않게 했으며, 제품 저장 코드는 수정하지 않았다. 상세 결과: `docs/qa/V122_I1_2_MANAGEMENT_AUDIO_REPRESENTATIVE_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_I1_2_MANAGEMENT_AUDIO_REPRESENTATIVE_2026-08-02.md`.
- 실제 헤드폰·일반 스피커 청취, UI음 체감, Q1-R 권리·manifest gate는 OWNER 대기다. 다음 순서는 I1-3 DAY 3 도둑·집중·혼잡 타격 대표 검수다.

#### I1-3 DAY 3 도둑·집중·혼잡 타격 대표 검수 (완료)

- 실제 Godot 렌더링 환경에서 `1280×720` DAY 3 전투의 도둑 침입·도둑 사냥꾼 특성·집중 명령·혼잡 타격 상황을 캡처했다. 도둑 사냥꾼 특성 적용, 전투 진입, 유닛 구성, 집중 모드, 도둑 instance 해석, 집중 기본 공격의 7 assertions가 모두 PASS다.
- 더 가까운 일반 탐험가가 있어도 집중 대상은 도둑으로 유지됐고, 대표 타격에서 도둑 HP는 `-21`, 탐험가 HP는 `0`으로 확인했다. 기계 결과와 캡처는 `tmp/v122_release_polish/i1_3_day3_focus/`에 남겼다.
- 기존 `V122DefenderConnectorTest`와 `V122CommandButtonIntegrationTest`도 다시 실행해 PASS했다. headless 종료 시 Godot harness의 ObjectDB/resource leak 경고가 출력됐지만 종료 코드는 0이며 제품 실패로 분류하지 않았다.
- 상세 결과: `docs/qa/V122_I1_3_DAY3_THIEF_FOCUS_REPRESENTATIVE_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_I1_3_DAY3_THIEF_FOCUS_REPRESENTATIVE_2026-08-02.md`.
- 이번 패킷에서는 런타임·데이터·자산·빌드를 수정하지 않았다. 실제 소유자 DAY 3 플레이 확인은 `I1-3-OWNER-01`로 남겼고, 다음 순서는 I1-4 후반 일반 전투 대표 검수다.

#### I1-4 후반 일반 전투 대표 검수 (완료)

- DAY 20을 후반 일반 전투 대표로 삼아 실제 Godot Vulkan 환경에서 `1280×720` 준비·기본 타격·화염구 시전·도착·결과 화면을 캡처했다. 슬라임·고블린·임프와 탐험가·조사관·공병을 배치했고 보스는 넣지 않았다.
- 일반전 BGM `combat_dungeon_pressure.wav` 유지, 고블린 기본 공격의 탐험가 `90` 피해, 임프 화염구의 탐험가 `73` 피해, 실제 결과 화면 전환과 관리 BGM 복귀를 13 assertions PASS로 확인했다.
- `V122CombatResultUIContractTest`, `V122ResultUISimplificationTest`(37 assertions), `V122CombatUISimplificationTest`(85 assertions), `V122CombatVisualHierarchyTest`가 모두 PASS다. 재도전 결과 테스트의 한 프레임 시점 차이는 화면 표시가 3초임을 보장하는 범위 계약으로만 보정했고 런타임은 수정하지 않았다.
- 상세 결과: `docs/qa/V122_I1_4_LATE_COMBAT_REPRESENTATIVE_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_I1_4_LATE_COMBAT_REPRESENTATIVE_2026-08-02.md`, 기계 결과: `tmp/v122_release_polish/i1_4_late_combat/i1_4_inventory.json`.
- 실제 소유자 청취·Windows 후보 조작은 `I1-4-OWNER-01`로 남겼다. 다음 순서는 I1-5 보스·최종전 음악·VFX 대표 검수다.

#### I1-5 보스·최종전 음악·VFX 대표 검수 (완료)

- DAY 30을 최종전 대표로 삼아 실제 Godot Vulkan 환경에서 `1280×720` 보스 준비·검수 예고·축성 바닥·자비의 방벽 화면을 캡처했다. 정식 셀렌(`official_paladin_selen`)과 탐험가·슬라임을 함께 배치해 보스의 화면 맥락을 확인했다.
- 살아 있는 보스 감지 뒤 보스 전용 BGM `combat_boss_council.wav`로 전환되는 것을 확인했다. 검수 예고의 0.8초 이상 경고, HP 65% 이하 축성 바닥, HP 35% 이하 마지막 단계와 자비의 방벽을 실제 상태 전환으로 확인했다.
- 대표 검수는 11 assertions PASS, 실패 0건이다. `OfficialSelenPhase20Test`(26 assertions)와 `EndingPhase28Test`(45 assertions)도 PASS했다.
- 상세 결과: `docs/qa/V122_I1_5_BOSS_FINAL_REPRESENTATIVE_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_I1_5_BOSS_FINAL_REPRESENTATIVE_2026-08-02.md`, 기계 결과: `tmp/v122_release_polish/i1_5_boss_final/i1_5_inventory.json`.
- 실제 소유자 청취·Windows 후보 조작은 `I1-5-OWNER-01`로 남겼다. 이번 패킷에서는 런타임·데이터·자산·빌드를 수정하지 않았고, 다음 순서는 I1-6 Stage 01~04 환경음·발소리 전환이다.

#### I1-6 Stage 01~04 환경음·발소리 전환 공백 감사 (감사 완료, A4 대기)

- Stage ID 네 개의 순서와 현재 오디오 버스 기준선을 읽기 전용으로 확인했다. 현재 버스는 `Master / Music / SFX`이며 `Ambience` 버스와 발 접촉 scheduler가 없다.
- Stage 01~04 환경 loop 후보 4개와 동굴석·성벽석·금속 통로의 normal/heavy 발소리 후보 4개가 아직 없음을 확인했다. 공백은 총 10건이다.
- `I1StageAudioGapAudit` 4 baseline assertions가 실행 완료됐고, 결과는 `AUDIT_ONLY_BLOCKED_PENDING_A4`다. 이번 패킷에서는 런타임·데이터·자산·빌드를 수정하지 않았다.
- 상세 결과: `docs/qa/V122_I1_6_STAGE_AUDIO_GAP_AUDIT_2026-08-02.md`, 핸드오프: `docs/handoff/V122_RELEASE_POLISH_I1_6_STAGE_AUDIO_GAP_AUDIT_2026-08-02.md`, 기계 결과: `tmp/v122_release_polish/i1_6_stage_audio/i1_6_inventory.json`.
- 다음 순서는 외부 음원 생성이 아니라 A0 v1.2.2 manifest·출처·승격 계약이었다. 계약은 완료했지만 사용자의 생성·비용·청취 승인이 없는 동안 A4 자산과 런타임 연결은 보류한다.

### I2. 사용자 비교 승인

- 캐릭터는 기존/수정 contact sheet와 실제 화면을 함께 보여 준다.
- BGM은 핵심 30초와 loop 경계를 들려준다.
- 타격·환경음은 같은 전투의 전/후 비교를 제공한다.
- 사용자 지적 한 건을 여러 결함과 묶지 않고 새 패킷 하나로 수정한다.
- 아래 승인 대상의 `pending`이 남아 있으면 출시 완료로 표시하지 않는다.
  - BGM 6상태의 핵심 30초·stream loop·상태 전환
  - 기본 타격·피격 재질음과 핵심 UI음
  - Stage 01~04 환경음과 surface·weight 발소리
  - 기존 고유 스킬 24개, Lyria 출처 28개, 실제 연결된 보조 합성음과 A2~A4 신규 자산

### R1. 정식 출시 검수와 후보

이 페이즈는 현재 `PLANNED`이며 아직 실행 승인을 받은 것이 아니다. `R1 시작` 한 번으로 아래 모든 외부 변경을 포괄 승인한 것으로 보지 않고, 각 하위 게이트마다 사용자의 별도 명시 지시를 받는다.

#### R1-A release 통합선 동결

1. 완료한 개별 `codex/v122-*` PR을 필수 상태 확인 뒤 merge commit으로 `release/v1.2.2`에 통합한다.
2. `README.md`의 공개·후보 버전 상태, 새 `docs/release/V1_2_2_RELEASE_NOTES_<release-date>.md`, `docs/handoff/CURRENT.md`를 최종 내용으로 갱신한다.
3. 버전·릴리스 문서·정책 관련 검사를 다시 실행한다. 출시 결함 등급 P0/P1/P2가 0이고 OUT_OF_SCOPE·P3가 근거와 함께 분리됐는지 확인한다.
4. 통합선의 40자리 SHA를 `release_candidate_sha`로 기록하고 이후 README·릴리스 노트를 포함한 제품 코드·데이터·자산·문서를 동결한다.

#### R1-B 사용자 OWNER 전체 QA

1. 사용자가 `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md` 전체를 축약 없이 수행한다.
2. 여기에는 DAY 1~30, 시설 중심·성장 중심·명령 최소 빌드, Update 2~4, 1920×1080·1366×768·1280×720, 모바일 landscape·touch·최대 글꼴, 설정→튜토리얼 비변경, dead click·placeholder, Update 4 마젠타, `1.2.1` 저장 hash·mtime와 `.tmp/.bak` 손상 복구가 모두 포함된다.
3. 실패 한 건은 새 `codex/v122-*` Luna 패킷 하나로 수정하고 관련 검사를 다시 거쳐 `release/v1.2.2`에 통합한다. 이 경우 R1-A의 출시 문서·검사를 다시 닫고 새 SHA를 동결한 뒤 영향받은 OWNER 경로를 재검수한다.
4. 사용자 PASS의 `source_sha`는 최종 `release_candidate_sha`와 정확히 같아야 하며, PASS 뒤 이 값을 `reviewed_release_sha`로 고정한다.

#### R1-C Full 검증

1. 사용자의 별도 명시 승인 뒤 `reviewed_release_sha`에서만 Full 검증과 요청된 별도 검수를 실행한다.
2. 정책 필드에는 실제 Review task ID, Reviewed SHA, `Remaining P1/P2: 0`, PASS를 기록한다.
3. 검증 결과를 기록하는 `docs/handoff/` 전용 종료 커밋 뒤 release HEAD를 `release_evidence_sha`로 기록한다. `reviewed_release_sha..release_evidence_sha`에는 handoff 문서만 있어야 한다.
4. 검증 뒤 `docs/handoff/` 밖의 파일이 달라지면 이전 사용자 PASS와 Full 결과를 무효로 하고 R1-A부터 필요한 검수를 다시 한다.

#### R1-D 후보 export·hash

1. 별도 명시 승인 뒤 같은 `reviewed_release_sha`에서 Windows Desktop과 PC Web·Mobile Web 후보를 export하고 실행·대표 부팅·SHA-256·오디오 포함을 확인한다.
2. `docs/handoff/V122_P17_RELEASE_READINESS_2026-07-27.md`의 PC Web·Mobile Web·Windows Desktop·Windows Steam 네 preset 상태를 모두 기록한다. Steam용 빌드 기술 검증과 계약·세금·App ID·스토어 심사 같은 외부 owner gate는 별도 상태로 구분한다.
3. 후보 산출물은 소스 브랜치에 커밋하지 않고 승인된 artifact 경로에만 보관한다.

#### R1-E main 통합

1. 별도 명시 승인 뒤 `release/v1.2.2`에서 `main`으로 PR을 열고 필수 상태를 통과한 merge commit으로만 병합한다.
2. 새 `main_merge_sha`에서 `reviewed_release_sha`와 비교해 `docs/handoff/**`만 차이가 나고, 그 밖의 제품 tree가 정확히 같은지 확인한다. README·릴리스 노트는 예외가 아니며 달라지면 태그를 만들지 않는다.
3. `release_evidence_sha`가 `main_merge_sha`의 두 번째 부모 계보에 포함되고, `repository-policy`를 포함한 필수 상태가 `main_merge_sha`에서 통과해야 한다.
4. handoff 밖 차이가 있으면 원인을 감사하고 제품 변경은 R1-A부터 재검수한다.

#### R1-F 태그·Release

1. 별도 명시 승인 뒤 검수된 제품 tree와 동일성이 확인된 정확한 `main_merge_sha`에 불변 annotated `v1.2.2` 태그를 만든다.
2. 태그에서 Windows·Web artifact, manifest, SHA-256을 생성하고 대표 실행을 확인한 뒤 GitHub Release에 올린다.
3. 기존 `v1.2.1` 태그와 Release 자산은 이동하거나 교체하지 않는다.

Steam 계약·세금·App ID·스토어 심사·Coming Soon은 제품 코드 완성 검수와 분리된 외부 게이트다.

## 8. 예상 테스트 계약

기존 테스트는 가능한 한 확장하고, 새 테스트는 실제 결함 계약에만 추가한다.

| 영역 | 기존 기반 | 필요한 추가 계약 |
|---|---|---|
| 캐릭터 계층 | `V122CombatVisualHierarchyTest` | 프로필 누락, 맵 비례 크기, 발 흔들림, 비행 예외 |
| 벽 가림 | `V122CorridorTopologyLayoutMatrixTest` | 실제 유닛과 전면 벽의 Canvas 순서 |
| 오디오 승격 | `tools/audio/test_lyria_pipeline.py` | v1.2.2 manifest 선택, 선언 수량·해시·출처 경로, v0.5 불변 |
| 음악 | `MusicStateAudioTest` | 6상태 선택, loop, crossfade, 최종전 우선순위 |
| 스킬음 | `SkillAudioPaletteTest` | 기존 고유 스킬 24개 event 연결 유지, 출처와 청취 상태 분리 |
| 기본 타격 | 신규 소형 계약 | 무기·피격 재질 조합과 결정적 변형 |
| 믹서 | 신규 소형 계약 | 버스 라우팅, 음소거, limiter, voice cap |
| 접촉 시점 | 신규 소형 계약 | 피해·소리·VFX·반응 동일 simulation 사건 |
| VFX catalog | 신규 소형 계약 | Update 4 포함 활성 ID, 앵커, 가림, 강도, 접근성 |
| 환경음·발소리 | 신규 소형 계약 | Stage 라우팅, 정지 무음, voice budget |
| 출시 준비 | `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md` 전체 | 출시 문서 재검사, 사용자 요청 뒤 Full, Windows·Web 후보·hash, handoff 제외 release/main 제품 tree 동일성 |

매 패킷에서 Quick/Full 전체를 반복하지 않는다. 마지막 R1에서 사용자가 명시적으로 요청한 경우에만 전체 검증을 수행한다.

## 9. Luna용 시작 지시문 템플릿

아래 문구의 대괄호만 현재 페이즈 값으로 바꿔 Luna에게 전달한다.

```text
목표 버전은 v1.2.2다. 이번 작업에서는 [페이즈 ID와 이름] 패킷 하나만 수행한다.

먼저 AGENTS.md, docs/handoff/CURRENT.md, docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md의 해당 페이즈, [직전 핸드오프]를 전체 읽어라.

기준 브랜치/SHA: [브랜치] / [40자리 SHA]
관찰 증상: [사용자에게 보이는 문제 1개]
변경 허용 경로: [최대 4개 코드·데이터 또는 계획의 자산 상한]
절대 변경 금지: 밸런스, 스토리, 다른 페이즈, 기존 dirty 13개, tmp 외 빌드 산출물
완료 조건: [계획의 수치·화면·청취 기준]
실행할 관련 검사: [직접 테스트 한 묶음]
대표 확인: [DAY/화면/1280×720 또는 청취 이벤트]

상한을 넘거나 공통 구조 결함을 발견하면 임의 확장하지 말고 중단 사유와 다음 패킷 분할안을 보고하라. 완료하면 해당 핸드오프와 CURRENT를 갱신하고, 허용 파일만 명시적으로 스테이징할 수 있는 목록을 보고하라. 푸시·PR·Full·빌드·태그는 하지 마라.
```

## 10. 최종 완료 정의

- BGM 6상태가 끊김 없이 반복·전환된다.
- 모든 실제 오디오 이벤트가 catalog에 있고 미분류·무음 폴백·음량 우회·의미가 다른 동일 파일이 없다.
- 전체 catalog의 `pending`과 런타임 연결 asset의 `replace`가 0이고, `retire` asset은 실제 event에서 참조되지 않는다.
- 일반 공격이 무기와 피격 재질에 따라 구분되고, 핵심 UI·환경음·발소리가 과밀하지 않게 들린다.
- 모든 활성 지상 캐릭터의 발 위치와 작은 회흑색 그림자가 일치하고, 일반 체격은 맵 비례 정규화 후 약 15% 커진다.
- 비행·소형·대형·보스만 명시적 예외를 사용한다.
- 캐릭터가 전면 벽 앞으로 튀어나오지 않고 이름·HP·피해 숫자가 몸과 벽을 가리지 않는다.
- 피해·타격음·VFX·피격 동작·피해 숫자가 같은 접촉 사건에서 시작한다.
- 정규화로 해결되지 않은 그래픽만 선별 재제작되고 생성 출처·후처리·실제 화면 승인이 기록돼 있다.
- 출시 전 결함 P0/P1/P2와 사용자 지적이 0이며, 고급 확장 기능은 결함 등급과 다른 POST_RELEASE 목록으로 분리돼 있다.
- 사용자 전체 QA·Full·Windows와 Web 후보·hash는 고정된 `reviewed_release_sha`에서 완료되고, `main_merge_sha`는 `docs/handoff/**`를 제외한 제품 tree가 그 검수 기준과 동일함을 확인한 뒤에만 태그·Release 기준이 된다.
