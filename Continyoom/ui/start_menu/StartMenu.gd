extends Control

var menu: int = 0
var menu_disp: float = 0
var track_path: String = ""
var car_path: String = ""
var blur: float = 0
var cc: float = 0

enum { TITLE, SPEED, TRACK_SELECT, CAR_SELECT, START, LOADING }


func _ready():
	$WideCar.show()
	$Blur.show()
	$Title.show()
	$TrackSelect.show()
	$CarSelect.show()
	$Start.show()
	$Back.show()
	$Blur.material.set_shader_param("amount", blur)
	if not Input.get_connected_joypads().empty():
		$Title/Play.grab_focus()


func _physics_process(delta):
	var window_size = get_viewport_rect().size
	menu_disp = lerp(menu_disp, menu, .2 / clamp(abs(menu - menu_disp) + .5, 0, 1))
	if abs(menu_disp - menu) < .0001:
		menu_disp = menu
	var offset = window_size.x * menu_disp
	$Title.rect_position.x = window_size.x * TITLE - offset
	$CCSelect.rect_position.x = window_size.x * SPEED - offset
	$TrackSelect.rect_position.x = window_size.x * TRACK_SELECT - offset
	$CarSelect.rect_position.x = window_size.x * CAR_SELECT - offset
	$Start.rect_position.x = window_size.x * START - offset
	blur = clamp(menu_disp * 4, 0, 4)
	$Blur.material.set_shader_param("amount", blur)
	$Back.rect_position.x = clamp(window_size.x * SPEED - offset, 0, 999999)
	$BlackScreen.visible = false
	var audio_speed = lerp(.9, 1.1, menu_disp / LOADING)
#	var audio_pitch = -log(audio_speed) / log(2) * .75
	var audio_pitch = (1 - audio_speed)
	print(audio_pitch)
#	print(str(audio_speed) + " " + str(log(audio_speed) / log(2)))
	$MenuMusic.set_pitch_scale(audio_speed)
	var effect = AudioServer.get_bus_effect(AudioServer.get_bus_index("MenuBus"), 0)
	
	effect.set_pitch_scale(audio_pitch + 1)
	if menu == LOADING:
		$BlackScreen.visible = true
		$Back.rect_position.x = window_size.x * (START - menu_disp)
	$BlackScreen.modulate = Color(1, 1, 1, clamp(menu_disp - START, 0, 1))
	if menu_disp == LOADING:
		$BlackScreen/LoadingAnimation/Loading.time = 0
		_load_stage()


func _load_stage():
	var track: Node
	track = load("res://tracks/archetype/Track.tscn").instance()
	track.add_track(track_path)
	track.add_car(car_path)
	track.set_cc(cc)
	get_tree().get_root().add_child(track)
	queue_free()


func _on_Back_pressed():
	if menu > 0:
		menu -= 1
	if !Input.get_connected_joypads().empty() && menu == 1:
			$Title/Play.grab_focus()
#			2:
#				$TrackSelect/VBoxContainer/RainbowRoad.grab_focus()
#			3:
#				$CarSelect/VBoxContainer/DefaultKart.grab_focus()

func _on_Play_pressed():
	menu = SPEED
	if not Input.get_connected_joypads().empty():
		$TrackSelect/VBoxContainer/RainbowRoad.grab_focus()


func _on_RainbowRoad_pressed():
	track_path = "res://tracks/new_ds_rainbow_road/NewDSRainbowRoad.tscn"
	menu = CAR_SELECT
	if not Input.get_connected_joypads().empty():
		$CarSelect/VBoxContainer/DefaultKart.grab_focus()


func _on_TrackUno_pressed():
	track_path = "res://tracks/track_uno/track1.tscn"
	menu = CAR_SELECT
	if not Input.get_connected_joypads().empty():
		$CarSelect/VBoxContainer/DefaultKart.grab_focus()


func _on_DefaultKart_pressed():
	car_path = "res://vehicles/box_car/BoxCar.tscn"
	menu = START
	if not Input.get_connected_joypads().empty():
		$Start/Start.grab_focus()


func _on_ModelB_pressed():
	car_path = "res://vehicles/tyber_cruck/betterCybertruck.tscn"
	menu = START
	if not Input.get_connected_joypads().empty():
		$Start/Start.grab_focus()


func _on_Quit_pressed():
	get_tree().quit()


func _on_Start_pressed():
	menu = LOADING


func _on_TooFast_pressed():
	cc = 150
	menu = TRACK_SELECT


func _on_Fast_pressed():
	cc = 100
	menu = TRACK_SELECT


func _on_NotSoFast_pressed():
	cc = 50
	menu = TRACK_SELECT
