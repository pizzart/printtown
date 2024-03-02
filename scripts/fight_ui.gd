extends CanvasLayer

signal petted
signal kicked
signal stickered

var actual_progress: float
var progress: float

@onready var pet_btn = $C/Pet
@onready var kick_btn = $C/Kick
@onready var sticker_btn = $C/Sticker
@onready var progress_text = $C/Progress
@onready var health_text = $C/Health
@onready var fighter_line = $FighterLine

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

func enable_all():
	pet_btn.disabled = false
	kick_btn.disabled = false
	sticker_btn.disabled = false

func enable_not_sticker():
	pet_btn.disabled = false
	kick_btn.disabled = false
	sticker_btn.disabled = true

func enable_only_sticker():
	pet_btn.disabled = true
	kick_btn.disabled = true
	sticker_btn.disabled = false

func _on_pet_pressed():
	petted.emit()

func _on_kick_pressed():
	kicked.emit()

func _on_sticker_pressed():
	stickered.emit()
