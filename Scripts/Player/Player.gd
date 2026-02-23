extends CharacterBody3D
class_name Player

@export var init_head_rot = 0

@onready var _ball = preload("res://Scenes/Sprites/Ball.tscn")
@onready var _health_label = get_node("CanvasLayer/Health")

var _last_attack_pos = Vector3.ZERO
const mouse_sensitivity = 2.6
const max_health = 100
var paused = false
var health = max_health
var dead = false
var mouse_captured = false

func _ready():
	$Head.rotation.y = deg_to_rad(init_head_rot)
	$BallGunAnimator.play("BallGunIdle")
	capture_mouse()

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
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
		
	if just_fired and not paused:
		var ball = _ball.instantiate()
		var direction = ($Head/B.global_transform.origin - $Head/A.global_transform.origin).normalized()
		ball.position = $Head.global_transform.origin + direction * 1
		ball.position.y -= 0.5
		get_tree().root.add_child(ball)
		ball.apply_impulse(direction * 120 + Vector3.UP * 8, Vector3.ZERO)
		$BallGunAnimator.stop()
		$BallGunAnimator.play("BallGunLaunch")
		
		Audio.play_rand_player("Gun/Fire", "gun_fire")
		
	var cursor = get_window().size / 2
	var target = Vector2(get_window().size.x / 2, get_window().size.y - 20)
	var pos = $Head/Camera3D.unproject_position(_last_attack_pos)
	var dir = (pos - target).normalized()
	if $Head/Camera3D.is_position_behind(_last_attack_pos):
		dir.y = abs(dir.y)
		dir.x *= -1
	$CanvasLayer/HurtDirection.position = Vector2(cursor) + dir * 30
	$CanvasLayer/HurtDirection.rotation = dir.angle() + PI / 2
	#$CanvasLayer/Debug.text = "FPS: " + str(Engine.get_frames_per_second()) + "\nON FLOOR: " + str(is_on_floor())
	
	
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
