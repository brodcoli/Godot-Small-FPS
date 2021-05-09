extends Area

const _default_path = "Steps/Default"
var step_audio_path = _default_path

func _on_area_entered(area_id, area, area_shape, local_shape):
	print("y")
	if area is StepArea:
		step_audio_path = area.get_audio_path()
		print(step_audio_path)


func _on_area_exited(area_id, area, area_shape, local_shape):
	if area is StepArea:
		step_audio_path = _default_path
