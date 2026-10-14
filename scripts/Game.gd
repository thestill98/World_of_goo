extends Node2D

const LEVEL_PATH := "res://levels/"
const LEVEL_FILES: Array[String] = [
	"01_humble_tower.json",
	"02_the_gap.json",
	"03_balloon_lift.json",
	"04_burn_the_wall.json",
	"05_sticky_wall.json",
	"06_twin_peaks.json",
	"07_sky_high.json",
	"08_gear_gauntlet.json",
]

var world: WorldLogic
var level: LevelData
var _level_index: int = 0
var _hovered: GooNode = null

@onready var level_root: Node2D = $LevelRoot
@onready var camera: Camera2D = $Camera2D
@onready var hud_label: Label = $UI/HUD/Label
@onready var status_label: Label = $UI/HUD/StatusLabel


func _ready() -> void:
	_setup_debug_overlay()
	_setup_win_overlay()
	_setup_hint_label()

	# Find level index from GameState id, default to 0
	var target_id: String = GameState.current_level_id
	for i in range(LEVEL_FILES.size()):
		var data := LevelData.load_file(LEVEL_PATH + LEVEL_FILES[i])
		if data != null and data.id == target_id:
			_level_index = i
			break
	_load_level(_level_index)


func _setup_win_overlay() -> void:
	_win_overlay = WinOverlay.new()
	add_child(_win_overlay)
	_win_overlay.next_level_pressed.connect(_on_win_next)
	_win_overlay.retry_pressed.connect(_on_win_retry)
	_win_overlay.menu_pressed.connect(_on_win_menu)


func _setup_hint_label() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	_hint_label = Label.new()
	_hint_label.position = Vector2(0, 660)
	_hint_label.size     = Vector2(1280, 40)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.88, 0.80))
	_hint_label.visible = false
	cl.add_child(_hint_label)


func _setup_debug_overlay() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)

	_debug_label = Label.new()
	_debug_label.position = Vector2(980, 580)
	_debug_label.size     = Vector2(286, 120)
	_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_debug_label.add_theme_font_size_override("font_size", 12)
	_debug_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.88, 0.90))
	_debug_label.visible  = false
	cl.add_child(_debug_label)


var _decor: DecorLayer = null
var _hazard_layer: HazardLayer = null
var _particles: Array = []   # [{pos, vel, life, color}]
var _debug_label: Label = null
var _debug_visible: bool = false
var _debug_events: Array = []  # [{text, life}]

var _win_overlay: WinOverlay = null
var _elapsed: float = 0.0
var _game_over: bool = false

var _pipe_t: float = 0.0

var _hint_label: Label = null
var _hint_t: float = 0.0
var _hint_visible: bool = false

const EDGE_MARGIN := 80.0
const CAM_PAN_SPEED := 380.0

func _load_level(idx: int) -> void:
	# clear previous
	for c in level_root.get_children():
		c.queue_free()
	if world:
		world.queue_free()
	if _decor:
		_decor.queue_free()
		_decor = null
	if _hazard_layer:
		_hazard_layer.queue_free()
		_hazard_layer = null
	_particles.clear()
	_elapsed = 0.0
	_game_over = false
	_pipe_t = 0.0
	if _win_overlay:
		_win_overlay.hide_overlay()

	var path := LEVEL_PATH + LEVEL_FILES[idx % LEVEL_FILES.size()]
	level = LevelData.load_file(path)
	if level == null:
		push_error("Failed to load level: " + path)
		return

	# Decor layer — renders above terrain (z=1), below balls (z=2)
	_decor = DecorLayer.new()
	add_child(_decor)
	_decor.setup(level)

	# Hazard layer — above balls (z=3)
	_hazard_layer = HazardLayer.new()
	add_child(_hazard_layer)
	_hazard_layer.setup(level)

	world = WorldLogic.new()
	world.event_fired.connect(_on_event)
	world.status_changed.connect(_on_status)
	world.goo_smashed.connect(_on_goo_smashed)
	add_child(world)
	world.setup(level, level_root)
	world.hazard_nodes = _hazard_layer.nodes

	# center camera on level
	camera.position = Vector2(level.width * 0.5, level.height * 0.5)

	# hint: show for first 8s on humble_tower, hide after first attach
	_hint_t = 8.0
	_hint_visible = (level.id == "humble_tower")
	if _hint_label != null:
		_hint_label.text = tr("Drag a goo ball onto the structure to attach it")
		_hint_label.visible = _hint_visible
		_hint_label.modulate.a = 1.0

	queue_redraw()


