@icon("res://icons/icon.png")
##A Character 2D Class
class_name Character extends FunkinSprite

const NoteHit = preload("uid://dx85xmyb5icvh")
const Song = preload("uid://cerxbopol4l1g")
enum Type{
	BF = 0,
	OPPONENT = 1,
	GF = 2
}
@export var curCharacter: StringName: set = loadCharacter ##The name of the character json.

##how many beats should pass before the character dances again.[br][br]For example: 
##If it's [code]2[/code], 
##the character will dance every second beat. If it's [code]1[/code], they dance on every beat.

#region Dance Variables

var danced: bool ##Used to make the "danceLeft/danceRight" animation.
var danceAfterHold: bool = true ##If [code]false[/code], the character will not return to the idle anim.
var danceOnAnimEnd: bool ##If [code]true[/code],the character will dance when a "sing" animation ends.
var danceEveryNumBeats: int = 2
var autoDance: bool = true ##If [code]false[/code], the character will not return to dance while pressing the sing keys.
var forceDance: bool ##If [code]true[/code], the dance animation will be reset every beat hit, making character dance even though the animation hasn't finished.
var hasDanceAnim: bool: set = set_has_dance_anim ##If character have "danceLeft" or "danceRight" animation.
var _is_playing_sing_anim: bool = false

var charType: Character.Type = Character.Type.BF:
	set(val):
		charType = val
		_update_character_flip()

var holdTimer: float ##The time the character is in singing animation.
var heyTimer: float ##The time the character is in the "Hey" animation.
var singDuration: float = 4.1: set = set_sing_duration ##The duration of the sing animations.
var holdLimit: float = 1.0: set = set_hold_limit ##The time limit to return to idle animation.
var _real_hold_limit: float = singDuration
#endregion

var _images: Dictionary[StringName,Texture2D]


var stunned: bool = false

#region Animation Variables
var animationsArray

var specialAnim: bool ##If [code]true[/code], the character will not return to dance while the current animation ends.
var hasMissAnimations: bool ##If the character have any miss animation, used to play a miss animation when miss a note.

##If is not blank, it will be added to the "idle" animation name, for example:[codeblock]
##var character = Character.new()
##character.dance() #Will play "idle" animation(if not has "danceLeft" or "danceRight" anim).
##
##character.idleSuffix = '-alt'
##character.dance() #Will play "idle-alt" animation
##
##character.idleSuffix = '-alt2'
##character.dance() #Will play "idle-alt2"
##[/codeblock]
var idleSuffix: String


var mirror_sing_on_flip: bool = true:
	set(val):
		if val == mirror_sing_on_flip: return
		mirror_sing_on_flip = val
		flip_sing_animations()

var _flipped_sing_anims: bool
#endregion

#region Data Variables
var healthIcon: String ##The Character Icon
var healthBarColors: Color = Color.WHITE ##The color of the character bar.

var positionArray: Vector2 ##The character position offset.
var cameraPosition: Vector2 ##The camera position offset.

var json: Dictionary[StringName, Variant] ##The character json. See also [method loadCharacter]
var jsonScale: float = 1.0 ##The Character Scale from his json.
var origin_offset: Vector2
#endregion


#region Updaters
func updateBPM(): ##Update the character frequency.
	holdLimit = (Conductor.stepCrochet * (0.0011 / Conductor.music_pitch))
	_update_dance_animation_speed()

func _update_character_flip(): 
	image.flip_h = !json.get(&'flipX',false) if isPlayer() else json.get(&'flipX',false)

#endregion

#region Character Data
func loadCharacter(char_name: StringName) -> Dictionary: ##Load Character. Returns a [Dictionary] with the json found data.
	var new_json: Dictionary = Paths.character(char_name); 
	if !new_json: char_name = &'bf'; new_json = Paths.character('bf')
	if !new_json: _clear(); curCharacter = &''; return new_json
	curCharacter = char_name
	loadCharacterFromJson(new_json)
	return json

func loadCharacterFromJson(new_json: Dictionary[StringName,Variant]):
	_clear()
	json.assign(new_json)
	
	var tex = json.get('assetPath')
	if tex:
		image.texture = Paths.texture(tex)
		if image.texture: _images[tex] = image.texture
	
	_on_load_character()
	reloadAnims()
	
	return json

