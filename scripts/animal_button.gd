extends Button

const OUTLINE_MAT = preload("res://misc/outline.tres")
var new_rotation: float = 0.0
var selected: bool
var health: int

func _process(_delta):
	rotation = new_rotation

func add_outline():
	material = OUTLINE_MAT
 
func remove_outline():
	material = null

func update_rotation():
	new_rotation = randf_range(-PI / 4, PI / 4)

func animate():
	$NewAnim.play("default")

func _on_timer_timeout():
	update_rotation()

func _on_mouse_entered():
	add_outline()

func _on_mouse_exited():
	if not selected:
		remove_outline()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if disabled:
				$DisabledSFX.play()
