extends Sprite3D

onready var player:Spatial = get_node("/root/Scene/Player")
onready var parent:Spatial = get_parent()

var parent_position:Vector3
var distance_to_player:float
var visibility_min_distance = 3 # 100% opacity at this distance
var visibility_max_distance = 7 # 0% opacity at this distance
var clamped_player_distance
var max_opacity = 0.7

func _physics_process(_delta):
	parent_position = parent.global_transform.origin
	distance_to_player = (parent_position - player.global_transform.origin).length()
	if(distance_to_player < visibility_max_distance):
		global_transform.origin.x = parent_position.x
		global_transform.origin.y = parent_position.y + 1
		global_transform.origin.z = parent_position.z
		look_at(player.global_transform.origin, Vector3.UP)
		clamped_player_distance = clamp(distance_to_player, visibility_min_distance, visibility_max_distance)
		opacity = 1 - (clamped_player_distance - visibility_min_distance) / (visibility_max_distance - visibility_min_distance)
		opacity *= max_opacity
