extends Node3D

var game_camera: Camera3D
var mouse_mode: Input.MouseMode
var can_unpause: bool

func _input(event):
	if event.is_action_pressed("pause"):
		if can_unpause:
			unpause()

func pause(texture: ImageTexture, _game_camera: Camera3D, _mouse_mode: Input.MouseMode):
	game_camera = _game_camera
	mouse_mode = _mouse_mode
	#$Camera.make_current()
	$GameTexture.texture = texture
	var tween = create_tween()
	tween.tween_property($Camera, "global_transform", $ZoomOutPoint.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	can_unpause = true
	$UI/Unpause.disabled = false

func unpause():
	$UI/Unpause.disabled = true
	can_unpause = false
	var tween = create_tween()
	tween.tween_property($Camera, "global_transform", $ZoomPoint.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished
	Input.mouse_mode = mouse_mode
	#game_camera.make_current()
	get_parent().get_parent().get_parent().hide()
	get_tree().paused = false

func _on_unpause_pressed():
	unpause()
