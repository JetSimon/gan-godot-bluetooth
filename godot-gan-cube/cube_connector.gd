class_name CubeConnector
extends Node

var bluetooth_manager: BluetoothManager
var cube_device : BleDevice

func _ready() -> void:
	bluetooth_manager = BluetoothManager.new()
	add_child(bluetooth_manager)
	
	bluetooth_manager.adapter_initialized.connect(_on_initialized)
	bluetooth_manager.device_discovered.connect(_on_device_found)
	bluetooth_manager.scan_stopped.connect(_on_scan_done)
	
	bluetooth_manager.initialize()

func _input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		print("Scanning again..")
		bluetooth_manager.start_scan(30.0)

func _on_initialized(success: bool, error: String):
	if success:
		bluetooth_manager.start_scan(30.0)

func _on_device_found(info: Dictionary):
	var name = info.get("name", "")
	if name and "GAN" in name:
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
	print(cube_device)
	
func _on_connection_failed():
	print("Connection failed!")
	cube_device.disconnect()
	cube_device = null 
	
