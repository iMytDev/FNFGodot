@tool
@icon("res://icons/StrumState3D.svg")
class_name PlayState3D extends PlayStateBase

@export var loadCharacterFromSong: bool = true
@onready var camGame: FunkinCamera3D
@export var boyfriend: CharacterBase3D
@export var dad: CharacterBase3D
@export var gf: CharacterBase3D

@onready var active_characters: Array[CharacterBase3D] = [boyfriend,dad,gf]

@export var camFollow: Vector3
var camFollowRotation: Vector3

func _ready(): gameMode = GameMode.MODE_3D; super();

func _setup_cameras():
	camGame = _get_or_add_camera(^"camGame", FunkinCamera3D)
	camGame.default_zoom = defaultCamZoom
	super()

func _load_song_objects() -> void:
	if loadCharacterFromSong: loadCharactersFromData()
	moveCamera()
	super()

#region Character Methods
func charactersDance() -> void:
	var beat = Conductor.beat
	for character in active_characters:
		if !(character and character.can_dance()): continue
		if !(beat % character.data.danceEveryNumBeats): character.dance()

func loadCharactersFromData():
	var data = SONG.data
	if boyfriend is CharacterSprite3D: boyfriend.loadCharacter(data.get('player1','bf'))
	if dad is CharacterSprite3D: dad.loadCharacter(data.get('player2','bf'))
	if gf is CharacterSprite3D: gf.loadCharacter(data.get('gfVersion','gf'))

func singCharacter(character: CharacterBase3D, anim_name: StringName) -> void: 
	if character is CharacterMesh3D: 
		character.animation.seek(0)
		character.animation.play(anim_name)
	elif character is CharacterSprite3D: character.animation.play(anim_name,true)
	character.holdTimer = get_process_delta_time()

func singCharacterFromNote(note: Note) -> void:
	var character = note.hitCharacter; if !character: return
	var anim = note.hitAnim
	if !character.animation.has_animation(anim): anim = singAnimations[note.noteData]
	character.autoDance = note.autoHit or !note.mustPress
	character.holdKeys = note.hit_actions
	singCharacter(character, anim)

func singMissCharacterFromNote(_note: Note) -> void: pass

func changeCharacter(_t: int = 0, _character: StringName = &'bf'): pass

func getCharacterFromNote(note: Note) -> Node: return gf if note.gfNote else (boyfriend if note.mustPress else dad)
#endregion

#region Camera Methods
func screenBeat(multi: float = 1.0) -> void: 
	super(multi); camGame.zoom += 0.05 * multi

func get_focus_position(char: CharacterBase3D) -> Vector3: return char.getCameraPosition()

func moveCamera(target: StringName = detectSection()) -> void:
	var node: CharacterBase3D
	match target:
		&"gf": node = gf
		&"dad": node = dad
		_: node = boyfriend
	if !node: return

	if node: 
		camFollow = get_focus_position(node)
		camFollowRotation = node.getCameraRotation()
	FunkinGD.callOnScripts(&'onMoveCamera', target)

func _follow_camera(delta: float):
	if Engine.is_editor_hint(): return
	var speed = _real_camera_speed*delta
	camGame.scroll_camera.position = camGame.scroll_camera.position.lerp(camFollow,speed)
	camGame.scroll_camera.rotation = camGame.scroll_camera.rotation.lerp(camFollowRotation,speed)
#endregion

#region Stage Methods
func load_stage(_stage: String): pass
func get_char_stage_position(_char: StringName) -> Vector3: return Vector3.ZERO
#endregion

#region Scripts Methods
func trigger_event(event: StringName, values: Dictionary) -> void:
	super(event, values)
	FunkinGD.callScript(&"onLocalEvent", "custom_events/3d/"+event, values)

func loadExternalScript(path: String) -> Object:
	var script = super(path); if script: return script
	return FunkinGD.addScript(path.get_base_dir()+'/3d/'+path.get_file())

func _load_scripts():
	super()
	if loadScripts: FunkinGD.load_scripts_from_dir('scripts/3d')
	if loadSongScript: FunkinGD.load_scripts_from_dir_absolute(Conductor.songData.json+'/3d')
#endregion

func _process(delta: float) -> void:
	super(delta)
	if camZooming: camGame.zoom = lerpf(camGame.zoom, camGame.default_zoom,delta*_real_zoom_speed)
	if camFollowPosition: _follow_camera(delta)

func set_default_zoom(v: float): 
	super(v); 
	if !is_node_ready(): return
	camGame.default_zoom = v; if Engine.is_editor_hint(): camGame.zoom = v

func get_restart_object() -> Object: return get_script()
