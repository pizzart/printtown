extends CanvasLayer

signal petted
signal kicked
signal treated
signal stickered

signal rps_chosen(choice: Global.RPS)

const ANGRY = preload("res://graphics/ui/fight/stamps/stamp_angry.png")
const NEUTRAL = preload("res://graphics/ui/fight/stamps/stamp_neutral.png")
const HAPPY = preload("res://graphics/ui/fight/stamps/stamp_happy.png")

const ALERT0 = preload("res://graphics/ui/fight/alert/alert0.png")
const ALERT1 = preload("res://graphics/ui/fight/alert/alert1.png")
const ALERT2 = preload("res://graphics/ui/fight/alert/alert2.png")

var actual_progress: float
var progress: float

@onready var pet_btn = $C/Pet
@onready var kick_btn = $C/Kick
@onready var sticker_btn = $C/Sticker
@onready var treat_btn = $C/Treat
@onready var progress_text = $C/Progress
@onready var friendliness_text = $C/Friendliness
@onready var guard_text = $C/Guard
@onready var health_text = $C/Health
@onready var fighter_line = $FighterLine
@onready var stamp = $C/Stamp
@onready var guard_icon = $C/Alert
@onready var main_ui = $C

@onready var hand = $Hand
@onready var pet_particles = $PetParticles
@onready var rps_choose_text = $RPS/Choose
@onready var rps_action_text = $RPS/Action
@onready var rock_btn = $RPS/Rock
@onready var paper_btn = $RPS/Paper
@onready var scissors_btn = $RPS/Scissors

func _ready():
	hide()

func _process(delta):
	if visible:
		progress = lerpf(progress, actual_progress, delta * 4)
		progress_text.text = "%d%%" % roundf(progress * 100)

func set_progress(_progress: float):
	actual_progress = _progress

func disable_all():
	pet_btn.disabled = true
	kick_btn.disabled = true
	treat_btn.disabled = true
	sticker_btn.disabled = true

func enable_all(treats: int, can_sticker: bool):
	pet_btn.disabled = false
	kick_btn.disabled = false
	treat_btn.disabled = treats == 0
	sticker_btn.disabled = not can_sticker

func partial_hide():
	pet_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kick_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	treat_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sticker_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(main_ui, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	main_ui.hide()

func unhide():
	main_ui.show()
	var tween = create_tween()
	tween.tween_property(main_ui, "modulate", Color.WHITE, 0.5)
	pet_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	kick_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	treat_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	sticker_btn.mouse_filter = Control.MOUSE_FILTER_STOP

func change_mood(mood: float):
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

func change_guard(guard: float):
	if guard < 0.33:
		guard_icon.texture = ALERT0
	elif guard < 0.66:
		guard_icon.texture = ALERT1
	else:
		guard_icon.texture = ALERT2

func show_rps():
	$RPS.modulate.a = 0
	$RPS.show()
	var tween = create_tween()
	tween.tween_property($RPS, "modulate", Color.WHITE, 0.5)

func hide_rps():
	var tween = create_tween()
	tween.tween_property($RPS, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	$RPS.hide()

func disable_rps():
	$RPS/Rock.disabled = true
	$RPS/Paper.disabled = true
	$RPS/Scissors.disabled = true

func enable_rps():
	$RPS/Rock.disabled = false
	$RPS/Paper.disabled = false
	$RPS/Scissors.disabled = false

func animate_action(choice: Global.RPS):
	rps_choose_text.hide()
	rps_action_text.text = "rock..."
	rps_action_text.show()
	await get_tree().create_timer(0.5).timeout
	rps_action_text.text = "paper..."
	await get_tree().create_timer(0.5).timeout
	rps_action_text.text = "scissors!"
	await get_tree().create_timer(0.5).timeout
	var pick_text = "rock"
	if choice == Global.RPS.PAPER:
		pick_text = "paper"
	elif choice == Global.RPS.SCISSORS:
		pick_text = "scissors"
	rps_action_text.text = "my pick: %s" % pick_text

func _on_pet_pressed():
	petted.emit()

func _on_kick_pressed():
	kicked.emit()

func _on_sticker_pressed():
	stickered.emit()

func _on_treat_pressed():
	treated.emit()


func _on_rock_pressed():
	rps_chosen.emit(Global.RPS.ROCK)

func _on_paper_pressed():
	rps_chosen.emit(Global.RPS.PAPER)

func _on_scissors_pressed():
	rps_chosen.emit(Global.RPS.SCISSORS)
