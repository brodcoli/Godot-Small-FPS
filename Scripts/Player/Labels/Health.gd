extends Label

var _ui_label_settings = preload("res://ui_label_settings.tres")

@onready var _player = get_node("../..")

var _font_size = 4

func _ready():
	get_tree().get_root().connect("size_changed", Callable(self, "_on_resize"))
	_on_resize()
	_update_text()

func _on_resize():
	var size = get_viewport_rect().size
	position = Vector2(size.x * 0.15, size.y * 0.8)
	_font_size = (int(size.x * 0.02) | 0x03) + 1
	_ui_label_settings.font_size = _font_size
	$Sprite2D.scale = Vector2.ONE * (_font_size / 4)
	$Sprite2D.position.x = -_font_size * 2
	_update_text()
	
func _update_text():
	text = str(_player.health)
	$Max.position.x = _font_size * text.length()
	
func on_heal():
	_update_text()
	$HealthAnimator.stop()
	$HealthAnimator.play("Heal")
	
func on_hurt():
	_update_text()
	$HealthAnimator.stop()
	$HealthAnimator.play("Hurt")
