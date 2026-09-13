extends RefCounted

# Describes starting placements only; this is not a strength score or battle prediction.
static func selected_route(game: Node) -> Dictionary:
	var route: Dictionary = {}
	for candidate in game.maze_route_forecasts:
		if str(candidate.id) == str(game.maze_route_id):
			route = candidate
			break
	if route.is_empty():
		return {"text":"현재 선택할 예상 진입로가 없습니다.","tooltip":"오늘의 침입 일정과 성 구조를 기준으로 표시합니다.","count":0,"known":false,"members":[]}
	var rooms: Array = game.graph.path_between(str(route.spawn_room_id),str(route.target_room_id))
	var zone_ids: Array[String] = []
	var zone_names: Array[String] = []
	for zone in game.graph.layout.get("combat_topology",{}).get("defense_zones",[]):
		var overlaps := false
		for room_id in zone.get("room_ids",[]):
			if rooms.has(room_id): overlaps = true
		if rooms.has(str(zone.get("anchor_room_id",""))): overlaps = true
		if overlaps:
			zone_ids.append(str(zone.zone_id))
			zone_names.append(game._maze_zone_name(str(zone.zone_id)))
	var members: Array[String] = []
	var details: Array[String] = []
	for id in game.maze_deployments:
		var placement: Dictionary = game.maze_deployments[id]
		if not zone_ids.has(str(placement.get("defense_zone_id",""))): continue
		var member := "%s Lv.%d" % [game._monster_companion_name(str(id)),int(game.monster_roster.get(id,{}).get("level",1))]
		members.append(member)
		details.append("%s · %s" % [member,game._maze_zone_name(str(placement.defense_zone_id))])
	var headline := "초기 배치 없음 · 이 경로의 방어 구역을 확인하세요."
	if not members.is_empty():
		var shown: Array = members.slice(0,2)
		headline = "초기 배치 · " + " / ".join(shown)
		if members.size() > 2: headline += " 외 %d명" % (members.size()-2)
	var note := "경로상 방어 구역 %d곳 · 교전과 명령에 따라 동료가 이동합니다." % zone_ids.size()
	if rooms.is_empty() or zone_ids.is_empty():
		headline = "이 경로의 방어 구역 연결 정보를 확인할 수 없습니다."
		note = "예상 진입로와 현재 성 구조를 확인하세요."
	return {"text":headline+"\n"+note,"tooltip":"방어 구역: "+" / ".join(zone_names)+"\n"+"\n".join(details)+"\n현재 초기 배치만 표시합니다. 사거리·지원 합류·승패를 예측하지 않습니다.","count":members.size(),"members":members,"known":not rooms.is_empty() and not zone_ids.is_empty()}

static func refresh(game: Node) -> void:
	var label := game.ui_layer.find_child("MazePreparationSummary",true,false) as Label
	if label == null: return
	var summary := selected_route(game)
	label.text = str(summary.text)
	label.tooltip_text = str(summary.tooltip)
	label.add_theme_color_override("font_color",Color("#e8bd76") if bool(summary.known) and int(summary.count)==0 else Color("#c0b2c6"))
