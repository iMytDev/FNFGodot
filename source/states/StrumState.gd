@tool
@icon("res://icons/StrumState.svg")
class_name StrumState extends Node

@export_category('Notes')
const NOTE_SPAWN_TIME: float = 1000
const StrumOffset: float = 112.0
const NoteSplash = preload("uid://cct1klvoc2ebg")
const SplashPool = preload("uid://dcbm0oeieae0v")

const NoteParser = preload("uid://h8nnpmoaoq70")

static var isModding: bool = true

static var week_data: Dictionary

var inModchartEditor: bool
@export_group("Song Data")
@export var SONG: SongData = SongData.new()
@export var autoStartSong: bool = true ##Start the Song when the Song json is loaded. Used in PlayState

##If this is [code]false[/code], will disable the notes, 
##making them stretched and not being created
var generateMusic: bool = !Engine.is_editor_hint()
var exitingSong: bool
var clear_song_after_exiting: bool = true

var songSpeed: float: set = set_song_speed 
var _is_song_start: bool

var keyCount: int = 4: ##The amount of notes that will be used, default is [b]4[/b].
	set(value): 
		if value == keyCount: return
		keyCount = value; _rebuild_keys()

var _songPos: float

@export_group("Notes")
var defaultStrumPos: PackedVector2Array
var defaultStrumAlpha: PackedFloat32Array

var strumLineNotes: SpriteGroup = SpriteGroup.new()#Strum's Group.

var opponentStrums: SpriteGroup = SpriteGroup.new() ##Strum's Oponnent Group.
var playerStrums: SpriteGroup = SpriteGroup.new() ##Strum's Player Group.
var extraStrums: Array[StrumNote]

##Returns the player strum. 
##If [member playAsOpponent] = true, returns [member opponentStrums], else, returns [member playerStrums]
var current_player_strum: Array = playerStrums.members

var uiGroup: SpriteGroup = SpriteGroup.new() ##Hud Group.

var unspawnNotes: Array[Note] ##Unspawn notes.
var _unspawn_length: int
var _unspawn_index: int
var _respawn_index: int
var respawnNotes: bool
var notes: SpriteGroup = SpriteGroup.new()
var noteSpawnTime: float = NOTE_SPAWN_TIME

var _notes_to_hit: Array[Note]

var canHitNotes: bool = true

var splashesEnabled: bool = true
var opponentSplashes: bool
var grpNoteSplashes: SpriteGroup = SpriteGroup.new() ##Note Splashes Group.
var grpNoteHoldSplashes: Dictionary[int,NoteSplash] ##Note Hold Splashes Group.

static var isPixelStage: bool
var arrowStyle: StringName = SongData.DEFAULT_ARROW_STYLE
var splashStyle: StringName = SongData.DEFAULT_SPLASH_STYLE
var splashHoldStyle: StringName = SongData.DEFAULT_SPLASH_HOLD_STYLE

@export_group("Play Options")
##Play as Opponent, reversing the sides.
@export var playAsOpponent: bool = ClientPrefs.data.playAsOpponent: set = _set_play_opponent


@export var botplay: bool = ClientPrefs.data.botplay: set = _set_botplay ##When activate, the notes will be hitted automatically.

var downScroll: bool: set = _set_downscroll
var middleScroll: bool: set = _set_middlescroll

var stateLoaded: bool
var touch_state #Android System

var Inst: AudioStreamPlayer:
	get(): return ArrayUtils.get_array_index(Conductor.songs,0)

var vocals: AudioStreamPlayer:
	get(): return ArrayUtils.get_array_index(Conductor.songs,1)

#region Native Methods
func _process(_d) -> void: 
	if generateMusic:_songPos = Conductor.songPositionDelayed; _process_notes()

func _init(data: SongData = null):
	if data: SONG = data
	
	splashesEnabled = ClientPrefs.data.splashesEnabled
	opponentSplashes = splashesEnabled and ClientPrefs.data.opponentSplashes
	downScroll = ClientPrefs.data.downscroll
	middleScroll = ClientPrefs.data.middlescroll
	
	add_child(uiGroup)
	uiGroup.name = &'uiGroup'
	_add_note_groups()

