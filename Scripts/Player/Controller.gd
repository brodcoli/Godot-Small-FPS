extends KinematicBody

#A lot of the code in this script is borrowed from here https://github.com/turtlewit/VineCrawler/blob/master/PlayerNew.gd

var noclip = false

var cmd = {
	forward_move 	= 0.0,
	right_move 		= 0.0,
	up_move 		= 0.0
}

const walk_speed = 6
const sprint_speed = 10
const crouch_speed = 2
const noclip_speed = 40
const jump_speed = 5.3
const noclip_hyper_speed = 200
const gravity_strength = 15

var x_mouse_sensitivity = .1

var gravity = gravity_strength

var friction = 6.0

var move_speed = 15.0
var run_acceleration = 20.0
var run_deacceleration = 12.0
var air_acceleration = 0.7
var air_deacceleration = 2.0
var air_control = 0.3
var side_strafe_acceleration = 50.0
var side_strafe_speed = 1.0
var move_scale = 1.0

var ground_snap_tolerance = 1

var move_direction_norm = Vector3()
var player_velocity = Vector3()

var up = Vector3(0,1,0)

var wish_jump = false;

var touching_ground = false;

var _player: Spatial
var _head: Spatial
var _collision_shape: CollisionShape

func init(player: Spatial, head: Spatial, collision_shape: CollisionShape):
	_player = player
	_head = head
	_collision_shape = collision_shape
	set_physics_process(true)

func process_movement(delta):
	var is_sprinting = Input.is_action_pressed("sprint")
	var is_jumping = Input.is_action_pressed("jump")
	var is_crouching = Input.is_action_pressed("crouch")
	var just_jumped = Input.is_action_just_pressed("jump")
	var just_crouched = Input.is_action_just_pressed("crouch")
	var just_uncrouched = Input.is_action_just_released("crouch")
	
	if just_crouched:
		_player.get_node("CrouchAnimator").play("Crouch")
	elif just_uncrouched:
		_player.get_node("CrouchAnimator").play("Stand")
		
	
	if noclip:
		var forward = int(Input.is_action_pressed("move_forward")) - int(Input.is_action_pressed("move_backward"))
		var right = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
		var up = int(Input.is_action_pressed("noclip_up")) - int(Input.is_action_pressed("noclip_down"))
		
		var speed = noclip_speed
		if is_crouching:
			speed = noclip_hyper_speed
		touching_ground = false
		player_velocity = Vector3.ZERO
		var h = Vector3.ZERO
		var v = Vector3.ZERO
		h += _head.transform.basis.x * right
		h += _head.transform.basis.z * -forward
		v += Vector3.UP * up
		_player.translation += (h + v) * speed * delta
	else:
		_queue_jump()
		if touching_ground:
			_ground_move(delta)
		else:
			_air_move(delta)
		
		var vel_h = Vector3(player_velocity.x, 0, player_velocity.z)
		var vel_v = Vector3(0, player_velocity.y, 0)
		
		var speed = walk_speed
		if touching_ground:
			if is_sprinting:
				speed = sprint_speed
			elif is_crouching:
				speed = crouch_speed
			
		if vel_h.length() > speed:
			vel_h = vel_h.normalized() * speed
			
		player_velocity = vel_h + vel_v
		
		player_velocity.y -= gravity * delta

		if just_jumped:
			player_velocity = _player.move_and_slide(player_velocity, up, false, 4, 0.785398, false)
		else:
			player_velocity = _player.move_and_slide_with_snap(player_velocity, Vector3.DOWN, up, true, 4, 0.785398, false)
		touching_ground = _player.is_on_floor()
		
		return player_velocity

func _snap_to_ground(from):
	var to = from + -_head.global_transform.basis.y * ground_snap_tolerance
	var space_state = get_world().get_direct_space_state()

	var result = space_state.intersect_ray(from, to)
	if !result.empty():
		_head.global_transform.origin.y = result.position.y

func _set_movement_dir():
	cmd.forward_move = 0.0
	cmd.right_move = 0.0
	cmd.forward_move += int(Input.is_action_pressed("move_forward"))
	cmd.forward_move -= int(Input.is_action_pressed("move_backward"))
	cmd.right_move += int(Input.is_action_pressed("move_right"))
	cmd.right_move -= int(Input.is_action_pressed("move_left"))

func _queue_jump():
	if Input.is_action_just_pressed("jump") and !wish_jump:
		wish_jump = true
	if Input.is_action_just_released("jump"):
		wish_jump = false

