@tool
class_name BarResource extends Resource

@export var position: Vector2: ##Bar Offset
	set(v): position = v; changed.emit()

@export var color: Color = Color.WHITE: ##Bar Color
	set(v): color = v; changed.emit()

@export var texture: Texture2D:
	set(v):
		texture = v; 
		texture_changed.emit(); 
		size = texture.get_size() if texture else Vector2.ZERO
		changed.emit()

var size: Vector2

@export var visible: bool = true:
	set(val): visible = val; changed.emit()

@export var scale: Vector2 = Vector2.ONE: ##Bar Scale
	set(v): scale = v; changed.emit()

signal texture_changed()
func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"color":
			property.usage = PROPERTY_USAGE_DEFAULT if !texture else PROPERTY_USAGE_STORAGE
		&"scale":
			property.usage = PROPERTY_USAGE_DEFAULT if texture else PROPERTY_USAGE_STORAGE
		
