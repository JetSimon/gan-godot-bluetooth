extends Label

@export
var connector : CubeConnector

func _ready() -> void:
	connector.on_cube_updated.connect(_on_cube_updated)
	
func _on_cube_updated(cube_state : CubeState):
	text = cube_state.to_string()
