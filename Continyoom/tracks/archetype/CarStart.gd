extends Spatial

signal tfm_ready(tfm)

func _ready():
	emit_signal("tfm_ready", transform)