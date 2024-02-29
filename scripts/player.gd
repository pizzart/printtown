class_name Player
extends CharacterBody3D

enum State {
	GROUND,
	AIR,
	LEDGE,
	WALLSLIDE,
}

const ACCEL = 0.2
const DECEL = 0.3

const SPEED = 6.0
const RUN_SPEED = 12.0
const LEDGE_SPEED = 4.0

const COYOTE_TIME = 0.15
const JUMP_VELOCITY = 17.0
const WALLJUMP_VELOCITY = 14.0
const WALLJUMP_HORIZONTAL = 22.0

const BACK_POS = Vector3(0, 0, 0.01)

const SHADOW_SIZE = 1.8
const SHADOW_DIST = 9.0

var hvelo: Vector3
var add_velo: Vector3
var speed: float
var last_floor_y: float
var coyote: float
var state: State = State.GROUND
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	#%Gimbal.global_position = lerp(%Gimbal.global_position, global_position, delta * 2)
	%Gimbal.global_position.y = lerpf(%Gimbal.global_position.y, last_floor_y + 3, delta * 5)
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
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	match state:
		State.GROUND:
			ground(input_dir, delta)
		State.AIR:
			air(delta, input_dir)
		State.LEDGE:
			ledge(delta, input_dir)
		State.WALLSLIDE:
			wall_slide(delta, input_dir)
	
	velocity += add_velo
	add_velo = lerp(add_velo, Vector3.ZERO, 0.1)
	
	#if input_dir.y:
		#$Sprite.rotation.x
	
	if input_dir.x > 0:
		$Sprite.play("side")
		$Sprite.flip_h = false
	elif input_dir.x < 0:
		$Sprite.play("side")
		$Sprite.flip_h = true
	elif input_dir.y > 0:
		$Sprite.play("front")
		$Sprite.flip_h = false
	elif input_dir.y < 0:
		$Sprite.play("back")
		$Sprite.flip_h = false
	else:
		$Sprite.stop()
	
	$Sprite.speed_scale = 1.6 if Input.is_action_pressed("run") else 1

	move_and_slide()

func ground(input_dir: Vector2, _delta: float):
	coyote = 0
	var col = get_last_slide_collision()
	if col:
		last_floor_y = col.get_position().y
	
	var direction = (transform.basis * Vector3(input_dir.x * (0.3 if Input.is_action_pressed("run") else 1), 0, input_dir.y)).normalized()
	if direction:
		speed = lerpf(speed, RUN_SPEED if Input.is_action_pressed("run") else SPEED, ACCEL)
		hvelo = lerp(hvelo, direction * speed, 0.5)
		velocity.x = hvelo.x
		velocity.z = hvelo.z
	else:
		speed = lerpf(speed, 0, DECEL)
		hvelo = Vector3.ZERO
		velocity = lerp(velocity, Vector3(0, velocity.y, 0), DECEL)
	
	if Input.is_action_just_pressed("jump"):
		coyote = COYOTE_TIME + 0.1
		velocity.y = JUMP_VELOCITY
		state = State.AIR
	
	if not is_on_floor():
		state = State.AIR

func air(delta: float, input_dir: Vector2):
	velocity.y -= gravity * delta
	coyote += delta
	
	if $WallCast.is_colliding():
		if $GrabCast.is_colliding() and not $HeadCast.is_colliding() and velocity.y < 0:
			velocity.y = 0
			state = State.LEDGE
		elif velocity.y <= 0:
			state = State.WALLSLIDE
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	hvelo = lerp(hvelo, direction * SPEED, 0.05)
	velocity.x = hvelo.x
	velocity.z = hvelo.z
	
	if Input.is_action_just_pressed("jump"):
		if coyote <= COYOTE_TIME:
			coyote = COYOTE_TIME + 0.1
			velocity.y = JUMP_VELOCITY
	
	if is_on_floor():
		state = State.GROUND

func ledge(delta: float, input_dir: Vector2):
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if $WallCast.is_colliding():
		hvelo = lerp(hvelo, direction * LEDGE_SPEED * $WallCast.get_collision_normal(0).rotated(Vector3.UP, PI / 2).abs(), ACCEL)
		velocity.x = hvelo.x
		velocity.z = hvelo.z
	else:
		velocity = lerp(velocity, Vector3.ZERO, 0.3)
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		state = State.AIR

func wall_slide(delta: float, input_dir: Vector2):
	velocity.y -= gravity * delta * 0.5
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	hvelo = lerp(hvelo, direction * SPEED, 0.05)
	velocity.x = hvelo.x
	velocity.z = hvelo.z
	
	if Input.is_action_just_pressed("jump"):
		if $WallCast.is_colliding():
			add_velo += $WallCast.get_collision_normal(0) * WALLJUMP_HORIZONTAL
			velocity.y = WALLJUMP_VELOCITY
			last_floor_y = global_position.y - 2
	
	if is_on_floor():
		state = State.GROUND
	elif not $WallCast.is_colliding() or velocity.y > 0:
		state = State.AIR
	else:
		var normal = $GrabCast.get_collision_normal(0)
		var dot = normal.dot(direction)
		if $GrabCast.is_colliding() and not $HeadCast.is_colliding() and dot > 0:
			velocity.y = 0
			state = State.LEDGE

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * 0.002
		%Gimbal.rotation.x = clampf(%Gimbal.rotation.x - event.relative.y * 0.002, -PI / 2.5, PI / 16)
