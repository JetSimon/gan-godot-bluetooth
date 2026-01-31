class_name CubeConnector
extends Node

signal on_cube_updated(cube_state : CubeState)
signal on_cube_move(move : CubeMove)
signal on_cube_solved()

var encrypter : CubeEncrypter
var bluetooth_manager: BluetoothManager
var cube_device : BleDevice = null
var gan_handler : GanHandler

var _prev_is_solved : bool = false

func _ready() -> void:
	gan_handler = GanGen4Handler.new()
	add_child(gan_handler)
	encrypter = GanCubeEncrypter.new()
	add_child(encrypter)
	bluetooth_manager = BluetoothManager.new()
	add_child(bluetooth_manager)

	bluetooth_manager.adapter_initialized.connect(_on_initialized)
	bluetooth_manager.device_discovered.connect(_on_device_found)
	bluetooth_manager.scan_stopped.connect(_on_scan_done)
	
	bluetooth_manager.initialize()
	

func _on_initialized(success: bool, error: String):
	if success:
		bluetooth_manager.start_scan(10.0)

func _on_device_found(info: Dictionary):
	var name = info.get("name", "")
	if not cube_device and name and "GAN" in name:
		print("Cube found")
		print(info)
		bluetooth_manager.stop_scan()
		connect_to_target(info.get("address"))

func _on_scan_done():
	print("Scan complete")

func connect_to_target(address: String):
	print("Trying to connect now")
	cube_device = bluetooth_manager.connect_device(address)
	if cube_device:
		print("hooking up")
		cube_device.connected.connect(_on_connected)
		cube_device.connection_failed.connect(_on_connection_failed)
		cube_device.connect_async()
	else:
		print("connect device call failed?")
		
func _on_connected():
	print("Device connected!")
	
	var key : Array = GanTypes.GAN_ENCRYPTION_KEYS[0]["key"]
	var iv : Array = GanTypes.GAN_ENCRYPTION_KEYS[0]["iv"]
	encrypter.init(key, iv, cube_device.get_address())
	
	cube_device.services_discovered.connect(_on_services_discovered)
	
	cube_device.characteristic_notified.connect(_on_notified)
	
	cube_device.discover_services()

func _on_services_discovered(services : Array):
	print("Discovered ", services.size(), " services!")
	cube_device.subscribe_characteristic(GanTypes.GAN_GEN4_SERVICE, GanTypes.GAN_GEN4_STATE_CHARACTERISTIC)
	
	gan_handler.send_command_message(GanTypes.CommandType.REQUEST_HARDWARE, cube_device, encrypter)
	await get_tree().create_timer(1).timeout
	gan_handler.send_command_message(GanTypes.CommandType.REQUEST_BATTERY, cube_device, encrypter)

func _on_notified(id : String, data : PackedByteArray):
	if id == GanTypes.GAN_GEN4_STATE_CHARACTERISTIC:
		var raw_state = encrypter.decrypt(data)
		var state_msg = packed_byte_array_to_bits(raw_state)
		gan_handler.handle_state(state_msg, self)
		on_cube_updated.emit(gan_handler.cube_state)
		
		var is_solved = gan_handler.cube_state.is_solved()
		if is_solved and _prev_is_solved != is_solved:
			on_cube_solved.emit()
		_prev_is_solved = is_solved
	
func _on_connection_failed():
	print("Connection failed!")
	cube_device.disconnect()
	cube_device = null 

func disconnect_cube():
	if cube_device:
		print("Disconnecting cube")
		cube_device.disconnect()

func packed_byte_array_to_bits(bytes_array: PackedByteArray) -> String:
	var bits: String = ""
	for byte in bytes_array:
		var new_byte : int = (byte + 0x100)
		var chunk : String = String.num_int64(new_byte, 2).substr(1)
		bits += chunk
	return bits
