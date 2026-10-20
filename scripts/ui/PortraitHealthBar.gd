extends TextureProgressBar
## C artwork assembly. Animation is presentation time, independent of combat math.
const ART := "res://assets/ui/v130r/hpbar/C/"
const Presentation = preload("res://scripts/map_builder/ApprovedActorPresentation.gd")
const MonsterCards = preload("res://scripts/map_builder/ApprovedMonsterPlacementUI.gd")
const BOUNDS := Rect2(-50,-28,100,42)
static var thumbnails := {}
var unit: Node
var ghost_ratio := 1.0
var previous_ratio := 1.0
var ghost_wait := 0.0
var heal_flash := 0.0
var recent_combat := 0.0
var portrait_path := ""
var portrait_group: Control
var portrait: TextureRect
var ribbon: NinePatchRect
var ghost_clip: Control
var fill_clip: Control
var shield_clip: Control
var fill_art: NinePatchRect
var sockets: Array[TextureRect] = []
var status_icons: Array[TextureRect] = []
var level_text: Label
var status_key := []

func art(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = load(path); image.position = rect.position; image.size = rect.size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(image)
	return image

func patch(parent: Node, part: String, rect: Rect2, margins: Vector2 = Vector2(49,49)) -> NinePatchRect:
	var image := NinePatchRect.new(); image.texture = load(ART+part+".png")
	image.position = rect.position
	# Source cap widths stay intact; rendered caps follow the bar height.
	image.region_rect = Rect2(Vector2.ZERO,image.texture.get_size())
	var factor := rect.size.y/image.texture.get_height()
	image.size = Vector2(rect.size.x/factor,image.texture.get_height()); image.scale = Vector2.ONE*factor
	image.patch_margin_left = roundi(margins.x); image.patch_margin_right = roundi(margins.y)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(image)
	return image

func layer(part: String, y: float, height: float) -> Control:
	var clip := Control.new(); clip.position = Vector2(7,y); clip.size = Vector2(50,height)
	clip.clip_contents = true; clip.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(clip)
	patch(clip,part,Rect2(0,0,50,height))
	return clip

static func portrait_source(actor: Node) -> String:
	var species: String = actor.unit_id
	if actor.faction=="monster":
		var card := "res://assets/sprites/v130r/%s/portrait_%s_card.png" % [species,species]
		if ResourceLoader.exists(card): return card
		if MonsterCards.PORTRAITS.has(species): return "res://assets/sprites/portraits/"+MonsterCards.PORTRAITS[species]+".png"
	var definition: Dictionary = DataRegistry.enemies.get(species,{})
	var direct = definition.get("portrait","")
	if direct is Dictionary: direct = direct.get("base","")
	if str(direct)!="" and ResourceLoader.exists(str(direct)): return str(direct)
	if species=="official_hero_leon": return "res://assets/sprites/portraits/campaign/CHR_HERO_LEON_OFFICIAL_portrait_final.png"
	for character_id in DataRegistry.characters:
		var character: Dictionary = DataRegistry.characters[character_id]
		var ref = character.get("unit_ref",{})
		if (ref is Dictionary and ref.get("id","")==species and ref.get("dataset","")=="enemies") or character_id==definition.get("character_id",""):
			var path: String = character.get("portrait",{}).get("base","")
			if ResourceLoader.exists(path): return path
	# Existing enemy inspector portrait: one live idle frame, never the sheet.
	return "idle_frame:"+species

static func thumbnail(actor: Node, path: String) -> Texture2D:
	if not thumbnails.has(path):
		var source: Texture2D = actor.idle_frame if path.begins_with("idle_frame:") else load(path)
		var image := source.get_image()
		var used := image.get_used_rect()
		image = image.get_region(used)
		# Square face crop from existing portrait; no generated replacement art.
		var side := mini(image.get_width(),image.get_height())
		image = image.get_region(Rect2i((image.get_width()-side)/2,0,side,side))
		image.resize(64,64,Image.INTERPOLATE_LANCZOS)
		thumbnails[path] = ImageTexture.create_from_image(image)
	return thumbnails[path]

func setup(actor: Node) -> void:
	unit = actor; position = Vector2(-24,-6); size = Vector2(64,8)
	nine_patch_stretch = true; mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var kind := "boss" if actor.unit_id in Presentation.BOSSES else "ally" if actor.faction=="monster" else "enemy"
	patch(self,"frame_"+kind,Rect2(0,0,64,8),Vector2(91,53) if kind=="boss" else Vector2(49,49))
	ghost_clip = layer("damage_orange",2,4)
	fill_clip = layer("fill_"+kind,2,4); fill_art = fill_clip.get_child(0)
	shield_clip = layer("shield",-1,3); shield_clip.hide()
	ribbon = patch(self,"name_ribbon_compact",Rect2(-4,-22,78,19),Vector2(48,48))
	actor.name_label.reparent(self,false)
	actor.name_label.position = Vector2(3,-22); actor.name_label.size = Vector2(64,18)
	actor.name_label.add_theme_font_size_override("font_size",12)
	actor.name_label.add_theme_constant_override("outline_size",1)
	actor.name_label.add_theme_color_override("font_color",Color("#fff3d9"))
	portrait_group = Control.new(); portrait_group.position = Vector2(-26,-8)
	portrait_group.size = Vector2(26,28); portrait_group.pivot_offset = Vector2(13,14)
	portrait_group.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(portrait_group)
	portrait_path = portrait_source(actor)
	portrait = art(portrait_group,ART+"portrait_frame.png",Rect2(4,6,18,18))
	portrait.texture = thumbnail(actor,portrait_path)
	var material := ShaderMaterial.new(); material.shader = preload("res://scripts/ui/hpbar_portrait.gdshader")
	portrait.material = material
	art(portrait_group,ART+"portrait_frame.png",Rect2(0,0,26,28))
	var level := art(portrait_group,ART+"level_badge.png",Rect2(17,17,11,11))
	level_text = Label.new(); level_text.size = Vector2(11,11)
	level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; level_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_text.add_theme_font_override("font",preload("res://assets/fonts/NEXON_Maplestory_Light.otf"))
	level_text.add_theme_font_size_override("font_size",7); level_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_child(level_text)
	for i in range(4):
		var socket := art(self,ART+"status_socket.png",Rect2(14+i*9,10,8,8)); sockets.append(socket)
		var icon := art(socket,"res://assets/ui/kit/icons/icon_hp_64.png",Rect2(2,2,4,4)); icon.hide(); status_icons.append(icon)
	if kind=="boss": art(self,ART+"boss_ornament.png",Rect2(48,-22,12,14))
	previous_ratio = clampf(float(unit.hp)/maxi(1,unit.max_hp),0,1); ghost_ratio = previous_ratio
	sync(0)

func sync(delta: float) -> void:
	var ratio := clampf(float(unit.hp)/maxi(1,unit.max_hp),0,1)
	if ratio<previous_ratio:
		ghost_ratio = maxf(ghost_ratio,previous_ratio); ghost_wait = .4; recent_combat = 3
	elif ratio>previous_ratio:
		heal_flash = .35; ghost_ratio = ratio; ghost_wait = 0
	else:
		var remainder := maxf(0,delta-ghost_wait)
		ghost_wait = maxf(0,ghost_wait-delta)
		if ghost_wait<=0: ghost_ratio = move_toward(ghost_ratio,ratio,remainder*1.8)
	previous_ratio = ratio; value = ratio*100
	heal_flash = maxf(0,heal_flash-delta); recent_combat = maxf(0,recent_combat-delta)
	fill_clip.size.x = 50*ratio; ghost_clip.size.x = 50*ghost_ratio
	fill_art.modulate = Color.WHITE.lerp(Color(.45,2,1),heal_flash/.35)
	var barrier: int = unit.duo_barrier+(unit.patch_plate_barrier if unit.patch_plate_barrier_timer>0 else 0)+(unit.mori_barrier if unit.mori_barrier_timer>0 else 0)
	shield_clip.visible = barrier>0 or unit.shield_timer>0
	shield_clip.size.x = 50*clampf(float(barrier)/maxi(1,unit.max_hp) if barrier>0 else unit.damage_reduction,0,1)
	var level := 1
	if unit.faction=="monster": level = int(unit.battle_runtime.root.monster_roster.get(unit.unit_id,{}).get("level",1))
	else: level = int(DataRegistry.enemies.get(unit.unit_id,{}).get("level",1))
	level_text.text = str(level)
	var statuses := [barrier>0 or unit.shield_timer>0,unit.root_timer>0 or unit.seal_move_lock_timer>0,unit.slow_timer>0,unit.armor_break_timer>0 or unit.acid_zone_timer>0 or unit.bounty_mark_timer>0]
	if statuses!=status_key:
		status_key = statuses
		for i in range(4):
			status_icons[i].visible = statuses[i]
			status_icons[i].texture = load("res://assets/ui/kit/icons/icon_"+["garrison","lock","speed","warning"][i]+"_64.png")
	visible = unit.is_alive()

func set_crowded(crowded: bool) -> void:
	portrait_group.scale = Vector2.ONE*(.85 if crowded else 1.0)

func should_show() -> bool:
	return unit.is_alive() and (not UISettings.hide_noncombat_hp_bars or unit.selected or unit.unit_id in Presentation.BOSSES or recent_combat>0 or heal_flash>0 or shield_clip.visible or status_key.has(true) or unit.attack_anim_timer>0 or unit.skill_anim_timer>0 or (is_instance_valid(unit.target) and unit.target.is_alive()))
