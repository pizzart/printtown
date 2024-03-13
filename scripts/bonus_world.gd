extends Node3D

const INTRO_DIALOGUE = preload("res://dialogue/bonus.dialogue")
const END_DIALOGUE = preload("res://dialogue/bonus_end.dialogue")
const PEDESTRIAN = preload("res://scenes/pedestrian.tscn")
const DATA: PackedByteArray = [
	0xfb, 0xc1, 0xd7, 0xbe, 0x8b, 0x53, 0xd1, 0xa2, 0x8b, 0x99, 0x4f, 0xa2, 0x8b, 0x85, 0x3b, 0xa2, 
	0xfb, 0x53, 0x71, 0xbe, 0x02, 0xaa, 0xaa, 0x80, 0xfe, 0x6b, 0x8d, 0xff, 0x4b, 0x60, 0x27, 0xbe, 
	0x95, 0xbb, 0xf3, 0xcb, 0x90, 0x6b, 0xa5, 0x4c, 0xc5, 0xf9, 0x18, 0xeb, 0x60, 0x32, 0x77, 0x80, 
	0x25, 0x2f, 0xdf, 0x5f, 0xf0, 0x79, 0x5a, 0x49, 0x86, 0x23, 0xba, 0x73, 0x73, 0x0e, 0xf9, 0x12, 
	0x3f, 0xdc, 0x8e, 0x8d, 0xea, 0x61, 0x09, 0xea, 0x5d, 0x54, 0xeb, 0x98, 0x0a, 0x56, 0xf7, 0xd4, 
	0x25, 0xe5, 0x34, 0xc2, 0xfb, 0xd4, 0x75, 0x54, 0x94, 0x46, 0x1f, 0xd9, 0x7a, 0x84, 0xd4, 0x00, 
	0xfe, 0x72, 0x20, 0xe5, 0x03, 0x45, 0xd2, 0xab, 0xfb, 0x9c, 0xc8, 0xe2, 0x8a, 0xf9, 0x60, 0x0f, 
	0x8a, 0x41, 0x0d, 0x74, 0x8b, 0x1d, 0xd9, 0xe8, 0xfa, 0x68, 0x9c, 0x98, 0x02, 0xe1, 0x7c, 0x57
]

var timer: float
var mouse_mode = Input.MOUSE_MODE_CAPTURED

@onready var pause_menu = $PauseLayer/Container/SubViewport/PauseMenu

func _ready():
	Global.total_treats = $Collectibles.get_child_count()
	Global.treats = 0
	Global.collected_treats = 0
	
	mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Player.global_position = $PlayerSpawn.global_position
	$Player.can_move = false
	_load_img()
	DialogueUI.start_dialogue(INTRO_DIALOGUE, true)
	await DialogueUI.finished
	$Player.can_move = true
	mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	Global.treat_collected.connect(_on_treat_collected)

func _process(delta):
	timer += delta
	$Overlay/M/Timer.text = get_time_text()
	$Overlay/M/Timer.visible = Global.timer_enabled
	
	if $Player.global_position.y < -40:
		$Player.global_position = $PlayerSpawn.global_position

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

func _load_img():
	var buffer: PackedByteArray = []
	for hex in DATA:
		for i in range(8):
			var bit = (hex & (128 >> i)) >> 7 - i
			buffer.append(bit * 255)
	var image = Image.create_from_data(32, 32, false, Image.FORMAT_L8, buffer)
	#image.set_data(33, 33, false, Image.FORMAT_L8, buffer)
	var texture = ImageTexture.create_from_image(image)
	$Image.texture = texture

func _on_treat_collected():
	if Global.collected_treats == Global.total_treats:
		Global.bonus_visited = true
		mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Player.global_position = $PlayerSpawn.global_position
		$Player.can_move = false
		DialogueUI.start_dialogue(END_DIALOGUE, true)
		await DialogueUI.finished
		get_tree().change_scene_to_file("res://scenes/bonus.tscn")