func _ready() -> void:
	if Engine.is_editor_hint(): return;
	PathsStore.curMod = SONG.mod; 
	_load_song()
	_rebuild_keys()
	_load_song_objects()
	if autoStartSong: startSong()
	stateLoaded = true

func _add_note_groups():
	grpNoteSplashes.name = &'grpNoteSplashes'
	
	opponentStrums.name = &'opponentStrums'
	playerStrums.name = &'playerStrums'
	strumLineNotes.name = &'strumLineNotes'
	
	notes.name = &'notes'
	uiGroup.append(strumLineNotes)
	uiGroup.append(playerStrums)
	uiGroup.append(opponentStrums)
	uiGroup.append(notes)
	uiGroup.append(grpNoteSplashes)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if botplay or !event.pressed or event.echo: return
		_check_hit_notes(event.keycode)

func clear() -> void: 
	clear_song_notes()
	Conductor.clearSong(exitingSong)
	grpNoteSplashes.members.clear()
	grpNoteHoldSplashes.clear()
	unspawnNotes.clear()
	NoteStyleData.styles_loaded.clear()
	inModchartEditor = false
	isPixelStage = false
#endregion

#region Ui Methods
func _setup_hud() -> void:
	arrowStyle = SONG.getArrowStyle(isPixelStage)
	splashStyle = SONG.getSplashStyle()
	splashHoldStyle = SONG.getSplashHoldStyle()
	_create_strums()
	
	if !Engine.is_editor_hint() and Paths.is_on_mobile: createMobileGUI()

func createMobileGUI() -> void: ##HitBox
	touch_state = load("uid://caqru406gega1").new()
	add_child(touch_state)
	touch_state.z_index = 1
#endregion

#region Song Methods
func _load_song():
	if !SONG.data: SONG.load_data();
	Conductor.loadSongFromData(SONG)
	
	keyCount = SONG.keyCount
	FunkinGD.keyCount = keyCount
	
	songSpeed = SONG.data.get("speed",2.0)
	Conductor.loadSongsStreamsFromData(SONG)

func _load_song_objects(): ##Load song data. Used in PlayState
	_setup_hud()
	_respawn_index = 0
	_unspawn_index = 0
	if !SONG: return
	load_notes()


func startSong() -> void: ##Begins the song. See also [method loadSong].
	if !Conductor.songs: return
	Conductor.resumeSongs()
	_is_song_start = true
	FunkinGD.songLength = Conductor.songLength

##Seek the Song Position to [param time] in miliseconds.[br]
##If [param kill_notes] is [code]true[/code], the notes above the [param time] will be removed.
func seek_to(time: float, kill_notes: bool = true):
	Conductor.seek(time)
	if !kill_notes: return
	
	var time_offset: float = time + 1000
	for i in notes: if i.strumTime < time_offset: i.kill()
	
	while _unspawn_index < _unspawn_length:
		if unspawnNotes[_unspawn_index].strumTime > time_offset: break
		_unspawn_index += 1
#endregion

#region Strums
func _update_strums_position(): 
	defaultStrumPos = getDefaultStrumPos(); defaultStrumAlpha = getDefaultStrumAlpha()

func getDefaultStrumAlpha(middlescroll: bool = middleScroll) -> PackedFloat32Array:
	var value = PackedFloat32Array()
	var length = keyCount * 2
	if middlescroll:
		var i = 0
		while i < length:
			if i >= keyCount: value.append(0.3 if playAsOpponent else 1.0)
			else: value.append(1.0 if playAsOpponent else 3.0)
			i += 1
	else:
		value.resize(length)
		value.fill(1.0)
	return value

