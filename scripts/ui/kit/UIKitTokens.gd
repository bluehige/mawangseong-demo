extends RefCounted
class_name UIKitTokens
## Style B. Logical pixels; UIFont remains the sole font-file/locale authority.
const BACKGROUND := Color("#100c19")
const PANEL := Color("#21182d")
const PANEL_RAISED := Color("#241a31")
const BORDER := Color("#9373ab")
const GRADIENT_TOP := Color("#9e50df")
const GRADIENT_BOTTOM := Color("#3a1763")
const PRIMARY_RIM := Color("#ead1ff")
const EMPHASIS_RIM := Color("#d5b37b")
const DISABLED_BOTTOM := Color("#17141d")
const DISABLED_RIM := Color("#66566f")
const DANGER_TOP := Color("#6d2944")
const DANGER_BOTTOM := Color("#2b1023")
const ACCENT := Color("#cc8dff")
const HIGHLIGHT := Color("#ffe4a0")
const DANGER := Color("#e36b89")
const DISABLED := Color("#282331")
const TEXT := Color("#fff4e8")
const TEXT_SECONDARY := Color("#d0bddc")
const TEXT_MUTED := Color("#a696b4")
const GOLD := Color("#ffd064")
const MANA := Color("#b876ff")
const FOOD := Color("#f8a46b")
const INFAMY := Color("#dfb4f7")
const HP := Color("#6ddf80")
const EXP := Color("#ac68ef")
const SHADOW := Color("#05030999")
const GLOW := Color("#b56bff66")
const RADIUS_SMALL := 12
const RADIUS := 16
const RADIUS_LARGE := 26
const RADIUS_COMPACT := 21
const RADIUS_TAB := 14
const RADIUS_DOCK := 20
const SPACE_UNIT := 4
const SPACE_SMALL := 12
const SPACE := 24
const SPACE_LARGE := 32
const PADDING := Vector2(24, 12)
const SHADOW_SIZE := 6
const SHADOW_OFFSET := Vector2(0, 3)
const GLOW_SIZE := 8
const TITLE_SIZE := 36
const BODY_SIZE := 26
const SUPPORT_SIZE := 24
const NUMBER_SIZE := 28
const BUTTON_SIZE := 28
const BUTTON_HEIGHT := 70
const TAB_HEIGHT := 78
const DOCK_HEIGHT := 96
const BATTLE_HEIGHT := 100
const RESOURCE_HEIGHT := 84
const BAR_HEIGHT := 24
const ICON_SIZE := 56
const ICON_SMALL := 40
const ICON_BUTTON_SIZE := 84
const PORTRAIT_SIZE := 240
const TOOLTIP_SIZE := 26
const TOOLTIP_WIDTH := 560
const TOUCH_SCALE := 1.35
const RESOURCE_COLORS := {"gold": GOLD, "mana": MANA, "food": FOOD, "infamy": INFAMY}
# Legacy palette aliases preserve existing screens until their U5 migration.
const LEGACY_INK := Color("#17121f")
const LEGACY_LINE := Color("#67546e")
const LEGACY_PAPER := Color("#f4eadc")
const LEGACY_MUTED := Color("#c0b2c6")
const LEGACY_GOLD := Color("#e8bd76")

static func font_size(base: int, text_scale: float = 1.0, touch: bool = false) -> int:
	return maxi(SUPPORT_SIZE, roundi(base * clampf(text_scale, 0.9, 1.15) * (TOUCH_SCALE if touch else 1.0)))

static func geometry_scale(text_scale: float = 1.0, touch: bool = false) -> float:
	return maxf(1.0, text_scale) * (TOUCH_SCALE if touch else 1.0)
