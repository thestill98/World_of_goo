class_name LevelData

var id: String = ""
var level_name: String = ""
var order: int = 0
var hint: String = ""
var width: int = 1280
var height: int = 720
var gravity: float = 900.0
var terrain: Array = []
var obstacles: Array = []
var nodes: Array = []
var strands: Array = []
var free_goo: Array = []
var pipe_pos: Vector2 = Vector2(640, 360)
var pipe_radius: float = 46.0
var target: int = 1
var ocd: Dictionary = {}
var ocd_target: int = 0  # 0 = no OCD challenge; set from ocd.target in JSON
var decor: Array = []
var hazards: Array = []


static func load_file(path: String) -> LevelData:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open level: " + path)
		return null
	var src := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(src) != OK:
		push_error("JSON parse error in: " + path + " — " + json.get_error_message())
		return null
	return from_dict(json.data)


static func from_dict(d: Dictionary) -> LevelData:
	var ld := LevelData.new()
	ld.id = d.get("id", "")
	ld.level_name = d.get("name", "")
	ld.order = d.get("order", 0)
	ld.hint = d.get("hint", "")
	var world: Dictionary = d.get("world", {})
	ld.width = world.get("width", 1280)
	ld.height = world.get("height", 720)
	ld.gravity = float(d.get("gravity", 900.0))
	ld.terrain = d.get("terrain", [])
	ld.obstacles = d.get("obstacles", [])
	ld.nodes = d.get("nodes", [])
	ld.strands = d.get("strands", [])
	ld.free_goo = d.get("free_goo", [])
	var pipe: Dictionary = d.get("pipe", {})
	var pp: Array = pipe.get("pos", [640, 360])
	ld.pipe_pos = Vector2(float(pp[0]), ld.flip_y(float(pp[1])))
	ld.pipe_radius = float(pipe.get("radius", 46.0))
	ld.target = int(d.get("target", 1))
	ld.ocd        = d.get("ocd", {})
	ld.ocd_target = int(ld.ocd.get("target", 0))
	ld.decor      = d.get("decor", [])
	ld.hazards    = d.get("hazards", [])
	return ld


func flip_y(y: float) -> float:
	return float(height) - y


func to_vec2(arr: Array) -> Vector2:
	return Vector2(float(arr[0]), flip_y(float(arr[1])))
