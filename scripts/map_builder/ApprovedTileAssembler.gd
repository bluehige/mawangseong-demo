extends RefCounted
## Texture assembly only: every visible surface is sampled GPT raster artwork.
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const ART := "res://assets/maps/v130r_step2/"
const Placement = preload("res://scripts/map_builder/ApprovedPlacement.gd")

static func populate(view: Control, s: Dictionary) -> void:
	for child in view.world.get_children(): child.free()
	var bg: Dictionary = view.state.background
	var background: Sprite2D = view.image_node(bg.asset,Vector2(bg.position[0],bg.position[1]))
	background.name = "DynamicCaveBackground"
	background.scale = Vector2(bg.size[0],bg.size[1])/background.texture.get_size()
	for record in view.state.draw_list:
		if record.asset.begins_with("assembled/cliff_"):
			view.image_node(record.asset,Vector2(record.position[0],record.position[1]))
	for x in range(Placement.SIZE.x):
		if not s.water.has(Vector2i(x,0)): piece(view,"perimeter/edge_nw.png",Layout.project(Vector2(x,1)))
	for y in range(Placement.SIZE.y):
		if not s.water.has(Vector2i(31,y)): piece(view,"perimeter/edge_ne.png",Layout.project(Vector2(31,y+1)))
	for kind in ["floor","water","road"]:
		for y in range(18):
			for x in range(32):
				var c := Vector2i(x,y)
				if kind=="water" and not s.water.has(c): continue
				if kind=="road" and (not s.road_cells.has(c) or s.water.has(c)): continue
				var index: int = view.terrain_data.cell_index[str(x)+","+str(y)]
				var texture := AtlasTexture.new()
				texture.atlas = view.texture(ART+kind+"_cells.png")
				texture.region = Rect2((index%16)*130,(index/16)*66,130,66)
				texture.filter_clip = true
				var tile := Sprite2D.new()
				tile.centered = false; tile.texture = texture
				tile.position = Layout.project(Vector2(c))+Vector2(-1,-33)
				view.world.add_child(tile)
		if kind!="floor":
			# Water remains beneath bridge decks. Roads terminate at the bank.
			var cells: Dictionary = s.water if kind=="water" else s.road_cells.duplicate()
			if kind=="road":
				for c in s.water: cells.erase(c)
			edges(view,kind,cells)
	piece(view,"terrain/entrance_external_road.png",Layout.project(Vector2(0,9)))
	bridges(view,s)
	var objects: Array = []
	for b in s.buildings: building(view,s,b,objects)
	for trap in s.traps:
		var cell := Vector2(trap.cell[0]+.5,trap.cell[1]+.5)
		objects.append(record("traps/"+str(trap.kind)+".png",Layout.project(cell)))
	# Stage-one occupants remain visual samples. Newly computed defense sites
	# are empty GPT highlights; assigning units/combat belongs to the next stage.
	var original := Layout.cells(view.state,"m")
	for id in s.defense_points:
		for c in s.defense_points[id]:
			var b := Placement.building(s,id)
			var unchanged := false
			for old in view.state.buildings:
				if old.id==b.id and b.rect==Rect2i(old.rect[0],old.rect[1],old.rect[2],old.rect[3]): unchanged = true
			if unchanged and c in original:
				objects.append(record("monsters/"+(["slime","goblin"][(c.x+c.y)%2])+".png",Layout.project(Vector2(c)+Vector2(.5,.5)),2))
			else:
				var highlight: Sprite2D = view.cell_highlight(view.world,c,Color(.9,.65,.15,.7))
				highlight.set_meta("defense_site",id)
	for i in range(objects.size()): objects[i]["insertion"] = i
	objects.sort_custom(func(a,b): return a.depth<b.depth or (a.depth==b.depth and a.insertion<b.insertion))
	for r in objects: piece(view,r.asset,r.anchor)
	piece(view,"bridge/entrance_bridge.png",Layout.project(Vector2(-1.7,9)))

static func record(asset: String, anchor: Vector2, extra: float = 0) -> Dictionary:
	return {"asset":asset,"anchor":anchor,"depth":anchor.y+extra}

static func piece(view: Control, asset: String, anchor: Vector2, parent: Node = null) -> Sprite2D:
	var pivot: Array = view.state.assets[asset].pivot
	var sprite: Sprite2D = view.image_node(asset,(anchor-Vector2(pivot[0],pivot[1])).round())
	if parent!=null: sprite.reparent(parent)
	return sprite

