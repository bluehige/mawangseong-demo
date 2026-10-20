# 0112 항목8·9 현재 코드 대조

대상 `e40eb91c4902e72237783508105004be7e4d989e`. 읽기 전용 보조 검토 `01a15039-506b-7362-9db9-dec2b09d8a4f`. 이 문서는 정적 대조이며 이번 실행 결과는 RELEASE_AUDIT.md·run_index.json을 따른다. 과거 시험을 이번 실행으로 합산하지 않는다.

| 항목 | 현재 대조 |
|---|---|
| B02 | `scripts/game/ApprovedBattleController.gd:127`에서 공통 성장 계산 사용. 원래 능력치 우회는 해소 경로가 존재한다. |
| B03 | 공통 웨이브·날짜 처리, 원정/기록실 진입, 다음 회차 초기화 연결. `docs/handoff/V130R_FIX_B02_B03_2026-10-18.md:102`. 서비스 단독 검사와 자연 플레이 증빙을 구분한다. |
| B04 | 최신 0119 인계에도 DAY15~28 승률 곡선, DAY15~16 HP 과다·25~26 부족, DAY5·15·27 추천 HP 열세가 남는다. `docs/handoff/V130R_REBALANCE_2026-10-18.md:183`. 과거 DAY30 승률40%는 현재 수치로 재사용하지 않는다. |
| 명령 효과 | 수명·저장 누수는 수정됐으나 비교 DAY15 HP−26/생존−1, DAY30 HP−234 및 명령 미사용1쌍. `docs/handoff/V130R_FIX_COMMANDS_2026-10-18.md:125`. 이번 3회 기본 수비 캠페인은 명령 비교 검사가 아니다. |
| 로로 원정 위험−1 | 표시·기록만 존재. 원정은 비용 후 즉시 보상하며 위험에 따른 실패/피해 규칙이 없다. `scripts/game/GameRoot.gd:10642`. 규칙 수용 또는 별도 명세 판단 필요. |
| E 건설 | `data/castle_evolution_stages.json:32` 상한7과 기본도면8 불일치. `scripts/map_builder/ApprovedPlacement.gd:345`에서 고정시설도 총수에 포함. |
| Steam 응답 누락 | `AchievementService.gd:64`의15초 후 inflight 해제와 달리 `SteamAchievementBridge.gd:81` pending이 남아 같은 실행 재전송을 막을 수 있다. 실제 Steam 접속은 금지 범위라 하지 않는다. |
| 의회 확장 자격 | `scripts/game/GameRoot.gd:6293` 임시 안전 시설·eligible=false. 독립 확장 부지 방어와 관련 업적/엔딩을 해소로 기록하지 않는다. |
| DAY29 | `data/waves.json:1867` 빈 웨이브, `ApprovedPlacementView.gd:801` 준비 결산 경로. 이번 캠페인에서 별도 확인한다. |
| G01 출처 | 기존 사본의 제작 출시본 미상. 실제1.2.12/Steam1.3.0 출처 증빙을 새 테스트 저장으로 대체하지 않는다. |
| 그래픽·취향 | 혼잡 이름표·누비 바늘을 포함한 포즈, 원어민 톤·음원 청취는 별도 미확인. 임시 가격·환불·범위·식량·이전 규칙/자산 대체는 확정 결함과 명세·취향 확인 사항을 구분한다. |
| 기타 기능 | 전문화 일부 조합 약화, 자연 기억·합동기 해금/모든 조합, 원정·칙령·굶주림 누적 경제의 전수 보장은 이번3회만으로 할 수 없다. |
| G02 | `data/v130r/achievements/README.md:3` 실제 Steamworks 세트ID·게시·실계정 해제 미확인. `tools/release/PrepareSteamBuild.ps1:89` 필수 목록은 EXE/PCK라 DLL 패키지 확인은 이번 export 산출물로 별도 수행한다. |

사용자 확인 대기.
