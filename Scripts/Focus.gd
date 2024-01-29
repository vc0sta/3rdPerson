extends Node

var focused := true

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			focused = true


func input_is_action_pressed(action: StringName) -> bool:
	if focused:
		return Input.is_action_pressed(action)

	return false

func is_action_just_pressed(action: StringName) -> bool:
	if focused:
		return Input.is_action_just_pressed(action)

	return false

func is_action_just_released(action: StringName) -> bool:
	if focused:
		return Input.is_action_just_released(action)

	return false

func get_action_strength(action: StringName) -> float:
	if focused:
		return Input.get_action_strength(action)
	return 0.0
	
func event_is_action_pressed(event: InputEvent, action: StringName) -> bool:
	if focused:
		return event.is_action_pressed(action)

	return false
