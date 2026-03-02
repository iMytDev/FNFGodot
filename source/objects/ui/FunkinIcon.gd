@tool
@icon("res://icons/icon.svg")
class_name FunkinIcon extends FunkinAnimatedSprite2D

enum State{
	NORMAL,
	LOSING,
	WINNING
}

var animated: bool
var hasWinningIcon: bool

@export var default_scale: Vector2 = Vector2.ONE
@export var scale_lerp: bool = false:
	set(val): scale_lerp = val; notify_property_list_changed();

@export var cur_icon: StringName
@export_tool_button("Load Icon","Image") var c = changeIcon

var beat_value: Vector2 = Vector2(0.2,0.2)
var scale_lerp_time: float = 10.0

var isPixel: bool

func _init(texture: String = ''): super(); if texture: changeIcon(texture);
func _ready() -> void: super(); if cur_icon: changeIcon(cur_icon);

func changeIcon(icon: StringName = cur_icon):
	var tex = Paths.icon(icon); if !tex: tex = Paths.icon('icon-face')
	set_icon(tex)

func set_icon(icon: Texture):
	if animated: animation.clearLibrary()
	image.texture = icon; if !icon: return
	hasWinningIcon = icon.resource_name.get_base_dir().ends_with("winning_icons")
	animated = FileAccess.file_exists(image.texture.resource_name+'.xml')
	
	if animated:
		animation.add_animation_by_prefix(&'normal',&'Default',24,true)
		animation.add_animation_by_prefix(&'losing',&'Losing',24,true)
		animation.add_animation_by_prefix(&"winning",&'Winning',24,true)
		return
	
	var size: Vector2
	if hasWinningIcon:
		image.region_rect.size = Vector2(imageSize.x / 3.0,imageSize.y)
		animation.add_frame_animation(&'normal',[0])
		animation.add_frame_animation(&'losing',[1])
		animation.add_frame_animation(&'winning',[2])
	else:
		image.region_rect.size = Vector2(imageSize.x * 0.5,imageSize.y)
		animation.add_frame_animation(&'normal',[0])
		animation.add_frame_animation(&'losing',[1])

func reloadIconFromCharacterJson(json: Dictionary): 
	json = json.get(&'healthIcon',{})
	changeIcon(json.get(&'id',&'icon-face')); 
	set_pixel(json.get(&'isPixel',false),json.get(&'canScale',false))

func _process(delta: float) -> void:
	if scale_lerp and scale != default_scale: scale = scale.lerp(default_scale,delta*scale_lerp_time)
	super(delta)


func set_pixel(is_pixel: bool = false, scale_if_pixel: bool = false):
	if is_pixel == isPixel: return
	var _scale: Vector2 = Vector2.ONE
	texture_filter = TEXTURE_FILTER_NEAREST if is_pixel else TEXTURE_FILTER_LINEAR
	if scale_if_pixel and is_pixel: _scale = Vector2(4.5,4.5); beat_value = Vector2(0.6,0.6)
	else: _scale = Vector2.ONE; beat_value = Vector2(0.2,0.2)
	isPixel = is_pixel
	scale = _scale
	default_scale = _scale

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"default_scale": property.usage = PROPERTY_USAGE_DEFAULT if scale_lerp else PROPERTY_USAGE_NONE
		_: super(property)
