@tool class_name PathsStore extends Object
##A Class that returns the path of the external files.

const BASE_FOLDERS: PackedStringArray = ['assets/','mods/','res://']
static var _files_directories_cache: Dictionary[StringName,String]
static var _images_paths_cache: Dictionary[StringName,String]
static var _icons_paths_cache: Dictionary[StringName,String]
static var _character_paths_cache: Dictionary[StringName, String]
static var is_system_case_sensitive: bool = StringName(OS.get_name()) in [&'macOS',&'Linux',&"FreeBSD", &"NetBSD", &"OpenBSD", &"BSD"]

#region Paths
static var assetsPath: StringName = get_assets_folder()
static var dirsToSearch: PackedStringArray 
static var extraDirectory: String: 
	set(dir):
		if extraDirectory == dir: return
		extraDirectory = dir
		update_search_dirs()

static var enableMods: bool = true:
	set(value): 
		enableMods = value; 
		update_search_dirs()

static var curMod: String: 
	set(mod):
		if mod == curMod: return
		curMod = mod; 
		update_search_dirs() 

#endregion

#region Formats
const model_formats: PackedStringArray = ['.tres','.glb']
const audio_formats: PackedStringArray = ['.ogg','.wav']
#endregion


#region Mods
static var modsData: Dictionary[String,ModData]
const commomFolders: PackedStringArray = [
	"characters",
	"custom_events",
	"custom_notetypes",
	"data",
	"fonts",
	"images",
	"scripts",
	"shaders",
	"shared",
	"songs",
	"sounds",
	"stages",
	"weeks"
]
static func _detect_mods() -> void:
	modsData.clear()
	var mods_path = assetsPath+'/mods'
	for mods in DirAccess.get_directories_at(mods_path):
		if commomFolders.has(mods): continue
		var data = ModData.new()
		data.name = mods
		modsData[mods] = data

static func getModOptionValue(mod: StringName, property: String, default: Variant = null) -> Variant:
	var data = modsData.get(mod); if !data: return default
	data = data.get("options"); if !data: return default
	return data.get(property,default)

static func getRunningMods(location: bool = false) -> PackedStringArray:
	var mods: PackedStringArray
	if location: 
		for mod in modsData: if isModRunning(mod): mods.append(assetsPath+'/mods/'+mod+'/')
	else: 
		for mod in modsData: if isModRunning(mod): mods.append(mod)
	return mods

static func isModRunning(mod_name: String) -> bool: 
	var data = modsData.get(mod_name)
	return data and data.enabled and (curMod == data.name or data.runsGlobally)

static func get_mods_enabled(location: bool = false) -> PackedStringArray:
	var mods: PackedStringArray
	for mod in modsData:
		var data = modsData[mod]; if !data.enabled: continue
		mods.append(data.name if !location else assetsPath+'/mods/'+data.name)
	return mods
#endregion

static func _static_init() -> void: 
	update_search_dirs()
	_detect_mods()

static func get_assets_folder() -> String:
	match OS.get_name():
		"Android": return '/storage/emulated/0/.FunkinGD'
		_: return OS.get_executable_path().get_base_dir()


static func detectFileFolder(path: StringName, case_sensive: bool = false) -> String:
	var path_cache = _files_directories_cache.get(path)
	if path_cache: return path_cache
	
	var path_string: String = String(path)
	if case_sensive: return _detect_file_folder_case_sensive(path)
	
	if FileAccess.file_exists(path_string): 
		_files_directories_cache[path] = path
		return path
	
	for d in dirsToSearch:
		var curPath: String = d + path_string
		if !FileAccess.file_exists(curPath): continue
		_files_directories_cache[path] = curPath
		return curPath
	return ''

static func _detect_file_folder_case_sensive(path: String) -> String:
	var file = path.get_file()
	var folder = path.get_base_dir()
	for d in dirsToSearch:
		var dir_path = d+folder
		var dir: DirAccess = PathsDir.get_dir(dir_path)
		if !dir: continue
		for i in dir.get_files():
			if not i == file: continue
			var full_path: String = dir_path+'/'+file
			_files_directories_cache[path] = full_path
			return full_path
	return ''

static func update_search_dirs(): ##Update the folders that the [method detectFileFolder] will search the files.
	dirsToSearch.clear()
	clear()
	
	var new_dirs: PackedStringArray
	
	if enableMods:
		new_dirs.append_array(getRunningMods(true))
		new_dirs.append(assetsPath+'/mods/')
	new_dirs.append(assetsPath+'/assets/')
	new_dirs.append(assetsPath+'/')
	new_dirs.append('res://assets/')
	
	if extraDirectory: for i in new_dirs: dirsToSearch.append(i+extraDirectory+'/'); dirsToSearch.append(i)
	else: dirsToSearch.append_array(new_dirs)


