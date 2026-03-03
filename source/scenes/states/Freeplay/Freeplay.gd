extends Node
const ModImageSize = Vector2(60.0, 60.0)
const SONG_ICON_SIZE = Vector2(150.0, 150.0)

const default_difficulties: PackedStringArray = ['easy','normal','hard']
const Sprite2DScaleWindow = preload("uid://bxwxuogjmeb0b")

const WeekNode = preload("uid://d3oulttdmbwlv")

const default_difficulty_color: Dictionary[StringName, Color] ={
	&"easy": Color.GREEN,
	&"normal": Color.YELLOW,
	&"hard": Color.RED
}

static var last_mod_index: int
static var last_difficulty: int
static var mods_node_created: Dictionary[StringName, Variant]
static var mods_created_keys: Array
static var cur_mod_selected: StringName
static var back_to: Object

@export var weeks: Array[FreeplaySection]
@export var load_external_weeks: bool = true

@onready var bar_top = SolidNode2D.new()
@onready var bar_bottom = SolidNode2D.new()
@onready var mod_name_node = FunkinText.new()
@onready var mod_sprite = SparrowAnimatedSprite2D.new()

@onready var bg = Sprite2DScaleWindow.new()

var default_bg_texture: Texture

var cur_mod_index: int: set = set_mod_index
var cur_mod_node: WeekNode
var default_mod_icon: Texture

var cur_song_node: Node
var cur_song_data: SongData

@onready var difficultyText: Label = Label.new()
var difficulty: int: set = set_difficulty
var difficulty_string: String

@onready var left_arrow = SparrowAnimatedSprite2D.new()
@onready var right_arrow = SparrowAnimatedSprite2D.new()

#region Weeks Methods
func _load_weeks():
	if load_external_weeks: _load_external_weeks()
	for w in weeks: if w: _load_week_nodes(w)
	
	mods_created_keys = mods_node_created.keys()

func _load_external_weeks():
	for f in PathsStore.get_mods_enabled(true):
		var folder = f+'/weeks'
		var dir = PathsDir.get_dir(folder)
		if !dir: continue
		for i in dir.get_files():
			if i.ends_with('.json'): load_week_from_json(folder+'/'+i) 
	load_external_weeks = true

func load_week_from_json(json_path: String):
	var json = Paths.loadJsonNoCache(json_path)
	var json_songs = json.get('songs'); if !json_songs: return
	var mod = PathsDir.get_mod_folder(json_path)
	
	var week_data = FreeplaySection.new()
	PathsStore.curMod = mod
	week_data.title = mod
	week_data.bg = Paths.texture("mods/"+mod+"/images/menuDesat",false); 
	week_data.mod_icon = Paths.texture('mods/'+mod+'/pack',false)
	
	
	var difficulties: PackedStringArray
	var diff_colors: Dictionary[StringName, Color] = default_difficulty_color
	var diff_colors_find = json.get('difficulty_colors')
	if diff_colors_find:
		var new_colors: Dictionary[StringName, Variant]
		for i in diff_colors_find: new_colors[i.to_lower().strip_edges()] = ColorUtils.array_to_color(diff_colors_find[i],true)
		diff_colors = new_colors
	
	var diff_string = json.get('difficulties')
	if diff_string: for i in diff_string.split(','): difficulties.append(i.to_lower().strip_edges())
	else: difficulties = default_difficulties
	
	for i in json_songs:
		var song = SongData.new()
		song.songName = i[0]; 
		song.icon = Paths.icon(i[1]);
		song.bg_color = ColorUtils.array_to_color(i[2],true)
		song.mod = week_data.title
		song.difficulty_colors = diff_colors
		song.difficulties = difficulties
		week_data.songs.append(song)
	weeks.append(week_data)

func _load_week_nodes(week: FreeplaySection):
	var week_node = mods_node_created.get(week.title)
	if !week_node: 
		week_node = WeekNode.new()
		if week.title: week_node.name = week.title
		mods_node_created[week.title] = week_node
		week_node.set_meta(&"modData",week)
	week_node.hide_week()
	
	for i in week.songs:
		var node = _load_song_data(i)
		node.position.y += 150 * week_node.get_child_count()
		week_node.add_child(node)
#endregion

#region Mod Methods
func on_song_selected(node: Node) -> void: 
	cur_song_node = node
	cur_song_data = node.get_meta(&"songData")
	set_difficulty(difficulty)

