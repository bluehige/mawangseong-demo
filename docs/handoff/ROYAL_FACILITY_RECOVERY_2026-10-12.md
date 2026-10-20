# 왕관 톡톡 — 실제 시설 수리·방호·이동 제련

Product/Reviewed SHA: `15d5efb67a6cc6c5229e2eadc734d9b710debd32`. Branch `codex/royal-facility-skill-recovery`, Godot4.6.3, 표시1.2.11 유지. 독립 집중 읽기 `/root/skill_action_review`: TARGETED_PASS, 열린 확정 P1/P2 0; 전체제품 review task NOT_REQUESTED. [최신 승인과 명세](SKILL_COMPLETION_SPEC_2026-10-12.md).

## 연결한 효과

`royal_emergency_plating`: 현재 살아 있는 왕관 톡톡의 실제1F 손상 시설을 대상으로 한다. 물리 방 안 또는 기존 판금120거리와 검증된 경로로 닿는 시설 중 HP비율 최저를 준비 때 고정하고 접촉 때 ID/역할/활성/마력/봉인/왕관을 다시 확인한다. 마나0/CD0/전투1회. 일반 heart 수리×1.25는 유지하되 왕관 수리는 **최종실효수리 floor(maxHP×.30)** 이하로 cap하며 초과 심장 기여를 만들지 않는다. 정수 floor는 30%초과를 막는 실행 명세 선택이다.

8초 방호의 비어 있던 크기는 기존 젤의 .30피해감소를 차용한 NEW_DESIGN. 기존 shield→심장.88커널은 그대로 뒤에 적용하고, 보호 여부를 비교하는 순수 deep-copy 미리 계산은 버린다. 실제 HP손실 차이만 방호 기여에 기록한다. overkill요청량/심장 shield소모/지표를 두 번 적용하지 않는다. 시전자 비활성/down/free/queued/억제, 목표 교체/disabled/층identity변경, simulation시각8초에서 보호 해제. 이후 이동×.75/5초는 별도 actor 타이머다.

`moving_forge`의 원기획·Service 원본은 시설 **피해**이며 누적 수리가 아니다. 같은 실제 물리 방의 마지막 양수 실효HP손실을 ceil(loss/10),cap1–6으로 DEF에 별도 더한다.35→4, 다음1→1로 대체; 회복·이미0HP·예방피해·요청overkill은 새 제련 사건이 아니다. 방 이탈/억제는 그 전투 보너스를 즉시 지운다. assigned_room만 같은 원격 보너스나 재진입의 오래된 보너스 복원 없음. 기존 legacy scrap raw-hit producer와 별개다.

컷신은 build-hover 그림이나 시설형 가짜 Unit을 사용하지 않는다. 실제 quarter renderer의 배치instance ID, current back/front texture와 rect를 읽고 별도 art canvas에 표시한다. 실제 심장 AtlasTexture와 기존 chroma material도 유지한다. 접촉 시 HP40→70 같은 실제 전후값과 수리30·방호8초 표시. 실제월드 Sprite transform/node/texture 변경0. 왕관 톡톡은 현재 native frames, once/always/off와 실제auto는 공통 요청/커밋 경로다.

## 검증

| 검사 | 결과 |
|---|---|
| CrownFacilityRecoveryTest GUI | PASS120/0: policy/auto동일, 실제시설art/왕관actor, 준비효과0, cap/심장중복소모0, last-loss제련, 메뉴x3/세이브임시상태제외, 교체·disabled·flooradapter·queued즉시폐기 |
| 기존 석골 심장 | PASS34/0: ordinary 수리boost/피해/shield/충전/안전저장 |
| 기본지원 / 모리 GUI | PASS253/0 / PASS119/0 |
| 저장·메뉴 continuity | PASS89/0; 의도된 저장실패 경고 포함 |
| editor / private export | exit0 / exit0 |
| 실제 새 PCK | PASS14/0: 실제효과·그림·한도·제련·종료 |
| 격리 EXE | 180frames 결과는 아래 manifest가 실행값을 소유 |
| 독립 집중 읽기 | TARGETED_PASS; 독립engine실행 NOT_RUN |

첫104PASS 후 검수P2(심장 재질 누락)를 고쳤다.112→120 최종확대는 실제심장그림/HP표시와경계fixture추가다. 첫 continuity는 userdata marker를 잘못 정해 안전 guard에서 FAIL했고 개인데이터에 접근하지 않았다. 적절한 `continuity_review` 분리 경로로 최종89/0을 다시 확인했다. 실패로그 보존, PASS로 세지 않는다.

## 경계·복구점

현재 일반 실전시설1F 연결이다. 심장 그림 검사는 production heart renderer+실제Atlas/재질과 **synthetic HP변경 packet**이며 왕관→심장 피해 전체루프/정상심장해금 증거가 아니다. real2F왕관실·인장금고의 실제목표는 별도층/채널 작업 전까지 NOT_RUN. 금고에 가짜HP를 만들지 않았다. forcedcrown/controlled시설HP는 정상mastery/영입 증거가 아니다. 사람OS·밸런스·전체캠페인·두PCCloud·DKSteamworks 읽기 NOT_RUN.

별도 `task-2/evidence/royal-support-recovery/facility-development-build`의 `development-manifest.json`이 EXE/PCK/launcher 해시·부팅·보존 결과를 가진다. ReviewEvidence에 이번8GPU캡처와검사로그·독립검수, 이전 Mori6869/기본5f/979/aab 패키지는 유지한다. 개인698+백업 해시는 보존 검사 결과와 대조한다. 공개Steam/원격Git/홍보 변경0.

다음 승인 범위는 잔여4액티브(메아리/곱/핀/왕관전령), 젤계승·잔여passive, 왕관body억제/저항과 정상영입/mastery이다. 실제 상층 연결과 핀의 존재하지 않는 최대마나 모델에 구체 선택을 요청했고 답 없는 상태의 의존 작업은 보류한다. 독립 구현은 계속하며 성장코드는 스킬 묶음 뒤 순서다.
