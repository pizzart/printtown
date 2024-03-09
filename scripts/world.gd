extends Node3D

signal transitioned

#const INTRO_DIALOGUE = preload("res://dialogue/intro.dialogue")
const PEDESTRIAN = preload("res://scenes/pedestrian.tscn")
const PETS_REQUIRED = 2

var timer: float
var can_interact_shelter: bool
var mouse_mode = Input.MOUSE_MODE_CAPTURED
@onready var pause_menu = $PauseLayer/Container/SubViewport/PauseMenu

func _ready():
	$Shader.show()
	
	Global.total_treats = $Collectables.get_child_count()
	for _i in range(50):
		add_child(PEDESTRIAN.instantiate())
	
	if not OS.is_debug_build():
		$Overlay/M/FPS.hide()
		
		#mouse_mode = Input.MOUSE_MODE_VISIBLE
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#$Player.global_position = $PlayerSpawn.global_position
		#$Player.can_move = false
		#DialogueUI.start_dialogue(INTRO_DIALOGUE, true)
		#await DialogueUI.finished
		#$Player.can_move = true
		#mouse_mode = Input.MOUSE_MODE_CAPTURED
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#else:
	#$Overlay/M/FPS.show()
	else:
		query()

func _process(delta):
	timer += delta
	$Overlay/M/Timer.text = get_time_text()
	$Overlay/M/Timer.visible = Global.timer_enabled
	
	if $Player.global_position.y < -40:
		$Player.global_position = $PlayerSpawn.global_position
	
	MiscUI.pets_popup.modulate.a = lerpf(MiscUI.pets_popup.modulate.a, 1.0 if can_interact_shelter else 0.0, delta * 10)

func _input(event):
	if event.is_action_pressed("interact") and can_interact_shelter and Global.animals.size() >= PETS_REQUIRED:
		$ShelterArea.set_deferred("monitoring", false)
		can_interact_shelter = false
		$Player.can_move = false
		await get_tree().create_timer(2.0).timeout
		transition()
		await transitioned
		await $Shelter/CutscenePlayer.play_cutscene()
	
	if event.is_action_pressed("restart") and OS.is_debug_build():
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		RenderingServer.global_shader_parameter_set("ca_strength", Global.DEFAULT_CA)
		$PauseLayer.show()
		pause_menu.pause(ImageTexture.create_from_image(get_viewport().get_texture().get_image()), $Player.camera, mouse_mode, get_time_text())
		#$Pause.show()
		get_tree().paused = true
	
	if event.is_action_pressed("wave"):
		get_tree().root.use_occlusion_culling = not get_tree().root.use_occlusion_culling
		print(get_tree().root.use_occlusion_culling)

func transition():
	var tween = create_tween()
	tween.tween_method(set_trans, 1.0, 0.0, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(emit_signal.bind("transitioned"))
	tween.tween_method(set_trans, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

func get_time_text():
	return "%d:%06.3f" % [floori(timer / 60.0), timer - floorf(timer / 60.0) * 60.0]

func query():
	while true:
		$Overlay/M/FPS.text = "FPS: %s" % Performance.get_monitor(Performance.TIME_FPS)
		await get_tree().create_timer(1.0).timeout

func set_trans(value: float):
	$Overlay/Trans.material.set_shader_parameter("size", value)

func _on_shelter_area_body_entered(body):
	if body is Player:
		MiscUI.update_pet_count(Global.animals.size(), PETS_REQUIRED)
		if Global.animals.size() >= PETS_REQUIRED:
			body.can_interact = true
			can_interact_shelter = true

func _on_shelter_area_body_exited(body):
	if body is Player:
		body.can_interact = false
		can_interact_shelter = false

func _on_cutscene_start_body_entered(body):
	if body is Player:
		$Tutorial/CutsceneStart.set_deferred("monitoring", false)
		$Tutorial/CutscenePlayer.play_cutscene()
