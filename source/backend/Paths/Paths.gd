@tool
class_name Paths extends Object
const game_name: String = "Friday Night Funkin'" ## The game name.[br][b]OBS: this constant cannot be a empty string!!![/b]
static var is_on_mobile: bool = OS.get_name() == &'Android' or OS.get_name() == &'iOs'

#region Caches
static var textFiles: Dictionary[StringName, String]
static var fontFiles: Dictionary[StringName, FontFile]

static var imagesCreated: Dictionary[String,Image]
static var imagesTextures: Dictionary[String,Texture2D]

static var songsCreated: Dictionary[String,AudioStream]
static var soundsCreated: Dictionary[String,AudioStream]

static var musicCreated: Dictionary[String,AudioStream]
static var fontsCreated: Dictionary[String,FontFile] 
static var shadersCreated: Dictionary[String,Material]
static var shadersCodes: Dictionary[String,Shader]

static var jsonsLoaded: Dictionary[String,Dictionary]
static var modelsCreated: Dictionary[String,Object]
static var videosCreated: Dictionary[String,VideoStream]
#endregion

static func _static_init() -> void: if is_on_mobile: OS.request_permissions()

static func font(path: StringName) -> Font:
	var font_file = fontFiles.get(path)
	if font_file: return font_file
	var fontPath = PathsStore.font(path)
	if !fontPath: return ThemeDB.fallback_font
	font_file = FontFile.new()
	font_file.load_dynamic_font(fontPath)
	return font_file

static func image(path: StringName,imagesDirectory: bool = true, format: String = '.png') -> Image:
	return _image_no_path_check(PathsStore.image(path,imagesDirectory,format))

static func _image_no_path_check(path_absolute: StringName) -> Image:
	if !path_absolute: return
	if imagesCreated.has(path_absolute): return imagesCreated[path_absolute]
	var path_str = String(path_absolute)
	var imageFile: Image = Image.load_from_file(path_str)
	imageFile.resource_path = path_str
	imagesCreated[path_absolute] = imageFile
	return imageFile

static func texture(path: StringName, imagesDirectory: bool = true, format: String = '.png') -> ImageTexture:
	return _texture_no_check(PathsStore.image(path,imagesDirectory,format))

static func _texture_no_check(path_absolute: StringName) -> Texture:
	if !path_absolute: return
	if imagesTextures.has(path_absolute): return imagesTextures[path_absolute]
	var image = _image_no_path_check(path_absolute)
	if !image: return null
	
	var texture = ImageTexture.create_from_image(image)
	texture.resource_name = path_absolute.get_basename()
	imagesTextures[path_absolute] = texture
	return texture
	
static func icon(icon_name: String) -> Texture: return _texture_no_check(PathsStore.icon_path(icon_name))

static func video(path: String) -> VideoStreamTheora: ##Get the [param video] path
	if !path.ends_with('.ogv'): path += '.ogv'
	if videosCreated.has(path): return videosCreated[path]
	
	var video_path = 'videos/'+path
	var path_absolute = PathsStore.detectFileFolder(video_path)
	if !path_absolute: return null
	
	var video = load(path_absolute)
	video.resource_name = PathsStore.get_base_path(video_path)
	videosCreated[path] = video
	return video

#region Audio File Methods
static func audio(path) -> AudioStream:
	if !path: return null
	if songsCreated.has(path): return songsCreated[path].duplicate()
	var stream_path = PathsStore.detectFileFolder(path)
	if !stream_path: return null
	
	var audio = audio_absolute(stream_path)
	songsCreated[path] = audio
	return audio.duplicate()

static func audio_absolute(path: String) -> AudioStream:
	match StringName(path.get_extension()):
		&'ogg': return AudioStreamOggVorbis.load_from_file(path);
		&'mp3': return AudioStreamMP3.load_from_file(path)
		&'wav': return AudioStreamWAV.load_from_file(path)
		_: return null
	
static func sound(path: String) -> AudioStreamOggVorbis:
	if !path.ends_with('.ogg'): path += '.ogg'
	if songsCreated.has(path): return soundsCreated[path].duplicate()
	
	var songPath = PathsStore.detectFileFolder('sounds/'+path)
	if !songPath: return null
	var audio = AudioStreamOggVorbis.load_from_file(songPath)
	if !audio: return
	audio.resource_name = path
	soundsCreated[path] = audio
	return audio

static func music(path: String) -> AudioStreamOggVorbis:
	var _music = musicCreated.get(path)
	if _music: return _music
	
	_music = PathsStore.detectFileFolder('music/'+path+'.ogg')
	if !_music: return null
	_music = AudioStreamOggVorbis.load_from_file(_music)
	musicCreated[path] = _music
	return _music

