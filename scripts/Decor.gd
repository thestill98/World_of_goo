class_name DecorLayer
extends Node2D

const TEX_PATH := "res://assets/textures/decor/"
const GRASS_SPACING := 30.0  # px between auto-scattered grass tufts

const TYPE_FILE := {
    "grass":       "grass_tuft.png",
    "bush_small":  "bush_small.png",
    "bush_large":  "bush_large.png",
    "flower":      "flower.png",
    "rock":        "rock_small.png",
    "mushroom":    "mushroom.png",
}

# sway amplitude (radians) per type — larger = more movement
const TYPE_SWAY := {
    "grass":      0.12,
    "bush_small": 0.055,
    "bush_large": 0.035,
    "flower":     0.10,
    "rock":       0.0,
    "mushroom":   0.04,
}

var _entries: Array = []  # [{node, phase, sway, speed}]
var _time: float = 0.0


func setup(level: LevelData) -> void:
    z_index = 1  # above terrain draw (z=0), below balls (z=2)
    _scatter_grass(level)
    for item in level.decor:
        _place_manual(item, level)


# ── Auto-scatter grass on top surfaces of terrain ────────────────────────────

func _scatter_grass(level: LevelData) -> void:
    var rng := RandomNumberGenerator.new()
    for terrain in level.terrain:
        var pts: Array = terrain.get("polyline", [])
        for i in range(pts.size() - 1):
            var a := level.to_vec2(pts[i])
            var b := level.to_vec2(pts[i + 1])
            _scatter_segment(a, b, rng)


func _scatter_segment(a: Vector2, b: Vector2, rng: RandomNumberGenerator) -> void:
    var dir    := (b - a).normalized()
    var normal := Vector2(-dir.y, dir.x)
    if normal.y > -0.3:
        return  # skip near-vertical or bottom-facing surfaces
    var seg_len := a.distance_to(b)
    var n := maxi(1, int(seg_len / GRASS_SPACING))
    rng.seed = int(a.x * 73856093 ^ int(a.y) * 19349663)
    for i in range(n):
        var t    := (float(i) + rng.randf_range(0.15, 0.85)) / float(n)
        var pos  := a.lerp(b, t) + normal * rng.randf_range(-3.0, 1.0)
        var sc   := rng.randf_range(0.75, 1.25)
        var flip := rng.randi() % 2 == 0
        _add("grass", pos, sc, flip)


# ── Manual placement from level JSON ─────────────────────────────────────────

func _place_manual(item: Dictionary, level: LevelData) -> void:
    var type := item.get("type", "bush_small") as String
    # JSON uses Y-up coords like the rest of the level
    var pos  := level.to_vec2([item.get("x", 0), item.get("y", 0)])
    var sc   := float(item.get("scale", 1.0))
    var flip := bool(item.get("flip", false))
    _add(type, pos, sc, flip)


# ── Sprite creation ───────────────────────────────────────────────────────────

func _add(type: String, pos: Vector2, sc: float, flip: bool) -> void:
    var file := TYPE_FILE.get(type, "bush_small.png")
    var tex  := load(TEX_PATH + file) as Texture2D
    if tex == null:
        push_warning("Decor: missing texture " + file)
        return
    var spr       := Sprite2D.new()
    spr.texture    = tex
    spr.position   = pos
    spr.scale      = Vector2(sc * (-1.0 if flip else 1.0), sc)
    spr.offset     = Vector2(0.0, -tex.get_height() * 0.5)
    add_child(spr)
    _entries.append({
        "node":  spr,
        "phase": randf() * TAU,
        "sway":  TYPE_SWAY.get(type, 0.05),
        "speed": randf_range(0.7, 1.3),
    })


# ── Wind sway animation ───────────────────────────────────────────────────────

func _process(delta: float) -> void:
    _time += delta
    for e in _entries:
        if e.sway > 0.0:
            e.node.rotation = sin(_time * e.speed + e.phase) * e.sway
