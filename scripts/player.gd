class_name Player
extends CharacterBody3D

enum State {
	GROUND,
	AIR,
	LEDGE,
	WALLSLIDE,
	#ROLL,
}

const JUMP_PARTICLES = preload("res://scenes/jump_particles.tscn")

const ACCEL = 0.15
const DECEL = 0.27
const AIR_ACCEL = 0.03
const ADDVELO_DECEL_AIR = 0.04
const ADDVELO_DECEL_GROUND = 0.1

const CAMERA_HEIGHT = 3.5
const SHAKE_REDUCE = 3.0
const FALL_STRENGTH = 0.004
const FALL_SHAKE_VELOCITY = 35.0

const SPEED = 6.0
const RUN_SPEED = 12.5
const LEDGE_SPEED = 4.0

const COYOTE_TIME = 0.15
const JUMP_VELOCITY = 15.0
const ADD_JUMP_VELOCITY = 0.75
const WALLJUMP_VELOCITY = 16.0
const WALLJUMP_HORIZONTAL = 26.0
const JUMP_LENGTH = 0.12
#const ROLL_TIME = 0.5
#const ROLL_FALL_VELO = -30.0
const STEP_HEIGHT = 0.51

const MAX_STAMINA = 10.0
const WALLJUMP_COST = 3.0
const AIR_RECOVERY = 2.5 # per second
const WALL_RECOVERY = 1.5

const BACK_POS = Vector3(0, 0, 0.01)

const SHADOW_SIZE = 1.8
const SHADOW_DIST = 9.0

const INTERACT_SPIN_SPEED = 1.8
const INTERACT_SPIN_RAD = 80.0

var hvelo: Vector3
var add_velo: Vector3
var speed: float
var last_floor_y: float
var coyote: float
var last_wall_normal: Vector3
var jump_time: float
var roll_time: float
var stamina: float = MAX_STAMINA
var jump_buffered: bool
var last_velocity: Vector3
var last_input: Vector2
var shake: float
var can_move: bool = true
var time: float
var can_interact: bool
var state: State = State.GROUND
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var gimbal = $Gimbal
@onready var camera = $Gimbal/Camera
@onready var col_shape = $CollisionShape3D
@onready var smoke_particles = $SmokeParticles
@onready var shadow = $Shadow
@onready var shadow_cast = $ShadowCast
@onready var sprite = $Sprite
@onready var step_cast_top = $StepCastTop
@onready var step_cast_bot = $StepCastBottom
@onready var wall_cast = $WallCast
@onready var grab_cast = $GrabCast
@onready var head_cast = $HeadCast

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	#gimbal.global_position = lerp(gimbal.global_position, global_position, delta * 2)
	time += delta
	
	gimbal.global_position.y = lerpf(gimbal.global_position.y, last_floor_y + CAMERA_HEIGHT, delta * 5)
	gimbal.global_position.x = global_position.x
	gimbal.global_position.z = global_position.z
	gimbal.rotation.y = rotation.y
	
	shadow.global_position.x = global_position.x
	shadow.global_position.z = global_position.z
	
	if shadow_cast.is_colliding():
		var point = shadow_cast.get_collision_point()
		shadow.global_position.y = point.y
		shadow.size.x = SHADOW_SIZE * (1 - (global_position.y - point.y) / SHADOW_DIST)
		shadow.size.z = SHADOW_SIZE * (1 - (global_position.y - point.y) / SHADOW_DIST)
	
	camera.h_offset = randfn(0, shake)
	camera.v_offset = randfn(0, shake)
	
	shake = lerpf(shake, 0, delta * SHAKE_REDUCE)
	
	if can_interact:
		MiscUI.interact_icon.modulate.a = lerpf(MiscUI.interact_icon.modulate.a, 1.0, delta * 10)
		MiscUI.interact_icon.position = lerp(MiscUI.interact_icon.position, camera.unproject_position(global_position) + Vector2(cos(time * INTERACT_SPIN_SPEED), sin(time * INTERACT_SPIN_SPEED)) * INTERACT_SPIN_RAD, delta * 10)
	else:
		MiscUI.interact_icon.modulate.a = lerpf(MiscUI.interact_icon.modulate.a, 0.0, delta * 10)
		MiscUI.interact_icon.position = lerp(MiscUI.interact_icon.position, camera.unproject_position(global_position), delta * 10)
	
	#$StepCast.target_position

