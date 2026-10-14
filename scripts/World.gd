class_name WorldLogic
extends Node

const SUCK_TIME := 0.35
const SUCK_INTERVAL := 0.45
const WIN_DELAY := 0.9
const STUCK_TIME := 3.0
const WANDER_SPEED := 10.0
const PICK_RADIUS := 24.0

signal event_fired(ev: String)
signal status_changed(s: String)
signal goo_smashed(pos: Vector2, color: Color)

var level: LevelData
var level_root: Node2D

var goos: Array[GooNode] = []
var strands: Array[StrandNode] = []
var terrain_bodies: Array[StaticBody2D] = []

var _next_id: int = 1
var _rng := RandomNumberGenerator.new()

var game_time: float = 0.0
var moves: int = 0
var collected: int = 0
var status: String = "playing"
var final_balls: int = 0
var dragging: GooNode = null
var history: Array = []

var hazard_nodes: Array = []  # Array[HazardNode] — set by Game after HazardLayer.setup()

var _win_timer: float = -1.0
var _still_timer: float = 0.0
var _suck_clock: float = 0.0
var _node_vel: Dictionary = {}  # goo_id -> Vector2
var _trace_goo: GooNode = null
var _trace_t: float = 0.0
var _drag_vel: Vector2 = Vector2.ZERO
var _drag_prev_pos: Vector2 = Vector2.ZERO


func setup(ld: LevelData, root: Node2D) -> void:
	level = ld
	level_root = root
	_rng.seed = 1

	_build_terrain()
	_build_structure()
	_spawn_free()


# ─── Build ───────────────────────────────────────────────────────────────────

func _build_terrain() -> void:
	for t in level.terrain:
		var pts: Array = t.get("polyline", [])
		for i in range(pts.size() - 1):
			var a := level.to_vec2(pts[i])
			var b := level.to_vec2(pts[i + 1])
			_add_segment(a, b)
	# invisible side walls
	var h := float(level.height)
	_add_segment(Vector2(0, -400), Vector2(0, h + 400))
	_add_segment(Vector2(level.width, -400), Vector2(level.width, h + 400))


