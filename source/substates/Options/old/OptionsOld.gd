extends Node

const OptionMenu = preload("res://source/substates/Options/old/OptionMenu.gd")
var back_to: Variant #Can be a GDScript or a PackedScene
var cur_visual: Node

var visuals: Dictionary = _get_visuals()
var cur_menu: OptionMenu: set = set_cur_menu
var options_changed: bool
var cur_text_selected: Node
var menus_created: Dictionary
var prev_menus: Array


var bg: Sprite2D = Sprite2D.new()

var description_bg: SolidNode2D = SolidNode2D.new()
var description_text: Label = Label.new()
func _ready() -> void:
	add_child(bg)
	move_child(bg,0)
	bg.centered = false
	bg.texture = Paths.texture('menuDesat')
	
	#Load Options
	cur_menu = createMenuOptions(ClientPrefs.data,'default')
	description_text.name = &'Description'
	description_text.text = '<No Description>'
	description_text.size = Vector2(ScreenUtils.screenWidth,30)
	description_text.position.y = ScreenUtils.screenHeight-description_text.size.y
	description_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_text.add_child(description_bg)
	add_child(description_text)
	
	description_bg.scale = description_text.size
	description_bg.modulate = Color(0,0,0,0.5)
	description_bg.show_behind_parent = true

func _get_visuals() -> Dictionary:
	var dir = "res://source/substates/Options/Visuals/"
	var found: Dictionary = {}
	for i in DirAccess.get_files_at(dir):
		if !i.ends_with('.tscn'): continue
		var obj_name = i.get_basename()
		var scene = load(dir+i).instantiate()
		found[obj_name] = scene
		add_child(scene)
		scene.name = obj_name
		disableNode(scene)
	return found

func createMenuOptions(option_data: Prefs, tag: String):
	if menus_created.has(tag): return menus_created[tag]

	var node = OptionMenu.new()
	node.data = option_data
	node.loadInterators()
	node.on_index_changed.connect(_on_option_selected.bind(node))
	add_child(node)
	return node

func backMenu():
	if !prev_menus:
		if back_to:  SceneManager.change_scene(back_to); saveOptions()
		return
	cur_menu = prev_menus.pop_back()

#region Options Visual
func _on_option_selected(menu: OptionMenu):
	var data = menu.cur_data
	show_visual(data.get(&'visual',&''))
	description_text.text = data.get('description','<No Description>')

func show_visual(visual_name: String):
	if !visual_name and !cur_visual: return
	if cur_visual: 
		if visual_name == cur_visual.name: return
		disableNode(cur_visual)
	if visual_name: cur_visual = get_node(visual_name)
	if !cur_visual: return
	enableNode(cur_visual)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_BACKSPACE: backMenu()
			KEY_ENTER:
				var cur_option_data = cur_menu.cur_data
				if !cur_option_data: return
				if cur_option_data.has(&'menu'):
					prev_menus.append(cur_menu)
					cur_menu = createMenuOptions(cur_option_data.menu,cur_option_data.name)
				else:
					var obj = _get_object_selected()
					var value: Variant
					match cur_option_data.get(&'type',0):
						TYPE_BOOL: value = !obj.value
						_: return
					obj.value = value
					_call_setter(value)
			KEY_LEFT:
				var obj = _get_object_selected()
				if obj is OptionMenu.NumberRange: 
					obj.sub_value()
					_call_setter(obj.value)
				elif obj is OptionMenu.TextRange: 
					obj.value -= 1
					_call_setter(obj.key_value)
			KEY_RIGHT:
				var obj = _get_object_selected()
				if obj is OptionMenu.NumberRange:
					obj.add_value()
					_call_setter(obj.value)
				elif obj is OptionMenu.TextRange: 
					obj.value += 1
					_call_setter(obj.key_value)

func _call_setter(value: Variant) -> bool:
	var setter = cur_menu.cur_data.get(&'setter')
	if setter: setter.call(value); return true
	cur_menu.cur_data.object[cur_menu.cur_data.property] = value
	return false
	
func _get_object_selected():
	var obj = cur_menu.get_node(cur_menu.cur_data.name)
	if obj and obj.has_node('value'): return obj.get_node('value')
	return obj
	
#region Setters
func set_cur_menu(menu: OptionMenu):
	if cur_menu: disableNode(cur_menu)
	cur_menu = menu
	enableNode(menu)
	_on_option_selected(cur_menu)
func set_middlescroll(middle: bool):
	ClientPrefs.data.middlescroll = middle
	cur_visual.middle = middle

func set_downscroll(down: bool):
	ClientPrefs.data.downscroll = down
	cur_visual.downscroll = down
	
func set_play_as_opponent(play: bool):
	ClientPrefs.data.playAsOpponent = play
	cur_visual.left_side = play
#endregion

#region Visual Setters
func set_window_mode(mode: DisplayServer.WindowMode) -> void:
	var value = int(mode)
	DisplayServer.window_set_mode(mode)
	ClientPrefs.data.window_mode = value
func set_vsycn_mode(mode: DisplayServer.VSyncMode) -> void:
	DisplayServer.window_set_vsync_mode(mode)
	ClientPrefs.data.vsycn_mode = mode
	
func set_max_fps(fps: int) -> void: 
	Engine.max_fps = fps
	ClientPrefs.data.fps = fps
#endregion

func saveOptions(): Paths.saveFile(ClientPrefs,'res://data/options.json')

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: saveOptions()

static func disableNode(node: Node):
	if !node: return
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.visible = false

static func enableNode(node: Node):
	if !node: return
	node.process_mode = Node.PROCESS_MODE_INHERIT
	node.visible = true
