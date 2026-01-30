class_name GanCubeEncrypter
extends CubeEncrypter

var aes = AESContext.new()
var _key : Array = []
var _iv : Array = []

func init(key : Array, iv : Array, mac_address : String) -> bool:
	_key = key
	_iv = iv
	
	if _key.size() != 16 or _iv.size() != 16:
		printerr("key and iv of GanCubeEncrypter must be size 16")
		return false
		
	var salt = []
	
	# Use mac address to create salt
	for byte in mac_address.split(":"):
		salt.append(byte.hex_to_int())
	salt.reverse()
	
	if salt.size() != 6:
		printerr("salt of GanCubeEncrypter must be size 6")
		return false
	
	for i in range(0, 6):
		_key[i] = (key[i] + salt[i]) % 0xFF
		_iv[i] = (iv[i] + salt[i]) % 0xFF
		
	return true
	
func encrypt(data: PackedByteArray) -> PackedByteArray:
	if data.size() < 16:
		printerr("size of data in GanCubeEcrypter must be of size >= 16")
		return data
	
	var res = data.duplicate()
	_encrypt_chunk(res, 0)
	
	if res.size() > 16:
		_encrypt_chunk(res, res.size() - 16)
	return res

func decrypt(data: PackedByteArray) -> PackedByteArray:
	if data.size() < 16:
		printerr("size of data in GanCubeEcrypter must be of size >= 16")
		return data
	
	var res = data.duplicate()
	
	if res.size() > 16:
		_decrypt_chunk(res, res.size() - 16)
	_decrypt_chunk(res, 0)
	
	return res

func _encrypt_chunk(buffer : PackedByteArray, offset : int) -> void:
	aes.start(AESContext.MODE_CBC_ENCRYPT, _key, _iv)
	var chunk = aes.update(buffer.slice(offset, offset + 16))
	aes.finish()
	
	for i in range(0, 16):
		buffer[offset + i] = chunk[i]

func _decrypt_chunk(buffer : PackedByteArray, offset : int) -> void:
	aes.start(AESContext.MODE_CBC_DECRYPT, _key, _iv)
	var chunk = aes.update(buffer.slice(offset, offset + 16))
	aes.finish()
	
	for i in range(0, 16):
		buffer[offset + i] = chunk[i]