func _physics_process(delta):
	if not can_move:
		return
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	match state:
		State.GROUND:
			$CanvasLayer/Label.text = "state: GROUND"
			ground(delta, input_dir)
		State.AIR:
			$CanvasLayer/Label.text = "state: AIR"
			air(delta, input_dir)
		State.LEDGE:
			$CanvasLayer/Label.text = "state: LEDGE"
			ledge(delta, input_dir)
		State.WALLSLIDE:
			$CanvasLayer/Label.text = "state: WALLSLIDE"
			wall_slide(delta, input_dir)
		#State.ROLL:
			#$CanvasLayer/Label.text = "state: ROLL"
			#roll(delta, input_dir)
	
	velocity += add_velo
	$CanvasLayer/Label.text += "\nvelocity: %s // %s" % [get_real_velocity(), get_real_velocity().length()]
	$CanvasLayer/Label.text += "\nstamina: %s // %s" % [snappedf(stamina, 0.01), snappedf(pow(stamina / MAX_STAMINA, 0.4), 0.01)]
	
	if input_dir:
		last_input = input_dir
	#if input_dir.y:
		#sprite.rotation.x
	
	#sprite.speed_scale = 1.6 if Input.is_action_pressed("run") else 1.0
	
	#stamina = clampf(stamina + delta * 1.5, 0, MAX_STAMINA)

	last_velocity = get_real_velocity()
	move_and_slide()
	
	RenderingServer.global_shader_parameter_set("ca_strength", maxf((get_real_velocity().length() - RUN_SPEED) * 0.001 + Global.DEFAULT_CA, Global.DEFAULT_CA))

func ground(delta: float, input_dir: Vector2):
	coyote = 0
	stamina = MAX_STAMINA
	
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
	
	add_velo = lerp(add_velo, Vector3.ZERO, ADDVELO_DECEL_GROUND)
	
	if input_dir.x < 0:
		sprite.flip_h = true
	elif input_dir.x > 0:
		sprite.flip_h = false
	
	if input_dir.y > 0:
		sprite.play("walk_front")
	elif input_dir.y < 0:
		if Input.is_action_pressed("run"):
			sprite.play("run_back")
		else:
			sprite.play("walk_back")
	elif input_dir.x != 0:
		if Input.is_action_pressed("run"):
			sprite.play("run_side")
		else:
			sprite.play("walk_side")
	else:
		if last_input.y > 0:
			sprite.play("walk_front")
		elif last_input.x != 0:
			sprite.play("idle_side")
		else:
			sprite.play("idle_back")
	
	if Input.is_action_just_pressed("jump"):
		coyote = COYOTE_TIME + 0.1
		velocity.y = JUMP_VELOCITY
		state = State.AIR
		sprite.play("jump_back")
		#$JumpParticles.restart()
		spawn_jump_particles()
	
	if not is_on_floor():
		state = State.AIR
	
	if step_cast_top.is_colliding():
		var diff = absf(step_cast_top.get_collision_point(0).y - global_position.y + 1.2)
		if diff < STEP_HEIGHT:
			if step_cast_bot.get_collision_normal(0).dot(direction) < 0:
				global_position.y += diff + 0.01

