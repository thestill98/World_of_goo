class_name WinOverlay
extends CanvasLayer

signal next_level_pressed
signal retry_pressed
signal menu_pressed

var _stats_label: Label = null
var _ocd_label: Label   = null


func _ready() -> void:
	layer   = 15
	visible = false
	_build_ui()


func show_win(collected: int, target: int, elapsed: float, ocd_target: int, is_ocd_done: bool) -> void:
	var time_str := "%.1fs" % elapsed
	_stats_label.text = "%d balls collected  •  %s" % [collected, time_str]

	if ocd_target > 0:
		if is_ocd_done:
			_ocd_label.text = "★ OCD: %d / %d — perfect!" % [collected, ocd_target]
			_ocd_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20))
		else:
			_ocd_label.text = "OCD goal: collect %d balls" % ocd_target
			_ocd_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.72))
		_ocd_label.visible = true
	else:
		_ocd_label.visible = false

	visible = true


func hide_overlay() -> void:
	visible = false


func _build_ui() -> void:
	# semi-transparent background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 0.78)
	bg.position = Vector2.ZERO
	bg.size     = Vector2(1280, 720)
	add_child(bg)

	# title
	var title := Label.new()
	title.text = tr("LEVEL COMPLETE!")
	title.position = Vector2(0, 210)
	title.size     = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.88, 0.95, 0.45))
	add_child(title)

	# stats
	_stats_label = Label.new()
	_stats_label.position = Vector2(0, 298)
	_stats_label.size     = Vector2(1280, 36)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 22)
	_stats_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	add_child(_stats_label)

	# ocd row
	_ocd_label = Label.new()
	_ocd_label.position = Vector2(0, 340)
	_ocd_label.size     = Vector2(1280, 30)
	_ocd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ocd_label.add_theme_font_size_override("font_size", 17)
	_ocd_label.visible = false
	add_child(_ocd_label)

	# buttons
	var btn_y := 420.0
	var btn_h := 50.0
	UI.make_button(self, tr("NEXT LEVEL"), Vector2(446, btn_y), 164, btn_h,
		func(): emit_signal("next_level_pressed"), "primary")
	UI.make_button(self, tr("RETRY"),      Vector2(622, btn_y), 130, btn_h,
		func(): emit_signal("retry_pressed"),      "secondary")
	UI.make_button(self, tr("MENU"),       Vector2(764, btn_y), 130, btn_h,
		func(): emit_signal("menu_pressed"),        "secondary")
