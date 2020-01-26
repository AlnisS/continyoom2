extends Spatial

var last_timescale = 0
var new_timescale = 0
var music_loc = 0

const TRACK_SPEED = 1
const ARROW_SPEED = 4
const CANNON_SPEED = .5
const CANNON_WALL_SPEED = .2
const SMOOTHED = false

func _on_timescale_updated(var the_new_timescale):
	if SMOOTHED:
		new_timescale = lerp(new_timescale, the_new_timescale, .07)
	else:
		new_timescale = the_new_timescale
	if last_timescale != new_timescale:
#		$SomeAnimationPlayer.set_speed_scale(new_timescale * SOME_CONST)
		$TrackAnimationPlayer.set_speed_scale(new_timescale * TRACK_SPEED)
		$ArrowAnimationPlayer.set_speed_scale(new_timescale * ARROW_SPEED)
		$CannonAnimationPlayer.set_speed_scale(new_timescale * CANNON_SPEED)
		$CannonWallAnimationPlayer.set_speed_scale(new_timescale * CANNON_WALL_SPEED)
		
		
		music_loc = $TrackMusicPlayer.get_playback_position()
		if $TrackMusicPlayer.is_ready:
			if new_timescale > 0:
				
				if last_timescale > 0:
					pass
#					$TrackMusicPlayer.play(music_loc)
				else:
					$TrackMusicPlayer.stream = load("res://tracks/waluigi_pinball/waluigi_pinball_music.ogg")
					$TrackMusicPlayer.play($TrackMusicPlayer.stream.get_length() - music_loc)
			else:
				
				if last_timescale < 0:
					pass
#					$TrackMusicPlayer.play(music_loc)
				else:
					$TrackMusicPlayer.stream = load("res://tracks/waluigi_pinball/waluigi_pinball_music_reversed.ogg")
					$TrackMusicPlayer.play($TrackMusicPlayer.stream.get_length() - music_loc)
			$TrackMusicPlayer.pitch_scale = abs(new_timescale)
			last_timescale = new_timescale