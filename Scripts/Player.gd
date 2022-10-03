extends KinematicBody

export(float) var jump_strength = 10.0
export(float) var movement_speed = 7.0
export(float) var gravity = 0.7

export(Array, AudioStreamSample) var foostep_samples
export(Array, AudioStreamSample) var jump_samples
export(Array, AudioStreamSample) var throw_samples

signal looked_at_item(item_interact_string)
signal looked_away_from_item

onready var camera = $"PlayerCam"
onready var game_manager = $"/root/Scene"
onready var environment_ray:RayCast = $"PlayerCam/EnvironmentRay"
onready var audio_left_foot = $"AudioLeftFoot"
onready var audio_right_foot = $"AudioRightFoot"
onready var audio_misc = $"AudioMisc"
onready var line_renderer:ImmediateGeometry = $"../DebugLines"

const FOOTSTEP_DELAY = 0.2

var enable_input = true
var is_debug_cam_active = false
var is_alive = true
var can_play_footstep = true
var last_foot_stepped = "left"

var is_looking_at_interactive_object = false
var is_holding_object = false
var is_in_turret = false
var looking_at_object:Spatial
var holding_object:Spatial
var holding_object_original_parent:Node
var holding_object_offset:Vector3 = Vector3(0.5, -0.5, -0.5)
var holding_object_type:String
var throw_force = 18
var throw_up_amount = 0.35

var _velocity = Vector3.ZERO
var _snap_vector = Vector3.DOWN
var _move_direction := Vector3.ZERO



func _ready():
	pass


func _input(_event):
	if(!is_alive):
		return
	if(Input.is_action_just_pressed("c")):
		pass
	if(Input.is_action_just_pressed("interact")):
		if(is_looking_at_interactive_object and !is_holding_object and !is_in_turret):
			if(looking_at_object.TYPE == "Item"):
				pick_up_item()
			elif(looking_at_object.TYPE == "Turret"):
				pick_up_item()
			elif(looking_at_object.TYPE == "Pad"):
				pick_up_item()
			else:
				print("Interacting with a non-item object. TODO: this.")
		elif(is_holding_object):
			var _new_item = put_down_item()
		elif(is_in_turret):
			print("Leaving")
			leave_turret()
	
	if(Input.is_action_just_pressed("mouse_left")):
#		draw_aim_line()
		if(is_holding_object):
			if(holding_object_type == "Item"):
				throw_item()
		if(is_looking_at_interactive_object and !is_holding_object and !is_in_turret):
			if(looking_at_object.TYPE == "Turret"):
				enter_turret()
	
	if(Input.is_action_pressed("mouse_left")):
		pass
	if(Input.is_action_just_released("mouse_left")):
		pass


func draw_aim_line():
	line_renderer.begin(Mesh.PRIMITIVE_LINES)
	line_renderer.add_vertex(camera.global_transform.origin)
	line_renderer.add_vertex(camera.global_transform.translated(Vector3.FORWARD * 20).origin)
	line_renderer.end()


func _physics_process(_delta: float):	
	if(is_debug_cam_active or !is_alive or !enable_input):
		return
		
	# Handle movement
	_move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	_move_direction.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	_move_direction = _move_direction.rotated(Vector3.UP, camera.rotation.y).normalized()
	
	_velocity.x = _move_direction.x * movement_speed
	_velocity.z = _move_direction.z * movement_speed
	_velocity.y -= gravity
	
	# Handle jumping
	var just_landed = is_on_floor() and _snap_vector == Vector3.ZERO
	var should_jump = is_on_floor() and Input.is_action_just_pressed("jump")
	
	if(should_jump):
		_velocity.y = jump_strength
		_snap_vector = Vector3.ZERO
		audio_misc.stream = jump_samples[randi() % jump_samples.size()]
		audio_misc.play()
	elif(just_landed):
		_snap_vector = Vector3.DOWN
		audio_misc.stream = throw_samples[randi() % throw_samples.size()]
		audio_misc.play()
	elif(is_on_floor()):
		_velocity.y = 0
	
	# Apply velocity
	_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP)
	
	var h_vel = Vector2(_velocity.x, _velocity.z)
	
	if(h_vel.length() > 0.2):
		if(can_play_footstep):
			play_footstep()


func play_footstep():
	can_play_footstep = false
	if(last_foot_stepped == "left"):
		audio_right_foot.stream = foostep_samples[randi() % foostep_samples.size()]
		audio_right_foot.play()
		last_foot_stepped = "right"
	else:
		audio_left_foot.stream = foostep_samples[randi() % foostep_samples.size()]
		audio_left_foot.play()
		last_foot_stepped = "left"
	yield(get_tree().create_timer(FOOTSTEP_DELAY), "timeout")
	can_play_footstep= true