func _air_move(delta):
	var wishdir = Vector3()
	var wishvel = air_acceleration
	var accel = 0.0

	var scale = _cmd_scale()

	_set_movement_dir()

	wishdir += _head.transform.basis.x * cmd.right_move
	wishdir -= _head.transform.basis.z * cmd.forward_move

	var wishspeed = wishdir.length()
	wishspeed *= move_speed

	wishdir = wishdir.normalized()
	move_direction_norm = wishdir

	var wishspeed2 = wishspeed
	if player_velocity.dot(wishdir) < 0:
		accel = air_deacceleration
	else:
		accel = air_acceleration

	if(cmd.forward_move == 0) and (cmd.right_move != 0):
		if wishspeed > side_strafe_speed:
			wishspeed = side_strafe_speed
		accel = side_strafe_acceleration

	_accelerate(wishdir, wishspeed, accel, delta)
	if air_control > 0:
		_air_control(wishdir, wishspeed2, delta)

func _air_control(wishdir, wishspeed, delta):
	var zspeed = 0.0
	var speed = 0.0
	var dot = 0.0
	var k = 0.0

	if (abs(cmd.forward_move) < 0.001) or (abs(wishspeed) < 0.001):
		return
	zspeed = player_velocity.y
	player_velocity.y = 0

	speed = player_velocity.length()
	player_velocity = player_velocity.normalized()

	dot = player_velocity.dot(wishdir)
	k = 32.0
	k *= air_control * dot * dot * delta

	if dot > 0:
		player_velocity.x = player_velocity.x * speed + wishdir.x * k
		player_velocity.y = player_velocity.y * speed + wishdir.y * k 
		player_velocity.z = player_velocity.z * speed + wishdir.z * k 

		player_velocity = player_velocity.normalized()
		move_direction_norm = player_velocity

	player_velocity.x *= speed 
	player_velocity.y = zspeed 
	player_velocity.z *= speed 

func _ground_move(delta):
	var wishdir = Vector3()

	if (!wish_jump):
		_apply_friction(1.0, delta)
	else:
		_apply_friction(0, delta)

	_set_movement_dir()

	var scale = _cmd_scale()

	wishdir += _head.transform.basis.x * cmd.right_move
	wishdir -= _head.transform.basis.z * cmd.forward_move

	wishdir = wishdir.normalized()
	move_direction_norm = wishdir

	var wishspeed = wishdir.length()
	wishspeed *= move_speed

	_accelerate(wishdir, wishspeed, run_acceleration, delta)

	player_velocity.y = 0.0

	if wish_jump:
		player_velocity.y = jump_speed
		wish_jump = false

func _apply_friction(t, delta):
	var vec = player_velocity
	var speed = 0.0
	var newspeed = 0.0
	var control = 0.0
	var drop = 0.0

	vec.y = 0.0
	speed = vec.length()
	drop = 0.0

	if touching_ground:
		if speed < run_deacceleration:
			control = run_deacceleration
		else:
			control = speed
		drop = control * friction * delta * t

	newspeed = speed - drop;
	if newspeed < 0:
		newspeed = 0
	if speed > 0:
		newspeed /= speed

	player_velocity.x *= newspeed
	player_velocity.z *= newspeed

func _accelerate(wishdir, wishspeed, accel, delta):
	var addspeed = 0.0
	var accelspeed = 0.0
	var currentspeed = 0.0

	currentspeed = player_velocity.dot(wishdir)
	addspeed = wishspeed - currentspeed
	if addspeed <=0:
		return
	accelspeed = accel * delta * wishspeed
	if accelspeed > addspeed:
		accelspeed = addspeed

	player_velocity.x += accelspeed * wishdir.x
	player_velocity.z += accelspeed * wishdir.z

func _cmd_scale():
	var var_max = 0
	var total = 0.0
	var scale = 0.0

	var_max = int(abs(cmd.forward_move))
	if(abs(cmd.right_move) > var_max):
		var_max = int(abs(cmd.right_move))
	if var_max <= 0:
		return 0

	total = sqrt(cmd.forward_move * cmd.forward_move + cmd.right_move * cmd.right_move)
	scale = move_speed * var_max / (move_scale * total)

	return scale
			
func process(delta):
	var just_noclip = Input.is_action_just_pressed("noclip")
	
	if just_noclip:
		noclip = not noclip
		if noclip:
			gravity = 0
			_collision_shape.disabled = true
		else:
			gravity = gravity_strength
			_collision_shape.disabled = false

func input(event):
	if event is InputEventMouseMotion and _player.mouse_captured:
		_head.rotation_degrees.y -= event.relative.x * _player.mouse_sensitivity / 10
		_head.rotation_degrees.x = clamp(_head.rotation_degrees.x - event.relative.y * _player.mouse_sensitivity / 10, -90, 90)

