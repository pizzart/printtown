extends Control

const SPEED_NORMAL = 15.0
const SPEED_FAST = 220.0
var time: float
var can_rotate: bool
var shown_help: bool
var line: int
var scroll_speed: float = SPEED_NORMAL
@onready var box = $C/View/Cube/Box

func _ready():
	var full_text = ""
	for y in range(20):
		while full_text.split("\n")[y].length() < 80:
			full_text += "end "
		full_text += "\n"
	$BG2/Layer/BGText.text = full_text
	
	if Global.bonus_visited:
		$Main/Text/Hint.show()
		$C/View/Cube/Box/Hint.show()
		$Credits.hide()
		$Main.show()
		$C.show()
	else:
		$Credits/CreditsText.text = $Credits/CreditsText.text % [Global.collected_treats, Global.get_time_text()]
		$Credits/CreditsText.position.y = 480.0
		
		await get_tree().create_timer(1).timeout
		$Music.play()

func _process(delta):
	if $Credits.visible:
		if $Credits/CreditsText.position.y > -$Credits/CreditsText.size.y:
			$Credits/CreditsText.position.y -= delta * scroll_speed
		else:
			$Credits.hide()
			if Global.bonus_unlocked:
				$Main.show()
				$C.show()
				var tween = create_tween().set_parallel()
				tween.tween_property($Main, "modulate", Color.WHITE, 1.0).from(Color.TRANSPARENT)
				tween.tween_property($C, "modulate", Color.WHITE, 1.0).from(Color.TRANSPARENT)
	
	$BG2/Layer.motion_offset += Vector2(delta * 9.0, delta * 10.0)
	
	if not can_rotate:
		box.quaternion = lerp(box.quaternion, Quaternion(0, 0, 0, 1), delta * 5)
	
	time += delta
	$BG/BG.material.set_shader_parameter("shrink", 3.0 + (sin(time) + 1.0) * 3.0)

func _input(event):
	if event is InputEventKey:
		if not shown_help:
			shown_help = true
			$Credits/M/Help.show()
	if event.is_action_pressed("skip_dialogue"):
		$Credits/M/Help.hide()
		scroll_speed = SPEED_FAST
	if event.is_action_released("skip_dialogue"):
		scroll_speed = SPEED_NORMAL

func _on_3dview_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.is_pressed():
				can_rotate = true
			if event.is_released():
				can_rotate = false
				
	if event is InputEventMouseMotion:
		if can_rotate:
			var quat = Quaternion(event.relative.y * 0.1, event.relative.x * 0.1, 0, 0) * box.quaternion
			box.quaternion += quat * 0.01
			#box.quaternion = box.quaternion.normalized()

func _on_world_pressed():
	get_tree().change_scene_to_file("res://scenes/bonus_world.tscn")

func _on_quit_pressed():
	get_tree().quit()
