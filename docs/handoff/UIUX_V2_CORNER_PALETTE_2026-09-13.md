# UIUX V2 모서리 가림·벽/바닥 배색 수정 — 2026-09-13

## 1. 메타데이터

- WORKSTREAM_ID: UIUX-V2-CORNER-PALETTE-20260913
- 목표 버전: 공개 1.2.6 기반 미출시 UI/UX 작업. 새 제품 버전 지정 없음.
- 브랜치: codex/v126-uiux-u0-u3
- main / origin/main / 실제 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112 (종료 시 ls-remote 일치 확인)
- 세션 시작 SHA: 09dcd236ed7972e795e6dbfeb47c161e50aeb71f
- 마지막 구현 SHA: 753b41608f50d438d574999bb58ff1d8a2ddb85a
- 원격 푸시·PR·새 태그·배포: 없음
- 정책: 권위 main:AGENTS / main:CURRENT 확인. 오래된 1.2.5 표현보다 현재 제품 기준 1.2.6을 적용.

## 2. 목표와 완료 조건

사용자가 이전 석조 개선의 확대 화면에서 모서리 형태가 이상하고 벽·바닥의 회색이 비슷해 구분이 어렵다고 지적했다.
실제 모서리 결함을 재현해 고치고, 같은 화면에서 벽/바닥의 색과 밝기를 구분한다.
이전 PASS는 면적·연결 검증이며 사용자 지적이 없다는 뜻이 아니었다. 이번에는 빠졌던 벽끼리의 가림 검사를 추가한다.
경로·방 배치·비용·전투·성장·저장 시스템과 기존 시설/캐릭터 자산은 변경 범위가 아니다.

## 3. 완료 작업

- 원인: 낮은 벽의 전면 CanvasItem이 실제로 더 가까운 높은 벽까지 덮었다. 높은 벽에 낮은 윗면/띠가 끼어들어 모서리가 벽을 관통하는 모양으로 보였다.
- 각 면의 화면 위치와 지면 깊이를 비교하고, 높은 벽 뒤에 있는 낮은 면을 전면 렌더에서 잘라냈다.
- 볼록 조각으로 나눠 구멍 윤곽이 잘못 채워지는 문제와 미세한 잘못된 다각형을 방지했다. UV는 원래 면에서 보간하고 결과를 지도 갱신 때만 캐시한다.
- 다른 벽과 만나지 않는 자유 끝은 끝면을 넘어 반 두께만큼 튀어나오지 않게 마무리한다. 기존 공유 모서리와 실제 통행/건설 영역은 보존한다.
- 벽 윗면과 측면은 따뜻한 갈색 석재, 일반 바닥과 통로는 어두운 청보라색으로 구분했다.
- 기존 시설 자체의 색상, 새 미궁 동선, 적 목표, 샛문 비용/해금, 건설 검토/확정/취소/Undo 및 세이브 규칙은 유지한다.
- 기존 저장 지도의 벽 표현에는 적용하지 않는다.

## 4. 변경 파일

| 파일 | 변경 |
|---|---|
| scripts/dungeon_quarter/PreparedMazeMasonry.gd | 모서리 가림, 볼록 면 분할, 자유 끝, 따뜻한 벽색 |
| scripts/dungeon_quarter/QuarterDungeonRenderer.gd | 새 미궁 바닥·통로의 청보라 배색 |
| tools/UIUXMasonryTest.gd | 재현 가능한 벽 가림/돌출 회귀 및 최종 다각형 검증, 증거 경로 인자 |
| docs/design/UIUX_MAZE_MASONRY_2026-09-13.md | 후속 결함 원인과 변경 설명 |

## 5. 그래픽·오디오

- 신규 이미지 생성 및 로컬 래스터 후처리 없음.
- 기존 GPT 석재 재질·횃불·시설·바닥 자산을 재사용한다.
- 배색은 게임 실행 시 색상값으로 적용한다. 원본 PNG와 출처 문서는 변경하지 않았다.
- 기존 출처: assets/source/imagegen/prepared_maze_masonry_20260913/SOURCE.md
- 오디오 변경 없음.

## 6. 관련 검증

Godot 4.6.3 stable / Windows / RTX 3060 Ti. 네이티브 창을 순차 실행했고 검사별 임시 APPDATA를 사용했다.

