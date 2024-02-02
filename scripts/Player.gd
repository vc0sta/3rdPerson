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

@onready var _main_camera = %MainCamera3D
@onready var _player_pcam: PhantomCamera3D = %PlayerPhantomCamera3D
@onready var _aim_pcam: PhantomCamera3D = %PlayerAimPhantomCamera3D

@export var targeting = false
@export var target = 0
var target_material = StandardMaterial3D.new()

var snap_vector = Vector3.ZERO

@onready var pivot = $Pivot
@onready var animation = $AnimationTree

func _ready():
	$Pivot/Sprite3D/SubViewport/Label.text = str(is_multiplayer_authority())
	
	if is_multiplayer_authority():
		_main_camera.current = true
		_player_pcam.set_follow_target_node($".")
	
		
func _enter_tree():
	set_multiplayer_authority(name.to_int())
	
	
func _physics_process(delta):
	#var movement_vector = Vector3.ZERO
	if is_multiplayer_authority():
		# Inputs
		handle_inputs(delta)
		
		# Apply movements
		apply_gravity(delta)
		set_velocity(velocity)
		set_up_direction(Vector3.UP)
		set_floor_stop_on_slope_enabled(true)
		move_and_slide()

var horizontal_rotation_sensitiveness = 15

@export var min_yaw: float = -89.9
@export var max_yaw: float = 50

@export var min_pitch: float = 0
@export var max_pitch: float = 360

var tilt_sensitiveness = 15

func apply_rotation() -> void:
	if _player_pcam.get_follow_mode() == _player_pcam.Constants.FollowMode.THIRD_PERSON:
		var active_pcam: PhantomCamera3D
		if is_instance_valid(_aim_pcam):
			_set_pcam_rotation(_player_pcam)
			#_set_pcam_rotation(_aim_pcam)


func _set_pcam_rotation(pcam: PhantomCamera3D) -> void:
	var pcam_rotation_degrees: Vector3
	
	# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
	pcam_rotation_degrees = pcam.get_third_person_rotation_degrees()

	var camera_horizontal_rotation_variation = Focus.get_action_strength("camera_right") -  Focus.get_action_strength("camera_left")
	camera_horizontal_rotation_variation = camera_horizontal_rotation_variation * get_process_delta_time() * 30 * horizontal_rotation_sensitiveness
	# Change the Y rotation value
	pcam_rotation_degrees.y -= camera_horizontal_rotation_variation
	# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
	pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_pitch, max_pitch)

	var tilt_variation = Focus.get_action_strength("camera_up") -  Focus.get_action_strength("camera_down")
	tilt_variation = tilt_variation * get_process_delta_time() * 5 * tilt_sensitiveness

	# Change the X rotation
	pcam_rotation_degrees.x += tilt_variation
	# Clamp the rotation in the X axis so it go over or under the target
	pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_yaw, max_yaw)

	# Change the SpringArm3D node's rotation and rotate around its target
	pcam.set_third_person_rotation_degrees(pcam_rotation_degrees)

func _toggle_aim_pcam(target) -> void:
	_aim_pcam.set_look_at_target(target)
	if (_player_pcam.is_active() or _aim_pcam.is_active()):
		if _player_pcam.get_priority() > _aim_pcam.get_priority():
			_aim_pcam.set_priority(30)
			targeting = true
		else:
			_aim_pcam.set_priority(0)
			targeting = false

func random_target():
	target = $"/root/Map/Targetable".get_child(randi() % len($"/root/Map/Targetable".get_children()))
	target_material.albedo_color = Color("#ff0000")
	target.get_child(0).material_override = target_material
	return target


func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, jump_impulse)
	update_snap_vector()
	
func update_snap_vector():
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN
	
func handle_inputs(delta):
	# Movement
	var input_vector = Vector3.ZERO
	input_vector.x = Focus.get_action_strength("move_right") - Focus.get_action_strength("move_left")
	input_vector.z = Focus.get_action_strength("move_back") - Focus.get_action_strength("move_forward")
	input_vector = input_vector.normalized() if input_vector.length() > 1 else input_vector
	
	var direction = (input_vector.x * _main_camera.global_transform.basis.x) + (input_vector.z * _main_camera.global_transform.basis.z )
	
	# Set movement velocity
	if direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(direction * max_speed, acceleration * delta).z
		
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), rot_speed * delta)
	else:
		if is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		else:
			velocity.x = velocity.move_toward(direction * max_speed, air_friction * delta).x
			velocity.z = velocity.move_toward(direction * max_speed, air_friction * delta).z
	
	# Camera
	if _player_pcam.get_follow_mode() == _player_pcam.Constants.FollowMode.THIRD_PERSON:
		var pcam_rotation_degrees: Vector3

		# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
		pcam_rotation_degrees = _player_pcam.get_third_person_rotation_degrees()

		var camera_horizontal_rotation_variation = Focus.get_action_strength("camera_right") -  Focus.get_action_strength("camera_left")
		camera_horizontal_rotation_variation = camera_horizontal_rotation_variation * get_process_delta_time() * 30 * horizontal_rotation_sensitiveness
		# Change the Y rotation value
		pcam_rotation_degrees.y -= camera_horizontal_rotation_variation
		# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
		pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_pitch, max_pitch)

		var tilt_variation = Focus.get_action_strength("camera_up") -  Focus.get_action_strength("camera_down")
		tilt_variation = tilt_variation * get_process_delta_time() * 5 * tilt_sensitiveness

		# Change the X rotation
		pcam_rotation_degrees.x += tilt_variation
		# Clamp the rotation in the X axis so it go over or under the target
		pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_yaw, max_yaw)

		# Change the SpringArm3D node's rotation and rotate around its target
		_player_pcam.set_third_person_rotation_degrees(pcam_rotation_degrees)
		
	# Target
	if Focus.is_action_just_pressed("target"):
		_toggle_aim_pcam(random_target())
	
	# Jumping
	if Focus.is_action_just_pressed("jump") and is_on_floor():
		snap_vector = Vector3.ZERO
		velocity.y = jump_impulse
		animation.set("parameters/on_air/transition_request", "true")
	if Focus.is_action_just_released("jump") and velocity.y > jump_impulse / 2:
		velocity.y = jump_impulse / 2
		
	# Set animations
	if targeting:
		$Pivot.look_at(target.position)
	animation.set("parameters/Movement/blend_amount", input_vector.length())
	if is_on_floor():
		animation.set("parameters/on_air/transition_request", "false")

	
