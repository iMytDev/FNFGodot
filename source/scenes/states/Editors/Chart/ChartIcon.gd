@tool
extends FunkinIcon

func _ready() -> void: super(); Conductor.beat_hit.connect(func(): scale += beat_value)
