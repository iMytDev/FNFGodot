@tool
class_name ChessScroll
extends Chess

@export var scroll_speed: Vector2 = Vector2(1,1)
var scroll: Vector2 = Vector2.ZERO

func _init() -> void: 
	super(); 
	clip_contents = true

func _process(delta: float) -> void:
	scroll += scroll_speed*delta
	scroll.x = fmod(scroll.x,2.0)
	scroll.y = fmod(scroll.y,2.0)
	queue_redraw()

func _draw() -> void:
	var pos = scroll * rect_size
	draw_set_transform(pos,0.0, rect_size)
	draw_texture_rect(chess_texture,Rect2(Vector2(-2,-2), (size) / rect_size - scroll + Vector2(2,2)),true)

func _validate_property(property: Dictionary) -> void:
	super(property)
	match StringName(property.name):
		&"scroll",&"clip_contents": 
			property.usage = PROPERTY_USAGE_NONE
