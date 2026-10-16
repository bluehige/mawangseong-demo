extends RefCounted
## Screen geometry only. All visible borders and controls use existing GPT art.

static func unit(screen: Vector2) -> float:
	return minf(screen.x/1920.0,screen.y/1080.0)

static func panels(screen: Vector2) -> Dictionary:
	var u := unit(screen)
	return {"hud":Rect2(24*u,18*u,490*u,66*u),
		"tabs":Rect2(screen.x/2-285*u,18*u,570*u,74*u),
		"tools":Rect2(screen.x-220*u,18*u,196*u,66*u),
		"build":Rect2(screen.x/2-438*u,screen.y-180*u,876*u,170*u),
		"minimap":Rect2(screen.x-304*u,screen.y-246*u,280*u,222*u)}

static func cut(region: Rect2, obstacle: Rect2) -> Array[Rect2]:
	if not region.intersects(obstacle): return [region]
	var hit := region.intersection(obstacle)
	var result: Array[Rect2] = []
	for r in [Rect2(region.position,Vector2(hit.position.x-region.position.x,region.size.y)),
		Rect2(Vector2(hit.end.x,region.position.y),Vector2(region.end.x-hit.end.x,region.size.y)),
		Rect2(Vector2(hit.position.x,region.position.y),Vector2(hit.size.x,hit.position.y-region.position.y)),
		Rect2(Vector2(hit.position.x,hit.end.y),Vector2(hit.size.x,region.end.y-hit.end.y))]:
		if r.size.x>0.00001 and r.size.y>0.00001: result.append(r)
	return result

static func translations(screen: Vector2, targets: Array[Rect2], obstacles: Array[Rect2], zoom: float, margin: float) -> Array[Rect2]:
	var lo := Vector2(-INF,-INF); var hi := Vector2(INF,INF)
	for r in targets:
		lo = lo.max(Vector2.ONE*margin-r.position*zoom)
		hi = hi.min(screen-Vector2.ONE*margin-r.end*zoom)
	if hi.x<=lo.x or hi.y<=lo.y: return []
	var free: Array[Rect2] = [Rect2(lo,hi-lo)]
	for r in targets:
		for o in obstacles:
			# Overlap is forbidden precisely for this translation-space rectangle.
			var forbidden := Rect2(o.position-r.end*zoom,o.size+r.size*zoom)
			var next: Array[Rect2] = []
			for region in free: next.append_array(cut(region,forbidden))
			free = next
			if free.is_empty(): return []
	return free

static func solve(screen: Vector2, targets: Array[Rect2], ui: Dictionary) -> Dictionary:
	var margin := 8*unit(screen)
	var obstacles: Array[Rect2] = []
	for panel in ui.values(): obstacles.append(panel.grow(margin))
	var bounds := targets[0]
	for r in targets: bounds = bounds.merge(r)
	var upper := minf((screen.x-2*margin)/bounds.size.x,(screen.y-2*margin)/bounds.size.y)
	# Rectangle arrangements change feasibility only when two affine boundaries
	# cross. Test every such zoom event, descending: no local search assumption.
	var candidates: Array[float] = [upper]
	for axis in range(2):
		var lines: Array[Vector2] = [] # intercept + slope * zoom
		for r in targets:
			lines.append(Vector2(margin,-r.position[axis]))
			lines.append(Vector2(screen[axis]-margin,-r.end[axis]))
			for o in obstacles:
				lines.append(Vector2(o.position[axis],-r.end[axis]))
				lines.append(Vector2(o.end[axis],-r.position[axis]))
		for i in range(lines.size()):
			for j in range(i):
				var delta := lines[i].y-lines[j].y
				if absf(delta)<0.000001: continue
				var z := (lines[j].x-lines[i].x)/delta
				if z>0 and z<upper: candidates.append(z)
	candidates.sort(); candidates.reverse()
	for candidate in candidates:
		# 1e-5 zoom inset prevents floating-point contacts becoming occlusions.
		var z := candidate-0.00001
		var free := translations(screen,targets,obstacles,z,margin)
		if free.is_empty(): continue
		var preferred := screen*Vector2(.5,.48)-bounds.get_center()*z
		var offset := Vector2.ZERO; var distance := INF
		for region in free:
			var point := preferred.clamp(region.position,region.end)
			var d := point.distance_squared_to(preferred)
			if d<distance: offset = point; distance = d
		return {"zoom":z,"maximum":candidate,"offset":offset,"center":(screen/2-offset)/z,"margin":margin}
	return {}

static func free_rect(rect: Rect2, safe: Rect2, obstacles: Array[Rect2]) -> bool:
	if not safe.encloses(rect): return false
	for obstacle in obstacles:
		if rect.intersects(obstacle): return false
	return true
