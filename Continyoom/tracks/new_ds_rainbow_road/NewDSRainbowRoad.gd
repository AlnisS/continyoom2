extends Spatial

const PIPE_ROT_SPEED = .35
const STAR_ROT_SPEED = .65
const TRACK_MOVE_SPEED = 1
const ARROW_MOVE_SPEED = 4

var last_timescale = 0
var music_loc = 0

func _on_timescale_updated(var new_timescale):
	if last_timescale != new_timescale:
		$PipeAnimationPlayer.set_speed_scale(new_timescale * PIPE_ROT_SPEED)
		$StarAnimationPlayer.set_speed_scale(new_timescale * STAR_ROT_SPEED)
		$TrackAnimationPlayer.set_speed_scale(new_timescale * TRACK_MOVE_SPEED)
		$ArrowAnimationPlayer.set_speed_scale(new_timescale * ARROW_MOVE_SPEED)
		
		music_loc = $TrackMusicPlayer.get_playback_position()
		if $TrackMusicPlayer.is_ready:
			if new_timescale > 0:
				$TrackMusicPlayer.stream = load("res://tracks/new_ds_rainbow_road/ndsrr_music.ogg")
				if last_timescale > 0:
					$TrackMusicPlayer.play(music_loc)
				else:
					$TrackMusicPlayer.play($TrackMusicPlayer.stream.get_length() - music_loc)
			else:
				$TrackMusicPlayer.stream = load("res://tracks/new_ds_rainbow_road/ndsrr_music_reversed.ogg")
				if last_timescale < 0:
					$TrackMusicPlayer.play(music_loc)
				else:
					$TrackMusicPlayer.play($TrackMusicPlayer.stream.get_length() - music_loc)
			$TrackMusicPlayer.pitch_scale = abs(new_timescale)
		
		last_timescale = new_timescale