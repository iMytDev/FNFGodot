@tool
@icon("res://icons/Camera2D.svg")
class_name FunkinScroll2D extends Node2D

@export var scroll: Vector2:
	set(val): scroll = val; _update_pivot()

@export var _rotation: float:
	set(val): _rotation = val; _update_pivot()

@export var zoom: float = 1.0:
	set(val): zoom = val; zoom_vec.x = zoom; zoom_vec.y = zoom; _update_pivot()

@export var pivot_offset: Vector2 = Vector2.ZERO:
	set(val): pivot_offset = val; _update_pivot()

var _real_pivot_offset: Vector2:
	set(val): _real_pivot_offset = val; queue_redraw()

var zoom_vec: Vector2 = Vector2.ONE

func move_child_notify(node: Node): print(node)

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"rotation": _rotation = value;
		_: return false
	return true

func _get(property: StringName) -> Variant:
	match property:
		&"rotation": return _rotation
	return


func _update_pivot() -> void:
	var real_scroll = pivot_offset + scroll
	var pivot = real_scroll
	if _rotation: pivot = pivot.rotated(_rotation)
	if zoom != 1.0: pivot *= zoom
	_real_pivot_offset = pivot - real_scroll

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"rotation",&"position": property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR


func get_real_scroll() -> Vector2:  return -scroll - _real_pivot_offset
func _draw():
	RenderingServer.canvas_item_set_transform(
		get_canvas_item(), Transform2D(_rotation,zoom_vec,0.0, get_real_scroll())
	)
