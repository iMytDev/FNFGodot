@tool
class_name AnimationData extends Resource
##A Animation Data for [FunkinAnimation] Class.


##Frames that will be played. 
##This stores an [Array] that contains a [Dictionary]:[code]
##{
##'property': 'name',
##'value': Variant
##}[/code][br]
##Example: [codeblock]
##var animation = AnimationController.new()
##var node = Node2D.new()
##animation.node_to_animate = node
##animation.frames = [
##   [{^'position:x': -50}],
##   [{^'position:x':  50}]
##]
##animation.frameRate = 10
##animation.play()
##[/codeblock]
##In that example, in the first frame, the node will be move to -50 in x position,[br]
##and in the second frame will be moved to 50.
@export_storage var frames: Array
@export var reversed: bool = false
@export var loop_frame: int = 0
@export var frameRate: float = 24.0: set = _set_frame_rate
@export var speed_scale: float = 1.0: set = _set_speed_scale
var _real_frame_rate: float = 24.0

@export var looped: bool = false
@export_storage var asset: Variant
var prefix: String

func _set_frame_rate(f: float) -> void: frameRate = f; _update_fps()
func _set_speed_scale(s: float): speed_scale = s; _update_fps()

func _update_fps() -> void: _real_frame_rate = frameRate * speed_scale


func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"frames": property.usage = PROPERTY_USAGE_DEFAULT
		&"node_to_animate",&"finished": 
			property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_NO_INSTANCE_STATE
