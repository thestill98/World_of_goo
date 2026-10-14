extends Node2D

const LEVEL_FILES := [
	"res://levels/01_humble_tower.json",
	"res://levels/02_the_gap.json",
	"res://levels/03_balloon_lift.json",
	"res://levels/04_burn_the_wall.json",
	"res://levels/05_sticky_wall.json",
	"res://levels/06_twin_peaks.json",
	"res://levels/07_sky_high.json",
	"res://levels/08_gear_gauntlet.json",
]

var _HILLS_FAR := PackedVector2Array([
	Vector2(0, 720), Vector2(0, 590), Vector2(200, 555), Vector2(480, 580),
	Vector2(700, 545), Vector2(950, 568), Vector2(1150, 542),
	Vector2(1280, 558), Vector2(1280, 720),
])
var _HILLS_NEAR := PackedVector2Array([
	Vector2(0, 720), Vector2(0, 635), Vector2(300, 618), Vector2(650, 636),
	Vector2(1000, 618), Vector2(1280, 628), Vector2(1280, 720),
])

var _levels: Array = []
var _time: float   = 0.0


func _ready() -> void:
	_load_level_data()

	var layer := CanvasLayer.new()
	add_child(layer)

	_build_cards(layer)
	UI.make_button(layer, tr("BACK"),     Vector2(30,   660), 120, 44, _on_back,     "secondary")
	UI.make_button(layer, tr("SETTINGS"), Vector2(1130, 660), 120, 44, _on_settings, "secondary")


func _load_level_data() -> void:
	for path in LEVEL_FILES:
		if not FileAccess.file_exists(path):
			continue
		var f    := FileAccess.open(path, FileAccess.READ)
		var data: Variant = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			_levels.append(data)


func _build_cards(parent: Node) -> void:
	var card_w := 196
	var card_h := 148
	var gap    := 24
	var total_w := _levels.size() * card_w + (_levels.size() - 1) * gap
	var start_x := int((1280 - total_w) / 2)
	var card_y  := 280

	for i in range(_levels.size()):
		var lvl: Dictionary = _levels[i]
		var cx := start_x + i * (card_w + gap)
		_make_card(parent, lvl, i, cx, card_y, card_w, card_h)


func _make_card(parent: Node, lvl: Dictionary, idx: int,
				x: int, y: int, w: int, h: int) -> void:
	var level_id: String = lvl.get("id", "")
	var done: bool     = GameState.is_complete(level_id)
	var ocd_done: bool = GameState.is_ocd(level_id)

	var btn: Button = UI.make_button(parent, "", Vector2(x, y), w, h,
									 _on_level.bind(idx), "card")
	btn.tooltip_text = lvl.get("name", "")

	# completed levels get a green border tint via modulate
	if done:
		btn.modulate = Color(0.75, 1.10, 0.80)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)

	var num_lbl := Label.new()
	var marker := " ★" if ocd_done else (" ✓" if done else "")
	num_lbl.text = "%02d%s" % [idx + 1, marker]
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 36)
	num_lbl.add_theme_color_override("font_color",
		Color(0.45, 0.95, 0.55) if done else Color(0.85, 0.87, 0.92))
	num_lbl.layout_mode = 2

	var name_lbl := Label.new()
	name_lbl.text                 = lvl.get("name", "???")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.65, 0.68, 0.76))
	name_lbl.layout_mode = 2

	vbox.add_child(num_lbl)
	vbox.add_child(name_lbl)
	btn.add_child(vbox)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	Draw.sky(self)
	Draw.hills(self, _HILLS_FAR, _HILLS_NEAR)
	Draw.heading(self, tr("Select Level"), 180, 1280.0, 52)


func _on_level(idx: int) -> void:
	if idx < 0 or idx >= _levels.size():
		return
	GameState.current_level_id = _levels[idx].get("id", "")
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
