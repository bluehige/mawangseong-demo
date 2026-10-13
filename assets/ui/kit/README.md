# 스타일 B 공통 UI 리소스

- `StyleB.tres`: 새 부품에만 적용하는 단일 Godot Theme. 전역 Theme 설정과 기존 화면은 변경하지 않는다.
- 토큰의 권위는 `scripts/ui/kit/UIKitTokens.gd`, 폰트 파일·언어 선택의 권위는 기존 `scripts/ui/UIFont.gd`다.
- `surface.gdshader` + `KitSurface.gd`: 패널·버튼·탭·칩·카드·툴팁·모달·독·토스트의 세로 그라데이션, 유한12px glow, 밝은 외곽선/어두운 안쪽선, 상단 하이라이트. 화면 샘플/블러/다중 패스/시간 애니메이션 없음. 크기/상태가 바뀔 때만 uniform을 갱신한다.
- `tools/ui_kit/BuildTheme.gd`로 Theme과 native Control용 `accent_button.svg`를 재생성한다. HP/EXP는24px 둥근 끝 그라데이션9-slice를 공유한다. 새 키트의 표면은 셰이더이며 기존 native Control fallback은 Theme을 사용한다.
- `icons/icon_*_{64,128}.png`: 기존 GPT 네이티브 알파 원본32종의 Lanczos 최적화64개, 총636452bytes. 재현: tools/ui_kit/prepare_icons.py. 출처: assets/source/imagegen/v1213_ui_icons/SOURCE.md. 임시 SVG5종을 제거했다.
- `UIKitIcons.gd`의32종+호환 별칭 중앙 매핑. 기존 UIStandard 화면은 기존12칸 atlas와 원래 치수를 별도 보존한다. U5에서 새 키트를 채택해야 새 치수가 실제 화면에 적용된다.
- 비교용 기준/U3/성 홀 배경은 갤러리에서만 읽는다. 새로운 imagegen 호출이나 스킨 PNG 생성은 없다.

사용법과 검증 경계: [U4 UI Kit](../../../docs/design/v1213_uiux/U4_UI_KIT.md).
