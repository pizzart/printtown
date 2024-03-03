extends CanvasLayer

signal petted
signal kicked
signal treated
signal stickered

const ANGRY = preload("res://graphics/ui/fight/stamps/stamp_angry.png")
const NEUTRAL = preload("res://graphics/ui/fight/stamps/stamp_neutral.png")
const HAPPY = preload("res://graphics/ui/fight/stamps/stamp_happy.png")

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
	sticker_btn.disabled = true
	treat_btn.disabled = true

func enable_all():
	pet_btn.disabled = false
	kick_btn.disabled = false
	treat_btn.disabled = false
	sticker_btn.disabled = false

func enable_not_sticker():
	enable_all()
	sticker_btn.disabled = true

func enable_only_sticker():
	disable_all()
	sticker_btn.disabled = false

func change_mood(mood: float):
	var old_texture = stamp.texture
	var new_texture
	if mood < 0.35:
		new_texture = ANGRY
	elif mood < 0.7:
		new_texture = NEUTRAL
	else:
		new_texture = HAPPY
	if old_texture != new_texture:
		$StampAnimation.play("stamp")
		await $StampAnimation.frame_changed
		await $StampAnimation.frame_changed
		stamp.texture = new_texture

func _on_pet_pressed():
	petted.emit()

func _on_kick_pressed():
	kicked.emit()

func _on_sticker_pressed():
	stickered.emit()

func _on_treat_pressed():
	treated.emit()
