extends CanvasLayer

@onready var interact_icon = $Interact
@onready var collectables_popup = $Collectables

func _ready():
	Global.treat_collected.connect(_on_treat_collected)

func _on_treat_collected():
	$Collectables/Count.text = "%s/%s" % [Global.collected_treats, Global.total_treats]
	var tween = create_tween()
	tween.tween_property($Collectables, "modulate", Color.WHITE, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property($Collectables, "modulate", Color(1, 1, 1, 0), 0.5)
