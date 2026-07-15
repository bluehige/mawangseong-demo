# Lyria 3 Interactions API 오디오 교체 워크플로

작성일: 2026-07-15
대상 버전: v0.5

## 목적과 현재 범위

현재 게임이 사용하는 WAV 76개를 Lyria 3 후보로 다시 만들기 위한 로컬 파이프라인이다. 관리·일반 전투·보스 전투 BGM 3곡은 `lyria-3-pro-preview`, 짧은 전투·스킬·경고·모티프 소스 릴 73개는 `lyria-3-clip-preview`를 사용한다. 요청은 모두 Gemini Interactions API의 `interactions.create`로 전송한다.

- 공식 Lyria 3 음악 생성: <https://ai.google.dev/gemini-api/docs/music-generation>
- 공식 Interactions API 개요: <https://ai.google.dev/gemini-api/docs/interactions-overview>
- 공식 Gemini API 과금: <https://ai.google.dev/gemini-api/docs/pricing>
- 공식 Gemini API 결제 설정: <https://ai.google.dev/gemini-api/docs/billing>

`lyria-3-pro`는 현재 유효한 모델 ID가 아니다. 이 파이프라인은 공식 프리뷰 ID인 `lyria-3-pro-preview`를 사용한다.

## 안전 원칙

1. API 키는 파일, 명령 인자, Git, 생성 메타데이터에 저장하지 않는다.
2. `run_lyria.ps1`은 유료 실행에 키가 없으면 가려진 입력창으로 키를 받고 자식 프로세스에서만 사용한 뒤 제거한다.
3. `generate`는 기본적으로 계획만 출력한다. 실제 호출은 `--execute`를 명시해야 한다.
4. 모든 요청은 단발 생성이며 `store=false`로 전송한다. 서버 대화 상태를 사용하지 않는다.
5. API 응답은 곧바로 게임 파일을 덮어쓰지 않는다. `tmp/lyria_audio/<run>/.../preview.wav`에서 먼저 듣는다.
6. 런타임 WAV 교체는 단일 후보를 지정하고 `promote --confirm`을 실행한 경우에만 일어난다.
7. 승격 시 선택한 원본, 프롬프트, 모델, 생성일, SHA-256과 후처리 계약을 `assets/source/audio/lyria/v0.5/<asset>/`에 남긴다. Lyria 프리뷰 응답이 Interaction ID를 반환하지 않은 경우에는 빈 값 대신 그 사실을 명시한다.

Interactions API는 기본적으로 요청을 저장하므로, 이 파이프라인은 공식 문서가 제공하는 stateless 옵션 `store=false`를 명시한다. Lyria 생성물에는 공식 문서에 설명된 SynthID 오디오 워터마크가 포함된다.

## 설치와 무과금 점검

저장소 루트 PowerShell에서 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/audio/setup_lyria.ps1
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 validate
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 doctor
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 plan
```

가상환경은 Git에서 제외된 `tmp/lyria_audio_venv/`에 만들어진다. `doctor`는 모듈과 키 존재 여부만 확인하며 네트워크 요청을 보내지 않는다.

기본 계획은 현재 76개 자산마다 후보 2개를 만드는 구성이다.

| 모델 | 요청 수 | 현재 공식 단가 | 소계 |
|---|---:|---:|---:|
| `lyria-3-clip-preview` | 146 | USD 0.04 | USD 5.84 |
| `lyria-3-pro-preview` | 6 | USD 0.08 | USD 0.48 |
| 합계 | 152 |  | 약 USD 6.32 |

한 테이크씩만 만들면 약 USD 3.16다. 단가는 바뀔 수 있으므로 실제 실행 직전에 공식 가격 페이지와 `plan` 출력을 다시 확인한다.

Gemini 앱의 Ultra 구독과 Gemini API 프로젝트의 유료 등급은 같은 결제 항목이 아니다. Lyria 3는 공식 가격표상 무료 등급에서 제공되지 않으므로, 키가 연결된 AI Studio/Cloud 프로젝트에 유료 결제와 잔액이 있어야 한다.

## 후보 생성

먼저 한 자산으로 연결과 결과 형식을 확인한다. 아래 명령은 `--execute`가 없으므로 비용이 들지 않는다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 generate --asset combat_dungeon_pressure --takes 2
```

