extends StaticBody

signal pressed

const TYPE = "Pad"
const INTERACT_STRING = "E: Pick up"
const USAGE_HINT = "E: Place"
const BUTTON_ORIGIN = Vector3(0.2, 0.1, 0.2)
const TURRET_SIGNAL_RANGE = 6

export var mat_red_emission:Material
export var mat_green_emission:Material
export var mat_light_off:Material
export(AudioStreamSample) var button_down_sample
export(AudioStreamSample) var button_up_sample

onready var timer = $"Timer"
onready var game_manager = $"/root/Scene"
onready var light = $"Light"
onready var pad_mesh = $"Housing"
onready var audio = $"Audio"

var is_pressed:bool = false
var depression_amount = 0.9
var is_proximity_checking = false
var turrets_in_range:Array


func _ready():
	game_manager.register_pad(self)
	audio.volume_db = -999
	yield(get_tree().create_timer(0.5), "timeout")
	proximity_check()
	yield(get_tree().create_timer(2.0), "timeout")
	audio.volume_db = -5


func _button_area_entered(_body):
	press()


func press():
	if(!is_pressed):
		is_pressed = true
		emit_signal("pressed")
		$"Button".transform.origin = BUTTON_ORIGIN
		$"Button".translate(Vector3(0, -depression_amount, 0))
		fire_nearby_turrets()
		timer.start()
		audio.stream = button_down_sample
		audio.play()


func unpress():
	if(is_pressed):
		is_pressed = false
		$"Button".transform.origin = BUTTON_ORIGIN
		audio.stream = button_up_sample
		audio.play()


func pick_up():
	$"TriggerArea".monitoring = false
	is_proximity_checking = true


func put_down():
#	yield(get_tree().create_timer(0.5), "timeout")
	$"TriggerArea".monitoring = true
	is_proximity_checking = false


func place_on_surface(pos:Vector3, normal:Vector3):
	global_transform.origin = pos
	if(!normal.is_equal_approx(Vector3.UP)):
		var local_up = normal
		var local_forward = Vector3.UP
		var local_right = normal.cross(local_forward)
		global_transform.basis = Basis(-local_right, local_up, -local_forward)


func get_interact_string():
	return INTERACT_STRING


func fire_nearby_turrets():
	for t in turrets_in_range:
		t.remote_fire()


func add_nearby_turret(turret:Node):
	if(turrets_in_range.size() == 0):
		set_light_state("green")
	turrets_in_range.append(turret)


func remove_nearby_turret(turret:Node):
	turrets_in_range.erase(turret)
	if(turrets_in_range.size() == 0):
		set_light_state("off")


func proximity_check():
	var dist_to_turret:float
	var in_list_already:bool
	for t in game_manager.turret_list:
		dist_to_turret = (t.global_transform.origin - global_transform.origin).length()
		in_list_already = turrets_in_range.has(t)
		if(dist_to_turret < TURRET_SIGNAL_RANGE):
			if(!in_list_already):
				add_nearby_turret(t) # Add to self
				t.add_nearby_pad(self)	# Notify turret
		else:
			if(in_list_already):
				remove_nearby_turret(t)	# Remove from self
				t.remove_nearby_pad(self)	# Notify turret


func _process(_delta):
	if(is_proximity_checking):
		proximity_check()


func set_light_state(state:String):
	if(state == "green"):
		pad_mesh.set_surface_material(1, mat_green_emission)
		light.light_color = Color(0, 1, 0)
	elif(state == "red"):
		pad_mesh.set_surface_material(1, mat_red_emission)
		light.light_color = Color(1, 0, 0)
	elif(state == "off"):
		light.light_color = Color(0, 0, 0)
		pad_mesh.set_surface_material(1, mat_light_off)

