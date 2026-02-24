@tool
class_name Anim extends Resource
##A class to run Spritesheet Animations.[br] Compatible with XML Sparrow and .txt animations.[br][br]
##Setup:[codeblock]
##extends Sprite2D
##var animation = Anim.new()
##func _ready():
##	animation.node_to_animate = self #Node that will be animated.
##[/codeblock]
##How to run a animation:[br]
##Files Demonstration:[codeblock]
##"path/to/texture/image.png" #< - image path
##"path/to/texture/image.xml" #< - XML/TxT File, must have the same name as the texture.
##[/codeblock]
##Code:[codeblock]
##extends Sprite2D
##func _ready():
##	texture = load("path/to/texture/image.png")
##	animation.add_animation_by_prefix("animationName", "prefix", 24.0, true)
##[/codeblock]

var _anim_file: StringName
var _float_frame: float
@export_storage var animationsArray: Dictionary: ##Stores the dates of created animations. See also [method insertAnim].
	set(val): animationsArray = val; notify_property_list_changed()

@export var curAnim: AnimationData

##The Node that will have his values changed.[br]
##[b]Note:[/b] The object [b]NEEDS[/b] to contain this properties to work correctly:[codeblock]
##signal texture_changed()
##var texture: Texture2D[/codeblock]
var node_to_animate: Object:  set = set_node_to_animate
var animations_use_textures: bool 


#region Animation Player Vars


@export_category("Player Properties")
@export var current_animation: StringName: set = set_current_animation ##The name of the current animation.
@export var playing: bool = true ##If [code]false[/code], the animation will not process.
@export var frame: int: ##The current frame of the animation.
	set(val): if frame != val: frame = val; _on_frame_set()
@export var finished: bool
@export_range(0,10,0.05) var speed_scale: float = 1.0 ##A multiplier for the frame rate.

## if [code]true[/code], when the animation ends and the animator have the same animation name 
##with "-loop" at the end, that animation will be played.[br][br]
##Example:[codeblock]
##var animation = Anim.new()
##animation.add_animation_by_prefix(&'idle',&'prefix1',24,false)
###When the "idle" animation ends, "idle-loop" will be played automatically
##animation.add_animation_by_prefix(&'idle-loop',&'prefix2',24,true,[5,6,7])
##[/codeblock]
@export var auto_loop: bool

var frame_data: Dictionary
var maxFrames: int ##The number of frames in the animation.

signal animation_added(anim_name) ##Emiited when a animation is added to [member animations_array] using [method insertAnim]
signal animation_finished(anim_name: StringName)
signal animation_started(anim_name: StringName) ##Emitted when a animation starts.
signal animation_changed(old_anim: StringName,new_anim: StringName) ##Emitted when the animation changes.
signal animation_renamed(old_name: StringName,new_name: StringName) ##Emitted when a animation is renamed.
signal animation_updated(anim_name: StringName) ##Emitted when a animation is renamed.
signal animation_stopped()
#endregion

#region Player Methods
##Play animation.[br][br]
##Returns [code]true[/code] if the animation starts.[br][br]
##If [param force] is [code]true[/code], the animation will be forced to restart if already playing.[br]
##See also [method play_reverse].
func play(anim: StringName = current_animation, force: bool = false) -> bool:
	if !can_play(anim,force): return false
	current_animation = anim
	update_anim()
	_float_frame = 0.0; 
	frame = 0;
	_start_anim()
	return true

func stop() -> void: playing = false; _float_frame = 0; animation_stopped.emit() ##Stop animation.

func can_play(anim: StringName, force: bool = false) -> bool:
	return anim in animationsArray and (force or !playing or current_animation != anim)

func play_random(force: bool = false): if animationsArray: play(animationsArray.keys().pick_random(), force)

func play_reverse(anim: StringName, force: bool = false) -> void: ##Plays the animation from end to beggining. See also [method play]
	if !can_play(anim,force): return
	current_animation = anim
	update_anim()
	frame = maxFrames-1; 
	_float_frame = frame;
	_start_anim()
#endregion

func set_animation_file_from_texture(texture: Texture2D):
	if !texture: _anim_file = ''; return
	_anim_file = AnimationService.findAnimFile(texture.resource_path)
	if !_anim_file: _anim_file = AnimationService.findAnimFile(texture.resource_name)



#region Animation Methods
##Add Animation from [u]Sparrow[/u]. Returns [code]true[/code] if the animation as added, [code]false[/code] otherwise.[br][br]
##To make the animation play specific frames, you can use [param indices], can be set as a [String] or a [Array]:[codeblock]
##var animation = Anim.new()
##animation.node_to_animate = self
##animation.add_animation_by_prefix('indices_array','prefix',24.0,false,[0,1,2,5,6]) #Using Array
##animation.add_animation_by_prefix('indices_string','prefix',24,false,"0,1,2,3,4,5") #Using String
##[/codeblock]
func add_animation_by_prefix(animName: StringName, prefix: StringName, fps: float = 24.0, loop: bool = false, indices: PackedInt32Array = PackedInt32Array()) -> AnimationData:
	var frames = AnimationService.get_anim_frames(prefix, _anim_file, indices); if !frames: return
	var anim_data = AnimationData.new()
	anim_data.frames = frames
	anim_data.looped = loop
	anim_data.prefix = prefix
	anim_data.frameRate = fps
	insert_animation(animName,anim_data)
	return anim_data

