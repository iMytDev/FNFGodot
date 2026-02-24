@tool
class_name SparrowAnimatedSprite2D extends SparrowSprite

var current_animation_frames: Array
var cur_frame_data: Dictionary
var animation_data: Dictionary
var _is_setting_frame: bool

##If true, the script will try to find his sparrow [br]
##when the texture changes.
@export var auto_load_sparrow: bool = false

@export_tool_button("Load Sparrow") var b = _load_sparrow
@export var animation: StringName: set = set_animation
@export var frame: int = 0: set = set_frame
var _real_frame: float: set = _set_real_frame

@export var fps: float = 24.0
@export var playing: bool
@export var auto_play: bool = true ##Auto play the current animation when added to scene.
@export var looped: bool



func _ready() -> void: if auto_play: playing = true

func set_texture(tex: Texture2D):
	super(tex); if !auto_load_sparrow: _load_sparrow()

func _load_sparrow():
	if !texture: animation_data = {}; notify_property_list_changed(); return
	var path = texture.resource_path
	if !path: path = texture.resource_name; if !path: return
	_load_sparrow_from_path(path.get_basename()+'.xml')

func _load_sparrow_from_path(path: String):
	animation_data = Sparrow._load_sparrow(path)
	if animation_data: animation = animation_data.keys()[0]
	_detect_pivot()
	notify_property_list_changed()

func _detect_pivot():
	for i in animation_data.values():
		for anim in i:
			var rect = anim.get(&"region_rect");
			if rect and rect.size: pivot_offset = rect.size/2.0; break
		if pivot_offset: break

func set_animation(anim: StringName):
	if animation == anim: return
	animation = anim
	current_animation_frames = animation_data.get(anim)
	frame = 0
	_real_frame = 0.0
	notify_property_list_changed()

func set_frame(f: int): 
	frame = clampi(f,0,current_animation_frames.size())
	if !current_animation_frames: return
	
	_is_setting_frame = true
	
	cur_frame_data = current_animation_frames[frame]
	frameData = cur_frame_data.get(&"frameData",Rect2(0,0,0,0))
	region_rect = cur_frame_data.get(&"region_rect",Rect2(0,0,0,0))
	
	rotated = cur_frame_data.get(&"rotated",false)
	
	_is_setting_frame = false; 
	queue_redraw()

func _draw() -> void: if !_is_setting_frame: super()

func _set_real_frame(f: float):
	_real_frame = f
	var int_f = int(f)
	if int_f >= current_animation_frames.size(): 
		if looped: int_f = 0; _real_frame = 0.0;
		else: _real_frame = 0.0; playing = false; return
	frame = int_f

func _process(delta: float) -> void: if playing: _real_frame += delta*fps

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&'frame': frame = value; _real_frame = value; return true
	return false

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"animation_data",&"region_rect",&"_frame_offset",&"rotated":
			property.usage = PROPERTY_USAGE_STORAGE
		&"cur_frame_data",&"current_animation_frames":
			property.usage = PROPERTY_USAGE_READ_ONLY
		&"animation":
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(animation_data.keys())
		&"frame":
			property.usage = PROPERTY_USAGE_DEFAULT
			property.hint = PROPERTY_HINT_RANGE
			property.hint_string = "-,"+str(current_animation_frames.size()-1)
