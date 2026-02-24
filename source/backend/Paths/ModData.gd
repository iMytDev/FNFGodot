class_name ModData extends Resource

@export var name: String
@export var enabled: bool = true:
	set(val): enabled = val; changed.emit()
@export var needs_restart: bool
@export var description: String
@export var runsGlobally: bool
