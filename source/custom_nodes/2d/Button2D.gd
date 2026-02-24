class_name Button2D extends Node2D

@export var size: Vector2 = Vector2(10,10)
signal pressed()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Rect2(global_position,size).has_point(event.position): pressed.emit()
