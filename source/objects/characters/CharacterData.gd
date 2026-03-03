class_name CharacterData extends Resource

var hasMissAnim: bool ##If the character have any miss animation.
var hasDanceAnim: bool ##If character have "danceLeft" or "danceRight" animation.
var hasDifferentAnimationTextures: bool

@export_category("Animations")
var animationsArray: Dictionary[StringName, AnimationData]
@export var mirror_sing_on_flip: bool

@export_category("Dance Properties")
##how many beats should pass before the character dances again. For example:[br]
##If it's [code]2[/code], the character will dance every second beat.[br]
##If it's [code]1[/code], will dance on every beat.
@export var danceEveryNumBeats: int = 2
@export var danceAfterHold: bool = true ##If [code]false[/code], the character will not dance after the hold time.[br]See also [param holdLimit].
@export var danceOnAnimEnd: bool ##If [code]true[/code], the character will dance when a "sing" animation ends.
@export var forceDance: bool ##If [code]true[/code], the dance animation will be reset every beat hit, making character dance even though the animation hasn't finished.
var singDuration: float = 4.1
@export_storage var jsonScale: float = 1.0 ##The Character Scale from his json.

@export_category("Data")
@export var imageFile: String
@export var isPixel: bool
@export var flipX: bool
var json: Dictionary

@export_category("Position")
@export var positionArray: Vector2 = Vector2.ZERO
@export var cameraPosition: Vector2 = Vector2.ZERO ##The camera position offset.

@export var offset_follow_flip: bool
@export var offset_follow_scale: bool


@export_category("Health Bar")
@export_placeholder("icon-face") var healthIcon: String ##The [u]name[/u] of icon that will be showed in health bar.
@export_color_no_alpha var healthBarColors: Color = Color.WHITE ##The color of the character bar.
var iconData: Dictionary = {
	&"id": "icon-face",
	&"isPixel": false
}

static func create_from_json(json: Dictionary) -> CharacterData:
	var data = CharacterData.new()
	fix_char_json(json)
	
	data.json = json
	data.danceAfterHold = json.get(&'danceAfterHold',true)
	data.danceOnAnimEnd = json.get(&'danceOnAnimEnd',false)
	data.imageFile = json.get(&'assetPath',&"")
	
	data.singDuration = json.get(&"singTime",4.1)
	
	data.healthBarColors = json.get(&'healthbar_colors',Color.WHITE)
	
	data.iconData = json.get(&"healthIcon",{})
	data.isPixel = json.get(&"isPixel",false)
	
	data.flipX = json.get(&"flipX",false)
	
	var offsets = json.get(&'offsets')
	data.positionArray = Vector2(offsets[0],offsets[1]) if offsets else Vector2.ZERO
	
	var camera_pos = json.get(&"camera_position")
	data.cameraPosition = Vector2(camera_pos[0],camera_pos[1]) if camera_pos else Vector2.ZERO
	
	data.offset_follow_flip = json.get(&'offset_follow_flip',false)
	data.offset_follow_scale = json.get(&'offset_follow_scale',false)
	data.mirror_sing_on_flip = json.get(&'mirror_sing_on_flip',false)
	
	#Load Animations
	data.animationsArray = _load_animations(json)
	
	for i in data.animationsArray:
		if !data.hasMissAnim: data.hasMissAnim = i.ends_with("-miss")
		if !data.hasDanceAnim: data.hasDanceAnim = i.begins_with("dance")
		if data.hasMissAnim and data.hasDanceAnim: break
	return data

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"positionArray",&"cameraPosition": property.usage = PROPERTY_USAGE_DEFAULT
func get_as_json():
	var icon_data: Dictionary[StringName, Variant] = {
		&"id": iconData.get(&"id","icon-face")
	}
	
	if iconData.get("canScale"): icon_data.canScale = true
	if iconData.get("isPixel"): icon_data.canScale = true
	
	var data: Dictionary[StringName, Variant] = {
		&"animations": [],
		&"assetPath": imageFile,
		&"healthbar_colors": healthBarColors,
		&"healthIcon": iconData,
		&"singTime": singDuration,
	}
	
	if cameraPosition: data.camera_position = [cameraPosition.x,cameraPosition.y]
	if positionArray: data.offsets = [positionArray.x,positionArray.y]
	
	if danceOnAnimEnd: data.danceOnAnimEnd = true
	if !danceAfterHold: data.danceAfterHold = false
	
	if jsonScale != 1.0: data.scale = jsonScale
	if singDuration != 4.1: data.singTime = singDuration
	return data

static func getCharacterBaseData() -> Dictionary[StringName,Variant]: ##Returns a base to character data.
	return {
		&"animations": [],
		&"offsets": [],
		&"camera_position": Vector2.ZERO,
		&"assetPath": "",
		&"healthbar_colors": Color.WHITE,
		&"healthIcon": {
			&"id": "icon-face",
			&"isPixel": false,
			&'canScale': false
		},
		&"singTime": 4.1,
		&"scale": 1.0,
		&'danceAfterHold': true,
		&'danceOnAnimEnd': false,
	}

static func fix_char_json(j: Dictionary):
	if j.has(&'camera_position'): j.camera_position = Vector2(j.camera_position[0],j.camera_position[1])
	if j.has(&'offsets'): j.offsets = Vector2(j.offsets[0],j.offsets[1])
	if j.has(&'healthbar_colors'): 
		j.healthbar_colors = Color(
			j.healthbar_colors[0]/255.0,
			j.healthbar_colors[1]/255.0,
			j.healthbar_colors[2]/255.0
		)

static func _get_character_anim_file(path: String) -> String:
	path = PathsStore.image(path); if !path: return ''
	path = AnimationService.findAnimFile(path.get_basename());
	return path

static func _load_animations(dict: Dictionary) -> Dictionary[StringName,AnimationData]:
	var animation_file: String = _get_character_anim_file(dict.assetPath)
	var animations: Dictionary[StringName,AnimationData]
	for i in dict.get("animations",[]):
		var asset = i.get("asset","")
		var anim_file = animation_file
		var resource = AnimationData.new()
		resource.asset = asset
		
		resource.frameRate = i.get("fps",24.0)
		resource.prefix = i.get("prefix","")
		resource.looped = i.get("looped",false)
		resource.loop_frame = i.get("loop_frame",0)
		resource.frames = AnimationService.get_anim_frames(resource.prefix,anim_file, i.get("frameIndices",[]))
		
		var offset = i.get("offsets")
		resource.set_meta(&"offset", Vector2(offset[0],offset[1]) if offset else Vector2.ZERO)
		
		animations[i.name] = resource
	return animations
