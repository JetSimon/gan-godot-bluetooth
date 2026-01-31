extends Node3D

@export
var rotate_speed : float = 10.0

func _process(delta: float) -> void:
	var rot : float = Input.get_axis("move_left", "move_right")
	if rot == 0:
		return
	var amt = deg_to_rad(rot) * delta * rotate_speed
	rotate_y(amt)
