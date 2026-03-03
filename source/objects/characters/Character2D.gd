@tool
@icon("res://icons/FunkinMicrophone.svg")
##A Character 2D Class
class_name Character2D extends FunkinAnimatedSprite2D

#region Dance Variables
@export_storage var data: CharacterData = CharacterData.new(): set = _on_data_set
@export_category("Dance Properties")
var _danced: bool #Used to make the "danceLeft/danceRight" animation.

##how many beats should pass before the character dances again. For example:[br]
##If it's [code]2[/code], the character will dance every second beat.[br]
##If it's [code]1[/code], will dance on every beat.
@export var singDuration: float = 4.1: set = set_sing_duration ##The duration of the sing animations.

##If [code]false[/code], the character will not return to dance while pressing the sing keys.[br]
##OBS: This property is set automatically in PlayState scripts.
@export_storage var autoDance: bool = true

@export_category("Character Properties")
@export_placeholder("bf") var curCharacter: String ##The name of the character json.
@export_tool_button("Load Character") var char_method = loadCharacter

@export var charType: Character.Type = Character.Type.BF: set = set_character_type
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
var specialAnim: bool ##If [code]true[/code], the character will not return to dance while the current animation ends.

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
func set_character_type(type: Character.Type) -> void: charType = type; _update_character_flip()
func set_mirror_sing_on_flip(flip: bool) -> void:
	if flip == mirror_sing_on_flip: return
	mirror_sing_on_flip = flip; Character.flip_sing_animations(self)
#endregion

#region Getters
func getMidpoint() -> Vector2: return super() + data.positionArray ##Returns the [u]Center[/u] of the sprite in the scene.

func getCameraPosition() -> Vector2: ##Returns the [u]Camera[/u] position of this character.
	match charType:
		Character.Type.OPPONENT: 
			return getMidpoint() + Vector2(150,-100) + data.cameraPosition
		Character.Type.BF: 
			return getMidpoint() + Vector2(-100 - data.cameraPosition.x,-100 + data.cameraPosition.y)
		_: 
			return getMidpoint() + data.cameraPosition 

func get_canvas_offset() -> Vector2: return super() + data.positionArray
#endregion

#region Character Data
func loadCharacter(char_name: String = curCharacter) -> void: Character.load_character_json_from_name(self,char_name)

func _on_data_set(d: CharacterData) -> void: #Called in CharacterClass
	data = d
	texture_filter = TEXTURE_FILTER_NEAREST if data.json.get(&'isPixel',false) else TEXTURE_FILTER_LINEAR
	image.texture = Paths.texture(data.imageFile)
	
	animation.animationsArray = data.animationsArray
	offset_follow_flip = data.offset_follow_flip
	offset_follow_scale = data.offset_follow_scale
	offset_follow_rotation = true
	_update_character_scale()
	_update_character_flip()
	notify_property_list_changed()

func _update_hold_limit() -> void: _real_hold_limit = holdLimit * singDuration
func _update_character_scale() -> void: scale = Vector2(data.jsonScale,data.jsonScale) * jsonScaleMult
func _update_character_flip() -> void: 
	image.flip_h = !data.flipX if Character.isPlayer(self) else data.flipX
#endregion

#region Dance Methods
func can_dance() -> bool: return !(specialAnim or holdTimer or heyTimer) ##Returns [code]true[/code] if the character is allowed to dance. Used in PlayState scripts.

func dance() -> void: ##Makes the character plays his dance animation.
	if data.hasDanceAnim: 
		animation.play(&'danceRight' if _danced else &'danceLeft'); 
		_danced = !_danced
	else: 
		animation.play('idle'+idleSuffix, data.forceDance)
	
	if holdKeys: holdKeys = PackedInt32Array()
	holdTimer = 0.0
	specialAnim = false

func _update_hold_time(delta: float) -> void:
	if holdTimer < _real_hold_limit: holdTimer += delta; return
	var hold_dance: bool = false
	if !autoDance: hold_dance = InputUtils.is_any_key_pressed(holdKeys)
	if data.danceAfterHold and !hold_dance: dance()

func _check_dance_anim(anim_name: String) -> void:
	if anim_name.begins_with('singLEFT'): _danced = false
	elif anim_name.begins_with('singRIGHT'): _danced = true
#endregion

#region Internal Methods
func _init(): super(); animation.auto_loop = true;

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
#endregion



#region Signals
func _on_animation_started(anim: StringName) -> void:
	if data.hasDanceAnim: _check_dance_anim(anim)
	_is_playing_sing_anim = anim.begins_with('sing');

func _on_animation_finished(_anim: StringName) -> void: 
	if specialAnim or data.danceOnAnimEnd and _is_playing_sing_anim: dance();
#endregion


#region Property Methods
func _validate_property(property: Dictionary) -> void: Character.validate_character_property(property); super(property)

func _property_get_revert(property: StringName) -> Variant: #Used in ModchartEditor
	match property:
		&'scale': return Vector2(data.jsonScale,data.jsonScale)
	return super(property)
#endregion
