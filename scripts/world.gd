extends Node3D

const INTRO_DIALOGUE = preload("res://dialogue/intro.dialogue")
const PEDESTRIAN = preload("res://scenes/pedestrian.tscn")

var timer: float
var mouse_mode = Input.MOUSE_MODE_CAPTURED

@onready var pause_menu = $PauseLayer/Container/SubViewport/PauseMenu

func _ready():
	Global.total_treats = $Collectables.get_child_count()
	for _i in range(50):
		add_child(PEDESTRIAN.instantiate())
	
	if not OS.is_debug_build():
		$Overlay/M/FPS.hide()
		
		mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Player.global_position = $PlayerSpawn.global_position
		$Player.can_move = false
		DialogueUI.start_dialogue(INTRO_DIALOGUE, true)
		await DialogueUI.finished
		$Player.can_move = true
		mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		$Overlay/M/FPS.show()
		query()

func query():
	while true:
		$Overlay/M/FPS.text = "FPS: %s" % Performance.get_monitor(Performance.TIME_FPS)
		await get_tree().create_timer(1.0).timeout

func _process(delta):
	timer += delta
	$Overlay/M/Timer.text = get_time_text()
	$Overlay/M/Timer.visible = Global.timer_enabled

func _input(event):
	if event.is_action_pressed("restart") and OS.is_debug_build():
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		RenderingServer.global_shader_parameter_set("ca_strength", Global.DEFAULT_CA)
		$PauseLayer.show()
		pause_menu.pause(ImageTexture.create_from_image(get_viewport().get_texture().get_image()), $Player.camera, mouse_mode, get_time_text())
		#$Pause.show()
		get_tree().paused = true

func get_time_text():
	return "%d:%06.3f" % [floori(timer / 60.0), timer - floorf(timer / 60.0) * 60.0]
