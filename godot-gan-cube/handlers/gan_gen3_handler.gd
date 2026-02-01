class_name GanGen3Handler
extends GanHandler

var _cube_timestamp : int = 0
var _last_move_timestamp : float = 0

func handle_state(state_msg : String, connector : CubeConnector):
	
	var timestamp : float = Time.get_unix_time_from_system()
	
	var magic = _get_bit_word(state_msg, 0, 8)
	var event_type = _get_bit_word(state_msg, 8, 8)
	var data_length = _get_bit_word(state_msg, 16, 8)

	if magic != 0x55 or data_length <= 0:
		return
	
	# MOVE
	if event_type == 0x01:
		if _last_serial == -1:
			return
		
		var cube_timestamp = _get_bit_word(state_msg, 24, 32, true)
		_serial = _get_bit_word(state_msg, 56, 16, true)
		
		var direction : int = _get_bit_word(state_msg, 72, 2)
		var face : int = [2, 32, 8, 1, 16, 4].find(_get_bit_word(state_msg, 74, 6))
		
		if face >= 0:
			var move : String = ["U", "R", "F", "D", "L", "B"][face] + ["", "'"][direction]
			
			var new_move : CubeMove = CubeMove.new(
				face,
				direction,
				move,
				timestamp,
				timestamp,
				cube_timestamp
			)

			connector.on_cube_move.emit(new_move)
	
	# MOVE HISTORY
	elif event_type == 0x06:
		# TODO
		pass
	
	# FACELETS
	elif event_type == 0x02:
		_serial = _get_bit_word(state_msg, 24, 16, true)
		
		if _last_serial != -1:
			# TODO debounce if a move is being made or something
			pass
		
		if _last_serial == -1:
			_last_serial = _serial
		
		var cp : Array[int] = []
		var co : Array[int] = []
		var ep : Array[int] = []
		var eo : Array[int] = []
		
		# Corners
		for i in range(7):
			cp.append(_get_bit_word(state_msg, 40 + i * 3, 3));
			co.append(_get_bit_word(state_msg, 61 + i * 2, 2));
		cp.append(28 - CubeUtils.sum(cp))
		co.append((3 - (CubeUtils.sum(co) % 3)) % 3)
		
		# Edges
		for i in range(11):
			ep.append(_get_bit_word(state_msg, 77 + i * 4, 4));
			eo.append(_get_bit_word(state_msg, 121 + i, 1));
		ep.append(66 - CubeUtils.sum(ep));
		eo.append((2 - (CubeUtils.sum(eo) % 2)) % 2);
		
		cube_state.co = co
		cube_state.cp = cp
		cube_state.eo = eo
		cube_state.ep = ep
		cube_state.facelets = CubeUtils.to_kociemba_facelets(cp, co, ep, eo)
	
	# HARDWARE
	elif event_type == 0x07:
		var hw_major : int = _get_bit_word(state_msg, 80, 4)
		var hw_minor : int = _get_bit_word(state_msg, 84, 4)
		var sw_major : int = _get_bit_word(state_msg, 72, 4)
		var sw_minor : int = _get_bit_word(state_msg, 36, 4)
		var gyro_supported : bool = _get_bit_word(state_msg, 104, 1) != 0
		
		var hw_name : String = ""
		for i in range(5):
			hw_name += char(_get_bit_word(state_msg, i * 8 + 32, 8))
		
		cube_state.hardware_name = hw_name
		cube_state.hardware_version = str(hw_major) + "." + str(hw_minor)
		cube_state.software_version = str(sw_major) + "." + str(sw_minor)
		cube_state.gyro_supported = false
	
	# BATTERY
	elif event_type == 0x10:
		var battery_level = _get_bit_word(state_msg, 24, 8)
		cube_state.battery_level = battery_level
		
	# DISCONNECT
	elif event_type == 0x11:
		connector.disconnect_cube()
	
	else:
		print("Unknown event 0x%X" % event_type, " (%d)" % event_type)

func send_command_message(command : GanTypes.CommandType, cube_device : BleDevice, encrypter : CubeEncrypter):
	var cmd = []
	if command == GanTypes.CommandType.REQUEST_FACELETS:
		cmd = [0x68, 0x01]
	elif command == GanTypes.CommandType.REQUEST_HARDWARE:
		cmd = [0x68, 0x04]
	elif command == GanTypes.CommandType.REQUEST_BATTERY:
		cmd = [0x68, 0x07]
	elif command == GanTypes.CommandType.REQUEST_RESET:
		cmd = [0x68, 0x05, 0x05, 0x39, 0x77, 0x00, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0x00, 0x00, 0x00]
	else:
		printerr("Command type not implemented: " + str(command))
		return
	
	while len(cmd) < 20:
		cmd.append(0x00)
	
	var encrypted_command = encrypter.encrypt(PackedByteArray(cmd))
	
	cube_device.write_characteristic(GanTypes.GAN_GEN3_SERVICE, GanTypes.GAN_GEN3_COMMAND_CHARACTERISTIC, encrypted_command, false)

func get_service_uuid() -> String:
	return GanTypes.GAN_GEN3_SERVICE

func get_state_char_uuid() -> String:
	return GanTypes.GAN_GEN3_STATE_CHARACTERISTIC
	
func get_command_char_uuid() -> String:
	return GanTypes.GAN_GEN3_COMMAND_CHARACTERISTIC
