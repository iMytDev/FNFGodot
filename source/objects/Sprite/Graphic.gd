@tool
##A base [Sprite2D] to be compatible with [Anim].
extends Sprite2D

@export var _flip_h: bool = false:
	set(val): 
		if _flip_h == val: return
		scale.x = -1.0 if val else 1.0; _update_pivot_offset(); _flip_h = val
		on_flip_x.emit()

@export var _flip_v: bool = false:
	set(val): 
		if _flip_v == val: return
		scale.y = -1.0 if val else 1.0; _update_pivot_offset(); _flip_v = val;
		on_flip_y.emit()
var _frame_offset: Vector2: set = set_frame_offset
var _frame_angle: float:
	set(value): _frame_angle = value; rotation = _frame_angle*scale.x

var pivot_offset: Vector2: 
	set(val): pivot_offset = val; _update_pivot_offset()

var _real_pivot_offset: Vector2:
	set(val):
		if val == _real_pivot_offset: return
		_real_pivot_offset = val
		_update_offset()

var is_solid: bool: set = set_solid

signal on_flip_x()
signal on_flip_y()

func _init() -> void: 
	process_mode = Node.PROCESS_MODE_DISABLED
	region_enabled = true; centered = false; region_filter_clip_enabled = true;
	texture_changed.connect(_texture_changed)

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"flip_h": _flip_h = value; _update_pivot_offset(); return true
		&"flip_v": _flip_v = value; _update_pivot_offset(); return true
	return false

func _get(property: StringName) -> Variant:
	match property:
		&"flip_h": return _flip_h
		&"flip_v": return _flip_v
	return

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"texture",&"position",&"rotation", &"flip_h", &"flip_v": 
			property.usage = PROPERTY_USAGE_NONE

func _enter_tree() -> void: _update_offset()

func _update_offset() -> void: position = _frame_offset - _real_pivot_offset

func _update_pivot_offset(): _real_pivot_offset = (pivot_offset*scale - pivot_offset)

func set_graphic_size(size: Vector2) -> void: if is_solid: scale = size; return
func set_frame_offset(off: Vector2) -> void: _frame_offset = off*scale; _update_offset();
func _texture_changed() -> void: _frame_offset = Vector2.ZERO; rotation = 0;


func set_solid(solid: bool = true):
	if is_solid == solid: return
	is_solid = solid
	set_notify_local_transform(!solid)
	if !solid:
		item_rect_changed.disconnect(queue_redraw)
		queue_redraw()
		return
	pivot_offset = Vector2.ZERO
	texture = null
	is_solid = true
	centered = true
	scale = Vector2.ONE
	item_rect_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void: if is_solid: draw_rect(Rect2(Vector2.ZERO,region_rect.size),Color.WHITE)