실제 호출은 다음과 같다. `GEMINI_API_KEY`가 설정되지 않았다면 키를 가려서 입력받는다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 generate --asset combat_dungeon_pressure --takes 2 --execute
```

단일 SFX를 시험할 때:

```powershell
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 generate --asset combat_hit --takes 2 --execute
```

76개 전체 후보를 만들 때:

```powershell
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 generate --all --takes 2 --execute
```

실행은 자동 재시도하지 않는다. 실패한 요청을 무조건 재시도하면 중복 과금과 서로 다른 비결정적 결과를 만들 수 있기 때문이다.

## 청취와 재렌더

각 후보는 다음 구조로 저장된다.

```text
tmp/lyria_audio/<run-id>/<asset-id>/take-01/
├── source.mp3
├── generation.json
├── preview.wav
└── preview.json
```

Lyria 3 Clip은 항상 30초 음악 오디오를 생성하는 모델이다. 짧은 SFX 프롬프트는 2·7·12·17·22·27초에 분리된 변형을 요구하고, 렌더러는 첫 후보의 시작점을 찾아 현재 게임과 같은 길이의 WAV로 자른다. 모델이 음악이나 연속 배경음을 섞었으면 그 테이크는 승격하지 않는다.

매니페스트의 길이·앵커·페이드·루프 크로스페이드를 조정한 뒤 후보만 다시 렌더할 수 있다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 render --run tmp/lyria_audio/<run-id> --asset combat_hit --take 1
```

청취 기준:

- 타격음은 애니메이션 접촉 시점보다 늦게 들리는 선행 무음이 없어야 한다.
- 동일 효과음을 빠르게 반복해도 클릭, 긴 잔향, 음량 피로가 없어야 한다.
- BGM 루프 경계에 박자 점프와 DC 클릭이 없어야 한다.
- BGM 아래에서 타격, 경고, 대사성 UI 정보가 묻히지 않아야 한다.
- 특정 기존 곡, 게임, 작곡가를 연상시키는 결과는 폐기한다.

## 승인 승격

후보를 실제로 들은 뒤 한 자산씩 승격한다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/audio/run_lyria.ps1 promote --run tmp/lyria_audio/<run-id> --asset combat_hit --take 1 --confirm
```

같은 자산의 기존 Lyria 원본 기록을 새 후보로 바꿀 때만 `--force`를 추가한다. 승격 뒤에는 Godot가 WAV import를 갱신하도록 프로젝트를 한 번 열거나 관련 headless 테스트를 실행하고, 해당 효과가 실제 재생되는 장면에서 음량과 타이밍을 확인한다.

전체 자산을 한 번에 무청취 승격하는 명령은 의도적으로 제공하지 않는다.

## 2026-07-15 승격 상태

- 사용자가 선택한 `combat_dungeon_pressure` Take 1과 `combat_hit` Take 2를 런타임에 승격했다.
- 관리 화면 `management_castle_bustle`, 일반 전투 `combat_dungeon_pressure`, 보스 전투 `combat_boss_council`의 3상태 음악 전환을 연결했다.
- 코어·update3의 직접 전투 스킬 24개에 각각 별도 WAV와 별도 재질·동작·음조 프롬프트를 부여했다. 스킬 발동음은 기존 베기·화염·피격 레이어와 함께 재생된다.
- 이번 확장 호출은 Clip 24회와 Pro 2회로, 실행 당시 공식 단가 기준 예상 USD 1.12다. 최초 선택 후보 4회까지 포함한 누적 예상 요청 비용은 USD 1.36이다.
- 생성 원본과 프롬프트·해시·후처리 기록은 `assets/source/audio/lyria/v0.5/`에 있으며 API 키는 포함하지 않는다. 이번 Lyria 프리뷰 응답은 Interaction ID 값을 반환하지 않아 각 `SOURCE.md`에 그 사실을 명시했다.
- 파일 로드, 길이, 비무음, 고유 해시, 스킬 매핑과 음악 상태 전환은 자동 검증했다. 최종 지각 음량과 반복 피로는 실제 플레이 청취가 필요하다.

## 현재 한계

- Lyria 3는 음악 생성 모델이며 전용 Foley/SFX 모델이 아니다. 짧은 타격음은 소스 릴의 일부를 추출하는 방식이라 모든 결과가 쓸 만하다고 보장할 수 없다.
- Clip은 항상 30초이고 같은 프롬프트도 결과가 달라진다.
- 멀티턴 편집을 지원하지 않으므로 좋은 테이크를 고르고 로컬에서 자르는 방식으로 반복한다.
- 자동 렌더는 피크와 길이를 맞출 뿐 지각 음량, 믹스 피로, 타격감, 루프의 음악적 자연스러움을 판정하지 못한다.
