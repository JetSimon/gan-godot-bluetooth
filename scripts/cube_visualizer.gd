extends MeshInstance3D

@export
var conn : CubeConnector

@export
var faces : Array[Node3D] = []

var facelets : Array[MeshInstance3D] = []

const FACE_COLOR_MAP = {
	"F" : Color.GREEN,
	"U" : Color.WHITE,
	"D" : Color.YELLOW,
	"R" : Color.RED,
	"L" : Color.ORANGE,
	"B" : Color.BLUE
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	facelets.clear()
	for face in faces:
		for facelet in face.get_children():
			if facelet is MeshInstance3D:
				facelet.set_surface_override_material(0, facelet.get_surface_override_material(0).duplicate())
				facelets.append(facelet)
				
	conn.on_cube_updated.connect(_on_cube_updated)

func _on_cube_updated(cube_state : CubeState):
	rotation = cube_state.rotation.get_euler()
	position += cube_state.velocity
	
	if cube_state.facelets.is_empty():
		return
	
	if cube_state.facelets.size() != facelets.size():
		printerr("facelets in state must have same length as facelets in cube")
		return
	
	for i in range(len(cube_state.facelets)):
		facelets[i].get_surface_override_material(0).albedo_color = FACE_COLOR_MAP[cube_state.facelets[i]]
		