func _on_load_character():
	healthBarColors = json.get(&'healthbar_colors',Color.WHITE)
	healthIcon = json.healthIcon.id
	imageFile = json.get(&'assetPath','')
	antialiasing = !json.get(&'isPixel',false)
	positionArray = json.get(&'offsets',Vector2.ZERO)
	cameraPosition = json.get(&'camera_position',Vector2.ZERO)
	jsonScale = json.get(&'scale',1.0)
	offset_follow_flip = json.get(&'offset_follow_flip',false)
	offset_follow_scale = json.get(&'offset_follow_scale',false)
	origin_offset = json.get(&'origin_offset',Vector2.ZERO)
	mirror_sing_on_flip = json.get(&'mirror_sing_on_flip',false)
	scale = Vector2(jsonScale,jsonScale)
	danceAfterHold = json.get(&'danceAfterHold',true)
	danceOnAnimEnd = json.get(&'danceOnAnimEnd',false)
	_update_character_flip()

func getCameraPosition() -> Vector2: 
	match charType:
		Type.OPPONENT: return getMidpoint() + Vector2(150,-100) + cameraPosition
		Type.BF: return getMidpoint() + Vector2(-100 - cameraPosition.x,-100 + cameraPosition.y)
		_: return getMidpoint() + cameraPosition 
#endregion

#region Checkers
func isPlayer() -> bool: return charType == Type.BF
#endregion

#region Character Animation
func reloadAnims(): ##Reload the character animations.
	var has_dance_anim: bool = false
	animation.clearLibrary()
	
	danceEveryNumBeats = 2
	hasMissAnimations = false
	animation.animations_use_textures = false
	
	for anims in json.animations:
		var animName = anims.name
		if _flipped_sing_anims:
			if animName.begins_with('singLEFT'): animName = 'singRIGHT'+animName.right(-8)
			elif animName.begins_with('singRIGHT'): animName = 'singLEFT'+animName.right(-9)
		
		if !hasMissAnimations: hasMissAnimations = animName.ends_with('miss')
		animName = StringName(animName)
		if !has_dance_anim: has_dance_anim = (animName == &'danceLeft' or animName == &'danceRight')
		
		add_animation(
			animName,
			{
				&'prefix': anims.prefix,
				&'fps': anims.get('fps',24.0),
				&'looped': anims.get('looped',false),
				&'indices': anims.get('frameIndices',[]),
				&'asset': anims.get('assetPath',json.assetPath),
			}
		)
		animation.set_anim_offset(animName,anims.get(&'offsets',Vector2.ZERO))
		animation.setLoopFrame(animName,anims.get(&'loop_frame',0))
	hasDanceAnim = has_dance_anim

func add_animation(animName: StringName, anim_data: Dictionary[StringName,Variant]) -> Dictionary:
	var tex = _load_animation_image(anim_data.get(&'asset',&''))
	if tex: anim_data.asset = tex; return _add_animation_from_data(animName,anim_data,tex)
	for i in _images.values():
		var data = _add_animation_from_data(animName,anim_data,i); if data: return data
	return {}

func _add_animation_from_data(animName: String,animData: Dictionary[StringName,Variant], asset: Texture) -> Dictionary:
	var prefix = animData.get(&'prefix')
	if !prefix: return {}
	
	var indices = animData.get(&'indices')
	var asset_file = AnimationService.findAnimFile(asset.resource_name)
	var anim_frames: Array = animation.get_frames_from_prefix(animData.prefix,indices,asset_file)
	
	if !anim_frames: return {}
	animData.frames = anim_frames
	return animation.insertAnim(animName,animData)

func _load_animation_image(path) -> Texture2D:
	if !path: return
	if !path: path = json.assetPath
	var asset = _images.get(path)
	if asset: return asset
	
	asset = Paths.texture(path)
	if !asset: return null
	_images[path] = asset
	animation.setup_animation_textures()
	return asset

