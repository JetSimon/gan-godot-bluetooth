class_name CubeState

var rotation : Quaternion = Quaternion.IDENTITY

var velocity : Vector3 = Vector3.ZERO

var battery_level : float = 0

var facelets : Array[String] = []

var cp : Array[int] = []
var co : Array[int] = []
var ep : Array[int] = []
var eo : Array[int] = []

var product_date : String = "Unknown"
var hardware_name : String = "Unknown"
var software_version : String = "Unknown"
var hardware_version : String = "Unknown"
var gyro_supported : bool = false

func is_solved() -> bool:
	return str(facelets) == str(GanTypes.SOLVED_STATE)

func _to_string() -> String:
	var info_string = ""
	
	info_string += "PRODUCT DATE: " + product_date + "\n"
	info_string += "HARDWARE NAME: " + hardware_name + "\n"
	info_string += "SOFTWARE VERSION: " + software_version + "\n"
	info_string += "HARDWARE VERSION: " + hardware_version + "\n"
	info_string += "BATTERY: " + str(battery_level) + "/100\n"
	info_string += "GYRO: " + str(gyro_supported) + "\n"
	
	var rot = rotation.get_euler()
	rot.x = rad_to_deg(rot.x)
	rot.y = rad_to_deg(rot.y)
	rot.z = rad_to_deg(rot.z)
	
	info_string += "\nORI: " + str(rot) + " degrees\n"
	info_string += "VEL: " + str(velocity) + "\n"
	
	info_string += "\nSOLVED: " + str(is_solved()) + "\n"
	
	return info_string
