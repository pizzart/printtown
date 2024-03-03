extends Area3D

#signal won
#signal lost

const CAMERA_FOV = 45.0
const SHAKE_REDUCE = 7.0

const SPIN_SPEED = 0.3
const SPIN_OFFSET = PI * 2 / 3
const SPIN_RAD = 135.0
const TEXT_SPIN_RAD = 75.0
const TEXT_SPIN_SPEED = 0.8

const INIT_HEALTH = 10

var player: Player
var enemy: Animals.Animal
var health: int = INIT_HEALTH
var fight_active: bool
var time: float
var shake: float

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
		
		camera.h_offset = randfn(0, shake)
		camera.v_offset = randfn(0, shake)
		
		shake = lerpf(shake, 0, delta * SHAKE_REDUCE)

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
			if is_tutorial:
				FightUI.enable_not_sticker()
			else:
				FightUI.enable_all()
		
		update_ui()
		#FightUI.crect.position = camera.unproject_position($AnimalPoint.global_position)

func add_shake(amount: float):
	shake += amount

func update_ui():
	FightUI.set_progress(enemy.satisfaction)
	FightUI.friendliness_text.text = "mood: %d%%" % (enemy.mood * 100)
	FightUI.guard_text.text = "guard: %d%%" % (enemy.guard * 100)
	FightUI.health_text.text = str(health)
	FightUI.change_mood(enemy.mood)
	FightUI.treat_btn.disabled = Global.treats == 0

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

func _on_petted():
	var damage = enemy.pet()
	if damage != 0:
		add_shake(0.08)
		apply_damage(damage)
	update_ui()
	
	if enemy.satisfaction >= enemy.SATISFACTION_MIN:
		if dialogue_big_progress != null:
			FightUI.disable_all()
			DialogueUI.start_dialogue(dialogue_big_progress, false)
			await DialogueUI.finished
			if is_tutorial:
				FightUI.enable_only_sticker()
			else:
				FightUI.enable_all()

func _on_kicked():
	var damage = enemy.kick()
	if damage != 0:
		add_shake(0.08)
		apply_damage(damage)
	update_ui()
	
	if enemy.health <= 0:
		FightUI.disable_all()
		if dialogue_kicked:
			DialogueUI.start_dialogue(dialogue_kicked, false)
			await DialogueUI.finished
		if is_tutorial:
			FightUI.enable_only_sticker()
		else:
			FightUI.enable_all()

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
