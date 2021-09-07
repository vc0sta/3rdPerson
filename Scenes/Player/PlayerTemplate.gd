extends KinematicBody

onready var pivot = $Pivot
onready var animation = get_node("AnimationTree")

func move_player(new_position, new_rotation, movement_animation):
	transform.origin = new_position
	pivot.transform.basis.x = new_rotation[0]
	pivot.transform.basis.z = new_rotation[1]
	animation.set("parameters/Movement/blend_amount", movement_animation)
	
