@tool
class_name AtlasSprite2D extends Node2D
@export var texture: Texture2D: set = set_texture

@export var animation_data: Dictionary
var _current_animation_data: Array

@export var frame: int: set = set_frame
 
@export var frame_data: Array
@export var sprites: Dictionary[int, Rect2]
@export var current_animation: StringName: set = set_current_animation

func set_current_animation(anim: StringName):
	current_animation = anim
	_current_animation_data = animation_data.get(anim,[])
	notify_property_list_changed()

func set_frame(f: int):
	frame = clampi(f,0,_current_animation_data.size()-1)
	if !_current_animation_data: frame_data = []
	else: frame_data = _current_animation_data[frame]
	queue_redraw()

func set_texture(tex: Texture2D):
	texture = tex
	if !tex: _clear();
	else: _load_atlas()

func _clear():
	animation_data = {}
	frame_data = []
	sprites = {}

func _load_atlas():
	if !texture: return
	sprites = Atlas._load_map_sprites(texture.resource_path.get_base_dir()+'/spritemap1.json')
	animation_data = Atlas._load_map_animations(texture.resource_path.get_base_dir()+'/Animation.json')
	notify_property_list_changed()


func _draw() -> void:
	if !frame_data: return
	var id: int = 0
	for i in frame_data:
		draw_set_transform_matrix(i.transform)
		draw_texture_rect_region(
			texture,
			Rect2(Vector2.ZERO,sprites[id].size),
			sprites[id]
		)
		id += 1

func _validate_property(property) -> void:
	match StringName(property.name):
		&"frame":
			property.hint_string = ','.join(range(_current_animation_data.size()))
		&"current_animation": 
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ','.join(animation_data.keys())
