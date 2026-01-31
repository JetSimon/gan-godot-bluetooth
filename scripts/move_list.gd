extends Label

@export
var connector : CubeConnector

@export
var max_moves = 10

var moves = []

func _ready():
	connector.on_cube_move.connect(_on_cube_move)

func _on_cube_move(move : CubeMove):
	if len(moves) > max_moves:
		moves.pop_front()
	moves.append(move)
	
	var move_string = ""
	for m in moves:
		move_string += m.move + " "
	text = move_string	
		