func _add_segment(a: Vector2, b: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var seg := SegmentShape2D.new()
	seg.a = a
	seg.b = b
	shape.shape = seg
	body.collision_layer = GooNode.LAYER_TERRAIN
	body.collision_mask = GooNode.LAYER_STRUCTURE | GooNode.LAYER_FREE | GooNode.LAYER_TERRAIN
	body.add_child(shape)
	level_root.add_child(body)
	terrain_bodies.append(body)


func _build_structure() -> void:
	var placed: Array[GooNode] = []
	for n in level.nodes:
		var state: String = "anchor" if n.get("anchor", false) else "node"
		var g := _new_goo(n.get("kind", "common"), level.to_vec2(n.get("pos", [0, 0])), state)
		g.is_source = n.get("source", true)
		placed.append(g)
	for pair in level.strands:
		var a := placed[int(pair[0])]
		var b := placed[int(pair[1])]
		var rest: float = a.position.distance_to(b.position)
		_link(a, b, rest)


func _spawn_free() -> void:
	for spec in level.free_goo:
		var n: int = int(spec.get("count", 1))
		var xrange: Array = spec.get("x", [0, 100])
		var x0 := float(xrange[0])
		var x1 := float(xrange[1])
		var k: String = spec.get("kind", "common")
		for i in range(n):
			var x := x0 + (x1 - x0) * (i + 0.5) / n if n > 1 else (x0 + x1) * 0.5
			var y: float = _ground_y(x) - float(GooTypes.get_type(k).get("radius", 12.0)) - 2.0
			_new_goo(k, Vector2(x, y), "free")


func _ground_y(x: float) -> float:
	# cast a ray downward to find terrain
	var space := level_root.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.new()
	query.from = Vector2(x, 0)
	query.to = Vector2(x, float(level.height))
	query.collision_mask = GooNode.LAYER_TERRAIN
	var result := space.intersect_ray(query)
	if result:
		return result.position.y
	return float(level.height) - 10.0


func _new_goo(kind: String, pos: Vector2, state: String) -> GooNode:
	var g := GooNode.new()
	level_root.add_child(g)
	g.setup(_next_id, kind, pos, state)
	_next_id += 1
	goos.append(g)

	if state == "free":
		g.wander_t = _rng.randf_range(0.2, 1.2)
		g.wander_dir = 0.0

	return g


# ─── Queries ─────────────────────────────────────────────────────────────────

func free_goos() -> Array:
	return goos.filter(func(g): return g.goo_state == "free")


func usable_balls_left() -> int:
	return goos.filter(func(g): return g.goo_state in ["free", "drag"] and g.kind != "fire").size()


func max_speed() -> float:
	var s := 0.0
	for g in goos:
		if g.goo_state in ["node", "free"] and not g.freeze:
			s = maxf(s, g.linear_velocity.length())
	return s


# ─── Player interaction ───────────────────────────────────────────────────────

func pick(pos: Vector2) -> GooNode:
	var best: GooNode = null
	var bd := PICK_RADIUS
	for g in goos:
		if g.goo_state == "free" or (g.goo_state == "node" and g.goo_type.get("movable", false)):
			var d := g.position.distance_to(pos)
			if d <= maxf(bd, g.goo_type.radius + 6.0) and d <= bd + g.goo_type.radius:
				if best == null or d < bd:
					best = g
					bd = d
	return best


func begin_drag(g: GooNode) -> bool:
	if status != "playing" or dragging != null or g == null:
		return false
	print("PICK id=", g.goo_id, " kind=", g.kind, " state=", g.goo_state, " pos=", g.position.snapped(Vector2.ONE))
	g.origin = g.position
	_node_vel.erase(g.goo_id)
	_drag_vel = Vector2.ZERO
	_drag_prev_pos = g.position
	for s in g.strands.duplicate():
		_remove_strand(s, "break")
	g.set_goo_state("drag")
	dragging = g
	emit_signal("event_fired", "pick")
	return true


func drag_to(pos: Vector2) -> void:
	if dragging == null:
		return
	var x := clampf(pos.x, 0.0, float(level.width))
	var y := clampf(pos.y, 0.0, float(level.height))
	var clamped := Vector2(x, y)
	var raw_vel := (clamped - _drag_prev_pos) * 60.0
	_drag_vel = _drag_vel.lerp(raw_vel, 0.25)
	_drag_prev_pos = clamped
	dragging.move_drag(clamped)


func preview(pos: Vector2) -> Array:
	var g := dragging
	if g == null:
		return []
	var gt := g.goo_type
	if gt.get("max_links", 0) == 0 or gt.get("burns", false):
		return []
	var cands := _structure_candidates(pos, gt, g)
	if cands.size() < int(gt.get("min_links", 1)):
		return []
	return cands.slice(0, int(gt.get("max_links", 2)))


func release(pos: Vector2 = Vector2.INF) -> Dictionary:
	var g := dragging
	if g == null:
		return {"ok": false, "reason": "nothing"}
	if pos != Vector2.INF:
		drag_to(pos)
	dragging = null

	var gt := g.goo_type
	g.set_goo_state("free")

	if gt.get("burns", false):
		var burned := _ignite_near(g.position)
		if burned > 0:
			_kill(g, "burn")
			moves += 1
			history.append({"goo": null, "irreversible": true})
			return {"ok": true, "reason": "burn", "burned": burned}
		_drop_free(g)
		return {"ok": false, "reason": "nothing_to_burn"}

	var cands := _structure_candidates(g.position, gt, g)
	print("DROP id=", g.goo_id, " kind=", g.kind, " pos=", g.position.snapped(Vector2.ONE), " cands=", cands.size(), " min=", gt.get("min_links",1))

	if gt.get("sticks_to_terrain", false) and _touching_terrain(g.position, gt.radius + 6.0):
		return _stick_to_terrain(g, cands)

	print("release cands=", cands.size(), " min_links=", gt.get("min_links",1), " kind=", g.kind)
	if cands.size() < int(gt.get("min_links", 1)):
		_drop_free(g)
		return {"ok": false, "reason": "no_target"}

	var too_close := cands.filter(func(c): return g.position.distance_to(c.position) < (gt.radius + c.goo_type.radius) * 0.9)
	if too_close.size() > 0 or _blocked(g.position, gt.radius, g):
		_drop_free(g)
		return {"ok": false, "reason": "blocked"}

	return _attach(g, cands, gt)


func undo() -> bool:
	if dragging != null or history.is_empty():
		return false
	var h: Dictionary = history.pop_back()
	var g: GooNode = h.get("goo")
	if g == null or h.get("irreversible", false) or not g.alive:
		return false
	for s in g.strands.duplicate():
		_remove_strand(s, "")
	if h.get("anchor", false):
		g.stuck_to_terrain = false
	g.set_goo_state("free")
	g.position = h.get("origin", g.position)
	g.linear_velocity = Vector2.ZERO
	moves = maxi(0, moves - 1)
	emit_signal("event_fired", "undo")
	return true


# ─── Internal placement helpers ───────────────────────────────────────────────

func _structure_candidates(pos: Vector2, gt: Dictionary, exclude: GooNode) -> Array:
	var out := []
	for g in goos:
		if g == exclude or not g.in_structure():
			continue
		var d := g.position.distance_to(pos)
		if d <= float(gt.get("attach_range", 90.0)):
			out.append(g)
	out.sort_custom(func(a, b): return a.position.distance_to(pos) < b.position.distance_to(pos))
	return out


func _blocked(pos: Vector2, radius: float, _ignore: GooNode) -> bool:
	var space := level_root.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = GooNode.LAYER_TERRAIN
	return not space.intersect_point(query).is_empty()


func _touching_terrain(pos: Vector2, dist: float) -> bool:
	var space := level_root.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = GooNode.LAYER_TERRAIN
	return not space.intersect_point(query).is_empty()


func _drop_free(g: GooNode) -> void:
	var drop_pos := g.position
	g.set_goo_state("free")
	PhysicsServer2D.body_set_state(g.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, drop_pos))
	var throw_vel := _drag_vel.limit_length(1200.0)
	PhysicsServer2D.body_set_state(g.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, throw_vel)
	g.origin = drop_pos
	g.wander_t = 0.6
	print("FREE id=", g.goo_id, " pos=", g.position.snapped(Vector2.ONE))
	_trace_goo = g
	_trace_t = 0.0