func flip_sing_animations() -> void:
	if _flipped_sing_anims == image.flip_h or !animationsArray: return
	_flipped_sing_anims = image.flip_h
	
	var left_anims_data: Dictionary
	var right_anims_data: Dictionary
	for i in animationsArray.keys():
		i = str(i)
		if !i.begins_with('singLEFT'): left_anims_data[i] = animationsArray[i]; animationsArray.erase(i)
		elif i.begins_with('singRIGHT'): right_anims_data[i] = animationsArray[i]; animationsArray.erase(i)
	
	for i in left_anims_data: animationsArray[i.replace('LEFT','RIGHT')] = left_anims_data[i]
	for i in right_anims_data: animationsArray[i.replace('RIGHT','LEFT')] = left_anims_data[i]
	animation.update_anim()
#endregion

#region Animation Methods
func _on_animation_started(anim: StringName) -> void: _is_playing_sing_anim = anim.begins_with('sing')
func _on_animation_finished(_anim: StringName): if specialAnim or danceOnAnimEnd and _anim.begins_with('sing'): dance();

func dance() -> void: ##Make character returns to his dance animation.
	if not hasDanceAnim: animation.play('idle'+idleSuffix,forceDance)
	else: animation.play(&'danceRight' if danced else &'danceLeft',forceDance); danced = !danced
	holdTimer = 0.0
	specialAnim = false

const dance_anim: Array = [&'danceLeft',&'danceRight']
func _update_dance_animation_speed():
	if !hasDanceAnim: return
	for i in dance_anim:
		var animData = animation.animationsArray.get(i)
		if !animData: continue
		var anim_length = 1.0/animData.fps * animData.frames.size()
		animData.speed_scale = clamp(anim_length/(Conductor.crochet*0.007),1.0,3.0)

func _update_hold_time(delta: float) -> void:
	if holdTimer < _real_hold_limit: holdTimer += delta; return
	if danceAfterHold and (autoDance or !InputUtils.is_any_actions_pressed(NoteHit.getInputActions())): dance()

func _check_dance_anim(anim_name: StringName) -> void:
	if anim_name.begins_with('singLEFT'): danced = false
	elif anim_name.begins_with('singRIGHT'): danced = true

func _update_hold_limit() -> void: _real_hold_limit = holdLimit*singDuration
#endregion

func _clear() -> void:
	pivot_offset = Vector2.ZERO
	animation.clearLibrary()
	_images.clear()
	json.clear()

#region Setters
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"position": _position = value; return true
	return false
func set_hold_limit(limit: float) -> void: holdLimit = limit; _update_hold_limit()
func set_sing_duration(duration: float) -> void: singDuration = duration; _update_hold_limit()
func set_pivot_offset(pivot: Vector2): pivot += origin_offset; super.set_pivot_offset(pivot)

func set_has_dance_anim(has: bool):
	if hasDanceAnim == has: return
	hasDanceAnim = has
	
	var anim_signal = animation.animation_started
	if has: 
		danceEveryNumBeats = 1
		if !anim_signal.is_connected(_check_dance_anim): anim_signal.connect(_check_dance_anim)
	else:
		danceEveryNumBeats = 2
		if anim_signal.is_connected(_check_dance_anim): anim_signal.disconnect(_check_dance_anim)

#endregion


#region Static Methods
static func create_from_json(json_name: String, type: Type = Type.OPPONENT) -> Character:
	var script = FunkinGD.loadScript('characters/'+json_name+'.gd')
	var char: Character = script.new() if script else Character.new()
	char.loadCharacter(json_name)
	char.charType = type
	return char

static func export_character_json(char_json: Dictionary) -> Dictionary:
	var j = char_json.duplicate_deep()
	
	
	if j.has('camera_position'): j.camera_position = [j.camera_position[0],j.camera_position[1]]
	if j.has('origin_offset'): j.origin_offset = [j.origin_offset[0],j.origin_offset[1]]
	if j.has('offsets'): j.offsets = [j.offsets[0],j.offsets[1]]
	if j.has('healthbar_colors'): j.healthbar_colors = PackedInt32Array([
		j.healthbar_colors.r*255,
		j.healthbar_colors.g*255,
		j.healthbar_colors.b*255
	])
	
	var anims = j.get('animations')
	if anims: for i in anims: if i.has('offsets'): i.offsets = [i.offsets[0],i.offsets[1]]
	return j
	
