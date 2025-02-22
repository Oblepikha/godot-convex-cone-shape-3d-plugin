@tool
extends EditorPlugin


const CollisionShape3DGizmoPlugin := preload("src/collision_shape_3d_gizmo_plugin.gd")


var gizmo_plugin := CollisionShape3DGizmoPlugin.new(get_undo_redo())


func _enter_tree() -> void:
	add_node_3d_gizmo_plugin(gizmo_plugin)


func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
