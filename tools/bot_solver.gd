## Playtesting bot — greedy goo attacher
##
## Usage:
##   godot --headless --script tools/bot_solver.gd -- <level_file>
##
## Example:
##   godot --headless --script tools/bot_solver.gd -- levels/01_humble_tower.json
##
## The bot picks the free goo closest to an existing structure node and tries
## to place it at the optimal attachment point. Reports result to stdout.

extends SceneTree

const TICK_DELTA   := 1.0 / 60.0
const MAX_TICKS    := 3600  # 60 seconds of simulated time
const MAX_ATTEMPTS := 200   # placement attempts before giving up

var _root_node: Node2D
var _world: WorldLogic
var _level: LevelData
var _tick_count: int = 0
var _attempts: int   = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var level_path := "res://levels/01_humble_tower.json"
	if args.size() > 0:
		level_path = args[0]
		if not level_path.begins_with("res://") and not level_path.begins_with("user://"):
			level_path = "res://" + level_path

	_level = LevelData.load_file(level_path)
	if _level == null:
		print("BOT ERROR: cannot load level: ", level_path)
		quit(1)
		return

	print("BOT: loaded level '", _level.level_name, "' target=", _level.target)

	_root_node = Node2D.new()
	get_root().add_child(_root_node)

	_world = WorldLogic.new()
	_world.event_fired.connect(func(ev): pass)
	_world.status_changed.connect(_on_status)
	_root_node.add_child(_world)
	_world.setup(_level, _root_node)


func _process(_delta: float) -> bool:
	if _world == null or _world.status != "playing":
		return false  # stop loop

	_world.tick(TICK_DELTA)
	_tick_count += 1

	# Every 6 ticks (~0.1s simulated), try a placement
	if _tick_count % 6 == 0:
		_bot_step()

	if _tick_count >= MAX_TICKS:
		print("BOT TIMEOUT after ", _tick_count, " ticks — collected=",
			_world.collected, "/", _level.target,
			" moves=", _world.moves)
		quit(2)
		return false

	return true  # keep running


func _bot_step() -> void:
	if _world.dragging != null:
		_world.release()
		return

	if _attempts >= MAX_ATTEMPTS:
		return

	# Find best free goo to pick (closest to any structure node)
	var free_goos := _world.free_goos()
	if free_goos.is_empty():
		return

	var best_goo: GooNode   = null
	var best_target: GooNode = null
	var best_dist := INF

	for g in free_goos:
		for s in _world.goos:
			if not s.in_structure():
				continue
			var d := g.position.distance_to(s.position)
			if d < best_dist:
				best_dist  = d
				best_goo   = g
				best_target = s

	if best_goo == null or best_target == null:
		return

	# Drag to a point just within attach range of the target
	var gt  := best_goo.goo_type
	var ar  := float(gt.get("attach_range", 90.0))
	var dir := (best_target.position - best_goo.position).normalized()
	var drop_pos := best_target.position - dir * ar * 0.75

	_world.begin_drag(best_goo)
	_world.drag_to(drop_pos)
	var result := _world.release(drop_pos)
	_attempts += 1

	if not result.get("ok", false):
		pass  # will retry next step


func _on_status(s: String) -> void:
	match s:
		"won":
			print("BOT WON: collected=", _world.collected,
				"/", _level.target,
				" moves=", _world.moves,
				" ticks=", _tick_count,
				" (", snappedf(_tick_count * TICK_DELTA, 0.1), "s simulated)")
			quit(0)
		"lost":
			print("BOT LOST: collected=", _world.collected,
				"/", _level.target,
				" moves=", _world.moves)
			quit(1)


func _finalize() -> void:
	pass
