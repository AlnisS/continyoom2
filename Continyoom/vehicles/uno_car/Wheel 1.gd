extends Spatial

var timescale: float = 1
var targ_drift: int = 0
var curr_steer: float = 1

func _process(delta):
	pass

func _on_timescale_updated(new_timescale) -> void:
	timescale = new_timescale
	$AnimationPlayer.set_speed_scale(timescale * 1)
#	$DriftParticles._on_timescale_updated(timescale)

func _on_targ_drift_updated(new_targ_drift) -> void:
	targ_drift = new_targ_drift

func _on_curr_steer_updated(new_curr_steer) -> void:
	pass
	#curr_steer = new_curr_steer
	#$transform_fixer/LSteerControl.rotation_degrees = Vector3(0, 90 - 30 * curr_steer, 0)
	#$transform_fixer/RSteerControl.rotation_degrees = Vector3(0, 90 - 30 * curr_steer, 0)
#	$SteeringPlayer.seek(.5 + curr_steer * .5, true)
#	$SteeringPlayer.play()
#	$SteeringPlayer.playback_speed = 0