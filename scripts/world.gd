extends Node3D

func _input(event):
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Pause.show()
		get_tree().paused = true
