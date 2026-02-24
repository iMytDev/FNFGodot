@icon("res://icons/letter.svg")
extends SparrowSprite
var imageFile: StringName:
	set(path): texture = Paths.texture(path); imageFile = path

var animation: Anim = Anim.new()

var letter: StringName = '': set = set_letter

var suffix: String = ' bold instance 1'
func _init(imagePath: StringName = ''):
	animation.node_to_animate = self
	if imagePath: imageFile = imagePath

func set_letter(_letter: StringName):
	var prefix = _letter.to_lower()+suffix
	letter = _letter; animation.add_animation_by_prefix('anim',prefix,24,true)

func _process(delta: float) -> void: animation.process_frame(delta)
