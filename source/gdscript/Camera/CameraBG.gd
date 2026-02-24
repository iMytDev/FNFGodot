class_name CameraBG extends Node2D
var parent: Node
func _init() -> void: top_level = true

func _draw() -> void:
	if !get_parent(): return
	draw_rect(Rect2(Vector2.ZERO,get_parent().get_viewport().size), Color.WHITE)
