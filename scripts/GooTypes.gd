class_name GooTypes

const TYPES: Dictionary = {
	"common": {
		"kind": "common", "radius": 12.0, "mass": 1.0,
		"max_links": 2, "min_links": 2, "attach_range": 115.0,
		"strand_stiffness": 100.0, "strand_damping": 0.8,
		"break_ratio": 1.9, "min_len": 34.0, "max_len": 80.0,
		"lift": 0.0, "movable": false,
		"sticks_to_terrain": false, "burns": false, "dies_on_spikes": true,
		"color": Color(0.07, 0.07, 0.10),
	},
	"ivy": {
		"kind": "ivy", "radius": 10.0, "mass": 0.7,
		"max_links": 4, "min_links": 2, "attach_range": 115.0,
		"strand_stiffness": 120.0, "strand_damping": 0.7,
		"break_ratio": 1.45, "min_len": 40.0, "max_len": 105.0,
		"lift": 0.0, "movable": true,
		"sticks_to_terrain": false, "burns": false, "dies_on_spikes": true,
		"color": Color(0.20, 0.68, 0.24),
	},
	"slime": {
		"kind": "slime", "radius": 13.0, "mass": 1.2,
		"max_links": 1, "min_links": 1, "attach_range": 120.0,
		"strand_stiffness": 60.0, "strand_damping": 0.5,
		"break_ratio": 2.8, "min_len": 28.0, "max_len": 130.0,
		"lift": 0.0, "movable": false,
		"sticks_to_terrain": false, "burns": false, "dies_on_spikes": true,
		"color": Color(0.88, 0.93, 0.90),
	},
	"bit": {
		"kind": "bit", "radius": 8.0, "mass": 1.8,
		"max_links": 3, "min_links": 2, "attach_range": 90.0,
		"strand_stiffness": 350.0, "strand_damping": 0.95,
		"break_ratio": 3.5, "min_len": 18.0, "max_len": 55.0,
		"lift": 0.0, "movable": false,
		"sticks_to_terrain": false, "burns": false, "dies_on_spikes": true,
		"color": Color(0.22, 0.25, 0.38),
	},
	"balloon": {
		"kind": "balloon", "radius": 13.0, "mass": 0.5,
		"max_links": 1, "min_links": 1, "attach_range": 80.0,
		"strand_stiffness": 80.0, "strand_damping": 0.7,
		"break_ratio": 2.2, "min_len": 34.0, "max_len": 80.0,
		"lift": 1.7, "movable": false,
		"sticks_to_terrain": false, "burns": false, "dies_on_spikes": true,
		"color": Color(0.92, 0.43, 0.55),
	},
	"sticky": {
		"kind": "sticky", "radius": 12.0, "mass": 1.0,
		"max_links": 2, "min_links": 1, "attach_range": 95.0,
		"strand_stiffness": 100.0, "strand_damping": 0.8,
		"break_ratio": 1.9, "min_len": 34.0, "max_len": 80.0,
		"lift": 0.0, "movable": false,
		"sticks_to_terrain": true, "burns": false, "dies_on_spikes": true,
		"color": Color(0.86, 0.75, 0.24),
	},
	"fire": {
		"kind": "fire", "radius": 11.0, "mass": 0.6,
		"max_links": 0, "min_links": 1, "attach_range": 90.0,
		"strand_stiffness": 100.0, "strand_damping": 0.8,
		"break_ratio": 1.9, "min_len": 34.0, "max_len": 80.0,
		"lift": 0.0, "movable": false,
		"sticks_to_terrain": false, "burns": true, "dies_on_spikes": false,
		"color": Color(0.92, 0.35, 0.16),
	},
}

static func get_type(kind: String) -> Dictionary:
	return TYPES.get(kind, TYPES["common"])
