extends Area3D

const TUTORIAL_DIALOGUE = preload("res://dialogue/collectable_tutorial.dialogue")
var time: float
static var tutorial_given: bool = OS.is_debug_build()

func _ready():
	$Mesh.rotation.x = randf_range(-PI, PI)
	$Mesh.rotation.y = randf_range(-PI, PI)
	$Mesh.rotation.z = randf_range(-PI, PI)

func _process(delta):
	time += delta
	$Mesh.rotation.y = time * 0.7
	$Mesh.rotation.x = sin(time * 1.5) * 0.5
	$Mesh.position.y = cos(time * 3.0) * 0.3

func _on_area_entered(area):
	if area.is_in_group("player_collect"):
		set_deferred("monitoring", false)
		
		if not tutorial_given:
			tutorial_given = true
			area.get_parent().sprite.play("idle_back")
			area.get_parent().can_move = false
			DialogueUI.start_dialogue(TUTORIAL_DIALOGUE, true)
			await DialogueUI.finished
			area.get_parent().can_move = true
		
		Global.treats += 1
		Global.treat_collected.emit()
		$Mesh.top_level = true
		$Sphere.mesh = $Sphere.mesh.duplicate(true)
		var tween = create_tween().set_parallel()
		#tween.tween_property(self, "scaAle", Vector3.ZERO, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property($Mesh, "global_position", global_position + Vector3(0, 100, 0), 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_method(set_explosion_progress, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		await tween.finished
		queue_free()

func set_explosion_progress(progress: float):
	$Sphere.mesh.material.set_shader_parameter("explosion_progress", progress)
