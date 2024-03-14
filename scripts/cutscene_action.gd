@tool
class_name CutsceneAction
extends Resource

enum Action {
	WAIT,
	MOVE_NODE,
	MOVE_PLAYER,
	MOVE_CAMERA,
	DIALOGUE,
	LOOK_AT,
	PLAY_ANIMATION,
	TRANSITION,
	CALL_NODE,
}

@export var action: Action = Action.WAIT:
	set(val):
		action = val
		notify_property_list_changed()
@export var dialogue: DialogueResource = null
@export var node_title: String = "start"
@export var is_call: bool = false
@export_node_path("Node3D") var move_node: NodePath = ""
@export_node_path("Marker3D") var move_point: NodePath = ""
@export_range(0, 100, 0.1) var move_time: float = 0
@export var transition_type: Tween.TransitionType = Tween.TRANS_EXPO
@export var ease_type: Tween.EaseType = Tween.EASE_OUT
@export var camera_follow: bool = false
@export_range(0, 100) var wait_time: float = 0
#@export_node_path("Camera3D") var camera: NodePath
@export_node_path("Node3D") var look_at: NodePath = ""
@export var animation_name: String = ""
@export var called_node: NodePath = ""
@export var function_name: String = ""
@export var wait: bool = true
#@export var additional_action: CutsceneAction = null

#func _init(_action: Action = Action.WAIT, _dialogue: DialogueResource = null, _move_node: NodePath = "", _move_point: NodePath = "", _move_time: float = 0, _wait_time: float = 0):
	#action = _action
	#dialogue = _dialogue
	#move_node = _move_node
	#move_point = _move_point
	#move_time = _move_time
	#wait_time = _wait_time

func _validate_property(property: Dictionary):
	if property.name in ["wait_time"] and action != Action.WAIT:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["move_point", "move_time", "transition_type", "ease_type"] and not action in [Action.MOVE_NODE, Action.MOVE_PLAYER, Action.MOVE_CAMERA]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name == "move_node" and action != Action.MOVE_NODE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name == "camera_follow" and not action in [Action.MOVE_NODE, Action.MOVE_PLAYER]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["dialogue", "is_call", "node_title"] and action != Action.DIALOGUE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["look_at"] and action != Action.LOOK_AT:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["animation_name"] and action != Action.PLAY_ANIMATION:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name == "wait" and action in [Action.WAIT, Action.PLAY_ANIMATION, Action.TRANSITION, Action.CALL_NODE]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["called_node", "function_name"] and action != Action.CALL_NODE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
