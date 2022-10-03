extends Camera

export(bool) var enabled = false;
export(float, 0.1, 1.0) var mouse_sensitivity = 0.1
export(float, 1.0, 100.0) var movement_speed = 15
export(Dictionary) var input_mappings = {
	"forward" : "move_forward",
	"backward" : "move_back",
	"left" : "move_left",
	"right" : "move_right",
	"up" : "move_up",
	"down" : "move_down"
	}

onready var parent = get_parent() 

func _physics_process(delta):
	if(enabled):
		if(Input.is_action_pressed(input_mappings["up"])):
			parent.translate(Vector3(0, movement_speed * delta, 0))

		if(Input.is_action_pressed(input_mappings["down"])):
			parent.translate(Vector3(0, -movement_speed * delta, 0))

		if(Input.is_action_pressed(input_mappings["right"])):
			parent.translate(Vector3(movement_speed * delta, 0, 0))

		if(Input.is_action_pressed(input_mappings["left"])):
			parent.translate(Vector3(-movement_speed * delta, 0, 0))

		if(Input.is_action_pressed(input_mappings["forward"])):
			parent.translate(Vector3(0, 0, -movement_speed * delta))

		if(Input.is_action_pressed(input_mappings["backward"])):
			parent.translate(Vector3(0, 0, movement_speed * delta))
	
	
func _input(event):
	if(enabled):
		if (event is InputEventMouseMotion):
			var mouse_motion = event.relative
			parent.rotate_object_local(Vector3(0, 1, 0), -deg2rad(mouse_motion.x) * mouse_sensitivity)
			rotate_object_local(Vector3(1, 0, 0), -deg2rad(mouse_motion.y) * mouse_sensitivity)
