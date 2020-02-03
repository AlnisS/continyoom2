extends Spatial

var track: Node
var eligible_to_lap = false

func _ready():
	$Car.connect("timescale_updated", $NewDSRainbowRoad, "_on_timescale_updated")


func add_track(path: String):
#	var track: Node = load(path).instance()
	track = load(path).instance()
	$Car.connect("timescale_updated", track, "_on_timescale_updated")
	$Car.set_camera_transform(track.get_node("CameraStart").transform)
	add_child(track)
	track.get_node("CarStart").connect("tfm_ready", $Car, "set_start")


func add_car(path: String):
	var car_visual: Node = load(path).instance()
	$Car.add_child(car_visual, true)
	$Car.connect("timescale_updated", car_visual, "_on_timescale_updated")
	$Car.connect("targ_drift_updated", car_visual, "_on_targ_drift_updated")
	$Car.connect("curr_steer_updated", car_visual, "_on_curr_steer_updated")

func set_cc(cc: float):
	$Car.cc = cc
	$Car._prepare_cc(cc)

func _process(delta):
	var translation = $Car.translation
	var area = track.get_node("beginning_end")
	var intersects = area.overlaps_body($Car.get_node("collider"))
	
	if not eligible_to_lap and not intersects:
		eligible_to_lap = true
	elif eligible_to_lap and intersects:
		eligible_to_lap = false
		$TimeKeeper.lap()