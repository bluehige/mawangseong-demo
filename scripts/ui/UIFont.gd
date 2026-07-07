extends RefCounted
class_name UIFont

const ROLE_BODY := "body"
const ROLE_DIALOGUE := "dialogue"
const ROLE_EMPHASIS := "emphasis"
const ROLE_BUTTON := "button"
const ROLE_FALLBACK := "fallback"

const BODY_FONT = preload("res://assets/fonts/NEXON_Maplestory_Light.otf")
const DIALOGUE_FONT = BODY_FONT
const EMPHASIS_FONT = preload("res://assets/fonts/NEXON_Maplestory_Bold.otf")
const BUTTON_FONT = EMPHASIS_FONT
const FALLBACK_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")

static func font_for_role(role: String) -> Font:
	match role:
		ROLE_DIALOGUE:
			return DIALOGUE_FONT
		ROLE_EMPHASIS:
			return EMPHASIS_FONT
		ROLE_BUTTON:
			return BUTTON_FONT
		ROLE_FALLBACK:
			return FALLBACK_FONT
		_:
			return BODY_FONT
