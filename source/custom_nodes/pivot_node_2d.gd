@tool
class_name PivotNode2D extends Node2D

@export var pivot_offset: Vector2: set = set_pivot_offset
var _real_pivot: Vector2:
	set(val): 
		if _real_pivot == val: return
		position -= val - _real_pivot;
		_real_pivot = val;

@export var _position: Vector2:
	set(val): 
		if _position == val: return
		position += val - _position; 
		_position = val

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"position": _position = value; return true
	return false

func _get(property: StringName) -> Variant:
	match property:
		&"position": return _position
	return

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"position",&"_last_scale",&"_last_rotation": property.usage = PROPERTY_USAGE_NONE

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE: set_notify_local_transform(true); _check_transform(); _update_position()
		NOTIFICATION_EXIT_TREE: set_notify_local_transform(false)
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED: _check_transform()



#region Pivot
var _last_scale: Vector2 = scale
var _last_rotation: float = rotation
func _check_transform() -> void:
	if _last_scale == scale and _last_rotation == rotation: return
	_last_rotation = rotation
	_last_scale = scale
	_update_pivot()


func set_pivot_offset(val: Vector2): pivot_offset = val; _update_pivot()
func _update_pivot() -> void:
	if !pivot_offset: _real_pivot = Vector2.ZERO; return
	var pivo = pivot_offset
	if rotation: pivo = pivo.rotated(rotation)
	if scale != Vector2.ONE: pivo *= scale
	_real_pivot = pivo - pivot_offset

func _update_position() -> void: position = _get_real_position()
func _get_real_position() -> Vector2: return _position - _real_pivot
#endregion
