# 스타일 B 공통 UI 리소스

- `StyleB.tres`: 새 부품에만 적용하는 단일 Godot Theme. 전역 Theme 설정과 기존 화면은 변경하지 않는다.
- 토큰의 권위는 `scripts/ui/kit/UIKitTokens.gd`, 폰트 파일·언어 선택의 권위는 기존 `scripts/ui/UIFont.gd`다.
- `tools/ui_kit/BuildTheme.gd`로 Theme과 `accent_button.svg`를 재생성한다. 강조 버튼의 작은 그라데이션 Texture 하나만 Theme에 내장하며 나머지 표면은 StyleBoxFlat이다.
- `icons/build.svg`, `check.svg`, `chevron.svg`, `unchecked.svg`, `slider_grip.svg`는 사용자 지시대로 코드 writer가 작성한 단순 임시 벡터다. GPT 이미지 생성·외부 다운로드·배경 제거를 사용하지 않았다. 최종 자산 승인본이 아니다.
- 기존 금화/마력/식량/악명/방패/공격 PNG, 푸딩 초상, 기존 4×3 공통 아이콘 atlas를 재사용한다. 경로와 atlas 셀의 권위는 `scripts/ui/kit/UIKitIcons.gd`다. 새 경로로 교체하면 Theme도 재생성한다.
- 비교용 기준 PNG와 다른 작업자의 `u3/`, `assets/source/imagegen/v1213_*`는 읽기만 하거나 사용하지 않았으며 이번 커밋에 포함하지 않는다.

사용법과 검증 경계: [U4 UI Kit](../../../docs/design/v1213_uiux/U4_UI_KIT.md).
