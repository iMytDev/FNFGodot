@tool
class_name Character extends Node
const dance_anims: Array = [&'danceLeft',&'danceRight']

static var characters_loaded: Dictionary[StringName, Dictionary]

enum Type{BF, OPPONENT, GF}

#region Character Json
static func validate_character_property(property: Dictionary):
	match StringName(property.name):
		&"json",&"imageFile": property.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		&"scale": property.usage = PROPERTY_USAGE_STORAGE

static func isPlayer(char: Node) -> bool: return !char.get(&"charType")

static func create_from_json(json_name: String, type: Type = Type.OPPONENT) -> Character2D:
	var script = FunkinGD.addScript('characters/'+json_name+'.gd')
	if script and !script is Character:
		var char_type: String
		var base_script = script.get_script().get_base_script()
		if !base_script: char_type = script.get_class()
		else: char_type = base_script.resource_path.get_file().get_basename()
		
		FunkinGD.debug_message(
			'"'+json_name+'" character cannot be loaded: Script should be extended by Character, but it is by of '+char_type+'.'
		)
		return
	
	var char: Character2D = (script if script else Character2D).new()
	char.charType = type
	load_character_json_from_name(char, json_name)
	return char

static func fix_char_json(j: Dictionary):
	if j.has(&'camera_position'): j.camera_position = Vector2(j.camera_position[0],j.camera_position[1])
	if j.has(&'offsets'): j.offsets = Vector2(j.offsets[0],j.offsets[1])
	if j.has(&'healthbar_colors'): 
		j.healthbar_colors = Color(
			j.healthbar_colors[0]/255.0,
			j.healthbar_colors[1]/255.0,
			j.healthbar_colors[2]/255.0
		)

static func load_character_json_from_name(char: Node, char_name: String):
	var new_json: Dictionary = load_character_json(char_name); 
	if !new_json: char_name = &'bf'; new_json = load_character_json('bf')
	if !new_json: char._clear(); char.curCharacter = &''; return new_json
	char.curCharacter = char_name
	assign_character_json(char, new_json)
	char.dance()
	return new_json

static func load_character_json(json_name: StringName) -> Dictionary[StringName, Variant]:
	var data = characters_loaded.get(json_name)
	if data: return data
	
	data = Paths.character(json_name)
	var json: Dictionary[StringName, Variant]
	if !data: return json
	json.assign(data)
	load_character_json_animations(json)
	if !Engine.is_editor_hint(): characters_loaded[json_name] = json
	return json

static func load_character_json_animations(dict: Dictionary) -> Dictionary[StringName, AnimationData]:
	var anims = dict.get("animations",[]).duplicate()
	var animation_file: String = _get_character_anim_file(dict.assetPath)
	
	dict.animations = Dictionary(
		{},
		TYPE_STRING_NAME,&"",null, 
		TYPE_OBJECT, &"Resource", AnimationData
	)
	for i in anims:
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
		
		dict.animations[i.name] = resource
	return dict.animations

static func _get_character_anim_file(path: String) -> String:
	path = PathsStore.image(path); if !path: return ''
	path = AnimationService.findAnimFile(path.get_basename());
	return path

static func assign_character_json(char: Node, dict: Dictionary):
	fix_char_json(dict)
	char._clear(); 
	char.json.assign(dict)
	load_character_animations(char)
	char._on_load_character()
	return char.json
#endregion

static func get_type_from_name(char_type: StringName):
	match char_type:
		&"bf",&"boyfriend": return Type.BF
		&"dad": return Type.OPPONENT
		&"gf": return Type.GF

static func getCharactersList(return_jsons: bool = false) -> Variant:
	if !return_jsons: return PathsDir.get_files_at('characters',false,'.json')
	var directory: Dictionary
	for i in PathsDir.get_files_at('characters',true,'.json'): directory[i.get_file().left(-5)] = Paths.loadJson(i)
	return directory


#region Character Animations
static func update_dance_speed(char):
	if !char.hasDanceAnim: return
	for i in dance_anims:
		var animData = char.animation.animationsArray.get(i); if !animData: continue
		var anim_length = 1.0/animData.frameRate * animData.frames.size()
		var crochet_speed = (Conductor.bpm_data.crochet*0.007)
		animData.speed_scale = clampf(anim_length / crochet_speed,1.0,3.0)

static func load_character_animations(char: Node):
	var has_dance_anim: bool
	var has_miss_anims: bool
	
	char.animation.clearLibrary()
	char.animation.animations_use_textures = false
	char.animation.animationsArray = char.json.animations
	for i in char.json.animations:
		if !has_miss_anims and i.ends_with("-miss"): has_miss_anims = true
		if !has_dance_anim and (i.begins_with("danceLeft") or i.begins_with("danceRight")): has_dance_anim = true
	char.hasMissAnimations = has_miss_anims
	char.hasDanceAnim = has_dance_anim
	char.danceEveryNumBeats = 1 if has_dance_anim else 2

static func _add_character_animation(char, animName: StringName, data: Dictionary) -> AnimationData:
	var asset = char.image.texture
	var images = char.get_meta(&"images_find")
	var data_path = data.get(&"assetPath")
	if !data_path: return char.animation.add_animation_by_prefix(animName,data.prefix,data.fps,data.looped,data.indices)
	asset = images.get(data_path)
	if !asset: 
		asset = Paths.texture(data_path); if !asset: return
		images[data.assetPath] = asset
	
	char.animation.set_animation_file_from_texture(asset)
	var d = char.animation.add_animation_by_prefix(animName,data.prefix,data.fps,data.looped,data.indices)
	char.animation.set_animation_file_from_texture(char.image.texture)
	return d

static func _character_needs_flip_animations(char: Node) -> bool: return char.image.flip_h and char.mirror_sing_on_flip

static func flip_sign_animations(character: Node):
	var is_flipped = character.get_meta(&"flipped_anims",false)
	if is_flipped == character.image.flip_h or !character.animation.animationsArray: return
	character.set_meta(&"_flipped_sing_anims", character.image.flip_h)
	
	var left_anims_data: Dictionary
	var right_anims_data: Dictionary
	for i in character.animation.animationsArray.keys():
		i = str(i)
		if !i.begins_with('singLEFT'): 
			left_anims_data[i] = character.animation.animationsArray[i]; character.animation.animationsArray.erase(i)
		elif i.begins_with('singRIGHT'): 
			right_anims_data[i] = character.animation.animationsArray[i]; character.animation.animationsArray.erase(i)
	
	for i in left_anims_data: character.animation.animationsArray[i.replace('LEFT','RIGHT')] = left_anims_data[i]
	for i in right_anims_data: character.animation.animationsArray[i.replace('RIGHT','LEFT')] = left_anims_data[i]
	character.animation.update_anim()


static func export_character_json(char_json: Dictionary) -> Dictionary:
	var j = char_json.duplicate_deep()
	if j.has('camera_position'): j.camera_position = [j.camera_position[0],j.camera_position[1]]
	if j.has('offsets'): j.offsets = [j.offsets[0],j.offsets[1]]
	if j.has('healthbar_colors'): j.healthbar_colors = PackedInt32Array([
		j.healthbar_colors.r*255,
		j.healthbar_colors.g*255,
		j.healthbar_colors.b*255
	])
	var anims = j.get('animations')
	if anims: for i in anims: if i.has('offsets'): i.offsets = [i.offsets[0],i.offsets[1]]
	return j

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
		&'danceAfterHold': true,
	}

static func clear_characters() -> void: characters_loaded.clear()
#endregion
