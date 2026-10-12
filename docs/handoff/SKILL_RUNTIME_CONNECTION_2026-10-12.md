# 실키 응급 실밥·푸딩 왕관 젤 기본 효과 연결

## 1. 메타데이터

- 작성일: 2026-10-12 UTC. 목표: Who Guards the Demon Castle1.2.11 비공개 개발 검토.
- 작업 브랜치: codex/skill-runtime-connection. 분리 작업본: task-2/mawangseong-action.
- 기준: c1e81dcccd9c4b8df330d08e7ea81a82c4029203. 이전 제품6618c0998451f2eda30bc0a40ce64de0105b6f80.
- 제품 커밋: aab19e40edc77b5b9baa52e47cdd360232e578a4. 문서 후속 커밋은 제품 코드 변경 없음.
- 원격 push/merge/PR/Steam 업로드·설정 변경: 없음. 로컬 main없음/origin main0ac9fdc7은 과거 관측, 원격 최신 NOT_RUN.
- 허브 등록 baseline은 기존 sibling mawangseong/562f0d1이며 이 분리 작업본으로 바꾸지 않았다.

## 2. 요청 및 원인

사용자가 미연결이면 실제 효과·컷신까지 연결하고, 설계나 기반이 없으면 따로 보고하도록 승인했다. Silky/Popo의 기본4개는 왕관과 무관한 Lv1 기본 슬롯이다. 데이터·서비스는 있으나 실제 전투 호출자가 빠져 있었다. 왕관6은 획득/선택/억제/외형/능력치 경로가 있고, 일부 왕관 액티브·패시브 전투 연동이 빠져 있었다. 의도적 보류라는 기록을 찾지 못했으며 통합 누락이라는 설명은 코드 근거에 따른 추론이다. 사전 원인 문서는 evidence/SKILL_SUPPORT_CAUSE_20261012.md에 보존한다.

완료 범위는 응급 실밥 및 왕관 젤 기본 방어/흡수와 실제 컷신이다. 열 개 전부 또는 모든 왕관 효과 완료가 아니다.

## 3. 완료 동작 및 구현 판단

- emergency_thread_pull: 실제 HP35% 이하 살아 있는 동료 중 최저 HP 선택(본인 제외), mana14/CD10, 기존10% 보호막/warden7%/tailor15%. 전체 보행 가능 경로120px 이하를 검증하여 효과 접촉 시 끝점으로 실제 당기고 navigation/방·깊이를 갱신한다. 원 설계에 이동 시간이 없어 즉시 당김을 선택했다. 임의 이동속도/무적은 추가하지 않았다. 보스·봉인·합동기 이동잠금에는 보호만 적용한다. 무효 대상/HP 변화/마나 부족이면 준비 이후 비용·이력·컷신을 잘못 확정하지 않는다.
- tailor 시설 수리12: 실제 손상 시설 복구를 기존 helper 및 patch_plates120px 범위로 제한했다. 이 대상/범위 재사용은 구현 판단이지 실키에 별도 명시된 규칙이라고 주장하지 않는다.
- royal_jelly_bastion: 실제 council 선택/활성 왕관 푸딩에 기존 두 액티브를 유지한 세 번째 슬롯. 전투1회/비용0, 기존 서비스 기본6초/피해감소30%/피해흡수35%, 실제 같은 방 동료. 각 timer/protector를 기존 방어막/합동기 redirect와 분리해 서로 수명을 늘리지 않는다. 겹치는 redirect는 강한 하나만 선택, 재진입 가드로 순환 종료. 억제·이미 사용한 왕관은 확정 거부.
- 실제 수동/자동 준비→현재 외형 컷신→효과 접촉, 기존 SFX/VFX 및 off/once/always 정책. 시전 caption은 ‘시전/Cast/施法’. 실키 HUD에는 계단 꿰매기 미지원, 왕관 젤에는 분기 계승 미지원/사용 완료를 명시한다.
- 저장 형식·개인 경로·버전·해금·공격력·적 수·배속 값은 이 수정에서 바꾸지 않았다. 새 이미지/SDK/서비스 없음.

## 4. 수정 파일

| 파일 | 변경 |
|---|---|
| scripts/game/CombatSceneController.gd | 실제 구조/왕관 슬롯·준비 검증·효과·자동 사용·가용성 안내 |
| scripts/units/Unit.gd | 독립 왕관 방어/흡수 수명·피해 처리·순환 가드 |
| scripts/ui/HUDController.gd | 부분 지원/이름별 미지원·사용 완료 |
| scripts/ui/SkillActionPresentation.gd | 지원 시전 caption |
| tools/tests/SkillActionRosterMatrixTest.gd | 새 실제 연결과 남은 미지원 분리 |
| tools/tests/SkillRuntimeConnectionTest.gd/.uid/.tscn | 전용 상태·실제 효과·GUI 회귀 |

