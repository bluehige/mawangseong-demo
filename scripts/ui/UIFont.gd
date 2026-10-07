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
	# An explicit bundled fallback also keeps the Chinese selector legible in ko/en.
	var body: FontFile = BODY_FONT
	var emphasis: FontFile = EMPHASIS_FONT
	if body.fallbacks.is_empty():
		body.fallbacks = [FALLBACK_FONT]
	if emphasis.fallbacks.is_empty():
		emphasis.fallbacks = [FALLBACK_FONT]
	if TranslationServer.get_locale().begins_with("zh"):
		return FALLBACK_FONT
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
