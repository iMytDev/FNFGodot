@tool
@icon("res://icons/StrumState2D.svg")
class_name PlayState2D extends PlayStateBase

@export var boyfriend: Character2D
@export var dad: Character2D
@export var gf: Character2D

var boyfriendCameraOffset: Vector2
var girlfriendCameraOffset: Vector2
var opponentCameraOffset: Vector2


var camFollow: Vector2
@onready var camGame: FunkinCamera2D
@onready var active_characters: Array[Character2D]

@export_category('Groups')
@onready var boyfriendGroup: SpriteGroup
@onready var dadGroup: SpriteGroup
@onready var gfGroup: SpriteGroup


func _ready():
	if Engine.is_editor_hint(): super(); return
	boyfriendGroup = SpriteGroup.new()
	dadGroup = SpriteGroup.new()
	gfGroup = SpriteGroup.new()
	
	boyfriendGroup.name = &'boyfriendGroup'
	dadGroup.name = &'dadGroup'
	gfGroup.name = &'gfGroup'
	super()

func _setup_cameras() -> void:
	camGame = _get_or_add_camera(^"camGame")
	super()

func _load_song_objects():
	if Engine.is_editor_hint(): return
	
	camGame.add(gfGroup,true); 
	camGame.add(dadGroup,true); 
	camGame.add(boyfriendGroup,true)
	loadCharactersFromData()
	load_stage(SONG.data.get("stage",""))
	super()
	
#region Stage Methods
func _set_characters_order():
	var chars = stageJson.get('characters'); if !chars: return
	if chars.gf.has('zIndex'): camGame.move.call_deferred(chars.gf.zIndex)
	else: camGame.move(gfGroup,0)
	
	if chars.dad.has('zIndex'): camGame.move.call_deferred(dadGroup,chars.dad.zIndex)
	else: camGame.move(dadGroup,1)
	
	if chars.bf.has('zIndex'): camGame.move.call_deferred(boyfriendGroup,chars.bf.zIndex)
	else: camGame.move(boyfriendGroup,2)

func _load_characters_offset():
	var offset = stageJson.characters.bf.get('cameraOffsets')
	boyfriendCameraOffset = Vector2(offset[0],offset[1]) if offset else Vector2.ZERO
	
	offset = stageJson.characters.gf.get('cameraOffsets')
	girlfriendCameraOffset = Vector2(offset[0],offset[1]) if offset else Vector2.ZERO
	
	offset = stageJson.characters.dad.get('cameraOffsets')
	opponentCameraOffset = Vector2(offset[0],offset[1]) if offset else Vector2.ZERO

func _load_characters_stage_data():
	_load_characters_offset()
	
	gfGroup.visible = !stageJson.get('hide_girlfriend')
	boyfriendGroup.visible = !stageJson.get('hide_boyfriend')
	_set_characters_order()
	if boyfriend: set_character_position_from_stage(boyfriend)
	if dad: set_character_position_from_stage(dad)
	if gf: set_character_position_from_stage(gf)
	moveCamera(detectSection())
	
func load_stage(stage: String) -> void:
	if curStage == stage: return
	var json = Stage.loadStage("stages/"+stage+'.json')
	if !json: json = Stage.loadStage("stages/2d/"+stage+'.json'); 
	if !json: return
	curStage = stage
	load_stage_from_json(json)
	FunkinGD.callOnScripts(&"onLoadStage",stage)

func load_stage_from_json(stage: Dictionary):
	isPixelStage = stage.get(&"isPixelStage",false)
	FunkinGD.isPixelStage = isPixelStage
	
	defaultCamZoom = stage.cameraZoom
	cameraSpeed = stage.cameraSpeed
	camGame.zoom = defaultCamZoom
	
	for i in stageJson.get("props",[]): FunkinGD.removeSprite(i.get("name",""),true)
	stageJson = stage
	PathsStore.extraDirectory = stage.get(&"directory","")
	Stage.loadStageSprites(stage)
	_load_characters_stage_data()

func _check_stage_sprites_beat():
	for i in Stage.dance_sprites:
		if fmod(Conductor.beat,i.get_meta(&"danceEvery")): continue
		if !i.get_meta(&"has_dance_anim"): i.animation.play(&'idle',false)
		else:
			var danced = i.get_meta(&'danced',false)
			i.animation.play(&'danceLeft' if danced else &'danceRight')
			i.set_meta(&'danced',!danced)
#endregion

func _process(delta: float) -> void:
	if camZooming: 
		camGame.zoom = lerpf(camGame.zoom,camGame.default_zoom,delta*_real_zoom_speed*Conductor.music_pitch)
	if camFollowPosition and !Engine.is_editor_hint(): 
		_follow_camera(delta)
	super(delta)

func onBeatHit() -> void: _check_stage_sprites_beat(); super()

