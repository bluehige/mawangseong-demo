# 3차 업데이트 데이터 계약

Phase 1에서는 모든 카탈로그를 빈 `{}`로 시작했다. Phase 3부터 `fronts`, `front_day_overlays`, `rival_finales`에 선택 화면용 기본 전선 3종을 추가했다. 셀렌·로만 전투는 `placeholder` 상태며 런타임 웨이브에 아직 적용하지 않는다.

필수 계약은 `tools/content/ValidateUpdate3Content.gd`가 검사한다.

- front: 최종 라이벌·DAY 30 적·overlay·DAY 28 선택 그룹
- front overlay: 소유 front와 DAY 30 boss 연결
- heart: 패시브·대가·충전원·액티브 스킬·Stage별 심장방 HP
- duo link: 정확히 두 개체, 해금 조건, 게이지 원천, 효과 handler
- monster/enemy extension: 캐릭터·스킬·행동 handler 참조
- rival finale: front·적·캐릭터 참조와 정확히 3단계
- ending: E12~E16 코드, front·metric·리소스 참조
- chronicle: 목표 종류·대상·임계값·보상 목록

후속 Phase는 이 파일들에만 실제 항목을 추가하며 같은 내용을 루트 데이터에 중복 저장하지 않는다.
