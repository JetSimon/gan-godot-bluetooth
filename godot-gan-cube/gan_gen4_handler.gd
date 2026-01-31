class_name GanGen4Handler
extends GanHandler

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_state(state_msg : String, connector : CubeConnector):
	
	var timestamp : int = round(Time.get_unix_time_from_system())
	
	var event_type = _get_bit_word(state_msg, 0, 8)
	var data_length = _get_bit_word(state_msg, 8, 8)
	
	# MOVE
	if event_type == 0x01:
		if _last_serial == -1:
			evict_move_buffer()
			return
		
		var cube_timestamp = _get_bit_word(state_msg, 16, 32, true)
		_serial = _get_bit_word(state_msg, 48, 16, true)
		
		var direction : int = _get_bit_word(state_msg, 64, 2)
		var face : int = [2, 32, 8, 1, 16, 4].find(_get_bit_word(state_msg, 66, 6))
		
		if face >= 0:
			var move : String = ["U", "R", "F", "D", "L", "B"][face] + ["", "'"][direction]
			
			print(timestamp, " vs ", cube_timestamp)
			var new_move : CubeMove = CubeMove.new(
				face,
				direction,
				move,
				timestamp,
				timestamp,
				cube_timestamp
			)
			cube_state.move_buffer.append(new_move)
			
			connector.on_cube_move.emit(new_move)
		evict_move_buffer()
	
	# MOVE HISTORY
	elif event_type == 0xD1:
		print("Got MOVE HISTORY TODO")
	
	# FACELETS
	elif event_type == 0xED:	
		_serial = _get_bit_word(state_msg, 16, 16, true)
		
		if _last_serial != -1:
			# Is 500 really the amount we want here?
			if _last_local_timestamp != -1 and timestamp - _last_local_timestamp > 500:
				check_if_move_missed()
		else:
			_last_serial = _serial
		
		var cp : Array[int] = []
		var co : Array[int] = []
		var ep : Array[int] = []
		var eo : Array[int] = []
		
		# Corners
		for i in range(7):
			cp.append(_get_bit_word(state_msg, 32 + i * 3, 3));
			co.append(_get_bit_word(state_msg,53 + i * 2, 2));
		cp.append(28 - sum(cp))
		co.append((3 - (sum(co) % 3)) % 3)
		
		# Edges
		for i in range(11):
			ep.append(_get_bit_word(state_msg, 69 + i * 4, 4));
			eo.append(_get_bit_word(state_msg, 113 + i, 1));
		ep.append(66 - sum(ep));
		eo.append((2 - (sum(eo) % 2)) % 2);
		
		cube_state.co = co
		cube_state.cp = cp
		cube_state.eo = eo
		cube_state.ep = ep
		cube_state.facelets = CubeUtils.to_kociemba_facelets(cp, co, ep, eo)
	
	# HARDWARE EVENT
	elif event_type >= 0xFA and event_type <= 0xFE:
		print("Got HARDWARE EVENT TODO")
	
	# GYRO
	elif event_type == 0xEC:
		var qw = _get_bit_word(state_msg, 16, 16);
		var qx = _get_bit_word(state_msg, 32, 16);
		var qy = _get_bit_word(state_msg, 48, 16);
		var qz = _get_bit_word(state_msg, 64, 16);
		
		var rot_denom : float = float(0x7FFF)
		
		var cube_quat = Quaternion(
			(1 - (qx >> 15) * 2) * (qx & 0x7FFF) / rot_denom,
			(1 - (qy >> 15) * 2) * (qy & 0x7FFF) / rot_denom,
			(1 - (qz >> 15) * 2) * (qz & 0x7FFF) / rot_denom,
			(1 - (qw >> 15) * 2) * (qw & 0x7FFF) / rot_denom
		)
		
		cube_state.rotation = Quaternion(
			cube_quat.x,
			cube_quat.z,
			-cube_quat.y,
			cube_quat.w
		)
		
		var vx = _get_bit_word(state_msg, 80, 4)
		var vy = _get_bit_word(state_msg, 84, 4)
		var vz = _get_bit_word(state_msg, 88, 4)
		
		# TODO: Confirm how to convert coordinate systems here
		cube_state.velocity = Vector3(
			(1 - (vx >> 3) * 2) * (vx & 0x7),
			(1 - (vy >> 3) * 2) * (vy & 0x7),
			(1 - (vz >> 3) * 2) * (vz & 0x7)
		)
	
	# BATTERY
	elif event_type == 0xEF:
		print("Got BATTERY TODO")
		var battery = _get_bit_word(state_msg, 8 + data_length * 8, 8)
		cube_state.battery_level = battery
	
	# DISCONNECT
	elif event_type == 0xEA:
		print("Got DISCONNECT TODO")
		# TODO
	else:
		print("Unknown event 0x%X" % event_type, " (%d)" % event_type)
	
func evict_move_buffer():
	#TODO
	pass
	
func check_if_move_missed():
	#TODO
	pass

func sum(arr : Array[int]) -> int:
	var total = 0
	for n in arr:
		total += n
	return total
