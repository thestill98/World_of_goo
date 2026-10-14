extends Node2D

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
	var layer := CanvasLayer.new()
	add_child(layer)

	Draw.heading(layer, tr("Settings"), 180, 1280.0, 48)

	_add_volume_section(layer)
	_add_language_section(layer)

	UI.make_button(layer, tr("BACK"), Vector2(30, 660), 120, 44, _on_back, "secondary")


func _add_volume_section(parent: Node) -> void:
	var y := 260.0
	_label(parent, tr("Master Volume"), Vector2(380, y))

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step      = 0.01
	slider.value     = GameState.master_volume
	slider.position  = Vector2(520, y)
	slider.size      = Vector2(360, 28)
	slider.value_changed.connect(func(v): GameState.set_master_volume(v))
	parent.add_child(slider)

	y += 64.0
	_label(parent, tr("Music Volume"), Vector2(380, y))

	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step      = 0.01
	music_slider.value     = GameState.music_volume
	music_slider.position  = Vector2(520, y)
	music_slider.size      = Vector2(360, 28)
	music_slider.value_changed.connect(func(v): GameState.set_music_volume(v))
	parent.add_child(music_slider)


func _add_language_section(parent: Node) -> void:
	var y := 420.0
	_label(parent, tr("Language"), Vector2(380, y))

	var langs := ["EN", "RO"]
	var cur   := GameState.language
	var x     := 520.0
	for lang in langs:
		var role := "primary" if lang == cur else "secondary"
		var l := lang
		UI.make_button(parent, lang, Vector2(x, y - 4), 70, 38,
			func(): _set_language(l), role)
		x += 82.0


func _label(parent: Node, text: String, pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = pos
	lbl.size     = Vector2(130, 32)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88))
	parent.add_child(lbl)


func _set_language(lang: String) -> void:
	GameState.set_language(lang)
	# Reload scene to apply language change
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	Draw.sky(self)
	Draw.hills(self, _HILLS_FAR, _HILLS_NEAR)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