func getDefaultStrumPos(middlescroll: bool = middleScroll, downscroll: bool = downScroll) -> PackedVector2Array:
	var positions: PackedVector2Array
	positions.resize(keyCount*2)
	positions.fill(Vector2(0.0,getDefaultStrumY(downscroll)))
	
	var strum_off = StrumOffset
	var key_length = keyCount * 2
	var strums_full_width = StrumOffset * (key_length)
	strum_off *= minf(
		ScreenUtils.screenWidth / strums_full_width,
		1.0
	)
	var space_between_strums: float = clampf(
		ScreenUtils.screenWidth / strum_off - (key_length + 0.5),
		0.0,
		2.0
	)
	
	var i: int = 0
	while i < keyCount: #Opponent Position
		var strumPos: float = getDefaultStrumX(i,strum_off,space_between_strums,middleScroll,playAsOpponent)
		if middlescroll and !playAsOpponent: defaultStrumAlpha[i] = 0.35
		positions[i].x = strumPos
		i += 1
	
	i = 0
	while i < keyCount: #Player Position
		var strumIndex: int = i+keyCount
		if middleScroll and playAsOpponent:defaultStrumAlpha[strumIndex] = 0.35
		positions[strumIndex].x = getDefaultStrumX(i,strum_off,space_between_strums,middleScroll,!playAsOpponent)
		i += 1
	return positions

func getDefaultStrumX(
	data: int, 
	offset: float = StrumOffset, 
	space_between_notes: float = 3.0, middle: bool = middleScroll, must_press: bool = false
):
	var first_pos: float
	if middle: 
		if must_press: first_pos = -offset * keyCount * 0.5
		else:
			if data < keyCount*0.5: first_pos = -offset * (keyCount * 2 + space_between_notes*0.5)
			else: first_pos = offset * (keyCount * 2 + space_between_notes*0.5)
	else:
		if must_press: first_pos = offset * (space_between_notes * 0.5)
		else: first_pos = -offset * (keyCount + space_between_notes * 0.5)
	
	return ScreenUtils.screenCenter.x + first_pos + offset * data 
func getDefaultStrumY(downscroll: bool = downScroll): return (ScreenUtils.screenHeight - 50.0) if downscroll else 50.0

func _create_strums() -> void:
	StrumNote.keyCount = keyCount
	strumLineNotes.queue_free_members()
	strumLineNotes.members.clear()
	playerStrums.members.clear()
	opponentStrums.members.clear()
	
	_update_strums_position()
	var i: int = keyCount
	i = keyCount*2
	while i > keyCount: #Player Strums
		i -= 1
		var strum = createStrum(i)
		strum.mustPress = !botplay
		playerStrums.insert(0,strum)
		strumLineNotes.insert(0,strum)
		strum.position = defaultStrumPos[i]
		strum.mustPress = !playAsOpponent and !botplay
		strum.modulate.a = defaultStrumAlpha[i]
	while i: #Opponent Strums
		i -= 1
		var strum = createStrum(i)
		opponentStrums.insert(0,strum)
		strumLineNotes.insert(0,strum)
		strum.position = defaultStrumPos[i]
		strum.mustPress = playAsOpponent and !botplay
		strum.modulate.a = defaultStrumAlpha[i]

func createStrum(i: int) -> StrumNote:
	var strum = StrumNote.new(i)
	strum.loadFromStyle(arrowStyle)
	strum.downscroll = downScroll
	strum.name = &"StrumNote"
	strum.isPixelNote = isPixelStage
	return strum

func _update_strum_must_press() -> void:
	var strums = strumLineNotes.members
	if !strums: return
	
	var index: int = strums.size()
	while index:
		index -= 1
		if botplay: strums[index].mustPress = false; continue
		if index < keyCount: strums[index].mustPress = playAsOpponent
		else: strums[index].mustPress = !playAsOpponent

func _strum_confirm_from_note(note: Note) -> void:
	var strum: StrumNote = note.strumNote; if !strum: return
	if !strum.mustPress and (!note.isSustainNote or note.isEndSustain): strum.strumConfirm(note.hitStrumAnim); return
	strum.hitTime = 0.0; strum.animation.play(note.hitStrumAnim,true); strum.return_to_static_on_finish = false
#endregion



#region Note Methods
func load_notes() -> void:
	if !unspawnNotes:  unspawnNotes = NoteParser.getNotesFromData(SONG.data)
	_unspawn_length = unspawnNotes.size()
	reloadNotes()

func clear_song_notes():
	for i in unspawnNotes: if i: i.queue_free()
	_respawn_index = 0; _unspawn_index = 0
	unspawnNotes.clear()