func _attach(g: GooNode, cands: Array, gt: Dictionary) -> Dictionary:
	g.set_goo_state("node")
	var max_l: int = gt.get("max_links", 2)
	var slice := cands.slice(0, maxi(1, max_l))
	print("_attach: max_l=", max_l, " cands=", cands.size(), " slice=", slice.size())
	var links := 0
	for c in slice:
		var d := g.position.distance_to(c.position)
		var rest := clampf(d, float(gt.get("min_len", 34.0)), float(gt.get("max_len", 80.0)))
		print("  link->id=", c.goo_id, " state=", c.goo_state, " d=", snappedf(d,1.0), " rest=", snappedf(rest,1.0))
		_link(g, c, rest)
		links += 1
	print("  total links=", links, " g.strands=", g.strands.size())
	moves += 1
	history.append({"goo": g, "strands": g.strands.duplicate(), "origin": g.origin})
	emit_signal("event_fired", "stick")
	return {"ok": true, "reason": "attached", "links": links}


func _stick_to_terrain(g: GooNode, cands: Array) -> Dictionary:
	g.set_goo_state("anchor")
	g.stuck_to_terrain = true
	g.is_source = false
	var links := 0
	var gt := g.goo_type
	for c in cands.slice(0, maxi(1, int(gt.get("max_links", 2)))):
		var d := g.position.distance_to(c.position)
		var rest := clampf(d, float(gt.get("min_len", 34.0)), float(gt.get("max_len", 80.0)))
		_link(g, c, rest)
		links += 1
	moves += 1
	history.append({"goo": g, "strands": g.strands.duplicate(), "origin": g.origin, "anchor": true})
	emit_signal("event_fired", "stick")
	return {"ok": true, "reason": "stuck", "links": links}


