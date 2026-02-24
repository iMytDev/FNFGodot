class_name EventKey extends Sprite2D

var chart_data: Dictionary = EventNote.get_base_data()
var event_data: Dictionary:
	set(val):
		event_data = val
		var timeline_tex = val.get(&"icon_timeline")
		texture = Paths.texture(timeline_tex) if timeline_tex else null
	
var event_name: StringName:
	set(val):
		event_name = val
		event_data = EventData.get_event_json(val)

func _ready() -> void:
	texture_changed.connect(_on_texture_changed)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_on_texture_changed()

func _on_texture_changed():
	if !texture: texture = load("uid://buha7m47s5fu1"); return
	if texture: scale = Vector2(30,30) / texture.get_size()
