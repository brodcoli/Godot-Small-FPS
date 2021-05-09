extends KinematicBody

class_name Player

export var init_head_rot = 0

var Controller = load("res://Scripts/Player/Controller.gd")
var StepHandler = load("res://Scripts/Player/StepHandler.gd")
onready var _ball = preload("res://Scenes/Sprites/Ball.tscn")
onready var _health_label = get_node("CanvasLayer/Health")

var _last_attack_pos = Vector3.ZERO
const mouse_sensitivity = 2.6
const max_health = 100
var paused = false
var health = max_health
var dead = false
var mouse_captured = false

var controller = Controller.new()
var step_handler = StepHandler.new()

func _ready():
	$Head.rotation.y = deg2rad(init_head_rot)
	controller.init(self, $Head, $CollisionShape)
	step_handler.init(self, $Feet)
	$BallGunAnimator.play("BallGunIdle")

func _physics_process(delta):
	step_handler.physics_process(delta)
	controller.process_movement(delta)

func _process(delta):
	var just_paused = Input.is_action_just_pressed("pause")
	var just_fired = Input.is_action_just_pressed("fire")
	var just_fullscreen = Input.is_action_just_pressed("fullscreen")
	
	if just_paused:
		paused = not paused
		if not paused:
			capture_mouse()
			$PauseScreen.get_child(0).visible = false
		else:
			uncapture_mouse()
			$PauseScreen.get_child(0).visible = true
			
	if just_fullscreen:
		OS.window_fullscreen = !OS.window_fullscreen
		
	if just_fired and not paused:
		var ball = _ball.instance()
		var direction = ($Head/B.global_transform.origin - $Head/A.global_transform.origin).normalized()
		ball.translation = $Head.global_transform.origin + direction * 1
		ball.translation.y -= 0.5
		ball.apply_impulse(Vector3.ZERO, direction * 120 + Vector3.UP * 8)
		get_tree().root.add_child(ball)
		$BallGunAnimator.stop()
		$BallGunAnimator.play("BallGunLaunch")
		
		Audio.play_rand_player("Gun/Fire", "gun_fire")
		
	var cursor = OS.window_size / 2
	var target = Vector2(OS.window_size.x / 2, OS.window_size.y - 20)
	var pos = $Head/Camera.unproject_position(_last_attack_pos)
	var dir = (pos - target).normalized()
	if $Head/Camera.is_position_behind(_last_attack_pos):
		dir.y = abs(dir.y)
		dir.x *= -1
	$CanvasLayer/HurtDirection.position = cursor + dir * 30
	$CanvasLayer/HurtDirection.rotation = dir.angle() + PI / 2
	#$CanvasLayer/Debug.text = "FPS: " + str(Engine.get_frames_per_second()) + "\nON FLOOR: " + str(is_on_floor())
	
	controller.process(delta)

func _input(event):
	controller.input(event)
	
func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
func uncapture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	
func heal(amount: int):
	health += amount
	if health > max_health:
		health = max_health
	_health_label.on_heal()
	
func hurt(amount: int, origin: Vector3):
	health -= amount
	if health < 0:
		health = 0
	_last_attack_pos = origin
	
	Audio.play_rand_player("Hurt", "hurt")
	$HurtAnimator.stop()
	$HurtAnimator.play("hurt")
	
	if health <= 0:
		dead = true
		paused = true
		$DeathScreen.get_child(0).visible = true
		$CanvasLayer/CenterContainer/Cursor.visible = false
		uncapture_mouse()
		AudioServer.set_bus_effect_enabled(0, 1, true)
		
	_health_label.on_hurt()

