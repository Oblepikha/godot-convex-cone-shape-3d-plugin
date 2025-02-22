extends RefCounted


var undo_redo: EditorUndoRedoManager
var initial_value: Variant
var initial_transform: Transform3D


func _init(p_undo_redo: EditorUndoRedoManager) -> void:
	undo_redo = p_undo_redo


func initialize_handle_action(p_initial_value: Variant, p_initial_transform: Transform3D) -> void:
	initial_value = p_initial_value
	initial_transform = p_initial_transform


func get_segment(p_camera: Camera3D, p_point: Vector2) -> PackedVector3Array:
	var gt := initial_transform
	var gi := gt.affine_inverse();
	
	var ray_from := p_camera.project_ray_origin(p_point)
	var ray_dir := p_camera.project_ray_normal(p_point)
	
	var segment: PackedVector3Array
	segment.resize(2)
	segment[0] = gi * (ray_from)
	segment[1] = gi * (ray_from + ray_dir * 4096)
	
	return segment


func cone_get_handles(p_height: float, p_radius: float) -> PackedVector3Array:
	var handles: PackedVector3Array
	handles.resize(3)
	handles[0] = Vector3(p_radius, -p_height * 0.5, 0.0) # Radius
	handles[1] = Vector3(0.0, p_height * 0.5, 0.0) # Top
	handles[2] = Vector3(0.0, -p_height * 0.5, 0.0) # Bottom
	return handles


func cone_get_handle_name(p_id: int) -> String:
	if p_id == 0:
		return "Radius"
	else:
		return "Height"


func cone_set_handle(p_segment: PackedVector3Array, p_id: int, r_radius: float, r_height: float, r_cone_position: Vector3) -> ConeSetHandleResult:
	
	var axis := 0 if p_id == 0 else 1
	var sign := -1 if p_id == 2 else 1
	
	var axis_vector: Vector3
	axis_vector[axis] = sign
	var ra_rb := Geometry3D.get_closest_points_between_segments(axis_vector * -4096, axis_vector * 4096, p_segment[0], p_segment[1])
	var d := axis_vector.dot(ra_rb[0])
	
	# Snap to grid.
	if Input.is_key_pressed(KEY_CTRL):
		d = snappedf(d, 0.1)
	
	if p_id == 0:
		# Adjust radius.
		if d < 0.001:
			d = 0.001
		r_radius = d
		r_cone_position = initial_transform.origin
	elif p_id == 1 or p_id == 2:
		var initial_height: float = initial_value
		
		# Adjust height.
		if Input.is_key_pressed(KEY_ALT):
			r_height = d * 2.0
		else:
			r_height = (initial_height * 0.5) + d
		
		if r_height < 0.001:
			r_height = 0.001
		
		if Input.is_key_pressed(KEY_ALT):
			r_cone_position = initial_transform.origin
		else:
			var offset: Vector3
			offset[axis] = (r_height - initial_height) * 0.5 * sign
			r_cone_position = initial_transform * offset
	
	return ConeSetHandleResult.new(r_radius, r_height, r_cone_position)


func cone_commit_handle(p_id: float, p_radius_action_name: String, p_height_action_name: String, p_cancel: bool, p_position_object: Object, p_height_object: Object, p_radius_object: Object, p_position_property: StringName = &"global_position", p_height_property: StringName = &"height", p_radius_property: StringName = &"radius") -> void:
	if not p_height_object:
		p_height_object = p_position_object
	if not p_radius_object:
		p_radius_object = p_position_object
	
	if p_cancel:
		if p_id == 0:
			p_radius_object.set(p_radius_property, initial_value)
		else:
			p_height_object.set(p_height_property, initial_value)
		p_position_object.set(p_position_property, initial_transform.origin)
		return
	
	undo_redo.create_action(p_radius_action_name if p_id == 0 else p_height_action_name)
	if p_id == 0:
		undo_redo.add_do_property(p_radius_object, p_radius_property, p_radius_object.get(p_radius_property))
		undo_redo.add_undo_property(p_radius_object, p_radius_property, initial_value)
	else:
		undo_redo.add_do_property(p_height_object, p_height_property, p_height_object.get(p_height_property))
		undo_redo.add_do_property(p_position_object, p_position_property, p_position_object.get(p_position_property))
		undo_redo.add_undo_property(p_height_object, p_height_property, initial_value)
		undo_redo.add_undo_property(p_position_object, p_position_property, initial_transform.origin)
	undo_redo.commit_action(true)


class ConeSetHandleResult:
	
	
	var radius: float
	var height: float
	var cone_position: Vector3
	
	
	func _init(p_radius: float, p_height: float, p_cone_position: Vector3) -> void:
		radius = p_radius
		height = p_height
		cone_position = p_cone_position
