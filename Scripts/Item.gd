extends RigidBody

class_name Item

const TYPE = "Item"
const THROW_TORQUE_MULT = 0.8
const USAGE_HINT = "Left Mouse: Throw\nE: Put down"

onready var collision_layer_original = get_collision_layer()
onready var collision_mask_original = get_collision_mask()

var interact_string = "E: Pick up"
var is_impulse_requested = false
var impulse_request:Vector3

func _physics_process(_delta):
	if(is_impulse_requested):
		mode = RigidBody.MODE_RIGID
		apply_central_impulse(impulse_request)
		apply_torque_impulse(Vector3(randf() * THROW_TORQUE_MULT, randf() * THROW_TORQUE_MULT, randf() * THROW_TORQUE_MULT))
		is_impulse_requested = false

func get_interact_string() -> String:
	return interact_string

func pick_up():
	disable_collision()
	$"InteractHint".visible = false

func put_down():
	enable_collision()
	$"InteractHint".visible = true

func enable_collision():
	set_collision_layer(collision_layer_original)
	set_collision_mask(collision_mask_original)

func disable_collision():
	set_collision_layer(0)
	set_collision_mask(0)

func enable_collision_delayed(delay:float):
	yield(get_tree().create_timer(delay), "timeout")
	enable_collision()

func disable_gravity():
	gravity_scale = 0

func enable_gravity_delayed(delay:float):
	yield(get_tree().create_timer(delay), "timeout")
	gravity_scale = 1

func disable_physics():
	mode = RigidBody.MODE_STATIC

func enable_physics_delayed(delay):
	yield(get_tree().create_timer(delay), "timeout")
	mode = RigidBody.MODE_RIGID

func request_impulse(v:Vector3):
	is_impulse_requested = true
	impulse_request = v

func request_impulse_delayed(v:Vector3, delay:float):
	yield(get_tree().create_timer(delay), "timeout")
	request_impulse(v)
