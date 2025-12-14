@tool
class_name PivotSprite2D extends Sprite2D

@export var _position: Vector2:
	set(val): 
		if _position == val: return
		position += val - _position;
		_position = val;
		_update_position()

@export var pivot_offset: Vector2:
	set(val): 
		val = -val
		if offset == val: return
		offset = val; _update_position()
	get(): return -offset


func _init() -> void: set_notify_local_transform(true); centered = false

func _get_real_position() -> Vector2: return _position - offset

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"position": _position = value; return true
	return false

func _get(property: StringName) -> Variant:
	match property:
		&"position": return _position
	return

func _update_position() -> void: position = _get_real_position(); 

func set_pivot_offset(pivo: Vector2): offset = -pivo; _update_position()

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"position",&"offset",&"centered": property.usage = PROPERTY_USAGE_NONE

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE: _update_position();
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED: _check_transform()

func _draw() -> void: _update_position();

var _last_scale: Vector2
var _last_rotation: float
func _check_transform():
	if _last_scale == scale and _last_rotation == rotation: return
	_last_scale = scale
	_last_rotation = rotation
	_update_position()
