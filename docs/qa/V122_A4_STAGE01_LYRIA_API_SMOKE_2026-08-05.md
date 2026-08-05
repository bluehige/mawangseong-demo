# v1.2.2 A4 Stage 01 Lyria API smoke 검증

검수일: 2026-08-05
대상 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
패킷: `A4-STAGE-01-LYRIA-API-SMOKE`

## 목적

사용자가 로그인한 Chrome의 Google AI Studio 유료 계정에서 API 키를 복사하고, 키를 파일에 저장하지 않은 채 기존 Lyria 파이프라인으로 실제 음원 후보 1개를 생성할 수 있는지 확인했다. 현재 v1.2.2 manifest에는 Stage 01 환경 loop 항목이 없으므로, 비용과 범위를 최소화하기 위해 기존 `management_castle_bustle` 항목으로 API·모델·다운로드·미리듣기 변환 경로만 검증했다. 이 후보는 Stage 01 환경음이나 제품 runtime 교체본이 아니다.

## 직접 실행 결과

1. `tools/audio/setup_lyria.ps1`
   - 전용 경로 `tmp/lyria_audio_venv/`에 `google-genai 2.11.0`, `miniaudio 1.71` 설치
   - manifest 검증: `assets=76`, PASS
2. `doctor`
   - Python 3.11.9, `google.genai=OK`, `miniaudio=OK`, manifest PASS, 프로세스 내 `GEMINI_API_KEY=SET`
3. `generate` 사전 점검
   - 대상 1개, take 1개, `lyria-3-pro-preview` 요청 1회 계획
   - 예상 비용: `$0.08`
   - 사전 점검 단계에서는 네트워크 요청 없음
4. `generate --execute`
   - 실제 유료 요청 1회, PASS
   - API: `v1beta/interactions`
   - `store=false`
   - 생성 시각: `2026-08-05T00:03:26Z`

첫 실행은 1.5초 실행 제한으로 `doctor` 뒤 종료됐으며 유료 요청이 발생하지 않았다. 실행 제한을 조정한 두 번째 실행에서만 실제 유료 요청 1회가 발생했다. 실패 시 자동 재호출은 하지 않았다.

## 후보 파일 검증

후보 디렉터리:

`tmp/lyria_audio_v122/20260805_stage01_api_smoke/management_castle_bustle/take-01/`

| 파일 | 크기 | SHA-256 | 결과 |
|---|---:|---|---|
| `source.mp3` | 2,738,275 bytes | `135B7956860E3A158070ADCEE7675FBEFEE126D9C36DCA602479E573B9073B00` | PASS |
| `preview.wav` | 19,728,908 bytes | `0EF02B619E390F1AD05DB92D3595570B2549F9B427B53DCB4FE4DADC503BE3FE` | PASS |

`preview.wav`는 2채널, 44.1kHz, 16bit, 111.842초로 열렸으며 파형 메타데이터를 정상 판독했다. 후보 디렉터리 전체에서 Google API 키 형식(`AIza...`) 문자열은 0건이었다.

## 보안 및 범위 경계

- API 키 값은 화면·로그·저장소 문서에 출력하지 않았다.
- 키는 생성 프로세스의 환경 변수로만 전달했고 프로세스 종료 뒤 제거했다.
- 생성 직후 Windows 클립보드는 일반 문구로 덮어썼다.
- `promote --confirm`은 실행하지 않았다.
- 제품 runtime WAV, manifest, event catalog, 라우팅 코드는 변경하지 않았다.
- 후보는 Git에서 무시되는 `tmp/` 아래에만 있다.
- 사람 청취, loop 이음새, 게임 내 음량·믹스 검수는 아직 하지 않았다.

## 판정

`A4_STAGE01_LYRIA_API_SMOKE_PASS`

Lyria 3 Pro API 생성 경로는 정상 작동한다. 다음 패킷은 실제 Stage 01 환경 loop의 manifest·파이프라인 계약을 먼저 만들고, 그 다음 패킷에서 Stage 01용 후보 한 개만 별도로 생성해야 한다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Review range: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
