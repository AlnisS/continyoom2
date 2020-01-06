extends AudioStreamPlayer

var mute
const MUTE_SPEED = 4
const COMPLETE_MUTE_SPEED = 4
var complete_mute = 0
var complete_mute_target = 0
var manual_complete_mute = false
var is_ready = false

func _ready():
	yield(get_tree().create_timer(1), "timeout")  # no clue why this works
	mute = 0.2  # makes start slightly less punchy
	playing = true
	is_ready = true

func _physics_process(delta):
	if (mute == null):
		return
	if (get_tree().paused == true):
		mute += delta * MUTE_SPEED
		if (mute > 1):
			mute = 1
	else:
		mute -= delta * MUTE_SPEED
		if (mute < 0):
			mute = 0
	if (complete_mute_target < complete_mute):
		complete_mute -= delta * COMPLETE_MUTE_SPEED
		if (complete_mute < 0):
			complete_mute = 0
	elif (complete_mute_target > complete_mute):
		complete_mute += delta * COMPLETE_MUTE_SPEED
		if (complete_mute > 1):
			complete_mute = 1
	if (Input.is_action_just_pressed("mute")):
		manual_complete_mute = !manual_complete_mute
	update_mute()
	complete_mute(complete_mute)

	manual_complete_mute(manual_complete_mute)

func update_mute():
	var effect = AudioServer.get_bus_effect(AudioServer.get_bus_index("PauseEQ"), 0)
	if effect == null:
		return
	effect.set_band_gain_db(3, -40 * mute)
	effect.set_band_gain_db(4, -40 * mute)
	effect.set_band_gain_db(5, -40 * mute)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -1 * mute)

func complete_mute(var mute):
	var bi = AudioServer.get_bus_index("Master")
	if (mute == 0):
		AudioServer.set_bus_mute(bi, true)
	else:
		AudioServer.set_bus_mute(bi, false)
		AudioServer.set_bus_volume_db(bi, 10 * log(1 - mute))

func manual_complete_mute(var mute):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), mute)

func _notification(what):
    if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
        complete_mute_target = 0
    elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
        complete_mute_target = 1