func _rebuild_keys():
	var length = keyCount*2
	_notes_to_hit.resize(keyCount)
	defaultStrumPos.resize(length)
	defaultStrumAlpha.resize(length)
	
func _process_notes():
	_check_unspawn_notes()
	_check_respawn_notes()
	if !notes.members: return
	var members = notes.members
	var note_index: int = members.size()
	if respawnNotes:
		while note_index:
			note_index -= 1
			var note = members[note_index]
			if note.strumTime - _songPos > noteSpawnTime: note.kill(); _unspawn_index -= 1
			elif !updateNote(note): continue
			notes.remove_at(note_index)
	else: 
		while note_index: 
			note_index -= 1; 
			if !updateNote(members[note_index]): notes.remove_at(note_index)

func updateNote(n: Note) -> bool:
	if !n or !n.is_inside_tree(): return false
	
	var isSus: bool = n.isSustainNote
	var opponentNote: bool = n.autoHit or botplay or !isPlayerNote(n)
	n.noteSpeed = songSpeed
	n.updateNote()
	
	var noteMissed = _is_note_missed(n)
	if noteMissed and !n.missed and !opponentNote and !n.ignoreNote: noteMiss(n,!isSus); return true
	
	if noteMissed or isSus and n._sustain_filled: n.kill(); return false
	
	if !n.canBeHit or !canHitNotes or n.missed: return true
	
	if opponentNote:
		if not n.ignoreNote and (isSus or n.distance <= 0.0): preHitNote(n)
		return true
	
	if isSus:
		var hit_action = n.noteParent.hit_actions
		if InputUtils.is_any_key_pressed(hit_action): preHitNote(n);
		elif n.wasHit: _remove_hold_splash_from_strum(n.strumNote);
		return true
	
	var l = _notes_to_hit[n.noteData]
	if !l or absf(n.distance) < absf(l.distance): _notes_to_hit[n.noteData] = n
	return true

func _check_unspawn_notes() -> void:
	while _unspawn_index < _unspawn_length:
		var unspawn: Note = unspawnNotes[_unspawn_index]
		if unspawn and unspawn.strumTime - _songPos > noteSpawnTime: break
		_unspawn_index += 1
		spawnNote(unspawn)

func _check_respawn_notes() -> void:
	if !respawnNotes: return
	while _respawn_index < _unspawn_index:
		var note = unspawnNotes[_respawn_index]
		if !note.wasHit and !note.missed: break
		_respawn_index += 1

func _check_hit_notes(action_pressed: Key) -> void:
	var index: int = keyCount
	while index: 
		index -= 1
		var i: Note = _notes_to_hit[index]
		if !i or !i.canBeHit: _notes_to_hit[index] = null; continue
		if action_pressed in i.hit_actions: 
			preHitNote(i);
			_notes_to_hit[index] = null

##Spawns the note
func spawnNote(note: Note) -> void: 
	addNoteToGroup(note, note.noteGroup, 0 if note.isSustainNote else -1)
	if note.has_sustains(): spawnNote(note.sustain); spawnNote(note.sustain.end_sustain)

func addNoteToGroup(note: Note, group: Node, at: int = -1) -> void:
	if !group: return
	if group != notes: notes.members.append(note)
	if group is SpriteGroup:
		if at != -1: group.insert(at,note)
		else: group.append(note)
		return
	
	group.add_child(note)
	if at != -1: group.move_child(note,at)

func _is_note_missed(n: Note) -> bool:
	return not (n.isSustainNote and n.isBeingDestroyed) and n.distance <= n.missOffset

func preHitNote(note: Note):
	if !note: return
	if !note.isSustainNote: note.updateRating()
	note.wasHit = true
	note.judgementTime = _songPos
	note.hitStrumAnim = &'press' if note.isEndSustain and isPlayerNote(note) else &'confirm'
	hitNote(note)

