extends Node2D



var options: Array
var option_index: int = 0: set = _set_option_index

var _pos_lerp: float

var cur_option: Node: set = _select_option

func _set_option_index(i: int = option_index):
	option_index = wrapi(i,0,options.size())
	FunkinAudioServer.playSound("scrollMenu")
	if options: cur_option = options[option_index]

func _select_option(i: Node):
	if cur_option: _unselect_option(cur_option)
	cur_option = i;
	if i: 
		i.modulate = Color.WHITE; 
		i.set_process_unhandled_input(true)

func _unselect_option(i: Node):
	i.modulate = Color.DIM_GRAY
	i.set_process_unhandled_input(false)

func add_option(node: CanvasItem):
	node.position = Vector2(10,120.0 * options.size())
	options.append(node)
	if is_node_ready(): 
		add_child(node)
		_unselect_option(node)

func _ready() -> void:
	for i in options: add_child(i); _unselect_option(i)
	_set_option_index()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP: option_index -= 1
			KEY_DOWN: option_index += 1

func _process(delta: float) -> void:
	if !options: return
	_pos_lerp = lerpf(_pos_lerp,options[option_index].position.y, delta*10.0)
	var t = transform
	t.origin.y -= _pos_lerp
	RenderingServer.canvas_item_set_transform(get_canvas_item(), t)
