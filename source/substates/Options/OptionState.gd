extends Node
const OPTION_VALUE = preload("uid://kvqnds3hf0r7")
const OPTION_MENU = preload("uid://s4ym17gyqvel")

static var back_to: Object

var options: Dictionary[String,Array] = {
	"Gameplay Options": [
		OPTION_VALUE.new("DownScroll",ClientPrefs.data,"downscroll"),
		OPTION_VALUE.new("MiddleScroll",ClientPrefs.data,"middlescroll"),
		OPTION_VALUE.new("Play As Opponent",ClientPrefs.data,"playAsOpponent")
	],
	"Video Options":[
		OPTION_VALUE.new("VSYNC MODE",ClientPrefs.data,"vsycn_mode",{
			"enabled": DisplayServer.VSYNC_MAILBOX, "disabled": DisplayServer.VSYNC_DISABLED}
		),
	],
	"Audio Options":[
		
	],
	"Mod Options": [
		
	]
}
var bar = SolidNode2D.new()

var options_nodes: Array[Node2D]
var cur_option_menu: Node2D
var option_menu_index: int

var title: FunkinText = FunkinText.new()
func _ready() -> void:
	var bg = Sprite2D.new()
	bg.centered = false
	bg.texture = Paths.texture("menuDesat")
	add_child(bg)
	
	
	bar.size = Vector2(ScreenUtils.screenSize.x, 60.0)
	bar.self_modulate = Color.BLACK
	add_child(bar)
	bar.add_child(title)
	title.scale = Vector2(0.6,0.6)
	title.position = Vector2(20,10)
	
	_load_option_nodes()
	_select_option_menu(0)

func _select_option_menu(i: int):
	if !options_nodes: 
		return
	i = wrapi(i,0,options_nodes.size())
	
	if cur_option_menu:
		_hide_options(cur_option_menu)
	
	cur_option_menu = options_nodes[i]
	title.text = cur_option_menu.name
	cur_option_menu.visible = true; 
	cur_option_menu.process_mode = PROCESS_MODE_INHERIT

func _hide_options(node: Node2D):
	node.visible = false; 
	node.process_mode = PROCESS_MODE_DISABLED

func _load_option_nodes():
	for i in options:
		var node = OPTION_MENU.new()
		options_nodes.append(node)
		node.name = i
		node.position.y = bar.size.y + 300
		for o in options[i]: node.add_option(o)
		_hide_options(node)
		add_child(node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_BACKSPACE:
				SceneManager.change_scene(back_to)
