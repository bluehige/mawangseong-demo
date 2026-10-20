extends RefCounted
# Existing GPT UI texture, readable screen-space text and one small state accent.
const UXTheme = preload("res://scripts/ui/UIUXTheme.gd")
static func layout(target: CanvasItem, anchor: Vector2, text: String, font: Font, base_size: int = 18) -> Dictionary:
	text = LanguageSettings.ui_text(text)
	var transform:=target.get_global_transform_with_canvas()
	var point:=transform*anchor
	var font_size:=UISettings.scaled_font_size(base_size)
	var size:=Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+42,font.get_height(font_size)+14)
	var rect:=Rect2(point-Vector2(size.x*0.5,size.y+8),size)
	var viewport:=target.get_viewport_rect().size
	rect.position.x=clampf(rect.position.x,8,maxf(8,viewport.x-size.x-8))
	rect.position.y=clampf(rect.position.y,8,maxf(8,viewport.y-size.y-8))
	return {"rect":rect,"point":point,"text":text,"font_size":font_size,"transform":transform}
static func place(rect: Rect2, bounds: Rect2, obstacles: Array[Rect2]) -> Rect2:
	# Candidate positions touch an obstacle edge. Choose the nearest free position,
	# rather than alternating above/below the same pair of crowded labels.
	var xs: Array[float]=[clampf(rect.position.x,bounds.position.x,bounds.end.x-rect.size.x)]
	var ys: Array[float]=[clampf(rect.position.y,bounds.position.y,bounds.end.y-rect.size.y)]
	for obstacle in obstacles:
		xs.append(clampf(obstacle.position.x-rect.size.x-8,bounds.position.x,bounds.end.x-rect.size.x))
		xs.append(clampf(obstacle.end.x+8,bounds.position.x,bounds.end.x-rect.size.x))
		ys.append(clampf(obstacle.position.y-rect.size.y-8,bounds.position.y,bounds.end.y-rect.size.y))
		ys.append(clampf(obstacle.end.y+8,bounds.position.y,bounds.end.y-rect.size.y))
	var best:=Rect2(Vector2(xs[0],ys[0]),rect.size)
	var distance:=INF
	for x in xs:
		for y in ys:
			var candidate:=Rect2(Vector2(x,y),rect.size)
			var cost:=candidate.position.distance_squared_to(rect.position)
			if cost>=distance: continue
			var blocked:=false
			for obstacle in obstacles:
				if candidate.grow(3).intersects(obstacle):
					blocked=true
					break
			if not blocked:
				best=candidate
				distance=cost
	return best
static func draw(target: CanvasItem, info: Dictionary, color: Color, font: Font) -> void:
	var rect: Rect2=info.rect
	var transform: Transform2D=info.transform
	target.draw_set_transform_matrix(transform.affine_inverse())
	var stem:=Vector2(clampf(info.point.x,rect.position.x+12,rect.end.x-12),clampf(info.point.y,rect.position.y+5,rect.end.y-5))
	target.draw_line(stem,info.point,Color(color,0.5),1.0,true)
	target.draw_style_box(UXTheme.world_badge(color),rect)
	var at:=rect.position+Vector2(13,rect.size.y*0.5)
	target.draw_line(at-Vector2(0,5),at+Vector2(0,5),color,2.5,true)
	var baseline:=rect.position+Vector2(25,7+font.get_ascent(info.font_size))
	target.draw_string_outline(font,baseline,info.text,HORIZONTAL_ALIGNMENT_LEFT,-1,info.font_size,3,Color("#08080bd9"))
	target.draw_string(font,baseline,info.text,HORIZONTAL_ALIGNMENT_LEFT,-1,info.font_size,Color("#f4eadc"))
	target.draw_set_transform_matrix(Transform2D.IDENTITY)
static func at(target: CanvasItem, anchor: Vector2, text: String, color: Color, font: Font, base_size: int = 18) -> void:
	draw(target,layout(target,anchor,text,font,base_size),color,font)

# Management uses the same screen-space collision placement for both rendering
# and build-label hit testing. Combat's existing typography remains unchanged.
static func management_layout(point: Vector2, text: String, font: Font, font_size: int, viewport: Vector2, above: bool = false) -> Dictionary:
	text = LanguageSettings.ui_text(text)
	var limit := minf(440.0,viewport.x-40.0)
	var lines: Array[String] = []
	var current := ""
	for word in text.replace("\n"," ").split(" ",false):
		var candidate := word if current == "" else current+" "+word
		if current != "" and font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x > limit-24:
			lines.append(current)
			current = word
		else: current = candidate
	if current != "": lines.append(current)
	var width := 0.0
	for value in lines: width = maxf(width,font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
	var line_height := font.get_height(font_size)
	var size := Vector2(maxf(64,width+24),line_height*lines.size()+12)
	var rect := Rect2(point-Vector2(size.x*0.5,size.y+6 if above else -6),size)
	rect.position.x = clampf(rect.position.x,12,maxf(12,viewport.x-size.x-12))
	return {"rect":rect,"font_size":font_size,"lines":lines,"line_height":line_height}

static func draw_management(target: CanvasItem, anchor: Vector2, info: Dictionary, color: Color, font: Font) -> void:
	var rect: Rect2 = info.rect
	target.draw_set_transform_matrix(target.get_global_transform_with_canvas().affine_inverse())
	if not rect.has_point(anchor): target.draw_line(anchor,rect.get_center(),Color(color,0.5),1,true)
	target.draw_style_box(UXTheme.world_badge(color),rect)
	var baseline := rect.position.y+6+font.get_ascent(info.font_size)
	for value in info.lines:
		target.draw_string(font,Vector2(rect.position.x+12,baseline),value,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-24,info.font_size,Color("#fff4e8"))
		baseline += float(info.line_height)
	target.draw_set_transform_matrix(Transform2D.IDENTITY)
