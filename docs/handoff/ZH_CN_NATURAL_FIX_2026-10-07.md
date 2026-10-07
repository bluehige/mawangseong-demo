# 간체 정상 플레이 P2 수정 로컬 후보 — 2026-10-07

## 1. 메타데이터

- 작성자: Codex, 현재 원본 작업트리의 유일한 구현 writer
- WORKSTREAM_ID: ZH_CN_NATURAL_P2_FIX_20261007
- 목표 버전: 승인1.2.9 기반 미공개 간체 후보; 새SemVer 미지정
- 작업 브랜치: `codex/v129-build-approval-status`
- 기준 브랜치 및 SHA / 마지막 커밋 SHA: `b06be967aa763199ac631729eb65cacbe9489c26`
- 승인 태그 / 제품 SHA: `v1.2.9` / `4076e099202f440c85a30699268d1c887c26c903`
- 원격 푸시: 없음. 로컬main/origin/main 일치; 새원격 조회 없이 같은 날 부모 감사의 최신성 증거 사용.
- 관련 PR/태그: 새로 만들지 않음; 승인태그·배포파일 유지.

## 2. 이번 세션 목표

- 사용자 ‘검증한 것들 수정’ 승인: [구 정상30일 플레이](ZH_CN_FULL_PLAY_2026-10-07.md)의 동적 전술·시설/보물·확장 복도 한국어 잔여와 닫기/확대 겹침4유형 보완.
- 완료 조건: 최소 표시 변경, 정상 저장의 실제 전후·두해상도 닫기 입력·한영 회귀·엔딩 저장재진입·후보EXE 실행 확인, 별도 새후보 및 보존 해시.
- 범위 밖: 규칙/밸런스/보상/저장 의미 변경, 새전체30일·전체회귀·검수에이전트, 공개Steam/Git작업, 새버전·원어민·SC자형·홍보 승인.

## 3. 완료한 작업

- 전술 요약의 이름/레벨/나머지 인원과 경로 적 이름을 먼저 번역한 뒤 합쳤다. 같은 조합 결함인 지침 적용/기본복귀 피드백도 보완했다.
- 시설 효과·범위를 먼저 번역; 가변 보물 경고와 시설 꼬리 템플릿 추가. 효과 값과 내부ID 유지.
- 정문/측문/연결의 생성 복도4형태 번역 템플릿 추가. 실제DAY17 전투/결과에서 `侧门汇合走廊`, `侧门内侧走廊 → 通道` 확인.
- 관리 패널이 열리면 겹치는 지도 도구 묶음을 숨기고 닫으면 복원. 실제720p·1080p 닫기 중앙 클릭으로 배율 유지·패널닫힘·정상확대 확인.
- 신규 간체 supplemental9키; 기존5344 UI 번역과 스토리 유지. 검사·fixture 추가. 이번 변경은 구동결 후보 대비10경로이며 전체현지화overlay는46파일.

## 4. 변경 파일

| 경로 | 변경 | 상태 |
|---|---|---|
| `scripts/ui/DefensePreparationSummary.gd` | 조합 전 간체 이름/레벨·인원 | TARGETED_PASS |
| `scripts/ui/FacilityEffectText.gd` | 효과/범위 조합 전 번역 | TARGETED_PASS |
| `scripts/game/GameRoot.gd` | 경로 적 이름·지침 피드백 표시 | TARGETED_PASS |
| `scripts/ui/ManagementWorkspaceUI.gd` | 패널 열린 동안 지도 도구 숨김 | TARGETED_PASS |
| `data/localization/ui_zh_cn.json` | 수치·복도 가변9템플릿 | TARGETED_PASS |
| `tools/tests/ChineseCatalogTest.cjs` | 보조키 검사 보완 | PASS |
| `tools/tests/ChineseNaturalPresentationTest.gd/.gd.uid/.tscn` | 직접 표시·수치·한영 기준 검사 | PASS305 |
| `tools/tests/fixtures/chinese_natural_presentation_baseline.json` | 기존40요약·50효과 캡처 기대값 | PASS |
| `docs/handoff/ZH_CN_NATURAL_FIX_2026-10-07.md`, `CURRENT.md` | 종료/최신 후보 기록 | 완료 |