func _process(delta: float) -> void:
	if world == null:
		return
	var prev := _hovered
	_hovered = world.pick(get_global_mouse_position()) if world.dragging == null else null
	if _hovered != prev:
		queue_redraw()
	_update_debug_overlay(delta)
	_pan_camera(delta)
	_update_hint(delta)


func _physics_process(delta: float) -> void:
	if world:
		world.tick(delta)
	_tick_particles(delta)
	if not _game_over:
		_elapsed += delta
	_pipe_t += delta
	queue_redraw()
	_update_hud()


func _pan_camera(delta: float) -> void:
	if world == null or world.dragging == null or level == null:
		return
	var mp := get_viewport().get_mouse_position()
	var vp := get_viewport().get_visible_rect().size
	var move := Vector2.ZERO
	if mp.x < EDGE_MARGIN:
		move.x = -1.0
	elif mp.x > vp.x - EDGE_MARGIN:
		move.x = 1.0
	if mp.y < EDGE_MARGIN:
		move.y = -1.0
	elif mp.y > vp.y - EDGE_MARGIN:
		move.y = 1.0
	if move != Vector2.ZERO:
		camera.position += move * CAM_PAN_SPEED * delta
		camera.position.x = clampf(camera.position.x, 0.0, float(level.width))
		camera.position.y = clampf(camera.position.y, 0.0, float(level.height))


func _update_hint(delta: float) -> void:
	if not _hint_visible or _hint_label == null:
		return
	_hint_t -= delta
	if _hint_t <= 0.0:
		_hint_visible = false
		_hint_label.visible = false
		return
	# fade in last 2s
	if _hint_t < 2.0:
		_hint_label.modulate.a = _hint_t / 2.0


func _update_hud() -> void:
	if world == null or level == null:
		return
	hud_label.text = (
		level.level_name
		+ "  |  Collected: " + str(world.collected) + "/" + str(level.target)
		+ "  |  Moves: " + str(world.moves)
	)


# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if world == null:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var world_pos := get_global_mouse_position()

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var g := world.pick(world_pos)
				world.begin_drag(g)
			else:
				world.release(world_pos)

	elif event is InputEventMouseMotion:
		world.drag_to(get_global_mouse_position())

	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Z:
				if event.ctrl_pressed:
					world.undo()
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
			KEY_R:
				_load_level(_level_index)
			KEY_N:
				_level_index += 1
				_load_level(_level_index)
			KEY_D:
				_debug_visible = not _debug_visible
				if _debug_label != null:
					_debug_label.visible = _debug_visible


# ─── Draw ─────────────────────────────────────────────────────────────────────

func _draw() -> void:
	if world == null or level == null:
		return
	_draw_terrain()
	_draw_pipe()
	_draw_strands()
	_draw_hover()
	_draw_preview()
	_draw_particles()


func _draw_terrain() -> void:
	for t in level.terrain:
		var pts: Array = t.get("polyline", [])
		var color := Color(0.35, 0.28, 0.20)
		for i in range(pts.size() - 1):
			var a := level.to_vec2(pts[i])
			var b := level.to_vec2(pts[i + 1])
			draw_line(a, b, color, 6.0)
		if t.get("fill", false) and pts.size() >= 2:
			var a := level.to_vec2(pts[0])
			var b := level.to_vec2(pts[-1])
			# fill below terrain to bottom of screen
			var poly := PackedVector2Array()
			for p in pts:
				poly.append(level.to_vec2(p))
			poly.append(Vector2(b.x, float(level.height) + 20))
			poly.append(Vector2(a.x, float(level.height) + 20))
			draw_colored_polygon(poly, Color(0.22, 0.18, 0.13))