| 직접 검사 | 결과 | 증거 |
|---|---|---|
| UIUXMasonryTest.tscn | PASS, 26,417 assertions / 고유 캡처 100장 | tmp/uiux_corner_palette_matrix.log, tmp/uiux_corner_palette_20260913/after/results.json |
| UIUXBuildPlacementTest.tscn | PASS, 344 checks / 캡처36장 | tmp/uiux_corner_palette_build.log, tmp/uiux_corner_palette_20260913/build/ |
| UIUXCombatInteractionTest.tscn | PASS, 210 assertions / 캡처24장 | tmp/uiux_corner_palette_combat.log, tmp/uiux_corner_palette_20260913/combat/results.json |
| 최종 로그 | ERROR / SCRIPT ERROR / FAIL 없음 | 위 3개 최종 stdout 로그 |
| 캡처·비교 링크 | 100장 중복/누락 없음, 실제 1920×1080 또는 1280×720, HTML 링크 누락 없음 | tmp/uiux_corner_palette_20260913/index.html |
| git diff --cached --check | PASS | 구현 커밋 직전 |
| 저장소 정책 | 아래 최종 기록 참조 | tmp/uiux_corner_palette_policy.log |
| 전체 캠페인·사람 사용성·다른 플랫폼·장시간 성능 | NOT_REQUESTED / NOT_RUN | PASS로 확대하지 않음 |

- 성 성장 4단계 × Windows 1920×1080 / 1280×720 × 글자90/100/115%, 실제 확대 버튼과 캐시 검사를 수행했다.
- 기존 미궁 검사의 저장 왕복, 몬스터 배치, 샛문 복구/Undo, 목표별 경로와 실제 전투 생성도 포함한다.
- 별도 회귀는 평행한 높은 벽과 낮은 벽으로 잘못된 전면 띠를 재현한다. 독립적으로 계산한 지점 (249.2,117.26)이 원본 낮은 면에는 있으나 최종 전면에서는 가려지는지 확인했다.
- 기존 접합 검사에 더해 모든 최종 조각의 삼각형 변환, UV 범위, 추가 중복 면적이 없는지도 확인했다.
- 숫자가 이전 26,643과 다른 이유는 자유 끝을 줄여 회귀 구성의 셀/면 수가 달라졌기 때문이다. 검사 수를 품질 점수로 비교하지 않는다.
- 대표 시각 확인: 사용자가 지적한 성 단계 확대, 최종 성장, 720p 글자115%, 실제 전투. 같은 장면의 전후8쌍 제공.
- 개발 중 일반 다각형 차집합의 미세 조각 오류가 나타나 볼록 분할로 수정했다. 중간 파일 끝 잘못된 문자로 인한 파서 오류도 수정했다. 최종 로그에는 해당 오류가 없다.
- 임시 미리보기 도구는 tmp/uiux_corner_palette_20260913/preview_source/에만 보존하며 소스 커밋에 넣지 않았다.
- 주 에이전트 단독 수행. 서브에이전트 사용 없음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 753b41608f50d438d574999bb58ff1d8a2ddb85a
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..753b41608f50d438d574999bb58ff1d8a2ddb85a
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 남은 관찰 범위

- 이번 재현 결함과 관련 검사에 남은 실패 없음.
- 석재 색은 현재 성장 단계 공통이다. 기존 시설 바닥·배경의 미술은 별도로 재제작하지 않았다.
- 사람의 색상 취향·전체 캠페인·Web/모바일·장시간 성능 검증 결과로 확대하지 않는다.

## 8. 다음 작업

1. tmp/uiux_corner_palette_20260913/index.html에서 사용자가 지적한 확대 장면의 전후를 확인한다.
2. 추가 시각 피드백이 있으면 실제 장면과 배율을 기준으로 보완한다.
3. 통합·테스트 빌드 게시·출시·태그는 해당 요청을 받았을 때 진행한다.

## 9. 작업 트리와 산출물

- 시작 시 깨끗한 09dcd23 작업트리. 기존 변경을 되돌리지 않았다.
- 구현 753b416은 로컬 커밋. 이후 핸드오프와 CURRENT만 기록한다.
- 캡처·로그·비교 페이지는 tmp/에만 보존하며 소스 커밋에서 제외한다.
- main·과거 v20 브랜치·기존 출시 태그·공개 URL·배포는 그대로 유지한다.

## 10. 종료 확인

- [x] 사용자 지적 장면의 원인 확인 및 수정
- [x] 새 회귀와 기존 관련 건설·전투 직접 검사
- [x] 실제 전후 캡처와 미수행 범위 기록
- [x] 최종 구현 SHA / CURRENT / 로컬 커밋 기록
- [x] 의도한 네 경로만 구현 커밋에 포함

## 최종 정책 결과

- REPOSITORY_POLICY: PASS (668 final files, 45 commits inspected).
- 검사 HEAD: 74c677def322882c5dcc927adeb74953afdf01a7.
- 로그: tmp/uiux_corner_palette_policy.log. 이후 이 결과와 CURRENT만 기록했다.
- 종료 작업트리 깨끗함. 로컬 커밋만 수행했고 원격 푸시 없음.
