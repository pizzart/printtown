extends CanvasLayer

func _on_continue_pressed():
	$C/Buttons/Continue.disabled = true
	$C/Buttons/Options.disabled = true
	$C/Buttons/Quit.disabled = true
	
	$C/BG.play("default")
	$C/BG.frame = 1
	await $C/BG.animation_finished
	hide()
	
	Input.mouse_mode = get_parent().mouse_mode
	
	$C/Buttons/Continue.disabled = false
	$C/Buttons/Options.disabled = false
	$C/Buttons/Quit.disabled = false
	
	$C/BG.frame = 0
	get_tree().paused = false
