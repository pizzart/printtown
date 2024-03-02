class_name Player
extends CharacterBody3D

enum State {
	GROUND,
	AIR,
	LEDGE,
	WALLSLIDE,
	ROLL,
}

const JUMP_PARTICLES = preload("res://scenes/jump_particles.tscn")

const ACCEL = 0.2
const DECEL = 0.3
const ADDVELO_DECEL = 0.055

const CAMERA_HEIGHT = 3.5

const SPEED = 6.0
const RUN_SPEED = 12.0
const LEDGE_SPEED = 4.0

const COYOTE_TIME = 0.15
const JUMP_VELOCITY = 15.0
const ADD_JUMP_VELOCITY = 0.75
const WALLJUMP_VELOCITY = 16.0
const WALLJUMP_HORIZONTAL = 26.0
const JUMP_LENGTH = 0.12
const ROLL_TIME = 0.5
const ROLL_FALL_VELO = -30.0

const BACK_POS = Vector3(0, 0, 0.01)

const SHADOW_SIZE = 1.8
const SHADOW_DIST = 9.0

var hvelo: Vector3
var add_velo: Vector3
var speed: float
var last_floor_y: float
var coyote: float
var last_wall_normal: Vector3
var jump_time: float
var roll_time: float
var last_velocity: Vector3
var can_move: bool = true
var state: State = State.GROUND
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Gimbal/Camera

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	#%Gimbal.global_position = lerp(%Gimbal.global_position, global_position, delta * 2)
	%Gimbal.global_position.y = lerpf(%Gimbal.global_position.y, last_floor_y + CAMERA_HEIGHT, delta * 5)
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
	
	#$StepCast.target_position

func _physics_process(delta):
	if not can_move:
		return
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	match state:
		State.GROUND:
			$CanvasLayer/Label.text = "state: GROUND"
			ground(input_dir, delta)
		State.AIR:
			$CanvasLayer/Label.text = "state: AIR"
			air(delta, input_dir)
		State.LEDGE:
			$CanvasLayer/Label.text = "state: LEDGE"
			ledge(delta, input_dir)
		State.WALLSLIDE:
			$CanvasLayer/Label.text = "state: WALLSLIDE"
			wall_slide(delta, input_dir)
		State.ROLL:
			$CanvasLayer/Label.text = "state: ROLL"
			roll(delta, input_dir)
	
	velocity += add_velo
	add_velo = lerp(add_velo, Vector3.ZERO, ADDVELO_DECEL)
	$CanvasLayer/Label.text += "\nvelocity: %s" % get_real_velocity()
	
	#if input_dir.y:
		#$Sprite.rotation.x
	
	$Sprite.flip_h = input_dir.x < 0
	if input_dir.x != 0:
		$Sprite.play("side")
	elif input_dir.y > 0:
		$Sprite.play("front")
	elif input_dir.y < 0:
		$Sprite.play("back")
	else:
		$Sprite.stop()
	
	$Sprite.speed_scale = 1.6 if Input.is_action_pressed("run") else 1.0

	move_and_slide()
	
	last_velocity = get_real_velocity()

func ground(input_dir: Vector2, _delta: float):
	coyote = 0
	var col = get_last_slide_collision()
	if col:
		last_floor_y = col.get_position().y
	
	var direction = (transform.basis * Vector3(input_dir.x * (0.3 if Input.is_action_pressed("run") else 1.0), 0, input_dir.y)).normalized()
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
		#$JumpParticles.restart()
		spawn_jump_particles()
	
	if not is_on_floor():
		state = State.AIR
	
	if $StepCastBottom.is_colliding() and not $StepCastTop.is_colliding():
		if $StepCastBottom.get_collision_normal(0).dot(direction) < 0:
			global_position.y += 0.5

func air(delta: float, input_dir: Vector2):
	velocity.y -= gravity * delta
	coyote += delta
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	hvelo = lerp(hvelo, direction * (RUN_SPEED if Input.is_action_pressed("run") else SPEED), 0.05)
	velocity.x = hvelo.x
	velocity.z = hvelo.z
	
	if Input.is_action_just_pressed("jump"):
		if coyote <= COYOTE_TIME:
			coyote = COYOTE_TIME + 0.1
			velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("jump"):
		if coyote > COYOTE_TIME:
			if jump_time <= JUMP_LENGTH:
				jump_time += delta
				velocity.y += ADD_JUMP_VELOCITY
	
	if Input.is_action_just_released("jump"):
		jump_time = JUMP_LENGTH + delta
	
	if is_on_floor():
		jump_time = 0
		last_floor_y = global_position.y - 1
		if last_velocity.y < ROLL_FALL_VELO:
			hvelo = direction * abs(last_velocity.y)
			velocity.x = hvelo.x
			velocity.z = hvelo.z
			roll_time = 0
			state = State.ROLL
		else:
			state = State.GROUND
	elif $WallCast.is_colliding():
		if $GrabCast.is_colliding() and not $HeadCast.is_colliding() and velocity.y < 0:
			velocity.y = 0
			last_floor_y = global_position.y - 2
			state = State.LEDGE
		elif velocity.y <= 0:
			state = State.WALLSLIDE

