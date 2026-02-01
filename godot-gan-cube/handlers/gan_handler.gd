class_name GanHandler
extends Node

var cube_state : CubeState = CubeState.new()
var _serial = -1
var _last_serial = -1
var _last_local_timestamp = -1

func _get_bit_word(bits : String, start_bit : int, bit_length : int, little_endian : bool = false) -> int:
	if bit_length <= 8:
		return bits.substr(start_bit, bit_length).bin_to_int()
	elif bit_length == 16 or bit_length == 32:
		var buf = PackedByteArray()
		for i in range(0, bit_length / 8):
			buf.append(bits.substr(8 * i + start_bit, 8).bin_to_int())
		if bit_length == 16:
			if not little_endian:
				buf.reverse()
			return buf.decode_u16(0)
		else:
			if not little_endian:
				buf.reverse()
			return buf.decode_u32(0)
	else:
		printerr("Unsupported bit length")
		return -1

func handle_state(state_msg : String, connector : CubeConnector):
	pass

func send_command_message(command : GanTypes.CommandType, cube_device : BleDevice, encrypter : CubeEncrypter):
	pass
	
func get_service_uuid() -> String:
	return ""

func get_state_char_uuid() -> String:
	return ""
	
func get_command_char_uuid() -> String:
	return ""
