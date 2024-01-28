extends CharacterBody3D

@export var max_speed = 15
@export var acceleration = 70
@export var friction = 300
@export var air_friction = 5
@export var gravity = -40
@export var jump_impulse = 20
@export var mouse_sensitivity = .1
@export var controller_sensitivity = 3
@export var rot_speed = 30
@export var movement_vector = Vector3.ZERO

var snap_vector = Vector3.ZERO

@onready var pivot = $Pivot
@onready var animation = $AnimationTree

@onready var cam = $CamOrigin/SpringArm3D/Camera3D
@onready var name_label = $Sprite3D/SubViewport/Label

func _ready():
	cam.current = is_multiplayer_authority()
	name_label.text = "Player " + name + str(is_multiplayer_authority())
	
func _enter_tree():
	set_multiplayer_authority(name.to_int())
	
func _physics_process(delta):
	if is_multiplayer_authority():
		var input_vector = get_input_vector()
		var direction = get_direction(input_vector)
		movement_vector = input_vector
		apply_movement(input_vector, direction, delta)
		apply_friction(direction, delta)
		apply_gravity(delta)
		update_snap_vector()
		jump()
		#apply_controller_rotation()
		set_velocity(velocity)
		set_up_direction(Vector3.UP)
		set_floor_stop_on_slope_enabled(true)
		move_and_slide()
		velocity = velocity
	animation.set("parameters/Movement/blend_amount", movement_vector.length())
	
func get_input_vector():
	var input_vector = Vector3.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector
	
func get_direction(input_vector):
	var direction = (input_vector.x * transform.basis.x) + (input_vector.z * transform.basis.z ) 
	return direction
	
func apply_movement(input_vector, direction, delta):
	if direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(direction * max_speed, acceleration * delta).z

		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-input_vector.x, -input_vector.z), rot_speed * delta)
		
func apply_friction(direction, delta):
	if direction == Vector3.ZERO:
		if is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		else:
			velocity.x = velocity.move_toward(direction * max_speed, air_friction * delta).x
			velocity.z = velocity.move_toward(direction * max_speed, air_friction * delta).z
		
func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, jump_impulse)
	
	
func update_snap_vector():
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN
	
func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap_vector = Vector3.ZERO
		velocity.y = jump_impulse
	if Input.is_action_just_released("jump") and velocity.y > jump_impulse / 2:
		velocity.y = jump_impulse / 2
		
func apply_controller_rotation():
	var axis_vector = Vector2.ZERO
	axis_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	#axis_vector.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	#if InputEventJoypadMotion:
		#$CamOrigin/SpringArm3D.rotate_y(deg_to_rad(-axis_vector.x) * controller_sensitivity)
		#$CamOrigin/SpringArm3D.rotate_x(deg_to_rad(-axis_vector.y) * controller_sensitivity)
	
