extends "res://source/states/PlayStateBase.gd"

@export var boyfriend: Character
@export var dad: Character
@export var gf: Character

var boyfriendCameraOffset: Vector2 = Vector2.ZERO
var girlfriendCameraOffset: Vector2 = Vector2.ZERO
var opponentCameraOffset: Vector2 = Vector2.ZERO


var camFollow: Vector2
var camFollowPosition: bool = true
var camGame: FunkinCamera = FunkinCamera.new()
var cameras: Array[FunkinCamera] = [camGame,camHUD,camOther]

var active_characters: Array[Character]

@export_category('Groups')
var boyfriendGroup: SpriteGroup = SpriteGroup.new()
var dadGroup: SpriteGroup = SpriteGroup.new()
var gfGroup: SpriteGroup = SpriteGroup.new()

@export_category('Game Over')
const GameOverSubstate = preload("uid://clemxsqclutjh")

func _ready():
	camGame.name = &'camGame'
	boyfriendGroup.name = &'boyfriendGroup'
	dadGroup.name = &'dadGroup'
	gfGroup.name = &'gfGroup'
	
	add_child(camGame)
	camGame.add(gfGroup)
	camGame.add(dadGroup)
	camGame.add(boyfriendGroup)
	
	super._ready()

func loadSongObjects():
	if isPixelStage:
		GameOverSubstate.characterName = 'bf-pixel'
		GameOverSubstate.opponentName = 'bf-pixel'
		GameOverSubstate.deathSoundName = 'gameplay/gameover/fnf_loss_sfx-pixel'
		GameOverSubstate.loopSoundName = 'gameplay/gameover/gameOver-pixel'
		GameOverSubstate.endSoundName = 'gameplay/gameover/gameOverEnd-pixel'
	else:
		GameOverSubstate.characterName = 'bf'
		GameOverSubstate.opponentName = 'bf'
		GameOverSubstate.deathSoundName = 'gameplay/gameover/fnf_loss_sfx'
		GameOverSubstate.loopSoundName = 'gameplay/gameover/gameOver'
		GameOverSubstate.endSoundName = 'gameplay/gameover/gameOverEnd'
	super.loadSongObjects()

func destroy(absolute: bool = true): super.destroy(absolute); camGame.removeFilters()

func gameOver():
	var state = GameOverSubstate.new()
	state.scale = Vector2(camGame.zoom,camGame.zoom)
	state.transform = camGame.scroll_camera.transform
	state.isOpponent = playAsOpponent
	state.character = dad if playAsOpponent else boyfriend
	Global.scene.add_child(state)
	for cams in cameras: cams.visible = false
	super.gameOver()

func loadStage(stage: StringName):
	super.loadStage(stage)
	
	var offset = stageJson.characters.bf.get('cameraOffsets')
	boyfriendCameraOffset = Vector2(offset[0],offset[1]) if offset else Vector2.ZERO
	
	offset = stageJson.characters.gf.get('cameraOffsets')
	girlfriendCameraOffset = Vector2(offset[0],offset[1]) if offset else Vector2.ZERO
	
	offset = stageJson.characters.dad.get('cameraOffsets')
	opponentCameraOffset = Vector2(offset[0],offset[1]) if offset else Vector2.ZERO
	
	defaultCamZoom = stageJson.cameraZoom
	cameraSpeed = stageJson.cameraSpeed
	camGame.zoom = defaultCamZoom
	
	boyfriendGroup.x = stageJson.characters.bf.position[0]
	boyfriendGroup.y = stageJson.characters.bf.position[1]
	dadGroup.x = stageJson.characters.dad.position[0]
	dadGroup.y = stageJson.characters.dad.position[1]
	gfGroup.x = stageJson.characters.gf.position[0]
	gfGroup.y = stageJson.characters.gf.position[1]
	
	if stageJson.get('hide_girlfriend'): gfGroup.visible = false
	else: gfGroup.visible = true
	
	
	if stageJson.get('hide_boyfriend'): boyfriendGroup.visible = false
	else:  boyfriendGroup.visible = true
	moveCamera(detectSection())