func _draw_pipe() -> void:
	var pp := level.pipe_pos
	var pr := level.pipe_radius
	var connected := world.pipe_connected()

	# pulsing outer ring
	var pulse := (sin(_pipe_t * 3.2) * 0.5 + 0.5)  # 0..1
	var ring_alpha := 0.55 * pulse if connected else 0.18 * pulse
	var ring_r := pr * (1.0 + pulse * 0.28)
	draw_arc(pp, ring_r, 0.0, TAU, 36,
		Color(0.9, 0.75, 0.2, ring_alpha) if connected else Color(0.5, 0.5, 0.55, ring_alpha), 3.0)

	# outer ring
	draw_circle(pp, pr, Color(0.15, 0.15, 0.15))
	draw_arc(pp, pr, 0.0, TAU, 48, Color(0.5, 0.5, 0.5), 3.0)
	# inner glow when connected
	if connected:
		var glow_a := 0.55 + 0.20 * pulse
		draw_circle(pp, pr * 0.65, Color(0.9, 0.75, 0.2, glow_a))
	else:
		draw_circle(pp, pr * 0.65, Color(0.25, 0.25, 0.25))
	# center mark
	draw_circle(pp, 4.0, Color(0.8, 0.8, 0.8))


func _draw_strands() -> void:
	if world == null:
		return
	const STRAND_COLORS: Dictionary = {
		"common":  Color(0.22, 0.22, 0.26),
		"ivy":     Color(0.15, 0.52, 0.18),
		"slime":   Color(0.68, 0.80, 0.70),
		"balloon": Color(0.78, 0.30, 0.46),
		"sticky":  Color(0.68, 0.55, 0.12),
		"fire":    Color(0.78, 0.24, 0.08),
		"bit":     Color(0.22, 0.26, 0.46),
	}
	for s in world.strands:
		if not is_instance_valid(s) or not is_instance_valid(s.goo_a) or not is_instance_valid(s.goo_b):
			continue
		var col: Color = STRAND_COLORS.get(s.strand_kind, Color(0.25, 0.25, 0.28))
		var stretch := s.current_length() / maxf(s.rest_len, 1.0)
		if stretch > 1.4:
			col = col.lerp(Color(0.85, 0.15, 0.08), clampf((stretch - 1.4) / 0.5, 0.0, 1.0))

		var pa: Vector2 = s.goo_a.position
		var pb: Vector2 = s.goo_b.position
		var seg_len := pa.distance_to(pb)
		# catenary sag control point — drops down proportional to length
		var sag := seg_len * 0.12
		var mid := (pa + pb) * 0.5 + Vector2(0.0, sag)

		# sample bezier curve into polyline (12 points)
		var pts: PackedVector2Array = []
		for i in range(13):
			var t := float(i) / 12.0
			var p := (1.0 - t) * (1.0 - t) * pa + 2.0 * (1.0 - t) * t * mid + t * t * pb
			pts.append(p)

		var r_a := float(s.goo_a.goo_type.get("radius", 12.0))
		var r_b := float(s.goo_b.goo_type.get("radius", 12.0))
		var strand_w := clampf(minf(r_a, r_b) * 0.52, 5.0, 11.0)

		# outer dark stroke
		draw_polyline(pts, col.darkened(0.45), strand_w + 3.0, true)
		# main strand body
		draw_polyline(pts, col, strand_w, true)
		# subtle center highlight
		draw_polyline(pts, col.lightened(0.18), strand_w * 0.35, true)

		# junction blobs — strand blends into ball
		var blob_r_a := r_a * 0.42
		var blob_r_b := r_b * 0.42
		draw_circle(pa, blob_r_a + 1.5, col.darkened(0.45))
		draw_circle(pa, blob_r_a, col)
		draw_circle(pb, blob_r_b + 1.5, col.darkened(0.45))
		draw_circle(pb, blob_r_b, col)


