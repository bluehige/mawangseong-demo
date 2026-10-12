extends Control
# Immutable actual placed-room art, with no build-hover or world-node mutation.
var snapshot:Dictionary={}
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# The actual heart is one AtlasTexture with its own chroma material. Keep
	# that material on this isolated art canvas, never on ordinary room layers.
	var layers:Array=snapshot.get("layers",[])
	if layers.size()==1 and str(layers[0].get("key",""))=="actual_heart_atlas":
		material=layers[0].get("material")
func _draw()->void:
	var bounds:Rect2=snapshot.get("bounds",Rect2())
	if bounds.size.x<=0.0 or bounds.size.y<=0.0:return
	var factor:float=minf(size.x/bounds.size.x,size.y/bounds.size.y)
	draw_set_transform((size-bounds.size*factor)*.5-bounds.position*factor,0,Vector2.ONE*factor)
	for layer in snapshot.get("layers",[]):
		draw_texture_rect(layer.texture,layer.rect,false,layer.get("modulate",Color.WHITE))
	draw_set_transform(Vector2.ZERO)
