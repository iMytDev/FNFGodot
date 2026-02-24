@tool
extends Node

@export var songData: SongData:
	set(val):
		songData = val
		val._editor_mode = SongData.EditorMode.EVENTS
