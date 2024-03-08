extends CanvasLayer

signal petted
signal kicked
signal treated
signal stickered

signal stickers_opened
signal stickers_closed

signal healed(animal: Animals.Animal)
signal bitten(animal: Animals.Animal)
signal convinced(animal: Animals.Animal)

signal rps_chosen(choice: Global.RPS)

const ANGRY = preload("res://graphics/ui/fight/stamps/stamp_angry.png")
const NEUTRAL = preload("res://graphics/ui/fight/stamps/stamp_neutral.png")
const HAPPY = preload("res://graphics/ui/fight/stamps/stamp_happy.png")

const ALERT0 = preload("res://graphics/ui/fight/alert/alert0.png")
const ALERT1 = preload("res://graphics/ui/fight/alert/alert1.png")
const ALERT2 = preload("res://graphics/ui/fight/alert/alert2.png")

const RPS_TEXTURES = {
	Global.RPS.ROCK: preload("res://graphics/ui/fight/rps/rock.png"),
	Global.RPS.PAPER: preload("res://graphics/ui/fight/rps/paper.png"),
	Global.RPS.SCISSORS: preload("res://graphics/ui/fight/rps/scissors.png"),
}

const ANIMAL_BTN = preload("res://scenes/animal_button.tscn")

var actual_progress: float
var progress: float
var picked_animal_index: int = -1
#var used_animals: PackedInt32Array = []

@onready var fighter_line = $FighterLine
@onready var friendliness_text = $C/Friendliness
@onready var guard_text = $C/Guard

@onready var pet_btn = $C/Pet
@onready var kick_btn = $C/Kick
@onready var sticker_btn = $C/Sticker
@onready var treat_btn = $C/Treat
@onready var call_btn = $C/Call

@onready var progress_text = $C/Progress
@onready var hp = $C/HealthBG
@onready var health_text = $C/HealthBG/Text
@onready var stamp = $C/Stamp
@onready var guard_icon = $C/AlertBG/Alert
@onready var guard_bg = $C/AlertBG
@onready var hp_alert_bg = $C/HPAlertBG

@onready var main_ui = $C
@onready var rps_ui = $RPS
@onready var sticker_ui = $Stickers

@onready var hand = $Hand
@onready var pet_particles = $PetParticles
@onready var surprise_bite = $SurpriseBite
@onready var pet_count = $Hand/Count

@onready var rps_choose_text = $RPS/Choose
@onready var rps_action = $RPS/Action
@onready var rps_action_text = $RPS/Action/Text
@onready var rock_btn = $RPS/Rock
@onready var paper_btn = $RPS/Paper
@onready var scissors_btn = $RPS/Scissors
@onready var enemy_choice_texture = $RPS/EnemyChoice
@onready var player_choice_texture = $RPS/PlayerChoice
@onready var rps_anim = $RPSAnim

@onready var heal_btn = $Stickers/Heal
@onready var bite_btn = $Stickers/Bite
@onready var convince_btn = $Stickers/Convince
@onready var animal_grid = $Stickers/Grid
@onready var back_btn = $Stickers/Back
@onready var note_bg = $Stickers/Note
@onready var note = $Stickers/Note/Text

@onready var bite_anim = $BiteAnim
@onready var convince_anim = $ConvinceAnim

func _ready():
	hide()

func _process(delta):
	if visible:
		progress = lerpf(progress, actual_progress, delta * 4)
		progress_text.text = "%d%%" % roundf(progress * 100)

func update_satisfaction(_progress: float):
	actual_progress = _progress

func disable_all():
	pet_btn.disabled = true
	kick_btn.disabled = true
	treat_btn.disabled = true
	call_btn.disabled = true
	sticker_btn.disabled = true

func enable_all(can_treat: bool, can_sticker: bool):
	pet_btn.disabled = false
	kick_btn.disabled = false
	treat_btn.disabled = not can_treat
	call_btn.disabled = Global.animals.size() == 0
	#sticker_btn.visible = can_sticker
	if can_sticker and sticker_btn.disabled:
		show_stickerup()
	sticker_btn.disabled = not can_sticker

func show_stickerup():
	sticker_btn.visible = true
	sticker_btn.self_modulate.a = 0
	$C/Sticker/Animation.play("default")
	await $C/Sticker/Animation.animation_finished
	$C/Sticker/Animation.hide()
	sticker_btn.self_modulate.a = 1

