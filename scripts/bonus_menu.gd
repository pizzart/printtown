extends Control

var time: float
var can_rotate: bool
@onready var box = $C/View/Cube/Box

func _ready():
	var full_text = ""
	for y in range(20):
		while full_text.split("\n")[y].length() < 80:
			full_text += "bonus "
		full_text += "\n"
	$BG2/Layer/BGText.text = full_text
	if Global.bonus_visited:
		$M/Text/Hint.show()
		$C/View/Cube/Box/Hint.show()

func _process(delta):
	$BG2/Layer.motion_offset += Vector2(delta * 9.0, delta * 10.0)
	
	if not can_rotate:
		box.quaternion = lerp(box.quaternion, Quaternion(0, 0, 0, 1), delta * 5)
	
	time += delta
	$BG/BG.material.set_shader_parameter("shrink", 3.0 + (sin(time) + 1.0) * 3.0)

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
