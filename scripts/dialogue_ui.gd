extends CanvasLayer

enum Character {
	TOP,
	BOTTOM,
}
signal finished
const JAKE_ICON = preload("res://graphics/ui/dialogue/dialogue_other.png")
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
	var rot = PI / 12.0 if ceili(time * 3.0) % 2 == 0 else -PI / 12.0
	if char_moving == Character.TOP:
		$C/TopIcon.rotation = rot
		$C/BottomIcon.rotation = 0
	else:
		$C/BottomIcon.rotation = rot
		$C/TopIcon.rotation = 0
	
	time += delta
	
	if Input.is_action_pressed("skip_dialogue") and active:
		next_line(false)

func start_dialogue(dialogue: DialogueResource, is_call: bool, start_node: String = "start"):
	dialogue_res = dialogue
	text_label.text = ""
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
	var tween = create_tween().set_parallel()
	tween.tween_property($C, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($BG, "modulate", Color.WHITE, 0.8)
	await get_tree().create_timer(0.5).timeout
	next_line(true, start_node)
	active = true

func _input(event):
	if event.is_action_pressed("next_dialogue") and active:
		next_line(false)
	
func next_line(started: bool, start_node: String = "start"):
	if text_label.is_typing:
		text_label.skip_typing()
		return
	
	$DialogueTimer.stop()
	tip.hide()
	
	if started:
		dialogue_line = await dialogue_res.get_next_dialogue_line(start_node)
	else:
		dialogue_line = await dialogue_res.get_next_dialogue_line(dialogue_line.next_id)
	
	if not dialogue_line:
		active = false
		var tween = create_tween().set_parallel()
		tween.tween_property($C, "scale", Vector2.ONE * 4, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property($BG, "modulate", Color(1, 1, 1, 0), 0.8)
		await get_tree().create_timer(0.5).timeout
		hide()
		await get_tree().create_timer(0.3).timeout
		finished.emit()
		return
	
	if dialogue_line.character == Global.player_name:
		char_moving = Character.TOP
	else:
		char_moving = Character.BOTTOM
	
	# kind of bad but it works ig. BE SURE TO HAVE THE ANIMAL'S TEXTURE IN THE FOLDER
	# also the dialogue has to start with not the player or it will look weird
	if dialogue_line.character == "jake": # weird place to hardcode
		$C/BottomIcon.texture = JAKE_ICON
	elif dialogue_line.character != Global.player_name:
		$C/BottomIcon.texture = load("res://graphics/animals/%s.png" % dialogue_line.character)
	
	time = 0
	
	$C/Text/Name.text = dialogue_line.character
	text_label.dialogue_line = dialogue_line
	text_label.type_out()
	
	#$DialogueTimer.start()

func _on_dialogue_timer_timeout():
	tip.show()
	$DialogueTimer.wait_time = 15

func _on_dialogue_finished_typing():
	$DialogueTimer.start()
