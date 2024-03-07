extends CanvasLayer

signal voice_stopped

const ALLOWED_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"
const FAKE_NOTICE = "© 2024 PIZZART ENTERTAINMENT LLC."
const HUM_VOL = -35

var pressed: bool
var intro_voice_playing: bool = true
var current_voice: AudioStreamPlayer
var current_rotation: Quaternion = Quaternion(0, 0, 0, 1).normalized()
var box_can_spin: bool
var time: float
var can_rotate: bool

@onready var box = $UI/UI/C/View/Cube/Box
@onready var notice = $UI/UI/M/Text/Notice
@onready var hidden = $UI/UI/M/Text/Hidden
@onready var name_edit = $UI/UI/M/Name/NameEdit
@onready var done_btn = $UI/UI/M/Name/Done

func _ready():
	var file = FileAccess.open("res://misc/lines.txt", FileAccess.READ)
	var content = file.get_as_text(true)
	var lines = content.split("\n")
	var full_text = ""
	for y in range(20):
		while full_text.split("\n")[y].length() < 80:
			full_text += lines[randi() % lines.size()] + " "
		full_text += "\n"
	$BG/Layer/BGText.text = full_text
	
	$UI/UI/M/Buttons.hide()
	$UI/UI/C.hide()
	$BlackOverlay/Color.show()
	
	await get_tree().create_timer(1.0)
	
	$IntroVoice.play()
	intro_voice_playing = true
	var tween = create_tween()
	tween.tween_property($BlackOverlay/Color, "color", Color(0, 0, 0, 0), 1.345)
	await tween.finished
	
	#$UI/UI/M/Buttons.show()
	box.rotation.y = PI * 9
	tween = create_tween()
	tween.tween_property(box, "rotation", Vector3(0, 0, 0), 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	$UI/UI/C.show()
	
	notice.text = "PIZZART"
	await get_tree().create_timer(0.8).timeout
	notice.text = "PIZZART ENTERTAINMENT"
	await get_tree().create_timer(1.0).timeout
	notice.text = "PIZZART ENTERTAINMENT LLC."
	$UI/UI/M/Buttons.show()
	
	await get_tree().create_timer(1.5).timeout
	box_can_spin = true
	hidden.show()
	notice.text = FAKE_NOTICE
	tween = create_tween()
	tween.tween_property($BGHum, "volume_db", HUM_VOL, 3.0)
	intro_voice_playing = false
	
	await get_tree().create_timer(3.0).timeout
	$UI/UI/Tip.show()

func _process(delta):
	$BG/Layer.motion_offset += Vector2(delta * 9.0, delta * 10.0)
	if box_can_spin and not can_rotate:
		box.quaternion = lerp(box.quaternion, current_rotation, delta * 5)
	
	time += delta
	$Color/BG.material.set_shader_parameter("shrink", 3.0 + (sin(time) + 1.0) * 3.0)

func _input(event):
	if event.is_action_pressed("pause"):
		if $UI/UI/M/Name.visible:
			$UI/UI/M/Name.hide()
			$UI/UI/M/Buttons.show()
			current_rotation = Quaternion(0, 0, 0, 1).normalized()

func play_voice(voice_node: AudioStreamPlayer):
	if current_voice != null:
		current_voice.stop()
	current_voice = voice_node
	voice_node.play()
	await voice_node.finished
	current_voice = null
	voice_stopped.emit()

func _on_start_mouse_entered():
	current_rotation = Quaternion(0, 0, 0, 1).normalized()
	if intro_voice_playing or current_voice == $StartVoice:
		return
	play_voice($StartVoice)

func _on_quit_mouse_entered():
	current_rotation = Quaternion(0, 1, 0, 0).normalized()
	if intro_voice_playing or current_voice == $QuitVoice:
		return
	play_voice($QuitVoice)

func _on_start_pressed():
	if pressed:
		return
	#pressed = true
	
	$UI/UI/M/Buttons.hide()
	$UI/UI/M/Name.show()
	
	current_rotation = Quaternion(PI / 2, 0, 0, PI / 2).normalized()
	
	if current_voice != null or intro_voice_playing:
		await voice_stopped
	
	play_voice($NameVoice)

func _on_quit_pressed():
	if pressed:
		return
	
	if intro_voice_playing:
		pressed = true
		await voice_stopped
	
	get_tree().quit()

func _on_name_edit_text_changed(new_text):
	for char in new_text:
		if not char in ALLOWED_CHARS:
			name_edit.text = new_text.replace(char, "")
	done_btn.disabled = name_edit.text.is_empty()

func _on_done_pressed():
	Global.player_name = name_edit.text.strip_edges() # just in case
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_done_mouse_entered():
	current_rotation = Quaternion(0, -PI / 2, 0, PI / 2).normalized()
	if intro_voice_playing:
		return
	
	play_voice($DoneVoice)

func _on_done_mouse_exited():
	current_rotation = Quaternion(PI / 2, 0, 0, PI / 2).normalized()

func _on_credits_pressed():
	$UI/UI/M/Credits.show()
	$UI/UI/M/Buttons.hide()

func _on_credits_mouse_entered():
	current_rotation = Quaternion(-PI / 2, 0, 0, PI / 2).normalized()

func _on_done_credits_pressed():
	$UI/UI/M/Credits.hide()
	$UI/UI/M/Buttons.show()
	current_rotation = Quaternion(0, 0, 0, 1).normalized()

func _on_sound_value_changed(value):
	AudioServer.set_bus_volume_db(1, linear_to_db(value / 11))

func _on_music_value_changed(value):
	AudioServer.set_bus_volume_db(2, linear_to_db(value / 11))

func _on_3dview_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			$UI/UI/Tip.hide()
			if event.is_pressed():
				can_rotate = true
			if event.is_released():
				can_rotate = false
				
	if event is InputEventMouseMotion:
		if can_rotate:
			var quat = Quaternion(event.relative.y * 0.1, event.relative.x * 0.1, 0, 0) * box.quaternion
			box.quaternion += quat * 0.01
			#box.quaternion = box.quaternion.normalized()
