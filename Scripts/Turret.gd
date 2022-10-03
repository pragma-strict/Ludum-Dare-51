extends StaticBody

signal remote_trigger_update(new_usage_hint)

const TYPE = "Turret"
const INTERACT_STRING = "E: Move\nLeft Mouse: Use"
const USAGE_HINT = "E: Place\nRemote trigger out of range..."
const USAGE_HINT_ALT = "E: Place\nRemote trigger ready!"
const MOUSE_SENSITIVITY = 2
const FIRE_VELOCITY = 80
const FIRE_COOLDOWN = 0.7
const VERTICAL_ROT_CLAMP = 0.5
const HORIZONTAL_ROT_CLAMP = 0.7
const PAD_SIGNAL_RANGE = 6
const REMOTE_FIRE_DELAY = 0.4

export var projectile_scene:PackedScene
export var mat_red_emission:Material
export var mat_green_emission:Material
export var mat_light_off:Material
export(AudioStreamSample) var remote_connect_sample
export(AudioStreamSample) var remote_disconnect_sample
export(AudioStreamSample) var remote_fire_sample
export(AudioStreamSample) var fire_sample

var collision_layer_original:int = 4
var collision_mask_original:int = 7

var can_fire = true
var enable_input = false
var transform_origin
var is_proximity_checking:bool
var pads_in_range:Array

onready var turret_gun = $"GunParent"
onready var turret_gun_mesh:MeshInstance = $"GunParent/Gun"
onready var turret_light = $"GunParent/Light"
onready var turret_camera = $"GunParent/Camera"
onready var floor_check_ray = $"FloorCheckRay"
onready var target_ray = $"GunParent/TargetRay"
onready var game_manager = $"/root/Scene"
onready var audio = $"Audio"
onready var particle_template_node = $"GunParent/Particles"


func _ready():
	audio.volume_db = -999
	game_manager.register_turret(self)
	yield(get_tree().create_timer(0.5), "timeout")
	proximity_check()
	yield(get_tree().create_timer(1), "timeout")
	audio.volume_db = 0


func has_pad_in_range():
	return pads_in_range.size() > 0


func get_interact_string():
	return INTERACT_STRING


func pick_up():
	set_collision_layer(0)
	set_collision_mask(0)
	is_proximity_checking = true


func put_down():
	set_collision_layer(collision_layer_original)
	set_collision_mask(collision_mask_original)
	floor_check_ray.force_raycast_update()
	if(floor_check_ray.is_colliding()):
		var floor_point = floor_check_ray.get_collision_point()
		transform.origin = floor_point
	is_proximity_checking = false


func player_enter():
	set_process_input(true)
	enable_input = true


func player_exit():
	set_process_input(false)
	enable_input = false


func _input(event):
	if(!enable_input):
		return
	if (event is InputEventMouseMotion):
		var mouse_delta = -event.relative * MOUSE_SENSITIVITY * 0.001
		var mouse_vector_horz = Vector3(0.0, mouse_delta.x, 0.0)
		var mouse_vector_vert = Vector3(mouse_delta.y, 0.0, 0.0)
		var look_quat_horz = Quat(turret_gun.transform.basis.xform_inv(mouse_vector_horz))
		var look_quat_vert = Quat(mouse_vector_vert)
		turret_gun.transform.basis *= Basis(look_quat_horz) * Basis(look_quat_vert)
		
		# Clamp rotation
		var rot_quat = turret_gun.transform.basis.get_rotation_quat()
		var rot_euler = rot_quat.get_euler()
		rot_euler.x = clamp(rot_euler.x, -VERTICAL_ROT_CLAMP, VERTICAL_ROT_CLAMP)
		rot_euler.y = clamp(rot_euler.y, -HORIZONTAL_ROT_CLAMP, HORIZONTAL_ROT_CLAMP)
		rot_quat.set_euler(rot_euler)
		
		# Update transform with clamped rotation
		transform_origin = turret_gun.transform.origin
		turret_gun.transform = Transform(rot_quat)
		turret_gun.transform.origin = transform_origin
		
	if (Input.is_action_just_pressed("mouse_left")):
		if(can_fire):
			fire()
#	if (Input.is_action_just_pressed("interact")):
#		$"../Player".leave_turret()


func remote_fire():
	audio.stream = remote_fire_sample
	audio.play()
	yield(get_tree().create_timer(REMOTE_FIRE_DELAY), "timeout")
	fire()


func fire():
	if(target_ray.is_colliding()):
		target_ray.get_collider().get_parent().press()
	var particles = particle_template_node.duplicate()
	get_parent().add_child(particles)
	particles.global_transform = particle_template_node.global_transform
	particles.emitting = true
	can_fire = false
	audio.stream = fire_sample
	audio.play()
	yield(get_tree().create_timer(FIRE_COOLDOWN), "timeout")
	can_fire = true


func add_nearby_pad(pad:Node):
	if(pads_in_range.size() == 0):
		set_light_state("green")
		emit_signal("remote_trigger_update", USAGE_HINT_ALT)
	pads_in_range.append(pad)
	audio.stream = remote_connect_sample
	audio.play()


func remove_nearby_pad(pad:Node):
	pads_in_range.erase(pad)
	if(pads_in_range.size() == 0):
		set_light_state("off")
		emit_signal("remote_trigger_update", USAGE_HINT)
	audio.stream = remote_disconnect_sample
	audio.play()



func proximity_check():
	var dist_to_pad:float
	var in_list_already:bool
	for p in game_manager.pad_list:
		dist_to_pad = (p.global_transform.origin - global_transform.origin).length()
		in_list_already = pads_in_range.has(p)
		if(dist_to_pad < PAD_SIGNAL_RANGE):
			if(!in_list_already):
				add_nearby_pad(p) # Add to self
				p.add_nearby_turret(self)	# Notify pad
		else:
			if(in_list_already):
				remove_nearby_pad(p)	# Remove from self
				p.remove_nearby_turret(self)	# Notify pad


func _process(_delta):
	if(is_proximity_checking):
		proximity_check()


func set_light_state(state:String):
	if(state == "green"):
		turret_gun_mesh.set_surface_material(1, mat_green_emission)
		turret_light.light_color = Color(0, 1, 0)
	elif(state == "red"):
		turret_gun_mesh.set_surface_material(1, mat_red_emission)
		turret_light.light_color = Color(1, 0, 0)
	elif(state == "off"):
		turret_light.light_color = Color(0, 0, 0)
		turret_gun_mesh.set_surface_material(1, mat_light_off)
