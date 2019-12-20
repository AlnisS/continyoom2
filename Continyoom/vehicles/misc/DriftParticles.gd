extends Spatial

var history: Array
var state: Array
var time_since_last_emit: float
var particle_index: int = 0
var drift = 1
var timescale: float = 1

const PARTICLE_TIME = .25
const PARTICLE_COUNT = 5

func _ready():
	_reset()


func _physics_process(delta):
	time_since_last_emit += timescale * delta
	if timescale > 0:
		if time_since_last_emit > PARTICLE_TIME:
			time_since_last_emit -= PARTICLE_TIME
			_add_particle()
	if timescale < 0:
		if time_since_last_emit < 0:
			_step_back_particle()
			time_since_last_emit += PARTICLE_TIME


func _reset() -> void:
	history = Array()
	state = Array()
	var particle = load("res://vehicles/misc/DustParticle.tscn")
	for i in range(PARTICLE_COUNT):
		state.append(particle.instance())
		state[i].hide()
		state[i].set_as_toplevel(true)
	time_since_last_emit = 0


func _on_timescale_updated(new_timescale: float) -> void:
	timescale = new_timescale


func _add_particle() -> void:
	particle_index += 1
	if particle_index >= PARTICLE_COUNT:
		particle_index = 0
	if drift != 0:
		state[particle_index].transform.origin = get_global_transform().origin
		state[particle_index].show()
	else:
		state[particle_index].hide()
	
	var state_copy := Array()
	for i in range(PARTICLE_COUNT):
		var particle_state := Dictionary()
		particle_state.origin = state[i].transform.origin
		particle_state.visibility = state[i].is_visible()
		state_copy.append(particle_state)
	history.append(state_copy)


func _step_back_particle() -> void:
	var state_copy = history.pop_back()
	for i in range(PARTICLE_COUNT):
		state[i].transform.origin = state_copy[i].origin
		state[i].set_visible(state_copy[i].visibility)
#s