static func edges(view: Control, kind: String, cells: Dictionary) -> void:
	var runs := {}
	for c: Vector2i in cells:
		for spec in [[Vector2i.UP,"x",c.y,c.x],[Vector2i.DOWN,"x",c.y+1,c.x],[Vector2i.LEFT,"y",c.x,c.y],[Vector2i.RIGHT,"y",c.x+1,c.y]]:
			if cells.has(c+spec[0]): continue
			var key := str(spec[1])+":"+str(spec[2])
			if not runs.has(key): runs[key] = []
			runs[key].append(spec[3])
	var keys: Array = runs.keys(); keys.sort()
	for key in keys:
		var values: Array = runs[key]; values.sort()
		var axis: String = key.split(":")[0]
		var fixed := int(key.split(":")[1])
		var phase := 0
		var previous := -999
		for v in values:
			if v!=previous+1: phase = 0
			var a := Vector2(v,fixed) if axis=="x" else Vector2(fixed,v)
			var pa := Layout.project(a)
			var side := "up" if axis=="x" else "down"
			var sprite := Sprite2D.new()
			sprite.texture = view.texture(ART+kind+"_"+side+"_"+str(phase%4)+".png")
			sprite.centered = false
			sprite.position = pa+Vector2(0,-35 if side=="up" else -3)
			view.world.add_child(sprite)
			phase += 1; previous = v
	for y in range(19):
		for x in range(33):
			var q := [cells.has(Vector2i(x-1,y-1)),cells.has(Vector2i(x,y-1)),cells.has(Vector2i(x,y)),cells.has(Vector2i(x-1,y))]
			var count := q.count(true)
			if count in [1,3]:
				var type := "outer" if count==1 else "inner"
				var index := q.find(count==1)
				piece(view,kind+"/"+type+"_corner_q"+str(index)+".png",Layout.project(Vector2(x,y)))

static func bridges(view: Control, s: Dictionary) -> void:
	var seen := {}
	for c: Vector2i in s.bridges:
		if seen.has(c): continue
		var todo: Array = [c]
		var lo := c; var hi := c
		while not todo.is_empty():
			var t: Vector2i = todo.pop_back()
			if seen.has(t) or not s.bridges.has(t): continue
			seen[t] = true
			lo = Vector2i(mini(lo.x,t.x),mini(lo.y,t.y)); hi = Vector2i(maxi(hi.x,t.x),maxi(hi.y,t.y))
			for d in Placement.Roads.DIRS: todo.append(t+d)
		for y in range(lo.y,hi.y+1,2):
			for x in range(lo.x,hi.x+1,2):
				var bridge := piece(view,"bridge/bridge_water_y.png",Layout.project(Vector2(x+1,y+1)))
				if s.bridges[c]=="y":
					bridge.flip_h = true

static func building(view: Control, s: Dictionary, b: Dictionary, objects: Array, parent: Node = null) -> void:
	if b.kind=="entrance":
		objects.append(record("interiors/entrance.png",Layout.project(Vector2(.25,9)),5)); return
	var d: Dictionary = s.doors[b.id]
	var r: Rect2i = b.rect
	var gap: Array = d.cells
	for c in gap:
		var threshold := piece(view,"building/threshold.png",Layout.project(Vector2(c)+Vector2(.5,.5)),parent)
		if parent!=null: threshold.modulate.a = .48
	for x in range(r.position.x,r.end.x):
		if not (d.side=="N" and Vector2i(x,r.position.y) in gap): objects.append(record("building/back_nw.png",Layout.project(Vector2(x,r.position.y+1))))
		if not (d.side=="S" and Vector2i(x,r.end.y-1) in gap): objects.append(record("building/front_se.png",Layout.project(Vector2(x,r.end.y))))
	for y in range(r.position.y,r.end.y):
		if not (d.side=="E" and Vector2i(r.end.x-1,y) in gap): objects.append(record("building/back_ne.png",Layout.project(Vector2(r.end.x-1,y+1))))
		if not (d.side=="W" and Vector2i(r.position.x,y) in gap): objects.append(record("building/front_sw.png",Layout.project(Vector2(r.position.x,y+1))))
	objects.append(record("building/back_corner.png",Layout.project(Vector2(r.end.x-1,r.position.y+1))))
	objects.append(record("building/front_corner.png",Layout.project(Vector2(r.position.x,r.end.y))))
	var door := Vector2(d.cells[0])+Vector2(1,0) if d.side in ["N","S"] else Vector2(d.cells[0])+Vector2(0,1)
	if d.side=="S": door.y += 1
	if d.side=="E": door.x += 1
	objects.append(record("building/door_arch_"+str(view.door_data.face_table[d.side].arch)+".png",Layout.project(door),1))
	var center_depth := Layout.project(Vector2(r.position)+Vector2(r.size)/2).y+12
	var interior := record("interiors/"+b.kind+".png",Layout.project(Vector2(r.position.x,r.end.y)))
	interior.depth = center_depth
	objects.append(interior)
