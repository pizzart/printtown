class_name FightArea
extends Area3D

#signal won
#signal lost
signal pets_started
signal pets_ended
signal fight_finished

const PET_TUTORIAL = preload("res://dialogue/tutorial_fight/tutorialfight_pet.dialogue")
const KICK_TUTORIAL = preload("res://dialogue/tutorial_fight/tutorialfight_kick.dialogue")
const LOWHP_TUTORIAL = preload("res://dialogue/tutorial_fight/tutorialfight_lowhp.dialogue")
const TREAT_TUTORIAL = preload("res://dialogue/tutorial_fight/tutorialfight_treat.dialogue")
const GAVE_UP_TUTORIAL = preload("res://dialogue/tutorial_fight/tutorialfight_gaveup.dialogue")
const STICKER_TUTORIAL = preload("res://dialogue/tutorial_fight/tutorialfight_stickers.dialogue")

const CAMERA_FOV = 45.0
const SHAKE_REDUCE = 7.0

const SPIN_SPEED = 0.3
const SPIN_OFFSET = PI * 2.0 / 3.0
const SPIN_RAD = 135.0
const TEXT_SPIN_RAD = 75.0
const TEXT_SPIN_SPEED = 0.8

const INIT_HEALTH = 8
const TREAT_COOLDOWN = 3

const BAD_PETS = 5000.0
const OK_PETS = 8000.0
const GOOD_PETS = 15000.0

var can_activate: bool
var fight_active: bool
var player: Player
var enemy: Animals.Animal
var health: int = INIT_HEALTH
var time: float
var shake: float
#var treat_cooldown: int = 0
var death_count: int = 0

var petting: bool
var pets_given: float
var pet_awaiting: bool

static var pet_tutorial_given: bool = OS.is_debug_build()
static var kick_tutorial_given: bool = OS.is_debug_build()
static var treat_tutorial_given: bool = OS.is_debug_build()
static var low_hp_tutorial_given: bool = false
static var gave_up_tutorial_given: bool = false
static var sticker_tutorial_given: bool = false

@export var animal: Animals.AnimalType
@export var next_fight: FightArea

# this is kind of a mess tbh
@export var dialogue_pre: DialogueResource
@export var dialogue_start: DialogueResource
@export var dialogue_big_progress: DialogueResource
@export var dialogue_won: DialogueResource
@export var dialogue_lost: DialogueResource
@export var dialogue_lost2: DialogueResource
@export var dialogue_kicked: DialogueResource

@export var is_tutorial: bool
@export var is_finale: bool
@export var init_enabled: bool
#@export var animation_player: AnimationPlayer
#@export var animation_name: String
@onready var camera = $CameraPoint/Camera
@onready var book = $StickerbookPoint/Book

func _ready():
	$Animal.texture = Animals.animals[animal].TEXTURE
	$Animal.offset.y = Animals.animals[animal].TEXTURE.get_height() / 2 - 256
	
	if init_enabled:
		set_deferred("monitoring", true)
		show()
	else:
		set_deferred("monitoring", false)
		hide()

