class_name GanGen2Handler
extends GanHandler

var _cube_timestamp : int = 0
var _last_move_timestamp : float = 0

func handle_state(state_msg : String, connector : CubeConnector):
	
	var timestamp : float = Time.get_unix_time_from_system()
	var event_type = _get_bit_word(state_msg, 0, 4)

	# GYRO
	if event_type == 0x01:
		var qw = _get_bit_word(state_msg, 4, 16);
		var qx = _get_bit_word(state_msg, 20, 16);
		var qy = _get_bit_word(state_msg, 36, 16);
		var qz = _get_bit_word(state_msg, 52, 16);
		
		var cube_quat = Quaternion(
			CubeUtils.num_to_quat_component(qx),
			CubeUtils.num_to_quat_component(qy),
			CubeUtils.num_to_quat_component(qz),
			CubeUtils.num_to_quat_component(qw),
		)
		
		cube_state.rotation = CubeUtils.cube_quat_to_godot_quat(cube_quat)
		
		var vx = _get_bit_word(state_msg, 68, 4)
		var vy = _get_bit_word(state_msg, 72, 4)
		var vz = _get_bit_word(state_msg, 76, 4)
		
		var cube_vel = Vector3(
			CubeUtils.num_to_velocity_component(vx),
			CubeUtils.num_to_velocity_component(vy),
			CubeUtils.num_to_velocity_component(vz)
		)
		
		cube_state.velocity = CubeUtils.cube_vector_to_godot_vector(cube_vel)
	
	# MOVE
	elif event_type == 0x02:
		if _last_serial == -1:
			return
		
		_serial = _get_bit_word(state_msg, 4, 8)
		var diff : int = min((_serial - _last_serial) & 0xFF, 7)
		_last_serial = _serial
		
		if diff <= 0:
			return
		
		for i in range(diff - 1, -1, -1):
			var face : int = _get_bit_word(state_msg, 12 + 5 * i, 4)
			var direction : int = _get_bit_word(state_msg, 16 + 5 * i, 1)
			var move : String = ["U", "R", "F", "D", "L", "B"][face] + ["", "'"][direction]
			
			var elapsed : int = _get_bit_word(state_msg, 47 + 16 * i, 16)
			
			# In case of 16 bit cube timestamp register overflow
			if elapsed == 0: 
				elapsed = round(timestamp - _last_move_timestamp)
			
			_cube_timestamp += elapsed
			
			var new_move : CubeMove = CubeMove.new(
				face,
				direction,
				move,
				timestamp,
				timestamp,
				_cube_timestamp
			)

			connector.on_cube_move.emit(new_move)
	
	# FACELETS
	elif event_type == 0x04:
		_serial = _get_bit_word(state_msg, 4, 8)
		
		if _last_serial == -1:
			_last_serial = _serial
		
		var cp : Array[int] = []
		var co : Array[int] = []
		var ep : Array[int] = []
		var eo : Array[int] = []
		
		# Corners
		for i in range(7):
			cp.append(_get_bit_word(state_msg, 12 + i * 3, 3));
			co.append(_get_bit_word(state_msg, 33 + i * 2, 2));
		cp.append(28 - CubeUtils.sum(cp))
		co.append((3 - (CubeUtils.sum(co) % 3)) % 3)
		
		# Edges
		for i in range(11):
			ep.append(_get_bit_word(state_msg, 47 + i * 4, 4));
			eo.append(_get_bit_word(state_msg, 91 + i, 1));
		ep.append(66 - CubeUtils.sum(ep));
		eo.append((2 - (CubeUtils.sum(eo) % 2)) % 2);
		
		cube_state.co = co
		cube_state.cp = cp
		cube_state.eo = eo
		cube_state.ep = ep
		cube_state.facelets = CubeUtils.to_kociemba_facelets(cp, co, ep, eo)
	
	# HARDWARE
	elif event_type == 0x05:
		var hw_major : int = _get_bit_word(state_msg, 8, 8)
		var hw_minor : int = _get_bit_word(state_msg, 16, 8)
		var sw_major : int = _get_bit_word(state_msg, 24, 8)
		var sw_minor : int = _get_bit_word(state_msg, 32, 8)
		var gyro_supported : bool = _get_bit_word(state_msg, 104, 1) != 0
		
		var hw_name : String = ""
		for i in range(8):
			hw_name += char(_get_bit_word(state_msg, i * 8 + 40, 8))
		
		cube_state.hardware_name = hw_name
		cube_state.hardware_version = str(hw_major) + "." + str(hw_minor)
		cube_state.software_version = str(sw_major) + "." + str(sw_minor)
		cube_state.gyro_supported = gyro_supported
	
	# BATTERY
	elif event_type == 0x09:
		var battery_level = _get_bit_word(state_msg, 8, 8)
		cube_state.battery_level = battery_level
	
	# DISCONNECT
	elif event_type == 0x0D:
		connector.disconnect_cube()
	
	else:
		print("Unknown event 0x%X" % event_type, " (%d)" % event_type)

func send_command_message(command : GanTypes.CommandType, cube_device : BleDevice, encrypter : CubeEncrypter):
	var cmd = []
	if command == GanTypes.CommandType.REQUEST_FACELETS:
		cmd = [0x04]
	elif command == GanTypes.CommandType.REQUEST_HARDWARE:
		cmd = [0x05]
	elif command == GanTypes.CommandType.REQUEST_BATTERY:
		cmd = [0x09]
	elif command == GanTypes.CommandType.REQUEST_RESET:
		cmd = [0x0A, 0x05, 0x39, 0x77, 0x00, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
	else:
		printerr("Command type not implemented: " + str(command))
		return
	
	while len(cmd) < 20:
		cmd.append(0x00)
	
	var encrypted_command = encrypter.encrypt(PackedByteArray(cmd))
	
	cube_device.write_characteristic(GanTypes.GAN_GEN2_SERVICE, GanTypes.GAN_GEN2_COMMAND_CHARACTERISTIC, encrypted_command, false)


func get_service_uuid() -> String:
	return GanTypes.GAN_GEN2_SERVICE

func get_state_char_uuid() -> String:
	return GanTypes.GAN_GEN2_STATE_CHARACTERISTIC
	
func get_command_char_uuid() -> String:
	return GanTypes.GAN_GEN2_COMMAND_CHARACTERISTIC
