@tool
class_name Atlas
static var atlas_loaded: Dictionary[String,Dictionary]
static var maps_loaded: Dictionary
static func loadAtlasTxt(file: String) -> Dictionary[StringName, Array]:
	if !file.ends_with('.txt'): file += '.txt'
	
	if atlas_loaded.get(file): return atlas_loaded[file]
	var data: Dictionary[StringName, Array]
	
	for i in FileAccess.get_file_as_string(file).split('\n'):
		if !i: continue
		var find_equals = i.find('=')
		if find_equals == -1: continue
		
		var animName = i.left(find_equals-1)
		var find_underline: int = 0
		var prev_underline: int = 0
		while true:
			prev_underline = animName.find('_',prev_underline+1)
			if prev_underline == -1: break
			find_underline += prev_underline
			
		if find_underline == -1: continue
		
		var frame: int = int(animName.right(-find_underline))
		animName = animName.left(find_underline+1)
		
		var anim_frames: Array[Dictionary] = data.get_or_add(animName,Array([],TYPE_DICTIONARY,'',null))
		
		var anim_data = i.right(-find_equals-1).split(' ',false)
		var rect = Rect2(
			float(anim_data[0]),
			float(anim_data[1]),
			float(anim_data[2]),
			float(anim_data[3])
		)
		if anim_frames.size() < frame+1: anim_frames.resize(frame+1)
		
		var anim_dict: Dictionary[StringName,Variant] = {&'region_rect': rect}
		anim_frames[frame] = anim_dict
		
	atlas_loaded[file] = data
	return data

##Load the animation and sprites from the map('.json') file
static func loadMap(folder: String) -> Dictionary:
	var data = maps_loaded.get(folder)
	if data: return data.data
	
	data = _load_map_animations(folder+'/Animation.json')
	maps_loaded[folder] = {
		&'data': data,
		&'sprites': {}
	}
	return data

static func _load_map_animations(file: String) -> Dictionary[StringName, Array]:
	var data = Paths.loadJson(file)
	if !data: return data
	var result: Dictionary[StringName, Array]
	
	if !data.has("SD") or not data["SD"].has("S"):
		push_error("JSON inválido: SD/S não encontrado")
		return result
	
	for scene in data["SD"]["S"]:
		var scene_name = scene.get("SN", "scene")
		var layers = scene["TL"]["L"]
		
		var frame_idx: int = 0
		var frames := []
		
		while frame_idx < get_total_frames(layers):
			var draw_calls := []
			
			for layer_idx in range(layers.size()):
				var layer = layers[layer_idx]
				var fr := get_active_frame(layer["FR"], frame_idx)
				if fr == null or not fr.has("E"): continue

				for element in fr["E"]:
					if not element.has("SI"): continue
				
					var si = element["SI"]
					var trp = si.get("TRP", {})

					draw_calls.append({
						"sprite": clean_name(si.get("SN", "")),
						"transform": Transform2D(
							get_rotation(trp),
							Vector2.ONE,
							0.0,
							Vector2(trp.get("x",0.0),trp.get("y",0.0))
						)
					})
			frame_idx += 1
			frames.append(draw_calls)

		result[scene_name] = frames
	return result

static func loadMapSprites(folder: String) -> Dictionary[StringName, Rect2]:
	var data = maps_loaded.get(folder,{})
	if data: return data.sprites
	data = _load_map_sprites(folder+"/spritemap1.json")
	maps_loaded[folder] = {
		&'data': {},
		&'sprites': data
	}
	return data

static func _load_map_sprites(file: String) -> Dictionary[int, Rect2]:
	var sprite_data = Paths.loadJson(file)
	var data: Dictionary[int, Rect2]
	for i in sprite_data.get("ATLAS",{}).get("SPRITES",[]): 
		data[i.SPRITE.name.to_int()] = Rect2(i.SPRITE.x,i.SPRITE.y,i.SPRITE.w,i.SPRITE.h)
	return data

static func get_total_frames(layers: Array) -> int:
	var max_frame := 0
	for layer in layers: for fr in layer["FR"]: var end = fr["I"] + fr["DU"]; if end > max_frame: max_frame = end
	return max_frame

static func get_active_frame(frames: Array, index: int) -> Dictionary:
	for fr in frames: if index >= fr["I"] and index < fr["I"] + fr["DU"]: return fr
	return {}

static func get_rotation(trp: Dictionary) -> float:
	if trp.has("r"): return trp["r"]
	if trp.has("skX"): return trp["skX"]
	return 0.0

static func clean_name(name: String) -> String:
	# "bf misc/b head" -> "bf_head"
	return name.replace(" ", "_").replace("/", "_")
