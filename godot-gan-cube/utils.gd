class_name CubeUtils

const CORNER_FACELET_MAP = [
	[8, 9, 20], # URF
	[6, 18, 38], # UFL
	[0, 36, 47], # ULB
	[2, 45, 11], # UBR
	[29, 26, 15], # DFR
	[27, 44, 24], # DLF
	[33, 53, 42], # DBL
	[35, 17, 51]  # DRB
];

const EDGE_FACELET_MAP = [
	[5, 10], # UR
	[7, 19], # UF
	[3, 37], # UL
	[1, 46], # UB
	[32, 16], # DR
	[28, 25], # DF
	[30, 43], # DL
	[34, 52], # DB
	[23, 12], # FR
	[21, 41], # FL
	[50, 39], # BL
	[48, 14]  # BR
];

static func to_kociemba_facelets(cp : Array[int], co : Array[int], ep : Array[int], eo : Array[int]) -> Array[String]:
	var faces = ["U", "R", "F", "D", "L", "B"]
	var facelets : Array[String] = []
	
	for i in range(54):
		facelets.append(faces[~~(i / 9)])
	
	for i in range(8):
		for p in range(3):
			facelets[CORNER_FACELET_MAP[i][(p + co[i]) % 3]] = faces[~~(CORNER_FACELET_MAP[cp[i]][p] / 9)];
	
	for i in range(12):
		for p in range(2):
			facelets[EDGE_FACELET_MAP[i][(p + eo[i]) % 2]] = faces[~~(EDGE_FACELET_MAP[ep[i]][p] / 9)];
	
	return facelets

static func sum(arr : Array[int]) -> int:
	var total : int = 0
	for n in arr:
		total += n
	return total

static func num_to_quat_component(n : int) -> float:
	return (1 - (n >> 15) * 2) * (n & 0x7FFF) / float(0x7FFF)

static func num_to_velocity_component(n : int) -> float:
	return (1 - (n >> 3) * 2.0) * (n & 0x7)

static func cube_quat_to_godot_quat(quat : Quaternion) -> Quaternion:
	return Quaternion(
		quat.x,
		quat.z,
		-quat.y,
		quat.w
	)

static func cube_vector_to_godot_vector(vec : Vector3) -> Vector3:
	return Vector3(
		vec.x,
		vec.z,
		-vec.y
	)
