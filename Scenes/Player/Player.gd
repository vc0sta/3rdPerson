extends CharacterBody3D

@export var max_speed = 20
@export var acceleration = 70
@export var friction = 350
@export var air_friction = 5
@export var gravity = -70
@export var jump_impulse = 20
@export var mouse_sensitivity = .1
@export var controller_sensitivity = 3
@export var rot_speed = 30
@export var movement_vector = Vector3.ZERO

@export var targeting = false
@export var target = 0
var target_material = StandardMaterial3D.new()

var snap_vector = Vector3.ZERO

@onready var pivot = $Pivot
@onready var animation = $AnimationTree

var transitioning = false
@onready var dummy = $dummy_cam
@onready var cam = $ThirdPersonCamera/Camera
@onready var target_cam = $Pivot/TargetingCamera
@onready var name_label = $Sprite3D/SubViewport/Label

func _ready():
	cam.current = is_multiplayer_authority()
	name_label.text = "Player" + name
	
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
		set_velocity(velocity)
		set_up_direction(Vector3.UP)
		set_floor_stop_on_slope_enabled(true)
		move_and_slide()
		get_buttons()
		#velocity = velocity
		if targeting and !transitioning:
			$Pivot.look_at(target.position)
			
	animation.set("parameters/Movement/blend_amount", movement_vector.length())
	if is_on_floor():
		animation.set("parameters/on_air/transition_request", "false")

func change_camera(from, to, duration: float = 0.2):
	if transitioning: return
	
	dummy.fov = from.fov
	dummy.cull_mask = from.cull_mask
	dummy.global_transform = from.global_transform
	dummy.make_current()
	
	transitioning = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(dummy, "global_transform", to.global_transform, duration).from(dummy.global_transform)

	tween.tween_property(dummy, "fov", to.fov, duration).from(dummy.fov)

	# Wait for the tween to complete
	await tween.finished
	
	# Make the second camera current
	to.current = true
	transitioning = false
	
func get_buttons():
	if Focus.is_action_just_pressed("target"):
		if targeting:
			target_material.albedo_color = Color("#902d4a")
			target.get_child(0).material_override = target_material
			$ThirdPersonCamera.remove_target()
			change_camera(target_cam, cam)
		else:
			random_target()
			$Pivot.look_at(target.position)
			change_camera(cam, target_cam)
		targeting = !targeting
		
		
func random_target():
	target = $"../Targetable".get_child(randi() % len($"../Targetable".get_children()))
	target_material.albedo_color = Color("#ff0000")
	target.get_child(0).material_override = target_material
	$ThirdPersonCamera.set_target(target)
	
func get_input_vector():
	var input_vector = Vector3.ZERO
	input_vector.x = Focus.get_action_strength("move_right") - Focus.get_action_strength("move_left")
	input_vector.z = Focus.get_action_strength("move_back") - Focus.get_action_strength("move_forward")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector
	
func get_direction(input_vector):
	var direction = (input_vector.x * cam.transform.basis.x) + (input_vector.z * cam.transform.basis.z )
	return direction
	
func apply_movement(input_vector, direction, delta):
	if direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(direction * max_speed, acceleration * delta).z

		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), rot_speed * delta)
		
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
	if Focus.is_action_just_pressed("jump") and is_on_floor():
		snap_vector = Vector3.ZERO
		velocity.y = jump_impulse
		animation.set("parameters/on_air/transition_request", "true")
	if Focus.is_action_just_released("jump") and velocity.y > jump_impulse / 2:
		velocity.y = jump_impulse / 2

	
