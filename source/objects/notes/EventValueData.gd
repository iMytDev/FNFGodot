@tool
class_name EventValueType extends Resource
const event_value_types: Array = [
	&"String",
	&"StringName",
	&"Float",
	&"int",
	&"bool",
	&"Vector2",
	&"Vector2i",
	&"Vector3",
	&"Vector3i",
	&"Vector4",
	&"Vector4i",
	&"EasingType",
	&"Folder"
]
@export var default: Variant = ""
@export var folder: String
@export var type_string: StringName = &"String":
	set(val): 
		type_string = val; _update_type(); notify_property_list_changed()

var cur_enum: PackedStringArray
var type: Variant.Type = TYPE_STRING

func _update_type():
	cur_enum = PackedStringArray()
	match type_string:
		&"Folder": type = TYPE_STRING_NAME
		&"EasingType":
			cur_enum = TweenService.get_tween_presets()
			type = TYPE_STRING
		_: type = MathUtils.get_type_by_name(type_string)
	if typeof(default) != type: default = MathUtils.get_new_value(type)

func _init() -> void: type_string = event_value_types[0]

func _property_can_revert(property: StringName) -> bool:
	match property:
		&"default": return true
		&"type_string": return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"default": return MathUtils.get_new_value(type)
		&"type_string": return type_string
	return

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"folder": property.usage = PROPERTY_USAGE_DEFAULT if type_string == &"Folder" else PROPERTY_USAGE_NONE
		&"default": 
			if type_string == &"Folder": 
				property.usage = PROPERTY_USAGE_NONE; 
				return
			property.type = type
			if cur_enum:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(cur_enum)
		&"type_string":
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(event_value_types)