## 5. 그래픽 및 대용량 자산

- 이번 세션의 그래픽·폰트·스토리·밸런스 데이터 변경0. 새 생성/다운로드/설치/라이선스 수락/API키 사용 없음.
- 기존 내장OFL NotoSansCJKkr의1794glyph 기계 지원 검사는 통과. SC지역 자형·원어민·홍보 채택은 승인된 것으로 표시하지 않음.
- 승인1.2.9·구동결PCK·이전ZIP·구544캡처·원본 엔딩 저장 유지. 빌드/캡처는 ignored `tmp/`에만 있고 소스커밋에 추가하지 않음.

## 6. 테스트 및 검수

| 순서 | 내용 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 신규 표시 직접 검사 | PASS305: 레벨/인원·시설5종/배율5개·다른독립수치·복도·기존한영90출력 | `tmp/zh_cn_natural_fix_20261007/ChineseNaturalPresentationTest.log` |
| 2 | 간체/영문/스토리/튜토리얼 관련6종 | PASS1843/1794glyph,16,958,26,45 | 같은폴더 각test로그 |
| 3 | 카탈로그·export·PCK | PASS,3389엔트리/금지경로0 | `ChineseCatalogTest.log`, `windows_export.log`, `pack_verification.json` |
| 4 | 정상DAY1→17관리 저장 확보 | 16방어승리·패배/재시도0; 정상훈련·진화·DAY4/16원정 | `live_run/events.jsonl`, `checkpoints/` |
| 5 | 최종 후보 동일저장 전후 | 실제720p/1080p40캡처, 의미상태20쌍 일치, 닫기·숨김·복원·확대 | `runtime-verification.json` |
| 6 | 한영1080p 비교 | 10화면491항목 예정된지도도구숨김 외 표시/좌표 차이0 | 같은검증JSON |
| 7 | 최종PCK DAY17 정상전투 | 승리; 전투/결과 측문복도 간체; 결과자동저장5파일 보존 | `cases/zh_battle_720_new.json`, `checkpoints/D17_result_final/` |
| 8 | 기존정상DAY30 엔딩로드→후일담→엔딩→재부팅로드 | E02 철벽마왕요새; 자원/레벨/진화·왕좌2500/2500 등12의미필드 유지 | `cases/zh_ending_reload_1080_new.json` |
| 9 | 실제후보EXE 부팅2회 | exit0; 두Movie PNG는 실제1920×1080. EXE720p 검증으로 계산하지않음 | `exe_boot_720/`, `exe_boot_1080/` |
| 10 | 기존산출물 보존 | PASS40소스·구후보8·승인6·최초후보7·ZIP6·구544캡처·저장/설정6 | `preservation.json` |
| 11 | 새전체30일·전체회귀·별도검수에이전트 | NOT_REQUESTED / 미실행 | 새30일PASS로 표시하지않음 |

정상UI 검증은 공식Godot4.6.3+정확한PCK+외부 입력/관찰Node로 수행했다. 상태설정·날짜점프·강제승리·저장편집 없음. EXE자체의30일 입력자동화는 미실행. 오디오Dummy여서 청취 검증은 아니다. 대표수정문구의 실제줄바꿈·잘림·tofu를 확인했고 최종GDScript parse/runtime 오류 없음; 환경root-certificate-store 경고 유지.

새저장 확보에 사용한 중간PCK171803…도 보존했다. 지침피드백 보완 뒤 최종PCK를 재export하고 표적화면·전투·엔딩 확인을 했다. 마지막검사휴대성 보완은 PCK에서 제외된 `tools/tests`만 변경했고 관련6종을 재실행했다.

### 정책 CI용 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKING_COPY (46파일 SHA256 지문544160cf…)
- Review range: b06be967aa763199ac631729eb65cacbe9489c26..UNCOMMITTED_WORKING_COPY
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