func air(delta: float, input_dir: Vector2):
	velocity.y -= gravity * delta
	coyote += delta
	stamina = clampf(stamina + AIR_RECOVERY * delta, 0, MAX_STAMINA)
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	hvelo = lerp(hvelo, direction * (RUN_SPEED if Input.is_action_pressed("run") else SPEED), AIR_ACCEL)
	velocity.x = hvelo.x
	velocity.z = hvelo.z
	
	add_velo = lerp(add_velo, Vector3.ZERO, ADDVELO_DECEL_AIR)
	
	if $LandCast.is_colliding() and velocity.y < 0:
		sprite.play("land_back")
	
	if Input.is_action_just_pressed("jump"):
		if coyote <= COYOTE_TIME:
			coyote = COYOTE_TIME + delta
			velocity.y = JUMP_VELOCITY
			sprite.play("jump_back")
		else:
			jump_buffered = true
	
	if Input.is_action_pressed("jump"):
		if coyote > COYOTE_TIME:
			if jump_time <= JUMP_LENGTH:
				jump_time += delta
				velocity.y += ADD_JUMP_VELOCITY
	
	if Input.is_action_just_released("jump"):
		jump_time = JUMP_LENGTH + delta
		jump_buffered = false
	
	if is_on_floor():
		jump_time = 0
		last_floor_y = global_position.y - 1
		
		#if last_velocity.y < ROLL_FALL_VELO:
			#hvelo = direction * abs(last_velocity.y)
			#velocity.x = hvelo.x
			#velocity.z = hvelo.z
			#roll_time = 0
			#state = State.ROLL
		#else:
		if absf(last_velocity.y) > FALL_SHAKE_VELOCITY:
			add_shake(last_velocity.y * FALL_STRENGTH)
		
		if jump_buffered:
			jump_buffered = false
			jump_time = 0
			coyote = COYOTE_TIME + 0.1
			#hvelo += direction * absf(last_velocity.y)
			add_velo += direction * (pow(absf(last_velocity.y), 0.7) * 0.7 + maxf(log(absf(last_velocity.y) - JUMP_VELOCITY), 0))
			velocity.y = JUMP_VELOCITY
			sprite.play("jump_back")
			spawn_jump_particles()
		else:
			state = State.GROUND
	elif wall_cast.is_colliding():
		if grab_cast.is_colliding() and not head_cast.is_colliding() and velocity.y < 0:
			velocity.y = 0
			last_floor_y = global_position.y - col_shape.shape.height / 2
			state = State.LEDGE
			jump_buffered = false
		elif velocity.y <= 0:
			state = State.WALLSLIDE
			jump_buffered = false

func ledge(delta: float, input_dir: Vector2):
	stamina = MAX_STAMINA
	
	add_velo = lerp(add_velo, Vector3.ZERO, ADDVELO_DECEL_GROUND)
	
	if wall_cast.is_colliding():
		var angle = (camera.global_basis.z * Vector3(1, 0, 1)).signed_angle_to(wall_cast.get_collision_normal(0), Vector3.UP)
		#sprite.flip_h = 
		if absf(angle) < PI / 5:
			sprite.play("ledge_back")
			if input_dir.x < 0:
				sprite.flip_h = true
			elif input_dir.x > 0:
				sprite.flip_h = false
		else:
			sprite.play("ledge_side")
			sprite.flip_h = angle > 0
	if not input_dir:
		sprite.stop()
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if wall_cast.is_colliding():
		#$RayCast3D.target_position = wall_cast.get_collision_normal(0) * 2
		#$RayCast3D.global_rotation = Vector3.ZERO
		#$RayCast3D2.target_position = wall_cast.get_collision_normal(0).rotated(Vector3.UP, PI / 2).abs().round() * 2
		#$RayCast3D2.global_rotation = Vector3.ZERO
		if not head_cast.is_colliding():
			hvelo = lerp(hvelo, direction.round() * LEDGE_SPEED * wall_cast.get_collision_normal(0).rotated(Vector3.UP, PI / 2).abs().round() - wall_cast.get_collision_normal(0) * 3, ACCEL)
			velocity.x = hvelo.x
			velocity.z = hvelo.z
			last_wall_normal = wall_cast.get_collision_normal(0)
		else:
			velocity = lerp(velocity, head_cast.get_collision_normal(0).round() * 20, 0.3)
	else:
		velocity = lerp(velocity, -last_wall_normal * 7, 0.3)
	
	if Input.is_action_just_pressed("jump"):
		jump_time = JUMP_LENGTH + delta
		velocity.y = JUMP_VELOCITY
		state = State.AIR
		sprite.play("jump_back")

