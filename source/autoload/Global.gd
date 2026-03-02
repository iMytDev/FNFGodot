@tool
extends Node
#region Properties
const TRANSITION = preload("uid://dkv13shj47jyv")

static var root: Node

var scripts_running = FunkinGD.scriptsCreated
var sprites_created = FunkinSpritesServer.spritesCreated
var method_list = FunkinGD.method_list


var anims = Sparrow.sparrows_loaded
var current_transition: TRANSITION

var error_prints: Array[Label]

var f11_to_fullscreeen: bool = true

#endregion

func _ready() -> void: root = get_tree().root
#region Swap Tree methods


#endregion

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_MINUS:
			AudioServer.set_bus_volume_db(0,maxf(-80.0,AudioServer.get_bus_volume_db(0) - 2.0))
		elif event.keycode == KEY_EQUAL:
			AudioServer.set_bus_volume_db(0,AudioServer.get_bus_volume_db(0) + 2.0)
		elif event.keycode == KEY_0:
			AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
		elif event.keycode == KEY_F11:
			if !f11_to_fullscreeen or !ScreenUtils.main_window or ScreenUtils.main_window.unresizable: return
			var mode = ScreenUtils.main_window.mode
			if mode == Window.MODE_EXCLUSIVE_FULLSCREEN:ScreenUtils.main_window.mode = Window.MODE_WINDOWED
			else: ScreenUtils.main_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN


#region Label Warning
func show_label_warning(text: Variant, time: float = 2.0, width: float = ScreenUtils.screenWidth) -> Label:
	text = str(text)
	for i in error_prints: i.position.y += 20
	var label = Label.new()
	label.size.x = width
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.text = text
	var timer = Timer.new()
	label.add_child(timer)
	add_child(label)
	timer.start(time)
	timer.timeout.connect(_label_timer_finished.bind(label))
	label.set('theme_override_constants/outline_size',10)
	label.position.x = ScreenUtils.screenCenter.x - label.size.x*0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	label.z_index = 1
	error_prints.append(label)
	return label

func _label_timer_finished(label: Label):
	var tween = label.create_tween().tween_property(label,'modulate:a',0,2)
	tween.finished.connect(label.queue_free)
	tween.finished.connect(func(): error_prints.erase(label))
#endregion
