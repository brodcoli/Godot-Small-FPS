extends Spatial

onready var _player = get_node("..")
onready var _head = get_node("../Head")

const follow_speed = 20

func _process(delta):
	var des_rot = _head.rotation
	var rot = des_rot - rotation
	rotation += rot * follow_speed * delta
