@tool
@abstract
@icon("res://icons/FunkinMicrophone3D.svg")
class_name CharacterBase3D extends Node3D

@export_group("Dance")
@export var danceEveryNumBeats: int = 2
@export var danceAfterHold: bool = true ##If [code]false[/code], the character will not return to the idle anim.
@export var danceOnAnimEnd: bool = false ##If [code]true[/code],the character will dance when a "sing" animation ends.
@export var autoDance: bool = false
@export_storage var hasMissAnimations: bool = false
@export_storage var hasDanceAnim: bool = false


@export_group("Health Bar")
@export var healthIcon: String = 'icon-face'
@export var healthBarColors: Color = Color.WHITE

var danced: bool
var forceDance: bool #Used in Subclasses
@export var singDuration: float = 4.1:
	set(val): singDuration = val; _update_hold_limit()

@export_storage var holdLimit: float = 1.0: set = set_hold_limit
@export_storage var holdTimer: float = 0.0
@export_storage var heyTimer: float = 0.0
var _real_hold_limit: float = 4.1


var _is_playing_sing_anim: bool


var idleSuffix: String: set = set_idle_suffix
var specialAnim: bool = false
var _idle_anim: StringName = &"idle"
var holdKeys: PackedInt32Array


@abstract func getCameraPosition() -> Vector3
@abstract func getCameraRotation() -> Vector3

func _enter_tree() -> void: 
	if Engine.is_editor_hint(): return;
	Conductor.on_bpm_changes.connect(_on_bpm_changes); 
	_on_bpm_changes()

func _exit_tree() -> void: 
	if Engine.is_editor_hint(): return;
	Conductor.on_bpm_changes.disconnect(_on_bpm_changes)

func _on_bpm_changes() -> void: holdLimit = Conductor.bpm_data.stepCrochetMs * (1.1 / Conductor.music_pitch);

func set_idle_suffix(suffix: String) -> void: idleSuffix = suffix; _idle_anim = StringName("idle"+suffix)

func _process(delta: float) -> void: if _is_playing_sing_anim: _update_hold_time(delta)
#region Hold Methods
func _update_hold_time(delta: float) -> void:
	if holdTimer < _real_hold_limit: holdTimer += delta; return
	var hold_dance: bool = false
	if !autoDance: hold_dance = InputUtils.is_any_key_pressed(holdKeys)
	if danceAfterHold and !hold_dance: dance()

func set_hold_limit(limit: float) -> void: holdLimit = limit; _update_hold_limit()
func _update_hold_limit() -> void: _real_hold_limit = holdLimit * singDuration
#endregion



#region Dance Methods
func dance() -> void:
	holdTimer = 0.0
	specialAnim = false
	if holdKeys: holdKeys = PackedInt32Array()

func can_dance() -> bool: return !(specialAnim or holdTimer or heyTimer)
#endregion

func _on_animation_started(animName: StringName):
	if Engine.is_editor_hint(): return
	_is_playing_sing_anim = animName.begins_with('sing')
	if hasDanceAnim: _check_dance_anim(animName)

func _check_dance_anim(anim_name: String) -> void:
	if anim_name.begins_with('singLEFT'): danced = false
	elif anim_name.begins_with('singRIGHT'): danced = true
