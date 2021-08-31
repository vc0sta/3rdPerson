extends KinematicBody

export var max_speed = 30
export var gravity = 70
export var jump_impulse = 25

var velocity = Vector3.ZERO

var player_state

onready var pivot = $Pivot

func _physics_process(delta):
	var input_vector = get_input_vector()
	apply_movement(input_vector)
	apply_gravity(delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	define_player_state()
	
func get_input_vector():
	var input_vector = Vector3.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	
	return input_vector.normalized()
	

func apply_movement(input_vector):
	velocity.x = input_vector.x * max_speed
	velocity.z = input_vector.z * max_speed
	
	if input_vector != Vector3.ZERO:
		pivot.look_at(translation + input_vector, Vector3.UP)
		
	if Input.is_action_just_pressed("jump"):
		print("SPACE pressed")
		Server.fetch_skill_damage("Sword", get_instance_id())
	

func apply_gravity(delta):
	velocity.y -= gravity * delta
	
func set_damage(damage):
	print("Damage: " + str(damage))

func define_player_state():
	player_state = {"T": OS.get_system_time_msecs(), "P": global_transform.origin }
	Server.send_player_state(player_state)
	
