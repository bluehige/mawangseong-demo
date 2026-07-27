# v1.2.2 P16 구현 폐쇄·금지 상태 0

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-implementation-closure`
- 기준 브랜치 및 SHA: `codex/v122-content-compatibility@60ecd54ea2f3c392c1d091b58df2d63553f783c2`
- 기능 커밋 SHA: `317eba73052719e1a3eece62c262aa86d2bcfc7c`
- 원격 푸시: 미실행

## 2. 완료한 작업

- P0~P15 제품 기능을 15개 기능군으로 묶고 각 행에 요구 문서, 데이터, runtime consumer, UI 진입점, 입력 handler, 저장, 전투·결과 반영, 자동 테스트, 실제 실행 증거를 기록했다.
- 허용 상태를 `IMPLEMENTED`, `INTENTIONALLY_HIDDEN`, `REMOVED`로 제한하고 11개 금지 상태를 자동 검사한다.
- Update 4 지역 일반 적 6종의 `placeholder_art=true`를 제거하고 GPT 내장 이미지 생성으로 1254×1254, 4×4, 16프레임 전투 sheet를 제작했다. 제품 enemy catalog, asset manifest, source 기록, 런타임 import를 모두 연결했다.
- 전초기지 `placeholder_wave`와 `run_placeholder_trial`을 `day10_wave`와 `run_trial`로 교체하고 제품 소비자와 회귀를 함께 갱신했다.
- 온보딩의 `정규판 TODO`와 전투 fallback의 `다음 장 준비 중` 노출 문구를 실제 제품 설명으로 교체했다.
- 일반 문자열 `placeholder`·`pending`·`임시`가 정상 엔진 속성이나 실행 상태를 의미하는 경우를 기계 판독 예외로 분리해, 출시 누락과 정상 상태를 혼동하지 않게 했다.

## 3. 테스트

| 방법 | 결과 |
|---|---|
| `V122ImplementationClosureTest` | PASS, 665 assertions |
| 기능군·증거 필드 | PASS, 15개 × 필수 9필드 |
| 금지 구현 상태 | PASS, 0건 |
| Update 4 지역 적 실자산 | PASS, 6/6·16프레임·manifest·source |
| 지역 적 Phase 14·16·17·18·19 직접 회귀 | PASS, 5/5·loader 오류 0 |
| 전초기지 Phase 8·9 직접 회귀 | PASS, 2/2 |
| Update 2~4 compatibility | PASS, 85/85·480 assertions |
| `RunCoreVerification.ps1 -Mode Quick` | PASS, 115/115 |
| JSON parse·경로·handler·`git diff --check` | PASS |
| Full·DAY 1~30 전체 플레이·최종 수동 검수 | NOT_RUN, 사용자 최종검수 단계로 보류 |

최초 전체 리임포트 뒤 Godot 4.5.2 Windows 편집기 종료 단계에서 기존 접근 위반이 한 번 재현됐다. import는 완료됐고 지역 적 runtime texture loader 오류가 0임을 분리 확인했다. 첫 Quick은 import 항목만 실패하고 나머지 114개가 통과했으며, 안정화된 캐시에서 동일 Quick을 다시 실행해 프로젝트 import를 포함한 115/115 PASS를 확정했다.

## 4. 생성 그래픽

- 생성 방식: GPT built-in image generation
- 공통 프롬프트와 적별 차이: `assets/source/imagegen/update4_region_enemies/SOURCE.md`
- source 원본: `assets/source/imagegen/update4_region_enemies/*.png`
- runtime sheet: `assets/sprites/enemies/update4/region/*.png`
- 후처리: 없음. 기존 4×4 fractional region reader와 chroma shader를 사용한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 317eba73052719e1a3eece62c262aa86d2bcfc7c
- Review range: 60ecd54ea2f3c392c1d091b58df2d63553f783c2..317eba73052719e1a3eece62c262aa86d2bcfc7c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 5. 다음 작업

1. P17에서 프로젝트 버전, export preset, 플랫폼 설정과 RC 식별자를 1.2.2 기준으로 정적 정합화한다.
2. P17 자동 검증과 저장 호환 회귀를 통과한 뒤 사용자가 직접 실행할 최종검수 체크리스트를 제공한다.
3. 실제 export·배포·태그·Release와 최종 수동 플레이는 사용자의 별도 승인 전까지 실행하지 않는다.
