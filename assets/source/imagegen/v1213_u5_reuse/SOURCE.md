# U5-A 기존 승인 자산 재사용

- Generation model: GPT internal image generation
- Generated date: 2026-10-14
- Target version: 1.2.12 (v1213 U5-A 작업명; 제품 버전 변경 없음)
- Source image path: docs/design/v1213_screens/dialogue_bg_throne_report.png
- Runtime image path: assets/ui/v1213/dialogue_throne.png
- Source image path: marketing/steam/library/logo.png
- Runtime image path: assets/ui/v1213/logo_ko.png
- Source image path: marketing/steam/english/library/logo.png
- Runtime image path: assets/ui/v1213/logo_en.png
- Source image path: marketing/steam/schinese/library/logo.png
- Runtime image path: assets/ui/v1213/logo_zh_CN.png

신규 이미지 생성 없이 기존 승인된 GPT 자산을 재사용했다. 위 날짜는 U5-A 런타임 채택일이며 로고 최초 생성일을 새로 주장하지 않는다. 원래 생성·프롬프트 근거는 docs/design/v1213_screens/SOURCE.md 및 assets/source/imagegen/steam_english_title_v127/SOURCE.md, steam_chinese_title_local_candidate/SOURCE.md에 있다.

왕좌의 방 원본1600×900은 그대로 유지·PNG 최적화했다. 기존 흐린 원경(마왕·바티·골딘)을 보존하고 렌더러가 화면을 채운다. 로고3종은 기존 투명 PNG의 알파 bounding box만 잘라 불필요한 여백을 제거했고 픽셀·알파 재생성/배경 제거를 하지 않았다. PrepareU5Assets.py의 asset_checks.json으로 RGBA 알파0~255를 확인했다. 신규 타이틀 그림은 별도 v1213_title_monster_court/SOURCE.md에 기록한다.

?? ???? ?? ?? ??1 ??? ?? UI??? AtlasTexture region=(100,93,997,267)? ????. ??? PNG? ???8 ??/??? ???12px? ?? ?? ?????. ?? ??/??? ???? ???, ?? ?? ??? ?? ?? ?? ??1~7 ???. ???/?? ??? ?? ??? ?? ????.
