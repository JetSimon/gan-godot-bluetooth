class_name GanGen4Handler
extends GanHandler

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_state(state_msg : String):
	var event_type = _get_bit_word(state_msg, 0, 8)
	var data_length = _get_bit_word(state_msg, 8, 8)
	
	if event_type == 0x01:
		print("Got MOVE")
	elif event_type == 0xD1:
		print("Got MOVE HISTORY")
	elif event_type == 0xED:
		print("Got FACELETS")
	elif event_type >= 0xFA and event_type <= 0xFE:
		print("Got HARDWARE EVENT TODO")
	elif event_type == 0xEC:
		print("Got GYRO")
		
		var qw = _get_bit_word(state_msg, 16, 16);
		var qx = _get_bit_word(state_msg, 32, 16);
		var qy = _get_bit_word(state_msg, 48, 16);
		var qz = _get_bit_word(state_msg, 64, 16);
		
		var denom : float = float(0x7FFF)
		
		cube_state.rotation = Quaternion(
			(1 - (qx >> 15) * 2) * (qx & 0x7FFF) / denom,
			(1 - (qy >> 15) * 2) * (qy & 0x7FFF) / denom,
			(1 - (qz >> 15) * 2) * (qz & 0x7FFF) / denom,
			(1 - (qw >> 15) * 2) * (qw & 0x7FFF) / denom
		)
		
		# TODO: Velocity
	elif event_type == 0xEF:
		print("Got BATTERY")
	else:
		print("Unknown event 0x%X" % event_type, " (%d)" % event_type)
	
	
