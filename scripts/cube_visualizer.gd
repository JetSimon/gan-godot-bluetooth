extends MeshInstance3D

@export
var conn : CubeConnector

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	conn.on_cube_updated.connect(_on_cube_updated)

func _on_cube_updated(cube_state : CubeState):
	rotation = cube_state.rotation.get_euler(2)
