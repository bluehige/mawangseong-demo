이 파일이 왜 필요한지: 정규버전 기능별 자동 검증을 한곳에 모으기 위한 기준을 둔다.

# Test Tools

새 테스트 씬과 테스트 보조 코드는 이 폴더에 추가한다.

기존 테스트는 호환성을 위해 당장 이동하지 않는다.

- `tools/DemoSmokeTest.tscn`
- `tools/QuarterModuleSmokeTest.tscn`
- `tools/BalanceSimulation.tscn`

새 시스템을 만들 때는 최소 하나의 headless 실행 검증을 같이 추가한다.

## 핵심 통합 검증

여러 핵심 검사를 한 번에 실행하고 `tmp/core_verification/latest.json`과 한글 `latest.md`로 결과를 모은다.

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\tests\RunCoreVerification.ps1 -Mode Quick
powershell -ExecutionPolicy Bypass -File .\tools\tests\RunCoreVerification.ps1 -Mode Full
```

- `Quick`: 프로젝트 불러오기, 핵심 스모크, 기존 DAY 1~3 자동 기록 무결성을 빠르게 확인한다.
- `Full`: 튜토리얼, 모든 밸런스 판정, 첫 플레이 집계, UI·전투 화면 캡처까지 실행한다.
- Godot을 자동으로 찾지 못하면 `-GodotPath "C:\path\to\Godot_console.exe"`를 함께 지정한다.
- 실행별 원본 로그는 `tmp/core_verification/runs/<시각>/`에 보존하며 기존 기록을 삭제하지 않는다.
- 유지보수용 `-Mode SelfTest`는 일부러 없는 생성 자료를 검사해 실패 코드 1과 `없음` 판정이 나오는지 확인한다. 정상 결과 보고서가 필요할 때는 이후 `Quick` 또는 `Full`을 다시 실행한다.
