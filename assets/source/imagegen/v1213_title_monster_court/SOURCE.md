# U5-A 타이틀 몬스터 왕좌 배경

- Generation model: GPT internal image generation
- Generated date: 2026-10-14
- Target version: v1.2.12
- Source image path: assets/source/imagegen/v1213_title_monster_court/generated_native.png
- Source image path: assets/source/imagegen/v1213_title_monster_court/resolution_retry_native.png
- Source image path: assets/source/imagegen/v1213_title_monster_court/title_master_2048.png
- Runtime image path: assets/ui/v1213/title_monster_court.png

내부 imagegen 2회, transparent_background:false. 입력은 v1213_title_v3.png(구성·스타일 기준)였고 두 번째는 첫 생성 배경의 고해상도 재생성 요청이다. UI·글자·로고·버튼을 제거하고 양옆 귀여운 몬스터 군집, 뒤 옥좌의 마왕, 비어 있는 중앙 계단·카펫을 요청했다. 실제 프롬프트는 generation_prompts.json에 보존했다. 외부 서비스·유료 API 호출 없음.

## 해상도 제한과 후처리

프롬프트에서1920×1080 이상, 재시도에서는2560×1440 또는2048×1152 네이티브를 요구했지만 이 호출 인터페이스에는 해상도 인자가 없고 **두 생성 결과 모두1672×941 RGB**였다. native 두 파일은 생성 결과 그대로다. source master2048×1152와 runtime1920×1080은 LANCZOS 확대+PNG 최적화이며 네이티브 고해상도 생성으로 주장하지 않는다. 1920 이상 네이티브 원본 요구는 미충족이며 헤드 인계에 제한으로 남긴다. UI나 글자는 후처리로 덧씌우지 않았다. 런타임에는 별도 기존 투명 로고와 실제 버튼을 그린다.
