class_name HazardLayer
extends Node2D

var nodes: Array = []  # Array[HazardNode]


func setup(level: LevelData) -> void:
	z_index = 3  # above goo balls (z=2)
	for data in level.hazards:
		var h := HazardNode.new()
		add_child(h)
		h.setup(data, level)
		nodes.append(h)
