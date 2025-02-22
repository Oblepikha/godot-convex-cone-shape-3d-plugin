extends EditorNode3DGizmoPlugin


const Gizmo3DHelper := preload("gizmo_3d_helper.gd")


var undo_redo: EditorUndoRedoManager
var helper: Gizmo3DHelper


func _init(p_undo_redo) -> void:
	undo_redo = p_undo_redo
	helper = Gizmo3DHelper.new(undo_redo)
	
	create_handle_material("handles")


func _get_gizmo_name() -> String:
	return "ConvexConeShape3D"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is CollisionShape3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	var col_shape := gizmo.get_node_3d() as CollisionShape3D
	
	gizmo.clear()
	
	var shape := col_shape.shape
	if not shape:
		return
	
	var handles_material := get_material("handles")
	
	if shape is ConvexConeShape3D:
		var cone_shape := shape as ConvexConeShape3D
		
		var handles := helper.cone_get_handles(cone_shape.height, cone_shape.radius)
		gizmo.add_handles(handles, handles_material, [])


func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	var node := gizmo.get_node_3d() as CollisionShape3D
	
	var shape := node.shape
	if not shape:
		return ""
	
	if shape is ConvexConeShape3D:
		return helper.cone_get_handle_name(handle_id)
	
	return ""


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	var col_shape := gizmo.get_node_3d() as CollisionShape3D
	
	var shape := col_shape.shape
	if not shape:
		return null
	
	if shape is ConvexConeShape3D:
		var cone_shape := shape as ConvexConeShape3D
		return cone_shape.radius if handle_id == 0 else cone_shape.height
	
	return null


func _begin_handle_action(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> void:
	helper.initialize_handle_action(_get_handle_value(gizmo, handle_id, secondary), gizmo.get_node_3d().global_transform)


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var col_shape := gizmo.get_node_3d() as CollisionShape3D
	
	var shape := col_shape.shape
	if not shape:
		return
	
	var segment: PackedVector3Array = helper.get_segment(camera, screen_pos)
	
	if shape is ConvexConeShape3D:
		var cone_shape := shape as ConvexConeShape3D
		
		if handle_id == 0:
			var transform := helper.initial_transform
			helper.initial_transform = transform.translated_local(Vector3(0.0, -cone_shape.height * 0.5, 0.0))
			segment = helper.get_segment(camera, screen_pos)
			helper.initial_transform = transform
		
		var result := helper.cone_set_handle(segment, handle_id, cone_shape.radius, cone_shape.height, col_shape.global_position)
		cone_shape.radius = result.radius
		cone_shape.height = result.height
		col_shape.global_position = result.cone_position


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	var col_shape := gizmo.get_node_3d() as CollisionShape3D
	
	var shape := col_shape.shape
	if not shape:
		return
	
	if shape is ConvexConeShape3D:
		var cone_shape = shape as ConvexConeShape3D
		helper.cone_commit_handle(handle_id, "Change Cone Shape Radius", "Change Cone Shape Height", cancel, col_shape, cone_shape, cone_shape)