func ledge(delta: float, input_dir: Vector2):
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if $WallCast.is_colliding():
		#$RayCast3D.target_position = $WallCast.get_collision_normal(0) * 2
		#$RayCast3D.global_rotation = Vector3.ZERO
		#$RayCast3D2.target_position = $WallCast.get_collision_normal(0).rotated(Vector3.UP, PI / 2).abs().round() * 2
		#$RayCast3D2.global_rotation = Vector3.ZERO
		if not $HeadCast.is_colliding():
			hvelo = lerp(hvelo, direction.round() * LEDGE_SPEED * $WallCast.get_collision_normal(0).rotated(Vector3.UP, PI / 2).abs().round() - $WallCast.get_collision_normal(0) * 3, ACCEL)
			velocity.x = hvelo.x
			velocity.z = hvelo.z
			last_wall_normal = $WallCast.get_collision_normal(0)
		else:
			velocity = lerp(velocity, $HeadCast.get_collision_normal(0).round() * 20, 0.3)
	else:
		velocity = lerp(velocity, -last_wall_normal * 5, 0.3)
	
	if Input.is_action_just_pressed("jump"):
		jump_time = JUMP_LENGTH + delta
		velocity.y = JUMP_VELOCITY
		state = State.AIR

func wall_slide(delta: float, input_dir: Vector2):
	$SmokeParticles.emitting = true
	velocity.y -= gravity * delta * 0.5
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	hvelo = lerp(hvelo, direction * SPEED, 0.05)
	velocity.x = hvelo.x
	velocity.z = hvelo.z
	
	if Input.is_action_just_pressed("jump"):
		if $WallCast.is_colliding():
			jump_time = JUMP_LENGTH + delta
			if not $HeadCast.is_colliding():
				velocity.y = JUMP_VELOCITY
			else:
				add_velo += $WallCast.get_collision_normal(0) * WALLJUMP_HORIZONTAL * Vector3(1, 0, 1)
				velocity.y = WALLJUMP_VELOCITY
				last_floor_y = global_position.y - 2
			state = State.AIR
			$SmokeParticles.emitting = false
			#$JumpParticles.restart()
			spawn_jump_particles()
	
	if is_on_floor():
		jump_time = 0
		state = State.GROUND
		$SmokeParticles.emitting = false
	elif not $WallCast.is_colliding() or velocity.y > 0:
		state = State.AIR
		$SmokeParticles.emitting = false
	else:
		var normal = $GrabCast.get_collision_normal(0)
		var dot = normal.dot(direction)
		if $GrabCast.is_colliding() and not $HeadCast.is_colliding() and dot < 0:
			velocity.y = 0
			state = State.LEDGE
			$SmokeParticles.emitting = false

func roll(delta: float, _input_dir: Vector2):
	roll_time += delta
	
	var direction = -transform.basis.z
	hvelo = lerp(hvelo, direction * SPEED, 0.015)
	velocity.x = hvelo.x
	velocity.z = hvelo.z
	
	if Input.is_action_just_pressed("jump"):
		coyote = COYOTE_TIME + 0.1
		velocity.y = JUMP_VELOCITY
		state = State.AIR
		#$JumpParticles.restart()
		spawn_jump_particles()
	
	elif roll_time > ROLL_TIME:
		state = State.GROUND

func prepare_fight():
	$Sprite.play("back")
	$Sprite.speed_scale = 1
	can_move = false

func post_fight():
	can_move = true
	camera.make_current()

func spawn_jump_particles():
	var particles = JUMP_PARTICLES.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position - Vector3(0, 1.5, 0)
	particles.restart()

func _input(event):
	if not can_move:
		return
	
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * 0.002
		%Gimbal.rotation.x = clampf(%Gimbal.rotation.x - event.relative.y * 0.002, -PI / 2.5, PI / 16)
