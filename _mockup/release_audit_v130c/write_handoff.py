"""After the evidence commit, write handoff documents only."""
import json
import sys
from run_audit import ROOT, OUT

reviewed=sys.argv[1]
baseline=json.loads((OUT/'baseline_git.json').read_text(encoding='utf-8'))['head']
campaigns=json.loads((OUT/'campaign_summary.json').read_text(encoding='utf-8'))
native=json.loads((OUT/'computer_use.json').read_text(encoding='utf-8'))
logs=json.loads((OUT/'log_summary.json').read_text(encoding='utf-8'))
name='V130R_RELEASE_AUDIT_0121C_2026-10-19.md'
body=f'''# V130R 0121c 최종 출시 표적 재점검

## 1. 메타데이터

- 작성일/목표: 2026-10-19 KST / 1.3.0
- 브랜치: `codex/v130r-defense-layout`
- 기준·검수 제품 SHA: `{baseline}`
- 마지막 검수 증거 커밋 SHA: `{reviewed}`. 이후 인계/CURRENT 문서만 커밋하며 최종 tip은 Git 로그/최종 응답 참조.
- 원격 푸시/PR/태그/Steam/main: 모두 없음. 로컬 main 없음·캐시 origin/main 최신성 미확인.

## 2. 목표와 완료 조건

0121 수정 후 영향받은 항목만 점검했다. 기존 `_mockup/release_audit_v130b/` 근거를 재사용하고 제품 수정·밸런스 변경·원본 사용자 세이브 접근·전체 회귀는 제외했다.

## 3. 완료한 작업

- 새 연속 캠페인 시드130401~130403: 각 29전투 승리, DAY29 무전투 준비, DAY30 엔딩·후기 실제 디스크 저장·별도 프로세스 복원. 각819+14검사, 실패0.
- 구 v1~v6 사본42검사, en/zh 설정·알림108검사, 0121b 대사 넘침/원문 보존·입력 검사, 새 Windows export 및 실제 EXE Computer Use 흐름을 확인했다.
- 스토리73,027·몬스터2,408·지도 번역164키/우선144항목/고유명24종, 검증기 자체13테스트 통과. 로그 오류{logs['total_errors']} / 경고{logs['total_warnings']}.
- 코드/데이터/스토리/밸런스/게임 자산 변경0. 감사 스크립트와 결과만 새 폴더에 추가했다.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| `_mockup/release_audit_v130c/RELEASE_AUDIT.md` | B01~B05·G01/G02·N01~N03·V01/V02 및 최종 판정 | 완료 |
| `_mockup/release_audit_v130c/*.py`, 선택한 요약 JSON/CSV | 재현·검증 근거 | 완료 |
| `docs/handoff/{name}` | 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 지정 브랜치 진입 링크 | 완료 |

## 5. 그래픽 및 오디오

신규/수정 자산·생성 이미지0. 직접 이미지 {native['direct_images_total']}장, 모두960px 이하 사본. 원시 캡처는 모델에 전달하지 않았고 캡처/EXE/PCK/DLL/원시 로그를 소스 커밋에 넣지 않았다.

## 6. 테스트 및 검수

명령·실제 종료·횟수·한계는 [출시 감사](../../_mockup/release_audit_v130c/RELEASE_AUDIT.md)와 `runs/*.json`, `logs/`, `computer_use.json`에 있다. `python -X utf8 _mockup/release_audit_v130c/run_audit.py`의 prepare/campaigns/static/suite/export/launch를 사용했다. 전체 회귀·전체 EXE 수동30일·전체 검수 에이전트는 NOT_REQUESTED/미실행. 읽기 전용 보조 조사1명은 기존 근거와 변경 범위만 대조했다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: {reviewed}
- Review range: {baseline}..{reviewed}
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

검수 제품은 기준 SHA와 동일하다. Reviewed SHA는 그 제품의 점검 도구/증거 커밋이며, 이후 제품·데이터·자산·검사 도구 변경 없음.

## 7. 미해결 항목과 위험

**최종 출시 판정: 조건부 · 사용자 확인 대기.** 기능상 N01/G01 후기 저장 실패는3/3 해소했으나 실제1.2.12/Steam1.3.0 출시 세이브의 출처 증빙은 미확보다. G02 게시/실계정 검증은 사용자 작업이다.

비차단/권장 유지: 기존 DAY15~28 승률100% 곡선, DAY5/15/27 집중 HP우위3.73/0.36/1.16%p, 명령12쌍24전투 중2쌍 손해(HP−26/생존−1, HP−234). 과거 비교를 현재10회 재측정으로 바꾸지 않았다. 기존 성능과 명세/취향/전수 미검수 제한은 감사 보고서를 따른다.

## 8. 다음 작업 순서

1. 사용자: 최종 보고서와 비차단 편차·출시 세이브 출처 제한 확인.
2. 사용자: App5267750 업적100개 업로드 확인→게시→실계정 업적1개 정상 해제 테스트 및 증빙. 상세 단계는 보고서 말미.
3. 승인 없는 공개 배포·태그·Steam·main 작업은 진행하지 않는다.

## 9. 작업 트리 상태

기존 추적 import1,307개 및 기존 미추적 산출물을 보존했다. 원본 사용자 저장 접근/수정0, 기존 테스트 사본 해시 보존, 새 APPDATA/LOCALAPPDATA만 사용했다. Godot 직렬1개 이하·종료0개. 새 실행은 `_mockup/release_audit_v130c/`, 프로필/빌드는 `tmp/release_audit_v130c_v130r_release_blockers/`에 있다. 의도한 감사 텍스트만 명시적으로 스테이징했고 영어 로컬 커밋만 생성했다.

## 10. 종료 체크리스트

- [x] 요청된 표적 재실행 및 실제 EXE 조작
- [x] B01~B05/G01/G02/N01~N03/V01/V02 해소 표와 최종 조건부 판정
- [x] 잔여 수치 근거·실행/미실행 범위·로그 범주 기록
- [x] 제품/원본 저장 보존, 이미지 제한, Godot0
- [x] CURRENT 갱신·로컬 영어 커밋만·사용자 확인 대기
'''
(ROOT/'docs/handoff'/name).write_text(body,encoding='utf-8')
current=ROOT/'docs/handoff/CURRENT.md'
old=current.read_bytes().decode('utf-8-sig')
prefix=f'''## 2026-10-19 V130R 0121c 최종 출시 표적 재점검 / TARGETED_PASS · 조건부

[{name.replace('.md','')}]({name}), [최종 감사·해소 표](../../_mockup/release_audit_v130c/RELEASE_AUDIT.md). 제품 기준 `{baseline}`, 검수 증거 `{reviewed}`. 시드130401~130403 각29승·DAY29 무전투·DAY30 후기 저장/별도 재시작 복원819+14검사, 구v1~v6 42검사, en/zh 설정·알림108검사, 0121b·데이터 무결성·새 Windows export/실제 EXE 흐름 통과. 오류{logs['total_errors']}/경고{logs['total_warnings']}.

제품/밸런스/원본 사용자 저장 변경0. 기존 근거 재사용, 이미지{native['direct_images_total']}/12장·모두960px 이하 사본, Godot직렬1/종료0. 로컬 영어 커밋만, push/fetch/태그/Steam/main0. 로컬 main 부재/원격 최신성 미확인 유지. 전체 회귀·전체 EXE 수동30일·별도 전체 검수 에이전트 미요청/미실행.

**최종 출시 판정: 조건부. 사용자 확인 대기.** B04 곡선·집중 배치·명령 손해는 비차단/권장으로 유지. 실제 출시 세이브 출처 미확보와 G02 사용자 단계(App5267750 업적100개 업로드 확인→게시→실계정1개 해제)는 별도다. 공개 출시 권한을 부여하지 않는다.

---

'''
current.write_bytes(prefix.encode('utf-8')+old.encode('utf-8'))
print('Handoff and CURRENT updated; product unchanged.')
