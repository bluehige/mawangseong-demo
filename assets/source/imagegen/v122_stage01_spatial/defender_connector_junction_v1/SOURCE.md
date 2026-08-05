# Stage 01 방어자 전용 연결로 접속석 v1 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-08-01
- Target version: v1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/defender_connector_junction_v1/defender_connector_junction_raw_chroma.png
- Source image path: assets/source/imagegen/v122_stage01_spatial/defender_connector_junction_v1/defender_connector_junction_alpha.png
- Runtime image path: assets/tiles/stage_01/spatial_passage_v1/defender_connector_junction_stage01.png

## 역할과 상태

- 자산 역할: DAY 3 방어자 전용 연결로 중앙 접속석
- 런타임 크기: 128×64
- 상태: `RUNTIME_CANDIDATE`
- 잠김·건설 가능·건설 완료는 동일 bitmap에 회색·금색·청록색 tint를 적용해 표현한다.

## 생성·변환

- 도로 autotile v2와 일반 연결 통로를 재질 참고로 사용했다.
- 원본은 단색 `#00ff00` chroma 배경으로 생성한 뒤 로컬 alpha로 변환했다.
- `tools/prepare_v122_defender_connector.py`가 alpha bbox를 exact 128×64로 축소한다.
- 접속석은 원형 UI marker가 아니라 실제 바닥 석재와 홈으로 읽혀야 한다.

## 최종 생성 프롬프트

```text
Use case: stylized-concept
Asset type: isometric stone junction plate for a defender-only shortcut in a dark-fantasy fortress game
Input images: Image 1 is the approved road material; Image 2 is the approved connection-passage material.
Primary request: Create one small flat 2:1 isometric diamond junction stone that joins passage segments. Use a single broad chipped basalt plate with a shallow recessed four-way channel carved into the center. The channel must be neutral dark metal-gray so runtime tint can indicate locked, available, or built state.
Composition/framing: one centered 2:1 isometric diamond plate, perfectly flat and low profile, generous empty padding, clean silhouette.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local removal; no shadows, gradients, texture, reflections, floor plane, or lighting variation in the background.
Style/medium: painterly dark-fantasy game environment asset matching the supplied road and passage; low-frequency detail readable at 128x64.
Color palette: charcoal basalt, muted violet-gray, restrained warm upper-left edge wear, neutral recessed channel.
Constraints: no circular badge, no UI icon, no bright glow baked into the image, no gold, no teal, no text, no logo, no watermark, no walls, no props; do not use #00ff00 inside the plate; crisp separated silhouette.
```
