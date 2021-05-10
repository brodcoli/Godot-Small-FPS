extends RigidBody

class_name Robot

onready var _player = get_tree().get_nodes_in_group("player")[0]

const player_range = 30
const dart_speed = 700
var _rng = RandomNumberGenerator.new()
var _last_dart = 0
var _defeated = false
var _interested = false

func _physics_process(delta):
	if not _defeated:
		var time_since_dart = OS.get_ticks_msec() - _last_dart
		
		var a = _player.get_node("Head/Camera").global_transform.origin
		var b = $RayCast.global_transform.origin
		var dist = (a - b).length()
		if dist < player_range:
			$RayCast.cast_to = (a - b).rotated(Vector3.UP, -rotation.y)
			if $RayCast.is_colliding() and $RayCast.get_collider().is_in_group("player"):
				if not _interested:
					Audio.play("Robot/Awaken/A", translation)
					_interested = true
				var des_dir = PI - (Vector2(a.x, a.z) - Vector2(b.x, b.z)).angle() - rotation.y
				var amt = des_dir - $robot.rotation.y
				$robot.rotation.y += amt * delta
			
				if time_since_dart > dart_speed and abs(amt) < 0.5:
					_last_dart = OS.get_ticks_msec()
					Audio.play("Robot/Fire/A", translation)
					_player.hurt(2, translation)
			else:
				_interested = false
		else:
			_interested = false
			
		if _interested:
			$robot/Light.light_energy = 1
		else:
			$robot/Light.light_energy = 0
			
		if abs(rotation.x) > deg2rad(40) or abs(rotation.z) > deg2rad(40):
			Audio.play("Robot/Defeat/A", translation)
			$robot/Light.light_energy = 0
			_defeated = true
		elif abs(rotation.x) > deg2rad(3) or abs(rotation.z) > deg2rad(3):
			$robot/Light.light_energy = int(Engine.get_frames_drawn() % 5 == 0)