static var _asset_path_length: int = assetsPath.length()
## Returns the content-relative path, removing system, executable and mod folders:[codeblock]
## Paths.get_base_path("assets/image/combo.png")# -> Returns "image/combo.png"
## Paths.get_base_path("mods/Mod/sounds/three.png")# -> Returns "Mod/sounds/three.png"
## Paths.get_base_path("mods/Mod/sounds/three.png",false)# -> Returns "sounds/three.png"[/codeblock]
static func get_base_path(path: String, withMod: bool = true) -> String:
	if !path: return path
	if path.begins_with(assetsPath): path = path.right(-_asset_path_length-1)
	
	for i in BASE_FOLDERS: if path.begins_with(i): path = path.right(-i.length()); break
	
	if withMod: return path
	
	var find = path.find('/')
	var path_mod = path.left(find)
	if path_mod in modsData: path = path.right(-find-1)
	
	return path.strip_edges()

static func image(path: StringName, imagesDirectory: bool = true, format: String = '.png') -> String:
	var p = _images_paths_cache.get(path); if p: return p
	
	p = get_base_path(path,false)
	
	if !format.begins_with('.'): format = '.'+format
	if !p.ends_with(format): p += format
	
	if imagesDirectory and !p.begins_with('images/'): p = 'images/'+p
	p = detectFileFolder(p)
	_images_paths_cache[path] = p
	return p

static func character(path: String) -> String:
	var p = _character_paths_cache.get(path)
	if p: return p
	if !path.ends_with('.json'): path += '.json'
	p = detectFileFolder('characters/'+path)
	_character_paths_cache[path] = p
	return p

static func song(path: String):
	path = get_base_path(path)
	if !path.begins_with('songs/'): path = 'songs/'+path
	if !path.get_extension(): path += '.ogg'
	
	var paths: PackedStringArray = [path,path.to_lower()]
	
	for i in paths:
		var songPath = detectFileFolder(i)
		if songPath: return songPath
		
		songPath = detectFileFolder(i.replace(' ','-'))
		if songPath: return songPath
	return ''

static func font(path: String) -> String:
	var fontPath = detectFileFolder('fonts/'+path)
	if !fontPath:
		fontPath = 'res://assets/fonts/'+path; 
		if !FileAccess.file_exists(fontPath): return ''
	return fontPath

const icons_dirs: PackedStringArray = ['icons/','icons/icon-','winning_icons/','winning_icons/icon-']
static func icon_path(icon_name: StringName) -> StringName:
	var path = _icons_paths_cache.get(icon_name)
	if path: return path
	
	var icon_string = String(icon_name)
	for iconPath in icons_dirs: path = image(iconPath+icon_string); if path: _icons_paths_cache[icon_name] = path; return path
	return ''

static func file_exists(path: StringName) -> bool: return !!detectFileFolder(path)
const data_dirs: PackedStringArray = ['data/','data/songs/']
static func song_data(json: String = '',prefix: String = '',folder: String = '') -> String:
	if file_exists(json): return json
	
	if json.ends_with(".json"): json = json.left(-5)
	
	if !folder: folder = json
	else: 
		folder = get_base_path(folder,false)
		if folder.begins_with('data/'): folder = folder.right(-5)
	
	var json_path = folder+'/'+json
	var paths_to_lock: PackedStringArray
	
	if prefix:
		if prefix.to_lower() == 'normal':  paths_to_lock.append(json_path+'.json')
		paths_to_lock.append_array([json_path+'-'+prefix+'.json',json_path+'-chart-'+prefix+'.json'])
	else: paths_to_lock.append(json_path+'.json')
	
	paths_to_lock.append(json_path+'-chart.json')
	
	var contain_space = json_path.contains(' ')
	
	for i in paths_to_lock:
		var path_found: String
		for d in data_dirs: path_found = detectFileFolder(d+i,!is_system_case_sensitive); if path_found: return path_found
		if contain_space:
			i = i.replace(' ','-')
			for d in data_dirs: path_found = detectFileFolder(d+i,!is_system_case_sensitive); if path_found: return path_found
		
		i = i.to_lower()
		for d in data_dirs: path_found = detectFileFolder(d+i); if path_found: return path_found
	return ''

const shader_formats: PackedStringArray = ['.frag','.gdshader']
static func shaderPath(path: String) -> String:
	if FileAccess.file_exists(path): return path
	if !path.begins_with('shaders/'): path = 'shaders/'+path
	
	for i in shader_formats:
		var path_to_share = path
		if !path.ends_with(i): path_to_share += i
		
		var shader_path = detectFileFolder(path_to_share)
		if shader_path: return shader_path
	return ''

static func clear() -> void:
	_files_directories_cache.clear()
	_images_paths_cache.clear()
	_character_paths_cache.clear()
	_files_directories_cache.clear()