func loadStageSprites():
	var gfIndex: int = -1
	var dadIndex: int = -1
	var bfIndex: int = -1
	var chars = stageJson.get('characters')
	
	if chars:
		if chars.gf.has('zIndex'): gfIndex = chars.gf.zIndex
		else: camGame.move_to_order(gfGroup,0)
		
		if chars.dad.has('zIndex'): dadIndex = chars.dad.zIndex
		else: camGame.move_to_order(dadGroup,1)
		
		if chars.bf.has('zIndex'): bfIndex = chars.bf.zIndex
		else: camGame.move_to_order(boyfriendGroup,2)

	super.loadStageSprites()
	if gfIndex != -1: camGame.move_to_order(gfGroup,gfIndex)
	if dadIndex != -1: camGame.move_to_order(dadGroup,dadIndex)
	if bfIndex != -1: camGame.move_to_order(boyfriendGroup,bfIndex)

func _check_stage_sprites_beat():
	for i in stageDanceSprites:
		var danceEvery = i[0]
		var sprite = i[1]
		var has_dance_anim = i[2]
		if !fmod(Conductor.beat,danceEvery): 
			if has_dance_anim: 
				var danced = sprite.get_meta('danced',false)
				sprite.animation.play('danceLeft' if danced else 'danceRight',false)
				sprite.set_meta('danced',!danced)
			else: sprite.animation.play('idle',false)

func _process(delta: float) -> void:
	if camZooming: camGame.zoom = lerpf(camGame.zoom,camGame.defaultZoom,delta*3*zoomSpeed)
	super._process(delta)
	if camFollowPosition:
		var speed =cameraSpeed*delta*3.5
		var scroll = camFollow - ScreenUtils.screenCenter
		if speed >= 1.0: camGame.scroll = scroll
		else: camGame.scroll = camGame.scroll.lerp(scroll,speed)

func onBeatHit() -> void:
	for character in active_characters:
		if !character or character.specialAnim or character.holdTimer > 0 or character.heyTimer > 0: continue
		if fmod(Conductor.beat,character.danceEveryNumBeats) == 0.0: character.dance()
	_check_stage_sprites_beat()
	super.onBeatHit()


#region Character Methods
func changeCharacter(type: Character.Type = Character.Type.BF, character: StringName = 'bf') -> Object:
	var char_name: StringName = get_character_type_name(type)
	var character_obj = get(char_name)
	
	if character_obj and character_obj.curCharacter == character: return
	
	var group: SpriteGroup = get(char_name+'Group')
	if !group: return
	
	var newCharacter = addCharacterToList(character,type)
	if !newCharacter: return
	
	
	newCharacter.name = char_name
	newCharacter.holdTimer = 0.0
	newCharacter.visible = true
	newCharacter.process_mode = Node.PROCESS_MODE_INHERIT
	set(char_name,newCharacter)
	
	if character_obj:
		active_characters.erase(character_obj)
		var char_anim = character_obj.animation
		var new_char_anim = newCharacter.animation
		if new_char_anim.has_animation(char_anim.current_animation): 
			new_char_anim.play(char_anim.current_animation)
			new_char_anim.curAnim.curFrame = char_anim.curAnim.curFrame
		else: newCharacter.dance()
		
		newCharacter.material = character_obj.material
		character_obj.material = null
		
		character_obj.visible = false
		character_obj.process_mode = PROCESS_MODE_DISABLED
	else: newCharacter.dance()

	active_characters.append(newCharacter)
	match type:
		0:
			iconP1.reloadIconFromCharacterJson(newCharacter.json)
			healthBar.set_colors(null,newCharacter.healthBarColors)
		1:
			healthBar.set_colors(newCharacter.healthBarColors)
			iconP2.reloadIconFromCharacterJson(newCharacter.json)
	
	updateIconsImage(_healthBar_State)
	FunkinGD.callOnScripts(&'onChangeCharacter',[type,newCharacter,character_obj])
	updateIconsPivot()
	if !isCameraOnForcedPos and detectSection() == char_name: moveCamera(char_name)
	return newCharacter

func insertCharacterInGroup(character: Character,group: SpriteGroup) -> void:
	if !character or !group: return
	character.set(&"position", Vector2(group.x,group.y) + character.positionArray)
	group.add(character,true)

