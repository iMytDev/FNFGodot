@icon("res://icons/Chess.svg")
@tool
class_name Chess
extends Control

@export var primary_color: Color = Color.GRAY: set = set_primary_color
@export var secondary_color: Color = Color.DIM_GRAY: set = set_secondary_color

@export var rect_size: Vector2 = Vector2(30,30): set = set_rect_size
var _count: Vector2i


var _chess_image: Image = Image.create(2,2,false,Image.FORMAT_RGBA8)
var chess_texture: ImageTexture
func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _ready() -> void: 
	chess_texture = ImageTexture.create_from_image(_chess_image)
	_update_image_chess()
	resized.connect(_update_size); _update_size()

func _update_image_chess():
	if !chess_texture: return
	_chess_image.set_pixel(0,0,primary_color)
	_chess_image.set_pixel(1,1,primary_color)
	_chess_image.set_pixel(0,1,secondary_color)
	_chess_image.set_pixel(1,0,secondary_color)
	chess_texture.update(_chess_image)

func _update_size(): 
	_count = (size/rect_size).ceil()
	queue_redraw()

#region Setters

func set_rect_size(s: Vector2) -> void: var mult = s/rect_size; rect_size = s; if is_inside_tree(): size *= mult
func set_primary_color(color: Color) -> void: primary_color = color; _update_image_chess()
func set_secondary_color(color: Color) -> void: secondary_color = color; _update_image_chess()
#endregion

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0.0,rect_size)
	draw_texture_rect(chess_texture,Rect2(Vector2.ZERO, size / rect_size),true)

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"texture_filter",&"texture_repeat": property.usage = PROPERTY_USAGE_NONE