func select_mod(mod: StringName) -> void:
	if cur_mod_node: cur_mod_node.hide_week(); cur_mod_node.on_song_selected.disconnect(on_song_selected)
	cur_mod_node = mods_node_created.get(mod); 
	if !cur_mod_node: return
	
	cur_mod_node.show_week(); 
	cur_mod_node.on_song_selected.connect(on_song_selected)
	cur_song_node = cur_mod_node.cur_song
	on_song_selected(cur_mod_node.cur_song)
	
	
	var mod_data = cur_mod_node.get_meta(&"modData")
	mod_name_node.text = mod
	mod_name_node.position.y = (ModImageSize.y - mod_name_node.pivot_offset.y) * 0.5
	var mod_tex = mod_data.mod_icon; if !mod_tex: mod_tex = default_mod_icon
	mod_sprite.texture = mod_tex
	
	var image_size = mod_sprite.texture.get_size() if mod_sprite.texture else Vector2.ZERO
	if mod_sprite.animation_data: image_size = mod_sprite.pivot_offset*2.0
	
	mod_sprite.region_rect.size = image_size
	mod_sprite._draw_scale = ModImageSize / image_size
	
	var bg_tex = mod_data.bg; if !bg_tex: bg_tex = default_bg_texture 
	if bg_tex != bg.texture: bg.texture = bg_tex; bg.self_modulate = Color.BLACK

func set_mod_index(i: int):
	cur_mod_index = wrapi(i, 0,mods_created_keys.size())
	last_mod_index = cur_mod_index
	select_mod(mods_created_keys[cur_mod_index])
#endregion

#region Song Methods
func _load_song_data(song_data: SongData) -> Node2D:
	PathsStore.curMod = song_data.mod
	
	var text = FunkinText.new(song_data.songName)
	text.position.x = SONG_ICON_SIZE.x + 10
	text.name = text.text
	text.set_meta(&"songData",song_data)
	
	var icon_texture: Texture
	if song_data.icon: icon_texture = song_data.icon
	elif song_data.icon_name: icon_texture = Paths.icon(song_data.icon_name)
	
	if icon_texture:
		var icon: Node2D
		var tex_size: Vector2
		if song_data.icon_has_states:
			icon = FunkinIcon.new(); 
			icon.set_icon(icon_texture)
			tex_size = icon.image.region_rect.size
		else:
			icon = Sprite2D.new();
			icon.centered = false
			icon.texture = icon_texture
			tex_size = song_data.icon.get_size()
		
		icon.position = Vector2(-SONG_ICON_SIZE.x - 10,-SONG_ICON_SIZE.y * 0.3)
		icon.scale = get_uniform_fit_scale(tex_size, SONG_ICON_SIZE)
		text.add_child(icon)
	
	return text

func _enter_song(songData: SongData):
	if !songData: return
	var trans = FunkinTransition.create_transition()
	var tween_trans = trans.start_trans()
	
	set_process_input(false)
	
	
	tween_trans.finished.connect(
		_enter_song_no_transition.bind(songData),
		CONNECT_ONE_SHOT
	)

func _enter_song_no_transition(songData: SongData):
	var instance: Node
	
	var scene: Resource
	FunkinAudioServer.stopSound(&"freakyMenu")
	
	if songData.packedScene: scene = load(songData.packedScene)
	if scene: instance = scene.instantiate() if scene is PackedScene else scene.new()
	else: instance = PlayState2D.new(songData)
	
	
	#Set after entering the scene so that the file saved in the scene is replaced for this one.
	instance.tree_entered.connect(func():
		instance.set("SONG", songData),
		CONNECT_ONE_SHOT
	)
	SceneManager.change_scene(instance,false)
#endregion

#region Difficulty
func _update_difficulty_text() -> void: 
	difficultyText.text = difficulty_string.to_lower()
	var color: Color = Color.WHITE
	if cur_song_data: color = cur_song_data.difficulty_colors.get(difficulty_string,Color.WHITE)
	difficultyText.add_theme_color_override(&'font_color', color)
	
	left_arrow.modulate = color
	right_arrow.modulate = color
	_update_difficulty_position()

func _update_difficulty_position() -> void:
	difficultyText.position.x = ScreenUtils.screenWidth - difficultyText.get_minimum_size().x - 60
	right_arrow.position.x = difficultyText.get_minimum_size().x + 10
	
func set_difficulty(i: int) -> void:
	if !cur_song_node: return
	var difficulties = cur_song_node.get_meta(&"songData").difficulties
	if !difficulties or difficulties.size() == 1: 
		difficulty = 0; last_difficulty = 0;
		left_arrow.visible = false
		right_arrow.visible = false
	else: 
		left_arrow.visible = true
		right_arrow.visible = true
		difficulty = i
	last_difficulty = i
	_update_difficulty_string()

