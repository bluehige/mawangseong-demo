# Release 빌드 매니페스트 규격

SemVer 태그(v0.N.P)의 Web Release ZIP 루트에는 build-manifest.json이 있어야 한다. 매니페스트는 태그, 빌드 커밋, 전체 검증 카탈로그, 실제 검증 보고서와 ZIP의 모든 런타임 파일을 하나의 계약으로 묶는다.

## 1. build-manifest.json

~~~json
{
  "schema_version": 1,
  "version": "0.4.0",
  "tag": "v0.4.0",
  "commit_sha": "0123456789abcdef0123456789abcdef01234567",
  "godot_version": "4.5.2-stable",
  "built_at_utc": "2026-07-14T03:20:00Z",
  "verification": {
    "suite": "Full",
    "expected_checks": 12,
    "passed": 12,
    "failed": 0,
    "catalog_path": "verification-catalog.json",
    "catalog_sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "report_path": "verification-report.json",
    "report_sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  },
  "artifacts": [
    {
      "path": "index.html",
      "bytes": 12345,
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    },
    {
      "path": "index.js",
      "bytes": 12345,
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    },
    {
      "path": "index.pck",
      "bytes": 12345,
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    },
    {
      "path": "index.wasm",
      "bytes": 12345,
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    },
    {
      "path": "verification-catalog.json",
      "bytes": 12345,
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    },
    {
      "path": "verification-report.json",
      "bytes": 12345,
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    }
  ]
}
~~~

artifacts에는 build-manifest.json 자신을 제외한 ZIP 내부의 모든 파일을 정확히 한 번씩 기록한다. Godot이 추가로 만든 AudioWorklet, 아이콘, 서비스 워커 같은 파일도 빠짐없이 포함한다. 목록에 없는 파일이 ZIP에 있거나 목록의 파일이 실제로 없으면 검증은 실패한다.

각 경로는 ZIP 루트 기준 상대 경로이며 상위 경로(..)를 포함할 수 없다. index.html, index.js, index.pck, index.wasm, verification-catalog.json과 verification-report.json은 필수다. 모든 bytes와 sha256 값은 최종 ZIP에 들어갈 실제 파일에서 계산한다.

## 2. 전체 검증 카탈로그

verification-catalog.json은 태그 커밋의 tools/tests/core_verification_suite.json을 바이트 단위로 그대로 복사한 파일이다. 배포 검증기는 태그에서 원본 카탈로그를 읽어 SHA-256을 비교한다. 별도로 줄인 카탈로그나 임의의 Smoke 목록은 정식 Release 근거로 인정하지 않는다.

expected_checks는 카탈로그에서 modes에 full이 포함된 고유 체크 ID 개수와 같아야 한다. suite는 Full, passed는 expected_checks와 같고 failed는 0이어야 한다.

## 3. 검증 보고서

verification-report.json은 해당 commit_sha에서 전체 검증 실행기가 만든 결과다.

~~~json
{
  "commit_sha": "0123456789abcdef0123456789abcdef01234567",
  "suite": "Full",
  "catalog_sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "expected_checks": 12,
  "passed": 12,
  "failed": 0,
  "checks": [
    {
      "id": "project_import",
      "result": "PASS"
    }
  ]
}
~~~

checks에는 카탈로그의 full 체크 ID를 누락과 중복 없이 정확히 한 번씩 기록하며 모든 result가 PASS여야 한다. 보고서의 커밋, 카탈로그 해시와 집계 값은 매니페스트와 일치해야 한다.

## 4. 생성 순서

1. release/v0.N에서 전체 검증을 실행하고 모든 필수 체크가 통과한 커밋을 main에 병합한다.
2. 검수된 main 병합 커밋에 주석 SemVer 태그를 만든다.
3. 해당 태그를 체크아웃한 깨끗한 환경에서 Web 빌드를 생성한다.
4. 태그의 tools/tests/core_verification_suite.json을 verification-catalog.json으로 복사한다.
5. 동일 SHA에서 생성된 전체 검증 결과를 verification-report.json으로 변환한다.
6. 매니페스트를 제외한 모든 ZIP 파일의 SHA-256과 바이트 크기를 계산해 build-manifest.json을 마지막에 생성한다.
7. 다음 명령으로 검증하고, 통과한 디렉터리 내용만 ZIP으로 묶는다.

~~~powershell
$commit = git rev-list -n 1 v0.4.0
git show v0.4.0:tools/tests/core_verification_suite.json > expected-catalog.json
python tools/ci/validate_build_manifest.py path/to/web/build-manifest.json --expected-tag v0.4.0 --expected-commit $commit --expected-catalog expected-catalog.json
~~~

8. 자산 이름을 mawangseong-v0.4.0-web.zip 형식으로 지정하고 같은 태그의 GitHub Release에 첨부한다.

## 5. 배포 규칙

- .github/workflows/deploy-web-demo.yml은 main에서 수동 실행된 경우에만 배포한다.
- 안정 SemVer 태그는 정해진 자산 이름, 태그 SHA, 태그의 정식 카탈로그, 보고서와 ZIP 전체 파일을 검증해야 한다.
- 기존 update3-web-20260713만 이전 배포 호환 예외다. 자산 이름과 기존 ZIP SHA-256을 모두 고정하며 다른 비 SemVer Release는 거부한다.
- 빌드 파일이 바뀌면 기존 매니페스트와 검증은 무효다. 같은 태그 자산을 교체하지 말고 수정 커밋과 새 패치 태그로 다시 출시한다.
- 빌드 ZIP, PCK, WASM과 실행 파일은 소스 브랜치에 커밋하지 않는다. GitHub Release 또는 단기 Actions artifact로 보관한다.
