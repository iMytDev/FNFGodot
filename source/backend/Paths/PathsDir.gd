@tool
class_name PathsDir extends Object

static var _dir_exists_cache: Dictionary[StringName,DirAccess]
static func dir_exists(dir: String): return !!get_dir(dir)

static func get_dir(dir: String) -> DirAccess:
	if _dir_exists_cache.has(dir): return _dir_exists_cache[dir]
	var _dir = DirAccess.open(dir)
	_dir_exists_cache[dir] = _dir
	return _dir

static func get_files_at(folder: String, return_folder: bool = false, filters: Variant = '', with_extension: bool = false) -> PackedStringArray:
	var f: PackedStringArray = PackedStringArray()
	if filters is String: filters = PackedStringArray([filters]) if filters else PackedStringArray()
	if return_folder: 
		for i in PathsStore.dirsToSearch: f.append_array(get_files_at_absolute(i+folder,return_folder,filters,with_extension))
	else: 
		for i in PathsStore.dirsToSearch: for s in get_files_at_absolute(i+folder,return_folder,filters,with_extension): if !s in f: f.append(s)
	return f

static func get_files_at_absolute(
	folder: String, 
	return_folder: bool = false, 
	filters: PackedStringArray = PackedStringArray(), 
	with_extension: bool = false
) -> PackedStringArray:
	var dir = get_dir(folder)
	
	if !dir: return PackedStringArray()
	
	var files: PackedStringArray = dir.get_files()
	
	if !filters and !return_folder and with_extension: return files
	var index = 0
	while index < files.size():
		var s = files[index]
		if filters and not s.get_extension() in filters: 
			files.remove_at(index); 
			continue
		
		if !with_extension: s = s.get_basename();
		if return_folder: s = folder+'/'+s
		files[index] = s
		index += 1
	
	return files

##Returns the mod folder in [param path]. [br]
##[b]Note:[/b] If don't found, will return [param default].
static func get_mod_folder(path: String, default: String = Paths.game_name) -> String:
	path = PathsStore.get_base_path(path)
	var bar_find = path.find('/')
	if bar_find != -1: path = path.left(bar_find)
	
	if !path or path in PathsStore.commomFolders: return default
	return path

static func clear() -> void: 
	_dir_exists_cache.clear()
