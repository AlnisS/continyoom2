extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		#de presses action, only important when action is triggered in code
		Input.action_release("pause")
		
		#show/hide when necessary
		if get_tree().paused:
			self.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if not get_tree().paused:
			self.show()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if not Input.get_connected_joypads().empty():
				$resume.grab_focus()
		
		#switch pause state
		get_tree().paused = not get_tree().paused


func _on_Resume_pressed():
	Input.action_press("pause")


func _on_Menu_pressed():
	get_tree().paused = false
	self.hide()
	get_tree().change_scene("ui/start_menu/StartMenu.tscn")
	get_node("..").queue_free()


func _on_Quit_pressed():
	get_tree().quit()
	

#automatically pauses the game if the user focuses on something else
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT and !get_tree().paused:
		Input.action_press("pause")
