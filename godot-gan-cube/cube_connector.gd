class_name CubeConnector
extends Node

signal on_cube_updated(cube_state : CubeState)
signal on_cube_move(move : CubeMove)
signal on_cube_solved()

var bluetooth_manager: BluetoothManager
var cube_device : BleDevice = null

var encrypter : CubeEncrypter
var gan_handler : GanHandler

var _prev_is_solved : bool = false

func _ready() -> void:
	bluetooth_manager = BluetoothManager.new()
	add_child(bluetooth_manager)

	bluetooth_manager.adapter_initialized.connect(_on_initialized)
	bluetooth_manager.device_discovered.connect(_on_device_found)
	bluetooth_manager.scan_stopped.connect(_on_scan_done)
	
	bluetooth_manager.initialize()
	

func _on_initialized(success: bool, error: String):
	if success:
		bluetooth_manager.start_scan(10.0)
	else:
		printerr("Error initializing bluetooth: ", error)

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

	cube_device.services_discovered.connect(_on_services_discovered)
	cube_device.characteristic_notified.connect(_on_notified)
	cube_device.discover_services()

func _is_gan_from_services(services : Array) -> bool:
	for service in services:
		if "uuid" not in service or not service["uuid"]:
			continue
		if service["uuid"] in [GanTypes.GAN_GEN2_SERVICE, GanTypes.GAN_GEN3_SERVICE, GanTypes.GAN_GEN4_SERVICE]:
			return true
	return false

func _get_gan_generation_from_services(services : Array) -> int:
	for service in services:
		if "uuid" not in service or not service["uuid"]:
			continue
		if service["uuid"] == GanTypes.GAN_GEN2_SERVICE:
			return 2
		elif service["uuid"] == GanTypes.GAN_GEN3_SERVICE:
			return 3
		elif service["uuid"] == GanTypes.GAN_GEN4_SERVICE:
			return 4
	return -1

func _on_services_discovered(services : Array):
	print("Discovered ", services.size(), " services!")
	
	var is_gan = _is_gan_from_services(services)
	
	if is_gan:
		encrypter = GanCubeEncrypter.new()
		add_child(encrypter)
		
		var key : Array = GanTypes.GAN_ENCRYPTION_KEYS[0]["key"]
		var iv : Array = GanTypes.GAN_ENCRYPTION_KEYS[0]["iv"]
		encrypter.init(key, iv, cube_device.get_address())
		
		var generation = _get_gan_generation_from_services(services)

		if generation == 2:
			gan_handler = GanGen2Handler.new()
		elif generation == 3:
			gan_handler = GanGen3Handler.new()
		elif generation == 4:
			gan_handler = GanGen4Handler.new()
		else:
			printerr("GAN generation ", generation, " not supported!")
			encrypter = null
			gan_handler = null
			return
		
		add_child(gan_handler)
	else:
		# TODO: Add non-GAN cube support
		disconnect_cube()
		return
	
	cube_device.subscribe_characteristic(gan_handler.get_service_uuid(), gan_handler.get_state_char_uuid())
	
	gan_handler.send_command_message(GanTypes.CommandType.REQUEST_HARDWARE, cube_device, encrypter)
	await get_tree().create_timer(1).timeout
	gan_handler.send_command_message(GanTypes.CommandType.REQUEST_BATTERY, cube_device, encrypter)

func _is_state_notif(id : String) -> bool:
	return id == GanTypes.GAN_GEN2_STATE_CHARACTERISTIC or id == GanTypes.GAN_GEN3_STATE_CHARACTERISTIC or id == GanTypes.GAN_GEN4_STATE_CHARACTERISTIC

func _on_notified(id : String, data : PackedByteArray):
	if _is_state_notif(id):
		var raw_state = encrypter.decrypt(data)
		var state_msg = _packed_byte_array_to_bits(raw_state)
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

func _packed_byte_array_to_bits(bytes_array: PackedByteArray) -> String:
	var bits: String = ""
	for byte in bytes_array:
		var new_byte : int = (byte + 0x100)
		var chunk : String = String.num_int64(new_byte, 2).substr(1)
		bits += chunk
	return bits

func disconnect_cube():
	if cube_device:
		print("Disconnecting cube")
		cube_device.disconnect()

func send_command(command : GanTypes.CommandType) -> void:
	if not cube_device:
		printerr("Cannot send command if cube not connected")
		return
	gan_handler.send_command_message(command, cube_device, encrypter)
