@tool
extends Camera3D
const DEFAULT_FOV = 75.0

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"fov",&"h_offset",&"v_offset": 
			property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR
