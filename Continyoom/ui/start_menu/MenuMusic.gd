extends AudioStreamPlayer

func _process(delta):
	if get_playback_position() > 31.10:
		seek(8.46)
