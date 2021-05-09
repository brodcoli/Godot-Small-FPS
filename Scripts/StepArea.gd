extends Area

class_name StepArea

export(String, "Default", "Metal") var material_type = "Default"

func get_audio_path():
	if material_type == "Default":
		return "Steps/Default"
	elif material_type == "Metal":
		return "Steps/Metal"
