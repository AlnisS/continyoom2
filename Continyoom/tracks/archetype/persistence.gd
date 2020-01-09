extends Node

#PERSISTENCE
#Although located in the tracks/archetype folder, it is not attached to the track
#It is a singleton called throughout the runtime of the game

var state = {'sound': false}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


 #Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("mute"):
		state['sound'] = not state['sound']
		if state['sound']:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 10)
		else:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0)
			
