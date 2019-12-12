extends Spatial

func _ready():
	$Car.connect("timescale_updated", $NewDSRainbowRoad, "_on_timescale_updated")