extends Node3D

#const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity: Vector3
var ground_y: float = -1
var speed = 0.07
var player_overlap: bool = false
var player: Player
#@onready var district: District = get_parent()
@onready var navagent: NavigationAgent3D = $NavigationAgent3D
@onready var idle_timer: Timer = $IdleTimer
#@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready():
	randomize()
	#mesh.mesh = mesh.mesh.duplicate(true)
	#mesh.mesh.surface_get_material(0).set_shader_parameter("color0", Color(randf(), randf(), randf()))
	#mesh.mesh.surface_get_material(0).set_shader_parameter("color1", Color(randf(), randf(), randf()))
	#mesh.mesh.surface_get_material(0).set_shader_parameter("color2", Color(randf(), randf(), randf()))
	#mesh.mesh.surface_get_material(0).set_shader_parameter("color3", Color(randf(), randf(), randf()))
	await get_tree().create_timer(randf_range(0.1, 0.5)).timeout
	ask_new_target()

func _physics_process(delta):
	#if global_position.y > ground_y:
		#velocity.y -= gravity * delta
	#else:
		#velocity.y = 0
	#velocity.y = lerpf(velocity.y, ground_y - global_position.y, delta * 10)
	
	var direction = Vector3.ZERO
	if navagent.is_navigation_finished() and idle_timer.is_stopped():
		idle_timer.start()
	elif not navagent.is_target_reachable():
		ask_new_target()
	else:
		direction = global_position.direction_to(navagent.get_next_path_position())
	
	if player_overlap:
		direction = player.global_position.direction_to(global_position)

	velocity = lerp(velocity, direction * speed, delta * 10)
	#velocity.z = lerpf(velocity.z, direction.z * speed, delta * 10)
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 10)
	
	global_position += velocity
#
	#move_and_slide()

func get_random_pos():
	var pos = global_position + Vector3(randf_range(-50, 50), 50, randf_range(-50, 50))
	$Ray.global_position = pos
	await get_tree().physics_frame
	$Ray.force_raycast_update()
	if $Ray.is_colliding():
		return $Ray.get_collision_point()
	else:
		return await get_random_pos()

func ask_new_target():
	var pos = await get_random_pos()
	navagent.target_position = pos

func disappear():
	var tween = create_tween()
	tween.tween_property($Sprite, "transparency", 1.0, 2.0)

func appear():
	var tween = create_tween()
	tween.tween_property($Sprite, "transparency", 0.0, 2.0)

func _on_idle_timer_timeout():
	ask_new_target()
