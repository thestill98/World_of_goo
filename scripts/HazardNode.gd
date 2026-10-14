class_name HazardNode
extends Node2D

enum HazType { GEAR, SAW, SPINNER }

var haz_type: int = HazType.GEAR
var radius: float = 30.0
var speed: float = TAU * 1.5   # radians/sec (1.5 rot/sec default)
var move_speed: float = 120.0  # px/sec for patrolling hazards

var path_points: Array = []
var _path_t: float = 0.0
var _path_dir: int = 1
var _path_length: float = 0.0


func setup(data: Dictionary, level: LevelData) -> void:
	match data.get("type", "gear"):
		"gear":    haz_type = HazType.GEAR
		"saw":     haz_type = HazType.SAW
		"spinner": haz_type = HazType.SPINNER

	radius = float(data.get("radius", 30.0))
	speed  = float(data.get("speed", 1.5)) * TAU

	var raw_pos: Array = data.get("pos", [0, 0])
	position = level.to_vec2(raw_pos)

	for p in data.get("path", []):
		path_points.append(level.to_vec2(p))
	if path_points.size() >= 2:
		_path_length = maxf(path_points[0].distance_to(path_points[1]), 1.0)
		move_speed = float(data.get("move_speed", 120.0))


func kill_radius() -> float:
	return radius


func _process(delta: float) -> void:
	rotation += speed * delta

	if path_points.size() >= 2:
		_path_t += float(_path_dir) * move_speed * delta / _path_length
		if _path_t >= 1.0:
			_path_t = 1.0
			_path_dir = -1
		elif _path_t <= 0.0:
			_path_t = 0.0
			_path_dir = 1
		position = path_points[0].lerp(path_points[1], _path_t)

	queue_redraw()


func _draw() -> void:
	match haz_type:
		HazType.GEAR:    _draw_gear()
		HazType.SAW:     _draw_saw()
		HazType.SPINNER: _draw_spinner()
	# danger outline — thin red ring
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 36, Color(0.85, 0.15, 0.10, 0.55), 1.5)


func _draw_gear() -> void:
	var n_teeth := 10
	var r_out := radius
	var r_in  := radius * 0.73

	# tooth polygon
	var pts := PackedVector2Array()
	for i in range(n_teeth * 2):
		var a := float(i) / float(n_teeth * 2) * TAU
		var r := r_out if i % 2 == 0 else r_in
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	draw_colored_polygon(pts, Color(0.50, 0.52, 0.57))

	# face highlight lines on teeth
	for i in range(0, n_teeth * 2, 2):
		var a := float(i) / float(n_teeth * 2) * TAU
		draw_line(
			Vector2(cos(a) * r_in,  sin(a) * r_in),
			Vector2(cos(a) * r_out, sin(a) * r_out),
			Color(0.68, 0.70, 0.74), 1.5)

	# dark hub
	draw_circle(Vector2.ZERO, radius * 0.46, Color(0.22, 0.22, 0.26))
	draw_arc(Vector2.ZERO,    radius * 0.46, 0.0, TAU, 24, Color(0.16, 0.16, 0.20), 1.5)

	# three spokes
	for i in range(3):
		var a := float(i) / 3.0 * TAU
		draw_line(Vector2.ZERO,
			Vector2(cos(a), sin(a)) * radius * 0.43,
			Color(0.36, 0.37, 0.42), 3.0)

	# center bolt
	draw_circle(Vector2.ZERO, radius * 0.11, Color(0.62, 0.64, 0.68))


func _draw_saw() -> void:
	var n_teeth := 20
	var pts := PackedVector2Array()
	for i in range(n_teeth * 2):
		var a := float(i) / float(n_teeth * 2) * TAU
		var r := radius if i % 2 == 0 else radius * 0.60
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	draw_colored_polygon(pts, Color(0.70, 0.73, 0.78))

	# polished face
	draw_circle(Vector2.ZERO, radius * 0.65, Color(0.78, 0.81, 0.86))
	draw_circle(Vector2.ZERO, radius * 0.30, Color(0.24, 0.25, 0.29))
	draw_circle(Vector2.ZERO, radius * 0.09, Color(0.60, 0.62, 0.66))


func _draw_spinner() -> void:
	var n_arms := 6
	var arm_w  := radius * 0.22
	for i in range(n_arms):
		var a   := float(i) / float(n_arms) * TAU
		var tip := Vector2(cos(a) * radius, sin(a) * radius)
		var bl  := Vector2(cos(a + PI * 0.5) * arm_w, sin(a + PI * 0.5) * arm_w)
		var br  := Vector2(cos(a - PI * 0.5) * arm_w, sin(a - PI * 0.5) * arm_w)
		draw_colored_polygon(PackedVector2Array([bl, br, tip]), Color(0.50, 0.52, 0.58))
		draw_line(Vector2.ZERO, tip, Color(0.62, 0.64, 0.68), 2.0)
	draw_circle(Vector2.ZERO, radius * 0.22, Color(0.30, 0.31, 0.36))
	draw_circle(Vector2.ZERO, radius * 0.09, Color(0.60, 0.62, 0.66))
