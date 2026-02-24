class_name CameraFlashRect extends CameraBG

var speed: float = 1.0
func _process(delta: float) -> void:
	modulate.a -= delta * speed
	if modulate.a <= 0.0: queue_free()
