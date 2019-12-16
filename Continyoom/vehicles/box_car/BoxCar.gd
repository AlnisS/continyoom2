extends Spatial

var timescale: float = 1
var targ_drift: int = 0
var curr_steer: float = 1

func _process(delta):
	pass

func _on_timescale_updated(new_timescale) -> void:
	timescale = new_timescale

func _on_targ_drift_updated(new_targ_drift) -> void:
	targ_drift = new_targ_drift

func _on_curr_steer_updated(new_curr_steer) -> void:
	curr_steer = new_curr_steer
