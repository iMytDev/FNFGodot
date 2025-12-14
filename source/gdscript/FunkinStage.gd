static var dance_sprites: Array
static var danced: bool = false

static var json: Dictionary
##Load Sprites from the stage json.[br]
##[b]OBS:[/b] Is recommended to [u]call this function after the characters group are added in PlayState.[/u][br][codeblock]
##loadSprites(
##{"props":
##	   [
##       {
##         "zIndex": 10,
##         "danceEvery": 0,
##         "position": [-220, -80],
##         "scale": [0.9, 0.9],
##         "name": "limoSunset",
##         "animType": "sparrow",
##         "isPixel": false,
##         "scroll": [0.1, 0.1],
##         "assetPath": "limo/erect/limoSunset",
##         "animations": []
##       }
##    ]
##)[/codeblock]
##[b]Tip:[/b] The sprites created using this function can be acessed by his [param name] from functions like 
##[method FunkinGD.getProperty] and [method FunkinGD.setProperty].

static func loadStage(stage: String) -> Dictionary:
	json.assign(convert_old_to_new(Paths.loadJson(Paths.stage(stage))))
	json.merge(getStageBase(),false)
	Paths.extraDirectory = json.get('directory','')
	json.path = stage
	return json

static func convert_old_to_new(json: Dictionary):
	var new_json: Dictionary = getStageBase()
	
	for i in json: if new_json.has(i): new_json[i] = json[i]
	
	
	if json.has('camera_girlfriend'): new_json.characters.gf.cameraOffsets = json.camera_girlfriend
	if json.has('camera_boyfriend'): new_json.characters.bf.cameraOffsets = json.camera_boyfriend
	if json.has('camera_opponent'): new_json.characters.dad.cameraOffsets = json.camera_opponent
	
	#var chars = new_json.characters
	#for i in chars:
		#var pos = chars[i].position
		#if i == 'gf': pos[0] -= 280; pos[1] -= 700
		#else: pos[0] -= 180; pos[1] -= 750
	
	new_json.cameraZoom = json.get('defaultZoom',new_json.cameraZoom)
	new_json.cameraSpeed = json.get('camera_speed',new_json.cameraSpeed)
	new_json.characters.bf.position = json.get('boyfriend',new_json.characters.bf.position)
	new_json.characters.dad.position = json.get('opponent',new_json.characters.dad.position)
	new_json.characters.gf.position = json.get('girlfriend',new_json.characters.gf.position)
	return new_json

static func getPsychStageBase() -> Dictionary:
	return {
		"directory": "",
		"isPixelStage": false,
		"hide_girlfriend": false,
		"hide_boyfriend": false,
		"hide_opponent": false,
		"defaultZoom": 1.0,
		"camera_speed": 1.0,
		"boyfriend": [770.0,100.0],
		"opponent": [100.0,100.0],
		"girlfriend": [0.0,90.0],
		"camera_boyfriend": [0.0,0.0],
		"camera_opponent": [0.0,0.0],
		"camera_girlfriend": [0.0,0.0],
		'path': ''
	}

static func getStageBase() -> Dictionary:
	return {
		"cameraZoom": 1.0,
		"cameraSpeed": 1.0,
		"props": [],
		"hide_girlfriend": false,
		"isPixelStage": false,
		"characters": {
			"gf": { 
				"position": [808.5, 854], 
				"cameraOffsets": [0, 0]
			},
			"bf": {
				"position": [1297.5, 871],
				"cameraOffsets": [-100, -100]
			},
				
			"dad": {
				"position": [290.5, 869],
				"cameraOffsets": [150, -100]
			}
		},
		"directory": ""
	}
