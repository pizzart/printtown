extends Area3D

#signal won
#signal lost
signal pets_started
signal pets_ended

const PET_TUTORIAL = preload("res://dialogue/tutorial_fight/tutorialfight_pet.dialogue")

const CAMERA_FOV = 45.0
const SHAKE_REDUCE = 7.0

const SPIN_SPEED = 0.3
const SPIN_OFFSET = PI * 2 / 3
const SPIN_RAD = 135.0
const TEXT_SPIN_RAD = 75.0
const TEXT_SPIN_SPEED = 0.8

const INIT_HEALTH = 10

const BAD_PETS = 5000.0
const OK_PETS = 8000.0
const GOOD_PETS = 15000.0

var player: Player
var enemy: Animals.Animal
var health: int = INIT_HEALTH
var fight_active: bool
var time: float
var shake: float

var petting: bool
var pets_given: float
var pet_awaiting: bool
var pet_tutorial_given: bool

@export var animal: Animals.AnimalType
@export var dialogue_start: DialogueResource
@export var dialogue_big_progress: DialogueResource
@export var dialogue_won: DialogueResource
@export var dialogue_lost: DialogueResource
@export var dialogue_kicked: DialogueResource
@export var is_tutorial: bool
@onready var camera = $CameraPoint/Camera

func _process(delta):
	if fight_active:
		time += delta
		
		var cam_unproj = camera.unproject_position($AnimalPoint.global_position)
		var cam_unproj_player = camera.unproject_position($PlayerPoint.global_position)
		FightUI.pet_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED), sin(-time * SPIN_SPEED)) * SPIN_RAD
		FightUI.kick_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED + SPIN_OFFSET), sin(-time * SPIN_SPEED + SPIN_OFFSET)) * SPIN_RAD
		FightUI.treat_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED - SPIN_OFFSET), sin(-time * SPIN_SPEED - SPIN_OFFSET)) * SPIN_RAD
		FightUI.progress_text.position = cam_unproj + Vector2(cos(cos(-time * TEXT_SPIN_SPEED) - PI / 2), sin(cos(-time * TEXT_SPIN_SPEED) - PI / 2)) * TEXT_SPIN_RAD
		FightUI.friendliness_text.position = cam_unproj + Vector2(cos(sin(-time * TEXT_SPIN_SPEED) + PI / 2), sin(sin(-time * TEXT_SPIN_SPEED) + PI / 2)) * TEXT_SPIN_RAD
		FightUI.health_text.position = cam_unproj_player + Vector2(cos(sin(-time * TEXT_SPIN_SPEED) + PI / 2), sin(sin(-time * TEXT_SPIN_SPEED) + PI / 2)) * TEXT_SPIN_RAD
		FightUI.fighter_line.points[0] = cam_unproj
		FightUI.fighter_line.points[1] = FightUI.progress_text.position + Vector2(16, 34)
		FightUI.stamp.position = cam_unproj + Vector2(-86, 12)
		FightUI.guard_icon.position = cam_unproj + Vector2(-32, -80)
		
		FightUI.rock_btn.position = cam_unproj + Vector2(cos(cos(time * SPIN_SPEED) - PI / 4), sin(cos(time * SPIN_SPEED) - PI / 4)) * SPIN_RAD
		FightUI.paper_btn.position = cam_unproj + Vector2(cos(cos(time * SPIN_SPEED) - PI / 2), sin(cos(time * SPIN_SPEED) - PI / 2)) * SPIN_RAD
		FightUI.scissors_btn.position = cam_unproj + Vector2(cos(cos(time * SPIN_SPEED) - 3 * PI / 4), sin(cos(time * SPIN_SPEED) - 3 * PI / 4)) * SPIN_RAD
		
		camera.h_offset = randfn(0, shake)
		camera.v_offset = randfn(0, shake)
		
		shake = lerpf(shake, 0, delta * SHAKE_REDUCE)

func _input(event):
	if event.is_action_pressed("pet"):
		if pet_awaiting:
			pet_awaiting = false
			pets_started.emit()
			FightUI.hand.position = get_viewport().get_mouse_position()
	if event is InputEventMouseMotion:
		if petting or pet_awaiting:
			FightUI.hand.position = get_viewport().get_mouse_position()
		if petting:
			FightUI.pet_particles.position = get_viewport().get_mouse_position()
			pets_given += event.relative.length()
			add_shake(0.001)

