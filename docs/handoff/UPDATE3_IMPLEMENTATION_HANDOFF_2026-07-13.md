# 3차 업데이트 구현 인계서

작성일: 2026-07-13

## 현재 상태

Phase 0 기준선 감사부터 Phase 30 출시 후보까지 모두 완료했다. 단계별 완료 기록은 `docs/design/UPDATE3_BASELINE_AUDIT.md`와 `docs/design/UPDATE3_PHASE1_...`부터 `UPDATE3_PHASE30_...` 문서에 있다.

## 핵심 위치

- 3차 데이터: `data/regular_version/update3/`
- 게임 통합: `scripts/game/GameRoot.gd`, `scripts/game/CombatSceneController.gd`
- 저장 v4: `scripts/systems/save/`
- 전선·심장·합동기·엔딩·연대기: `scripts/systems/`
- 선택·연대기 UI: `scenes/ui/screens/`
- 최종 그래픽: `assets/sprites/`, `assets/ui/`
- 생성 원본과 SOURCE 기록: `assets/source/imagegen/`
- 3차 오디오: `assets/audio/update3/`
- 자동 검사: `tools/tests/`

## 검증 명령

Godot 실행 파일 예시:

```powershell
$godot = 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64_console.exe'
```

전체 통합 검증:

```powershell
.\tools\tests\RunCoreVerification.ps1 -Mode Full -GodotPath $godot
```

특정 장시간 검사를 별도로 실행한 뒤 중복 제외할 때:

```powershell
.\tools\tests\RunCoreVerification.ps1 -Mode Full -GodotPath $godot -SkipCheckId balance_all
```

후반 캠페인 밸런스:

```powershell
& $godot --headless --path . --scene res://tools/BalanceSimulation.tscn -- --assert-late-campaign
```

Web 출시 후보:

```powershell
New-Item -ItemType Directory -Path output/phase30_rc -Force | Out-Null
& $godot --headless --path . --export-release Web output/phase30_rc/index.html
```

## 최종 근거

- 통합 보고서: `tmp/core_verification/latest.json`
- 통합 한글 보고서: `tmp/core_verification/latest.md`
- 밸런스 로그: `tmp/phase30_balance/`
- 29페이즈 화면: `tmp/update3_phase29/`
- 최종 Web 빌드: `output/phase30_rc/`
- 출시 노트: `docs/release/UPDATE3_RELEASE_NOTES_RC1_2026-07-13.md`

## 작업 트리 주의

- 이번 구현 전체가 아직 커밋되지 않은 누적 작업 트리에 있다. 사용자 요청 없이 스테이징·커밋·푸시는 하지 않았다.
- `git diff --check`는 통과했다.
- `assets/source`, `docs`, `tmp`, `output`, `tools`는 Web 배포 묶음에서 제외한다.
- 원본 생성 자료가 크므로 배포 크기와 저장소 관리 시 실행용 자원과 제작 원본을 구분한다.
