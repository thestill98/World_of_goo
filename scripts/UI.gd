class_name UI

# role: "primary" (large nav), "secondary" (small nav), "card" (level card)
static func make_button(parent: Node, text: String, pos: Vector2,
						w: float, h: float, cb: Callable,
						role: String = "primary") -> Button:
	var btn := Button.new()
	btn.text         = text
	btn.position     = pos
	btn.size         = Vector2(w, h)
	btn.pivot_offset = Vector2(w * 0.5, h * 0.5)  # scale from center

	btn.add_theme_stylebox_override("normal",  _style(role, "normal"))
	btn.add_theme_stylebox_override("hover",   _style(role, "hover"))
	btn.add_theme_stylebox_override("pressed", _style(role, "pressed"))
	btn.add_theme_color_override("font_color", Color(0.88, 0.90, 0.95))

	match role:
		"primary":   btn.add_theme_font_size_override("font_size", 22)
		"secondary": btn.add_theme_font_size_override("font_size", 18)
		"card":      btn.add_theme_font_size_override("font_size", 14)

	# hover: scale grow
	btn.mouse_entered.connect(func(): _tween_scale(btn, 1.06))
	btn.mouse_exited.connect( func(): _tween_scale(btn, 1.00))
	# press: sink 2px down, release back
	btn.button_down.connect(func(): _tween_pos(btn, pos + Vector2(0.0, 2.0)))
	btn.button_up.connect(  func(): _tween_pos(btn, pos))

	if cb.is_valid():
		btn.pressed.connect(cb)
	parent.add_child(btn)
	return btn


static func _style(role: String, state: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_border_width_all(2)

	# organic asymmetric corners per role
	match role:
		"primary":
			s.corner_radius_top_left     = 18
			s.corner_radius_top_right    = 14
			s.corner_radius_bottom_right = 20
			s.corner_radius_bottom_left  = 16
		"secondary":
			s.corner_radius_top_left     = 12
			s.corner_radius_top_right    = 10
			s.corner_radius_bottom_right = 14
			s.corner_radius_bottom_left  = 11
		"card":
			s.corner_radius_top_left     = 16
			s.corner_radius_top_right    = 20
			s.corner_radius_bottom_right = 14
			s.corner_radius_bottom_left  = 18

	match state:
		"normal":
			s.bg_color     = Color(0.10, 0.10, 0.14, 0.92)
			s.border_color = Color(0.32, 0.33, 0.42)
		"hover":
			s.bg_color     = Color(0.18, 0.20, 0.28, 0.97)
			s.border_color = Color(0.48, 0.65, 0.50)  # border verde-albăstrui
			s.shadow_color = Color(0.35, 0.58, 0.38, 0.40)
			s.shadow_size  = 8
		"pressed":
			s.bg_color     = Color(0.07, 0.07, 0.11)
			s.border_color = Color(0.38, 0.52, 0.40)

	return s


static func _tween_scale(btn: Button, target: float) -> void:
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(target, target), 0.09) \
	  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _tween_pos(btn: Button, target: Vector2) -> void:
	var tw := btn.create_tween()
	tw.tween_property(btn, "position", target, 0.05) \
	  .set_trans(Tween.TRANS_LINEAR)
