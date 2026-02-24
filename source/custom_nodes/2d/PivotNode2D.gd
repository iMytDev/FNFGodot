@tool
@icon("res://icons/Node2DPivot.svg")
class_name PivotNode2D extends Node2D

var _rid: RID
var _canvas_transform_offset: Vector2:
	set(val): _canvas_transform_offset = val; queue_redraw()

@export var pivot_offset: Vector2: set = set_pivot_offset
var _real_pivot: Vector2:
	set(val): 
		if _real_pivot == val: return
		_canvas_transform_offset -= val - _real_pivot
		_real_pivot = val;

func _init() -> void: set_notify_local_transform(true);
func _ready() -> void: _rid = get_canvas_item();
func _draw() -> void:
	var _transform = transform; _transform.origin += _canvas_transform_offset
	RenderingServer.canvas_item_set_transform(_rid,_transform)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED: if !_update_rotation_scale(): queue_redraw()



#region Pivot
func set_pivot_offset(val: Vector2) -> void: pivot_offset = val; _update_pivot()

var _last_scale: Vector2 = scale
var _last_rotation: float = rotation
func _update_rotation_scale() -> bool:
	var r = _get_rotation()
	if _last_scale == scale and _last_rotation == r: return false
	_last_rotation = rotation; _last_scale = scale; _update_pivot()
	return true

func _get_scale(): return scale
func _get_rotation(): return rotation
func _update_pivot() -> void:
	var pivot = _get_pivot()
	_real_pivot = (pivot.rotated(rotation) if rotation else pivot)*scale - pivot

#Replaced in Subclasses.
func _get_pivot() -> Vector2: return pivot_offset
#endregion
