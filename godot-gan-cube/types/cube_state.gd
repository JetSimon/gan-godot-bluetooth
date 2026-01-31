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

var product_date : String = "Unknown"
var hardware_name : String = "Unknown"
var software_version : String = "Unknown"
var hardware_version : String = "Unknown"

func is_solved() -> bool:
	return str(facelets) == str(GanTypes.SOLVED_STATE)

func _to_string() -> String:
	var info_string = ""
	
	info_string += "PRODUCT_DATE: " + product_date + "\n"
	info_string += "HARDWARE NAME: " + hardware_name + "\n"
	info_string += "SOFTWARE VERSION: " + software_version + "\n"
	info_string += "HARDWARE VERSION: " + hardware_version + "\n"
	info_string += "BATTERY: " + str(battery_level) + "/100\n"
	
	return info_string
