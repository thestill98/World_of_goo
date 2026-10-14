extends Node2D

var _decor: Array = []
var _time: float = 0.0

var _HILLS_FAR := PackedVector2Array([
	Vector2(0, 720), Vector2(0, 570), Vector2(150, 530), Vector2(380, 565),
	Vector2(560, 518), Vector2(780, 548), Vector2(1000, 510),
	Vector2(1180, 538), Vector2(1280, 525), Vector2(1280, 720),
])
var _HILLS_NEAR := PackedVector2Array([
	Vector2(0, 720), Vector2(0, 625), Vector2(220, 608), Vector2(520, 628),
	Vector2(820, 608), Vector2(1100, 622), Vector2(1280, 612), Vector2(1280, 720),
])


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(7):
		_decor.append({
			"pos":   Vector2(rng.randf_range(80, 1200), rng.randf_range(380, 560)),
			"vel":   Vector2(rng.randf_range(-22, 22),  rng.randf_range(-14, 14)),
			"r":     rng.randf_range(13, 26),
			"phase": rng.randf_range(0.0, TAU),
		})

	var layer := CanvasLayer.new()
	add_child(layer)
	UI.make_button(layer, tr("PLAY"),     Vector2(540, 340), 200, 52, _on_play)
	UI.make_button(layer, tr("SETTINGS"), Vector2(540, 406), 200, 46, _on_settings, "secondary")
	UI.make_button(layer, tr("QUIT"),     Vector2(540, 464), 200, 46, _on_quit,     "secondary")


func _process(delta: float) -> void:
	_time += delta
	for b in _decor:
		b.pos += b.vel * delta
		if b.pos.x < b.r or b.pos.x > 1280 - b.r:
			b.vel.x *= -1.0
		if b.pos.y < 340 or b.pos.y > 590:
			b.vel.y *= -1.0
	queue_redraw()


func _draw() -> void:
	Draw.sky(self)
	Draw.hills(self, _HILLS_FAR, _HILLS_NEAR)
	_draw_title()
	_draw_decor_balls()


func _draw_title() -> void:
	Draw.heading(self, "World of Bloop", 195, 1280.0, 68)
	var font := ThemeDB.fallback_font
	var sub  := tr("A goo building puzzle")
	var subw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font, Vector2((1280 - subw) * 0.5, 228), sub,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.15, 0.15, 0.22, 0.75))


func _draw_decor_balls() -> void:
	for b in _decor:
		var bob := sin(_time * 1.3 + b.phase) * 5.0
		var p: Vector2 = b.pos + Vector2(0.0, bob)
		var r: float   = b.r
		var col        := Color(0.07, 0.07, 0.10)
		draw_circle(p, r, col)
		draw_circle(p + Vector2(-r * 0.12, -r * 0.15), r * 0.70, col.lightened(0.20))
		draw_circle(p + Vector2(-r * 0.30, -r * 0.36), r * 0.30, Color(0.28, 0.90, 0.52, 0.55))
		draw_circle(p + Vector2(-r * 0.14, -r * 0.46), r * 0.16, Color(0.30, 0.55, 1.00, 0.42))
		draw_arc(p, r, 0.0, TAU, 32, col.darkened(0.40), 1.5)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_quit() -> void:
	get_tree().quit()
