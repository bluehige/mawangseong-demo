extends RefCounted
## Plain-text layout shared by dialogue surfaces. Never rewrites authored copy.
const Fonts = preload("res://scripts/ui/UIFont.gd")
const MIN_FONT_SIZE := 18

static func paragraph(text: String, font: Font, pixels: int, width: float, gap: float = 0.0) -> TextParagraph:
	var result := TextParagraph.new()
	result.width = maxf(1,width)
	result.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	result.line_spacing = gap
	result.add_string(text,font,pixels,TranslationServer.get_locale())
	return result

static func pages(text: String, font: Font, pixels: int, bounds: Vector2, gap: float = 0.0) -> Array[String]:
	var result: Array[String] = []
	var start := 0
	while start < text.length():
		var remaining := text.substr(start)
		var shaped := paragraph(remaining,font,pixels,bounds.x-4,gap)
		var height := 0.0
		var end := remaining.length()
		for line in shaped.get_line_count():
			var next_height := height + shaped.get_line_size(line).y + gap
			# RichTextLabel rounds fallback-font ascenders and paragraph edges
			# differently from TextParagraph. Reserve one small baseline margin.
			if line > 0 and next_height > bounds.y-maxf(14,font.get_height(pixels)*0.25):
				end = shaped.get_line_range(line).x
				break
			height = next_height
		# A glyph/word wider than the slot still makes forward progress. Adaptive
		# wrapping keeps grapheme clusters together; no raw character truncation.
		end = maxi(1,end)
		result.append(remaining.substr(0,end))
		start += end
	if result.is_empty(): result.append(text)
	return result

static func fit_label(label: Label, bounds: Rect2, minimum: int = MIN_FONT_SIZE) -> void:
	label.set_meta("dialogue_layout_managed",true)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.max_lines_visible = -1
	label.clip_text = true
	label.position = bounds.position
	label.size = bounds.size
	var pixels := label.get_theme_font_size("font_size")
	while pixels > minimum and label_height(label,bounds.size.x) > bounds.size.y-2:
		pixels -= 1
		label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_font_size_override("font_size",pixels)
	label.custom_minimum_size = Vector2.ZERO
	label.size = bounds.size
	label.set_meta("dialogue_bounds",bounds)

static func label_height(label: Label, width: float) -> float:
	# Label uses the font's full line metrics, including leading. The shaped
	# glyph rectangle alone can be shorter and incorrectly hide the whole line.
	label.size.x = width
	var height := 0.0
	var lines := label.get_line_count()
	for line in lines: height += label.get_line_height(line)
	return height+maxi(0,lines-1)*label.get_theme_constant("line_spacing")+2

static func grow_feed(panel: Control, speaker: Label, body: Label) -> void:
	# Battle reactions stay nonmodal, with a bounded width and measured height.
	var right := 24.0
	var width := minf(panel.size.x,1920.0-48.0)
	panel.size.x = width
	var name_height := maxf(36,label_height(speaker,width-speaker.position.x-right)+4)
	fit_label(speaker,Rect2(speaker.position,Vector2(width-speaker.position.x-right,name_height)))
	body.position.y = speaker.position.y+name_height+8
	var needed := label_height(body,width-body.position.x-right)+8
	panel.size.y = maxf(panel.size.y,body.position.y+needed+24)
	panel.size.y = minf(panel.size.y,520)
	fit_label(body,Rect2(body.position,Vector2(width-body.position.x-right,panel.size.y-body.position.y-24)))
	panel.position.x = clampf(panel.position.x,24,1920-panel.size.x-24)
	panel.position.y = clampf(panel.position.y,24,1080-panel.size.y-24)
	panel.set_meta("dialogue_inner_margin",24)

static func scrolling_text(label: RichTextLabel) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.scroll_active = true
	label.scroll_following = false
	label.clip_contents = true
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.focus_mode = Control.FOCUS_ALL
	label.add_theme_font_override("normal_font",Fonts.font_for_role(Fonts.ROLE_DIALOGUE))
