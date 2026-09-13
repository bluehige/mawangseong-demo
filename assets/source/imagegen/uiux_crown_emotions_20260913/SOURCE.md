# 왕관 형태 감정 초상

Generation model: GPT internal image generation
Generated date: 2026-09-13
Target version: 1.2.6 UIUX worktree (unreleased)
Source image path: assets/source/imagegen/uiux_crown_emotions_20260913/core.png
Runtime image path: assets/sprites/portraits/uiux_crowns/core.png
Source image path: assets/source/imagegen/uiux_crown_emotions_20260913/support.png
Runtime image path: assets/sprites/portraits/uiux_crowns/support.png

각 그룹은 3열×2행, 위 승리/아래 부상이며 512×512 영역 6개를 참조한다. 원본 1536×1024 RGB를 그대로 복사했고 래스터 후처리는 없다. 불투명 UI 초상, 투명 전장 스프라이트가 아니다. 기존 의회 초상은 유지한다.

## core prompt

Use case: identity-preserve. Create one 1536x1024 production game portrait atlas with exactly 3 columns x 2 rows of equal 512x512 square cells. The three references are EXACT character identity/outfit/framing references. Columns: 1 crowned purple pudding fortress defender, turquoise stone armor and dual shields, cream/cherry on head, gold ruby crown; 2 older green goblin marshal, dark leather hood, golden circlet, burgundy scarf, black/gold armor, spear and keys; 3 pale pink-haired horned demon flame sage, ornate gold/purple crown, red black gold robes and magenta staff. Row1 VICTORY: smiling satisfied celebratory, still each character's own personality, tiny triumphant upper-body gesture. Row2 WOUNDED/FATIGUED: low energy, tired eyes, slight grimace and lowered shoulders; armor lightly scuffed, no blood, no new bandages, no death. Keep SAME identity, proportions, outfits, equipment and crown across both rows. Keep full reference silhouette visible within each square with comfortable margin; maximize legible eyes. Match rich polished stylized 3D collectible render with smooth clean materials and soft cool rim light; consistent dark charcoal-violet OPAQUE studio gradient backgrounds across cells, not transparency. No scenery, text, frames, cell borders, labels, gutters, additional characters or floating confetti. Nothing may cross cell edges. This is UI portrait art cropped in Godot.

## support prompt

Use case: identity-preserve. Make one 1536x1024 production game UI portrait atlas, exactly 3 columns by 2 rows, six equal square 512x512 cells, no gutters, no borders, no text. The three refs show EXACT characters, preserve their identity/equipment/proportions. Column1 mushroom high priest: huge red cap with cream spots, golden pearl circlet, cream stem face, green moss cloak, white gold priest stole, twisted wood staff with green glowing lantern. Column2 royal beetle armorer: squat black bronze gold armored beetle, purple eyes and violet gemstones, gold pointed crown centered above armored forehead, forelegs visible, never turn it into humanoid knight. Column3 grand night courier: cute dark blue bat, huge purple ears, violet eyes, navy gold crown cap, purple scarf/cape, brown satchel and sealed letter. Keep full reference silhouette within each square, same framing and physical size per character across both rows. Row1 VICTORY: mushroom delighted relaxed smile, beetle proud bright eyes and lifted body stance, bat joyful grin and tiny celebratory letter gesture. Row2 WOUNDED/FATIGUED: mushroom weary concerned low eyes, beetle tired narrowed eyes and slight slump with small armor scuffs, bat exhausted concerned soft eyes/low ears. No blood, gore, broken limbs, bandages, tears or destroyed equipment. Clean polished stylized 3D collectible art, smooth strong readable forms, nuanced highlights, fixed soft cool rim lighting. Every cell has the same very dark charcoal-violet opaque studio gradient, no scene/floor/shadows spilling outside character. Portrait atlas, intentionally opaque background. No extra characters or effects. Do not cross cell boundaries.
