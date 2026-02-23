extends Area3D

class_name StepArea

@export var material_type = "Default" # (String, "Default", "Metal")

func get_audio_path():
	if material_type == "Default":
		return "Steps/Default"
	elif material_type == "Metal":
		return "Steps/Metal"