static func _convert_psych_to_original(json: Dictionary) -> Dictionary[StringName,Variant]:
	var new_json: Dictionary[StringName,Variant] = getCharacterBaseData()
	
	var anims: Array = json.get(&'animations')
	json.erase(&'animations')
	for i in anims:
		var anim = getAnimBaseData()
		
		DictUtils.convertKeysToStringNames(i)
		DictUtils.merge_existing(anim,i)
		if i.has(&'indices'): anim.frameIndices = i.indices
		if i.has(&'loop'): anim.looped = i.loop
		if i.has(&'anim'):  anim.name = i.anim; if i.has(&'name'): anim.prefix = i.name
		
		anim.offsets = PackedFloat32Array(i.get(&'offsets',[0,0]))
		anim.fps = i.get(&'fps',24.0)
		new_json.animations.append(anim)
	
	new_json.offsets = json.get(&'position',[0,0])
	new_json.flipX = json.get(&'flip_x',false)
	new_json.healthbar_colors = json.get(&"healthbar_colors",PackedByteArray([255,255,255]))
	new_json.assetPath = json.get(&'image','')
	new_json.singTime = json.get(&'sing_duration',4.0)*2.0
	new_json.isPixel = json.get(&'no_antialiasing',false)
	
	var icon = json.get(&'healthicon',&'icon-face')
	new_json.healthIcon.id = StringName(icon)
	new_json.healthIcon.isPixel = icon.ends_with('-pixel')
	new_json.camera_position = json.get(&'camera_position',[0,0])
	new_json.scale = json.get(&'scale',1.0)
	
	DictUtils.merge_existing(new_json,json)
	return new_json


func _property_get_revert(property: StringName) -> Variant: #Used in ModchartEditor
	match property:
		&'scale': return Vector2(jsonScale,jsonScale)
	return super._property_get_revert(property)

static func getCharacterBaseData() -> Dictionary[StringName,Variant]: ##Returns a base to character data.
	return {
		&"animations": [],
		&"offsets": Vector2.ZERO,
		&"camera_position": Vector2.ZERO,
		&"assetPath": "",
		&"healthbar_colors": Color.WHITE,
		&"healthIcon": {
			&"id": "icon-face",
			&"isPixel": false,
			&'canScale': false
		},
		&"singTime": 4.0,
		&"scale": 1,
		&"origin_offset": Vector2.ZERO,
		&'danceAfterHold': true,
	}

static func getCharactersList(return_jsons: bool = false) -> Variant:
	if !return_jsons: return Paths.getFilesAt('characters',false,'.json')
	var directory = {}
	for i in Paths.getFilesAt('characters',true,'.json'): directory[i.get_file().left(-5)] = Paths.loadJson(i)
	return directory

static func fixCharJson(j: Dictionary):
	if j.has(&'camera_position'): j.camera_position = Vector2(j.camera_position[0],j.camera_position[1])
	if j.has(&'offsets'): j.offsets = Vector2(j.offsets[0],j.offsets[1])
	if j.has(&'origin_offset'): j.origin_offset = Vector2(j.origin_offset[0],j.origin_offset[1])
	if j.has(&'healthbar_colors'): 
		j.healthbar_colors = Color(
			j.healthbar_colors[0]/255.0,
			j.healthbar_colors[1]/255.0,
			j.healthbar_colors[2]/255.0
		)
	if j.has(&'animations'): 
		for i in j.animations: if i.has(&'offsets'): i.offsets = Vector2(i.offsets[0],i.offsets[1])

static func getAnimBaseData() -> Dictionary[StringName,Variant]: ##Returns a base for the character animation data.
	return {
		&'name': &'',
		&'prefix': &'',
		&'fps': 24,
		&'loop_frame': 0,
		&'looped': false,
		&'frameIndices': PackedFloat32Array(),
		&'offsets': Vector2.ZERO,
		&'assetPath': ''
	}
#endregion

#region Native Methods
func _init():
	super._init(true)
	animationsArray = animation.animationsArray
	animation.auto_loop = true; 
	animation.animation_finished.connect(_on_animation_finished)
	animation.animation_started.connect(_on_animation_started); 
	image.on_flip_x.connect(flip_sing_animations)

func _enter_tree() -> void: updateBPM()

func _process(delta) -> void:
	super._process(delta)
	if !specialAnim and _is_playing_sing_anim: _update_hold_time(delta)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY: Conductor.bpm_changes.connect(updateBPM)
	super._notification(what)
#endregion
