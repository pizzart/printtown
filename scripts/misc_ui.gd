extends CanvasLayer

signal transitioned
const PETS_TEXT = """you have %s pets
out of %s
to raid the place
"""
var bars_shown: bool = false
@onready var interact_icon = $Interact
@onready var collectables_popup = $Collectables
@onready var pets_popup = $Pets

func _ready():
	Global.treat_collected.connect(_on_treat_collected)

func _process(delta):
	$Bars.scale.y = lerpf($Bars.scale.y, 1.0 if bars_shown else 1.25, delta * 2)

func _on_treat_collected():
	$Collectables/Count.text = "%s/%s" % [Global.collected_treats, Global.total_treats]
	var tween = create_tween()
	tween.tween_property($Collectables, "modulate", Color.WHITE, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property($Collectables, "modulate", Color(1, 1, 1, 0), 0.5)

func update_pet_count(count: int, max_count: int):
	$Pets/Count.text = PETS_TEXT % [count, max_count]

func show_bars():
	bars_shown = true

func hide_bars():
	bars_shown = false

func transition():
	var tween = create_tween()
	tween.tween_method(_set_trans, 1.0, 0.0, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(emit_signal.bind("transitioned"))
	tween.tween_interval(0.1)
	tween.tween_method(_set_trans, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

func slow_transition(time_in: float, time_out: float):
	var tween = create_tween()
	tween.tween_property($Black, "color", Color(0, 0, 0, 1), time_in)
	tween.tween_callback(emit_signal.bind("transitioned"))
	tween.tween_property($Black, "color", Color(0, 0, 0, 0), time_out)

func _set_trans(value: float):
	$Trans.material.set_shader_parameter("size", value)

func play_video():
	var tween = create_tween()
	tween.tween_property($Black, "color", Color(0, 0, 0, 1), 3.0)
	await tween.finished
	$Video.show()
	$Video.play()
	tween = create_tween()
	tween.tween_property($Black, "color", Color(0, 0, 0, 0), 1.0)
	await get_tree().create_timer(4.8).timeout
	$ShakeSFX.play()
	await get_tree().create_timer(0.6).timeout
	$SpraySFX.play()
	await $Video.finished
	$LastFrame.show()
	tween = create_tween()
	tween.tween_property($Black, "color", Color(0, 0, 0, 1), 3.0)
	await tween.finished
	$LastFrame.hide()
	$Video.hide()
	tween = create_tween()
	tween.tween_property($Black, "color", Color(0, 0, 0, 0), 1.0)
