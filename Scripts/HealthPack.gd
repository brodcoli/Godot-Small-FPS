extends RigidBody3D

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.health < body.max_health:
			body.heal(30)
			Audio.play("HealthKit/Grab/A", position)
			queue_free()
