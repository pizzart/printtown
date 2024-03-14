extends Control

const DIALOGUE = preload("res://dialogue/finale/ending.dialogue")

func _ready():
	get_tree().paused = false
	MiscUI.hide_bars()
	await get_tree().create_timer(1.0).timeout
	DialogueUI.start_dialogue(DIALOGUE, false)
	await DialogueUI.finished
	await get_tree().create_timer(1.5).timeout
	MiscUI.slow_transition(3.0, 3.0)
	await MiscUI.transitioned
	get_tree().change_scene_to_file("res://scenes/bonus.tscn")