func get_pos():
	return global_transform.origin


# Assumes the only objects passed are those that have a "TYPE" variable
func _on_InteractRay_collide_begin(object):
	if(!is_holding_object and !is_looking_at_interactive_object):
		is_looking_at_interactive_object = true
		looking_at_object = object
		emit_signal("looked_at_item", object.get_interact_string())



func _on_InteractRay_collide_end(_object):
	if(!is_holding_object and is_looking_at_interactive_object):
		is_looking_at_interactive_object = false
		looking_at_object = null
		emit_signal("looked_away_from_item")


# Assumes looking_at_object is TYPE == "Item"
func pick_up_item():
	holding_object_type = looking_at_object.TYPE
	holding_object = looking_at_object
	
	# Reparent
	holding_object_original_parent = holding_object.get_parent()
	holding_object_original_parent.remove_child(holding_object)
	camera.add_child(holding_object)
	holding_object.set_owner(camera)
	
	var holding_pos = camera.global_transform.translated(holding_object_offset).origin
	holding_object.global_transform.origin = holding_pos
	holding_object.transform.basis = Basis(Vector3.FORWARD, Vector3.UP, Vector3.RIGHT)
	
	holding_object.pick_up()
	$"UsageHintLabel".text = holding_object.USAGE_HINT
	if(holding_object.TYPE == "Turret"):
		if(holding_object.has_pad_in_range()):
			$"UsageHintLabel".text = holding_object.USAGE_HINT_ALT
	is_holding_object = true
	is_looking_at_interactive_object = false
	emit_signal("looked_away_from_item")	


# Assumes holding_object is TYPE == "Item"
func put_down_item() -> Spatial:
	# Reparent
	camera.remove_child(holding_object)
	holding_object_original_parent.add_child(holding_object)
	holding_object.set_owner(holding_object_original_parent)

	var spawn_pos = camera.global_transform.translated(Vector3.FORWARD * 2).origin
	holding_object.global_transform.origin = spawn_pos
	var camera_rot = Quat(camera.global_transform.basis)
	var camera_rot_eul = camera_rot.get_euler()
	camera_rot_eul.x = 0
	camera_rot.set_euler(camera_rot_eul)
	holding_object.global_transform.basis = Basis(camera_rot)
	holding_object.put_down()
	
	# Handle the special case of putting down a pad
	if(holding_object_type == "Pad"):
		environment_ray.force_raycast_update()
		if(environment_ray.is_colliding()):
			var pos = environment_ray.get_collision_point()
			var normal = environment_ray.get_collision_normal()
			holding_object.place_on_surface(pos, normal)
		else:
			pick_up_item()
			return holding_object
	
	$"UsageHintLabel".text = ""
	is_holding_object = false
	return holding_object


# Assumes holding_object is TYPE == "Item"
func throw_item():
	# Reparent
	camera.remove_child(holding_object)
	holding_object_original_parent.add_child(holding_object)
	holding_object.set_owner(holding_object_original_parent)

	# Apply impulse
	holding_object.disable_physics()
	var spawn_pos = camera.global_transform.translated(Vector3.FORWARD * 2).origin	
	holding_object.global_transform.origin = spawn_pos
	var dir = (spawn_pos - camera.global_transform.origin).normalized()
	holding_object.request_impulse(dir * throw_force)
	
	holding_object.put_down()
	is_holding_object = false
	
	$"UsageHintLabel".text = ""
	audio_misc.stream = throw_samples[randi() % throw_samples.size()]
	audio_misc.play()


# Assumes looking_at_object is TYPE == "Turret"
func enter_turret():
	looking_at_object.turret_camera.make_current()
	looking_at_object.player_enter()
	emit_signal("looked_away_from_item")
	camera.enable_input = false
	enable_input = false
	is_in_turret = true


# Assumes in turret
func leave_turret():
	looking_at_object.player_exit()
	camera.make_current()
	camera.enable_input = true
	enable_input = true
	is_in_turret = false


func disable_regular_HUD():
	$"TimerHUD".visible = false
	$"InteractLabel".visible = false
	$"Crosshair".visible = false


func kill():
	is_alive = false
	camera.environment.adjustment_enabled = true
	disable_regular_HUD()
	$"DeathLabel".visible = true
	$"../Music".stop()


func win(_body):
	disable_regular_HUD()
	$"WinLabel".visible = true


func _on_turret_remote_trigger_update(new_usage_hint):
	print("Triggering")
	if(is_holding_object):
		if(holding_object.TYPE == "Turret"):
			$"UsageHintLabel".text = new_usage_hint
