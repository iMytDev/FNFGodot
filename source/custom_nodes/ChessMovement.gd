@tool
class_name ChessScroll
extends Chess

@export var scroll_speed: Vector2 = Vector2(20,20)
var scroll: Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
	scroll += scroll_speed*delta
	scroll = scroll.posmodv(rect_size)
	RenderingServer.canvas_item_set_transform(node.get_canvas_item(),Transform2D(0.0,_node_offset + scroll - rect_size))
