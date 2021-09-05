extends KinematicBody

onready var pivot = $Pivot

func move_player(new_position, new_rotation):
	transform.origin = new_position
	pivot.transform.basis.x = new_rotation[0]
	pivot.transform.basis.z = new_rotation[1]
	
