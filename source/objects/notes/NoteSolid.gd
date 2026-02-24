extends NoteBase

func reloadNote() -> void:
	if stylePrefix: _reload_note_from_data(styleData.data[stylePrefix])
	else: _reload_note_without_data()

func _reload_note_from_data(data: Dictionary) -> void:
	var p = data.get(&'prefix')
	if !p: _reload_note_without_data()
	else: animation.add_animation_by_prefix(&'static', p, data.get(&'fps',24.0), true)

func _reload_note_without_data() -> void:
	var rect = Rect2(Vector2.ZERO,imageSize)
	if !styleData.is_full_image(noteDirection):
		var cut = imageSize / Vector2(styleData.keyCount,5)
		rect.position = Vector2(cut.x*noteData,cut.y)
		rect.size = cut
	image.region_rect = rect
	#pivot_offset = rect.size*0.5
