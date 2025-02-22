@tool
@icon("../icons/ConvexConeShape3D.svg")
class_name ConvexConeShape3D
extends ConvexPolygonShape3D


@export_range(0.001, 100.0, 0.001, "or_greater") var height: float = 2.0:
	set(value):
		height = value
		_populate_points()

@export_range(0.001, 100.0, 0.001, "or_greater") var radius: float = 0.5:
	set(value):
		radius = value
		_populate_points()

@export_range(3, 32, 1) var segments: int = 8:
	set(value):
		segments = value
		_populate_points()


func _init() -> void:
	_populate_points()


func _populate_points() -> void:
	var array: PackedVector3Array
	array.resize(segments + 1)
	
	array[0] = Vector3(0.0, height * 0.5, 0.0); 
	
	var angle: float = TAU / segments
	for i in range(1, segments + 1):
		var x: float = radius * cos(i * angle)
		var z: float = radius * sin(i * angle)
		array[i] = Vector3(x, -height * 0.5, z);
	
	points = array
