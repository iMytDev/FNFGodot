@tool
@icon("res://icons/FunkinMicrophone.svg")
##A Character 2D Class
class_name Character2D extends FunkinAnimatedSprite2D
#region Dance Variables
@export_category("Dance Properties")
##how many beats should pass before the character dances again. For example:[br]
##If it's [code]2[/code], the character will dance every second beat.[br]
##If it's [code]1[/code], will dance on every beat.
@export var danceEveryNumBeats: int = 2
@export var danceAfterHold: bool = true ##If [code]false[/code], the character will not dance after the hold time.[br]See also [param holdLimit].
@export var danceOnAnimEnd: bool ##If [code]true[/code], the character will dance when a "sing" animation ends.
@export var forceDance: bool ##If [code]true[/code], the dance animation will be reset every beat hit, making character dance even though the animation hasn't finished.
@export var singDuration: float = 4.1: set = set_sing_duration ##The duration of the sing animations.
var danced: bool #Used to make the "danceLeft/danceRight" animation.

##If [code]false[/code], the character will not return to dance while pressing the sing keys.[br]
##OBS: This property is set automatically in PlayState scripts.
@export_storage var autoDance: bool = true

@export_category("Character Properties")
@export_placeholder("bf") var curCharacter: String ##The name of the character json.
@export_tool_button("Load Character") var char_method = loadCharacter

@export var charType: Character.Type = Character.Type.BF: set = set_character_type
@export var positionArray: Vector2: set = set_position_array ##The offset of the character position.

@export_storage var imageFile: StringName: set = set_image_file ##The Path from the current image

@export_placeholder("icon-face") var healthIcon: String ##The [u]name[/u] of icon that will be showed in health bar.
@export_color_no_alpha var healthBarColors: Color = Color.WHITE ##The color of the character bar.

@export var cameraPosition: Vector2 ##The camera position offset.
@export_storage var json: Dictionary[StringName, Variant] ##The character json. See also [method loadCharacter]
@export_storage var jsonScale: float = 1.0 ##The Character Scale from his json.
@export var jsonScaleMult: float = 1.0
#endregion



@export_category("Animation Properties")
var _is_playing_sing_anim: bool

##If [code]true[/code], the character will not play dance and 
##not play sing animations when a note is hit.
var stunned: bool

##Optional suffix appended to the "idle" animation name.[codeblock]
##idleSuffix = ''; dance(); #Plays "idle"
##idleSuffix = '-alt'; dance(); #Plays "idle-alt"[/codeblock]
var idleSuffix: String 


var hasDanceAnim: bool ##If character have "danceLeft" or "danceRight" animation.
var specialAnim: bool ##If [code]true[/code], the character will not return to dance while the current animation ends.
var hasMissAnimations: bool ##If the character have any miss animation.

##If [code]true[/code], the [code]singLEFT[/code] and [code]singRIGHT[/code] 
##will be inverted when the character flips horizontally. 
var mirror_sing_on_flip: bool = true: set =set_mirror_sing_on_flip
#endregion

@export_category("Hold Properties")
var holdTimer: float ##The duration that the character is in sing animation.
var holdKeys: PackedInt32Array #Set when a note is hit.
var heyTimer: float ##The duration that the character is in the "Hey" animation.

var holdLimit: float = 1.0: set = set_hold_limit ##The time limit to return to idle animation.
var _real_hold_limit: float = singDuration


#region Setters
func set_sing_duration(d: float) -> void: singDuration = d; if !Engine.is_editor_hint(): _update_hold_limit()
func set_hold_limit(limit: float) -> void: holdLimit = limit; if !Engine.is_editor_hint(): _update_hold_limit()
func set_image_file(file: StringName) -> void: imageFile = file; image.texture = Paths.texture(file)
func set_character_type(type: Character.Type) -> void: charType = type; _update_character_flip()
func set_position_array(val: Vector2) -> void: _canvas_transform_offset += val - positionArray;  positionArray = val; _update_pivot()
func set_mirror_sing_on_flip(flip: bool) -> void:
	if flip == mirror_sing_on_flip: return
	mirror_sing_on_flip = flip; Character.flip_sign_animations(self)
#endregion


#region Character Data
func loadCharacter(char_name: String = curCharacter) -> void: Character.load_character_json_from_name(self,char_name)

