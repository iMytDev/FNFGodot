@tool
class_name SparrowMeshMaterial extends StandardMaterial3D
func _init():
	cull_mode = BaseMaterial3D.CULL_DISABLED
	transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"uv1_scale",&"uv1_offset",&"cull_mode",&"transparency",&"depth_draw_mode",&"vertex_color_use_as_albedo":
			property.usage = PROPERTY_USAGE_NONE
		&"albedo_texture":
			property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_NO_INSTANCE_STATE
