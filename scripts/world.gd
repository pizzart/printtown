extends Node3D

#const INTRO_DIALOGUE = preload("res://dialogue/intro.dialogue")
const BUFFER_DIALOGUE = preload("res://dialogue/buffer_tutorial.dialogue")
const BONUS_DIALOGUE = preload("res://dialogue/bonus_later.dialogue")
const PEDESTRIAN = preload("res://scenes/pedestrian.tscn")
const MUSIC = [preload("res://audio/mus/parkour.ogg"), preload("res://audio/mus/parkour2.ogg")]
const PETS_REQUIRED = 2

#var timer: float
var cur_mus: int = 0
var can_interact_shelter: bool
var mouse_mode = Input.MOUSE_MODE_CAPTURED
var tutorials_given: Array[String] = []
@onready var pause_menu = $PauseLayer/Container/SubViewport/PauseMenu

func _ready():
	$Shader.show()
	
	Global.total_treats = $Collectables.get_child_count()
	Global.treat_collected.connect(_on_treat_collected)
	for _i in range(70):
		add_child(PEDESTRIAN.instantiate())
	
	if not OS.is_debug_build():
		$Overlay/M/FPS.hide()
		
		#mouse_mode = Input.MOUSE_MODE_VISIBLE
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Player.global_position = $PlayerSpawn.global_position
		#$Player.can_move = false
		#DialogueUI.start_dialogue(INTRO_DIALOGUE, true)
		#await DialogueUI.finished
		#$Player.can_move = true
		#mouse_mode = Input.MOUSE_MODE_CAPTURED
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		$Player.global_position = $PlayerSpawnDebug.global_position
		$ParkourMusic.play()
		#$Player.global_position = $PlayerSpawn.global_position
		#$Overlay/M/FPS.show()
		query()
		#_on_final_fight_finished()

func _process(delta):
	Global.time += delta
	$Overlay/M/Timer.text = Global.get_time_text()
	$Overlay/M/Timer.visible = Global.timer_enabled
	
	if $Player.global_position.y < -40:
		$Player.global_position = $PlayerSpawn.global_position
	
	MiscUI.pets_popup.modulate.a = lerpf(MiscUI.pets_popup.modulate.a, 1.0 if can_interact_shelter else 0.0, delta * 10)

func _input(event):
	if event.is_action_pressed("interact") and can_interact_shelter and Global.animals.size() >= PETS_REQUIRED:
		$Triggers/ShelterArea.set_deferred("monitoring", false)
		can_interact_shelter = false
		$Player.prepare_fight()
		$Ambience.stop()
		#await get_tree().create_timer(2.0).timeout
		MiscUI.transition()
		await MiscUI.transitioned
		await $Shelter/CutscenePlayer.play_cutscene()
		$FinalFight.activate_fight($Player)
	
	if event.is_action_pressed("restart") and OS.is_debug_build():
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		RenderingServer.global_shader_parameter_set("ca_strength", Global.DEFAULT_CA)
		AudioServer.set_bus_effect_enabled(2, 0, true) # lp filter
		$PauseLayer.show()
		pause_menu.pause(ImageTexture.create_from_image(get_viewport().get_texture().get_image()), $Player.camera, mouse_mode, Global.get_time_text())
		#$Pause.show()
		get_tree().paused = true
	
	#if event.is_action_pressed("wave"):
		#get_tree().root.use_occlusion_culling = not get_tree().root.use_occlusion_culling
		#print(get_tree().root.use_occlusion_culling)

func query():
	while true:
		$Overlay/M/FPS.text = "FPS: %s" % Performance.get_monitor(Performance.TIME_FPS)
		await get_tree().create_timer(1.0).timeout

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
		await $Tutorial/CutscenePlayer.play_cutscene()
		$ParkourMusic.volume_db = -80
		$ParkourMusic.play()
		var tween = create_tween()
		tween.tween_property($ParkourMusic, "volume_db", -20, 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func _on_buffering_tutorial_body_entered(body):
	if body is Player and not "buffer" in tutorials_given:
		tutorials_given.append("buffer")
		
		mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		body.prepare_fight()
		
		DialogueUI.start_dialogue(BUFFER_DIALOGUE, true)
		await DialogueUI.finished
		
		body.can_move = true
		mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_treat_collected():
	if Global.collected_treats == Global.total_treats:
		Global.bonus_unlocked = true
		mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		$Player.prepare_fight()
		
		DialogueUI.start_dialogue(BONUS_DIALOGUE, true)
		await DialogueUI.finished
		
		$Player.can_move = true
		mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_action_started(idx: int):
	#if idx == 0:
		#$Shelter/CutscenePlayer2.skip_to_action(18)
	
	if idx == 18:
		MiscUI.play_video()
	
	if idx == 25:
		MiscUI.slow_transition(3.0, 3.0)
		await get_tree().create_timer(3.0).timeout
		get_tree().paused = true
		get_tree().change_scene_to_file("res://scenes/ending.tscn")

func _on_final_fight_finished():
	$Player.prepare_fight()
	$Shelter/CutscenePlayer2/Giraffe.show()
	$Shelter/CutscenePlayer2/Giraffe3.show()
	await get_tree().create_timer(0.1).timeout
	$Shelter/CutscenePlayer2.started_action.connect(_on_action_started)
	$Shelter/CutscenePlayer2.play_cutscene()

func _on_parkour_music_finished():
	cur_mus = (cur_mus + 1) % 2
	$ParkourMusic.stream = MUSIC[cur_mus]
	$ParkourMusic.play()
