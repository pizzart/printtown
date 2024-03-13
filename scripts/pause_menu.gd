extends Node3D

enum Arrow {
	None,
	Minute,
	Hour,
}
const DIARY_TEXT = """
dear diary,
today was a strange day
i was asked to sign a contract in
which i had to climb on top of a
giraffe to graffiti the largest
building in town.

i collected %s treats
i got %s pets
"""
const TITLE_TEXT = """
%s's
 diary / sketchbook
"""
const HIGHLIGHT_COLOR = Color(0.9, 0.5, 0.6)
var game_camera: Camera3D
var mouse_mode: Input.MouseMode
var can_unpause: bool
var holding_arrow: Arrow = Arrow.None
var prev_angle: float

@onready var paused_text = $Book/Main/PausedText
@onready var name_text = $Book/Closed/NameText
@onready var camera = $Camera
@onready var book = $Book
#@onready var book_closed = $BookClosed
@onready var unpause_btn = $UI/MainUI/Unpause
@onready var quit_btn = $UI/MainUI/Quit

@onready var main_ui = $UI/MainUI
@onready var options_ui = $UI/OptionsUI
@onready var closed_ui = $UI/ClosedUI

@onready var main_book = $Book/Main
@onready var closed_book = $Book/Closed
@onready var options_book = $Book/Options

# small = music, big = sfx
@onready var arrow_small = $Book/Options/Clock/ArrowSmall
@onready var arrow_big = $Book/Options/Clock/ArrowBig
@onready var vol_text = $Book/Options/Clock/Volume

func _ready():
	var datetime = Time.get_datetime_dict_from_system()
	paused_text.text = "%02d/%02d/%s" % [datetime["day"], datetime["month"], datetime["year"] % 100]
	name_text.text = TITLE_TEXT % Global.player_name
	arrow_small.rotation.y = snappedf(db_to_linear(AudioServer.get_bus_volume_db(1)) * PI*2 + 2*PI/3, PI/6)
	arrow_big.rotation.y = snappedf(db_to_linear(AudioServer.get_bus_volume_db(2)) * PI*2 + 2*PI/3, PI/6)
	update_volume()

func update_volume():
	vol_text.text = "%02d:%02d" % [ceili(db_to_linear(AudioServer.get_bus_volume_db(2)) * 11), ceili(db_to_linear(AudioServer.get_bus_volume_db(1)) * 11) * 5]

func _input(event):
	if event.is_action_pressed("pause"):
		if can_unpause and main_ui.visible:
			unpause()
	
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.is_pressed():
				if options_book.visible:
					var dist = camera.unproject_position($Book/Options/Clock.global_position).distance_to(get_viewport().get_mouse_position())
					if dist < 40:
						holding_arrow = Arrow.Hour
						arrow_small.modulate = HIGHLIGHT_COLOR
					elif dist < 80:
						holding_arrow = Arrow.Minute
						arrow_big.modulate = HIGHLIGHT_COLOR
					else:
						holding_arrow = Arrow.None
			if event.is_released():
				holding_arrow = Arrow.None
	
	if event is InputEventMouseMotion:
		if options_book.visible:
			if holding_arrow != Arrow.None:
				var angle: float = camera.unproject_position($Book/Options/Clock.global_position).direction_to(get_viewport().get_mouse_position()).angle() - camera.rotation.y
				var snap_angle: float = snappedf(-angle, PI / 6)
				var volume_angle: float = -(snap_angle - PI / 2 if snap_angle - PI / 2 <= 0 else snap_angle - PI / 2 - PI * 2) / (PI * 2)
				if prev_angle != volume_angle:
					$ClockSFX.play()
				if holding_arrow == Arrow.Minute:
					arrow_big.rotation.y = snap_angle
					AudioServer.set_bus_volume_db(1, linear_to_db(volume_angle))
				else:
					arrow_small.rotation.y = snap_angle
					AudioServer.set_bus_volume_db(2, linear_to_db(volume_angle))
				prev_angle = volume_angle
				update_volume()
			else:
				var dist = camera.unproject_position($Book/Options/Clock.global_position).distance_to(get_viewport().get_mouse_position())
				var adj = clampf((140.0 - dist) / 80.0, 0.0, 1.0)
				var col = Color(adj * 0.2, adj * 0.3, adj * 0.8)
				$Book/Options/Clock/BG.modulate = col
				arrow_big.modulate = col
				arrow_small.modulate = col

