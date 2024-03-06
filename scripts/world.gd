extends Node3D

var timer: float
var mouse_mode = Input.MOUSE_MODE_CAPTURED
@onready var pause_menu = $PauseLayer/Container/SubViewport/PauseMenu

func _ready():
	Global.total_treats = $Collectables.get_child_count()
	if not OS.is_debug_build():
		$Player.global_position = $PlayerSpawn.global_position

func query():
	while true:
		$CanvasLayer/Label.text = "FPS: %s" % Performance.get_monitor(Performance.TIME_FPS)
		await get_tree().create_timer(1.0).timeout

func _process(delta):
	timer += delta
	$Overlay/Timer.text = "%d:%06.3f" % [floori(timer / 60.0), timer - floorf(timer / 60.0) * 60.0]

func _input(event):
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		RenderingServer.global_shader_parameter_set("ca_strength", Global.DEFAULT_CA)
		$PauseLayer.show()
		pause_menu.pause(ImageTexture.create_from_image(get_viewport().get_texture().get_image()), $Player.camera, mouse_mode)
		#$Pause.show()
		get_tree().paused = true
