extends Node

const move_dist_until_step = 2
var move_dist = 0
var is_in_air = false
var last_floor_height = 0
var last_h_pos: Vector2
var last_steps = ["", ""]

var _player: Spatial
var _feet: Spatial
var _rng = RandomNumberGenerator.new()

const landing_types = {
	"SMALL": 0,
	"SOFT": 1,
	"HARD": 3
}

func init(player: Spatial, feet: Spatial):
	_player = player
	_feet = feet

func _just_landed(landing_type):
	print(landing_type)
	if landing_type == "SOFT":
		pass
	elif landing_type == "HARD":
		pass
		
func physics_process(delta):
	var just_jumped = Input.is_action_just_pressed("jump")
	var h_pos = Vector2(_player.translation.x, _player.translation.z)
	
	if _player.is_on_floor():
		move_dist += (last_h_pos - h_pos).length()
		last_h_pos = h_pos
		
		if is_in_air:
			var fall_height = last_floor_height - _player.translation.y
			var landing_type = ""
			for type in landing_types.keys():
				if fall_height > landing_types[type]:
					landing_type = type
			_just_landed(landing_type)
		is_in_air = false
		
		last_floor_height = _player.translation.y
		
		if move_dist > move_dist_until_step:
			move_dist = 0
			Audio.play_rand_player(_feet.step_audio_path, "step")
	else:
		is_in_air = true
		
	if just_jumped and _player.is_on_floor():
		Audio.play_rand_player(_feet.step_audio_path, "step")