func _process(delta):
	if not fight_active:
		return
	
	time += delta
	# and this is just terrible lmao. so many sin and cos
	var cam_unproj = camera.unproject_position($AnimalPoint.global_position)
	if FightUI.main_ui.visible:
		var cam_unproj_player = camera.unproject_position($PlayerPoint.global_position)
		FightUI.pet_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED), sin(-time * SPIN_SPEED)) * SPIN_RAD
		FightUI.kick_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED + SPIN_OFFSET), sin(-time * SPIN_SPEED + SPIN_OFFSET)) * SPIN_RAD
		FightUI.treat_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED - SPIN_OFFSET), sin(-time * SPIN_SPEED - SPIN_OFFSET)) * SPIN_RAD
		FightUI.progress_text.position = cam_unproj + Vector2(cos(cos(-time * TEXT_SPIN_SPEED) - PI / 2), sin(cos(-time * TEXT_SPIN_SPEED) - PI / 2)) * TEXT_SPIN_RAD
		
		FightUI.stamp.position = cam_unproj + Vector2(-86, 12)
		FightUI.guard_bg.position = cam_unproj + Vector2(-20, -70)
		FightUI.hp_alert_bg.position = cam_unproj + Vector2(40, 0) + Vector2(cos(cos(-time * TEXT_SPIN_SPEED) / PI - PI / 2), sin(cos(-time * TEXT_SPIN_SPEED) / PI - PI / 2)) * TEXT_SPIN_RAD
		
		FightUI.call_btn.position = cam_unproj_player - Vector2(32, 0) + Vector2(cos(time * SPIN_SPEED), sin(time * SPIN_SPEED)) * TEXT_SPIN_RAD
		FightUI.hp.position = cam_unproj_player - Vector2(0, 64) + Vector2(cos(sin(-time * TEXT_SPIN_SPEED) - PI / 2), sin(sin(-time * TEXT_SPIN_SPEED) - PI / 2)) * TEXT_SPIN_RAD
		
		#FightUI.friendliness_text.position = cam_unproj + Vector2(cos(sin(-time * TEXT_SPIN_SPEED) + PI / 2), sin(sin(-time * TEXT_SPIN_SPEED) + PI / 2)) * TEXT_SPIN_RAD
		#FightUI.fighter_line.points[0] = cam_unproj
		#FightUI.fighter_line.points[1] = FightUI.progress_text.position + Vector2(16, 34)
	
	if FightUI.rps_ui.visible:
		var cam_unproj_player_interact = camera.unproject_position(player.global_position)
		var cam_unproj_animal = camera.unproject_position($Animal.global_position)
		FightUI.rock_btn.position = cam_unproj + Vector2(cos(cos(time * SPIN_SPEED) - PI / 4), sin(cos(time * SPIN_SPEED) - PI / 4)) * SPIN_RAD
		FightUI.paper_btn.position = cam_unproj + Vector2(cos(cos(time * SPIN_SPEED) - PI / 2), sin(cos(time * SPIN_SPEED) - PI / 2)) * SPIN_RAD
		FightUI.scissors_btn.position = cam_unproj + Vector2(cos(cos(time * SPIN_SPEED) - 3 * PI / 4), sin(cos(time * SPIN_SPEED) - 3 * PI / 4)) * SPIN_RAD
		
		FightUI.enemy_choice_texture.position = cam_unproj_animal - Vector2(64, 64)
		FightUI.player_choice_texture.position = cam_unproj_player_interact
		FightUI.rps_anim.position = cam_unproj_player_interact + Vector2(128, 128)
	
	if FightUI.sticker_ui.visible:
		var cam_unproj_book = camera.unproject_position($StickerbookPoint.global_position)
		FightUI.sticker_ui.position = cam_unproj_book - Vector2(320, 240)
		#FightUI.heal_btn.position = cam_unproj_book + Vector2(64, 0)
		#FightUI.bite_btn.position = cam_unproj_book + Vector2(64, 60)
		#FightUI.convince_btn.position = cam_unproj_book + Vector2(64, 120)
	
	if FightUI.bite_anim.visible:
		FightUI.bite_anim.position = camera.unproject_position($Animal.global_position)
	if FightUI.convince_anim.visible:
		FightUI.convince_anim.position = camera.unproject_position($Animal.global_position) - Vector2(16, 48)
	
	camera.h_offset = randfn(0, shake)
	camera.v_offset = randfn(0, shake)
	
	shake = lerpf(shake, 0, delta * SHAKE_REDUCE)

func _input(event):
	if not fight_active:
		if event.is_action_pressed("interact") and can_activate:
			activate_fight()
	else:
		if event.is_action_pressed("pet"):
			if pet_awaiting:
				pet_awaiting = false
				pets_started.emit()
				FightUI.hand.position = get_viewport().get_mouse_position()
				FightUI.pet_particles.position = get_viewport().get_mouse_position()
				FightUI.pet_stat.show()
				FightUI.set_pet_stat("BAD")
		if event is InputEventMouseMotion:
			if petting or pet_awaiting:
				FightUI.hand.position = get_viewport().get_mouse_position()
			if petting:
				FightUI.pet_particles.position = get_viewport().get_mouse_position()
				pets_given += event.relative.length()
				#FightUI.pet_count.text = str(ceili(pets_given / 100.0))
				add_shake(event.relative.length() * 0.0001)
				if pets_given < BAD_PETS:
					FightUI.set_pet_stat("BAD")
				elif pets_given < OK_PETS:
					FightUI.set_pet_stat("OK")
				elif pets_given < GOOD_PETS:
					FightUI.set_pet_stat("GOOD")
				else:
					FightUI.set_pet_stat("COOL")