func _ignite_near(pos: Vector2) -> int:
	var burned := 0
	for g in goos:
		if g.goo_state in ["node", "free"] and g.kind != "fire":
			if g.position.distance_to(pos) < 38.0:
				g.set_goo_state("burning")
				g.burn_timer = 1.4
				burned += 1
	return burned


# ─── Strands ──────────────────────────────────────────────────────────────────

func _link(a: GooNode, b: GooNode, rest: float) -> StrandNode:
	var s := StrandNode.new()
	# position the joint at midpoint (cosmetic only)
	s.position = (a.position + b.position) * 0.5
	level_root.add_child(s)
	s.setup(a, b, rest)
	strands.append(s)
	return s


func _remove_strand(s: StrandNode, ev: String) -> void:
	if not strands.has(s):
		return
	strands.erase(s)
	s.goo_a.strands.erase(s)
	s.goo_b.strands.erase(s)
	s.queue_free()
	if ev != "":
		emit_signal("event_fired", ev)
	for g in [s.goo_a, s.goo_b]:
		if g.goo_state == "node" and g.strands.is_empty():
			_to_free(g)


func _to_free(g: GooNode) -> void:
	var v: Vector2 = _node_vel.get(g.goo_id, Vector2.ZERO)
	_node_vel.erase(g.goo_id)
	g.set_goo_state("free")
	g.linear_velocity = v
	g.wander_t = 0.5


# ─── Simulation tick (called from Game._physics_process) ─────────────────────

func tick(delta: float) -> void:
	if status != "playing":
		return
	game_time += delta
	_apply_spring_forces(delta)
	_wander(delta)
	if _trace_goo != null and is_instance_valid(_trace_goo):
		_trace_t += delta
		if _trace_t >= 0.1 and _trace_t < 0.11:
			print("  trace +100ms id=", _trace_goo.goo_id, " pos=", _trace_goo.position.snapped(Vector2.ONE), " state=", _trace_goo.goo_state)
		elif _trace_t >= 0.2 and _trace_t < 0.21:
			print("  trace +200ms id=", _trace_goo.goo_id, " pos=", _trace_goo.position.snapped(Vector2.ONE), " state=", _trace_goo.goo_state)
		elif _trace_t >= 0.3:
			print("  trace +300ms id=", _trace_goo.goo_id, " pos=", _trace_goo.position.snapped(Vector2.ONE), " state=", _trace_goo.goo_state)
			_trace_goo = null
	_break_strands()
	_hazards(delta)
	_pipe(delta)
	_check_end(delta)


