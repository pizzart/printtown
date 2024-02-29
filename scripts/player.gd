extends CharacterBody3D

const ACCEL = 0.2
const DECEL = 0.15
const SPEED = 5.0
const RUN_SPEED = 10.0
const JUMP_VELOCITY = 17.0
const COYOTE_TIME = 0.15

const SHADOW_SIZE = 1.8
const SHADOW_DIST = 9.0

var hvelo: Vector3
var speed: float
var last_floor_y: float
var coyote: float
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	#%Gimbal.global_position = lerp(%Gimbal.global_position, global_position, delta * 2)
	%Gimbal.global_position.y = lerpf(%Gimbal.global_position.y, last_floor_y, delta * 5)
	%Gimbal.global_position.x = global_position.x
	%Gimbal.global_position.z = global_position.z
	%Gimbal.rotation.y = rotation.y
	
	$Shadow.global_position.x = global_position.x
	$Shadow.global_position.z = global_position.z
	
	if $ShadowCast.is_colliding():
		var point = $ShadowCast.get_collision_point()
		$Shadow.global_position.y = point.y
		$Shadow.size.x = SHADOW_SIZE * (1 - (global_position.y - point.y) / SHADOW_DIST)
		$Shadow.size.z = SHADOW_SIZE * (1 - (global_position.y - point.y) / SHADOW_DIST)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		coyote += delta
	else:
		coyote = 0
		if get_last_slide_collision():
			last_floor_y = get_last_slide_collision().get_position().y

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote <= COYOTE_TIME):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		speed = lerpf(speed, RUN_SPEED if Input.is_action_pressed("run") else SPEED, ACCEL)
		hvelo = direction * speed
		velocity.x = hvelo.x
		velocity.z = hvelo.z
	else:
		speed = lerpf(speed, 0, DECEL)
		hvelo = Vector3.ZERO
		velocity.x = move_toward(velocity.x, 0, DECEL)
		velocity.z = move_toward(velocity.z, 0, DECEL)
	
	if input_dir.y > 0:
		$Back.hide()
	elif input_dir.y < 0:
		$Back.show()

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * 0.002
		%Gimbal.rotation.x = clampf(%Gimbal.rotation.x - event.relative.y * 0.002, -PI / 2, PI / 16)
