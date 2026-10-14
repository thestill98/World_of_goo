class_name GooNode
extends RigidBody2D

const LAYER_TERRAIN := 1
const LAYER_STRUCTURE := 2
const LAYER_FREE := 4
const SUCK_TIME := 0.35

var goo_id: int = 0
var kind: String = "common"
var goo_type: Dictionary = {}
var goo_state: String = "free"
var strands: Array = []
var origin: Vector2 = Vector2.ZERO
var wander_t: float = 0.0
var wander_dir: float = 0.0
var suck_timer: float = 0.0
var suck_from: Vector2 = Vector2.ZERO
var pipe_pos: Vector2 = Vector2.ZERO
var burn_timer: float = 0.0
var stuck_to_terrain: bool = false
var is_source: bool = true

var _drag_target: Vector2 = Vector2.ZERO

# idle animation state
var _idle_t: float     = 0.0
var _blink_t: float    = 0.0  # set randomly in setup
var _blinking: bool    = false
var _blink_close: float = 0.0


func setup(id: int, k: String, pos: Vector2, state: String) -> void:
	goo_id = id
	kind = k
	goo_type = GooTypes.get_type(k)
	position = pos
	origin = pos

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = goo_type.radius
	shape.shape = circle
	add_child(shape)

	mass    = goo_type.mass
	z_index = 2  # above terrain (0) and decor (1)
	_set_state(state)

	# stagger blink timers so all balls don't blink simultaneously
	_blink_t = randf_range(1.5, 5.0) + float(id) * 0.37


func _set_state(new_state: String) -> void:
	goo_state = new_state
	_apply_filter()
	match new_state:
		"anchor":
			freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			freeze = true
		"drag":
			freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			freeze = true
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			linear_damp = 0.0
		"node":
			freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
			freeze = true
			linear_damp = 0.0
		"free":
			freeze = false
			linear_damp = 1.5
		_:
			freeze = false
			linear_damp = 0.0


func set_goo_state(new_state: String) -> void:
	_set_state(new_state)


func _apply_filter() -> void:
	match goo_state:
		"node", "anchor":
			collision_layer = LAYER_STRUCTURE
			collision_mask = LAYER_TERRAIN | LAYER_STRUCTURE
		"drag":
			collision_layer = 0
			collision_mask = 0
		_:
			collision_layer = LAYER_FREE
			collision_mask = LAYER_TERRAIN


func move_drag(target: Vector2) -> void:
	_drag_target = target
	position = target
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


func begin_suck(from_pos: Vector2, pipe: Vector2) -> void:
	suck_timer = 0.0
	suck_from = from_pos
	pipe_pos = pipe
	collision_layer = 0
	collision_mask = 0
	freeze = false


func _process(delta: float) -> void:
	if goo_state in ["dead", "sucked", "sucked_done"]:
		return
	_idle_t += delta
	_blink_t -= delta
	if _blinking:
		_blink_close -= delta
		if _blink_close <= 0.0:
			_blinking = false
			_blink_t  = randf_range(2.5, 6.5)
	elif _blink_t <= 0.0:
		_blinking   = true
		_blink_close = 0.12
	queue_redraw()


func _physics_process(delta: float) -> void:
	if goo_state == "sucked":
		suck_timer += delta
		var t: float = clampf(suck_timer / SUCK_TIME, 0.0, 1.0)
		position = suck_from.lerp(pipe_pos, ease(t, -2.0))
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
	elif goo_state == "node" and goo_type.get("lift", 0.0) > 0.0:
		var lift: float = goo_type.lift
		apply_central_force(Vector2(0.0, -mass * 900.0 * lift))


