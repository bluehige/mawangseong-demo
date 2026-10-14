# U5-A 기존 승인 자산 재사용

- Generation model: GPT internal image generation
- Generated date: 2026-10-14
- Target version: v1.2.12
- Source image path: assets/source/imagegen/v1213_u5_reuse/dialogue_throne_original.png
- Runtime image path: assets/ui/v1213/dialogue_throne.png
- Source image path: assets/source/imagegen/v1213_u5_reuse/logo_ko_original.png
- Runtime image path: assets/ui/v1213/logo_ko.png
- Source image path: assets/source/imagegen/v1213_u5_reuse/logo_en_original.png
- Runtime image path: assets/ui/v1213/logo_en.png
- Source image path: assets/source/imagegen/v1213_u5_reuse/logo_zh_CN_original.png
- Runtime image path: assets/ui/v1213/logo_zh_CN.png

신규 이미지 생성 없이 기존 승인된 GPT 자산을 재사용했다. 위 날짜는 U5-A 런타임 채택일이며 로고 최초 생성일을 새로 주장하지 않는다. 원래 생성·프롬프트 근거는 docs/design/v1213_screens/SOURCE.md 및 assets/source/imagegen/steam_english_title_v127/SOURCE.md, steam_chinese_title_local_candidate/SOURCE.md에 있다.

왕좌의 방 원본1600×900은 그대로 유지·PNG 최적화했다. 기존 흐린 원경(마왕·바티·골딘)을 보존하고 렌더러가 화면을 채운다. 로고3종은 기존 투명 PNG의 알파 bounding box만 잘라 불필요한 여백을 제거했고 픽셀·알파 재생성/배경 제거를 하지 않았다. PrepareU5Assets.py의 asset_checks.json으로 RGBA 알파0~255를 확인했다. 신규 타이틀 그림은 별도 v1213_title_monster_court/SOURCE.md에 기록한다.

영어 로고의 alpha=1 가장자리 때문에 글자가 작아 보이는 문제는 UI의 AtlasTexture region=(100,93,997,267)으로 보정했다. 원본 픽셀·알파는 유지하고 표시 영역만 제한한다. 별도 배경 제거나 픽셀 재생성은 하지 않았다.

2026-10-14 출처 정책 보완: Source image path는 이 SOURCE.md와 같은 디렉터리의 보존 사본으로 연결한다. 위 네 사본은 각각 docs/design/v1213_screens/dialogue_bg_throne_report.png, marketing/steam/library/logo.png, marketing/steam/english/library/logo.png, marketing/steam/schinese/library/logo.png와 SHA256/바이트가 같다. 신규 생성 없이 기존 원본을 보존 복사했으며 런타임 PNG는 변경하지 않았다. v1213은 작업 이름이고 실제 채택 제품 버전은v1.2.12다.