8파일360추가19삭제. 생성 import 변경은 되돌렸고 기존 사용자 저장/다른 프로젝트에는 쓰지 않았다.

## 5. 자산과 실제 캡처

기존 각 캐릭터 현재 외형·기존 update4/왕관 음향·VFX를 사용했다. 새 생성 이미지/편집본/SOURCE.md 추가 없음. 로스터 matrix는26형태/106스킬경로(96성공+10기대 미지원)/52합동 경로, 실제 GPU151PNG(148action+3미지원HUD). 두 왕관 동시 조합4경로는 실제 캠페인에서 불가능한 리소스 fixture이므로 실플레이로 세지 않는다.

새 효과 전용 GUI12PNG는 tmp/skill_runtime_connection. 작성자는 새 영향 장면2장을 직접 열었고 검수자는 자동 준비/영향 대표 장면을 직접 열었다. 모든151+12장에 개별 육안 PASS를 주장하지 않는다. 기존6618의29장 육안 검토를 이 새 버전 전체 검토로 바꾸지 않는다.

## 6. 검증 및 독립 검수

근거 루트: ../evidence/runtime-connection (작업 루트 기준). Godot4.6.3.stable.official.7d41c59c4, 실제 NVIDIA3060Ti OpenGL. 모든 실행은 별도 APPDATA.

| 검증 | 결과 | 근거 |
|---|---|---|
| SkillRuntimeConnectionTest 최종 실제 GUI | PASS126/0, ScriptError0 | connection-gui-release-fixed.log |
| 로스터 실제 GUI matrix | PASS1030/0, ScriptError0 | matrix-gui.log; tmp/skill_action_roster_matrix/matrix.json |
| 기존 manual 회귀(올바른 fixture 폴더) | PASS124/0 headless | manual-correct-isolation.log |
| AutomaticFrame | PASS56/0 | SkillActionAutomaticFrameTest.log |
| Lifecycle | PASS34/0, 의도적 실패 주입 진단 포함 | SkillActionLifecycleTest.log |
| Continuity(올바른 fixture 폴더) | PASS89/0, 의도적 실패 주입 포함 | continuity-correct-isolation.log |
| 최종 editor parse/import | PASS exit0 | editor-final.log |
| aab19e4 확인 후 새 개발 export | PASS exit0 | export-fixed-source.log |
| 새 실제 PCK 외부 smoke | PASS14/0 | packed-smoke.log; evidence/PackedSkillRuntimeSmoke.gd |
| 새 Windows EXE/격리 launcher180frame | PASS exit0 | development-manifest.json/boot record |
| 개인698+백업698/기존5산출물 | PASS 해시 불일치0 | evidence/skill-action-preservation-final.json |
| 실제 OS shortcut 더블클릭/자연 영입·왕관 획득/인간 재미 | NOT_RUN | 자동 컨트롤러 검증과 구분 |
| 실제 Steam 설치·업데이트·두PC Cloud·현재 Steamworks 재열람 | NOT_RUN | 로컬 효과 검증으로 대체하지 않음 |

전용 테스트에는 실제 HP피격/수리, 무효 준비, 오프/한번/항상, x3·메뉴 복귀, 보호만/실제 당김, 유효 보행 끝점, 독립6초 왕관/기존 합동기 잔여4초 및25%복구, 피해100에서 동료46/푸딩25, 순환 종료가 포함된다. 자연 전체 AI 조건이나 인간 입력을 전부 검증한 것은 아니다.

중간 실패 로그는 삭제하지 않았다. 방향/문자열 타입 파싱, 누락 로스터·최대HP fixture, 잘못된 테스트 저장 폴더, 이전 보호막0 assertion을 고친 뒤 새 최종 로그를 채택했다. 최초 export는 commit 대기 중 중단했고 export.log는 최종 근거가 아니다. 제품 SHA 확인 후 export-fixed-source.log로 다시 완료했다. 실패 로그를 PASS로 재표기하지 않았다.

| 회차 | 검수 작업 | 범위 | 결과 SHA | 결과 |
|---:|---|---|---|---|
| 1 | /root/skill_action_review | c1e81dcccd9c4b8df330d08e7ea81a82c4029203..aab19e40edc77b5b9baa52e47cdd360232e578a4 | aab19e40edc77b5b9baa52e47cdd360232e578a4 | TARGETED_PASS |

