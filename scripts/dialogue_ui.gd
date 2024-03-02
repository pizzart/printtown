extends CanvasLayer

enum Character {
	TOP,
	BOTTOM,
}
signal finished
var dialogue_res = preload("res://dialogue/intro.dialogue")
var active: bool = false
var dialogue_line: DialogueLine
var char_moving: Character = Character.TOP
var time: float
@onready var text_label = $C/Text/DialogueLabel
@onready var tip = $C/Tip

func _ready():
	hide()

func _process(delta):
	var rot = PI / 12 if ceili(time * 3) % 2 == 0 else -PI / 12
	if char_moving == Character.TOP:
		$C/TopIcon.rotation = rot
		$C/BottomIcon.rotation = 0
	else:
		$C/BottomIcon.rotation = rot
		$C/TopIcon.rotation = 0
	
	time += delta

func start_dialogue(dialogue: DialogueResource, is_call: bool):
	dialogue_res = dialogue
	show()
	if is_call:
		$C.hide()
		$CallSprite.show()
		$CallSprite.play("default")
		await $CallSprite.animation_finished
	else:
		$CallSprite.hide()
	$C.show()
	$C.scale = Vector2.ONE * 4
	var tween = create_tween()
	tween.tween_property($C, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.5).timeout
	next_line(true)
	active = true

func _input(event):
	if event.is_action_pressed("next_dialogue") and active:
		next_line(false)

func next_line(started: bool):
	if text_label.is_typing:
		text_label.skip_typing()
		return
	
	$DialogueTimer.stop()
	tip.hide()
	
	if started:
		dialogue_line = await dialogue_res.get_next_dialogue_line("start")
	else:
		dialogue_line = await dialogue_res.get_next_dialogue_line(dialogue_line.next_id)
	
	if not dialogue_line:
		active = false
		finished.emit()
		var tween = create_tween()
		tween.tween_property($C, "scale", Vector2.ONE * 4, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
		await get_tree().create_timer(0.5).timeout
		hide()
		return
	
	if dialogue_line.character == Global.player_name:
		char_moving = Character.TOP
	else:
		char_moving = Character.BOTTOM
	time = 0
	
	$C/Text/Name.text = dialogue_line.character
	text_label.dialogue_line = dialogue_line
	text_label.type_out()
	
	#$DialogueTimer.start()

func _on_dialogue_timer_timeout():
	tip.show()
	$DialogueTimer.wait_time = 10

func _on_dialogue_finished_typing():
	$DialogueTimer.start()