func pause(texture: ImageTexture, _game_camera: Camera3D, _mouse_mode: Input.MouseMode, timer: String):
	game_camera = _game_camera
	mouse_mode = _mouse_mode
	#$Camera.make_current()
	$Book/Main/DiaryText.text = DIARY_TEXT % [Global.collected_treats, Global.animals.size()]
	$Book/Main/GameTexture.texture = texture
	$Book/Main/TimerText.text = timer
	camera.global_transform = $ZoomPoint.global_transform
	var tween = create_tween()
	tween.tween_property(camera, "global_transform", $ZoomOutPoint.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	can_unpause = true
	unpause_btn.disabled = false
	#quit_btn.disabled = false

func unpause():
	unpause_btn.disabled = true
	#quit_btn.disabled = true
	can_unpause = false
	#$Camera.global_transform = $ZoomOutPoint.global_transform
	var tween = create_tween()
	tween.tween_property(camera, "global_transform", $ZoomPoint.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished
	Input.mouse_mode = mouse_mode
	#game_camera.make_current()
	AudioServer.set_bus_effect_enabled(2, 0, false) # lp filter
	get_parent().get_parent().get_parent().hide()
	get_tree().paused = false

func _on_unpause_pressed():
	unpause()

func _on_quit_pressed():
	$FlipSFX.play()
	main_ui.hide()
	main_book.hide()
	
	book.play("close")
	await book.animation_finished
	
	closed_book.show()
	closed_ui.show()

func _on_back_closed_pressed():
	$FlipSFX.play()
	closed_book.hide()
	closed_ui.hide()
	
	book.play("open")
	await book.animation_finished
	
	main_ui.show()
	main_book.show()

func _on_quit_closed_pressed():
	get_tree().quit()

func _on_options_pressed():
	$FlipSFX.play()
	main_ui.hide()
	main_book.hide()
	
	book.play("open")
	await book.animation_finished
	
	options_book.show()
	options_ui.show()

func _on_back_options_pressed():
	$FlipSFX.play()
	options_book.hide()
	options_ui.hide()
	
	book.play("open")
	await book.animation_finished
	
	main_ui.show()
	main_book.show()

func _on_timer_pressed():
	Global.timer_enabled = not Global.timer_enabled
	$Book/Main/TimerText.visible = Global.timer_enabled
	if Global.timer_enabled:
		$Book/Options/TimerPin.play("selected")
	else:
		$Book/Options/TimerPin.play("deselected")
	$SelectSFX.play()

func _on_ca_pressed():
	Global.ca_enabled = not Global.ca_enabled
	RenderingServer.global_shader_parameter_set("ca_enabled", Global.ca_enabled)
	if Global.ca_enabled:
		$Book/Options/CAPin.play("selected")
	else:
		$Book/Options/CAPin.play("deselected")
	$SelectSFX.play()

func _on_fs_pressed():
	if get_window().mode == Window.MODE_FULLSCREEN:
		get_window().mode = Window.MODE_WINDOWED
		$Book/Options/FSPin.play("deselected")
	else:
		get_window().mode = Window.MODE_FULLSCREEN
		$Book/Options/FSPin.play("selected")
	$SelectSFX.play()

func _on_quit_closed_mouse_entered():
	$Book/Closed/AskText.show()

func _on_quit_closed_mouse_exited():
	$Book/Closed/AskText.hide()
