class_name Draw

# ── Sky ──────────────────────────────────────────────────────────────────────

static func sky(canvas: CanvasItem, w: float = 1280.0, _h: float = 720.0) -> void:
	var cols := [Color(0.38, 0.60, 0.84), Color(0.52, 0.72, 0.90), Color(0.64, 0.82, 0.95)]
	for i in range(3):
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(0, i * 240), Vector2(w, i * 240),
			Vector2(w, (i + 1) * 240), Vector2(0, (i + 1) * 240),
		]), cols[i])


# ── Hills ─────────────────────────────────────────────────────────────────────
# Pass two closed polygons (bottom row = ground level).

static func hills(canvas: CanvasItem,
				  far_pts: PackedVector2Array,
				  near_pts: PackedVector2Array) -> void:
	canvas.draw_colored_polygon(far_pts,  Color(0.28, 0.60, 0.22))
	canvas.draw_colored_polygon(near_pts, Color(0.20, 0.47, 0.16))


# ── Centered heading with drop-shadow ─────────────────────────────────────────

static func heading(canvas: CanvasItem, text: String, y: float,
					w: float = 1280.0, size: int = 52) -> void:
	var font := ThemeDB.fallback_font
	var tw   := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x    := (w - tw) * 0.5
	canvas.draw_string(font, Vector2(x + 3, y + 3), text,
					   HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.30))
	canvas.draw_string(font, Vector2(x, y), text,
					   HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.10, 0.10, 0.14))
