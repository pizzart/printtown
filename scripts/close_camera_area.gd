@tool
extends Area3D

@export var shape: Shape3D

func _ready():
	$CollisionShape3D.shape = shape

func _process(delta):
	if Engine.is_editor_hint():
		$CollisionShape3D.shape = shape