func wall_slide(delta: float, input_dir: Vector2):
	stamina = clampf(stamina + WALL_RECOVERY * delta, 0, MAX_STAMINA)
	
	add_velo = lerp(add_velo, Vector3.ZERO, ADDVELO_DECEL_AIR)
	
	sprite.play("wall_side")
	if wall_cast.is_colliding():
		sprite.flip_h = camera.global_basis.z.signed_angle_to(wall_cast.get_collision_normal(0), Vector3.UP) > 0
	smoke_particles.emitting = true
	
	velocity.y -= gravity * delta * 0.48
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	hvelo = lerp(hvelo, direction * SPEED, 0.03)
	velocity.x = hvelo.x
	velocity.z = hvelo.z
	
	if Input.is_action_just_pressed("jump"):
		if wall_cast.is_colliding():
			jump_time = JUMP_LENGTH + delta
			if not head_cast.is_colliding():
				velocity.y = JUMP_VELOCITY
			else:
				add_velo += wall_cast.get_collision_normal(0) * WALLJUMP_HORIZONTAL * Vector3(1, 0, 1) + direction * WALLJUMP_HORIZONTAL / 2
				velocity.y = WALLJUMP_VELOCITY * maxf(pow(stamina / MAX_STAMINA, 0.4), 0.05)
				last_floor_y = global_position.y - col_shape.shape.height / 2
				stamina -= WALLJUMP_COST
			state = State.AIR
			smoke_particles.emitting = false
			#$JumpParticles.restart()
			spawn_jump_particles()
	
	if is_on_floor():
		jump_time = 0
		state = State.GROUND
		smoke_particles.emitting = false
	elif not wall_cast.is_colliding() or velocity.y > 0:
		state = State.AIR
		smoke_particles.emitting = false
	else:
		if grab_cast.is_colliding():
			var normal = grab_cast.get_collision_normal(0)
			var dot = normal.dot(direction)
			if not head_cast.is_colliding() and dot < 0:
				velocity.y = 0
				state = State.LEDGE
				smoke_particles.emitting = false

#func roll(delta: float, _input_dir: Vector2):
	#roll_time += delta
	#
	#var direction = -transform.basis.z
	#hvelo = lerp(hvelo, direction * SPEED, 0.015)
	#velocity.x = hvelo.x
	#velocity.z = hvelo.z
	#
	#if Input.is_action_just_pressed("jump") or jump_buffered:
		#coyote = COYOTE_TIME + delta
		#velocity.y = JUMP_VELOCITY
		#state = State.AIR
		##$JumpParticles.restart()
		#spawn_jump_particles()
	#
	#elif roll_time > ROLL_TIME:
		#state = State.GROUND

func prepare_fight():
	RenderingServer.global_shader_parameter_set("ca_strength", Global.DEFAULT_CA)
	sprite.play("idle_back")
	can_move = false

func post_fight():
	can_move = true
	camera.make_current()

func spawn_jump_particles():
	var particles = JUMP_PARTICLES.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position - Vector3(0, col_shape.shape.height / 2, 0)
	particles.restart()

func add_shake(amount: float):
	shake += amount

func _input(event):
	if not can_move:
		return
	
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * 0.002
		gimbal.rotation.x = clampf(gimbal.rotation.x - event.relative.y * 0.002, -PI / 2.5, PI / 16)