func _update_difficulty_string():
	if !cur_song_node: return
	var difficulties = cur_song_node.get_meta(&"songData").difficulties
	if !difficulties: difficulties = 0; difficulty_string = '';
	else: difficulty_string = difficulties[absi(difficulty) % difficulties.size()]
	cur_song_data.difficulty = difficulty_string
	_update_difficulty_text()

#endregion

#region Input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT: 
				if !Input.is_key_pressed(KEY_SHIFT): cur_mod_index -= 1
				else: difficulty -= 1
			KEY_RIGHT: 
				if !Input.is_key_pressed(KEY_SHIFT): cur_mod_index += 1
				else: difficulty += 1
			KEY_ENTER: 
				if cur_song_node: _enter_song(cur_song_node.get_meta(&"songData"))
			KEY_BACKSPACE: 
				SceneManager.change_scene(back_to)
#endregion

func _process(delta: float) -> void:
	var offset = 5.0 * sin(Time.get_ticks_msec()*0.002)
	bar_top.position.y = -5.0 + offset
	bar_bottom.position.y = ScreenUtils.screenHeight + 5.0 - bar_bottom.size.y - offset
	if cur_song_data: bg.self_modulate = bg.self_modulate.lerp(cur_song_data.bg_color, delta * 10.0)

func _ready():
	PathsStore.curMod = ''
	default_mod_icon = Paths.texture("pack",false)
	default_bg_texture = Paths.texture("menuDesat")
	
	get_window().size_changed.connect(_update_difficulty_position)
	add_child(bg, false, Node.INTERNAL_MODE_FRONT)
	
	
	if !mods_node_created: _load_weeks()
	
	for i in mods_node_created: add_child(mods_node_created[i])
	
	if mods_created_keys: set_mod_index(last_mod_index)
	
	bar_top.size = Vector2(ScreenUtils.screenWidth,78)
	bar_top.name = &"bar_top"
	bar_top.self_modulate = Color.BLACK
	add_child(bar_top)
	
	bar_bottom.size = Vector2(ScreenUtils.screenWidth,78)
	bar_bottom.self_modulate = Color.BLACK
	bar_bottom.name = &"bar_bottom"
	add_child(bar_bottom)
	
	var bottom_text = Label.new()
	bottom_text.add_theme_color_override('font_color', Color.DIM_GRAY)
	bottom_text.text = 'Left/Right Arrows: Change Mod\nShift + Left/Right Arrows: Change Difficulty'
	bottom_text.position.x = 10
	bar_bottom.add_child(bottom_text)

	difficultyText.add_theme_font_override('font',load("res://assets/fonts/FNFWEEKUIFONT.TTF"))
	difficultyText.add_theme_font_size_override("font_size",90)
	difficultyText.position.y = 5
	_update_difficulty_text()
	
	_load_arrow(left_arrow)
	left_arrow.position = Vector2(-60.0,-5)
	difficultyText.add_child(left_arrow)
	
	var left_button = Button2D.new()
	left_button.pressed.connect(func(): difficulty -= 1)
	left_button.size = left_arrow.region_rect.size
	left_arrow.add_child(left_button)
	
	_load_arrow(right_arrow)
	right_arrow.flip_h = true
	right_arrow.position.y = -5
	difficultyText.add_child(right_arrow)
	
	var right_button = Button2D.new()
	right_button.pressed.connect(func(): difficulty += 1)
	right_button.size = right_arrow.region_rect.size
	right_arrow.add_child(right_button)
	
	
	mod_name_node.scale = Vector2(0.5,0.5)
	mod_sprite.position = Vector2(60.0, 10.0)
	mod_name_node.position.x = ModImageSize.x + 50
	
	
	bar_bottom.add_child(difficultyText)
	bar_top.add_child(mod_sprite)
	mod_sprite.add_child(mod_name_node)
	set_difficulty(last_difficulty)

func _load_arrow(arrow):
	arrow.texture = Paths.texture('freeplay/freeplaySelector')
	arrow.looped = true
	arrow.scale = Vector2(0.8,0.8)
	arrow._load_sparrow()

func _exit_tree() -> void:
	if !is_queued_for_deletion(): return
	while get_child_count():
		remove_child(get_child(0))
func get_uniform_fit_scale(size: Vector2, to: Vector2, max: bool = false) -> Vector2:
	var _size = to / size
	var val: float
	if max: val = maxf(_size.x,_size.y)
	else: val = minf(_size.x,_size.y)
	return Vector2(val,val)
