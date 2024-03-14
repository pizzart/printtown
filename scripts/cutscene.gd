@tool
class_name CutscenePlayer
extends Node3D

signal started_action(idx: int)
signal finished

enum CameraStart {
	PLAYER,
	POSITION,
}
var current_action: int = 0
var cam_follow_node: Node3D = null
var cam_interp_pos: Vector3

## the array of actions to perform
@export var actions: Array[CutsceneAction] = []
	#set(val):
		#actions = val
		#notify_property_list_changed()
@export_group("Player")
@export var player: Player:
	set(val):
		player = val
		update_configuration_warnings()
@export var init_animation_name: String = ""
@export var init_player_position: Marker3D = null
## show the cursor when the cutscene is playing
@export var show_cursor: bool = true
@export var disable_controls: bool = true
@export_group("Camera")
@export var camera: Camera3D = null:
	set(val):
		camera = val
		update_configuration_warnings()
@export var camera_start: CameraStart = CameraStart.PLAYER:
	set(val):
		camera_start = val
		notify_property_list_changed()
		update_configuration_warnings()
@export var init_position: Marker3D = null:
	set(val):
		init_position = val
		update_configuration_warnings()

func _process(delta):
	if cam_follow_node != null:
		cam_interp_pos = lerp(cam_interp_pos, cam_follow_node.global_position, delta * 10)
		camera.look_at(cam_interp_pos)

func play_cutscene():
	if disable_controls:
		player.prepare_fight()
	
	if init_player_position:
		player.global_position = init_player_position.global_position
	if init_animation_name:
		player.sprite.play(init_animation_name)
	if show_cursor:
		get_tree().get_first_node_in_group("world").mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var init_fov = camera.fov
	camera.fov = player.camera.fov
	camera.global_transform = player.camera.global_transform
	camera.make_current()
	
	MiscUI.show_bars()
	
	var tween = create_tween().set_parallel()
	tween.tween_property(camera, "fov", init_fov, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if camera_start == CameraStart.POSITION:
		tween.tween_property(camera, "global_transform", init_position.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	current_action = 0
	while current_action < actions.size():
		started_action.emit(current_action)
		await _do_action(actions[current_action])
		current_action += 1
	
	player.velocity = Vector3.ZERO
	player.gimbal.global_position = player.global_position
	player.last_floor_y = player.global_position.y - 1
	
	tween = create_tween().set_parallel()
	tween.tween_property(camera, "global_transform", player.camera.global_transform, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "fov", player.camera.fov, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	player.can_move = true
	player.camera.make_current()
	
	MiscUI.hide_bars()
	
	if show_cursor:
		get_tree().get_first_node_in_group("world").mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	finished.emit()

func skip_to_action(idx: int):
	current_action = idx

func _do_action(action: CutsceneAction):
	#if action.additional_action:
		#_do_action(action.additional_action)
	match action.action:
		CutsceneAction.Action.WAIT:
			await get_tree().create_timer(action.wait_time).timeout
		CutsceneAction.Action.MOVE_NODE, CutsceneAction.Action.MOVE_PLAYER, CutsceneAction.Action.MOVE_CAMERA:
			var move_node
			if action.action == CutsceneAction.Action.MOVE_NODE:
				move_node = get_node(action.move_node)
			elif action.action == CutsceneAction.Action.MOVE_PLAYER:
				move_node = player
			else:
				move_node = camera
			
			if action.camera_follow and action.action != CutsceneAction.Action.MOVE_CAMERA:
				cam_follow_node = move_node
				cam_interp_pos = cam_follow_node.global_position
			
			if action.move_time != 0:
				var tween = create_tween()
				tween.tween_property(move_node, "global_transform", get_node(action.move_point).global_transform, action.move_time).set_trans(action.transition_type).set_ease(action.ease_type)
				if action.wait:
					await tween.finished
			else:
				move_node.global_transform = get_node(action.move_point).global_transform
			
			if action.camera_follow and action.action != CutsceneAction.Action.MOVE_CAMERA:
				cam_follow_node = null
		CutsceneAction.Action.DIALOGUE:
			DialogueUI.start_dialogue(action.dialogue, action.is_call, action.node_title)
			if action.wait:
				await DialogueUI.finished
		CutsceneAction.Action.LOOK_AT:
			camera.look_at(get_node(action.look_at).global_position)
		CutsceneAction.Action.PLAY_ANIMATION:
			player.sprite.play(action.animation_name)
		CutsceneAction.Action.TRANSITION:
			MiscUI.transition()
			await MiscUI.transitioned
		CutsceneAction.Action.CALL_NODE:
			get_node(action.called_node).call(action.function_name)

func _validate_property(property: Dictionary):
	#var has_look: bool = false
	#for action in actions:
		#if action == null:
			#continue
		#if action.action == CutsceneAction.Action.LOOK_AT:
			#has_look = true
	if property.name == "init_position" and camera_start != CameraStart.POSITION:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_configuration_warnings():
	var warnings = []
	if camera == null:
		warnings.append("camera must be set")
	if player == null:
		warnings.append("player must be set")
	return warnings
