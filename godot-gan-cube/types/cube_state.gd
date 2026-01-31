class_name CubeState

var rotation : Quaternion = Quaternion.IDENTITY

var velocity : Vector3 = Vector3.ZERO

var battery_level : float = 0

var move_buffer : Array[CubeMove] = []

var facelets : Array[String] = []

var cp : Array[int] = []
var co : Array[int] = []
var ep : Array[int] = []
var eo : Array[int] = []

func is_solved() -> bool:
	return str(facelets) == str(GanTypes.SOLVED_STATE)
