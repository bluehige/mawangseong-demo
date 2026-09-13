extends RefCounted
# Existing GPT UI texture, readable screen-space text and one small state accent.
const UXTheme = preload("res://scripts/ui/UIUXTheme.gd")
static func layout(target: CanvasItem, anchor: Vector2, text: String, font: Font, base_size: int = 18) -> Dictionary:
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
