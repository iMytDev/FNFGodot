@icon("res://icons/StrumNote.png")
@tool
class_name StrumNote extends FunkinAnimatedSprite2D ##Strum Note
static var keyCount: int = 4

@export var data: int: ##Strum Direction
	set(val): data = val; _data_mod = val % keyCount
var _data_mod: int

##Direction of the note in radius. [br]
##Example: [code]deg_to_rad(90)[/code] makes the notes come from the left,
##while [code]deg_to_rag(180)[/code] makes come from the top.[br]
##[b]Obs:[/b] If [param downscroll] is [code]true[/code], the direction is inverted.
var direction: float:
	set(value): direction = value; _direction_radius = deg_to_rad(value)
var _direction_radius: float:
	set(value): _direction_radius = value; _direction_lerp = Vector2(cos(value),sin(value))
var _direction_lerp: Vector2 = Vector2(0,1) #Used in Notes.gd

var mustPress: bool:
	set(val): mustPress = val; return_to_static_on_finish = !val

##The [Input]s of the note, see [method Input.is_action_just_pressed]
var hit_actions: PackedInt32Array ##Hit Key

var return_to_static_on_finish: bool = true
@export var default_scale: float = 0.7

@export var isPixelNote: bool: ##Pixel Note
	set(val): 
		isPixelNote = val; 
		texture_filter = TEXTURE_FILTER_NEAREST if isPixelNote else TEXTURE_FILTER_LINEAR


var styleName: StringName
var styleData: NoteStyleData = NoteStyleData.new()

var texture: String: set = set_strum_texture ##Strum Texture
var specialAnim: bool ##If [code]true[/code], make the strum don't make to Static anim when finish's animation

var downscroll: bool: set = set_downscroll ##Invert the note direction.

var multSpeed: float = 1.0: set = setMultSpeed ##The note speed multiplier.

## Time used to determine when the strum should return to the 'static' animation after being hit.
## When this reaches 0, the 'static' animation is played.
var hitTime: float

signal mult_speed_changed
func _init(dir: int = 0):
	super()
	data = dir
	offset_follow_scale = true
	offset_follow_rotation = true
	animation.animation_finished.connect(_on_animation_finished)
	var inputs = Note.getInputActions()
	hit_actions = inputs[minf(_data_mod,inputs.size()-1)]

func reloadStrumNote() -> void: ##Reload Strum Texture Data
	offset = Vector2.ZERO
	image.texture = Paths.texture(texture)
	
	if styleData and styleData.get('data'): _load_anims_from_prefix()
	else: _load_graphic_anims()
	image.scale = Vector2(default_scale,default_scale)

const _anim_direction: PackedStringArray = ['left','down','up','right']
func _load_anims_from_prefix() -> void:
	var type: String = _anim_direction[_data_mod]
	
	var press_data = styleData.data[type+'Press']
	var static_data = styleData.data[type+'Static']
	var confirm_data = styleData.data[type+'Confirm']
	
	animation.add_animation_by_prefix(&'static',static_data.prefix,24,true)
	animation.add_animation_by_prefix(&'confirm',confirm_data.prefix,24,false)
	animation.add_animation_by_prefix(&'press',press_data.prefix,24,false)
	animation.add_animation_offset(&"static", static_data.get(&'offsets',Vector2.ZERO))
	animation.add_animation_offset(&"confirm", confirm_data.get(&'offsets',Vector2.ZERO))
	animation.add_animation_offset(&"press", press_data.get(&'offsets',Vector2.ZERO))

func _load_graphic_anims() -> void:
	var keyCount: int = Conductor.songData.keyCount
	image.region_rect.size = imageSize / Vector2(keyCount,5)
	animation.add_frame_animation(&'static',[_data_mod])
	animation.add_frame_animation(&'confirm',[_data_mod + (keyCount*3),_data_mod + (keyCount*4),_data_mod + keyCount])
	animation.add_frame_animation(&'press',[_data_mod + (keyCount*3),_data_mod + (keyCount*2)])

func loadFromStyle(noteStyle: StringName):
	if !noteStyle: noteStyle = &'funkin'
	styleName = noteStyle
	_update_style_data()
	isPixelNote = styleData.is_pixel()
	default_scale = styleData.get_scale()
	texture = styleData.get_asset_path()

func _update_style_data(): styleData.load_from_style_json(styleName,&'strums')

func _on_texture_changed() -> void: super(); animation.clearLibrary()

#region Setters
func set_strum_texture(_texture: String) -> void: texture = _texture; reloadStrumNote()


func setMultSpeed(speed: float) -> void:
	if speed == multSpeed: return
	multSpeed = speed; mult_speed_changed.emit()

func set_downscroll(down: bool) -> void: downscroll = down; mult_speed_changed.emit()
#endregion


func strumConfirm(anim: StringName = &'confirm') -> void:
	animation.play(anim,true)
	hitTime = Conductor.bpm_data.stepCrochetMs
	return_to_static_on_finish = !mustPress

func _process(delta: float) -> void: super(delta); if hitTime: _update_hit_time(delta)

func _update_hit_time(delta: float) -> void:
	hitTime -= delta
	if hitTime <= 0.0: hitTime = 0.0; animation.play(&'static')

func _unhandled_input(event: InputEvent) -> void:
	if !mustPress: return
	if event is InputEventKey:
		if event.echo or !event.keycode in hit_actions: return
		if event.pressed: animation.play(&'press',true)
		else: animation.play(&'static')

func _on_animation_finished(anim: StringName):if return_to_static_on_finish and anim != &'static': animation.play(&'static')

func _property_can_revert(property: StringName) -> bool:
	match property:
		&'data',&'styleData': return false
	return true

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'direction': return 0.0
		&'multSpeed': return 1.0
		&'mustPress': return false
		&'scale': return Vector2(default_scale,default_scale)
	return null
