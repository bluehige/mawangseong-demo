# CURRENT 권위·역사 분리 교정

## 목적

정식 출시본 `v1.2.5` 대신 과거 v20 실험 브랜치가 현재 제품처럼 전달된 원인을 제거하고, 긴 CURRENT를 활성 정보와 역사 기록으로 분리한다.

## 기준

- 직접 사용자 지시: 2026-08-13 현재 Codex 작업에서 CURRENT 분할·순차 백업·오정보 및 원인 교정 요청
- 출시 기준: `v1.2.5@f757ffa9f9e962158f2123856c8568a3163ecb6c`
- 정리 시작 기준 main: `ce601b81b8f283543a04867e11632d0e87beea3c`
- 오인된 역사 작업트리: `codex/v20-p11-intuitive-board@43cd6ce0cdd10977faa818c13eb38bd7e7a54bfa`

## 확인된 원인

1. 컨테이너 루트 `AGENTS.md`와 `README_폴더안내.md`가 `게임소스/`를 기본 구현 진입점으로 고정했다.
2. 실제 `게임소스/`는 main이 아니라 과거 v20 작업트리였고, 브랜치 로컬 CURRENT와 AGENTS는 작성 당시 자신을 현재 지시로 표시했다.
3. 기존 main CURRENT는 807줄 안에 v1.2.5 출시 완료와 과거 v1.2.4 HOLD, v1.2.2 다음 작업, v20 기록을 함께 두어 검색 결과가 서로 충돌했다.
4. 폴더명과 로컬 CURRENT를 먼저 믿고 branch·HEAD·main·origin/main을 확인하지 않은 탓에 v20 조사 결과가 1.2.5 제품 사실처럼 전달됐다.

## 교정

- 현재 정책 권위를 `main:AGENTS.md`, 제품 상태 권위를 `main:docs/handoff/CURRENT.md`의 쌍으로 고정했다.
- preflight를 `repo root / branch / HEAD / main / origin/main / v1.2.5 tag / dirty 상태` 대조로 확장했다.
- 새 CURRENT에는 v1.2.5 기준선, 활성 품질 검수, 직접 사용자 결정, 범위와 다음 진입점만 남겼다.
- 제품 피드백·사용자 확정 의도는 `V125_PRODUCT_QUALITY_AUDIT_BRIEF_2026-08-13.md`로 분리했다.
- 과거 진행은 `archive/current/README.md`에서 버전·날짜 순으로 찾도록 만들었다.
- 원문은 내용과 SHA-256을 보존하되 현재 Markdown 지시 검색에 섞이지 않도록 `HISTORICAL_ONLY_*.snapshot.txt`로 격리했다.
- 과거 v20 작업트리의 AGENTS와 CURRENT는 현재 제품 작업을 막는 역사 안내판으로 축소했다.
- 현재 지시 검색에서 archive·tmp·output·builds·web_Demo와 다른 worktree를 제외하도록 명시했다.

## 원문 보존 증거

| 출처 | 보존 파일 | 행 수 | SHA-256 |
|---|---|---:|---|
| main 분할 전 CURRENT | `docs/handoff/archive/current/HISTORICAL_ONLY_CURRENT_2026-08-10_PRE_SPLIT.snapshot.txt` | 807 | `3AC54A53190A756DF354EE41D93BD44DB17D17456166F48A893BEE7042180564` |
| v20 Phase 11 분할 전 CURRENT | 과거 작업트리의 `docs/handoff/archive/current/HISTORICAL_ONLY_CURRENT_V20_P11_2026-07-21.snapshot.txt` | 226 | `2FB3454B74B58F4330BC8AD63A53E7003B806F4C6AB930428237887485EDC8FD` |

## 범위와 전달 상태

- 제품 코드·데이터·자산·빌드·배포는 변경하지 않았다.
- 기존 사용자 UID와 `참고자료/v20_p11r/`는 보존했다.
- 작성 시점의 변경은 두 worktree의 작업복사본에만 있으며 커밋·푸시·PR은 수행하지 않았다. 따라서 병합 전 `git show main:...`은 기존 커밋 내용을 보여 준다.
- 저장소 권위로 확정하려면 main 안전문서·CURRENT·brief·archive를 한 변경으로 검토·커밋·병합하고, 이후 `git show main:AGENTS.md`와 `git show main:docs/handoff/CURRENT.md`를 다시 확인해야 한다.
