extends Area3D

#signal won
#signal lost

const CAMERA_FOV = 48.0
const SPIN_SPEED = 0.3
const SPIN_OFFSET = PI * 2 / 3
const SPIN_RAD = 135.0
const TEXT_SPIN_RAD = 75.0
const TEXT_SPIN_SPEED = 0.8

var player: Player
var fighter: Animals.Animal
var health: int = 10
var fight_active: bool
var time: float

@export var animal: Animals.AnimalType
@export var dialogue_start: DialogueResource
@export var dialogue_big_progress: DialogueResource
@export var dialogue_won: DialogueResource
@export var dialogue_lost: DialogueResource
@onready var camera = $CameraPoint/Camera

func _process(delta):
	if fight_active:
		time += delta
		
		var cam_unproj = camera.unproject_position($AnimalPoint.global_position)
		var cam_unproj_player = camera.unproject_position($PlayerPoint.global_position)
		FightUI.pet_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED), sin(-time * SPIN_SPEED)) * SPIN_RAD
		FightUI.kick_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED + SPIN_OFFSET), sin(-time * SPIN_SPEED + SPIN_OFFSET)) * SPIN_RAD
		FightUI.sticker_btn.position = cam_unproj - Vector2(64, 64) + Vector2(cos(-time * SPIN_SPEED - SPIN_OFFSET), sin(-time * SPIN_SPEED - SPIN_OFFSET)) * SPIN_RAD
		FightUI.progress_text.position = cam_unproj + Vector2(cos(sin(-time * TEXT_SPIN_SPEED) - PI / 2), sin(sin(-time * TEXT_SPIN_SPEED) - PI / 2)) * TEXT_SPIN_RAD
		FightUI.health_text.position = cam_unproj_player + Vector2(cos(sin(-time * TEXT_SPIN_SPEED) + PI / 2), sin(sin(-time * TEXT_SPIN_SPEED) + PI / 2)) * TEXT_SPIN_RAD
		FightUI.fighter_line.points[0] = cam_unproj
		FightUI.fighter_line.points[1] = FightUI.progress_text.position + Vector2(16, 34)

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
		FightUI.stickered.connect(_on_stickered)
		
		fighter = Animals.animals[animal].new()
		
		fight_active = true
		if dialogue_start != null:
			DialogueUI.start_dialogue(dialogue_start, true)
			await DialogueUI.finished
			FightUI.enable_not_sticker()
		
		FightUI.set_progress(fighter.progress)
		FightUI.health_text.text = str(health)
		#FightUI.crect.position = camera.unproject_position($AnimalPoint.global_position)

func _on_petted():
	var result = fighter.pet()
	FightUI.set_progress(fighter.progress)
	if result:
		if fighter.progress >= 1:
			if dialogue_big_progress != null:
				FightUI.disable_all()
				DialogueUI.start_dialogue(dialogue_big_progress, false)
				await DialogueUI.finished
				FightUI.enable_only_sticker()
	else:
		health -= fighter.damage
		FightUI.health_text.text = str(health)
		if health <= 0:
			FightUI.disable_all()
			DialogueUI.start_dialogue(dialogue_lost, false)
			await DialogueUI.finished
			FightUI.hide()
			fight_active = false

func _on_kicked():
	var result = fighter.kick()
	FightUI.set_progress(fighter.progress)
	if result:
		if fighter.progress >= 1:
			if dialogue_big_progress != null:
				FightUI.disable_all()
				DialogueUI.start_dialogue(dialogue_big_progress, false)
				await DialogueUI.finished
				FightUI.enable_only_sticker()
	else:
		print("you kicked it when it wasn't looking. you're a monster")

func _on_stickered():
	if fighter.sticker():
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
