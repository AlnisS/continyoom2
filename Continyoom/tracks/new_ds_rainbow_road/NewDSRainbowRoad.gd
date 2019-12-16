extends Spatial

const PIPE_ROT_SPEED = .35
const STAR_ROT_SPEED = .65
const TRACK_MOVE_SPEED = 1
const ARROW_MOVE_SPEED = 4

func _on_timescale_updated(var new_timescale):
	$PipeAnimationPlayer.set_speed_scale(new_timescale * PIPE_ROT_SPEED)
	$StarAnimationPlayer.set_speed_scale(new_timescale * STAR_ROT_SPEED)
	$TrackAnimationPlayer.set_speed_scale(new_timescale * TRACK_MOVE_SPEED)
	$ArrowAnimationPlayer.set_speed_scale(new_timescale * ARROW_MOVE_SPEED)
