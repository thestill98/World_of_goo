extends Node2D

const LEVEL_PATH := "res://levels/"
const LEVEL_FILES: Array[String] = [
	"01_humble_tower.json",
	"02_the_gap.json",
	"03_balloon_lift.json",
	"04_burn_the_wall.json",
	"05_sticky_wall.json",
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
	# Find level index from GameState id, default to 0
	var target_id: String = GameState.current_level_id
	for i in range(LEVEL_FILES.size()):
		var data := LevelData.load_file(LEVEL_PATH + LEVEL_FILES[i])
		if data != null and data.id == target_id:
			_level_index = i
			break
	_load_level(_level_index)


func _load_level(idx: int) -> void:
	# clear previous
	for c in level_root.get_children():
		c.queue_free()
	if world:
		world.queue_free()

	var path := LEVEL_PATH + LEVEL_FILES[idx % LEVEL_FILES.size()]
	level = LevelData.load_file(path)
	if level == null:
		push_error("Failed to load level: " + path)
		return

	world = WorldLogic.new()
	world.event_fired.connect(_on_event)
	world.status_changed.connect(_on_status)
	add_child(world)
	world.setup(level, level_root)

	# center camera on level
	camera.position = Vector2(level.width * 0.5, level.height * 0.5)

	queue_redraw()


func _process(_delta: float) -> void:
	if world == null:
		return
	var prev := _hovered
	_hovered = world.pick(get_global_mouse_position()) if world.dragging == null else null
	if _hovered != prev:
		queue_redraw()


func _physics_process(delta: float) -> void:
	if world:
		world.tick(delta)
	queue_redraw()
	_update_hud()


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
			KEY_H:
				print("HELLO WORLD - scripts work")


# ─── Draw ─────────────────────────────────────────────────────────────────────

func _draw() -> void:
	if world == null or level == null:
		return
	_draw_terrain()
	_draw_pipe()
	_draw_strands()
	_draw_hover()
	_draw_preview()


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
	# outer ring
	draw_circle(pp, pr, Color(0.15, 0.15, 0.15))
	draw_arc(pp, pr, 0.0, TAU, 48, Color(0.5, 0.5, 0.5), 3.0)
	# inner glow when connected
	if world.pipe_connected():
		draw_circle(pp, pr * 0.65, Color(0.9, 0.75, 0.2, 0.7))
	else:
		draw_circle(pp, pr * 0.65, Color(0.25, 0.25, 0.25))
	# count label drawn via canvas; we approximate with a circle center mark
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


# ─── Events ───────────────────────────────────────────────────────────────────

func _on_event(ev: String) -> void:
	pass  # audio / particles will go here


func _on_status(s: String) -> void:
	match s:
		"won":
			status_label.text = "You win!  Press N for next level."
			status_label.show()
		"lost":
			status_label.text = "Lost!  Press R to restart."
			status_label.show()