func hitNote(note: Note) -> void: ##Hit a [NoteBase].
	if !note: return
	var strum: StrumNote = note.strumNote
	if note.isEndSustain: 
		if !isPlayerNote(note): _remove_hold_splash_from_strum(strum)
		else: 
			var s = _remove_hold_splash_from_strum(strum,false); if s: s.animation.play(&'end')
	
	if splashAllowed(note): createSplash(note);
	note._on_hit()
	if note.strumConfirm: _strum_confirm_from_note(note)

func splashAllowed(n: Note) -> bool:
	var en = splashesEnabled and !(n.noteParent.ratingMod if n.isSustainNote and n.noteParent else n.ratingMod)
	if n.isSustainNote: return en and !n.splashDisabled and !n.isBeingDestroyed
	return en and !n.splashDisabled and (isPlayerNote(n) or opponentSplashes)
#endregion

func isPlayerNote(note: Note) -> bool: return note.mustPress != playAsOpponent

func noteMiss(note: Note, kill_note: bool = true) -> void: ##Called when the player miss a [Note]
	if !note:return
	note.miss()
	note.judgementTime = _songPos
	if note.isSustainNote: _remove_hold_splash_from_strum(note.strumNote)
	if kill_note: note.kill()
	
func reloadNotes() -> void: 
	var index: int = unspawnNotes.size()
	while index: index -= 1; reloadNote(unspawnNotes[index]);
	
func reloadNote(note: Note):
	note.loadFromStyle(arrowStyle)
	var noteStrum: StrumNote = strumLineNotes.members.get((note.noteData + keyCount) if note.mustPress else note.noteData)
	note.strumNote = noteStrum
	note.isPixelNote = isPixelStage
	note.noteGroup = notes
	if note.has_sustains(): reloadNote(note.sustain); reloadNote(note.sustain.end_sustain)
	note.resetNote()
	note.splashStyle = splashHoldStyle if note.isSustainNote else splashStyle
#endregion

#region Splash Methods
func createSplash(note) -> NoteSplash: ##Create Splash
	if !note: return
	var strum: StrumNote = note.strumNote; if !strum or !strum.visible: return
	var splash = SplashPool.createSplashFromNote(note)
	if !splash: return
	
	splash.strum = strum
	splash.followStrum()
	if splash.holdSplash: 
		_remove_hold_splash_from_strum(strum); 
		grpNoteHoldSplashes[strum.get_instance_id()] = splash
	
	
	var splashParent = note.splashParent
	if splashParent: 
		if splash.is_inside_tree(): splash.reparent(splashParent,false)
		else: splash.add_child(splashParent); grpNoteSplashes.members.append(splash); 
	else:
		if splash.is_inside_tree(): splash.reparent(grpNoteSplashes,false)
		else: grpNoteSplashes.append(splash); 
	splash.isPixelSplash = isPixelStage
	return 

func _remove_hold_splash_from_strum(strum: StrumNote, hide: bool = true) -> NoteSplash:
	if !strum: return
	var id = strum.get_instance_id()
	var splash = grpNoteHoldSplashes.get(id)
	if !splash: return
	grpNoteHoldSplashes[id] = null
	if hide: splash.visible = false; 
	return splash
#endregion

func destroy(absolute: bool = true): ##Remove the state
	SplashPool.splashes_loaded.clear()
	Paths.clear_local_files()
	if absolute: clear(); queue_free(); return
	
	if isModding: NoteStyleData.styles_loaded.clear()
	for note in notes.members: note.kill()




#region Setters
func _set_botplay(is_botplay: bool) -> void: botplay = is_botplay; _update_strum_must_press()

func set_song_speed(value): songSpeed = value; noteSpawnTime = NOTE_SPAWN_TIME/(value*0.5)

func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void:
	if playAsOpponent == isOpponent: return
	playAsOpponent = isOpponent
	_update_strum_must_press()
	current_player_strum = (opponentStrums if isOpponent else playerStrums).members
	if middleScroll and stateLoaded: _update_strums_position()

func _set_downscroll(value):
	FunkinGD.downscroll = value
	if downScroll == value: return
	downScroll = value
	if stateLoaded: _update_strums_position()

func _set_middlescroll(value):
	FunkinGD.middlescroll = value
	if middleScroll == value: return
	middleScroll = value
	if stateLoaded: _update_strums_position()
#endregion
