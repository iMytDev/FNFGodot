extends Note
const NoteSustain = preload("uid://bhagylovx7ods")

const _rating_string: Array = [&'sick',&'good',&'bad',&'shit']
const _ratings_length: int = 4
const _rating_offset: PackedFloat32Array = [45.0,130.0,150.0,200]

var sustain: NoteSustain
var sustainEnd: NoteSustain

func updateRating() -> void:
	ratingMod = 0
	var dist = absf(distance)
	while ratingMod < _ratings_length and dist >= _rating_offset[ratingMod]: ratingMod += 1
	rating = _rating_string[ratingMod]

func follow_strum(strum: StrumNote = strumNote) -> void:
	super(strum)
	if copyAngle: rotation = strum.rotation + noteAngle
	if copyScale: scale = (strumNote.scale * multScale * noteScale)
