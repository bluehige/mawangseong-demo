# UIUX V2 흑요석 공통 UI 원본

- Generation model: GPT internal image generation
- Generated date: 2026-09-12
- Target version: v1.2.6

제품 기준선이며 새 출시 버전은 미확정이다. 사용자 지정 참고 gameuidatabase.com/gameData.php?id=729의 Curse of the Dead Gods 설정·전리품 선택 화면을 Chrome에서 확인했다(REFERENCE_VERIFIED, 2026-09-12). 어두운 판석, 잘린 모서리, 얇은 금빛 테두리, 선택 강조의 시각 언어를 참고했다. 레퍼런스 스크린샷을 다운로드하거나 생성 입력으로 사용하지 않았으며 원본 자산을 복제하지 않았다.

내장 imagegen의 실제 prompt만 사용했다. 별도 background 인수는 도구에 없으므로 전달했다고 기록하지 않는다. 결과의 실제 RGBA 및 바깥 alpha 0을 검사했다. 원본과 런타임은 바이트가 같고 로컬 배경 제거·재샘플링을 하지 않았다. 게임에서 9분할 UV와 고정 화면 모서리 크기로 표시한다. 버튼은 상하 투명 여백을 UV로 제외하고 글자·포커스는 Godot가 그린다.

## button

- Source image path: assets/source/imagegen/uiux_obsidian_20260912/button.png
- Runtime image path: assets/ui/uiux/obsidian_button.png

### 실제 프롬프트

Generate a production game UI button skin, a single wide horizontal dark obsidian plaque, front view, centered and filling almost all the canvas. Long straight sides, asymmetrical chipped angled ends, very restrained pale old-gold bevel only on the rim, slight ink-brush edge irregularity and a smoky charcoal surface. Broad calm nearly black blank center for white Korean UI text to be rendered separately. Stylized hand-painted dark fantasy, broad clean shapes readable at 300 by 60 screen pixels, sophisticated and understated, no filigree, no jewel, no icons, no letters, no text, no watermark. This is an original reusable game asset for Mawangseong. Aspect ratio 3:1. Use native transparent background output: actual transparent PNG alpha around the plaque, no colored backdrop, no checkerboard picture. Keep the graphic close to all four canvas edges with just a narrow transparent safety margin.

## panel

- Source image path: assets/source/imagegen/uiux_obsidian_20260912/panel.png
- Runtime image path: assets/ui/uiux/obsidian_panel.png

### 실제 프롬프트

Generate a single reusable dark fantasy game UI panel skin on a square canvas. Front-facing flat dark charcoal obsidian surface, smoky almost black uncluttered interior. An elegant very thin antique brass rim with restrained angular chipped corner cuts, faint broad painted edge wear, subtle depth of beveled slate at the perimeter. Interior 85 percent of image stays uniformly dark and completely empty for live game content. Do not draw text, symbols, icons, compartments or any UI content. Original art for Mawangseong, hand-painted dimensional material, calm and readable. Designed as a nine-slice panel with straight continuous edges and all corner detail restricted to the outer 5 percent of canvas. Native transparent PNG alpha outside the cut corners, panel itself opaque. No checkerboard background picture, no shadows sprawling outside canvas, no ornate filigree, no gold frame dominating the center.
