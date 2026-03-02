@abstract
class_name FunkinInternal extends Resource
#region Variables
##The node that will have all the source created using the [FunkinGD] methods. [b]Example:[/b][br]
## If the [method playSound] is called, the sound will be added to this node.[br]
## If the [method makeSprite] is called, the sprite will be added to this node.
## If the [method runTimer] is called, the timer will be processed from this node.
static var owner: Node

static var debugMode: bool = OS.is_debug_build()
static var game: PlayStateBase
static var modVars: Dictionary ##[b]Variables[/b] created using [method setVar] and [method createCamera] methods.

static var scriptsCreated: Dictionary ##Scripts created using [method addScript] function.
static var scriptsUID: Dictionary[int,Object]

static var dictionariesToCheck: Array[Dictionary] = [
	modVars,
	FunkinSpritesServer.spritesCreated,
	FunkinShadersServer.shadersCreated,
	FunkinTextServer.textsCreated,
	FunkinGroups.groups
]
#endregion

#region Script Arguments
static var method_list: Dictionary[StringName,Array]
#endregion



#region Classes Methods
static var class_dirs: PackedStringArray = [
	'',
	'res://',
	'res://source/',
	'res://source/general/',
	'res://source/objects/',
	PathsStore.assetsPath+'/assets/'
]
#endregion

#region Color Methods
static func _get_color(color: Variant) -> Color: 
	match typeof(color):
		TYPE_COLOR: return color
		TYPE_INT: return Color.hex(color)
		TYPE_STRING,TYPE_STRING_NAME: return Color.html(color)
		_: return Color.WHITE
#endregion

#region Script Methods
static func load_scripts_from_dir(dir_name: String) -> void:
	for i in PathsStore.dirsToSearch:
		var folder_name = i+dir_name; 
		var dir = PathsDir.get_dir(folder_name); if !dir: continue
		for file in dir.get_files(): 
			if !file.ends_with('.gd'): continue 
			var path = dir_name+'/'+file; if scriptsCreated.has(path): continue
			registerScript(_load_script_code(folder_name+'/'+file).new(), path)

static func load_scripts_from_dir_absolute(dir_name: String) -> void:
	var dir = PathsDir.get_dir(dir_name); if !dir: push_error("Error in load_scripts_from_dir_absolute: Dir don't exists."); return
	var dir_base = PathsStore.get_base_path(dir_name)
	for i in dir.get_files():
		if !i.ends_with('.gd'): continue 
		var path = dir_base+'/'+i; 
		if scriptsCreated.has(path): continue
		registerScript(_load_script_code(dir_name+'/'+i).new(), path)

static func _load_script_from_path(path: String) -> Object:
	var code = _get_script_code(path); 
	return code.new() if code else code

static func _get_script_code(path: String):
	var absolute_path = PathsStore.detectFileFolder(path); if !absolute_path: return
	var code = _load_script_code(absolute_path); if !code: return
	return code

static func _load_script_code(path_absolute: String) -> GDScript:
	var code = FileAccess.get_file_as_string(path_absolute); if !code: return
	var script: GDScript = GDScript.new()
	script.source_code = code
	script.take_over_path(path_absolute)
	script.reload()
	return script

static func _find_script_path(script: Object) -> String:
	var id = script.get_instance_id()
	for i in scriptsCreated: if scriptsCreated[i].get_instance_id() == id: return i
	return ''

static func _script_path(path: String): return path if path.ends_with('.gd') else path+'.gd'

static func _get_script(script: Variant) -> Object:
	if !script: return
	if script is Object: return script
	return scriptsCreated.get(_script_path(script))

static func get_arguments(script: Script) -> Dictionary[StringName,Variant]:
	var functions: Dictionary[StringName,Variant]
	if !script: return functions
	var methods = script.get_script_method_list()
	var f = methods.size()
	while f:
		f -= 1; 
		var data = methods[f]; 
		if data.flags & METHOD_FLAG_STATIC: continue
		
		var name: StringName = data.name
		var args = data.args; if !args: functions[name] = null; continue
		var new_args: Array[Dictionary]
		
		var default_args = data.default_args
		var args_default_length = default_args.size()
		var args_length = args.size()
		
		var a: int = 0
		while a < args_length: 
			var param_data = {&"type": args[a].type}
			if default_args:
				var d_i = args_default_length - (args_length - a)
				if d_i >= 0: param_data.default = default_args[d_i]
			new_args.append(param_data)
			a += 1
		functions[name] = new_args
	return functions



static func registerScript(script: Object, tag: StringName = &'') -> bool:
	if !script: return false
	var args = get_arguments(script.get_script())
	scriptsCreated[tag] = script; script.set_meta(&"arguments",args)
	for func_name in args: _register_callback_no_check(script,func_name)
	
	if args.has(&"onCreate"): script.onCreate()
	if args.has(&'onCreatePost') and game and game.get(&'stateLoaded'): script.onCreatePost(); 
	return true

static func _register_callback_no_check(script: Object, function: StringName):
	if !function in method_list: method_list[function] = Array([script],TYPE_OBJECT,&"",null)
	else: method_list[function].append(script)

static func removeScript(path: Variant): 
	if path is Object: path = _find_script_path(path)
	_remove_script_from_path(_script_path(PathsStore.get_base_path(path,false)))


static func _remove_script_from_path(path: StringName):
	var script: Object = scriptsCreated.get(path); if !script: return
	scriptsCreated.erase(path)
	
	var args = script.get_meta(&"arguments")
	if !args: FunkinGD.callOnScripts(&'onScriptRemoved', script, path); return
	
	for i in args:
		if method_list[i].size() == 1: method_list.erase(i)
		else: method_list[i].erase(script)
	FunkinGD.callOnScripts(&'onScriptRemoved', script, path)

static func _clear_scripts(absolute: bool = false):
	method_list.clear()
	modVars.clear()
	
	scriptsCreated.clear()
	FunkinAudioServer.clear()
	FunkinShadersServer.clear()
	FunkinSpritesServer.clear()
	FunkinTweenerServer.clear(absolute)
	FunkinTimerServer.clear(absolute)
	FunkinGroups.clear(absolute)
#endregion

#region Warning Methods
static func debug_error(warning: String):
	if OS.is_debug_build(): 
		push_error(warning)
	else: 
		debug_message(warning) 

static func debug_message(warning: String, color: Color = Color.RED, only_show_when_debugging: bool = true):
	if only_show_when_debugging and !debugMode: return
	
	var text = Global.show_label_warning(warning,5.0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.modulate = color 
	return text
#endregion
static func _add_game_node(node: Node) -> void:
	if owner: owner.add_child(node)
	else: Global.add_child(node)