func _apply_spring_forces(delta: float) -> void:
	const GRAVITY := 900.0
	const DAMP := 3.0

	# ensure velocity entries exist for all node balls
	for g in goos:
		if g.goo_state == "node" and not _node_vel.has(g.goo_id):
			_node_vel[g.goo_id] = Vector2.ZERO

	# accumulate forces: gravity first
	var forces: Dictionary = {}
	for g in goos:
		if g.goo_state == "node":
			forces[g.goo_id] = Vector2(0.0, GRAVITY * g.mass)

	# spring + damping forces
	for s in strands:
		if not is_instance_valid(s.goo_a) or not is_instance_valid(s.goo_b):
			continue
		var a: GooNode = s.goo_a
		var b: GooNode = s.goo_b
		var dp: Vector2 = b.position - a.position
		var cur_len: float = dp.length()
		if cur_len < 0.001:
			continue
		var dir: Vector2 = dp / cur_len
		var extension: float = cur_len - s.rest_len
		var spring_f: float = s.stiffness * extension
		var vel_a: Vector2 = _node_vel.get(a.goo_id, Vector2.ZERO)
		var vel_b: Vector2 = _node_vel.get(b.goo_id, Vector2.ZERO)
		var rel_vel: float = (vel_b - vel_a).dot(dir)
		var crit: float = 2.0 * sqrt(s.stiffness * minf(a.mass, b.mass))
		var damp_f: float = s.damping_ratio * crit * rel_vel
		var f: float = spring_f + damp_f
		if a.goo_state == "node":
			forces[a.goo_id] = forces[a.goo_id] + dir * f
		if b.goo_state == "node":
			forces[b.goo_id] = forces[b.goo_id] - dir * f

	# integrate: velocity + position
	for g in goos:
		if g.goo_state != "node":
			continue
		var v: Vector2 = _node_vel[g.goo_id]
		v += forces[g.goo_id] / g.mass * delta
		v *= 1.0 / (1.0 + DAMP * delta)
		_node_vel[g.goo_id] = v
		g.position += v * delta
		# terrain floor clamp
		var radius := float(g.goo_type.get("radius", 12.0))
		var floor_y := _ground_y(g.position.x) - radius
		if g.position.y >= floor_y:
			g.position.y = floor_y
			if _node_vel[g.goo_id].y > 0.0:
				_node_vel[g.goo_id].y = 0.0


func _wander(delta: float) -> void:
	for g in goos:
		if g.goo_state != "free":
			continue
		g.wander_t -= delta
		if g.wander_t <= 0.0:
			g.wander_t = _rng.randf_range(0.6, 1.8)
			var choices := [-1.0, 0.0, 1.0, 1.0, -1.0]
			g.wander_dir = choices[_rng.randi() % choices.size()]
		if absf(g.linear_velocity.y) < 30.0 and g.wander_dir != 0.0:
			var impulse := Vector2(g.wander_dir * WANDER_SPEED * g.mass * 0.1, 0.0)
			g.apply_central_impulse(impulse)
		var wander_range := float(level.width) * 0.125
		var left_wall := maxf(20.0, g.origin.x - wander_range)
		var right_wall := minf(float(level.width) - 20.0, g.origin.x + wander_range)
		if g.position.x < left_wall and g.wander_dir < 0.0:
			g.wander_dir = -g.wander_dir
		elif g.position.x > right_wall and g.wander_dir > 0.0:
			g.wander_dir = -g.wander_dir


func _break_strands() -> void:
	for s in strands.duplicate():
		var cur: float = s.current_length()
		var limit: float = s.rest_len * s.break_ratio + 4.0
		if cur > limit:
			print("BREAK a=", s.goo_a.goo_id, " b=", s.goo_b.goo_id, " cur=", snappedf(cur,1.0), " limit=", snappedf(limit,1.0))
			_remove_strand(s, "break")


func _hazards(delta: float) -> void:
	var h := float(level.height)
	var w := float(level.width)
	for g in goos.duplicate():
		if g.goo_state in ["dead", "sucked", "sucked_done"]:
			continue
		var p: Vector2 = g.position
		if p.y > h + 80.0 or p.y < -80.0 or p.x < -80.0 or p.x > w + 80.0:
			_kill(g, "pop")
			continue
		if g.goo_state == "burning":
			g.burn_timer -= delta
			if g.burn_timer <= 0.0:
				_kill(g, "burn")
				continue
		# mechanical hazard collision
		for hazard in hazard_nodes:
			if g.goo_state == "dead":
				break
			if not is_instance_valid(hazard):
				continue
			var goo_r := float(g.goo_type.get("radius", 12.0))
			if g.position.distance_to(hazard.position) <= hazard.kill_radius() + goo_r:
				_kill_by_hazard(g, hazard)
				break


