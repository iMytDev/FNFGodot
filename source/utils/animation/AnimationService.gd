@tool 
extends Node
const formats: PackedStringArray = ['xml','json','txt']

##Will store the created animations, containing the name and an array with its frames
static var animations_loaded: Dictionary[StringName,Array]
static var _anims_created: Dictionary
static var _anims_file_founded: Dictionary[String,String]

const animation_formats: PackedStringArray = ['.xml','.txt','.json']

#region Add Animations Methods
static func add_frame_anim(animator: Anim, animName: StringName, indices: PackedInt32Array = [], fps: float = 24.0, loop: bool = false) -> AnimationData:
	if !indices or !animator.node_to_animate or !animator.node_to_animate.texture: return
	var animData = AnimationData.new()
	animData.frameRate = fps
	animData.looped = loop
	
	var node_to_animate = animator.node_to_animate
	var tex_size = node_to_animate.texture.get_size() if node_to_animate.texture else Vector2.ZERO
	var offset: Vector2 = node_to_animate.region_rect.size
	for i in indices:
		var frameX = offset.x*i
		var frameY = int(frameX/tex_size.x)
		if frameY: frameX -= (tex_size.x*frameY)
		animData.frames.append({&'region_rect': Rect2(Vector2(frameX,frameY*offset.y),offset)})
	animData.frames[0].size = offset
	animator.insert_animation(animName,animData)
	return animData

static func get_indices_by_str(indices: String) -> PackedInt32Array:
	if indices: return PackedInt32Array(Array(indices.split(',')))
	return PackedInt32Array()

##Insert [Animation] to [member animationsArray] of the [Anim]. 
##If was no animation playing, the animation inserted will be played automatically.[br][br]
##See also [method addAnimation] and [method addFrameAnim].
#endregion

#region Getters
static func getPrefixList(file: String) -> Dictionary[StringName,Array]:
	match file.get_extension():
		'xml': return Sparrow.loadSparrow(file)
		'txt': return Atlas.loadAtlasTxt(file)
		'json': return Atlas.loadMap(file)
		_: return {}

##Get the Animation data using the prefix. [br][br]
##It will return the data and the [Animation] in [[Array][[Rect2]],[Animation]]
static func get_anim_frames(prefix: StringName, file: StringName = &'', indices: PackedInt32Array = []) -> Array[Dictionary]:
	if !file or !prefix: return []
	var frames = _anims_created.get_or_add(file,{}).get(prefix)
	if frames:
		if indices: return _get_anim_frames_indices(frames,indices)
		return frames
	
	var fileFounded: Dictionary[StringName,Array] = getPrefixList(file)
	if !fileFounded: return []
	
	frames = fileFounded.get(prefix,Array([],TYPE_DICTIONARY,&"",null))
	if !frames:
		var prefix_str = String(prefix)
		for anims in fileFounded: if (anims+'0000').begins_with(prefix_str): frames.append_array(fileFounded[anims])
	_anims_created[file][prefix] = frames
	
	if indices: return _get_anim_frames_indices(frames,indices)
	return frames

static func _get_anim_frames_indices(frames: Array, indices: PackedInt32Array) -> Array:
	var indice_frames: Array[Dictionary]
	var anim_length = frames.size()
	var indice_length: int = indices.size()
	var i = 0
	while i < indice_length:
		var indice = indices[i]
		if indice < anim_length: indice_frames.append(frames[indice])
		i += 1
	return indice_frames

static func findAnimFile(tex: String):
	if _anims_file_founded.has(tex): return _anims_file_founded[tex]
	for formats in animation_formats:
		if tex.ends_with(formats): return tex
		var file = tex+formats
		if FileAccess.file_exists(file): _anims_file_founded[tex] = file; return file
	return ''
#endregion

static func clear_anims() -> void:
	Sparrow.sparrows_loaded.clear()
	Atlas.atlas_loaded.clear()
	Atlas.maps_loaded.clear()
	_anims_file_founded.clear()
	_anims_created.clear()