func _on_body_entered(body):
	if body is Player:
		set_deferred("monitoring", false)
		
		get_parent().mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		player = body
		player.prepare_fight()
		
		camera.fov = player.camera.fov
		camera.global_transform = player.camera.global_transform
		camera.make_current()
		var tween = create_tween().set_parallel()
		tween.tween_property(camera, "transform", Transform3D(), 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(camera, "fov", CAMERA_FOV, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property($Animal, "global_position", $AnimalPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		FightUI.show()
		if dialogue_start != null:
			FightUI.disable_all()

		FightUI.petted.connect(_on_petted)
		FightUI.kicked.connect(_on_kicked)
		FightUI.treated.connect(_on_treated)
		FightUI.stickered.connect(_on_stickered)
		
		enemy = Animals.animals[animal].new()
		
		fight_active = true
		if dialogue_start != null:
			DialogueUI.start_dialogue(dialogue_start, true)
			await DialogueUI.finished
			FightUI.enable_all(Global.treats, false)
		
		update_ui()
		#FightUI.crect.position = camera.unproject_position($AnimalPoint.global_position)

func add_shake(amount: float):
	shake += amount

func update_ui():
	FightUI.set_progress(enemy.satisfaction)
	FightUI.friendliness_text.text = "mood: %d%%" % (enemy.mood * 100)
	#FightUI.guard_text.text = "guard: %d%%" % (enemy.guard * 100)
	FightUI.health_text.text = str(health)
	FightUI.change_mood(enemy.mood)
	FightUI.change_guard(enemy.guard)
	#FightUI.treat_btn.disabled = Global.treats == 0

func apply_damage(damage: int):
	health = maxi(health - damage, 0)
	update_ui()
	if health <= 0:
		FightUI.disable_all()
		DialogueUI.start_dialogue(dialogue_lost, false)
		await DialogueUI.finished
		if is_tutorial:
			enemy = Animals.animals[animal].new()
			health = INIT_HEALTH
			enemy.health = enemy.init_health
			update_ui()
			FightUI.enable_not_sticker()
		else:
			FightUI.hide()
			fight_active = false

func is_satisfied():
	return enemy.satisfaction >= enemy.SATISFACTION_MIN

func _on_petted():
	var tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", $CameraInteractPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerInteractPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	FightUI.disable_all()
	
	if is_tutorial and not pet_tutorial_given:
		DialogueUI.start_dialogue(PET_TUTORIAL, false)
		await DialogueUI.finished
		pet_tutorial_given = true

	FightUI.partial_hide()
	FightUI.hand.show()
	#FightUI.pet_particles.restart()
	FightUI.pet_particles.emitting = false
	
	var will_bite = randf() < enemy.guard * 0.4
	
	pet_awaiting = true
	await pets_started
	FightUI.pet_particles.emitting = true
	petting = true
	
	#FightUI.pet_particles.restart()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	await get_tree().create_timer(randf_range(1.0, 2.0) if will_bite else 3.0).timeout
	petting = false
	
	print("your score: %s" % pets_given)
	
	FightUI.hand.hide()
	FightUI.pet_particles.emitting = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", $CameraPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	if will_bite:
		var animal_tween = create_tween()
		animal_tween.tween_property($Animal, "global_position", $AnimalBitePoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		animal_tween.tween_interval(0.2)
		animal_tween.tween_callback(add_shake.bind(0.08))
		animal_tween.tween_interval(0.4)
		animal_tween.tween_property($Animal, "global_position", $AnimalPoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await animal_tween.finished
		
		enemy.add_mood(0.08 + randfn(0, 0.01))
		enemy.add_satisfaction(0.01 + randfn(0, 0.01))
		enemy.add_guard(-0.05 + randfn(0, 0.01))
		apply_damage(enemy.damage / 2)
	else:
		if pets_given < BAD_PETS:
			enemy.add_mood(0.05 + randfn(0, 0.02))
			enemy.add_satisfaction(0.1 + randfn(0, 0.02))
			enemy.add_guard(-0.02 + randfn(0, 0.01))
		elif pets_given < OK_PETS:
			enemy.add_mood(0.15 + randfn(0, 0.02))
			enemy.add_satisfaction(0.2 + randfn(0, 0.03))
			enemy.add_guard(-0.04 + randfn(0, 0.01))
		elif pets_given < GOOD_PETS:
			enemy.add_mood(0.2 + randfn(0, 0.02))
			enemy.add_satisfaction(0.25 + randfn(0, 0.03))
			enemy.add_guard(-0.05 + randfn(0, 0.01))
		else:
			enemy.add_mood(0.25 + randfn(0, 0.02))
			enemy.add_satisfaction(0.3 + randf_range(0, 0.04))
			enemy.add_guard(-0.07 + randfn(0, 0.01))
	
	update_ui()
	
	FightUI.enable_all(Global.treats, is_satisfied())
	FightUI.unhide()
	
	pets_given = 0
	
	if enemy.satisfaction >= enemy.SATISFACTION_MIN:
		if dialogue_big_progress != null:
			FightUI.disable_all()
			DialogueUI.start_dialogue(dialogue_big_progress, false)
			await DialogueUI.finished
		if is_tutorial:
			FightUI.disable_all()
			FightUI.sticker_btn.disabled = false
		else:
			FightUI.enable_all(Global.treats, true)

func _on_kicked():
	var tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", $CameraInteractPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerInteractPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	FightUI.disable_all()
	FightUI.rps_choose_text.text = "choose!"
	FightUI.show_rps()
	FightUI.enable_rps()
	FightUI.partial_hide()
	
	var player_choice = await FightUI.rps_chosen
	FightUI.disable_rps()
	var enemy_choice = (player_choice + 1) % 3 if randf() < enemy.guard * 0.5 else randi_range(0, 2)
	FightUI.animate_action(enemy_choice)
	await get_tree().create_timer(1.5).timeout
	
	if (player_choice + 1) % 3 == enemy_choice: # enemy won
		tween = create_tween().set_parallel()
		tween.tween_property(camera, "global_transform", $CameraPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
		
		var animal_tween = create_tween()
		animal_tween.tween_property($Animal, "global_position", $AnimalBitePoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		animal_tween.tween_interval(0.2)
		animal_tween.tween_callback(add_shake.bind(0.08))
		animal_tween.tween_interval(0.4)
		animal_tween.tween_property($Animal, "global_position", $AnimalPoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await animal_tween.finished
		
		enemy.add_mood(0.025)
		enemy.add_satisfaction(0.05)
		enemy.add_guard(-0.1)
		apply_damage(enemy.damage)
	elif (enemy_choice + 1) % 3 == player_choice: # player won
		enemy.add_mood(-0.05)
		enemy.add_satisfaction(-0.03)
		enemy.add_guard(-0.3)
		enemy.health -= 1
		
		tween = create_tween().set_parallel()
		tween.tween_property(camera, "global_transform", $CameraPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
	else: # tie
		tween = create_tween().set_parallel()
		tween.tween_property(camera, "global_transform", $CameraPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
		
		enemy.add_satisfaction(0.01)
		enemy.add_guard(-0.05)
	#var damage = enemy.kick()
	update_ui()
	
	FightUI.hide_rps()
	
	if enemy.health <= 0:
		FightUI.disable_all()
		if dialogue_kicked:
			DialogueUI.start_dialogue(dialogue_kicked, false)
			await DialogueUI.finished
		if is_tutorial:
			FightUI.disable_all()
			FightUI.sticker_btn.disabled = false
		else:
			FightUI.enable_all(Global.treats, true)
	
	FightUI.enable_all(Global.treats, is_satisfied())
	FightUI.unhide()
	
	#if damage != 0:
		#add_shake(0.08)
		#apply_damage(damage)

func _on_treated():
	#TODO: only if there are treats
	enemy.treat()
	update_ui()

func _on_stickered():
	if enemy.sticker():
		FightUI.disable_all()
		DialogueUI.start_dialogue(dialogue_won, false)
		await DialogueUI.finished
		
		FightUI.hide()
		fight_active = false
		
		get_parent().mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		var tween = create_tween().set_parallel()
		tween.tween_property(camera, "global_transform", player.camera.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(camera, "fov", player.camera.fov, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		player.post_fight()
