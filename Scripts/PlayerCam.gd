extends Camera

onready var player = get_parent()

const CAMERA_TURN_SPEED = 5
const MOUSE_SENSITIVITY = 2

var enable_input = true

func _ready():
	set_process_input(true)

func look_updown_rotation(rotation = 0):
	var toReturn = self.get_rotation() + Vector3(rotation, 0, 0)
	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)

	return toReturn

func look_leftright_rotation(rotation = 0):
	return player.get_rotation() + Vector3(0, rotation, 0)

func _input(event):
	if(!enable_input):
		return
	if (event is InputEventMouseMotion):
		var mouse_delta = -event.relative * MOUSE_SENSITIVITY * 0.001
		var mouse_vector_horz = Vector3(0.0, mouse_delta.x, 0.0)
		var mouse_vector_vert = Vector3(mouse_delta.y, 0.0, 0.0)
		var look_quat_horz = Quat(transform.basis.xform_inv(mouse_vector_horz))
		var look_quat_vert = Quat(mouse_vector_vert)
		transform.basis *= Basis(look_quat_horz) * Basis(look_quat_vert)