func _on_load_character() -> void: #Called in CharacterClass
	imageFile = json.get(&'assetPath',&"")
	healthBarColors = json.get(&'healthbar_colors',Color.WHITE)
	healthIcon = json.get(&"healthIcon",{}).get(&"id","icon-face")
	
	texture_filter = TEXTURE_FILTER_NEAREST if json.get(&'isPixel',false) else TEXTURE_FILTER_LINEAR
	positionArray = json.get(&'offsets',Vector2.ZERO)
	cameraPosition = json.get(&'camera_position',Vector2.ZERO)
	jsonScale = json.get(&'scale',1.0)
	offset_follow_flip = json.get(&'offset_follow_flip',false)
	offset_follow_scale = json.get(&'offset_follow_scale',false)
	mirror_sing_on_flip = json.get(&'mirror_sing_on_flip',false)
	
	danceAfterHold = json.get(&'danceAfterHold',true)
	danceOnAnimEnd = json.get(&'danceOnAnimEnd',false)
	
	
	_update_character_scale()
	_update_character_flip()
	notify_property_list_changed()

func _update_hold_limit() -> void: _real_hold_limit = holdLimit * singDuration
func _update_character_scale() -> void: scale = Vector2(jsonScale,jsonScale) * jsonScaleMult
func _update_character_flip() -> void: 
	var flip = json.get(&'flipX',false)
	image.flip_h = !flip if Character.isPlayer(self) else flip
#endregion

#region Dance Methods
func can_dance() -> bool: return !(specialAnim or holdTimer or heyTimer) ##Returns [code]true[/code] if the character is allowed to dance. Used in PlayState scripts.

func dance() -> void: ##Makes the character plays his dance animation.
	if hasDanceAnim: 
		animation.play(&'danceRight' if danced else &'danceLeft',forceDance); 
		danced = !danced
	else: animation.play('idle'+idleSuffix,forceDance)
	
	if holdKeys: holdKeys = PackedInt32Array()
	holdTimer = 0.0
	specialAnim = false

func _update_hold_time(delta: float) -> void:
	if holdTimer < _real_hold_limit: holdTimer += delta; return
	var hold_dance: bool = false
	if !autoDance: hold_dance = InputUtils.is_any_key_pressed(holdKeys)
	if danceAfterHold and !hold_dance: dance()

func _check_dance_anim(anim_name: String) -> void:
	if anim_name.begins_with('singLEFT'): danced = false
	elif anim_name.begins_with('singRIGHT'): danced = true
#endregion

#region Internal Methods
func _init(): super(); animation.auto_loop = true;

func _get_pivot() -> Vector2: return super._get_pivot() + positionArray

func _process(delta) -> void:
	super(delta); 
	if !specialAnim and _is_playing_sing_anim: _update_hold_time(delta)

func _enter_tree() -> void: 
	super(); if Engine.is_editor_hint(): return
	Conductor.on_bpm_changes.connect(_on_bpm_changes); _on_bpm_changes()

func _exit_tree() -> void: 
	super(); if Engine.is_editor_hint(): return
	Conductor.on_bpm_changes.disconnect(_on_bpm_changes)

func _on_bpm_changes() -> void:
	holdLimit = (Conductor.bpm_data.stepCrochetMs * (1.1 / Conductor.music_pitch)); 
	Character.update_dance_speed(self)

func _set_animation_resource() -> void:
	super(); if Engine.is_editor_hint(): return
	animation.animation_started.connect(_on_animation_started)
	animation.animation_finished.connect(_on_animation_finished)

func getMidpoint() -> Vector2: return super() + positionArray ##Returns the [u]Center[/u] of the sprite in the scene.

func getCameraPosition() -> Vector2: ##Returns the [u]Camera[/u] position of this character.
	match charType:
		Character.Type.OPPONENT: return getMidpoint()  + Vector2(150,-100) + cameraPosition
		Character.Type.BF: return getMidpoint()  + Vector2(-100 - cameraPosition.x,-100 + cameraPosition.y)
		_: return getMidpoint() + cameraPosition 

#Signals
func _on_animation_started(anim: StringName) -> void:
	if hasDanceAnim: _check_dance_anim(anim)
	_is_playing_sing_anim = anim.begins_with('sing');

func _on_animation_finished(_anim: StringName) -> void: 
	if specialAnim or danceOnAnimEnd and _is_playing_sing_anim: dance();

func _clear() -> void: animation.clearLibrary(); _pivot_set = false; json.assign({})
#endregion

#region Property Methods
func _validate_property(property: Dictionary) -> void: Character.validate_character_property(property); super(property)

func _property_get_revert(property: StringName) -> Variant: #Used in ModchartEditor
	match property:
		&'scale': return Vector2(jsonScale,jsonScale)
	return super(property)
#endregion
