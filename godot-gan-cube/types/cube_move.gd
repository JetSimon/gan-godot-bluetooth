class_name CubeMove

var face : int = -1
var direction : int = -1
var move : String
var timestamp : int = -1
var local_timestamp : int = -1
var cube_timestamp : int = -1

func _init(_face : int, _direction : int, _move : String, _timestamp : int, _local_timestamp : int, _cube_timestamp : int):
	face = _face
	direction = _direction
	move = _move
	timestamp = _timestamp
	local_timestamp = _local_timestamp
	cube_timestamp = _cube_timestamp

func _to_string() -> String:
	return "move: " + move
