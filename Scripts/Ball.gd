extends RigidBody

var first_hit = true

func _on_body_entered(body):
	if first_hit:
		if body is Robot:
			Audio.play("Ball/Hit/A", global_transform.origin)
		else:
			Audio.play_rand("Ball/Bounce", global_transform.origin, "ball_bounce")
	first_hit = false