#region Scripts methods
func trigger_event(event: StringName, values: Dictionary) -> void:
	super(event, values)
	print("custom_events/2d/"+event)
	FunkinGD.callScript("custom_events/2d/"+event,&"onLocalEvent", values)

func loadExternalScript(path: String) -> Object:
	var script = super(path); if script: return script
	return FunkinGD.addScript(path.get_base_dir()+'/2d/'+path.get_file())

func _load_scripts():
	super()
	if loadScripts: FunkinGD.load_scripts_from_dir('scripts/2d')
	if loadSongScript: FunkinGD.load_scripts_from_dir_absolute(SONG.json_folder+'/2d')
#endregion

#region Character Methods
func set_character_position_from_stage(char: Character2D, type: Character.Type = char.charType):
	if !char: return
	match type:
		Character.Type.OPPONENT: char.position = get_char_stage_position(&"dad")
		Character.Type.GF: char.position = get_char_stage_position(&"gf")
		_: char.position = get_char_stage_position(&"bf")

func get_char_stage_position(char: StringName) -> Vector2:
	var char_data = stageJson.characters.get(char)
	return char_data.position if char_data else Vector2.ZERO

func loadCharacter(json: String, type: Character.Type) -> Character2D:
	var group
	match type:
		Character.Type.OPPONENT: group = dadGroup;
		Character.Type.GF: group = gfGroup;
		_: group = boyfriendGroup
	
	for i in group: if i.curCharacter == json: return i
	var char = Character.create_from_json(json, type); if !char: return
	group.append(char)
	set_character_position_from_stage(char, type)
	return char

func loadCharactersFromData():
	if !boyfriend: boyfriend = loadCharacter(SONG.data.get("player1","bf"),Character.Type.BF)
	if boyfriend: active_characters.append(boyfriend)
	
	if !dad: dad = loadCharacter(SONG.data.get("player2","bf"),Character.Type.OPPONENT)
	if dad: active_characters.append(dad)
	
	if !gf: gf = loadCharacter(SONG.data.get("gfVersion","bf"),Character.Type.GF)
	if gf: active_characters.append(gf)
	
	moveCamera(detectSection())

func charactersDance() -> void:
	var b = Conductor.beat
	for i in active_characters: if i and i.can_dance() and !(b % i.data.danceEveryNumBeats): i.dance()

func singCharacter(character: Character2D, anim_name: StringName) -> void:
	if !character or character.stunned: return
	character.holdTimer = get_process_delta_time()
	character.heyTimer = 0.0
	character.specialAnim = false
	character.animation.play(anim_name,true)

func singCharacterFromNote(note: Note) -> void:
	var character = note.hitCharacter; if !character: return
	var anim = note.hitAnim
	var character_anim = character.animation
	if !character_anim.has_animation(anim): 
		anim = singAnimations[note.noteData]; if !character_anim.has_animation(anim): return
	
	var mustPress = (note.strumNote.mustPress if note.strumNote else false)
	character.autoDance = note.autoHit or not mustPress
	character.holdKeys = note.strumNote.hit_actions
	singCharacter(character,anim)

func singMissCharacterFromNote(note: Note) -> void: singCharacter(note.hitCharacter, note.hitAnim+'-miss')

func getCharacterFromNote(note: Note) -> Character2D: return gf if note.gfNote else (boyfriend if note.mustPress else dad)
#endregion

#region Camera Methods
func set_default_zoom(value: float) -> void: super(value); camGame.default_zoom = value;

func moveCamera(target: StringName = detectSection()) -> void:
	FunkinGD.callOnScripts(&'onMoveCamera', target)
	camFollow = get_focus_position(FunkinGD.getProperty(target))

func _follow_camera(delta: float):
	var speed =_real_camera_speed * delta
	var scroll = camFollow - ScreenUtils.screenCenter
	if speed >= 1.0: camGame.scroll = scroll
	else: camGame.scroll = camGame.scroll.lerp(scroll,speed)

func screenBeat(multi: float = 1.0) -> void:
	camGame.zoom += 0.015 * multi
	super(multi)

func get_focus_position(obj: Node2D) -> Vector2:
	if !obj: return Vector2.ZERO
	if obj is Character2D: 
		match obj.charType:
			Character.Type.BF: return obj.getCameraPosition() + boyfriendCameraOffset
			Character.Type.OPPONENT: return obj.getCameraPosition() + opponentCameraOffset
			Character.Type.GF: return obj.getCameraPosition() + girlfriendCameraOffset
		return obj.getCameraPosition()
	elif obj is FunkinSprite2D: return obj.getMidpoint()
	return obj.position
#endregion

func clear(): super(); camGame.controller.clear_filters()

func get_restart_object() -> Object: return load("uid://ckiryac52s0pv")
