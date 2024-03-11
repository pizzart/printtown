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

func _on_code_edit_text_changed(new_text):
	pass # Replace with function body.

func _on_base_64_edit_text_changed(new_text):
	pass # Replace with function body.

#func save_image():
	#var buffer: PackedByteArray = []
	#for hex in IMAGE:
		#for i in range(8):
			#var bit = (hex & (128 >> i)) >> 7 - i
			#buffer.append(bit * 255)
	#var image = Image.new()
	#image.set_data(32, 32, false, Image.FORMAT_L8, buffer)
	#image.save_png("./image.png")
