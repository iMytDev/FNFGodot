@tool
extends Camera3D

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"fov",&"h_offset",&"v_offset": 
			property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR
