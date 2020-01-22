extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var time = 0.0
var translation = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("reset"):
		time = 0.0
	
	time += delta
	$Label.text = "Time: " + str(stepify(time, 0.01))
	
#	translation = get_node('../Car').translation
#	area = get_node('../track')