func _draw_hover() -> void:
	if _hovered == null or not is_instance_valid(_hovered):
		return
	if world.dragging != null:
		return
	var r: float = float(_hovered.goo_type.get("radius", 12.0)) + 6.0
	draw_arc(_hovered.position, r, 0.0, TAU, 32, Color(1.0, 1.0, 0.55, 0.85), 2.5)


func _draw_preview() -> void:
	if world == null or world.dragging == null:
		return
	var mouse_pos := get_global_mouse_position()
	var targets := world.preview(mouse_pos)
	for t in targets:
		draw_line(mouse_pos, t.position, Color(1.0, 1.0, 1.0, 0.35), 2.0)


# ─── Particles ────────────────────────────────────────────────────────────────

func _on_goo_smashed(pos: Vector2, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 7 + pos.y * 13)
	for _i in range(10):
		var angle := rng.randf() * TAU
		var spd   := rng.randf_range(90.0, 220.0)
		_particles.append({
			"pos":   pos,
			"vel":   Vector2(cos(angle), sin(angle)) * spd,
			"life":  1.0,
			"color": color,
		})


func _tick_particles(delta: float) -> void:
	var alive: Array = []
	for p in _particles:
		p.pos  += p.vel * delta
		p.vel  *= 0.90
		p.life -= delta * 1.6
		if p.life > 0.0:
			alive.append(p)
	_particles = alive


func _draw_particles() -> void:
	for p in _particles:
		var r := lerpf(4.0, 1.0, 1.0 - p.life)
		draw_circle(p.pos, r, Color(p.color.r, p.color.g, p.color.b, p.life))


# ─── Events ───────────────────────────────────────────────────────────────────

func _update_debug_overlay(delta: float) -> void:
	if _debug_label == null:
		return
	var alive: Array = []
	for e in _debug_events:
		e.life -= delta
		if e.life > 0.0:
			alive.append(e)
	_debug_events = alive
	if _debug_visible:
		var txt := ""
		for e in _debug_events:
			var alpha := clampf(e.life / 1.5, 0.0, 1.0)
			txt += e.text + "\n"
		_debug_label.text = txt.strip_edges()


func _push_debug(text: String) -> void:
	_debug_events.append({"text": text, "life": 1.5})
	if _debug_events.size() > 4:
		_debug_events.pop_front()


func _on_event(ev: String) -> void:
	_push_debug(ev.to_upper())
	# hide hint on first attach
	if ev == "attach" and _hint_visible:
		_hint_visible = false
		if _hint_label != null:
			_hint_label.visible = false


func _on_status(s: String) -> void:
	_game_over = true
	match s:
		"won":
			if level != null:
				GameState.mark_complete(level.id)
				var is_ocd := level.ocd_target > 0 and world.collected >= level.ocd_target
				if is_ocd:
					GameState.mark_ocd(level.id)
				_spawn_win_celebration()
				if _win_overlay != null:
					_win_overlay.show_win(world.collected, level.target,
						_elapsed, level.ocd_target, is_ocd)
				else:
					status_label.text = "You win!"
					status_label.show()
		"lost":
			status_label.text = tr("Lost! Press R to restart.")
			status_label.show()


func _spawn_win_celebration() -> void:
	if level == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var colors := [
		Color(1.0, 0.85, 0.2), Color(0.4, 0.95, 0.4),
		Color(0.3, 0.7, 1.0),  Color(1.0, 0.4, 0.5),
		Color(0.9, 0.5, 1.0),
	]
	for _i in range(35):
		var angle := rng.randf_range(-PI * 0.85, -PI * 0.15)
		var spd   := rng.randf_range(140.0, 360.0)
		_particles.append({
			"pos":   level.pipe_pos,
			"vel":   Vector2(cos(angle), sin(angle)) * spd,
			"life":  rng.randf_range(0.9, 2.0),
			"color": colors[rng.randi() % colors.size()],
		})


func _on_win_next() -> void:
	_level_index += 1
	_load_level(_level_index)


func _on_win_retry() -> void:
	_load_level(_level_index)


func _on_win_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
