extends Node

#PERSISTENCE
#Although located in the tracks/archetype folder, it is not attached to the track
#It is a singleton called throughout the runtime of the game

var state = {'muted': false}

# Called when the node enters the scene tree for the first time.
func _ready():
	set_mute()

 #Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("mute"):
		state['muted'] = not state['muted']
		set_mute()

func set_mute():
		if state['muted']:
			AudioServer.lock()
		else:
			AudioServer.unlock()