func partial_hide():
	pet_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kick_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	treat_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sticker_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(main_ui, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	main_ui.hide()

func unhide():
	main_ui.show()
	var tween = create_tween()
	tween.tween_property(main_ui, "modulate", Color.WHITE, 0.4)
	pet_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	kick_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	treat_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	sticker_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	call_btn.mouse_filter = Control.MOUSE_FILTER_STOP

func update_mood(mood: float):
	var old_texture = stamp.texture
	var new_texture
	if mood < 0.35:
		new_texture = ANGRY
	elif mood < 0.9:
		new_texture = NEUTRAL
	else:
		new_texture = HAPPY
	if old_texture != new_texture:
		$StampAnimation.play("stamp")
		await $StampAnimation.frame_changed
		await $StampAnimation.frame_changed
		stamp.texture = new_texture

func update_guard(guard: float):
	var old_texture = guard_icon.texture
	var new_texture
	if guard < 0.33:
		new_texture = ALERT0
	elif guard < 0.66:
		new_texture = ALERT1
	else:
		new_texture = ALERT2
	if old_texture != new_texture:
		$C/AlertBG/Update.play("default")
		guard_icon.texture = new_texture

func show_rps():
	enemy_choice_texture.hide()
	player_choice_texture.hide()
	rps_choose_text.show()
	rps_ui.modulate.a = 0
	rps_ui.show()
	var tween = create_tween().set_parallel()
	tween.tween_property(rps_ui, "modulate", Color.WHITE, 0.5)
	tween.tween_property(rock_btn, "modulate", Color.WHITE, 0.5)
	tween.tween_property(paper_btn, "modulate", Color.WHITE, 0.5)
	tween.tween_property(scissors_btn, "modulate", Color.WHITE, 0.5)

func hide_rps():
	var tween = create_tween()
	tween.tween_property(rps_ui, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	rps_ui.hide()

func disable_rps():
	rock_btn.disabled = true
	paper_btn.disabled = true
	scissors_btn.disabled = true

func enable_rps():
	rock_btn.disabled = false
	paper_btn.disabled = false
	scissors_btn.disabled = false

func animate_action(player_choice: Global.RPS, enemy_choice: Global.RPS):
	var tween = create_tween().set_parallel()
	tween.tween_property(rock_btn, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_property(paper_btn, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_property(scissors_btn, "modulate", Color(1, 1, 1, 0), 1.0)
	#rock_btn.hide()
	#paper_btn.hide()
	#scissors_btn.hide()
	rps_choose_text.hide()
	
	rps_action_text.text = "rock..."
	rps_action.show()
	await get_tree().create_timer(0.5).timeout
	rps_action_text.text = "paper..."
	await get_tree().create_timer(0.5).timeout
	rps_action_text.text = "scissors..."
	await get_tree().create_timer(0.5).timeout
	rps_action_text.text = "shoot!"
	enemy_choice_texture.texture = RPS_TEXTURES[enemy_choice]
	player_choice_texture.texture = RPS_TEXTURES[player_choice]
	enemy_choice_texture.show()
	player_choice_texture.show()
	await get_tree().create_timer(1.0).timeout
	if enemy_choice == player_choice:
		rps_action_text.text = "tie!"
		await get_tree().create_timer(1.0).timeout
	rps_action.hide()
	#var pick_text = "rock"
	#if choice == Global.RPS.PAPER:
		#pick_text = "paper"
	#elif choice == Global.RPS.SCISSORS:
		#pick_text = "scissors"
	#rps_action_text.text = "my pick: %s" % pick_text

func play_win_anim(winner: Global.RPS):
	enemy_choice_texture.hide()
	player_choice_texture.hide()
	rps_anim.show()
	if winner == 0:
		rps_anim.play("rock_win")
	elif winner == 1:
		rps_anim.play("paper_win")
	else:
		rps_anim.play("scissors_win")
	await get_tree().create_timer(1.0).timeout
	rps_anim.hide()

func show_stickers():
	heal_btn.disabled = true
	bite_btn.disabled = true
	convince_btn.disabled = true
	picked_animal_index = -1

func update_grid():
	for c in animal_grid.get_children():
		c.queue_free()
	for i in range(Global.animals.size()):
		var btn = ANIMAL_BTN.instantiate()
		btn.disabled = Global.animals[i].health <= 0
		btn.pressed.connect(_on_animal_pressed.bind(i))
		btn.mouse_entered.connect(_on_animal_hovered.bind(Global.animals[i]))
		btn.mouse_exited.connect(_on_animal_unhovered)
		btn.icon = Global.animals[i].texture
		animal_grid.add_child(btn)

func add_animal(animal: Animals.Animal):
	var btn = ANIMAL_BTN.instantiate()
	btn.disabled = animal.health <= 0
	btn.icon = animal.texture
	animal_grid.add_child(btn)
	btn.update_rotation()
	btn.animate()

func hide_not_grid():
	back_btn.hide()
	heal_btn.hide()
	bite_btn.hide()
	convince_btn.hide()
	note_bg.hide()

func show_not_grid():
	back_btn.show()
	heal_btn.show()
	bite_btn.show()
	convince_btn.show()
	note_bg.show()

func set_notes(animal: Animals.Animal):
	var text = ""
	
	if animal.convincing > 0.7:
		text = "convincing\n"
	elif animal.convincing < 0.3:
		text = "unconvincing\n"
	
	if animal.damage > 4:
		text += "strong\n"
	elif animal.healing < 2:
		text += "weak\n"
	
	if animal.healing > 5:
		text += "cute\n"
	elif animal.healing < 2:
		text += "ugly\n"
	
	if text == "":
		note.text = "well-rounded"
	else:
		note.text = text

func remove_picked():
	note.text = ""
	animal_grid.get_child(picked_animal_index).selected = false
	animal_grid.get_child(picked_animal_index).remove_outline()
	picked_animal_index = -1

func show_sudden_bite():
	surprise_bite.show()
	await get_tree().create_timer(1.5).timeout
	surprise_bite.hide()

func update_health(health: int):
	if health_text.text != str(health):
		$C/HealthBG/Update.play("default")
	health_text.text = str(health)

func update_enemy_health(bad: bool):
	if bad:
		if not hp_alert_bg.visible:
			$C/HPAlertBG/Update.play("default")
	hp_alert_bg.visible = bad

func show_bite():
	bite_anim.show()
	bite_anim.play("bite")
	await bite_anim.animation_finished
	bite_anim.hide()

func show_convince(success: bool):
	convince_anim.show()
	if success:
		convince_anim.play("success")
	else:
		convince_anim.play("fail")
	await convince_anim.animation_finished
	await get_tree().create_timer(0.5).timeout
	convince_anim.hide()

func _on_animal_pressed(index: int):
	heal_btn.disabled = false
	bite_btn.disabled = false
	convince_btn.disabled = false
	
	animal_grid.get_child(picked_animal_index).selected = false
	animal_grid.get_child(picked_animal_index).remove_outline()
	animal_grid.get_child(index).selected = true
	animal_grid.get_child(index).add_outline()
	
	picked_animal_index = index
	set_notes(Global.animals[index])

func _on_animal_hovered(animal: Animals.Animal):
	if picked_animal_index == -1:
		set_notes(animal)

func _on_animal_unhovered():
	if picked_animal_index == -1:
		note.text = ""

func _on_pet_pressed():
	petted.emit()

func _on_kick_pressed():
	kicked.emit()

func _on_sticker_pressed():
	stickered.emit()

func _on_treat_pressed():
	treated.emit()

func _on_call_pressed():
	partial_hide()
	show_stickers()
	stickers_opened.emit()

func _on_rock_pressed():
	rps_chosen.emit(Global.RPS.ROCK)

func _on_paper_pressed():
	rps_chosen.emit(Global.RPS.PAPER)

func _on_scissors_pressed():
	rps_chosen.emit(Global.RPS.SCISSORS)

func _on_stickers_back_pressed():
	unhide()
	remove_picked()
	sticker_ui.hide()
	stickers_closed.emit()

func _on_heal_pressed():
	healed.emit(Global.animals[picked_animal_index])
	stickers_closed.emit()
	animal_grid.get_child(picked_animal_index).disabled = true
	remove_picked()
	#used_animals.append(picked_animal_index)
	sticker_ui.hide()
	disable_all()
	partial_hide()

func _on_bite_pressed():
	bitten.emit(Global.animals[picked_animal_index])
	stickers_closed.emit()
	animal_grid.get_child(picked_animal_index).disabled = true
	remove_picked()
	#used_animals.append(picked_animal_index)
	sticker_ui.hide()
	disable_all()
	partial_hide()

func _on_convince_pressed():
	convinced.emit(Global.animals[picked_animal_index])
	stickers_closed.emit()
	animal_grid.get_child(picked_animal_index).disabled = true
	remove_picked()
	#used_animals.append(picked_animal_index)
	sticker_ui.hide()
	disable_all()
	partial_hide()

func _on_treat_mouse_entered():
	$C/Treat/TreatCount.show()
	$C/Treat/TreatCount/Text.text = str(Global.treats)

func _on_treat_mouse_exited():
	$C/Treat/TreatCount.hide()
