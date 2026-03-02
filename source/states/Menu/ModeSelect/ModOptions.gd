extends "uid://d3jka7l4iy07n"
const mods_options: PackedStringArray = ['Character Editor','Chart Editor','Modchart Editor', "Mod Creator"]

func loadModsOptions():
	var index: int = 0
	for i in mods_options:
		var text = Label.new()
		text.text = i
		
		var icon_texture = Paths.texture('editors/icons/'+i.to_lower().replace(' ','_'))
		if icon_texture:
			var icon = Sprite2D.new()
			icon.texture = icon_texture
			icon.centered = false
			icon.position = Vector2(-130,-10)
			text.add_child(icon)
		text.modulate = UNSELECTED_COLOR
		text.name = i
		text.position.x = ScreenUtils.screenCenter.x-150
		text.position.y = ScreenUtils.screenCenter.y + 150*index - 50
		index += 1
		options.append(text)
		add_child(text)
	modulate.a = 0.0
