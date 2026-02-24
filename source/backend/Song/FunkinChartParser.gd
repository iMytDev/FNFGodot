class_name FunkinChartParser extends Object
static func load_data(absolute_path: String) -> Dictionary:
	if !absolute_path: return {}
	var data = Paths.load_json_absolute(absolute_path); if !data: return data
	
	if data.get('song') is Dictionary: data = data.song
	
	#Check if the chart is from the original fnf
	#if data.get('notes') is Dictionary:
		#var meta_data_path = absolute_path.replace('-chart','-metadata')
		#var meta_data = Paths.loadJson(meta_data_path)
		#data = _convert_new_to_old(data,meta_data,difficulty)
	#else:
	fixChart(data)
	sort_song_notes(data.notes)
	_set_section_times(data)
	if data.notes: _convert_notes_to_new(data.notes)
	return data

static func _set_section_times(json: Dictionary):
	var section_time: float = 0.0
	var cur_bpm: float = json.bpm
	var beat_crochet: float = BPMData.get_crochet(cur_bpm)
	for i in json.notes:
		if !i: break
		if i.changeBPM:
			cur_bpm = i.get('bpm',json.bpm)
			beat_crochet = BPMData.get_crochet(cur_bpm)
		i.sectionTime = section_time
		i.bpm = cur_bpm
		section_time += beat_crochet * i.sectionBeats


static func fixChart(json: Dictionary):
	json.merge(getChartBase(),false)
	for section: Dictionary in json.notes: section.merge(getSectionBase(),false)
	return json

static func _convert_new_to_old(chart: Dictionary, metaData: Dictionary = {}, difficulty: String = '') -> Dictionary:
	var newJson = getChartBase()
	var json_bpm = 0.0
	var bpms = []
	
	if metaData.has('timeChanges'):
		for changes in metaData.timeChanges:
			bpms.append([changes.get('t',0),changes.get('bpm',0)])
		json_bpm = bpms[0][1]
	
	var bpms_size = bpms.size()
	
	var bpmIndex: int = 0
	var subSections: int = 0
	var sectionStep: float = Conductor.get_section_crochet(json_bpm)
	
	var curSectionTime: float = 0
	
	var characters: Dictionary = {
		'player': 'bf',
		'girlfriend': 'bf',
		'opponent': 'bf'
	}
	
	var playData = metaData.get('playData',{})
	if playData.has('characters'): characters.merge(playData.get('characters',{}),true)
	newJson.stage = playData.get('stage','mainStage')
	
	newJson.player1 = characters.player
	newJson.gfVersion = characters.girlfriend
	newJson.player2 = characters.opponent
	newJson.songSuffix = characters.get('instrumental','')
	
	var vocal = characters.get('playerVocals')
	if vocal: newJson.playerVocals = vocal[0]
	
	vocal = characters.get('opponentVocals')
	if vocal: newJson.opponentVocals = vocal[0]
	
	newJson.opponentVoice = characters.get('opponentVocals',newJson.player1)
	newJson.speed = chart.get('scrollSpeed',{}).get(difficulty.to_lower(),2.0)
	
	newJson.song = metaData.get('songName','')
	newJson.bpm = json_bpm
	
	newJson.notes = []
	for notes in chart.notes.get(difficulty.to_lower(),[]):
		var strumTime = notes.get('t',0)
		var section = int(strumTime / sectionStep) - subSections
		
		#Detect Bpm Changes
		if bpmIndex < bpms_size and bpms[bpmIndex][0] <= strumTime:
			json_bpm = bpms[bpmIndex][1]
			sectionStep = Conductor.get_section_crochet(json_bpm)
			var newSection = strumTime / sectionStep - subSections
			subSections -= newSection - section
			section = newSection - subSections
			bpmIndex += 1
	
		while newJson.notes.size() <= section: #Create Sections
			var new_section = getSectionBase()
			new_section.mustHitSection = true
			new_section.sectionTime = curSectionTime
			
			curSectionTime += sectionStep
			newJson.notes.append(new_section)
		
		newJson.notes[section].sectionNotes.append(notes)
	
	if chart.get(&'events'): newJson.events = EventNote.loadEventsFromChart(chart.events)
	return newJson


static func _convert_notes_to_new(notes_data: Array):
	var index: int = 0
	var note_size = notes_data.size()
	while index < note_size:
		var section_data = notes_data[index].get('sectionNotes')
		index += 1
		if !section_data is Array: continue
		
		var new_notes: Array
		var size = section_data.size()
		var note_index: int = 0
		while note_index < size:
			var data = section_data[note_index]
			var data_size = data.size()
			var new_data: Dictionary = {&'t': data[0],&'d': data[1]}
			if data_size >= 3: new_data.l = float(data[2]) #Note Length
			if data_size >= 4: new_data.k = data[3] #Note Type
			new_notes.append(new_data)
			note_index += 1
		
		section_data.clear()
		section_data.assign(new_notes)

static func sort_song_notes(song_notes: Array) -> void:
	for i in song_notes: if i.sectionNotes: i.sectionNotes.sort_custom(ArrayUtils.sort_array_from_first_index)

static func getSectionBase() -> Dictionary:
	return {
		&'sectionNotes': [],
		&'mustHitSection': false,
		&'gfSection': false,
		&'sectionBeats': 4,
		&'sectionTime': 0,
		&'changeBPM': false,
		&'bpm': 0
	}

static func getChartBase() -> Dictionary: ##Returns a base [Dictionary] of the Song.
	return {
		'notes': [],
		'events': [],
		'bpm': 0.0,
		'song': '',
		'songSuffix': '',
		'player1': 'bf',
		'player2': 'dad',
		'gfVersion': 'gf',
		'speed': 1,
		'stage': 'stage',
		'arrowSkin': '',
		'splashSkin': '',
		'disableNoteRGB': false,
		'needsVoices': true,
		'keyCount': 4,
	}