이는 로컬 내용지문에 대한 간체표적 결과다. 전체제품P1/P2 전수0건·실제Git SHA 검수·PR CI·정식출시 승인으로 표시하지 않는다. 최종지문 이후 제품/검사 소스는 수정하지 않고 handoff와ignored 전달자료만 작성했다.

## 7. 미해결 항목과 위험

- 이번 간체4P2 유형은 FIXED_TARGETED_VERIFIED. 기존보고서의 OPEN은 구PCK 역사기록으로 남기고 이새후보 기록으로 대체한다.
- **기존영문 BASELINE-EN-01 미보완:** 구·신후보 DAY17 전술에 `탐험가·왕국 조사관`, `핀 Lv.7 외 1명` 동일하게 남음. 한영 회귀통과는 기존영문 잔여0건의 뜻이 아니다.
- 새후보의 전체30일/23엔딩/분기/난이도/NG+·전체회귀·실제Steam 설치/Cloud2PC·장기성능·청취 미실행. 원어민/SC지역자형/홍보·후보채택·새SemVer 별도.
- 반복정상전투는 흡수피해1/8처럼 난수·시점 지표가 달랐다. 같은 저장·규칙·코드데이터 보존과 별개이며 동일전투지표로 주장하지 않는다.

## 8. 다음 작업 순서

1. [실제 전후와 한계 보고서](../../tmp/zh_cn_natural_fix_20261007/REPORT.md), 새로컬후보를 검토하고 채택범위·미실행승인을 판단한다.
2. 기존영문조합잔여, 원어민/SC자형/홍보의 별도 작업범위를 정한다. 새폰트가 필요하면 정확한 대상·라이선스·다운로드 승인을 먼저 받는다.
3. 새버전/통합이 확정되면 허용된Git writer가46소스overlay+handoff만 명시적 적용·커밋하고 실제SHA의 관련검사를 남긴다. 공개push/Steam업로드/default/지원언어/출시/태그는 별도 명시승인 후에만 수행한다.

## 9. 작업 트리 상태 및 전달

- 현재원본cwd의 기존미커밋 현지화40소스를 보존하고 이번최종소스46파일로 추가보완했다. 기존local candidate/QA/full-play handoff도 유지.
- 새커밋·stage·push·PR·태그·권한변경0. Git 관리영역의 읽기제한을 우회하지 않았다. 작업branch는 기존ahead1 상태를 유지한다.
- 새후보: `tmp/zh_cn_natural_fix_20261007/windows_candidate_natural_fixed/`.
- 전달 ZIP: 같은 작업폴더의 `MawangCastle-zhCN-natural-fix-Windows-20261007.zip`, `MawangCastle-zhCN-natural-fix-source-review-final-20261007.zip`. 파일별 SHA256·바이트·ZIP 내부 일치 검증은 `delivery-manifest.json`, `archive-verification.json`에 기록한다. 최초 source-review ZIP도 보존한다.
- PCK SHA256: `b59cecd7d182979f7d37998d1c356bb03b243e9785dbd99eebeecf708057b184` /584254504bytes.
- 최종46소스 SHA256: `544160cfa00b7809111c58762fce643cbaf1ff72bbb700cef5c3204e2ff2d1ad`.
- 설명/명세/검사/캡처/정상저장/후보는 같은ignored작업폴더. 승인1.2.9 및 이전PCK/ZIP/개인저장을 덮어쓰지 않음.
- Steam/default/지원언어/출시버튼/공개Gitpush 실행0.

## 10. 종료 체크리스트

- [x] 승인된4간체P2 유형 구현·표적확인 완료
- [x] 관련자동검사·두해상도 실제입력·한영비교·저장/엔딩·EXE부팅 기록
- [x] 기존산출물·승인태그·저장보존 해시 기록
- [x] 새전체30일과미실행/원어민/SC자형/기존영문 위험 구분
- [x] handoff 및 CURRENT 업데이트
- [ ] 실제Git SHA의커밋/PR/필수CI·공개push — 요청/수행하지않음
- [ ] 후보채택·새버전·Steam공개 — 별도승인범위
