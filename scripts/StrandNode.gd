class_name StrandNode
extends Node2D

var goo_a: GooNode
var goo_b: GooNode
var rest_len: float = 60.0
var break_ratio: float = 1.9
var strand_kind: String = "common"
var stiffness: float = 100.0
var damping_ratio: float = 0.8


func setup(a: GooNode, b: GooNode, rest: float) -> void:
	goo_a = a
	goo_b = b
	rest_len = rest

	var ta: Dictionary = a.goo_type
	var tb: Dictionary = b.goo_type
	strand_kind = a.kind
	stiffness = minf(float(ta.get("strand_stiffness", 100.0)), float(tb.get("strand_stiffness", 100.0)))
	damping_ratio = minf(float(ta.get("strand_damping", 0.8)), float(tb.get("strand_damping", 0.8)))
	break_ratio = minf(float(ta.get("break_ratio", 1.9)), float(tb.get("break_ratio", 1.9)))

	a.strands.append(self)
	b.strands.append(self)


func current_length() -> float:
	if not is_instance_valid(goo_a) or not is_instance_valid(goo_b):
		return 0.0
	return goo_a.position.distance_to(goo_b.position)


func other(g: GooNode) -> GooNode:
	return goo_b if g == goo_a else goo_a
