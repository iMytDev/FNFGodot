const NoteHit = preload("uid://dx85xmyb5icvh")
##Load Notes from the Song.[br][br]
##[b]Note:[/b] This function have to be call [u]when [member SONG] and [member keyCount] is already setted.[/u]
static func getNotesFromData(songData: Dictionary = {}) -> Array[Note]:
	var _notes: Array[Note]
	var notesData = songData.get('notes')
	if !notesData: return _notes
	
	var _bpm: int = songData.get('bpm',0.0)
	var keyCount: int = songData.get('keyCount',4)
	
	var stepCrochet: float = BPMData.get_step_crochet(_bpm)
	var types_founded: PackedStringArray
	
	var i: int = 0
	var length = notesData.size()
	
	while i < length:
		var section = notesData[i]
		if section.changeBPM and section.bpm != _bpm:
			_bpm = section.bpm; stepCrochet = BPMData.get_step_crochet(_bpm)
		
		var note_index: int = 0
		var notes_length = section.sectionNotes.size()
		while note_index < notes_length:
			var note_data = section.sectionNotes[note_index]
			note_index += 1
			
			var note: NoteHit = createNoteFromData(note_data, section, keyCount)
			if !_insert_note_to_array(note,_notes): continue
			
			note.stepCrochet = stepCrochet
			if note.noteType: types_founded.append(note.noteType)
			
			var susLength = note_data.get('l',0.0)
			if susLength < stepCrochet: continue 
			_create_note_sustains(note,susLength)
			
		i += 1
	
	var type_unique: PackedStringArray
	for t in types_founded: if not t in type_unique: type_unique.append(t)
	songData.noteTypes = type_unique
	return _notes

static func _insert_note_to_array(note: Note, array: Array, check_duplicated_note: bool = true) -> bool:
	var index = array.size()
	while index:
		index -= 1
		var prev_note: Note = array[index]
		if prev_note.strumTime >= note.strumTime: continue; 
		if prev_note.strumTime < note.strumTime: array.insert(index + 1, note); return true
		
		#Remove duplicated note
		if !check_duplicated_note or !Note.same_note(note,prev_note): continue
		
		if note.sustainLength < prev_note.sustainLength: return false
		array.remove_at(index)
		_remove_sustains_from_note(prev_note.sustainParents,array)
		array.insert(index + 1,note);
	
	array.push_front(note)
	return true

static func _remove_sustains_from_note(sustains: Array[NoteSustain], array: Array) -> void:
	for i in sustains:
		var length = array.size(); 
		while length: length -= 1; if array[length] == i: array.remove_at(length); break

static func _create_note_sustains(note: NoteHit, length: float) -> void:
	note.sustainLength = length
	note.sustain = createSustainFromNote(note,false)
	note.sustain.end_sustain = createSustainFromNote(note,true)

static func createNoteFromData(data: Dictionary, sectionData: Dictionary, keyCount: int = 4) -> NoteHit:
	var noteData = int(data.d)
	var note = NoteHit.new(noteData%keyCount)
	var mustHitSection = sectionData.mustHitSection
	var gfSection = sectionData.gfSection
	var type = data.get('k','')
	var gfNote = data.get("g")
	if !gfNote: gfNote = gfSection and note.mustPress == mustHitSection
	
	note.strumTime = data.t
	
	note.mustPress = mustHitSection if noteData < keyCount else !mustHitSection
	if type and type is String: 
		note.noteType = type
		if !gfNote: gfNote = type == 'GF Sing'
	
	note.gfNote = gfNote
	return note
	
static func createSustainFromNote(note: Note, isEnd: bool = false) -> NoteSustain:
	var sus: NoteSustain = NoteSustain.new(note.noteData, isEnd)
	sus.splashStyle = &''
	sus.noteParent = note
	sus.hitHealth /= 2.0
	
	sus.strumTime = note.strumTime
	sus.noteType = note.noteType
	sus.gfNote = note.gfNote
	sus.mustPress = note.mustPress
	sus.noAnimation = note.noAnimation
	sus.isPixelNote = note.isPixelNote
	
	if !isEnd: 
		sus.sustainLength = note.sustainLength
	else: 
		sus.strumTime += note.sustainLength 
		sus.sustainLength = note.stepCrochet
	return sus