func _on_body_entered(body):
	if body is Player:
		player = body
		player.can_interact = true
		can_activate = true

func _on_body_exited(body):
	if body is Player:
		player.can_interact = false
		can_activate = false

func activate_fight(pl: Player = player):
	set_deferred("monitoring", false)
	can_activate = false
	if player == null:
		player = pl
	player.can_interact = false
	
	get_parent().mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	get_tree().call_group("pedestrian", "disappear")
	player.prepare_fight()
	
	book.show()
	
	#if animation_player != null and animation_name != "":
		#animation_player.play(animation_name)
		#await animation_player.animation_finished
	if dialogue_pre != null:
		DialogueUI.start_dialogue(dialogue_pre, false)
		await DialogueUI.finished
	
	camera.fov = player.camera.fov
	camera.global_transform = player.camera.global_transform
	camera.make_current()
	
	var tween = create_tween().set_parallel()
	tween.tween_property(camera, "transform", Transform3D(), 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "fov", CAMERA_FOV, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($Animal, "global_position", $AnimalPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	FightUI.sticker_btn.hide()
	FightUI.show()

	FightUI.petted.connect(_on_petted)
	FightUI.kicked.connect(_on_kicked)
	FightUI.treated.connect(_on_treated)
	FightUI.stickered.connect(_on_stickered)
	
	FightUI.stickers_opened.connect(_on_stickers_opened)
	FightUI.stickers_closed.connect(_on_stickers_closed)
	FightUI.healed.connect(_on_healed)
	FightUI.bitten.connect(_on_bitten)
	FightUI.convinced.connect(_on_convinced)
	
	enemy = Animals.animals[animal].new()
	
	FightUI.update_grid()
	fight_active = true
	
	if dialogue_start != null:
		FightUI.disable_all()
		DialogueUI.start_dialogue(dialogue_start, true)
		await DialogueUI.finished
	
	FightUI.enable_all(can_treat(), false)
	
	update_ui()

func add_shake(amount: float):
	shake += amount

func update_ui():
	#FightUI.friendliness_text.text = "mood: %d%%" % (enemy.mood * 100)
	#FightUI.guard_text.text = "guard: %d%%" % (enemy.guard * 100)
	FightUI.update_satisfaction(enemy.satisfaction)
	FightUI.update_mood(enemy.mood)
	await get_tree().create_timer(0.2).timeout
	FightUI.update_guard(enemy.guard)
	FightUI.update_health(health)
	FightUI.update_enemy_health(enemy.health <= roundi(enemy.init_health / 3.0))
	#FightUI.treat_btn.disabled = Global.treats == 0

func apply_damage(damage: int):
	health = maxi(health - damage, 0)
	update_ui()
	if health <= 0:
		finish_fight(false)

func is_satisfied():
	return enemy.satisfaction >= enemy.SATISFACTION_MIN

func can_treat():
	return Global.treats > 0# and treat_cooldown == 0

func check_enemy_health():
	if enemy.health <= roundi(enemy.init_health / 3.0):
		if not low_hp_tutorial_given:
			low_hp_tutorial_given = true
			DialogueUI.start_dialogue(LOWHP_TUTORIAL, false)
			await DialogueUI.finished
	
	if enemy.health <= 0:
		FightUI.disable_all()
		if not gave_up_tutorial_given:
			gave_up_tutorial_given = true
			DialogueUI.start_dialogue(GAVE_UP_TUTORIAL, false)
			await DialogueUI.finished
		if is_tutorial:
			FightUI.enable_all(can_treat(), true)
			FightUI.disable_all()
			FightUI.sticker_btn.disabled = false
		else:
			FightUI.enable_all(can_treat(), true)
			enemy.satisfaction = enemy.SATISFACTION_MIN

func _on_petted():
	var tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", $CameraInteractPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerInteractPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	FightUI.disable_all()
	
	if not pet_tutorial_given:
		DialogueUI.start_dialogue(PET_TUTORIAL, false)
		await DialogueUI.finished
		pet_tutorial_given = true

	FightUI.partial_hide()
	FightUI.hand.show()
	#FightUI.pet_particles.restart()
	FightUI.pet_particles.emitting = false
	
	var will_bite = randf() < enemy.guard * 0.5
	
	pet_awaiting = true
	await pets_started
	FightUI.pet_stat.show()
	FightUI.pet_particles.emitting = true
	$PetAudioTimer.start()
	petting = true
	
	#FightUI.pet_particles.restart()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	await get_tree().create_timer(randf_range(1.0, 2.0) if will_bite else 3.0).timeout
	$PetAudioTimer.stop()
	petting = false
	
	if will_bite:
		FightUI.show_sudden_bite()
		FightUI.pet_stat.hide()
	
	#print("your score: %s" % pets_given)
	
	FightUI.hand.hide()
	FightUI.pet_particles.emitting = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", $CameraPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.8).timeout
	FightUI.pet_stat.hide()
	
	if will_bite:
		var animal_tween = create_tween()
		animal_tween.tween_property($Animal, "global_position", $AnimalBitePoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		animal_tween.tween_interval(0.1)
		animal_tween.tween_callback(FightUI.show_bite)
		animal_tween.tween_interval(0.25)
		animal_tween.tween_callback(add_shake.bind(0.08))
		animal_tween.tween_callback($Animal/AttackSFX.play)
		animal_tween.tween_interval(0.4)
		animal_tween.tween_property($Animal, "global_position", $AnimalPoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await animal_tween.finished
		
		enemy.add_mood(0.08 + randfn(0, 0.01))
		enemy.add_satisfaction(0.01 + randfn(0, 0.01))
		enemy.add_guard(-0.05 + randfn(0, 0.01))
		apply_damage(enemy.damage)
	else:
		if pets_given < BAD_PETS:
			enemy.add_mood(0.05 + randf_range(0, 0.02))
			enemy.add_satisfaction(0.1 + randfn(0, 0.02))
			enemy.add_guard(-0.02 + randfn(0, 0.01))
		elif pets_given < OK_PETS:
			enemy.add_mood(0.15 + randf_range(0, 0.02))
			enemy.add_satisfaction(0.2 + randfn(0, 0.03))
			enemy.add_guard(-0.04 + randfn(0, 0.01))
		elif pets_given < GOOD_PETS:
			enemy.add_mood(0.2 + randf_range(0, 0.02))
			enemy.add_satisfaction(0.3 + randfn(0, 0.03))
			enemy.add_guard(-0.05 + randfn(0, 0.01))
		else:
			enemy.add_mood(0.25 + randf_range(0, 0.02))
			enemy.add_satisfaction(0.4 + randf_range(0, 0.05))
			enemy.add_guard(-0.08 + randfn(0, 0.01))
	
	update_ui()
	
	FightUI.enable_all(Global.treats > 0, is_satisfied())
	FightUI.unhide()
	
	pets_given = 0
	
	if enemy.satisfaction >= enemy.SATISFACTION_MIN:
		if dialogue_big_progress != null:
			FightUI.disable_all()
			DialogueUI.start_dialogue(dialogue_big_progress, false)
			await DialogueUI.finished
		FightUI.enable_all(can_treat(), true)
		if is_tutorial:
			FightUI.disable_all()
			FightUI.sticker_btn.disabled = false

func _on_kicked():
	var tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", $CameraInteractPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerInteractPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	FightUI.disable_all()
	
	if not kick_tutorial_given:
		DialogueUI.start_dialogue(KICK_TUTORIAL, false)
		await DialogueUI.finished
		kick_tutorial_given = true
	
	#FightUI.rps_choose_text.text = "choose!"
	FightUI.show_rps()
	FightUI.enable_rps()
	FightUI.partial_hide()
	
	var player_choice = await FightUI.rps_chosen
	FightUI.disable_rps()
	
	var enemy_choice = enemy.preference
	if randf() > enemy.mood * 0.65:
		if randf() < 0.4:
			enemy_choice = (player_choice + 1) % 3
		else:
			enemy_choice = randi_range(0, 2)
	
	FightUI.animate_action(player_choice, enemy_choice)
	
	await get_tree().create_timer(2.0).timeout
	
	if (player_choice + 1) % 3 == enemy_choice: # enemy won
		tween = create_tween().set_parallel()
		tween.tween_property(camera, "global_transform", $CameraPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
		
		var animal_tween = create_tween()
		animal_tween.tween_property($Animal, "global_position", $AnimalBitePoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		#animal_tween.tween_callback(FightUI.show_bite)
		animal_tween.tween_interval(0.2)
		animal_tween.tween_callback(FightUI.play_win_anim.bind(enemy_choice))
		animal_tween.tween_interval(0.125)
		animal_tween.tween_callback(add_shake.bind(0.08))
		animal_tween.tween_callback($Animal/AttackSFX.play)
		animal_tween.tween_interval(0.4)
		animal_tween.tween_property($Animal, "global_position", $AnimalPoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await animal_tween.finished
		
		enemy.add_mood(0.025)
		enemy.add_satisfaction(0.05)
		enemy.add_guard(-0.1)
		apply_damage(ceili(enemy.damage / 2.0))
	elif (enemy_choice + 1) % 3 == player_choice: # player won
		FightUI.play_win_anim(player_choice)
		await get_tree().create_timer(0.2).timeout
		$Animal/AttackSFX.play()
		await get_tree().create_timer(0.8).timeout
		
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
	
	check_enemy_health()
	
	FightUI.enable_all(can_treat(), is_satisfied())
	FightUI.unhide()
	
	#if damage != 0:
		#add_shake(0.08)
		#apply_damage(damage)

func _on_treated():
	var tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", $CameraInteractPoint.global_transform, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerInteractPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	FightUI.disable_all()
	FightUI.partial_hide()
	
	await tween.finished
	if not treat_tutorial_given:
		DialogueUI.start_dialogue(TREAT_TUTORIAL, false)
		await DialogueUI.finished
	
	await get_tree().create_timer(0.25).timeout
	$Animal/HealSFX.play()
	$Animal/HealParticles.restart()
	await get_tree().create_timer(0.25).timeout
	
	tween = create_tween().set_parallel()
	tween.tween_property(camera, "transform", Transform3D(), 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", $PlayerPoint.global_position, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	Global.treats -= 1
	enemy.add_mood(0.2 + randf_range(0.05, 0.2))
	enemy.add_guard(-0.25 - randf_range(0.05, 0.15))
	enemy.add_satisfaction(0.35 + randf_range(0.05, 0.1))
	
	FightUI.enable_all(can_treat(), is_satisfied())
	FightUI.unhide()
	
	update_ui()

func _on_stickered():
	#if enemy.sticker():
	#FightUI.used_animals.clear()
	finish_fight(true)

func enable():
	set_deferred("monitoring", true)
	show()

func finish_fight(success: bool):
	FightUI.disable_all()
	FightUI.enable_all_animals()
	
	if success:
		if dialogue_won != null:
			DialogueUI.start_dialogue(dialogue_won, false)
			await DialogueUI.finished
	else:
		death_count += 1
		if death_count == 0:
			if dialogue_lost != null:
				DialogueUI.start_dialogue(dialogue_lost, false)
				await DialogueUI.finished
		else:
			if dialogue_lost2 != null:
				DialogueUI.start_dialogue(dialogue_lost2, false)
				await DialogueUI.finished
		
		if is_tutorial or is_finale:
			enemy = Animals.animals[animal].new()
			health = INIT_HEALTH
			update_ui()
			FightUI.enable_all(can_treat(), false)
			return
	
	fight_active = false
	
	var tween = create_tween()
	if success and not is_finale:
		get_viewport().gui_disable_input = true
		
		tween.tween_property($Animal, "global_position", $Animal.global_position + Vector3(0, 20, 0), 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_callback(book.play.bind("open"))
		tween.tween_callback($StickerbookPoint/FlipSFX.play)
		tween.tween_callback(FightUI.main_ui.hide)
		tween.tween_property(camera, "global_transform", $CameraPoint/RotationPoint.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		await book.animation_finished
		
		FightUI.hide_not_grid()
		FightUI.sticker_ui.show()
		
		await get_tree().create_timer(0.5).timeout
		$StickerbookPoint/AppearSFX.play()
		FightUI.add_animal(enemy)
		Global.animals.append(enemy)
		await get_tree().create_timer(1.5).timeout
		FightUI.sticker_ui.hide()
		FightUI.show_not_grid()
		book.play("open")
		$StickerbookPoint/FlipSFX.play()
		await get_tree().create_timer(0.2).timeout
		
		get_viewport().gui_disable_input = false
	
	FightUI.main_ui.show()
	FightUI.hide()
	
	get_parent().mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().call_group("pedestrian", "appear")
	hide()
	tween = create_tween().set_parallel()
	if next_fight and success:
		next_fight.enable()
		tween.tween_property(camera, "global_transform", camera.global_transform.translated(Vector3(0, 40, 0)).looking_at(next_fight.global_position), 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(camera, "global_transform", player.camera.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "fov", player.camera.fov, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	player.post_fight()
	fight_finished.emit()
	
	if success:
		queue_free()
	else:
		enable()

func _on_healed(pet: Animals.Animal):
	$Pet.texture = pet.texture
	$Pet.global_position = $AnimalBitePoint.global_position
	$Pet.show()
	
	await get_tree().create_timer(1.0).timeout
	$Pet/HealSFX.play()
	await get_tree().create_timer(0.4).timeout
	$Pet/HealSFX.play()
	await get_tree().create_timer(0.5).timeout
	$Pet/HealSFX.play()
	$Pet/HealParticles.amount = pet.healing
	$Pet/HealParticles.restart()
	await get_tree().create_timer(2.5).timeout
	
	var tween = create_tween()
	tween.tween_property($Pet, "global_position", $AnimalBitePoint.global_position + Vector3(0, 10, 0), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback($Pet.hide)
	
	FightUI.enable_all(can_treat(), is_satisfied())
	FightUI.unhide()
	
	health = clampi(health + pet.healing, 0, INIT_HEALTH)
	update_ui()

func _on_bitten(pet: Animals.Animal):
	$Pet.texture = pet.texture
	$Pet.global_position = $AnimalBitePoint.global_position
	$Pet.show()
	await get_tree().create_timer(1.0).timeout
	
	var tween = create_tween()
	tween.tween_property($Pet, "global_position", $PetInteractPoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.2)
	tween.tween_callback(FightUI.show_bite)
	tween.tween_interval(0.25)
	tween.tween_callback(add_shake.bind(0.08))
	tween.tween_callback($Animal/AttackSFX.play)
	tween.tween_interval(0.5)
	tween.tween_property($Pet, "global_position", $PetInteractPoint.global_position + Vector3(0, 10, 0), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished
	$Pet.hide()
	
	FightUI.enable_all(can_treat(), is_satisfied())
	FightUI.unhide()
	
	enemy.health -= pet.damage
	enemy.add_guard(-randf_range(0.15, 0.3))
	enemy.add_mood(-randf_range(0.05, 0.1))
	
	update_ui()
	check_enemy_health()

func _on_convinced(pet: Animals.Animal):
	var success = randf() < pet.convincing
	
	$Pet.texture = pet.texture
	$Pet.global_position = $AnimalBitePoint.global_position
	$Pet.show()
	
	await get_tree().create_timer(1.0).timeout
	
	var tween = create_tween()
	tween.tween_property($Pet, "global_position", $PetInteractPoint.global_position, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(FightUI.show_convince.bind(success))
	tween.tween_interval(3.0)
	tween.tween_property($Pet, "global_position", $PetInteractPoint.global_position + Vector3(0, 10, 0), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished
	$Pet.hide()
	
	FightUI.enable_all(Global.treats, is_satisfied())
	FightUI.unhide()
	
	if success:
		enemy.add_mood(randf_range(0.05, 0.1))
		enemy.add_satisfaction(randf_range(0.03, 0.07))
		enemy.add_guard(-randf_range(0.1, 0.15))
	else:
		enemy.add_mood(randf_range(0.02, 0.04))
		enemy.add_satisfaction(-randf_range(0.02, 0.03))
		enemy.add_guard(-randf_range(0.01, 0.03))
	
	update_ui()

func _on_stickers_opened():
	$StickerbookPoint/FlipSFX.play()
	var tween = create_tween()
	tween.tween_property(camera, "global_transform", $CameraPoint/RotationPoint.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	book.play("open")
	await book.animation_finished
	if not sticker_tutorial_given:
		sticker_tutorial_given = true
		DialogueUI.start_dialogue(STICKER_TUTORIAL, false)
		await DialogueUI.finished
	FightUI.sticker_ui.show()

func _on_stickers_closed():
	var tween = create_tween()
	tween.tween_property(camera, "transform", Transform3D(), 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func _on_pet_audio_timer_timeout():
	$Animal/HealSFX.play()
