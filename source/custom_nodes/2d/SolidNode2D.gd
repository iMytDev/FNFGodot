@tool
@icon("res://icons/SolidNode2D.svg")
class_name SolidNode2D extends Node2D
@export var filled: bool = true: 
	set(val): filled = val; queue_redraw(); notify_property_list_changed()

@export var width: float = 3:
	set(val): width = val; if !filled: queue_redraw()

@export var size: Vector2 = Vector2(15,15): 
	set(val): size = val; queue_redraw(); if !filled: notify_property_list_changed()

@export_custom(PROPERTY_HINT_NONE, "suffix:m") var suffix: Vector3

func _get_rect(): return Rect2(Vector2.ZERO,size)

func _draw():
	if filled: draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)
	else:
		var w = width * 0.5
		var width_center = Vector2(w,w)
		draw_rect(Rect2(width_center,size - Vector2(width,width)),Color.WHITE,false,width)

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"width": 
			if filled:
				property.usage = PROPERTY_USAGE_NONE
			else: 
				property.usage = PROPERTY_USAGE_DEFAULT
				property.hint = PROPERTY_HINT_RANGE
				property.hint_string = "0,"+String.num(size[size.min_axis_index()]*0.5)+",0.5"