기존 합동기 수명 연장/당김 요청 AI덮어쓰기 P2와 caption P3 수정 후 검수. 변경한 두 효과 범위의 확인된 잔여 P1/P2/P3는0. 전체 제품이나 남은 미지원의 완료 승인 아님. 검수 파일 evidence/runtime-connection/independent-review.md에는 소스 해시와 범위가 있다.

- Review task ID: /root/skill_action_review
- Reviewed SHA: aab19e40edc77b5b9baa52e47cdd360232e578a4
- Review range: c1e81dcccd9c4b8df330d08e7ea81a82c4029203..aab19e40edc77b5b9baa52e47cdd360232e578a4
- Remaining P1/P2: 0 (reviewed changed scope only)
- Final review result: TARGETED_PASS

## 7. 미완료와 위험

미지원8: stitch_stairway, night_relay, echo_alarm, royal_no_second_cut, tricolor_demonfire, royal_shared_umbrella, royal_emergency_plating, royal_urgent_courier. 기본3+왕관5. 왕관 젤 두 승급 계승 효과도 미지원. 왕관 패시브6 전부 연결됐다는 주장 없음.

실제 floor_id/층 이동·왕관 목표 피해/봉인함HP·은신·드러내기·상호작용 지연·상태 저항이 런타임에 없거나, 모리 재생량/치명타 생존 규칙/핀 저주 기본강도·시간·모드UI/고블린 순차 피해·인접범위·왕관표식 수치가 부족하다. 서비스의 정적 AB값은 실제 효과 계측으로 사용하지 않았다. 설계/전투 기반 범위를 정한 뒤 별도 확장해야 한다.

새 게임에 실키나 왕관 푸딩이 즉시 나오는 것이 아니다. 자연 영입의 DAY/event는 이번에 검증하지 않았고 왕관은 기존 DAY23 평의회/자격·자원 조건을 거친다. 새 효과 검증은 명시적 synthetic fixture다. 당김/시설 대상 구현 판단과 왕관 기본만 연결한 한계를 인간 플레이에서 확인해야 한다.

기존6618 첫 방어 리뷰는 [별도 문서](FIRST_DEFENSE_REVIEW_2026-10-12.md). DAY2 TUT110 자동 입력 반복 정지 원인/사람 재현은 미확정이며 제품 스킬 검수0P1/P2로 이를 숨기지 않는다. 개인 저장 파괴적 테스트/공개 Steam/원격 Git 변경 없음.

## 8. 다음 승인 작업

[사용자 원문을 보존한 성장 개선 계획](GROWTH_APPEAL_NEXT_PLAN_2026-10-12.md): 기존 푸딩 두 승급 행동→실제 지원 기여→다음 회차 기존 조합/엔딩 선택. 대표1몬스터+1합동기로 baseline 후 최소 구현. 이번 턴에서는 성장 코드 개발을 시작하지 않았다. 나머지8스킬의 설계 없는 값을 성장 작업에 끼워 넣지 않는다.

## 9. 복구·전달

최종 제품aab19e4에서 빌드 고정. docs/handoff만 후속 commit. task-2/evidence/runtime-connection/development-build에 새 EXE/PCK/격리 LaunchPrototype.ps1/manifest/캡처와 보고서. 새 Desktop 마왕성_스킬연결_검토_aab19e4는 이 패키지에만 연결한다. 이전 데스크톱 폴더·shortcut·실행 빌드 그대로. 런처 사용 시 저장은 패키지 prototype_userdata 아래이며 EXE 단독 실행은 피한다. 허브 기존 session cutscene-policy-decision-20261012에 동일 trial 체크포인트로 기록, 중앙 기준/evidence ID PASS승격은 부모 담당. 시간·토큰·효율 측정은 null/NOT_MEASURED.

## 10. 종료 체크

- [x] 승인된 근거 있는 두 효과·컷신 및 부분 지원 안내
- [x] 변경 범위 테스트·검수·새 PCK/EXE·세이브 보존
- [x] 중간 실패와 미지원/NOT_RUN 분리
- [x] CURRENT와 성장 승인 원문·첫 방어 근거 보존
- [ ] 미지원8·왕관 계승·자연 전 캠페인·사람 입력/재미
- [ ] Steam 실제 설치/두PC Cloud/공개 배포 (이 작업에서 진행 안 함)