#endregion
#endregion

static func text(path: String) -> String:
	if not path.ends_with('.txt'): path += '.txt'
	if textFiles.has(path): return textFiles[path]
	
	var textFile = PathsStore.detectFileFolder(path)
	if !textFile: return ''
	var file = FileAccess.get_file_as_string(textFile)
	textFiles[path] = file
	return file

#region File metods
static func get_dialog(dir: String = '') -> FileDialog:
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	if not dir.ends_with('/'): dir = dir+'/'
	
	dialog.current_path = (dir if PathsDir.dir_exists(dir) else PathsStore.assetsPath+'/')
	dialog.size = ScreenUtils.screenSize/1.5
	
	dialog.visible = true
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	return dialog

##Save a File.[br]
##OBS: [param file_path] needs to contain the file extension: [br]
##[codeblock]
##Paths.saveFile({}, "res://file") ## Wrong ❌
##Paths.saveFile({}, "res://file.json") ## Correct ✅
##[/codeblock]
static func saveFile(json: Variant, file_path: String) -> void:
	if json is Dictionary: json = JSON.stringify(json,'\t')
	else: json = str(json)
	var folder_acess = FileAccess.open(file_path, FileAccess.WRITE)
	if folder_acess: folder_acess.store_string(json)

static func clear_files() -> void:
	soundsCreated.clear()
	imagesTextures.clear()
	imagesCreated.clear()
	clear_local_files()
	AnimationService.clear_anims()
	Character.clear_characters()

static func clear_local_files() -> void:
	shadersCreated.clear()
	shadersCodes.clear()
	textFiles.clear()
	jsonsLoaded.clear()
#endregion

#region Shader Methods
static func loadShader(path: String) -> ShaderMaterial:
	var absolute_path = PathsStore.shaderPath(path)
	if !absolute_path: return null
	
	var material: ShaderMaterial = shadersCreated.get(absolute_path)
	if material: return material.duplicate()
	
	material = ShaderMaterial.new()
	material.shader = loadShaderCodeAbsolute(absolute_path)
	_set_shader_parameters_to_default(material) # When you try to get a parameter, it returns "null" until the parameter is set.
	shadersCreated[absolute_path] = material
	return material

static func _set_shader_parameters_to_default(material: ShaderMaterial):
	for i in material.shader.get_shader_uniform_list():
		material.set_shader_parameter(i.name,RenderingServer.shader_get_parameter_default(material.shader.get_rid(),i.name))
static func loadShaderCode(path: String) -> Shader: return loadShaderCodeAbsolute(PathsStore.shaderPath(path))

static func loadShaderCodeAbsolute(absolute_path: String) -> Shader:
	if !absolute_path: return
	
	var shader = shadersCodes.get(absolute_path)
	if shader: return shader
	
	shader = Shader.new()
	var shader_code = FileAccess.get_file_as_string(absolute_path) 
	shader.resource_name = absolute_path.get_file().get_basename()
	shader.code = ShaderUtils.fragToGd(shader_code) if absolute_path.ends_with('.frag') else shader_code
	shadersCodes[absolute_path] = shader
	return shader
#endregion

#region Dirs Methods


static func _clear_paths_cache(): 
	PathsStore.clear()
	PathsDir.clear()
	NoteStyleData.styles_loaded.clear()
#endregion

#region Files Methods


#endregion


#region Json Methods
##Returns the json file from [param path].[br]
##Obs: If [param duplicate], this will returns a duplicated json, 
##making it possible to modify without damaging the original json
static func loadJson(path: String) -> Dictionary:
	if not path.ends_with('.json'): path += '.json'
	var json = jsonsLoaded.get(path)
	if !json: json = loadJsonNoCache(path); jsonsLoaded[path] = json
	return json

static func loadJsonNoCache(path: String) -> Dictionary: return load_json_absolute(PathsStore.detectFileFolder(path))

static func load_json_absolute(absolute_path: String) -> Dictionary:
	if !absolute_path: return {}
	var json = JSON.parse_string(FileAccess.get_file_as_string(absolute_path))
	return {} if json == null else json
#endregion

#region Data Methods
static func character(path: String) -> Dictionary: return load_json_absolute(PathsStore.character(path))

static func songData(path: String, difficulty: String, folder: String = '') -> Dictionary:
	path = PathsStore.song_data(path, difficulty, folder); if !path: return {}
	var json = load_json_absolute(path)
	return json.song if json.get("song") is Dictionary else json
#endregion
