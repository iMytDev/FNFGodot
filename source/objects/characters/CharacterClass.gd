@tool
class_name Character extends Node
const dance_anims: Array = [&'danceLeft',&'danceRight']

static var characters_loaded: Dictionary[StringName, CharacterData]

enum Type{BF, OPPONENT, GF}

#region Character Json
static func validate_character_property(property: Dictionary):
	match StringName(property.name):
		&"json",&"imageFile": property.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		&"scale": property.usage = PROPERTY_USAGE_STORAGE

static func isPlayer(char: Node) -> bool: return !char.get(&"charType")

static func create_from_json(json_name: String, type: Type = Type.OPPONENT) -> Character2D:
	var char: Character2D = Character2D.new()
	char.charType = type
	load_character_json_from_name(char, json_name)
	return char

static func load_character_json_from_name(char: Node, char_name: String):
	var data: CharacterData = load_character_data(char_name); 
	if !data: 
		char_name = &'bf'; 
		data = load_character_data('bf')
		if !data: return data
	
	char.curCharacter = char_name
	char.data = data
	char.dance()
	return data

static func load_character_data(json_name: StringName) -> CharacterData:
	var data = characters_loaded.get(json_name)
	if data: return data
	
	var json = Paths.character(json_name)
	if !json: return null
	data = CharacterData.create_from_json(json)
	
	if !Engine.is_editor_hint(): characters_loaded[json_name] = data
	return data

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

static func flip_sing_animations(character: Node):
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

static func clear_characters() -> void: characters_loaded.clear()
#endregion
