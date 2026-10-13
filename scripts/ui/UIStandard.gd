extends RefCounted
class_name UIStandard
const UIFont = preload("res://scripts/ui/UIFont.gd")

# Logical pixels at 1920x1080. Small text is supporting copy, never a fit escape.
const BODY_SIZE := 20
const SUPPORT_SIZE := 18
const BUTTON_SIZE := 22
const BUTTON_HEIGHT := 44
const BUTTON_PADDING := Vector2(12, 8)
const ICON_SIZE := 32
const ICON_BUTTON_SIZE := 48
const TOOLTIP_SIZE := 22
const TOOLTIP_WIDTH := 560
const ICON_ATLAS := "res://assets/ui/icons/v1213_common.png"
const ICONS := ["log", "settings", "menu", "auto", "skip", "close", "resume", "save", "load", "title", "quit", "reset"]
static var _icons: Dictionary = {}

static func tooltip_label(for_text: String) -> Label:
	var label := Label.new()
	label.text = LanguageSettings.ui_text(for_text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font := UIFont.font_for_role(UIFont.ROLE_BODY)
	var font_size := text_size(TOOLTIP_SIZE)
	var height := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, TOOLTIP_WIDTH, font_size).y + 8
	label.custom_minimum_size = Vector2(TOOLTIP_WIDTH, height)
	label.size = label.custom_minimum_size
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#fff6e8"))
	return label

static func text_size(requested: int) -> int:
	return maxi(SUPPORT_SIZE if requested <= SUPPORT_SIZE else BODY_SIZE, UISettings.scaled_font_size(requested))

static func localized(ko: String, en: String, zh: String) -> String:
	return en if LanguageSettings.locale == "en" else (zh if LanguageSettings.locale == "zh_CN" else ko)

static func icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var index := ICONS.find(id)
		if index < 0: return null
		var sheet: Texture2D = load(ICON_ATLAS)
		var cell := Vector2(sheet.get_size()) / Vector2(4, 3)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
		_icons[id] = atlas
	return _icons[id]

static func description(id: String) -> String:
	match id:
		"log": return localized("대화 로그\n지금까지 읽은 대사를 확인합니다. 진행과 선택은 바뀌지 않습니다.", "Dialogue log\nReview dialogue already read without changing progress or choices.", "对话记录\n查看已读对话，不改变进度或选择。")
		"settings": return localized("설정\n언어·화면·전투 표시·음량을 조정합니다.", "Settings\nAdjust language, display, combat presentation and volume.", "设置\n调整语言、画面、战斗显示和音量。")
		"menu": return localized("게임 메뉴\n계속하기·저장·불러오기·설정·타이틀·종료를 선택합니다.", "Game menu\nResume, save, load, change settings, return to title or quit.", "游戏菜单\n继续、保存、读取、设置、返回标题或退出。")
		"auto": return localized("자동 대화\n자동으로 다음 대사를 표시합니다. 다시 누르면 해제합니다.", "Auto dialogue\nAdvance dialogue automatically. Press again to turn it off.", "自动对话\n自动显示下一句，再次点击关闭。")
		"skip": return localized("대사 넘기기\n넘기기가 허용된 대사를 건너뜁니다.", "Skip dialogue\nSkip dialogue when skipping is allowed.", "跳过对话\n跳过允许跳过的对话。")
		"close": return localized("닫기\n현재 창을 닫고 이전 화면으로 돌아갑니다.", "Close\nClose this window and return to the previous screen.", "关闭\n关闭当前窗口并返回上一画面。")
		"resume": return localized("계속\n메뉴를 닫고 게임으로 돌아갑니다.", "Resume\nClose the menu and return to the game.", "继续\n关闭菜单并返回游戏。")
		"save": return localized("저장\n안전한 화면에서 현재 진행을 체크포인트에 저장합니다. 전투 중간 저장은 지원하지 않습니다.", "Save\nSave progress at a safe checkpoint. Mid-battle saves are unavailable.", "保存\n在安全画面保存检查点，不支持战斗中途存档。")
		"load": return localized("불러오기\n진행 손실 확인 후 마지막 체크포인트를 복원합니다.", "Load\nRestore the last checkpoint after confirming progress loss.", "读取\n确认进度损失后恢复最近检查点。")
		"title": return localized("타이틀\n진행 손실 확인 후 타이틀로 돌아갑니다.", "Title\nReturn to the title after confirming progress loss.", "标题\n确认进度损失后返回标题。")
		"quit": return localized("종료\n종료 선택을 확인한 뒤 게임을 닫습니다.", "Quit\nClose the game after confirming how to leave.", "退出\n确认退出方式后关闭游戏。")
		"reset": return localized("기본값\n현재 설정 분류를 기본값으로 되돌립니다. 적용을 눌러 저장합니다.", "Defaults\nReset this settings category. Press Apply to save.", "默认值\n重置当前设置分类，点击应用保存。")
	return ""

static func action_tooltip(text: String, callback: Callable) -> String:
	var name := LanguageSettings.ui_text(text).strip_edges()
	if name == "": return "" # Composite cards supply their actual content at construction.
	var method := str(callback.get_method())
	var help := localized("누르면 이 항목을 선택하거나 실행합니다.", "Select or activate this item.", "点击选择或执行此项。")
	if "open" in method or "show" in method:
		help = localized("누르면 해당 정보나 화면을 엽니다.", "Open this information or screen.", "点击打开相关信息或画面。")
	elif "cancel" in method or "close" in method:
		help = localized("현재 선택을 취소하거나 창을 닫습니다.", "Cancel the current selection or close this window.", "取消当前选择或关闭窗口。")
	return name + "\n" + help

static func complete_tooltips(node: Node) -> void:
	# Composite cards are assembled after their empty button shell. Use their
	# displayed content, never a developer node ID, for their accessible name.
	if node is BaseButton and node.tooltip_text.strip_edges() == "":
		var parts: Array[String] = []
		if node is Button and node.text.strip_edges() != "": parts.append(LanguageSettings.ui_text(node.text))
		for label in node.find_children("*", "Label", true, false):
			if label.text.strip_edges() != "": parts.append(LanguageSettings.ui_text(label.text))
		if not parts.is_empty():
			node.tooltip_text = "\n".join(parts) + "\n" + localized("누르면 이 항목을 선택하거나 실행합니다.", "Select or activate this item.", "点击选择或执行此项。")
	for child in node.get_children(): complete_tooltips(child)
