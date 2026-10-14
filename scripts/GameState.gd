extends Node

const SAVE_PATH := "user://save.json"

var current_level_id: String = "humble_tower"

# progress
var _completed: Array = []
var _ocd: Array = []

# settings
var master_volume: float = 1.0
var music_volume:  float = 0.8
var language: String = "EN"


func _ready() -> void:
	_load_save()
	_apply_audio()


# ── Progress ────────────────────────────────────────────────────────────────

func mark_complete(level_id: String) -> void:
	if level_id == "" or _completed.has(level_id):
		return
	_completed.append(level_id)
	_save()


func is_complete(level_id: String) -> bool:
	return _completed.has(level_id)


func mark_ocd(level_id: String) -> void:
	if level_id == "" or _ocd.has(level_id):
		return
	_ocd.append(level_id)
	_save()


func is_ocd(level_id: String) -> bool:
	return _ocd.has(level_id)


# ── Settings ─────────────────────────────────────────────────────────────────

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_audio()
	_save()


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_audio()
	_save()


func set_language(lang: String) -> void:
	language = lang
	_save()


func _apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume) if master_volume > 0.001 else -80.0)
	AudioServer.set_bus_mute(master_idx, master_volume < 0.001)


# ── Persistence ──────────────────────────────────────────────────────────────

func _save() -> void:
	var data := {
		"completed":     _completed,
		"ocd":           _ocd,
		"master_volume": master_volume,
		"music_volume":  music_volume,
		"language":      language,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: cannot write save file")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		return
	_completed    = Array(data.get("completed",     []))
	_ocd          = Array(data.get("ocd",           []))
	master_volume = float(data.get("master_volume", 1.0))
	music_volume  = float(data.get("music_volume",  0.8))
	language      = str(data.get("language",        "EN"))
