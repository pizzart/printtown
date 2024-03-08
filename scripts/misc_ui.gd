extends CanvasLayer

const PETS_TEXT = """
you have %s pets
out of %s
to raid the place
"""
@onready var interact_icon = $Interact
@onready var collectables_popup = $Collectables
@onready var pets_popup = $Pets

func _ready():
	Global.treat_collected.connect(_on_treat_collected)

func _on_treat_collected():
	$Collectables/Count.text = "%s/%s" % [Global.collected_treats, Global.total_treats]
	var tween = create_tween()
	tween.tween_property($Collectables, "modulate", Color.WHITE, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property($Collectables, "modulate", Color(1, 1, 1, 0), 0.5)

func update_pet_count(count: int, max_count: int):
	$Pets/Count.text = PETS_TEXT % [count, max_count]