func addCharacterToList(charFile: String, type: Character.Type = Character.Type.BF) -> Character:
	var group
	var charType: StringName = &'boyfriend'
	match type:
		1: group = dadGroup; charType = &'dad'
		2: group = gfGroup; charType = &'gf'
		_: group = boyfriendGroup
		
	if !Paths.file_exists('characters/'+charFile+'.json'): charFile = 'bf'
	
	#Check if the character is already created.
	for chars in group.members: if chars and chars.curCharacter == charFile: return chars
	
	var newCharacter: Character = Character.create_from_json(charFile,type)
	newCharacter.position += newCharacter.positionArray
	newCharacter.name = charType
	
	if group: group.add(newCharacter,false)
	
	Paths.image(newCharacter.healthIcon)
	FunkinGD.callOnScripts(&'onLoadCharacter',[newCharacter,type])
	insertCharacterInGroup(newCharacter,group)
	newCharacter.visible = false
	newCharacter.process_mode = Node.PROCESS_MODE_DISABLED
	return newCharacter


func signCharacter(character: Character, anim_name: StringName) -> void:
	character.holdTimer = 0.0
	character.heyTimer = 0.0
	character.specialAnim = false
	character.animation.play(anim_name,true)

func signCharacterFromNote(note: Note):
	var character = getCharacterNote(note)
	if !character or character.stunned: return
	var mustPress: bool = note.mustPress
	var target = boyfriend if mustPress else dad
	var gfNote = note.gfNote or (gfSection and mustPress == mustHitSection)
	var character_auto_dance: bool = not (mustPress != playAsOpponent and not botplay)
	
	if gfNote:
		if target: target.autoDance = true
		if gf: gf.autoDance = character_auto_dance
	else:
		if target: target.autoDance = character_auto_dance
		if gf: gf.autoDance = character_auto_dance
	
	var animNote = singAnimations[note.noteData]
	var realAnim = animNote
	var anim_player = character.animation
	var suffix = note.animSuffix
	if altSection and !suffix.ends_with('-alt'): suffix += '-alt'
	if suffix: realAnim += suffix; if !anim_player.has_animation(realAnim): realAnim = animNote
	signCharacter(character,realAnim)

func signMissCharacterFromNote(note: Note) -> void:
	var character = getCharacterNote(note)
	if !character or character.stunned: return
	
	var animNote = singAnimations[note.noteData]+'-miss'
	var realAnim = animNote
	var anim_player = character.animation
	var suffix = note.animSuffix
	if altSection and !suffix.ends_with('-alt'): suffix += '-alt'
	if suffix: realAnim += suffix; if !anim_player.has_animation(realAnim): realAnim = animNote
	signCharacter(character, realAnim)

func getCharacterNote(note: Note) -> Character: 
	if note.hitCharacter: return note.hitCharacter
	return gf if note.gfNote else (boyfriend if note.mustPress else dad)
#endregion



func clear():
	super.clear()
	camGame.removeFilters()
	
	boyfriendGroup.queue_free_members()
	boyfriend = null
	dadGroup.queue_free_members()
	dad = null
	gfGroup.queue_free_members()
	gf = null


#region Camera Methods
func set_default_zoom(value: float) -> void: super.set_default_zoom(value); camGame.defaultZoom = value;

func moveCamera(target: StringName = 'boyfriend') -> void:
	camFollow = get_focus_position(get(target))
	super.moveCamera(target)

func screenBeat(multi: float = 1.0) -> void:
	camGame.zoom += 0.015 * multi
	super.screenBeat(multi)

func get_focus_position(obj: Node) -> Vector2:
	if !obj: return Vector2.ZERO
	if obj is Character: 
		match obj.charType:
			Character.Type.BF: return obj.getCameraPosition() + boyfriendCameraOffset
			Character.Type.OPPONENT: return obj.getCameraPosition() + opponentCameraOffset
			Character.Type.GF: return obj.getCameraPosition() + girlfriendCameraOffset
		return obj.getCameraPosition()
	elif obj is FunkinSprite: return obj.getMidpoint()
	return obj.position
#endregion
