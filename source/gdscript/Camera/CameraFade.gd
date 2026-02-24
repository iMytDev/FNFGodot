class_name CameraFadeRect extends CameraBG

var speed: float = 1.0
func _process(delta: float) -> void:
	modulate.a = clamp(modulate.a + (delta * speed),0.0,1.0)
	if !modulate.a and speed < 0.0: queue_free()
