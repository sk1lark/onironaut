# cutscene_data.gd
# Resource for storing cutscene configuration
extends Resource
class_name CutsceneData

@export var image_path: String = ""
@export_multiline var dialogue_lines: Array[String] = []
@export var trigger_wave: int = 0  # Which wave triggers this cutscene (0 = never)

func get_image() -> Texture2D:
	if image_path and image_path != "":
		return load(image_path)
	return null