##Add frame animation.
##To works, the [param region_rect.size] of the [member image] have to be defined, 
##that will be used as offset to which frame.[br][br]
##For example, if the image texture's size is [code]60x60[/code], 
##and you want to cut it in 3 horizontal parts, 
##then set [param region_rect] from [param image] to [code]20x60[/code](or [code]60x20[/code]
##if you want to cut vertically).
func add_frame_animation(animName: StringName, indices: PackedInt32Array = PackedInt32Array(), fps: float = 24.0, loop: bool = false) -> AnimationData:
	return AnimationService.add_frame_anim(self,animName,indices,fps,loop)

func add_animation_offset(animName: StringName, _offset: Vector2):
	var _d = animationsArray.get(animName); if !_d: return 
	_d.set_meta(&"offset",_offset)
	if current_animation == animName: animation_updated.emit(current_animation);

func remove_animation(anim_name: StringName) -> AnimationData: 
	var d = animationsArray.get(anim_name); if !d: return
	animationsArray.erase(anim_name); return d

##Clear Library, removing all the Animations from the Node.
func clearLibrary() -> void: stop(); animationsArray.clear(); 
func has_animation(anim: StringName) -> bool: return animationsArray.has(anim) ##Returns [code]true[/code] if the [param anim] exists.

func has_any_animations(anims: PackedStringArray) -> bool: ##Returns [code]true[/code] if the animator have any animations from [param anims].
	for i in anims: if animationsArray.has(i): return true
	return false

func setup_animation_textures() -> void:
	if animations_use_textures: return
	animations_use_textures = true
	for i in animationsArray.values(): if !i.asset: i.asset = node_to_animate.texture


##Set the texture of a specific animation.
##When the [param anim_name] is played, the [member image] will change his texture to [param _texture].
func set_animation_texture(anim_name: StringName, _texture: Texture2D) -> void:
	var anim_data = animationsArray.get(anim_name); if !anim_data: return
	if _texture and node_to_animate and node_to_animate.texture == anim_data.asset: return
	setup_animation_textures()
	anim_data.asset = _texture
#endregion

#region Setters
func set_current_animation(anim: StringName):
	if anim == current_animation: return
	var old_anim = current_animation
	current_animation = anim
	update_anim()
	animation_changed.emit(old_anim,anim)
	if Engine.is_editor_hint(): play(anim,true)

func set_node_to_animate(object: Object) -> void:
	if node_to_animate and node_to_animate.texture_changed.is_connected(_texture_updated): node_to_animate.texture_changed.disconnect(_texture_updated)
	node_to_animate = object
	if object: object.texture_changed.connect(_texture_updated)
	_texture_updated()
	notify_property_list_changed()
#endregion

#region Property Methods
func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"current_animation":
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ','.join(animationsArray.keys())
		&"finished", &"playing":
			property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_NO_INSTANCE_STATE
		&"animationsArray":
			property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_STORAGE
		&"frame":
			property.hint = PROPERTY_HINT_RANGE
			property.hint_string = "0,"+String.num_int64(maxFrames-1)
		
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"frame": frame = (clampi(value,0,maxi(0,maxFrames-1)));
		_: return false
	return true
#endregion

#region Internal Methods
func _texture_updated(): 
	set_animation_file_from_texture(node_to_animate.texture)
	_on_frame_safe_set()

func _verify_loop(anim: String): if !play(anim+'-loop',true): play(anim+'-hold',true);

func _start_anim():
	finished = false
	if curAnim.frames: 
		playing = true
		_on_frame_set()
	animation_started.emit(current_animation)

func update_anim():
	curAnim = animationsArray.get(current_animation); 
	if !curAnim: return
	if animations_use_textures and curAnim.asset: node_to_animate.texture = curAnim.asset
	maxFrames = curAnim.frames.size()
	animation_updated.emit(current_animation)

func _finish_animation() -> void:
	if finished: return
	finished = true; playing = false
	animation_finished.emit(current_animation)
	if auto_loop: _verify_loop(current_animation)

func insert_animation(animName: StringName, animData: AnimationData) -> void:
	if !animData: return
	animationsArray[animName] = animData
	
	if !current_animation: play(animName)
	elif animName == current_animation: update_anim(); play(animName,true); 
	
	if animations_use_textures and !animData.asset: animData.asset = node_to_animate.texture
	animation_added.emit(animName)
	notify_property_list_changed()
#endregion

#region Process Animation
func process_frame(delta: float) -> void: ##Process animation
	if !playing or !curAnim: return
	_float_frame += delta*curAnim._real_frame_rate*speed_scale
	
	var int_frame = int(_float_frame)
	if int_frame < 0 or int_frame >= maxFrames: 
		if curAnim.looped: 
			int_frame = curAnim.loop_frame; _float_frame = int_frame;
		else: _finish_animation()
		return
	frame = int_frame;

func _on_frame_safe_set() -> void:
	if !curAnim or curAnim.frames.size() < frame: return
	_on_frame_set()

func _on_frame_set():
	frame_data = curAnim.frames[frame]
	if !node_to_animate: return
	for i in frame_data: 
		match typeof(i):
			TYPE_STRING_NAME, TYPE_STRING: node_to_animate.set(i,frame_data[i])
			TYPE_NODE_PATH: node_to_animate.set_indexed(i,frame_data[i])
#endregion
