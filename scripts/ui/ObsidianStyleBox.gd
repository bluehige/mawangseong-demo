extends StyleBox
# Native GPT textures are drawn as nine regions. Source pixels are never resized
# or background-removed on disk; destination corners keep a readable screen size.
var texture: Texture2D
var panel_texture: Texture2D
var fill := Color("#17121f")
var accent := Color("#e8bd76")
var strong := false
var outline_only := false
var button_shape := false
var tint := Color.WHITE

func _init() -> void:
	set_content_margin_all(8)

func _draw(item: RID, rect: Rect2) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	var cut := minf(12.0, rect.size.y * 0.2)
	var p := rect.position
	var s := rect.size
	var contour := PackedVector2Array([p+Vector2(cut,2),p+Vector2(s.x-cut,2),p+Vector2(s.x-2,cut),p+Vector2(s.x-2,s.y-cut),p+Vector2(s.x-cut,s.y-2),p+Vector2(cut,s.y-2),p+Vector2(2,s.y-cut),p+Vector2(2,cut),p+Vector2(cut,2)])
	if outline_only:
		RenderingServer.canvas_item_add_polyline(item,contour,PackedColorArray([accent]),2.0,true)
		return
	if texture == null or rect.size.y < 26.0:
		RenderingServer.canvas_item_add_polygon(item,contour,PackedColorArray([fill]))
		return
	var draw_texture: Texture2D = panel_texture if button_shape and s.y >= 110.0 else texture
	var ts := draw_texture.get_size()
	var source := Rect2(Vector2.ZERO,ts)
	var src_margin := ts * 0.105
	var edge := Vector2(18,18)
	if button_shape and s.y < 110.0:
		source = Rect2(0,ts.y*0.11,ts.x,ts.y*0.77)
		src_margin = Vector2(ts.x*0.185,source.size.y*0.2)
		edge = Vector2(28,12)
	edge.x = minf(edge.x,s.x*0.25)
	edge.y = minf(edge.y,s.y*0.35)
	var dx := [0.0,edge.x,s.x-edge.x,s.x]
	var dy := [0.0,edge.y,s.y-edge.y,s.y]
	var sx := [source.position.x,source.position.x+src_margin.x,source.end.x-src_margin.x,source.end.x]
	var sy := [source.position.y,source.position.y+src_margin.y,source.end.y-src_margin.y,source.end.y]
	for y in range(3):
		for x in range(3):
			var destination := Rect2(p+Vector2(dx[x],dy[y]),Vector2(dx[x+1]-dx[x],dy[y+1]-dy[y]))
			var region := Rect2(Vector2(sx[x],sy[y]),Vector2(sx[x+1]-sx[x],sy[y+1]-sy[y]))
			var color := tint
			RenderingServer.canvas_item_add_texture_rect_region(item,destination,draw_texture.get_rid(),region,color,false,true)
	if strong:
		RenderingServer.canvas_item_add_polyline(item,contour,PackedColorArray([accent]),1.4,true)
		var center := p + Vector2(9,s.y*0.5)
		RenderingServer.canvas_item_add_polygon(item,PackedVector2Array([center+Vector2(0,-4),center+Vector2(4,0),center+Vector2(0,4),center+Vector2(-4,0)]),PackedColorArray([accent]))
