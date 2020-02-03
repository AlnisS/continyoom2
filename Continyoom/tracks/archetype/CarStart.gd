extends Spatial

signal tfm_ready(tfm, ctfm)

func _ready():
	emit_signal("tfm_ready", transform, get_node("../CameraStart").get_global_transform())