func _draw() -> void:
	var r: float = goo_type.get("radius", 12.0)
	var col: Color = goo_type.get("color", Color(0.15, 0.15, 0.18))

	match goo_state:
		"dead", "sucked_done":
			return
		"burning":
			col = Color(0.92, 0.35, 0.16)
		"sucked":
			col.a = 1.0 - clamp(suck_timer / SUCK_TIME, 0.0, 1.0)

	var is_dark := col.get_luminance() < 0.08

	# Idle bob — visual only, does not affect physics position
	var bob_y := 0.0
	if goo_state in ["free", "node", "anchor"]:
		bob_y = sin(_idle_t * 1.7 + float(goo_id) * 0.85) * 1.3
	if bob_y != 0.0:
		draw_set_transform(Vector2(0.0, bob_y), 0.0, Vector2.ONE)

	# Drag petals — drawn first so ball renders on top
	if goo_state == "drag":
		_draw_drag_petals(r, col)

	# Base circle
	draw_circle(Vector2.ZERO, r, col)
	# Volume shading
	draw_circle(Vector2(-r * 0.12, -r * 0.15), r * 0.70, col.lightened(0.20))
	# Specular highlight
	if is_dark:
		draw_circle(Vector2(-r * 0.30, -r * 0.36), r * 0.30, Color(0.28, 0.90, 0.52, 0.58 * col.a))
		draw_circle(Vector2(-r * 0.14, -r * 0.46), r * 0.16, Color(0.30, 0.55, 1.00, 0.45 * col.a))
	else:
		draw_circle(Vector2(-r * 0.33, -r * 0.37), r * 0.26, Color(1.0, 1.0, 1.0, 0.52 * col.a))
	# Outline
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, col.darkened(0.40), 1.5)

	if goo_state in ["free", "node", "anchor", "drag"]:
		# look direction offset (eyes follow velocity)
		var look := Vector2.ZERO
		if linear_velocity.length() > 20.0:
			look = linear_velocity.normalized() * r * 0.10
		_draw_eyes(r, col, is_dark, look)

	# reset bob transform
	if bob_y != 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_drag_petals(r: float, col: Color) -> void:
	# Contrast against ball: light petals on dark balls, dark petals on light balls
	var petal_col := col.lightened(0.45) if col.get_luminance() < 0.15 else col.darkened(0.35)
	var n := 5
	for i in range(n):
		var angle := float(i) / float(n) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		draw_circle(dir * r * 1.22, r * 0.54, petal_col)
		draw_circle(dir * r * 1.80, r * 0.30, petal_col)


func _draw_eyes(r: float, base_col: Color, is_dark: bool, look: Vector2 = Vector2.ZERO) -> void:
	if is_dark:
		var eye_r   := r * 0.13
		var eye_sep := r * 0.17
		var eye_y   := -r * 0.28
		for side in [-1.0, 1.0]:
			var ep := Vector2(side * eye_sep, eye_y) + look
			if _blinking:
				# closed eye — thin horizontal line
				draw_line(ep + Vector2(-eye_r, 0), ep + Vector2(eye_r, 0), Color.WHITE, 1.5)
			else:
				draw_circle(ep, eye_r, Color.WHITE)
				draw_circle(ep + Vector2(eye_r * 0.10, eye_r * 0.15), eye_r * 0.55, Color(0.05, 0.05, 0.08))
				draw_circle(ep + Vector2(-eye_r * 0.28, -eye_r * 0.28), eye_r * 0.22, Color(1.0, 1.0, 1.0, 0.90))
	else:
		var eye_r   := r * 0.30
		var eye_sep := r * 0.33
		var eye_y   := -r * 0.10
		var iris_col := base_col.darkened(0.05).lerp(Color(0.2, 0.4, 0.9), 0.25)
		for side in [-1.0, 1.0]:
			var ep := Vector2(side * eye_sep, eye_y) + look
			if _blinking:
				# closed eye — arc
				draw_arc(ep, eye_r * 0.72, PI, TAU, 12, Color.WHITE, 2.5)
			else:
				draw_circle(ep, eye_r, Color.WHITE)
				draw_circle(ep + Vector2(0.0, eye_r * 0.10), eye_r * 0.66, iris_col)
				draw_circle(ep + Vector2(eye_r * 0.08, eye_r * 0.16), eye_r * 0.38, Color(0.05, 0.05, 0.08))
				draw_circle(ep + Vector2(-eye_r * 0.24, -eye_r * 0.22), eye_r * 0.17, Color(1.0, 1.0, 1.0, 0.92))
				draw_arc(ep, eye_r, 0.0, TAU, 24, Color(0.15, 0.15, 0.20, 0.55), 1.0)


var alive: bool:
	get:
		return goo_state not in ["dead", "sucked_done"]


func in_structure() -> bool:
	return goo_state in ["node", "anchor"]
