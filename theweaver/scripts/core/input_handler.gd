## InputHandler.gd
## Autoload — couche d'entrée unifiée mobile/desktop.
## Dev 2 · Jour 1
extends Node

signal swipe_detected(direction: Vector2, magnitude: float)

const MIN_SWIPE_PX: float = 40.0

var _touch_starts: Dictionary = {}

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_starts[event.index] = event.position
		else:
			_touch_starts.erase(event.index)

	elif event is InputEventScreenDrag:
		if _touch_starts.has(event.index):
			var delta: Vector2 = event.position - _touch_starts[event.index]
			var mag: float     = delta.length()
			if mag >= MIN_SWIPE_PX:
				swipe_detected.emit(delta.normalized(), mag)
				_touch_starts[event.index] = event.position

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_touch_starts[-1] = event.position
			else:
				_touch_starts.erase(-1)

	elif event is InputEventMouseMotion:
		if _touch_starts.has(-1) and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var delta: Vector2 = event.position - _touch_starts[-1]
			var mag: float     = delta.length()
			if mag >= MIN_SWIPE_PX:
				swipe_detected.emit(delta.normalized(), mag)
				_touch_starts[-1] = event.position
