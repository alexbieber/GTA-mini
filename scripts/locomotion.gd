class_name Locomotion
extends RefCounted
## Grace windows independent of character assets and rendering.
const JUMP_SPEED := 9.0
const COYOTE_TIME := 0.10
const BUFFER_TIME := 0.12
var _coyote := 0.0
var _buffer := 0.0
var _jumped := false

func request_jump() -> void:
	_buffer = BUFFER_TIME

func reset() -> void:
	_coyote = 0.0
	_buffer = 0.0
	_jumped = false

func tick(delta: float, grounded: bool) -> bool:
	if grounded:
		_coyote = COYOTE_TIME
		_jumped = false
	else:
		_coyote = maxf(_coyote - delta, 0.0)
	if _buffer > 0.0 and _coyote > 0.0 and not _jumped:
		_buffer = 0.0
		_coyote = 0.0
		_jumped = true
		return true
	_buffer = maxf(_buffer - delta, 0.0)
	return false
