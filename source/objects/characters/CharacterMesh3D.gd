@tool
class_name CharacterMesh3D extends CharacterBase3D
const NoteHit = preload("uid://dx85xmyb5icvh")

var _editor_marker_camera: Marker3D
@export var animation: AnimationPlayer = AnimationPlayer.new();
@export var cameraPosition: CharacterCameraPosition3D = CharacterCameraPosition3D.new()

func _ready() -> void:
	if Engine.is_editor_hint(): 
		cameraPosition.changed.connect(_update_marker_editor)
		_editor_marker_camera = Marker3D.new()
		_editor_marker_camera.top_level = true
		_editor_marker_camera.gizmo_extents = 50
		add_child(_editor_marker_camera)
		_update_marker_editor()
		return
	
	data.hasDanceAnim = animation.has_animation(&"danceLeft") or animation.has_animation(&"danceRight")
	animation.animation_started.connect(_on_animation_started)
	animation.animation_finished.connect(_on_animation_finished)

func _update_marker_editor():
	_editor_marker_camera.position = position + cameraPosition.position
	_editor_marker_camera.rotation = cameraPosition.rotation


#region Dance Methods
func dance() -> void: ##Make character returns to his dance animation.
	if not data.hasDanceAnim: animation.play(_idle_anim,forceDance)
	else: animation.play(&'danceRight' if danced else &'danceLeft',forceDance); danced = !danced
	super()
#endregion

func getCameraPosition() -> Vector3: return position + cameraPosition.position
func getCameraRotation() -> Vector3: return cameraPosition.rotation

func _on_animation_started(anim: StringName) -> void: super(anim); animation.seek(0)

func _on_animation_finished(_anim: StringName): if specialAnim or data.danceOnAnimEnd and _anim.begins_with('sing'): dance();