func _kill_by_hazard(g: GooNode, _hazard: HazardNode) -> void:
	if g.goo_state == "dead":
		return
	var pos   := g.position
	var color: Color = g.goo_type.get("color", Color(0.15, 0.15, 0.18))
	for s in g.strands.duplicate():
		_remove_strand(s, "")
	if g == dragging:
		dragging = null
	g.set_goo_state("dead")
	g.queue_redraw()
	g.hide()
	emit_signal("goo_smashed", pos, color)
	emit_signal("event_fired", "smash")


func _kill(g: GooNode, ev: String) -> void:
	if g.goo_state == "dead":
		return
	for s in g.strands.duplicate():
		_remove_strand(s, "")
	if g == dragging:
		dragging = null
	g.set_goo_state("dead")
	g.queue_redraw()
	g.hide()
	emit_signal("event_fired", ev)


func _pipe(delta: float) -> void:
	var pp := level.pipe_pos
	var pr := level.pipe_radius
	for g in goos:
		if g.goo_state == "free" and g.kind != "fire":
			if g.position.distance_to(pp) <= pr * 0.85:
				_suck(g)
	if pipe_connected():
		_suck_clock += delta
		if _suck_clock >= SUCK_INTERVAL:
			_suck_clock = 0.0
			var free := goos.filter(func(g): return g.goo_state == "free" and g.kind != "fire")
			if not free.is_empty():
				free.sort_custom(func(a, b): return a.position.distance_to(pp) < b.position.distance_to(pp))
				_suck(free[0])
	for g in goos:
		if g.goo_state == "sucked" and g.suck_timer >= SUCK_TIME:
			g.set_goo_state("sucked_done")
			g.hide()
			collected += 1
			emit_signal("event_fired", "collect")


func _suck(g: GooNode) -> void:
	for s in g.strands.duplicate():
		_remove_strand(s, "")
	g.set_goo_state("sucked")
	g.begin_suck(g.position, level.pipe_pos)
	emit_signal("event_fired", "suck")


func source_reachable() -> Array:
	var seen := []
	var frontier := goos.filter(func(g): return g.goo_state == "anchor" and g.is_source)
	while not frontier.is_empty():
		var g: GooNode = frontier.pop_back()
		if seen.has(g.goo_id):
			continue
		seen.append(g.goo_id)
		for s in g.strands:
			var o: GooNode = s.other(g)
			if not seen.has(o.goo_id) and o.in_structure():
				frontier.append(o)
	return seen


func pipe_connected() -> bool:
	var pp := level.pipe_pos
	var reach := level.pipe_radius * 1.15 + 10.0
	var near := goos.filter(func(g): return g.in_structure() and g.position.distance_to(pp) <= reach)
	if near.is_empty():
		return false
	var seen := source_reachable()
	return near.any(func(g): return seen.has(g.goo_id))


func _check_end(delta: float) -> void:
	if collected >= level.target:
		if _win_timer < 0.0:
			_win_timer = WIN_DELAY
		_win_timer -= delta
		if _win_timer <= 0.0:
			status = "won"
			var left := goos.filter(func(g): return g.goo_state in ["free", "node", "drag"] and g.kind != "fire").size()
			final_balls = collected + left
			emit_signal("event_fired", "win")
			emit_signal("status_changed", "won")
		return
	var in_flight := goos.filter(func(g): return g.goo_state == "sucked").size()
	if collected + in_flight + usable_balls_left() < level.target:
		_lose("not_enough_balls")
		return
	if free_goos().is_empty() and dragging == null and in_flight == 0:
		if max_speed() < 8.0:
			_still_timer += delta
		else:
			_still_timer = 0.0
		if _still_timer >= STUCK_TIME:
			_lose("out_of_goo")
	else:
		_still_timer = 0.0


func _lose(reason: String) -> void:
	status = "lost"
	emit_signal("event_fired", "lose")
	emit_signal("status_changed", "lost")
